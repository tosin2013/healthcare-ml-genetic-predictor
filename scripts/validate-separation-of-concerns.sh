#!/bin/bash

# Separation of Concerns Validation Script
# Validates that the 4 scaling modes maintain proper separation between
# UI buttons, Kafka topics, consumer groups, and KEDA configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((PASSED++))
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    ((FAILED++))
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((WARNINGS++))
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Function to validate UI button separation
validate_ui_buttons() {
    print_header "Validating UI Button Separation"
    
    local ui_file="quarkus-websocket-service/src/main/resources/META-INF/resources/index.html"
    
    if [ ! -f "$ui_file" ]; then
        print_error "UI file not found: $ui_file"
        return 1
    fi
    
    # Check for all 4 button IDs
    local buttons=("normalModeBtn" "bigDataModeBtn" "nodeScaleModeBtn" "kafkaLagModeBtn")
    local button_functions=("setNormalMode" "setBigDataMode" "setNodeScaleMode" "setKafkaLagMode")
    
    for button in "${buttons[@]}"; do
        if grep -q "id=\"$button\"" "$ui_file"; then
            print_success "Button ID found: $button"
        else
            print_error "Button ID missing: $button"
        fi
    done
    
    for func in "${button_functions[@]}"; do
        if grep -q "$func()" "$ui_file"; then
            print_success "Button function found: $func"
        else
            print_error "Button function missing: $func"
        fi
    done
    
    # Check for mode variable assignments
    local modes=("normal" "big-data" "node-scale" "kafka-lag")
    for mode in "${modes[@]}"; do
        if grep -q "currentMode = '$mode'" "$ui_file"; then
            print_success "Mode assignment found: $mode"
        else
            print_error "Mode assignment missing: $mode"
        fi
    done
}

# Function to validate Kafka topic separation
validate_kafka_topics() {
    print_header "Validating Kafka Topic Separation"
    
    local required_topics=(
        "genetic-data-raw"
        "genetic-bigdata-raw"
        "genetic-nodescale-raw"
        "genetic-lag-demo-raw"
        "genetic-data-annotated"
    )
    
    for topic in "${required_topics[@]}"; do
        if find k8s/ -name "*.yaml" -o -name "*.yml" | xargs grep -l "name: $topic" > /dev/null 2>&1; then
            print_success "Kafka topic definition found: $topic"
            
            # Validate topic configuration
            local topic_file=$(find k8s/ -name "*.yaml" -o -name "*.yml" | xargs grep -l "name: $topic" | head -1)
            if grep -A 20 "name: $topic" "$topic_file" | grep -q "partitions:"; then
                print_success "Topic has partition configuration: $topic"
            else
                print_warning "Topic missing partition configuration: $topic"
            fi
        else
            print_error "Kafka topic definition missing: $topic"
        fi
    done
}

# Function to validate consumer group separation
validate_consumer_groups() {
    print_header "Validating Consumer Group Separation"
    
    local expected_groups=(
        "vep-service-group"
        "vep-bigdata-service-group"
        "vep-nodescale-service-group"
        "genetic-lag-consumer-group"
        "websocket-results-service-group"
    )
    
    for group in "${expected_groups[@]}"; do
        if find . -name "*.java" -o -name "*.yaml" -o -name "*.yml" | xargs grep -l "$group" > /dev/null 2>&1; then
            print_success "Consumer group found: $group"
        else
            print_warning "Consumer group not found: $group"
        fi
    done
}

# Function to validate KEDA scaler separation
validate_keda_scalers() {
    print_header "Validating KEDA Scaler Separation"
    
    local keda_files=$(find k8s/ -name "*.yaml" -o -name "*.yml" | xargs grep -l "kind: ScaledObject" 2>/dev/null || echo "")
    
    if [ -z "$keda_files" ]; then
        print_error "No KEDA ScaledObjects found"
        return 1
    fi
    
    print_info "Found KEDA files: $keda_files"
    
    # Check each ScaledObject for topic references
    local genetic_topics=("genetic-data-raw" "genetic-bigdata-raw" "genetic-nodescale-raw" "genetic-lag-demo-raw")
    
    for topic in "${genetic_topics[@]}"; do
        if echo "$keda_files" | xargs grep -l "$topic" > /dev/null 2>&1; then
            print_success "KEDA scaler found for topic: $topic"
        else
            print_warning "No KEDA scaler found for topic: $topic"
        fi
    done
    
    # Validate lagThreshold configurations are different (separation)
    local threshold_count=$(echo "$keda_files" | xargs grep "lagThreshold:" | sort | uniq | wc -l)
    if [ "$threshold_count" -gt 1 ]; then
        print_success "Multiple lag thresholds found (good separation): $threshold_count"
    else
        print_warning "All scalers may have same lag threshold (check separation)"
    fi
}

