#!/bin/bash
# Author: Neil Concepcion
# Github: https://github.com/neo-con
# GenAI Assist: Claude 3.5 Sonnet


# setup.sh
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo -e "${GREEN}Starting Anthropic QuickStart Setup...${NC}"

# Check for Python installation
if ! command_exists python3; then
    echo -e "${RED}Python 3 is not installed. Please install Python 3 first.${NC}"
    exit 1
fi

# Check for pip
if ! command_exists pip3; then
    echo -e "${RED}pip3 is not installed. Please install pip3 first.${NC}"
    exit 1
fi

# Check for Docker
if ! command_exists docker; then
    echo -e "${YELLOW}Docker is not installed. Would you like to install it? (y/n)${NC}"
    read -r install_docker
    if [[ "$install_docker" =~ ^[Yy]$ ]]; then
        # Install Docker (this is for Ubuntu/Debian - modify for other OS)
        sudo apt-get update
        sudo apt-get install -y docker.io
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker $USER
        echo -e "${GREEN}Docker installed successfully. Please log out and back in for changes to take effect.${NC}"
    else
        echo -e "${RED}Docker is required for this setup. Exiting.${NC}"
        exit 1
    fi
fi

# Check for Git
if ! command_exists git; then
    echo -e "${YELLOW}Git is not installed. Would you like to install it? (y/n)${NC}"
    read -r install_git
    if [[ "$install_git" =~ ^[Yy]$ ]]; then
        # Detect OS
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if command_exists brew; then
                brew install git
            else
                echo -e "${YELLOW}Homebrew is required to install Git. Installing Homebrew...${NC}"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                brew install git
            fi
        elif command_exists apt-get; then
            # Debian/Ubuntu
            sudo apt-get update
            sudo apt-get install -y git
        elif command_exists yum; then
            # RHEL/CentOS
            sudo yum install -y git
        else
            echo -e "${RED}Could not detect package manager. Please install Git manually.${NC}"
            exit 1
        fi
        echo -e "${GREEN}Git installed successfully!${NC}"
    else
        echo -e "${RED}Git is required for this setup. Exiting.${NC}"
        exit 1
    fi
fi

# Alternative download method if Git installation fails
if ! command_exists git; then
    echo -e "${YELLOW}Attempting alternative download method...${NC}"
    if command_exists curl; then
        mkdir -p anthropic-quickstarts/computer-use-demo
        cd anthropic-quickstarts/computer-use-demo
        curl -L https://github.com/anthropics/anthropic-quickstarts/archive/refs/heads/main.zip -o repo.zip
        unzip repo.zip "anthropic-quickstarts-main/computer-use-demo/*"
        mv anthropic-quickstarts-main/computer-use-demo/* .
        rm -rf anthropic-quickstarts-main repo.zip
    elif command_exists wget; then
        mkdir -p anthropic-quickstarts/computer-use-demo
        cd anthropic-quickstarts/computer-use-demo
        wget https://github.com/anthropics/anthropic-quickstarts/archive/refs/heads/main.zip
        unzip main.zip "anthropic-quickstarts-main/computer-use-demo/*"
        mv anthropic-quickstarts-main/computer-use-demo/* .
        rm -rf anthropic-quickstarts-main main.zip
    else
        echo -e "${RED}Neither Git, curl, nor wget are available. Cannot download repository.${NC}"
        exit 1
    fi
fi


# Install pipenv if not present
if ! command_exists pipenv; then
    echo -e "${YELLOW}Installing pipenv...${NC}"
    pip3 install --user pipenv
    # Add pipenv to PATH if it's not already there
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        export PATH="$HOME/.local/bin:$PATH"
    fi
fi

# Create project directory
PROJECT_DIR="anthropic-demo"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# Initialize pipenv environment and install dependencies
echo -e "${GREEN}Creating virtual environment and installing dependencies...${NC}"
pipenv --python 3
pipenv install requests python-dotenv

# Clone only the computer-use-demo directory
echo -e "${GREEN}Cloning specific directory from Anthropic QuickStarts repository...${NC}"
git clone --filter=blob:none --sparse https://github.com/anthropics/anthropic-quickstarts.git
cd anthropic-quickstarts
git sparse-checkout init --cone
git sparse-checkout set computer-use-demo
cd computer-use-demo

# Create Python script to handle API key
cat > setup_api_key.py << 'EOF'
import os
from pathlib import Path
import getpass
import stat

def setup_api_key():
    api_key = getpass.getpass("Please enter your Anthropic API key: ")
    
    # Create .anthropic directory in home folder
    anthropic_dir = Path.home() / '.anthropic'
    anthropic_dir.mkdir(exist_ok=True)
    
    # Save API key to file
    api_key_file = anthropic_dir / 'api_key'
    with open(api_key_file, 'w') as f:
        f.write(api_key)
    
    # Set file permissions to user read/write only (600)
    os.chmod(api_key_file, stat.S_IRUSR | stat.S_IWUSR)
    
    # Set directory permissions to user read/write/execute only (700)
    os.chmod(anthropic_dir, stat.S_IRUSR | stat.S_IWUSR | stat.S_IXUSR)
    
    return api_key

if __name__ == "__main__":
    api_key = setup_api_key()
    print("API key saved successfully!")
EOF

# Set appropriate permissions for the setup script
chmod 700 setup_api_key.py

# Run API key setup using pipenv
pipenv run python setup_api_key.py

cat > .gitignore << 'EOF'
setup_api_key.py
.env
.anthropic
EOF

# Export API key and run docker container
echo -e "${GREEN}Starting Docker container...${NC}"
export ANTHROPIC_API_KEY=$(cat ~/.anthropic/api_key)
docker run \
    -e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \
    -v $HOME/.anthropic:/home/computeruse/.anthropic \
    -p 5900:5900 \
    -p 8501:8501 \
    -p 6080:6080 \
    -p 8080:8080 \
    -it ghcr.io/anthropics/anthropic-quickstarts:computer-use-demo-latest &

# Wait for container to start
echo -e "${YELLOW}Waiting for services to start...${NC}"
sleep 10

# Open browser (works on most Unix-like systems)
if command_exists xdg-open; then
    xdg-open http://localhost:8080
elif command_exists open; then
    open http://localhost:8080
else
    echo -e "${YELLOW}Please open http://localhost:8080 in your browser${NC}"
fi

echo -e "${GREEN}Setup complete! The application should be running at http://localhost:8080${NC}"
