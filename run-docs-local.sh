#!/bin/bash

# Healthcare ML Genetic Predictor - Quick Local Documentation Server
# This script starts the Docusaurus documentation server locally

set -e  # Exit on any error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if we're in the right directory
if [ ! -d "docs-site" ]; then
    echo "docs-site directory not found. Please run this script from the project root."
    exit 1
fi

cd docs-site

# Check if build directory exists
if [ ! -d "build" ]; then
    echo "Build directory not found. Please run './deploy-docs-local.sh' first to build the site."
    exit 1
fi

print_status "Starting local server..."
print_success "Documentation will be available at: http://localhost:3000/healthcare-ml-genetic-predictor/"
print_success "Press Ctrl+C to stop the server"

# Start the server
npm run serve