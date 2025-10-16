# ADAS-CARLA Makefile
# Main entry point for all project operations

.PHONY: help setup test deploy clean
.DEFAULT_GOAL := help

# Variables
SHELL := /bin/bash
PROJECT_NAME := adas-carla
PYTHON := python3
DOCKER_COMPOSE := docker-compose
TERRAFORM := terraform
KUBECTL := kubectl
ENV ?= dev

# Colors for terminal output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Versions
PYTHON_VERSION := 3.10
TERRAFORM_VERSION := 1.5
NODE_VERSION := 18

##@ General

help: ## Display this help
	@echo "$(BLUE)ADAS-CARLA - Makefile Commands$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make $(GREEN)<target>$(NC)\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(YELLOW)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

check-requirements: ## Check if required tools are installed
	@echo "$(YELLOW)Checking requirements...$(NC)"
	@command -v python3 >/dev/null 2>&1 || { echo "$(RED)Python 3 is required but not installed.$(NC)" >&2; exit 1; }
	@command -v docker >/dev/null 2>&1 || { echo "$(RED)Docker is required but not installed.$(NC)" >&2; exit 1; }
	@command -v docker-compose >/dev/null 2>&1 || { echo "$(RED)Docker Compose is required but not installed.$(NC)" >&2; exit 1; }
	@echo "$(GREEN) All requirements met$(NC)"

##@ Development

setup: check-requirements ## Setup local development environment
	@echo "$(YELLOW)Setting up ADAS-CARLA development environment...$(NC)"
	@echo "Creating Python virtual environment..."
	$(PYTHON) -m venv venv
	@echo "Installing Python dependencies..."
	./venv/bin/pip install --upgrade pip
	./venv/bin/pip install -r requirements.txt
	@echo "Installing pre-commit hooks..."
	./venv/bin/pre-commit install
	@echo "Creating .env file from template..."
	cp -n .env.example .env || true
	@echo "$(GREEN) Setup complete! Activate venv with: source venv/bin/activate$(NC)"

install: ## Install project in editable mode
	./venv/bin/pip install -e .

dev: ## Start development environment
	@echo "$(YELLOW)Starting development environment...$(NC)"
	$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN) Development environment running$(NC)"
	@echo "Services:"
	@echo "  - CARLA Simulator: http://localhost:2000"
	@echo "  - MLflow: http://localhost:5000"
	@echo "  - Grafana: http://localhost:3000"
	@echo "  - API: http://localhost:8000"

down: ## Stop development environment
	$(DOCKER_COMPOSE) down

logs: ## Show logs from all services
	$(DOCKER_COMPOSE) logs -f

##@ Testing

test: ## Run unit tests
	@echo "$(YELLOW)Running unit tests...$(NC)"
	./venv/bin/pytest tests/unit -v --color=yes

test-integration: ## Run integration tests
	@echo "$(YELLOW)Running integration tests...$(NC)"
	./venv/bin/pytest tests/integration -v --color=yes

test-e2e: ## Run end-to-end tests
	@echo "$(YELLOW)Running E2E tests...$(NC)"
	./venv/bin/pytest tests/e2e -v --color=yes

test-all: test test-integration test-e2e ## Run all tests

coverage: ## Generate test coverage report
	./venv/bin/pytest --cov=src --cov-report=html --cov-report=term
	@echo "$(GREEN)Coverage report generated at htmlcov/index.html$(NC)"

##@ Code Quality

lint: ## Run code linters
	@echo "$(YELLOW)Running linters...$(NC)"
	./venv/bin/flake8 src/ tests/
	./venv/bin/pylint src/
	./venv/bin/mypy src/

format: ## Format code with black and isort
	@echo "$(YELLOW)Formatting code...$(NC)"
	./venv/bin/black src/ tests/
	./venv/bin/isort src/ tests/
	@echo "$(GREEN) Code formatted$(NC)"

security-scan: ## Run security vulnerability scan
	@echo "$(YELLOW)Running security scan...$(NC)"
	./venv/bin/bandit -r src/
	./venv/bin/safety check
	trivy fs .

##@ Docker

docker-build: ## Build all Docker images
	@echo "$(YELLOW)Building Docker images...$(NC)"
	docker build -f docker/carla/Dockerfile -t $(PROJECT_NAME)-carla:latest .
	docker build -f docker/processor/Dockerfile -t $(PROJECT_NAME)-processor:latest .
	@echo "$(GREEN) Docker images built$(NC)"

docker-push: ## Push images to registry
	@echo "$(YELLOW)Pushing images to registry...$(NC)"
	docker tag $(PROJECT_NAME)-carla:latest $(REGISTRY)/$(PROJECT_NAME)-carla:$(VERSION)
	docker push $(REGISTRY)/$(PROJECT_NAME)-carla:$(VERSION)

##@ Infrastructure

terraform-init: ## Initialize Terraform
	@echo "$(YELLOW)Initializing Terraform...$(NC)"
	cd infrastructure/terraform && $(TERRAFORM) init

terraform-plan: ## Plan infrastructure changes
	@echo "$(YELLOW)Planning infrastructure changes for $(ENV)...$(NC)"
	cd infrastructure/terraform && \
		$(TERRAFORM) plan -var-file=environments/$(ENV)/terraform.tfvars -out=tfplan

