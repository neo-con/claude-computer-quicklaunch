# Anthropic QuickStart Automation

A streamlined setup script for Anthropic's Computer-Use Demo environment. This script automates the entire setup process, handling all dependencies and configuration automatically.

![Demo](docs/images/demo.gif)

## Features

- 🚀 One-click setup for Anthropic's Computer-Use Demo
- 🔒 Secure API key handling
- 📦 Automatic dependency management
- 🐳 Docker environment configuration
- 💻 Cross-platform support (macOS, Linux)

## Prerequisites - (Any other dependencies will be downloaded via script)

- Python 3.x
- Internet connection
- Anthropic API key

## Quick Start

1. Clone this repository:
```bash
git clone https://github.com/yourusername/anthropic-quickstart-automation.git
```

2. Make the setup script executable:
```bash
chmod +x setup.sh
```

3. Run the setup script:
```bash
./setup.sh
```

4. Enter your Anthropic API key when prompted

5. Access the demo at http://localhost:8080

## What Does It Do?

The setup script automatically:
- Checks and installs required dependencies (Python, Docker, Git)
- Creates a virtual environment using Pipenv
- Securely stores your Anthropic API key
- Downloads and configures the Computer-Use Demo
- Launches the Docker container with all necessary ports
- Opens the demo in your default browser

## Security

- API keys are stored securely with appropriate file permissions
- Environment variables are handled safely
- No sensitive data is logged or exposed

## License

MIT License - See [LICENSE](LICENSE) for details

## Author

Neocodes (@neo-con) - Neil Concepcion
