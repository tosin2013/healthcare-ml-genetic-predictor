#!/bin/bash

# VEP Service Threading Local Testing Script
# Addresses GitHub Issue: VEP Service Threading Issues Blocking KEDA Scaling
# Related to Issues #11, #12 (Containerized Local Testing)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 VEP Service Threading Local Testing${NC}"
echo "========================================"
echo "Purpose: Debug threading issues in controlled local environment"
echo "Related Issues: #11, #12 (Containerized Local Testing)"
echo ""

# Configuration
VEP_SERVICE_DIR="/home/azure/edge-project/vep-service"
CONTAINER_NAME="vep-service-test"
KAFKA_CONTAINER="kafka-test"
NETWORK_NAME="healthcare-ml-test"

# Function to check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}📋 Checking Prerequisites${NC}"
    
    # Check Podman
    if ! command -v podman &> /dev/null; then
        echo -e "${RED}❌ Podman not found. Please install Podman.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Podman available: $(podman --version)${NC}"
    
    # Check Java
    if ! command -v java &> /dev/null; then
        echo -e "${RED}❌ Java not found. Please install Java 17+.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Java available: $(java -version 2>&1 | head -1)${NC}"
    
    # Check Maven
    if ! command -v mvn &> /dev/null; then
        echo -e "${RED}❌ Maven not found. Please install Maven.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Maven available: $(mvn -version | head -1)${NC}"
    
    echo ""
}

# Function to create Podman network
create_network() {
    echo -e "${YELLOW}🌐 Creating Podman Network${NC}"
    
    # Remove existing network if it exists
    podman network rm $NETWORK_NAME 2>/dev/null || true
    
    # Create new network
    podman network create $NETWORK_NAME
    echo -e "${GREEN}✅ Network '$NETWORK_NAME' created${NC}"
    echo ""
}

# Function to start local Kafka for testing
start_kafka() {
    echo -e "${YELLOW}🚀 Starting Local Kafka${NC}"

    # For now, skip Kafka container and use embedded testing
    echo "Note: Using Quarkus dev mode with embedded testing instead of external Kafka"
    echo "This allows us to focus on threading issues without Kafka complexity"

    echo -e "${GREEN}✅ Kafka setup configured for embedded testing${NC}"
    echo ""
}

# Function to build VEP service locally
build_vep_service() {
    echo -e "${YELLOW}🔧 Building VEP Service Locally${NC}"
    
    cd $VEP_SERVICE_DIR
    
    # Clean and compile
    echo "Cleaning and compiling..."
    ./mvnw clean compile -q
    
    echo -e "${GREEN}✅ VEP service compiled successfully${NC}"
    echo ""
}

# Function to test threading models
test_threading_models() {
    echo -e "${YELLOW}🧵 Testing Threading Models${NC}"
    
    cd $VEP_SERVICE_DIR
    
    echo "1. Testing current reactive approach..."
    echo "   Starting Quarkus in dev mode for threading analysis..."
    
    # Start Quarkus in dev mode with threading analysis
    echo "Starting VEP service in dev mode..."
    echo "Use Ctrl+C to stop and analyze threading behavior"
    echo ""
    echo -e "${PURPLE}📊 Monitor for threading errors:${NC}"
    echo "   - Look for 'vert.x-eventloop-thread' errors"
    echo "   - Check if @Blocking annotations work"
    echo "   - Validate Uni<String> reactive processing"
    echo ""
    
    # Set environment for local testing (use test profile to avoid Kafka)
    export QUARKUS_PROFILE="test"

    echo -e "${BLUE}Starting VEP service in test mode to debug threading...${NC}"
    echo "This will use in-memory messaging to isolate threading issues"
    echo ""

    # Start in dev mode with test profile
    ./mvnw quarkus:dev -Dquarkus.profile=test
}

# Function to create test messages
create_test_messages() {
    echo -e "${YELLOW}📨 Creating Test Messages${NC}"

    # Create simple test CloudEvent
    cat > test-cloudevent.json << EOF
{
    "specversion": "1.0",
    "type": "com.redhat.healthcare.genetic.sequence.raw",
    "source": "local-test",
    "id": "test-$(date +%s)",
    "time": "$(date -Iseconds)",
    "datacontenttype": "application/json",
    "data": {
        "sessionId": "local-test-session",
        "genetic_sequence": "ATCGATCGATCGATCGATCG",
        "processing_mode": "test"
    }
}
EOF

    # Create large sequence test (100KB) for node scaling simulation
    LARGE_SEQUENCE=$(printf 'ATCG%.0s' {1..25000})  # 100KB sequence
    cat > test-large-sequence.json << EOF
{
    "specversion": "1.0",
    "type": "com.redhat.healthcare.genetic.sequence.nodescale",
    "source": "local-test",
    "id": "test-large-$(date +%s)",
    "time": "$(date -Iseconds)",
    "datacontenttype": "application/json",
    "data": {
        "sessionId": "local-test-large-session",
        "genetic_sequence": "$LARGE_SEQUENCE",
        "processing_mode": "node-scale"
    }
}
EOF

    echo -e "${GREEN}✅ Test CloudEvents created:${NC}"
    echo "   - test-cloudevent.json (normal sequence)"
    echo "   - test-large-sequence.json (100KB sequence for node scaling)"
    echo ""
}

# Function to cleanup
cleanup() {
    echo -e "${YELLOW}🧹 Cleaning Up${NC}"
    
    # Stop containers
    podman stop $KAFKA_CONTAINER 2>/dev/null || true
    podman stop $CONTAINER_NAME 2>/dev/null || true
    
    # Remove containers
    podman rm $KAFKA_CONTAINER 2>/dev/null || true
    podman rm $CONTAINER_NAME 2>/dev/null || true
    
    # Remove network
    podman network rm $NETWORK_NAME 2>/dev/null || true
    
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  setup     - Set up local testing environment"
    echo "  test      - Run threading tests"
    echo "  cleanup   - Clean up containers and networks"
    echo "  help      - Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 setup    # Set up environment"
    echo "  $0 test     # Run tests"
    echo "  $0 cleanup  # Clean up"
}

# Main execution
case "${1:-help}" in
    setup)
        check_prerequisites
        create_network
        start_kafka
        build_vep_service
        create_test_messages
        echo -e "${GREEN}🎉 Local testing environment ready!${NC}"
        echo "Next: Run '$0 test' to start threading tests"
        ;;
    test)
        echo -e "${BLUE}🧪 Starting Threading Tests${NC}"
        test_threading_models
        ;;
    cleanup)
        cleanup
        ;;
    help|*)
        show_usage
        ;;
esac
