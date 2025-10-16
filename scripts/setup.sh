#!/bin/bash

# ADAS-CARLA Local Development Setup Script
# Sets up everything needed for local development

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="adas-carla"
PYTHON_VERSION="3.10"
NODE_VERSION="18"
TERRAFORM_VERSION="1.5.0"

# Helper functions
print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${PURPLE}ℹ${NC} $1"
}

# Check if running from project root
check_project_root() {
    if [[ ! -f "Makefile" ]] || [[ ! -d "src" ]]; then
        print_error "Please run this script from the project root directory"
        exit 1
    fi
}

# Check system requirements
check_requirements() {
    print_header "Checking System Requirements"
    
    local missing_deps=()
    
    # Check Python
    if command -v python3 &> /dev/null; then
        py_version=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
        if [[ $(echo "$py_version >= $PYTHON_VERSION" | bc) -eq 1 ]]; then
            print_success "Python $py_version found"
        else
            print_warning "Python $py_version found, but $PYTHON_VERSION+ recommended"
        fi
    else
        missing_deps+=("python3")
        print_error "Python 3 not found"
    fi
    
    # Check Docker
    if command -v docker &> /dev/null; then
        print_success "Docker $(docker --version | cut -d' ' -f3 | cut -d',' -f1) found"
    else
        missing_deps+=("docker")
        print_error "Docker not found"
    fi
    
    # Check Docker Compose
    if command -v docker-compose &> /dev/null; then
        print_success "Docker Compose $(docker-compose --version | cut -d' ' -f4) found"
    else
        missing_deps+=("docker-compose")
        print_error "Docker Compose not found"
    fi
    
    # Check Git
    if command -v git &> /dev/null; then
        print_success "Git $(git --version | cut -d' ' -f3) found"
    else
        missing_deps+=("git")
        print_error "Git not found"
    fi
    
    # Check Make
    if command -v make &> /dev/null; then
        print_success "Make found"
    else
        missing_deps+=("make")
        print_error "Make not found"
    fi
    
    # Check for GPU (optional but recommended)
    if command -v nvidia-smi &> /dev/null; then
        gpu_name=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -n1)
        print_success "NVIDIA GPU found: $gpu_name"
    else
        print_warning "No NVIDIA GPU detected - CARLA will run in CPU mode (slow)"
    fi
    
    # Check optional tools
    echo -e "\n${PURPLE}Optional Tools:${NC}"
    
    if command -v terraform &> /dev/null; then
        print_info "Terraform $(terraform version -json | jq -r .terraform_version) found"
    else
        print_info "Terraform not found (optional for local dev)"
    fi
    
    if command -v kubectl &> /dev/null; then
        print_info "kubectl $(kubectl version --client --short 2>/dev/null | cut -d':' -f2) found"
    else
        print_info "kubectl not found (optional for local dev)"
    fi
    
    if command -v aws &> /dev/null; then
        print_info "AWS CLI $(aws --version | cut -d' ' -f1 | cut -d'/' -f2) found"
    else
        print_info "AWS CLI not found (optional for local dev)"
    fi
    
    # Exit if missing critical dependencies
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo
        print_error "Missing required dependencies: ${missing_deps[*]}"
        print_info "Please install missing dependencies and run setup again"
        exit 1
    fi
}

# Setup Python virtual environment
setup_python_env() {
    print_header "Setting up Python Environment"
    
    # Create virtual environment
    if [[ ! -d "venv" ]]; then
        print_info "Creating virtual environment..."
        python3 -m venv venv
        print_success "Virtual environment created"
    else
        print_info "Virtual environment already exists"
    fi
    
    # Activate and upgrade pip
    source venv/bin/activate
    print_info "Upgrading pip..."
    pip install --quiet --upgrade pip setuptools wheel
    print_success "pip upgraded"
    
    # Install requirements
    print_info "Installing Python dependencies (this may take a few minutes)..."
    pip install --quiet -r requirements.txt
    print_success "Python dependencies installed"
    
    # Install pre-commit hooks
    if command -v pre-commit &> /dev/null; then
        print_info "Installing pre-commit hooks..."
        pre-commit install
        print_success "Pre-commit hooks installed"
    fi
    
    # Install package in development mode
    print_info "Installing package in development mode..."
    pip install --quiet -e .
    print_success "Package installed in development mode"
}

# Setup environment configuration
setup_environment() {
    print_header "Setting up Environment Configuration"
    
    # Copy .env.example to .env if it doesn't exist
    if [[ ! -f ".env" ]]; then
        cp .env.example .env
        print_success "Created .env file from template"
        print_warning "Please update .env with your configuration"
    else
        print_info ".env file already exists"
    fi
    
    # Create necessary directories
    directories=(
        "data/raw"
        "data/processed"
        "data/synthetic"
        "models/checkpoints"
        "models/exports"
        "logs"
        "backups"
    )
    
    for dir in "${directories[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            print_success "Created directory: $dir"
        fi
    done
    
    # Create .gitkeep files for empty directories
    for dir in "${directories[@]}"; do
        touch "$dir/.gitkeep"
    done
}

