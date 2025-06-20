#!/bin/bash

# Test All Scaling Modes for Healthcare ML Genetic Analysis
# 
# This script tests all four scaling modes with appropriately sized genetic sequences:
# - Normal Mode: 50 chars (standard pod scaling)
# - Big Data Mode: 100KB (memory-intensive scaling)
# - Node Scale Mode: 1MB (cluster autoscaler)
# - Kafka Lag Mode: 1KB (consumer lag-based scaling)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEBSOCKET_CLIENT="$SCRIPT_DIR/test-websocket-client.js"
SEQUENCE_GENERATOR="$SCRIPT_DIR/generate-genetic-sequence.js"

# Default settings
TIMEOUT_NORMAL=60
TIMEOUT_BIGDATA=120
TIMEOUT_NODESCALE=180
TIMEOUT_KAFKALAG=90
DELAY_BETWEEN_TESTS=10

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

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if ! command -v node &> /dev/null; then
        print_error "Node.js is required but not installed"
        exit 1
    fi
    
    if ! npm list ws &> /dev/null; then
        print_warning "WebSocket library not found, installing..."
        npm install ws
    fi
    
    if [ ! -f "$WEBSOCKET_CLIENT" ]; then
        print_error "WebSocket client script not found: $WEBSOCKET_CLIENT"
        exit 1
    fi
    
    if [ ! -f "$SEQUENCE_GENERATOR" ]; then
        print_error "Sequence generator script not found: $SEQUENCE_GENERATOR"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to test a specific scaling mode
test_scaling_mode() {
    local mode=$1
    local timeout=$2
    local description=$3
    
    print_header "Testing $mode Mode - $description"
    
    print_info "Generating genetic sequence for $mode mode..."
    local sequence=$(node "$SEQUENCE_GENERATOR" "$mode")
    local sequence_length=${#sequence}
    
    print_info "Generated sequence: $sequence_length characters"
    print_info "Starting WebSocket test with ${timeout}s timeout..."
    echo ""
    
    # Run the test
    if node "$WEBSOCKET_CLIENT" "$mode" "$sequence" "$timeout"; then
        print_success "$mode mode test completed successfully"
        return 0
    else
        print_error "$mode mode test failed"
        return 1
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [options] [mode]"
    echo ""
    echo "Options:"
    echo "  --help, -h          Show this help message"
    echo "  --mode <mode>       Test only specific mode (normal|bigdata|node-scale|kafka-lag)"
    echo "  --timeout <sec>     Override default timeout for all tests"
    echo "  --no-delay          Skip delays between tests"
    echo "  --quick             Use shorter timeouts for faster testing"
    echo ""
    echo "Modes:"
    echo "  normal              Test standard pod scaling (50 chars, ${TIMEOUT_NORMAL}s)"
    echo "  bigdata             Test memory-intensive scaling (100KB, ${TIMEOUT_BIGDATA}s)"
    echo "  node-scale          Test cluster autoscaler (1MB, ${TIMEOUT_NODESCALE}s)"
    echo "  kafka-lag           Test consumer lag scaling (1KB, ${TIMEOUT_KAFKALAG}s)"
    echo "  all                 Test all modes sequentially (default)"
    echo ""
    echo "Examples:"
    echo "  $0                          # Test all modes"
    echo "  $0 --mode normal            # Test only normal mode"
    echo "  $0 --mode kafka-lag         # Test only Kafka lag mode"
    echo "  $0 --quick                  # Quick test with shorter timeouts"
    echo "  $0 --timeout 300            # Use 5-minute timeout for all tests"
}

# Parse command line arguments
MODE="all"
CUSTOM_TIMEOUT=""
USE_DELAY=true
QUICK_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_usage
            exit 0
            ;;
        --mode)
            MODE="$2"
            shift 2
            ;;
        --timeout)
            CUSTOM_TIMEOUT="$2"
            shift 2
            ;;
        --no-delay)
            USE_DELAY=false
            shift
            ;;
        --quick)
            QUICK_MODE=true
            TIMEOUT_NORMAL=30
            TIMEOUT_BIGDATA=60
            TIMEOUT_NODESCALE=90
            TIMEOUT_KAFKALAG=45
            DELAY_BETWEEN_TESTS=5
            shift
            ;;
        *)
            if [[ "$1" =~ ^(normal|bigdata|big-data|node-scale|nodescale|kafka-lag|kafkalag|all)$ ]]; then
                MODE="$1"
            else
                print_error "Unknown option: $1"
                show_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Override timeouts if custom timeout specified
