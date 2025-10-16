#!/usr/bin/env python3

import os
from pathlib import Path

def create_project_structure():
    """
    Initialize the project directory structure.
    """
    
    base_dir = Path.cwd()
    
    # Define the directory structure
    directories = [
        # GitHub/Git stuff
        ".github/workflows",
        ".github/ISSUE_TEMPLATE",
        
        # Infrastructure
        "infrastructure/terraform/modules/vpc",
        "infrastructure/terraform/modules/eks",
        "infrastructure/terraform/modules/s3",
        "infrastructure/terraform/modules/rds",
        "infrastructure/terraform/environments/dev",
        "infrastructure/terraform/environments/staging",
        "infrastructure/terraform/environments/prod",
        
        "infrastructure/ansible/playbooks",
        "infrastructure/ansible/roles/carla/tasks",
        "infrastructure/ansible/roles/docker/tasks",
        "infrastructure/ansible/inventories/dev",
        "infrastructure/ansible/inventories/prod",
        
        "infrastructure/kubernetes/base",
        "infrastructure/kubernetes/overlays/dev",
        "infrastructure/kubernetes/overlays/prod",
        "infrastructure/helm-charts/carla-simulator/templates",
        
        # CI/CD
        "pipelines/jenkins",
        "pipelines/gitlab",
        "pipelines/scripts",
        
        # Application source
        "src/simulator",
        "src/data_processor", 
        "src/ml_pipeline",
        "src/api",
        "src/common",
        
        # Monitoring
        "monitoring/prometheus",
        "monitoring/grafana/dashboards",
        "monitoring/alerts",
        
        # Testing
        "tests/unit",
        "tests/integration",
        "tests/e2e",
        "tests/fixtures",
        
        # Documentation
        "docs/architecture",
        "docs/setup",
        "docs/api",
        "docs/runbooks",
        
        # Docker
        "docker/carla",
        "docker/processor",
        
        # Configs
        "configs/environments",
        
        # Data directories
        "data/raw",
        "data/processed",
        "data/synthetic",
        
        # Models
        "models/checkpoints",
        "models/exports",
        
        # Scripts & tools
        "scripts",
        "tools",
        
        # Notebooks for experimentation
        "notebooks"
    ]
    
    # Create all directories
    for dir_path in directories:
        full_path = base_dir / dir_path
        full_path.mkdir(parents=True, exist_ok=True)
        
        # Add .gitkeep for empty dirs that should be tracked
        if dir_path.startswith(("data/", "models/")):
            gitkeep = full_path / ".gitkeep"
            gitkeep.touch()
    
    print(f"Created project structure at: {base_dir.absolute()}")
    print(f"Total directories created: {len(directories)}")
    
    # essential empty files
    essential_files = [
        "__init__.py",  
        "README.md",
        ".gitignore",
        "Makefile",
        "requirements.txt",
        "docker-compose.yml",
        ".env.example"
    ]
    
    # Add __init__.py to Python packages
    python_packages = [
        "src",
        "src/simulator",
        "src/data_processor",
        "src/ml_pipeline",
        "src/api",
        "src/common",
        "tests"
    ]
    
    for package in python_packages:
        init_file = base_dir / package / "__init__.py"
        init_file.touch()
    
    # Create root files
    root_files = ["README.md", ".gitignore", "Makefile", "requirements.txt", 
                  "docker-compose.yml", ".env.example", "setup.py"]
    
    for file_name in root_files:
        file_path = base_dir / file_name
        file_path.touch()
    
    print("Created essential files")
    
    return base_dir

if __name__ == "__main__":
    project_dir = create_project_structure()
    print(f"\nProject initialized successfully")
