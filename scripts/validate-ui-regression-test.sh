#!/bin/bash

# Validate UI Regression Test Setup
# 
# This script validates that the UI regression test can run successfully
# and helps debug any issues before running in GitHub Actions.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UI_REGRESSION_TEST="$SCRIPT_DIR/test-ui-regression.js"
WEBSOCKET_CLIENT="$SCRIPT_DIR/test-websocket-client.js"
SEQUENCE_GENERATOR="$SCRIPT_DIR/generate-genetic-sequence.js"

# Default settings
BASE_URL="https://quarkus-websocket-service-healthcare-ml-demo.apps.b9892ub1.eastus.aroapp.io"
TIMEOUT=60
TEST_MODE="normal"

# Function to print colored output
print_header() {
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}$(echo "$1" | sed 's/./=/g')${NC}"
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

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --help, -h          Show this help message"
    echo "  --url <url>         Base URL for testing (default: production)"
    echo "  --timeout <sec>     Timeout for tests (default: 60)"
    echo "  --mode <mode>       Test mode (normal|big-data|node-scale|kafka-lag|all)"
    echo "  --quick             Quick validation with normal mode only"
    echo "  --full              Full regression test (all modes)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Quick validation"
    echo "  $0 --full                             # Full regression test"
    echo "  $0 --mode kafka-lag                   # Test specific mode"
    echo "  $0 --url http://localhost:8080        # Test local deployment"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_usage
            exit 0
            ;;
        --url)
            BASE_URL="$2"
            shift 2
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --mode)
            TEST_MODE="$2"
            shift 2
            ;;
        --quick)
            TEST_MODE="normal"
            TIMEOUT=30
            shift
            ;;
        --full)
            TEST_MODE="all"
            TIMEOUT=120
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main validation
print_header "UI Regression Test Validation"
echo "Base URL: $BASE_URL"
echo "Test Mode: $TEST_MODE"
echo "Timeout: $TIMEOUT seconds"
echo ""

# Check prerequisites
print_info "Checking prerequisites..."

if ! command -v node &> /dev/null; then
    print_error "Node.js is required but not installed"
    exit 1
fi

if ! npm list ws &> /dev/null; then
    print_warning "WebSocket library not found, installing..."
    npm install ws
fi

# Check required files
for file in "$UI_REGRESSION_TEST" "$WEBSOCKET_CLIENT" "$SEQUENCE_GENERATOR"; do
    if [ ! -f "$file" ]; then
        print_error "Required file not found: $file"
        exit 1
    fi
done

print_success "Prerequisites check passed"
echo ""

# Test connectivity
print_info "Testing connectivity to healthcare dashboard..."

if curl -f -s --max-time 30 "${BASE_URL}/genetic-client.html" > /dev/null; then
    print_success "Healthcare dashboard is accessible"
else
    print_error "Healthcare dashboard is not accessible at ${BASE_URL}"
    print_info "Please check if the application is deployed and running"
    exit 1
fi

if curl -f -s --max-time 10 "${BASE_URL}/q/health" > /dev/null; then
    print_success "Health endpoint is responding"
else
    print_warning "Health endpoint not responding (may be normal)"
fi

echo ""

# Run the test
print_info "Running UI regression test..."
echo ""

if [ "$TEST_MODE" = "all" ]; then
    print_info "Running full regression test suite..."
    if node "$UI_REGRESSION_TEST" "$BASE_URL" "$TIMEOUT"; then
        print_success "Full regression test passed!"
        exit 0
    else
        print_error "Full regression test failed!"
        exit 1
    fi
else
    print_info "Running single mode test: $TEST_MODE"
    if node "$WEBSOCKET_CLIENT" "$TEST_MODE" --generate "$TIMEOUT"; then
        print_success "Single mode test passed!"
        exit 0
    else
        print_error "Single mode test failed!"
        exit 1
    fi
fi
