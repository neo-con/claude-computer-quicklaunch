#!/bin/bash
# Author: Neil Concepcion
# Github: https://github.com/neo-con
# GenAI Assist: Claude 3.5 Sonnet

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Global variables
PROJECT_DIR="anthropic-demo"

# Basic utility functions
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Docker operations function
# Docker operations function
docker_operations() {
    local operation=$1
    
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}Docker daemon is not running. Please start Docker first.${NC}"
        return 1
    fi

    if [ "$operation" = "remove" ] || [ "$operation" = "restart" ]; then
        if docker ps -a | grep -q "anthropic-demo"; then
            echo -e "Removing existing container..."
            docker rm -f anthropic-demo >/dev/null 2>&1
        fi
    fi

    if [ "$operation" = "start" ] || [ "$operation" = "restart" ]; then
        if [ -f "$HOME/.anthropic/api_key" ]; then
            export ANTHROPIC_API_KEY=$(cat ~/.anthropic/api_key)
            docker run \
                -e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \
                -v $HOME/.anthropic:/home/computeruse/.anthropic \
                -p 5900:5900 -p 8501:8501 -p 6080:6080 -p 8080:8080 \
                --name anthropic-demo \
                --restart unless-stopped \
                -d ghcr.io/anthropics/anthropic-quickstarts:computer-use-demo-latest
            return 0
        else
            echo -e "${RED}API key not found. Please run the full setup.${NC}"
            return 1
        fi
    fi
}

# Service check function
check_service() {
    local max_attempts=30
    local attempt=1
    local wait_time=2
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:8080 >/dev/null; then
            echo -e "${GREEN}Service is ready!${NC}"
            return 0
        fi
        attempt=$((attempt + 1))
        sleep $wait_time
    done
    
    echo -e "${RED}Service failed to start within the expected time.${NC}"
    echo -e "${YELLOW}Checking container logs for potential issues:${NC}"
    docker logs anthropic-demo
    return 1
}

# Browser opening function
open_browser() {
    if command_exists xdg-open; then
        xdg-open http://localhost:8080
    elif command_exists open; then
        open http://localhost:8080
    else
        echo -e "${YELLOW}Please open http://localhost:8080 in your browser${NC}"
    fi
}

# Dependency installation function
install_dependency() {
    local dep_name=$1
    local install_cmd=$2
    
    echo -e "${YELLOW}${dep_name} is not installed. Would you like to install it? (y/n)${NC}"
    read -r install_choice
    if [[ "$install_choice" =~ ^[Yy]$ ]]; then
        eval "$install_cmd"
        echo -e "${GREEN}${dep_name} installed successfully!${NC}"
        return 0
    else
        echo -e "${RED}${dep_name} is required for this setup. Exiting.${NC}"
        return 1
    fi
}

# Cleanup function
cleanup_existing() {
    echo -e "${YELLOW}Existing installation detected.${NC}"
    echo -e "Choose an option:"
    echo -e "1) Remove existing installation and start fresh"
    echo -e "2) Keep existing installation and exit"
    echo -e "3) Keep existing installation but restart container"
    read -p "Enter choice [1-3]: " choice

    case $choice in
        1)
            echo -e "${YELLOW}Removing existing installation...${NC}"
            docker_operations remove
            rm -rf "$PROJECT_DIR" "anthropic-quickstarts"
            echo -e "${GREEN}Cleanup complete. Starting fresh installation...${NC}"
            ;;
        2)
            echo -e "${YELLOW}Exiting without changes.${NC}"
            exit 0
            ;;
        3)
            echo -e "${YELLOW}Restarting container...${NC}"
            if docker_operations restart; then
                if check_service; then
                    open_browser
                fi
                echo -e "${GREEN}Container restarted! The application should be running at http://localhost:8080${NC}"
            fi
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Exiting.${NC}"
            exit 1
            ;;
    esac
}

# Setup API key function
setup_api_key() {
    cat > setup_api_key.py << 'EOF'
import os
from pathlib import Path
import getpass
import stat

def setup_api_key():
    api_key = getpass.getpass("Please enter your Anthropic API key: ")
    
    anthropic_dir = Path.home() / '.anthropic'
    anthropic_dir.mkdir(exist_ok=True)
    
    api_key_file = anthropic_dir / 'api_key'
    with open(api_key_file, 'w') as f:
        f.write(api_key)
    
    os.chmod(api_key_file, stat.S_IRUSR | stat.S_IWUSR)
    os.chmod(anthropic_dir, stat.S_IRUSR | stat.S_IWUSR | stat.S_IXUSR)
    
    return api_key

if __name__ == "__main__":
    api_key = setup_api_key()
    print("API key saved successfully!")
EOF

    chmod 700 setup_api_key.py
    pipenv run python setup_api_key.py
}

# Main setup function
main_setup() {
    echo -e "${GREEN}Starting Anthropic QuickStart Setup...${NC}"

    # Check dependencies
    if ! command_exists python3; then
        echo -e "${RED}Python 3 is not installed. Please install Python 3 first.${NC}"
        exit 1
    fi

    if ! command_exists pip3; then
        echo -e "${RED}pip3 is not installed. Please install pip3 first.${NC}"
        exit 1
    fi

    # Install Docker if needed
    if ! command_exists docker; then
        install_dependency "Docker" "sudo apt-get update && sudo apt-get install -y docker.io && sudo systemctl start docker && sudo systemctl enable docker && sudo usermod -aG docker $USER"
    fi

    # Install Git if needed
    if ! command_exists git; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            install_dependency "Git" "brew install git"
        elif command_exists apt-get; then
            install_dependency "Git" "sudo apt-get update && sudo apt-get install -y git"
        elif command_exists yum; then
            install_dependency "Git" "sudo yum install -y git"
        else
            echo -e "${RED}Could not detect package manager. Please install Git manually.${NC}"
            exit 1
        fi
    fi

    # Install pipenv if needed
    if ! command_exists pipenv; then
        echo -e "${YELLOW}Installing pipenv...${NC}"
        pip3 install --user pipenv
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
            export PATH="$HOME/.local/bin:$PATH"
        fi
    fi

    # Check for existing installation
    if [ -d "anthropic-quickstarts" ] || [ -d "$PROJECT_DIR" ]; then
        cleanup_existing
    fi

    # Create project directory and setup
    mkdir -p $PROJECT_DIR
    cd $PROJECT_DIR

    echo -e "${GREEN}Creating virtual environment and installing dependencies...${NC}"
    pipenv --python 3
    pipenv install requests python-dotenv

    echo -e "${GREEN}Cloning specific directory from Anthropic QuickStarts repository...${NC}"
    git clone --filter=blob:none --sparse https://github.com/anthropics/anthropic-quickstarts.git
    cd anthropic-quickstarts
    git sparse-checkout init --cone
    git sparse-checkout set computer-use-demo
    cd computer-use-demo

    # Setup API key
    setup_api_key

    # Create .gitignore
    echo -e "setup_api_key.py\n.env\n.anthropic" > .gitignore

    # Start Docker container
    echo -e "${GREEN}Starting Docker container...${NC}"
    if docker_operations start; then
        echo -e "${YELLOW}Waiting for service to become ready...${NC}"
        if check_service; then
            open_browser
        fi
    fi

    echo -e "${GREEN}Setup complete! The application should be running at http://localhost:8080${NC}"
}

# Execute main setup
main_setup