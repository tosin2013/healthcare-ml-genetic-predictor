#!/bin/bash

# WebSocket Flow Testing Script
# Tests complete end-to-end WebSocket flow with VEP processing
# Usage: ./test-websocket-flow.sh [mode] [timeout]

set -e

# Configuration
MODE=${1:-normal}
TIMEOUT=${2:-120}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="websocket-test-${MODE}-${TIMESTAMP}.log"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧬 WebSocket End-to-End Flow Test${NC}" | tee $LOG_FILE
echo "=======================================" | tee -a $LOG_FILE
echo "Mode: $MODE" | tee -a $LOG_FILE
echo "Timeout: ${TIMEOUT}s" | tee -a $LOG_FILE
echo "Log file: $LOG_FILE" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Check if Node.js is available
if ! command -v node >/dev/null 2>&1; then
    echo -e "${RED}❌ Node.js not found. Installing...${NC}" | tee -a $LOG_FILE

    # Try to install Node.js (this might need adjustment based on the system)
    if command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y nodejs npm
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y nodejs npm
    elif command -v apt >/dev/null 2>&1; then
        sudo apt update && sudo apt install -y nodejs npm
    else
        echo -e "${RED}❌ Cannot install Node.js automatically. Please install manually.${NC}" | tee -a $LOG_FILE
        exit 1
    fi
fi

# Check if ws module is available
if ! node -e "require('ws')" 2>/dev/null; then
    echo -e "${YELLOW}📦 Installing WebSocket module...${NC}" | tee -a $LOG_FILE
    npm install ws
fi

# Generate test sequences based on mode
case $MODE in
    "normal")
        SEQUENCE="ATCGATCGATCGATCGATCG"
        EXPECTED_TOPIC="genetic-data-raw"
        ;;
    "big-data"|"bigdata")
        SEQUENCE=$(printf 'ATCG%.0s' {1..100})  # 400 chars
        EXPECTED_TOPIC="genetic-bigdata-raw"
        MODE="big-data"
        ;;
    "node-scale"|"nodescale")
        SEQUENCE=$(printf 'ATCG%.0s' {1..250})  # 1000 chars
        EXPECTED_TOPIC="genetic-nodescale-raw"
        MODE="node-scale"
        ;;
    *)
        echo -e "${RED}❌ Invalid mode: $MODE${NC}" | tee -a $LOG_FILE
        echo "Valid modes: normal, big-data, node-scale" | tee -a $LOG_FILE
        exit 1
        ;;
esac

echo -e "${PURPLE}🔬 Test Configuration${NC}" | tee -a $LOG_FILE
echo "Sequence length: ${#SEQUENCE} characters" | tee -a $LOG_FILE
echo "Expected Kafka topic: $EXPECTED_TOPIC" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Check baseline cluster state
echo -e "${BLUE}📊 Baseline Cluster State${NC}" | tee -a $LOG_FILE
echo "VEP Service pods:" | tee -a $LOG_FILE
oc get pods -l serving.knative.dev/service=vep-service --no-headers 2>/dev/null | tee -a $LOG_FILE || echo "No VEP service pods running" | tee -a $LOG_FILE

echo "" | tee -a $LOG_FILE
echo "KEDA ScaledObject status:" | tee -a $LOG_FILE
oc get scaledobject vep-service-scaler -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | tee -a $LOG_FILE || echo "KEDA status unknown" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Run WebSocket test
echo -e "${GREEN}🚀 Starting WebSocket Test${NC}" | tee -a $LOG_FILE
echo "Running: node scripts/test-websocket-client.js $MODE \"$SEQUENCE\" $TIMEOUT" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Run the WebSocket client and capture output
if node scripts/test-websocket-client.js "$MODE" "$SEQUENCE" "$TIMEOUT" 2>&1 | tee -a $LOG_FILE; then
    echo "" | tee -a $LOG_FILE
    echo -e "${GREEN}✅ WebSocket test completed successfully${NC}" | tee -a $LOG_FILE
    TEST_RESULT="SUCCESS"
else
    echo "" | tee -a $LOG_FILE
    echo -e "${RED}❌ WebSocket test failed or timed out${NC}" | tee -a $LOG_FILE
    TEST_RESULT="FAILED"
fi

# Check post-test cluster state
echo "" | tee -a $LOG_FILE
echo -e "${BLUE}📊 Post-Test Cluster State${NC}" | tee -a $LOG_FILE
echo "VEP Service pods after test:" | tee -a $LOG_FILE
oc get pods -l serving.knative.dev/service=vep-service --no-headers 2>/dev/null | tee -a $LOG_FILE || echo "No VEP service pods running" | tee -a $LOG_FILE

# Check VEP service logs if pods are running
VEP_PODS=$(oc get pods -l serving.knative.dev/service=vep-service --no-headers 2>/dev/null | grep Running | awk '{print $1}')
if [ -n "$VEP_PODS" ]; then
    echo "" | tee -a $LOG_FILE
    echo "Recent VEP service logs:" | tee -a $LOG_FILE
    for pod in $VEP_PODS; do
        echo "--- Logs from $pod ---" | tee -a $LOG_FILE
        oc logs $pod --tail=5 --since=2m 2>/dev/null | tee -a $LOG_FILE || echo "Could not retrieve logs" | tee -a $LOG_FILE
    done
fi

# Final summary
echo "" | tee -a $LOG_FILE
echo -e "${PURPLE}📋 TEST SUMMARY${NC}" | tee -a $LOG_FILE
echo "===================" | tee -a $LOG_FILE
echo "Mode: $MODE" | tee -a $LOG_FILE
echo "Sequence length: ${#SEQUENCE} chars" | tee -a $LOG_FILE
echo "Timeout: ${TIMEOUT}s" | tee -a $LOG_FILE
echo "Result: $TEST_RESULT" | tee -a $LOG_FILE
echo "Log file: $LOG_FILE" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

if [ "$TEST_RESULT" = "SUCCESS" ]; then
    echo -e "${GREEN}🎉 End-to-end WebSocket flow is working!${NC}" | tee -a $LOG_FILE
    exit 0
else
    echo -e "${YELLOW}💡 Troubleshooting suggestions:${NC}" | tee -a $LOG_FILE
    echo "1. Check if VEP service scaled up: oc get pods | grep vep-service" | tee -a $LOG_FILE
    echo "2. Check KEDA scaling: oc describe scaledobject vep-service-scaler" | tee -a $LOG_FILE
    echo "3. Check Kafka lag: scripts/test-vep-scaling-simple.sh" | tee -a $LOG_FILE
    echo "4. Try with longer timeout: ./test-websocket-flow.sh $MODE 180" | tee -a $LOG_FILE
    exit 1
fi