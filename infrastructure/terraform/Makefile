# Makefile for Terraform operations
# Simplifies infrastructure management commands

.PHONY: help init plan apply destroy fmt validate clean

# Variables
ENV ?= dev
REGION ?= eu-west-1
TERRAFORM := terraform
TF_VARS := -var-file=environments/$(ENV)/terraform.tfvars
BACKEND_CONFIG := backend-$(ENV).hcl

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

help: ## Show this help message
	@echo "$(GREEN)ADAS-CARLA Terraform Commands$(NC)"
	@echo ""
	@echo "Usage: make [target] ENV=[dev|staging|prod]"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "Current environment: $(YELLOW)$(ENV)$(NC)"

check-env: ## Check if environment is valid
	@if [ "$(ENV)" != "dev" ] && [ "$(ENV)" != "staging" ] && [ "$(ENV)" != "prod" ]; then \
		echo "$(RED)Error: Invalid environment '$(ENV)'. Use dev, staging, or prod.$(NC)"; \
		exit 1; \
	fi

setup-backend: check-env ## Setup S3 backend for Terraform state
	@echo "$(YELLOW)Setting up Terraform backend for $(ENV)...$(NC)"
	@chmod +x scripts/setup-backend.sh
	@./scripts/setup-backend.sh $(ENV)
	@echo "$(GREEN) Backend setup complete$(NC)"

init: check-env ## Initialize Terraform
	@echo "$(YELLOW)Initializing Terraform for $(ENV)...$(NC)"
	@if [ ! -f "$(BACKEND_CONFIG)" ]; then \
		echo "$(RED)Backend config not found. Run 'make setup-backend' first.$(NC)"; \
		exit 1; \
	fi
	$(TERRAFORM) init -backend-config=$(BACKEND_CONFIG) -reconfigure
	@echo "$(GREEN) Terraform initialized$(NC)"

validate: init ## Validate Terraform configuration
	@echo "$(YELLOW)Validating Terraform configuration...$(NC)"
	$(TERRAFORM) validate
	@echo "$(GREEN) Configuration is valid$(NC)"

fmt: ## Format Terraform files
	@echo "$(YELLOW)Formatting Terraform files...$(NC)"
	$(TERRAFORM) fmt -recursive .
	@echo "$(GREEN) Files formatted$(NC)"

fmt-check: ## Check if Terraform files are formatted
	@echo "$(YELLOW)Checking Terraform formatting...$(NC)"
	@if $(TERRAFORM) fmt -check -recursive .; then \
		echo "$(GREEN) All files properly formatted$(NC)"; \
	else \
		echo "$(RED)✗ Some files need formatting. Run 'make fmt'$(NC)"; \
		exit 1; \
	fi

plan: validate ## Plan Terraform changes
	@echo "$(YELLOW)Planning Terraform changes for $(ENV)...$(NC)"
	$(TERRAFORM) plan $(TF_VARS) -out=tfplan-$(ENV)
	@echo "$(GREEN) Plan saved to tfplan-$(ENV)$(NC)"

apply: plan ## Apply Terraform changes
	@echo "$(YELLOW)Applying Terraform changes for $(ENV)...$(NC)"
	@echo "$(RED)WARNING: This will modify infrastructure in $(ENV)$(NC)"
	@read -p "Are you sure? [y/N]: " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		$(TERRAFORM) apply tfplan-$(ENV); \
		echo "$(GREEN) Changes applied successfully$(NC)"; \
	else \
		echo "$(YELLOW)Aborted$(NC)"; \
	fi

apply-auto: validate ## Apply changes without confirmation (CI/CD)
	@echo "$(YELLOW)Auto-applying Terraform changes for $(ENV)...$(NC)"
	$(TERRAFORM) apply $(TF_VARS) -auto-approve
	@echo "$(GREEN) Changes applied$(NC)"

destroy: check-env ## Destroy infrastructure
	@echo "$(RED)WARNING: This will DESTROY all infrastructure in $(ENV)$(NC)"
	@read -p "Type 'destroy-$(ENV)' to confirm: " confirm; \
	if [ "$$confirm" = "destroy-$(ENV)" ]; then \
		$(TERRAFORM) destroy $(TF_VARS); \
	else \
		echo "$(YELLOW)Aborted$(NC)"; \
	fi

refresh: init ## Refresh Terraform state
	@echo "$(YELLOW)Refreshing Terraform state for $(ENV)...$(NC)"
	$(TERRAFORM) refresh $(TF_VARS)
	@echo "$(GREEN) State refreshed$(NC)"