# Function to validate WebSocket service routing
validate_websocket_routing() {
    print_header "Validating WebSocket Service Routing"
    
    local ws_service_files=$(find quarkus-websocket-service/src -name "*.java" -type f)
    
    # Check for mode-based routing logic
    local routing_found=false
    for file in $ws_service_files; do
        if grep -q "genetic-data-raw\|genetic-bigdata-raw\|genetic-nodescale-raw\|genetic-lag-demo-raw" "$file"; then
            print_success "Topic routing found in: $(basename $file)"
            routing_found=true
        fi
    done
    
    if [ "$routing_found" = false ]; then
        print_error "No topic routing logic found in WebSocket service"
    fi
    
    # Check for mode constants or enums
    local mode_definitions=false
    for file in $ws_service_files; do
        if grep -q "normal\|big-data\|node-scale\|kafka-lag" "$file"; then
            print_success "Mode definitions found in: $(basename $file)"
            mode_definitions=true
        fi
    done
    
    if [ "$mode_definitions" = false ]; then
        print_error "No mode definitions found in WebSocket service"
    fi
}

# Function to validate VEP service separation
validate_vep_services() {
    print_header "Validating VEP Service Separation"
    
    local vep_files=$(find vep-service/src -name "*.java" -type f 2>/dev/null || echo "")
    local vep_config_files=$(find k8s/ -path "*/vep-service/*" -name "*.yaml" -o -name "*.yml" 2>/dev/null || echo "")
    
    if [ -z "$vep_files" ] && [ -z "$vep_config_files" ]; then
        print_warning "No VEP service files found"
        return 0
    fi
    
    # Check for @Incoming annotations with different topics
    local incoming_topics=("genetic-data-raw" "genetic-bigdata-raw" "genetic-nodescale-raw" "genetic-lag-demo-raw")
    
    for topic in "${incoming_topics[@]}"; do
        if echo "$vep_files" | xargs grep -l "@Incoming.*$topic" > /dev/null 2>&1; then
            print_success "VEP @Incoming found for topic: $topic"
        else
            print_warning "No VEP @Incoming found for topic: $topic"
        fi
    done
    
    # Check for different deployments/services
    local vep_deployments=$(echo "$vep_config_files" | xargs grep -l "kind: Deployment" | wc -l)
    if [ "$vep_deployments" -gt 1 ]; then
        print_success "Multiple VEP deployments found (good separation): $vep_deployments"
    else
        print_info "Single VEP deployment found (may handle multiple topics)"
    fi
}

# Function to validate test coverage
validate_test_coverage() {
    print_header "Validating Test Coverage"
    
    local test_script="scripts/test-ui-regression.js"
    
    if [ ! -f "$test_script" ]; then
        print_error "UI regression test script missing: $test_script"
        return 1
    fi
    
    # Check for all 4 test modes
    local test_modes=("normal" "big-data" "node-scale" "kafka-lag")
    
    for mode in "${test_modes[@]}"; do
        if grep -q "name: '$mode'" "$test_script"; then
            print_success "Test coverage for mode: $mode"
        else
            print_error "Test coverage missing for mode: $mode"
        fi
    done
    
    # Validate test script syntax
    if node -c "$test_script" 2>/dev/null; then
        print_success "Test script syntax is valid"
    else
        print_error "Test script has syntax errors"
    fi
}

