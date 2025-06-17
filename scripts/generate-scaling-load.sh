#!/bin/bash

# Generate load to test KEDA pod scaling
# This script sends multiple API requests to create Kafka lag and trigger VEP service scaling

set -e

# Configuration
API_BASE_URL="https://quarkus-websocket-service-healthcare-ml-demo.apps.b9892ub1.eastus.aroapp.io"
NAMESPACE="healthcare-ml-demo"
LOAD_DURATION=300  # 5 minutes
REQUEST_INTERVAL=1  # 1 second between requests
CONCURRENT_REQUESTS=5

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file
LOG_FILE="scaling-load-test-$(date +%Y%m%d-%H%M%S).log"

echo -e "${GREEN}🚀 Starting KEDA Pod Scaling Load Test${NC}" | tee -a $LOG_FILE
echo "=================================================================" | tee -a $LOG_FILE
echo "Target: Scale VEP service from 1 → 20 replicas" | tee -a $LOG_FILE
echo "Duration: ${LOAD_DURATION} seconds" | tee -a $LOG_FILE
echo "Concurrent requests: ${CONCURRENT_REQUESTS}" | tee -a $LOG_FILE
echo "Request interval: ${REQUEST_INTERVAL} seconds" | tee -a $LOG_FILE
echo "Log file: $LOG_FILE" | tee -a $LOG_FILE
echo "=================================================================" | tee -a $LOG_FILE

# Function to send API request
send_request() {
    local request_id=$1
    local sequence_length=$((50 + RANDOM % 100))  # Random sequence length 50-150
    local sequence=$(head /dev/urandom | tr -dc 'ATCG' | head -c $sequence_length)
    
    curl -s -X POST "${API_BASE_URL}/api/genetic/analyze" \
        -H "Content-Type: application/json" \
        -d "{\"sequence\": \"${sequence}\", \"resourceProfile\": \"standard\"}" \
        -w "Request ${request_id}: HTTP %{http_code}, Time: %{time_total}s\n" \
        >> $LOG_FILE 2>&1 &
}

# Function to monitor scaling
monitor_scaling() {
    echo -e "${BLUE}📊 Monitoring VEP service scaling...${NC}" | tee -a $LOG_FILE
    
    while true; do
        # Get current replica count
        current_replicas=$(oc get deployment vep-service -n $NAMESPACE -o jsonpath='{.status.replicas}' 2>/dev/null || echo "0")
        ready_replicas=$(oc get deployment vep-service -n $NAMESPACE -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        
        # Get KEDA scaler status
        keda_active=$(oc get scaledobject vep-service-scaler -n $NAMESPACE -o jsonpath='{.status.conditions[?(@.type=="Active")].status}' 2>/dev/null || echo "Unknown")
        
        # Get Kafka lag
        kafka_lag=$(oc exec genetic-data-cluster-kafka-0 -n $NAMESPACE -- /opt/kafka/bin/kafka-consumer-groups.sh \
            --bootstrap-server localhost:9092 --describe --group vep-service-group 2>/dev/null | \
            grep genetic-data-raw | awk '{print $5}' | head -1 2>/dev/null || echo "0")
        
        timestamp=$(date '+%H:%M:%S')
        echo "[$timestamp] VEP Replicas: $ready_replicas/$current_replicas, KEDA Active: $keda_active, Kafka Lag: $kafka_lag" | tee -a $LOG_FILE
        
        # Check if we've reached target scaling
        if [ "$current_replicas" -ge "10" ]; then
            echo -e "${GREEN}🎉 Significant scaling achieved! Current replicas: $current_replicas${NC}" | tee -a $LOG_FILE
        fi
        
        sleep 10
    done
}

# Function to generate continuous load
generate_load() {
    echo -e "${YELLOW}⚡ Starting load generation...${NC}" | tee -a $LOG_FILE
    
    local request_count=0
    local start_time=$(date +%s)
    local end_time=$((start_time + LOAD_DURATION))
    
    while [ $(date +%s) -lt $end_time ]; do
        # Send concurrent requests
        for i in $(seq 1 $CONCURRENT_REQUESTS); do
            request_count=$((request_count + 1))
            send_request $request_count
        done
        
        echo "Sent batch of $CONCURRENT_REQUESTS requests (Total: $request_count)" | tee -a $LOG_FILE
        sleep $REQUEST_INTERVAL
    done
    
    echo -e "${YELLOW}📤 Load generation completed. Total requests: $request_count${NC}" | tee -a $LOG_FILE
}

# Start monitoring in background
monitor_scaling &
MONITOR_PID=$!

# Generate load
generate_load

# Wait a bit more for scaling to complete
echo -e "${BLUE}⏳ Waiting for scaling to complete...${NC}" | tee -a $LOG_FILE
sleep 60

# Stop monitoring
kill $MONITOR_PID 2>/dev/null || true

# Final status check
echo -e "${GREEN}📋 Final Status Check:${NC}" | tee -a $LOG_FILE
echo "=================================================================" | tee -a $LOG_FILE

final_replicas=$(oc get deployment vep-service -n $NAMESPACE -o jsonpath='{.status.replicas}' 2>/dev/null || echo "0")
final_ready=$(oc get deployment vep-service -n $NAMESPACE -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
final_keda_active=$(oc get scaledobject vep-service-scaler -n $NAMESPACE -o jsonpath='{.status.conditions[?(@.type=="Active")].status}' 2>/dev/null || echo "Unknown")

echo "Final VEP Service Replicas: $final_ready/$final_replicas" | tee -a $LOG_FILE
echo "Final KEDA Active Status: $final_keda_active" | tee -a $LOG_FILE

if [ "$final_replicas" -gt "1" ]; then
    echo -e "${GREEN}✅ SUCCESS: VEP service scaled up from 1 to $final_replicas replicas!${NC}" | tee -a $LOG_FILE
else
    echo -e "${RED}❌ ISSUE: VEP service did not scale up (still at $final_replicas replicas)${NC}" | tee -a $LOG_FILE
fi

echo "=================================================================" | tee -a $LOG_FILE
echo -e "${GREEN}🎉 KEDA Pod Scaling Load Test Complete!${NC}" | tee -a $LOG_FILE
echo "Results saved to: $LOG_FILE" | tee -a $LOG_FILE