output: ## Show Terraform outputs
	@$(TERRAFORM) output -json

output-raw: ## Show raw Terraform outputs
	@$(TERRAFORM) output

show: ## Show current Terraform state
	@$(TERRAFORM) show

list: ## List resources in state
	@$(TERRAFORM) state list

graph: ## Generate dependency graph
	@echo "$(YELLOW)Generating dependency graph...$(NC)"
	@$(TERRAFORM) graph | dot -Tpng > terraform-graph-$(ENV).png
	@echo "$(GREEN) Graph saved to terraform-graph-$(ENV).png$(NC)"

cost: validate ## Estimate monthly costs (requires Infracost)
	@echo "$(YELLOW)Estimating costs for $(ENV)...$(NC)"
	@if command -v infracost >/dev/null 2>&1; then \
		infracost breakdown --path . --terraform-var-file environments/$(ENV)/terraform.tfvars; \
	else \
		echo "$(RED)Infracost not installed. Install from https://infracost.io$(NC)"; \
	fi

security-scan: ## Security scan with tfsec
	@echo "$(YELLOW)Running security scan...$(NC)"
	@if command -v tfsec >/dev/null 2>&1; then \
		tfsec . --var-file environments/$(ENV)/terraform.tfvars; \
	else \
		echo "$(RED)tfsec not installed. Install from https://github.com/aquasecurity/tfsec$(NC)"; \
	fi

docs: ## Generate documentation with terraform-docs
	@echo "$(YELLOW)Generating documentation...$(NC)"
	@if command -v terraform-docs >/dev/null 2>&1; then \
		terraform-docs markdown . > TERRAFORM.md; \
		echo "$(GREEN) Documentation saved to TERRAFORM.md$(NC)"; \
	else \
		echo "$(RED)terraform-docs not installed. Install from https://terraform-docs.io$(NC)"; \
	fi

clean: ## Clean up temporary files
	@echo "$(YELLOW)Cleaning up...$(NC)"
	@rm -rf .terraform/
	@rm -f tfplan-*
	@rm -f *.tfstate*
	@rm -f terraform-graph-*.png
	@echo "$(GREEN) Cleanup complete$(NC)"

workspace-list: ## List Terraform workspaces
	@$(TERRAFORM) workspace list

workspace-new: ## Create new workspace (use WORKSPACE=name)
	@if [ -z "$(WORKSPACE)" ]; then \
		echo "$(RED)Please specify WORKSPACE=name$(NC)"; \
		exit 1; \
	fi
	$(TERRAFORM) workspace new $(WORKSPACE)

workspace-select: ## Select workspace (use WORKSPACE=name)
	@if [ -z "$(WORKSPACE)" ]; then \
		echo "$(RED)Please specify WORKSPACE=name$(NC)"; \
		exit 1; \
	fi
	$(TERRAFORM) workspace select $(WORKSPACE)

import: ## Import existing resource (use RESOURCE=type.name ID=resource-id)
	@if [ -z "$(RESOURCE)" ] || [ -z "$(ID)" ]; then \
		echo "$(RED)Usage: make import RESOURCE=aws_instance.example ID=i-1234567890$(NC)"; \
		exit 1; \
	fi
	$(TERRAFORM) import $(TF_VARS) $(RESOURCE) $(ID)

state-mv: ## Move resource in state (use FROM=old.name TO=new.name)
	@if [ -z "$(FROM)" ] || [ -z "$(TO)" ]; then \
		echo "$(RED)Usage: make state-mv FROM=old.resource TO=new.resource$(NC)"; \
		exit 1; \
	fi
	$(TERRAFORM) state mv $(FROM) $(TO)

state-rm: ## Remove resource from state (use RESOURCE=type.name)
	@if [ -z "$(RESOURCE)" ]; then \
		echo "$(RED)Usage: make state-rm RESOURCE=aws_instance.example$(NC)"; \
		exit 1; \
	fi
	@echo "$(RED)WARNING: Removing $(RESOURCE) from state$(NC)"
	@read -p "Are you sure? [y/N]: " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		$(TERRAFORM) state rm $(RESOURCE); \
	fi

unlock: ## Force unlock state (use LOCK_ID=xxx)
	@if [ -z "$(LOCK_ID)" ]; then \
		echo "$(RED)Usage: make unlock LOCK_ID=xxx$(NC)"; \
		exit 1; \
	fi
	$(TERRAFORM) force-unlock $(LOCK_ID)

console: ## Open Terraform console
	$(TERRAFORM) console $(TF_VARS)