if [ -n "$CUSTOM_TIMEOUT" ]; then
    TIMEOUT_NORMAL=$CUSTOM_TIMEOUT
    TIMEOUT_BIGDATA=$CUSTOM_TIMEOUT
    TIMEOUT_NODESCALE=$CUSTOM_TIMEOUT
    TIMEOUT_KAFKALAG=$CUSTOM_TIMEOUT
fi

# Main execution
print_header "Healthcare ML Scaling Mode Test Suite"
echo "Testing mode: $MODE"
echo "Quick mode: $QUICK_MODE"
echo "Use delays: $USE_DELAY"
echo ""

check_prerequisites
echo ""

# Test results tracking
declare -A test_results
total_tests=0
passed_tests=0

# Function to run test and track results
run_test() {
    local mode=$1
    local timeout=$2
    local description=$3
    
    total_tests=$((total_tests + 1))
    
    if test_scaling_mode "$mode" "$timeout" "$description"; then
        test_results["$mode"]="PASSED"
        passed_tests=$((passed_tests + 1))
    else
        test_results["$mode"]="FAILED"
    fi
    
    if [ "$USE_DELAY" = true ] && [ "$total_tests" -lt 4 ]; then
        print_info "Waiting ${DELAY_BETWEEN_TESTS} seconds before next test..."
        sleep $DELAY_BETWEEN_TESTS
        echo ""
    fi
}

# Execute tests based on mode
case "$MODE" in
    normal)
        run_test "normal" "$TIMEOUT_NORMAL" "Standard Pod Scaling"
        ;;
    bigdata|big-data)
        run_test "bigdata" "$TIMEOUT_BIGDATA" "Memory-Intensive Scaling"
        ;;
    node-scale|nodescale)
        run_test "node-scale" "$TIMEOUT_NODESCALE" "Cluster Autoscaler"
        ;;
    kafka-lag|kafkalag)
        run_test "kafka-lag" "$TIMEOUT_KAFKALAG" "Consumer Lag Scaling"
        ;;
    all)
        print_info "Testing all scaling modes sequentially..."
        echo ""
        
        run_test "normal" "$TIMEOUT_NORMAL" "Standard Pod Scaling"
        run_test "bigdata" "$TIMEOUT_BIGDATA" "Memory-Intensive Scaling"
        run_test "node-scale" "$TIMEOUT_NODESCALE" "Cluster Autoscaler"
        run_test "kafka-lag" "$TIMEOUT_KAFKALAG" "Consumer Lag Scaling"
        ;;
    *)
        print_error "Invalid mode: $MODE"
        show_usage
        exit 1
        ;;
esac

# Print final results
print_header "Test Results Summary"
echo "Total tests: $total_tests"
echo "Passed: $passed_tests"
echo "Failed: $((total_tests - passed_tests))"
echo ""

for mode in "${!test_results[@]}"; do
    result="${test_results[$mode]}"
    if [ "$result" = "PASSED" ]; then
        print_success "$mode: $result"
    else
        print_error "$mode: $result"
    fi
done

echo ""
if [ "$passed_tests" -eq "$total_tests" ]; then
    print_success "🎉 All tests passed! Healthcare ML scaling is working correctly."
    exit 0
else
    print_error "❌ Some tests failed. Check the output above for details."
    exit 1
fi