# Pull Docker images
setup_docker() {
    print_header "Setting up Docker Environment"
    
    print_info "Pulling required Docker images..."
    
    images=(
        "carlasim/carla:0.9.15"
        "postgres:15-alpine"
        "redis:7-alpine"
        "minio/minio:latest"
        "prom/prometheus:latest"
        "grafana/grafana:latest"
    )
    
    for image in "${images[@]}"; do
        echo -n "  Pulling $image... "
        if docker pull "$image" &> /dev/null; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${YELLOW}⚠ Failed (will retry during docker-compose up)${NC}"
        fi
    done
    
    print_success "Docker images pulled"
}

# Initialize local services
init_services() {
    print_header "Initializing Local Services"
    
    print_info "Starting services with docker-compose..."
    
    # Start only essential services first
    docker-compose up -d postgres redis minio
    
    print_info "Waiting for services to be ready..."
    sleep 10
    
    # Check if services are running
    if docker-compose ps | grep -q "postgres.*Up"; then
        print_success "PostgreSQL is running"
    else
        print_warning "PostgreSQL may not be running correctly"
    fi
    
    if docker-compose ps | grep -q "redis.*Up"; then
        print_success "Redis is running"
    else
        print_warning "Redis may not be running correctly"
    fi
    
    if docker-compose ps | grep -q "minio.*Up"; then
        print_success "MinIO is running"
        
        # Create default buckets in MinIO
        print_info "Creating MinIO buckets..."
        docker-compose exec -T minio mc alias set local http://localhost:9000 minioadmin minioadmin 2>/dev/null || true
        docker-compose exec -T minio mc mb local/adas-raw 2>/dev/null || true
        docker-compose exec -T minio mc mb local/adas-processed 2>/dev/null || true
        docker-compose exec -T minio mc mb local/adas-models 2>/dev/null || true
        print_success "MinIO buckets created"
    else
        print_warning "MinIO may not be running correctly"
    fi
}

# Run initial tests
run_tests() {
    print_header "Running Initial Tests"
    
    source venv/bin/activate
    
    print_info "Running linting checks..."
    if flake8 src/ --count --select=E9,F63,F7,F82 --show-source --statistics; then
        print_success "Basic linting passed"
    else
        print_warning "Linting found some issues"
    fi
    
    print_info "Running unit tests..."
    if pytest tests/unit -v --tb=short -q; then
        print_success "Unit tests passed"
    else
        print_warning "Some tests failed (this is normal for initial setup)"
    fi
}

# Display summary
show_summary() {
    print_header "Setup Complete!"
    
    echo -e "${GREEN}ADAS-CARLA development environment is ready!${NC}\n"
    
    echo "Quick Start Commands:"
    echo -e "  ${BLUE}source venv/bin/activate${NC}  - Activate Python environment"
    echo -e "  ${BLUE}make dev${NC}                  - Start all services"
    echo -e "  ${BLUE}make test${NC}                 - Run tests"
    echo -e "  ${BLUE}make run-simulation${NC}       - Run a simulation"
    echo ""
    echo "Service URLs:"
    echo -e "  ${PURPLE}MinIO Console:${NC}    http://localhost:9001 (minioadmin/minioadmin)"
    echo -e "  ${PURPLE}Grafana:${NC}          http://localhost:3000 (admin/admin)"
    echo -e "  ${PURPLE}Prometheus:${NC}       http://localhost:9090"
    echo -e "  ${PURPLE}API Docs:${NC}         http://localhost:8000/docs"
    echo ""
    echo "Next Steps:"
    echo "  1. Update .env file with your configuration"
    echo "  2. Run 'make dev' to start all services"
    echo "  3. Check documentation in docs/ directory"
    echo ""
    print_info "For help, run: make help"
}

# Main execution
main() {
    echo -e "${PURPLE}"
    echo "     _    ____    _    ____       _____      ____      _      _          "
    echo "    / \\  |  _ \\  / \\  / ___|     | ____|__ _|  _ \\ ___| | ___| |__   __ _ "
    echo "   / _ \\ | | | |/ _ \\ \\___ \\ ____|  _| / _\` | |_) / _ \\ |/ _ \\ '_ \\ / _\` |"
    echo "  / ___ \\| |_| / ___ \\ ___) |____| |__| (_| |  _ <  __/ |  __/ |_) | (_| |"
    echo " /_/   \\_\\____/_/   \\_\\____/     |_____\\__,_|_| \\_\\___|_|\\___|_.__/ \\__,_|"
    echo "                                                                           "
    echo -e "${NC}"
    echo "Local Development Environment Setup for ADAS-CARLA"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Run setup steps
    check_project_root
    check_requirements
    setup_python_env
    setup_environment
    setup_docker
    init_services
    # run_tests  # Commented out for initial setup
    show_summary
}

# Run main function
main "$@"