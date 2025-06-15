#!/bin/bash

# RQ2.7 Performance Benchmarking: Healthcare ML Event-Driven Systems
# Research Question: What are the key performance metrics and benchmarks for 
# evaluating event-driven healthcare ML systems?

set -e

# Configuration
API_BASE="https://quarkus-websocket-service-healthcare-ml-demo.apps.b9892ub1.eastus.aroapp.io/api"
NAMESPACE="healthcare-ml-demo"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_DIR="performance-results-${TIMESTAMP}"
CONCURRENT_USERS=(1 5 10 20 50)
SEQUENCE_SIZES=(20 100 500 1000)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔬 RQ2.7 Performance Benchmarking Suite${NC}"
echo "=============================================="
echo "Timestamp: $(date)"
echo "Results Directory: $RESULTS_DIR"
echo ""

# Create results directory
mkdir -p "$RESULTS_DIR"

# Function to log results
log_result() {
    local test_name=$1
    local metric=$2
    local value=$3
    local unit=$4
    echo "$test_name,$metric,$value,$unit,$(date -Iseconds)" >> "$RESULTS_DIR/benchmark-results.csv"
}

# Initialize CSV header
echo "test_name,metric,value,unit,timestamp" > "$RESULTS_DIR/benchmark-results.csv"

# Function to measure API response time
measure_api_response() {
    local endpoint=$1
    local payload=$2
    local description=$3
    
    echo -e "${YELLOW}📊 Testing: $description${NC}"
    
    # Measure response time using curl
    local response_time=$(curl -w "%{time_total}" -s -o /dev/null \
        -X POST "$API_BASE/$endpoint" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    local http_code=$(curl -w "%{http_code}" -s -o /dev/null \
        -X POST "$API_BASE/$endpoint" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    echo "  Response Time: ${response_time}s"
    echo "  HTTP Code: $http_code"
    
    log_result "$description" "response_time" "$response_time" "seconds"
    log_result "$description" "http_code" "$http_code" "code"
    
    return 0
}

# Function to measure system metrics
measure_system_metrics() {
    local test_name=$1
    
    echo -e "${PURPLE}📈 Collecting System Metrics: $test_name${NC}"
    
    # VEP Service metrics
    local vep_pods=$(oc get pods -l app=vep-service -n $NAMESPACE --no-headers 2>/dev/null | wc -l)
    local vep_running=$(oc get pods -l app=vep-service -n $NAMESPACE --no-headers 2>/dev/null | grep Running | wc -l || echo "0")
    
    # WebSocket Service metrics
    local ws_pods=$(oc get pods -l app=quarkus-websocket-service -n $NAMESPACE --no-headers 2>/dev/null | wc -l)
    local ws_running=$(oc get pods -l app=quarkus-websocket-service -n $NAMESPACE --no-headers 2>/dev/null | grep Running | wc -l || echo "0")
    
    # Kafka metrics
    local kafka_pods=$(oc get pods -l app.kubernetes.io/name=kafka -n $NAMESPACE --no-headers 2>/dev/null | wc -l)
    
    echo "  VEP Pods: $vep_pods total, $vep_running running"
    echo "  WebSocket Pods: $ws_pods total, $ws_running running"
    echo "  Kafka Pods: $kafka_pods"
    
    log_result "$test_name" "vep_pods_total" "$vep_pods" "count"
    log_result "$test_name" "vep_pods_running" "$vep_running" "count"
    log_result "$test_name" "websocket_pods_total" "$ws_pods" "count"
    log_result "$test_name" "websocket_pods_running" "$ws_running" "count"
    log_result "$test_name" "kafka_pods" "$kafka_pods" "count"
}

# Function to generate genetic sequence of specified size
generate_sequence() {
    local size=$1
    printf 'ATCG%.0s' $(seq 1 $((size/4)))
}

echo -e "${GREEN}🧪 Test 1: Baseline System Health${NC}"
measure_system_metrics "baseline"

# Health check performance
echo -e "${GREEN}🧪 Test 2: Health Endpoint Performance${NC}"
for i in {1..5}; do
    measure_api_response "scaling/health" '{}' "health_check_$i"
    sleep 1
done

echo -e "${GREEN}🧪 Test 3: Genetic Analysis Performance by Sequence Size${NC}"
for size in "${SEQUENCE_SIZES[@]}"; do
    sequence=$(generate_sequence $size)
    payload="{\"sequence\": \"$sequence\", \"resourceProfile\": \"standard\"}"
    
    echo -e "${BLUE}Testing sequence size: ${size} characters${NC}"
    measure_api_response "genetic/analyze" "$payload" "genetic_analysis_size_${size}"
    
    # Wait for processing and measure scaling
    sleep 10
    measure_system_metrics "genetic_analysis_size_${size}_post"
    sleep 5
done

echo -e "${GREEN}🧪 Test 4: Concurrent Load Testing${NC}"
for users in "${CONCURRENT_USERS[@]}"; do
    echo -e "${BLUE}Testing concurrent users: $users${NC}"
    
    # Record start time
    start_time=$(date +%s)
    
    # Launch concurrent requests
    pids=()
    for ((i=1; i<=users; i++)); do
        {
            sequence=$(generate_sequence 100)
            payload="{\"sequence\": \"$sequence\", \"resourceProfile\": \"standard\"}"
            response_time=$(curl -w "%{time_total}" -s -o /dev/null \
                -X POST "$API_BASE/genetic/analyze" \
                -H "Content-Type: application/json" \
                -d "$payload")
            echo "$response_time" > "$RESULTS_DIR/concurrent_${users}_user_${i}.tmp"
        } &
        pids+=($!)
    done
    
    # Wait for all requests to complete
    for pid in "${pids[@]}"; do
        wait $pid
    done
    
    # Calculate statistics
    end_time=$(date +%s)
    total_time=$((end_time - start_time))
    
    # Calculate average response time
    total_response_time=0
    count=0
    for file in "$RESULTS_DIR/concurrent_${users}_user_"*.tmp; do
        if [[ -f "$file" ]]; then
            response_time=$(cat "$file")
            total_response_time=$(echo "$total_response_time + $response_time" | bc -l)
            count=$((count + 1))
            rm "$file"
        fi
    done
    
    if [[ $count -gt 0 ]]; then
        avg_response_time=$(echo "scale=3; $total_response_time / $count" | bc -l)
        throughput=$(echo "scale=3; $users / $total_time" | bc -l)
        
        echo "  Concurrent Users: $users"
        echo "  Total Time: ${total_time}s"
        echo "  Average Response Time: ${avg_response_time}s"
        echo "  Throughput: ${throughput} requests/second"
        
        log_result "concurrent_load_${users}_users" "total_time" "$total_time" "seconds"
        log_result "concurrent_load_${users}_users" "avg_response_time" "$avg_response_time" "seconds"
        log_result "concurrent_load_${users}_users" "throughput" "$throughput" "requests_per_second"
    fi
    
    # Measure system state after load test
    sleep 15
    measure_system_metrics "concurrent_load_${users}_users_post"
    sleep 10
done

echo -e "${GREEN}🧪 Test 5: KEDA Scaling Performance${NC}"
echo "Testing KEDA scaling behavior..."

# Generate sustained load to trigger scaling
echo "Generating sustained load for KEDA scaling..."
start_time=$(date +%s)
for i in {1..20}; do
    sequence=$(generate_sequence 200)
    payload="{\"sequence\": \"$sequence\", \"resourceProfile\": \"high-memory\"}"
    
    curl -s -X POST "$API_BASE/genetic/analyze" \
        -H "Content-Type: application/json" \
        -d "$payload" > /dev/null &
    
    if (( i % 5 == 0 )); then
        echo "  Sent $i requests..."
        measure_system_metrics "keda_scaling_requests_${i}"
        sleep 2
    fi
done

# Wait for all requests to complete
wait

# Monitor scaling for 2 minutes
echo "Monitoring KEDA scaling behavior..."
for i in {1..8}; do
    sleep 15
    measure_system_metrics "keda_scaling_monitor_${i}"
    echo "  Monitoring cycle $i/8 completed"
done

echo -e "${GREEN}🧪 Test 6: Resource Utilization Analysis${NC}"
# Get resource usage if available
if command -v oc &> /dev/null; then
    echo "Collecting resource utilization data..."
    
    # VEP Service resource usage
    oc top pods -l app=vep-service -n $NAMESPACE --no-headers 2>/dev/null | while read line; do
        if [[ -n "$line" ]]; then
            pod_name=$(echo $line | awk '{print $1}')
            cpu_usage=$(echo $line | awk '{print $2}' | sed 's/m//')
            memory_usage=$(echo $line | awk '{print $3}' | sed 's/Mi//')
            
            log_result "resource_utilization" "vep_cpu_usage" "$cpu_usage" "millicores"
            log_result "resource_utilization" "vep_memory_usage" "$memory_usage" "megabytes"
        fi
    done
    
    # WebSocket Service resource usage
    oc top pods -l app=quarkus-websocket-service -n $NAMESPACE --no-headers 2>/dev/null | while read line; do
        if [[ -n "$line" ]]; then
            pod_name=$(echo $line | awk '{print $1}')
            cpu_usage=$(echo $line | awk '{print $2}' | sed 's/m//')
            memory_usage=$(echo $line | awk '{print $3}' | sed 's/Mi//')
            
            log_result "resource_utilization" "websocket_cpu_usage" "$cpu_usage" "millicores"
            log_result "resource_utilization" "websocket_memory_usage" "$memory_usage" "megabytes"
        fi
    done
fi

echo -e "${GREEN}📊 Benchmark Complete!${NC}"
echo "=============================================="
echo "Results saved to: $RESULTS_DIR/"
echo ""

# Generate summary report
echo -e "${BLUE}📈 Performance Summary${NC}"
echo "======================================"

# Calculate key metrics
if [[ -f "$RESULTS_DIR/benchmark-results.csv" ]]; then
    echo "Total tests executed: $(tail -n +2 "$RESULTS_DIR/benchmark-results.csv" | wc -l)"
    
    # Average response times
    avg_health=$(grep "health_check" "$RESULTS_DIR/benchmark-results.csv" | grep "response_time" | awk -F',' '{sum+=$3; count++} END {if(count>0) print sum/count; else print "N/A"}')
    avg_genetic=$(grep "genetic_analysis" "$RESULTS_DIR/benchmark-results.csv" | grep "response_time" | awk -F',' '{sum+=$3; count++} END {if(count>0) print sum/count; else print "N/A"}')
    
    echo "Average health check response time: ${avg_health}s"
    echo "Average genetic analysis response time: ${avg_genetic}s"
    
    # Peak throughput
    peak_throughput=$(grep "throughput" "$RESULTS_DIR/benchmark-results.csv" | awk -F',' '{if($3>max) max=$3} END {print max}')
    echo "Peak throughput: ${peak_throughput} requests/second"
    
    # Max scaling
    max_vep_pods=$(grep "vep_pods_running" "$RESULTS_DIR/benchmark-results.csv" | awk -F',' '{if($3>max) max=$3} END {print max}')
    echo "Maximum VEP pods scaled: $max_vep_pods"
fi

echo ""
echo -e "${GREEN}✅ RQ2.7 Performance Benchmarking Complete${NC}"
echo "Results available in: $RESULTS_DIR/benchmark-results.csv"
