#!/bin/bash

# Simple VEP Service Scaling Test
# Tests if KEDA scaling is working for VEP service

set -e

API_BASE="https://quarkus-websocket-service-healthcare-ml-demo.apps.b9892ub1.eastus.aroapp.io/api"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "🔬 VEP Service KEDA Scaling Test - $(date)"
echo "=============================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check VEP service status
check_vep_status() {
    local description=$1
    echo -e "${BLUE}📊 $description${NC}"
    echo "  Timestamp: $(date)"
    
    # Check VEP pods
    vep_pods=$(oc get pods -l serving.knative.dev/service=vep-service --no-headers 2>/dev/null | wc -l)
    running_vep=$(oc get pods -l serving.knative.dev/service=vep-service --no-headers 2>/dev/null | grep Running | wc -l || echo "0")
    echo "  VEP Pods: $vep_pods total, $running_vep running"
    
    # Check KEDA ScaledObject status
    keda_ready=$(oc get scaledobject vep-service-scaler -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")
    keda_active=$(oc get scaledobject vep-service-scaler -o jsonpath='{.status.conditions[?(@.type=="Active")].status}' 2>/dev/null || echo "Unknown")
    echo "  KEDA Ready: $keda_ready, Active: $keda_active"
    
    # Check Kafka consumer group
    consumer_lag=$(oc exec genetic-data-cluster-kafka-0 -- /opt/kafka/bin/kafka-consumer-groups.sh \
        --bootstrap-server localhost:9092 --describe --group vep-service-group 2>/dev/null | \
        grep genetic-data-raw | awk '{sum+=$5} END {print sum+0}' || echo "0")
    echo "  Kafka Lag (vep-service-group): $consumer_lag messages"
    
    echo ""
}

# Test 1: Baseline check
echo -e "${YELLOW}🧪 Test 1: Baseline Status Check${NC}"
check_vep_status "Baseline (before any API calls)"

# Test 2: Health check (should not trigger scaling)
echo -e "${YELLOW}🧪 Test 2: Health Check (No Scaling Expected)${NC}"
echo "Making API call to health endpoint..."
health_response=$(curl -s "$API_BASE/scaling/health" || echo "ERROR")
echo "API Response: $health_response"
echo ""
sleep 10
check_vep_status "After health check (10s later)"

# Test 3: Genetic analysis (should trigger VEP scaling)
echo -e "${YELLOW}🧪 Test 3: Genetic Analysis (Should Trigger VEP Scaling)${NC}"
echo "Making API call to genetic analysis endpoint..."
analysis_response=$(curl -s -X POST "$API_BASE/genetic/analyze" \
    -H "Content-Type: application/json" \
    -d '{"sequence": "ATCGATCGATCGATCGATCG", "resourceProfile": "standard"}' || echo "ERROR")
echo "API Response: $analysis_response"
echo ""

# Monitor for 2 minutes
echo -e "${YELLOW}⏱️ Monitoring VEP scaling for 2 minutes...${NC}"
for i in {1..8}; do
    sleep 15
    check_vep_status "After ${i}x15s ($(($i * 15))s total)"
done

# Test 4: Larger workload
echo -e "${YELLOW}🧪 Test 4: Larger Genetic Analysis (More Scaling)${NC}"
large_sequence=$(printf 'ATCG%.0s' {1..250})  # 1KB sequence
echo "Making API call with larger sequence..."
large_response=$(curl -s -X POST "$API_BASE/genetic/analyze" \
    -H "Content-Type: application/json" \
    -d "{\"sequence\": \"$large_sequence\", \"resourceProfile\": \"high-memory\"}" || echo "ERROR")
echo "API Response: $large_response"
echo ""

# Monitor for 1 minute
echo -e "${YELLOW}⏱️ Monitoring after larger workload for 1 minute...${NC}"
for i in {1..4}; do
    sleep 15
    check_vep_status "Large workload - After ${i}x15s ($(($i * 15))s total)"
done

# Final status
echo -e "${GREEN}📋 Final Test Summary${NC}"
echo "=============================================="
check_vep_status "Final Status"

# Check KEDA ScaledObject details
echo -e "${BLUE}🔍 KEDA ScaledObject Details:${NC}"
oc describe scaledobject vep-service-scaler | grep -A 5 -B 5 "Status\|Conditions\|Triggers" || echo "Could not get ScaledObject details"

echo ""
echo -e "${GREEN}✅ VEP Scaling Test Complete!${NC}"
echo "Check the output above to see if VEP service scaled based on genetic analysis requests."
echo ""
echo "Expected behavior:"
echo "- Health check: No VEP scaling"
echo "- Genetic analysis: VEP pods should scale from 0 to 1+"
echo "- Kafka lag should increase then decrease as VEP processes messages"
echo "- KEDA Ready should be 'True', Active should be 'True' when scaling"