terraform-apply: ## Apply infrastructure changes
	@echo "$(YELLOW)Applying infrastructure changes for $(ENV)...$(NC)"
	cd infrastructure/terraform && \
		$(TERRAFORM) apply -var-file=environments/$(ENV)/terraform.tfvars -auto-approve

terraform-destroy: ## Destroy infrastructure
	@echo "$(RED)WARNING: Destroying infrastructure for $(ENV)...$(NC)"
	cd infrastructure/terraform && \
		$(TERRAFORM) destroy -var-file=environments/$(ENV)/terraform.tfvars

##@ Kubernetes

k8s-create-namespace: ## Create Kubernetes namespace
	$(KUBECTL) create namespace $(PROJECT_NAME) --dry-run=client -o yaml | $(KUBECTL) apply -f -

k8s-deploy: k8s-create-namespace ## Deploy to Kubernetes
	@echo "$(YELLOW)Deploying to Kubernetes ($(ENV))...$(NC)"
	$(KUBECTL) apply -k infrastructure/kubernetes/overlays/$(ENV)

k8s-status: ## Check deployment status
	$(KUBECTL) -n $(PROJECT_NAME) get all

k8s-logs: ## Show pod logs
	$(KUBECTL) -n $(PROJECT_NAME) logs -l app=$(PROJECT_NAME) --tail=100 -f

k8s-delete: ## Delete Kubernetes resources
	$(KUBECTL) delete -k infrastructure/kubernetes/overlays/$(ENV)

##@ Simulation

run-simulation: ## Run a CARLA simulation locally
	@echo "$(YELLOW)Starting CARLA simulation...$(NC)"
	./venv/bin/python src/simulator/run_simulation.py --config configs/simulation.yaml

generate-dataset: ## Generate synthetic dataset
	@echo "$(YELLOW)Generating synthetic dataset...$(NC)"
	./venv/bin/python src/data_processor/generate.py --scenarios 10 --output data/synthetic/

validate-data: ## Validate generated data
	./venv/bin/python src/data_processor/validate.py --input data/synthetic/

##@ ML Pipeline

train: ## Train ML model
	@echo "$(YELLOW)Starting model training...$(NC)"
	./venv/bin/python src/ml_pipeline/train.py --config configs/training.yaml

evaluate: ## Evaluate model performance
	./venv/bin/python src/ml_pipeline/evaluate.py --model models/latest

serve-model: ## Serve model via API
	./venv/bin/python src/api/serve.py --model models/latest --port 8000

##@ Monitoring

monitoring-up: ## Start monitoring stack
	@echo "$(YELLOW)Starting monitoring stack...$(NC)"
	docker-compose -f monitoring/docker-compose.yml up -d
	@echo "$(GREEN)Monitoring stack running:$(NC)"
	@echo "  - Prometheus: http://localhost:9090"
	@echo "  - Grafana: http://localhost:3000"

monitoring-down: ## Stop monitoring stack
	docker-compose -f monitoring/docker-compose.yml down

##@ Database

db-migrate: ## Run database migrations
	./venv/bin/alembic upgrade head

db-rollback: ## Rollback last migration
	./venv/bin/alembic downgrade -1

db-reset: ## Reset database
	./venv/bin/alembic downgrade base
	./venv/bin/alembic upgrade head

##@ Utilities

clean: ## Clean build artifacts and cache
	@echo "$(YELLOW)Cleaning up...$(NC)"
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	rm -rf .pytest_cache .coverage htmlcov .mypy_cache
	rm -rf build dist *.egg-info
	rm -rf data/raw/* data/processed/* data/synthetic/*
	@echo "$(GREEN) Cleanup complete$(NC)"

backup: ## Backup important data
	@echo "$(YELLOW)Creating backup...$(NC)"
	tar -czf backups/backup-$$(date +%Y%m%d-%H%M%S).tar.gz \
		--exclude=venv --exclude=.git --exclude=data \
		--exclude=models --exclude=__pycache__ .
	@echo "$(GREEN) Backup created$(NC)"

docs: ## Generate documentation
	./venv/bin/mkdocs build

docs-serve: ## Serve documentation locally
	./venv/bin/mkdocs serve

version: ## Show tool versions
	@echo "$(BLUE)Tool Versions:$(NC)"
	@echo "Python: $$(python3 --version)"
	@echo "Docker: $$(docker --version)"
	@echo "Docker Compose: $$(docker-compose --version)"
	@$(TERRAFORM) version 2>/dev/null | head -1 || echo "Terraform: not installed"
	@$(KUBECTL) version --client --short 2>/dev/null || echo "Kubectl: not installed"

##@ CI/CD

ci-local: lint test ## Run CI pipeline locally
	@echo "$(GREEN) Local CI pipeline passed$(NC)"

deploy: terraform-apply k8s-deploy ## Full deployment to environment
	@echo "$(GREEN) Deployment to $(ENV) complete$(NC)"

rollback: ## Rollback to previous version
	@echo "$(YELLOW)Rolling back deployment...$(NC)"
	$(KUBECTL) -n $(PROJECT_NAME) rollout undo deployment/$(PROJECT_NAME)

##@ Shortcuts

s: setup ## Shortcut for setup
d: dev ## Shortcut for dev
t: test ## Shortcut for test
f: format ## Shortcut for format
l: logs ## Shortcut for logs