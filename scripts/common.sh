#!/usr/bin/env bash
# Common functions for BMO Stack bootstrap scripts

# Print a section header
print_header() {
    echo "=== $1 ==="
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Error: Docker is not installed. Please install Docker."
        return 1
    fi
}

# Check if Docker Compose (v2) is available
check_docker_compose() {
    if ! docker compose version &> /dev/null; then
        echo "Error: Docker Compose v2 is not available. Please ensure Docker Desktop is up to date or install the Docker Compose plugin."
        return 1
    fi
}

# Check if OpenClaw is installed on the host
check_openclaw() {
    if [ ! -d "$HOME/.openclaw" ]; then
        echo "Warning: OpenClaw directory not found at $HOME/.openclaw"
        echo "Please install OpenClaw on your host machine first."
        echo "See: https://docs.openclaw.ai"
        return 1
    else
        echo "OpenClaw directory found at $HOME/.openclaw"
        return 0
    fi
}

# Check if context files are present in the current directory
check_context() {
    if [ ! -f "./context/BOOTSTRAP.md" ]; then
        echo "Error: Context files are missing. Please ensure you are in the bmo-stack directory."
        return 1
    fi
    echo "Context files present."
    return 0
}

# Copy .env.example to .env if it doesn't exist
create_env_if_missing() {
    if [ ! -f ./.env ]; then
        if [ -f ./.env.example ]; then
            cp ./.env.example ./.env
            echo "Created .env from .env.example. Please edit it to add your API keys."
        else
            echo "Error: .env.example not found."
            return 1
        fi
    else
        echo ".env already exists. Skipping copy."
    fi
    return 0
}

# Run the common bootstrap steps (checks and setup)
run_bootstrap() {
    print_header "BMO Stack Bootstrap"

    # Check prerequisites
    check_docker || return 1
    check_docker_compose || return 1
    check_openclaw || return 1
    check_context || return 1

    # Setup environment
    create_env_if_missing || return 1
}