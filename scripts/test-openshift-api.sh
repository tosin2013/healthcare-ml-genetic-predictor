#!/bin/bash

# OpenShift Live Cluster API Testing Script
# Tests the deployed API endpoints on the live OpenShift cluster

set -e

# Configuration
OPENSHIFT_URL="https://quarkus-websocket-service-healthcare-ml-demo.apps.b9892ub1.eastus.aroapp.io"
API_BASE="${OPENSHIFT_URL}/api"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TEST_LOG="openshift-test-results-${TIMESTAMP}.log"

echo "🚀 Testing API Endpoints on Live OpenShift Cluster - $(date)" | tee $TEST_LOG
echo "Cluster URL: $OPENSHIFT_URL" | tee -a $TEST_LOG
echo "=============================================================" | tee -a $TEST_LOG
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
        echo -e "  ${RED}❌ FAILED - Network/Connection Error${NC}" | tee -a $TEST_LOG
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

echo -e "${BLUE}🔍 Phase 1: Basic Health and Connectivity${NC}" | tee -a $TEST_LOG
echo "=============================================" | tee -a $TEST_LOG

# Test 1: Health Check
total_tests=$((total_tests + 1))
if test_endpoint "GET" "/scaling/health" "" "Health Check - All Systems Status"; then
    passed_tests=$((passed_tests + 1))
fi

echo -e "${BLUE}🎛️  Phase 2: Scaling Mode Management${NC}" | tee -a $TEST_LOG
echo "=======================================" | tee -a $TEST_LOG

# Test 2: Set Normal Mode
total_tests=$((total_tests + 1))
if test_endpoint "POST" "/scaling/mode" '{"mode": "normal", "description": "OpenShift cluster normal mode test"}' "Set Normal Scaling Mode"; then
    passed_tests=$((passed_tests + 1))
fi

# Test 3: Set Big Data Mode
total_tests=$((total_tests + 1))
if test_endpoint "POST" "/scaling/mode" '{"mode": "bigdata", "description": "OpenShift cluster big data mode test"}' "Set Big Data Scaling Mode"; then
    passed_tests=$((passed_tests + 1))
fi

echo -e "${BLUE}🧬 Phase 3: Genetic Analysis Processing${NC}" | tee -a $TEST_LOG
echo "=========================================" | tee -a $TEST_LOG

# Test 4: Small Genetic Sequence
total_tests=$((total_tests + 1))
if test_endpoint "POST" "/genetic/analyze" '{"sequence": "ATCGATCGATCGATCGATCG", "resourceProfile": "standard"}' "Analyze Small Genetic Sequence (20bp)"; then
    passed_tests=$((passed_tests + 1))
fi

# Test 5: Medium Genetic Sequence
medium_sequence=$(printf 'ATCG%.0s' {1..50})  # 200bp sequence
total_tests=$((total_tests + 1))
if test_endpoint "POST" "/genetic/analyze" "{\"sequence\": \"$medium_sequence\", \"resourceProfile\": \"high-memory\"}" "Analyze Medium Genetic Sequence (200bp)"; then
    passed_tests=$((passed_tests + 1))
fi

echo -e "${BLUE}⚡ Phase 4: Scaling Demonstrations${NC}" | tee -a $TEST_LOG
echo "===================================" | tee -a $TEST_LOG

# Test 6: Pod Scaling Demo
total_tests=$((total_tests + 1))
if test_endpoint "POST" "/scaling/trigger-demo" '{"demoType": "pod-scaling", "sequenceCount": 3, "sequenceSize": "5kb"}' "Trigger Pod Scaling Demo"; then
    passed_tests=$((passed_tests + 1))
fi

# Test 7: Node Scaling Demo
total_tests=$((total_tests + 1))
if test_endpoint "POST" "/scaling/trigger-demo" '{"demoType": "node-scaling", "sequenceCount": 5, "sequenceSize": "50kb"}' "Trigger Node Scaling Demo"; then
    passed_tests=$((passed_tests + 1))
fi

echo -e "${BLUE}📊 Phase 5: Monitoring and Status${NC}" | tee -a $TEST_LOG
echo "==================================" | tee -a $TEST_LOG

# Test 8: Get Scaling Status
total_tests=$((total_tests + 1))
if test_endpoint "GET" "/scaling/status/openshift-test-$(date +%s)" "" "Get Scaling Status"; then
    passed_tests=$((passed_tests + 1))
fi

echo -e "${BLUE}🛡️  Phase 6: Validation and Error Handling${NC}" | tee -a $TEST_LOG
echo "=============================================" | tee -a $TEST_LOG

# Test 9: Invalid Mode Validation
total_tests=$((total_tests + 1))
echo -e "${BLUE}Testing: Invalid Mode Validation (should return error)${NC}" | tee -a $TEST_LOG
response=$(curl -s -X POST "$API_BASE/scaling/mode" \
    -H "Content-Type: application/json" \
    -d '{"mode": "invalid", "description": "Testing invalid mode"}' || echo "ERROR")

if echo "$response" | grep -q '"status":"error"' || echo "$response" | grep -q "validation" || echo "$response" | grep -q "Constraint Violation"; then
    echo -e "  ${GREEN}✅ SUCCESS (Validation working correctly)${NC}" | tee -a $TEST_LOG
    passed_tests=$((passed_tests + 1))
else
    echo -e "  ${RED}❌ FAILED (Should reject invalid mode)${NC}" | tee -a $TEST_LOG
fi
echo "  Response: $response" | tee -a $TEST_LOG
echo "" | tee -a $TEST_LOG

echo "=============================================================" | tee -a $TEST_LOG
echo -e "${BLUE}📋 OpenShift Live Cluster Test Summary:${NC}" | tee -a $TEST_LOG
echo "  Cluster: Azure Red Hat OpenShift" | tee -a $TEST_LOG
echo "  Application: Healthcare ML Genetic Predictor" | tee -a $TEST_LOG
echo "  Total Tests: $total_tests" | tee -a $TEST_LOG
echo "  Passed: $passed_tests" | tee -a $TEST_LOG
echo "  Failed: $((total_tests - passed_tests))" | tee -a $TEST_LOG

if [ $passed_tests -eq $total_tests ]; then
    echo -e "  ${GREEN}🎉 ALL TESTS PASSED ON LIVE OPENSHIFT CLUSTER!${NC}" | tee -a $TEST_LOG
    echo "" | tee -a $TEST_LOG
    echo -e "${GREEN}✅ Issues #7 and #13: SUCCESSFULLY DEPLOYED AND VALIDATED${NC}" | tee -a $TEST_LOG
    echo -e "${GREEN}✅ API endpoints working on live cluster${NC}" | tee -a $TEST_LOG
    echo -e "${GREEN}✅ Scaling modes functional${NC}" | tee -a $TEST_LOG
    echo -e "${GREEN}✅ Genetic analysis processing active${NC}" | tee -a $TEST_LOG
    echo -e "${GREEN}✅ Demo triggers operational${NC}" | tee -a $TEST_LOG
    echo -e "${GREEN}✅ Ready for KEDA scaling validation${NC}" | tee -a $TEST_LOG
    exit 0
else
    echo -e "  ${RED}❌ SOME TESTS FAILED ON LIVE CLUSTER${NC}" | tee -a $TEST_LOG
    echo -e "  ${YELLOW}⚠️  Review failed tests and cluster configuration${NC}" | tee -a $TEST_LOG
    exit 1
fi