# Function to validate documentation consistency
validate_documentation() {
    print_header "Validating Documentation Consistency"
    
    local doc_files=$(find docs/ -name "*.md" -type f)
    
    # Check for scaling mode documentation
    local modes=("Normal Mode" "Big Data Mode" "Node Scale Mode" "Kafka Lag Mode")
    
    for mode in "${modes[@]}"; do
        if echo "$doc_files" | xargs grep -l "$mode" > /dev/null 2>&1; then
            print_success "Documentation found for: $mode"
        else
            print_warning "Documentation missing for: $mode"
        fi
    done
    
    # Check for topic documentation
    local topics=("genetic-data-raw" "genetic-bigdata-raw" "genetic-nodescale-raw" "genetic-lag-demo-raw")
    
    for topic in "${topics[@]}"; do
        if echo "$doc_files" | xargs grep -l "$topic" > /dev/null 2>&1; then
            print_success "Documentation found for topic: $topic"
        else
            print_warning "Documentation missing for topic: $topic"
        fi
    done
}

# Function to check for cross-contamination
validate_no_cross_contamination() {
    print_header "Validating No Cross-Contamination"
    
    # Check that different modes don't reference each other's topics incorrectly
    local ui_file="quarkus-websocket-service/src/main/resources/META-INF/resources/index.html"
    
    # Normal mode should not reference big data topics
    if grep -A 20 "setNormalMode" "$ui_file" | grep -q "genetic-bigdata-raw\|genetic-nodescale-raw\|genetic-lag-demo-raw"; then
        print_error "Normal mode function references other mode topics"
    else
        print_success "Normal mode maintains topic isolation"
    fi
    
    # Big data mode should not reference other topics
    if grep -A 20 "setBigDataMode" "$ui_file" | grep -q "genetic-data-raw\|genetic-nodescale-raw\|genetic-lag-demo-raw"; then
        print_error "Big data mode function references other mode topics"
    else
        print_success "Big data mode maintains topic isolation"
    fi
    
    # Check KEDA scalers don't have conflicting consumer groups
    local keda_files=$(find k8s/ -name "*.yaml" -o -name "*.yml" | xargs grep -l "kind: ScaledObject" 2>/dev/null || echo "")
    
    if [ -n "$keda_files" ]; then
        local consumer_groups=$(echo "$keda_files" | xargs grep "consumerGroup:" | sort | uniq)
        local group_count=$(echo "$consumer_groups" | wc -l)
        local unique_groups=$(echo "$consumer_groups" | cut -d: -f2 | sort | uniq | wc -l)
        
        if [ "$group_count" -eq "$unique_groups" ]; then
            print_success "No consumer group conflicts in KEDA scalers"
        else
            print_error "Consumer group conflicts detected in KEDA scalers"
        fi
    fi
}

# Main execution
main() {
    print_header "🛡️ Separation of Concerns Validation"
    echo "Validating 4-mode scaling architecture separation..."
    echo ""
    
    validate_ui_buttons
    echo ""
    
    validate_kafka_topics
    echo ""
    
    validate_consumer_groups
    echo ""
    
    validate_keda_scalers
    echo ""
    
    validate_websocket_routing
    echo ""
    
    validate_vep_services
    echo ""
    
    validate_test_coverage
    echo ""
    
    validate_documentation
    echo ""
    
    validate_no_cross_contamination
    echo ""
    
    # Final report
    print_header "🛡️ Validation Summary"
    echo -e "${GREEN}✅ Passed: $PASSED${NC}"
    echo -e "${YELLOW}⚠️  Warnings: $WARNINGS${NC}"
    echo -e "${RED}❌ Failed: $FAILED${NC}"
    echo ""
    
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 SEPARATION OF CONCERNS VALIDATION PASSED${NC}"
        echo "All 4 scaling modes maintain proper separation:"
        echo "📊 Normal Mode → genetic-data-raw"
        echo "🚀 Big Data Mode → genetic-bigdata-raw"
        echo "⚡ Node Scale Mode → genetic-nodescale-raw"
        echo "🔄 Kafka Lag Mode → genetic-lag-demo-raw"
        exit 0
    else
        echo -e "${RED}❌ SEPARATION OF CONCERNS VALIDATION FAILED${NC}"
        echo "Fix the issues above before merging changes"
        exit 1
    fi
}

# Run the validation
main "$@"
