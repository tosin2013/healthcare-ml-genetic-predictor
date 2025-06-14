#!/bin/bash

# Test script for Issue #13 - Testing API for Scaling Mode Validation
# This script validates all REST API endpoints locally before OpenShift deployment

set -e

API_BASE="http://localhost:8080/api"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TEST_LOG="test-results-${TIMESTAMP}.log"

echo "🧪 Testing API Endpoints for Issue #13 - $(date)" | tee $TEST_LOG
echo "=================================================" | tee -a $TEST_LOG
echo "" | tee -a $TEST_LOG

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test function
test_endpoint() {
    local method=$1
    local endpoint=$2
    local data=$3
    local description=$4
    
    echo -e "${BLUE}Testing: $description${NC}" | tee -a $TEST_LOG
    echo "  Method: $method" | tee -a $TEST_LOG
    echo "  Endpoint: $endpoint" | tee -a $TEST_LOG
    
    if [ -n "$data" ]; then
        echo "  Data: $data" | tee -a $TEST_LOG
        response=$(curl -s -X $method "$API_BASE$endpoint" \
            -H "Content-Type: application/json" \
            -d "$data" || echo "ERROR")
    else
        response=$(curl -s -X $method "$API_BASE$endpoint" || echo "ERROR")
    fi
    
    if [[ "$response" == "ERROR" ]]; then
        echo -e "  ${RED}❌ FAILED${NC}" | tee -a $TEST_LOG
        return 1
    elif echo "$response" | grep -q '"status":"success"'; then
        echo -e "  ${GREEN}✅ SUCCESS${NC}" | tee -a $TEST_LOG
        echo "  Response: $response" | tee -a $TEST_LOG
    elif echo "$response" | grep -q '"status":"error"'; then
        echo -e "  ${YELLOW}⚠️  API ERROR${NC}" | tee -a $TEST_LOG
        echo "  Response: $response" | tee -a $TEST_LOG
        return 1
    else
        echo -e "  ${GREEN}✅ SUCCESS${NC}" | tee -a $TEST_LOG
        echo "  Response: $response" | tee -a $TEST_LOG
    fi
    
    echo "" | tee -a $TEST_LOG
    return 0
}

# Test counter
total_tests=0
passed_tests=0

# Test 1: Health Check
total_tests=$((total_tests + 1))
if test_endpoint "GET" "/scaling/health" "" "Health Check Endpoint"; then
    passed_tests=$((passed_tests + 1))
fi

# Test 2: Set Normal Mode
total_tests=$((total_tests + 1))
if test_endpoint "POST" "/scaling/mode" '{"mode": "normal", "description": "Testing normal mode for pod scaling"}' "Set Normal Scaling Mode"; then
    passed_tests=$((passed_tests + 1))
fi

# Test 3: Set Big Data Mode
total_tests=$((total_tests + 1))
if test_endpoint "POST" "/scaling/mode" '{"mode": "bigdata", "description": "Testing big data mode for node scaling"}' "Set Big Data Scaling Mode"; then
    passed_tests=$((passed_tests + 1))
fi

# Test 4: Analyze Small Genetic Sequence
total_tests=$((total_tests + 1))
if test_endpoint "POST" "/genetic/analyze" '{"sequence": "ATCGATCGATCGATCGATCG", "resourceProfile": "standard"}' "Analyze Small Genetic Sequence"; then
    passed_tests=$((passed_tests + 1))
fi

# Test 5: Analyze Large Genetic Sequence
large_sequence=$(printf 'A%.0s' {1..1000})  # 1KB sequence
total_tests=$((total_tests + 1))
if test_endpoint "POST" "/genetic/analyze" "{\"sequence\": \"$large_sequence\", \"resourceProfile\": \"high-memory\"}" "Analyze Large Genetic Sequence (1KB)"; then
    passed_tests=$((passed_tests + 1))
fi

# Test 6: Trigger Pod Scaling Demo
total_tests=$((total_tests + 1))
if test_endpoint "POST" "/scaling/trigger-demo" '{"demoType": "pod-scaling", "sequenceCount": 2, "sequenceSize": "1kb"}' "Trigger Pod Scaling Demo"; then
    passed_tests=$((passed_tests + 1))
fi

# Test 7: Trigger Node Scaling Demo
total_tests=$((total_tests + 1))
if test_endpoint "POST" "/scaling/trigger-demo" '{"demoType": "node-scaling", "sequenceCount": 3, "sequenceSize": "100kb"}' "Trigger Node Scaling Demo"; then
    passed_tests=$((passed_tests + 1))
fi

# Test 8: Get Scaling Status
total_tests=$((total_tests + 1))
if test_endpoint "GET" "/scaling/status/test-tracking-id-123" "" "Get Scaling Status"; then
    passed_tests=$((passed_tests + 1))
fi

# Test 9: Invalid Mode Test (should fail gracefully)
total_tests=$((total_tests + 1))
echo -e "${BLUE}Testing: Invalid Mode Validation (should return error)${NC}" | tee -a $TEST_LOG
response=$(curl -s -X POST "$API_BASE/scaling/mode" \
    -H "Content-Type: application/json" \
    -d '{"mode": "invalid", "description": "Testing invalid mode"}' || echo "ERROR")

if echo "$response" | grep -q '"status":"error"' || echo "$response" | grep -q "validation" || echo "$response" | grep -q "Constraint Violation"; then
    echo -e "  ${GREEN}✅ SUCCESS (Validation working)${NC}" | tee -a $TEST_LOG
    passed_tests=$((passed_tests + 1))
else
    echo -e "  ${RED}❌ FAILED (Should reject invalid mode)${NC}" | tee -a $TEST_LOG
fi
echo "  Response: $response" | tee -a $TEST_LOG
echo "" | tee -a $TEST_LOG

# Summary
echo "=================================================" | tee -a $TEST_LOG
echo -e "${BLUE}Test Summary:${NC}" | tee -a $TEST_LOG
echo "  Total Tests: $total_tests" | tee -a $TEST_LOG
echo "  Passed: $passed_tests" | tee -a $TEST_LOG
echo "  Failed: $((total_tests - passed_tests))" | tee -a $TEST_LOG

if [ $passed_tests -eq $total_tests ]; then
    echo -e "  ${GREEN}🎉 ALL TESTS PASSED!${NC}" | tee -a $TEST_LOG
    echo "" | tee -a $TEST_LOG
    echo -e "${GREEN}✅ Issue #13 API Implementation: VALIDATED${NC}" | tee -a $TEST_LOG
    echo -e "${GREEN}✅ Ready for OpenShift deployment${NC}" | tee -a $TEST_LOG
    exit 0
else
    echo -e "  ${RED}❌ SOME TESTS FAILED${NC}" | tee -a $TEST_LOG
    echo -e "  ${YELLOW}⚠️  Review failed tests before OpenShift deployment${NC}" | tee -a $TEST_LOG
    exit 1
fi
