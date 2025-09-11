#!/bin/bash

# Healthcare ML Genetic Predictor - Local Documentation Deployment Script
# This script builds and serves the Docusaurus documentation site locally

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -d "docs-site" ]; then
    print_error "docs-site directory not found. Please run this script from the project root."
    exit 1
fi

cd docs-site

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed. Please install Node.js 18 or higher."
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    print_error "npm is not installed. Please install npm."
    exit 1
fi

print_status "Installing dependencies..."
npm ci

print_status "Building documentation site..."
npm run build

print_status "Starting local server..."
print_warning "If port 3000 is busy, the server will automatically use another port."
print_success "Documentation will be available at: http://localhost:3000/healthcare-ml-genetic-predictor/"
print_success "Press Ctrl+C to stop the server"

# Start the server with proper base URL handling
npm run serve -- --port 3000 --host 0.0.0.0