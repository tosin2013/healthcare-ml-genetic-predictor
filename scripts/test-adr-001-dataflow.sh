#!/bin/bash

# Test Script for ADR-001 Data Flow Validation
# Validates the corrected WebSocket + VEP service architecture

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

echo "🧪 Testing ADR-001 Implementation - Service Separation"
echo "======================================================"

# Test 1: Check if Kafka is running
print_status "1. Checking Kafka availability..."
if podman exec test-kafka kafka-topics --list --bootstrap-server localhost:9092 > /dev/null 2>&1; then
    print_success "Kafka is running and accessible"
else
    print_error "Kafka is not running. Run './scripts/test-local-setup.sh' first"
    exit 1
fi

# Test 2: Check if topics exist
print_status "2. Verifying Kafka topics..."
TOPICS=$(podman exec test-kafka kafka-topics --list --bootstrap-server localhost:9092)
if echo "$TOPICS" | grep -q "genetic-data-raw"; then
    print_success "genetic-data-raw topic exists"
else
    print_error "genetic-data-raw topic missing"
    exit 1
fi

if echo "$TOPICS" | grep -q "genetic-data-annotated"; then
    print_success "genetic-data-annotated topic exists"
else
    print_error "genetic-data-annotated topic missing"
    exit 1
fi

# Test 3: Check WebSocket service health
print_status "3. Checking WebSocket service health..."
if curl -s http://localhost:8080/q/health > /dev/null 2>&1; then
    print_success "WebSocket service is running on port 8080"
else
    print_warning "WebSocket service not running. Start with: cd quarkus-websocket-service && ./mvnw quarkus:dev -Dquarkus.profile=local"
fi

# Test 4: Check VEP service health
print_status "4. Checking VEP service health..."
if curl -s http://localhost:8081/q/health > /dev/null 2>&1; then
    print_success "VEP service is running on port 8081"
else
    print_warning "VEP service not running. Start with: cd vep-service && ./mvnw quarkus:dev -Dquarkus.profile=local -Dquarkus.http.port=8081"
fi

# Test 5: Test WebSocket endpoint
print_status "5. Testing WebSocket endpoint availability..."
if curl -s http://localhost:8080/genetic-client.html | grep -q "Healthcare ML Genetic Predictor"; then
    print_success "WebSocket UI is accessible"
else
    print_warning "WebSocket UI not accessible"
fi

# Test 6: Monitor Kafka topics for data flow
print_status "6. Setting up Kafka topic monitoring..."

echo ""
echo "🔍 Manual Testing Instructions:"
echo "================================"
echo ""
echo "1. 📱 Open WebSocket UI:"
echo "   http://localhost:8080/genetic-client.html"
echo ""
echo "2. 🔗 Connect to WebSocket service"
echo ""
echo "3. 🧬 Submit a test genetic sequence (e.g., ATCGATCGATCG)"
echo ""
echo "4. 📊 Monitor the data flow:"
echo ""
echo "   Terminal 1 - Raw Data Topic:"
echo "   podman exec test-kafka kafka-console-consumer --topic genetic-data-raw --bootstrap-server localhost:9092 --from-beginning"
echo ""
echo "   Terminal 2 - Annotated Data Topic:"
echo "   podman exec test-kafka kafka-console-consumer --topic genetic-data-annotated --bootstrap-server localhost:9092 --from-beginning"
echo ""
echo "   Terminal 3 - Kafka UI:"
echo "   http://localhost:8090"
echo ""
echo "5. ✅ Expected Data Flow (ADR-001):"
echo "   Step 1: WebSocket receives genetic sequence"
echo "   Step 2: WebSocket publishes to genetic-data-raw topic"
echo "   Step 3: VEP service consumes from genetic-data-raw topic"
echo "   Step 4: VEP service calls Ensembl VEP API"
echo "   Step 5: VEP service publishes to genetic-data-annotated topic"
echo "   Step 6: WebSocket consumes from genetic-data-annotated topic"
echo "   Step 7: WebSocket sends results back to browser"
echo ""
echo "6. 🎯 Success Criteria:"
echo "   ✅ Raw genetic data appears in genetic-data-raw topic"
echo "   ✅ VEP service processes the data (check logs)"
echo "   ✅ Annotated results appear in genetic-data-annotated topic"
echo "   ✅ WebSocket UI displays the VEP annotation results"
echo "   ✅ No VEP processing in WebSocket service logs"
echo "   ✅ No WebSocket handling in VEP service logs"
echo ""

# Test 7: Create a simple automated test
print_status "7. Running automated data flow test..."

# Function to test message flow
test_message_flow() {
    local test_sequence="ATCGATCGATCG"
    
    print_status "Sending test message to genetic-data-raw topic..."
    
    # Create a test CloudEvent message
    local test_message='{
        "specversion": "1.0",
        "type": "com.healthcare.genetic.sequence.raw",
        "source": "/genetic-simulator/test",
        "id": "test-'$(date +%s)'",
        "time": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
        "datacontenttype": "application/json",
        "data": {
            "genetic_sequence": "'$test_sequence'",
            "sessionId": "test-session-'$(date +%s)'",
            "mode": "normal",
            "timestamp": '$(date +%s)'
        }
    }'
    
    # Send message to Kafka
    echo "$test_message" | podman exec -i test-kafka kafka-console-producer --topic genetic-data-raw --bootstrap-server localhost:9092
    
    print_success "Test message sent to genetic-data-raw topic"
    print_status "Check VEP service logs to see if it processes the message"
    print_status "Check genetic-data-annotated topic for the processed result"
}

# Only run automated test if both services are running
if curl -s http://localhost:8080/q/health > /dev/null 2>&1 && curl -s http://localhost:8081/q/health > /dev/null 2>&1; then
    test_message_flow
else
    print_warning "Skipping automated test - both services need to be running"
fi

echo ""
echo "🏁 ADR-001 Testing Setup Complete!"
echo ""
echo "📋 Next Steps:"
echo "1. Start both services if not already running"
echo "2. Follow the manual testing instructions above"
echo "3. Verify the data flow matches the ADR-001 specification"
echo "4. Check that services are properly separated"
echo ""
echo "🛑 To cleanup: podman-compose -f podman-compose.test.yml down"
