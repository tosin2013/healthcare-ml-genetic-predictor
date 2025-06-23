#!/bin/bash

# Local Separation of Concerns Validation Script
# Run this before committing to ensure you don't break the scaling mode separation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

function log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

function log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

function log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

function log_error() {
    echo -e "${RED}❌ $1${NC}"
}

function log_header() {
    echo -e "${BLUE}"
    echo "=================================================================="
    echo "$1"
    echo "=================================================================="
    echo -e "${NC}"
}

# Change to project root
cd "$PROJECT_ROOT"

log_header "🔍 Local Separation of Concerns Validation"
echo "This script validates that the 4 scaling mode buttons maintain proper"
echo "separation of concerns with their corresponding Kafka topics."
echo ""

# Check if required files exist
REQUIRED_FILES=(
    "quarkus-websocket-service/src/main/resources/META-INF/resources/index.html"
    "quarkus-websocket-service/src/main/java/com/redhat/healthcare/GeneticPredictorEndpoint.java"
    "quarkus-websocket-service/src/main/resources/application.properties"
    "scripts/test-ui-regression.js"
)

log_info "Checking required files..."
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        log_error "Required file not found: $file"
        exit 1
    fi
    log_success "Found: $file"
done

# Validation 1: UI Button Mappings
log_header "1. Validating UI Button → JavaScript Function Mappings"

HTML_FILE="quarkus-websocket-service/src/main/resources/META-INF/resources/index.html"

# Expected mappings
declare -A BUTTON_MAPPINGS=(
    ["normalModeBtn"]="setNormalMode"
    ["bigDataModeBtn"]="setBigDataMode"
    ["nodeScaleModeBtn"]="setNodeScaleMode"
    ["kafkaLagModeBtn"]="setKafkaLagMode"
)

UI_VALIDATION_PASSED=true

for button_id in "${!BUTTON_MAPPINGS[@]}"; do
    function_name="${BUTTON_MAPPINGS[$button_id]}"
    
    # Check button exists with correct onclick
    if grep -q "id=\"$button_id\"" "$HTML_FILE" && grep -A5 "id=\"$button_id\"" "$HTML_FILE" | grep -q "onclick=\"$function_name()\""; then
        log_success "Button $button_id correctly mapped to $function_name()"
    else
        log_error "Button $button_id missing or incorrectly mapped (expected: $function_name())"
        UI_VALIDATION_PASSED=false
    fi
    
    # Check function exists
    if grep -q "function $function_name()" "$HTML_FILE" || grep -q "$function_name\s*=" "$HTML_FILE"; then
        log_success "Function $function_name() exists"
    else
        log_error "Function $function_name() not found"
        UI_VALIDATION_PASSED=false
    fi
done

if [ "$UI_VALIDATION_PASSED" = true ]; then
    log_success "UI button validation passed"
else
    log_error "UI button validation failed"
    exit 1
fi

# Validation 2: Java Mode → Kafka Topic Mappings
log_header "2. Validating Java Mode → Kafka Topic Mappings"

JAVA_FILE="quarkus-websocket-service/src/main/java/com/redhat/healthcare/GeneticPredictorEndpoint.java"

# Expected Java mappings
declare -A MODE_MAPPINGS=(
    ["big-data"]="genetic-bigdata-raw"
    ["node-scale"]="genetic-nodescale-raw"
    ["kafka-lag"]="genetic-lag-demo-raw"
    ["normal"]="genetic-data-raw"
)

declare -A EMITTER_MAPPINGS=(
    ["big-data"]="geneticBigDataEmitter"
    ["node-scale"]="geneticNodeScaleEmitter"
    ["kafka-lag"]="geneticLagDemoEmitter"
    ["normal"]="geneticDataEmitter"
)

JAVA_VALIDATION_PASSED=true

for mode in "${!MODE_MAPPINGS[@]}"; do
    topic="${MODE_MAPPINGS[$mode]}"
    emitter="${EMITTER_MAPPINGS[$mode]}"
    
    # Check switch case exists
    if grep -q "case \"$mode\":" "$JAVA_FILE"; then
        log_success "Switch case for mode '$mode' exists"
    else
        log_error "Switch case for mode '$mode' missing"
        JAVA_VALIDATION_PASSED=false
    fi
    
    # Check topic assignment
    if grep -A3 "case \"$mode\":" "$JAVA_FILE" | grep -q "kafkaTopic = \"$topic\""; then
        log_success "Mode '$mode' correctly mapped to topic '$topic'"
    else
        log_error "Mode '$mode' not correctly mapped to topic '$topic'"
        JAVA_VALIDATION_PASSED=false
    fi
    
    # Check emitter usage
    if grep -A15 "case \"$mode\":" "$JAVA_FILE" | grep -q "$emitter.send"; then
        log_success "Mode '$mode' uses correct emitter '$emitter'"
    else
        log_error "Mode '$mode' does not use correct emitter '$emitter'"
        JAVA_VALIDATION_PASSED=false
    fi
done

if [ "$JAVA_VALIDATION_PASSED" = true ]; then
    log_success "Java mode validation passed"
else
    log_error "Java mode validation failed"
    exit 1
fi

# Validation 3: Kafka Configuration Consistency
log_header "3. Validating Kafka Configuration Consistency"

PROPS_FILE="quarkus-websocket-service/src/main/resources/application.properties"

TOPICS=("genetic-data-raw" "genetic-bigdata-raw" "genetic-nodescale-raw" "genetic-lag-demo-raw")
EMITTERS=("genetic-data-raw-out" "genetic-bigdata-raw-out" "genetic-nodescale-raw-out" "genetic-lag-demo-raw-out")

KAFKA_VALIDATION_PASSED=true

# Check topics
for topic in "${TOPICS[@]}"; do
    if grep -q "topic=$topic" "$PROPS_FILE"; then
        log_success "Topic '$topic' configured"
    else
        log_error "Topic '$topic' not configured"
        KAFKA_VALIDATION_PASSED=false
    fi
done

# Check emitter channels
for emitter in "${EMITTERS[@]}"; do
    if grep -q "mp.messaging.outgoing.$emitter" "$PROPS_FILE"; then
        log_success "Emitter channel '$emitter' configured"
    else
        log_error "Emitter channel '$emitter' not configured"
        KAFKA_VALIDATION_PASSED=false
    fi
done

if [ "$KAFKA_VALIDATION_PASSED" = true ]; then
    log_success "Kafka configuration validation passed"
else
    log_error "Kafka configuration validation failed"
    exit 1
fi

# Validation 4: Test Coverage
log_header "4. Validating Test Coverage for All Modes"

TEST_SCRIPT="scripts/test-ui-regression.js"
TEST_MODES=("normal" "big-data" "node-scale" "kafka-lag")

TEST_VALIDATION_PASSED=true

for mode in "${TEST_MODES[@]}"; do
    if grep -q "name: '$mode'" "$TEST_SCRIPT"; then
        log_success "Mode '$mode' has test coverage"
    else
        log_error "Mode '$mode' missing from test script"
        TEST_VALIDATION_PASSED=false
    fi
done

# Check test mode count
MODE_COUNT=$(grep -c "name: '" "$TEST_SCRIPT" || echo "0")
if [ "$MODE_COUNT" -eq 4 ]; then
    log_success "All 4 modes are tested"
else
    log_error "Expected 4 test modes, found $MODE_COUNT"
    TEST_VALIDATION_PASSED=false
fi

if [ "$TEST_VALIDATION_PASSED" = true ]; then
    log_success "Test coverage validation passed"
else
    log_error "Test coverage validation failed"
    exit 1
fi

# Validation 5: CloudEvent Type Consistency
log_header "5. Validating CloudEvent Type Consistency"

declare -A CLOUDEVENT_TYPES=(
    ["big-data"]="com.redhat.healthcare.genetic.sequence.bigdata"
    ["node-scale"]="com.redhat.healthcare.genetic.sequence.nodescale"
    ["kafka-lag"]="com.redhat.healthcare.genetic.sequence.kafkalag"
    ["normal"]="com.redhat.healthcare.genetic.sequence.raw"
)

CLOUDEVENT_VALIDATION_PASSED=true

for mode in "${!CLOUDEVENT_TYPES[@]}"; do
    expected_type="${CLOUDEVENT_TYPES[$mode]}"
    if grep -A5 "case \"$mode\":" "$JAVA_FILE" | grep -q "eventType = \"$expected_type\""; then
        log_success "Mode '$mode' has correct CloudEvent type: $expected_type"
    else
        log_error "Mode '$mode' missing correct CloudEvent type: $expected_type"
        CLOUDEVENT_VALIDATION_PASSED=false
    fi
done

if [ "$CLOUDEVENT_VALIDATION_PASSED" = true ]; then
    log_success "CloudEvent type validation passed"
else
    log_error "CloudEvent type validation failed"
    exit 1
fi

# Final Summary
log_header "🎉 Validation Summary"

if [ "$UI_VALIDATION_PASSED" = true ] && \
   [ "$JAVA_VALIDATION_PASSED" = true ] && \
   [ "$KAFKA_VALIDATION_PASSED" = true ] && \
   [ "$TEST_VALIDATION_PASSED" = true ] && \
   [ "$CLOUDEVENT_VALIDATION_PASSED" = true ]; then
    
    log_success "ALL VALIDATIONS PASSED!"
    log_success "Your changes maintain proper separation of concerns"
    log_success "✅ Safe to commit and create PR"
    echo ""
    echo "The 4 scaling mode buttons properly maintain their separation:"
    echo "  🟢 Normal Mode → genetic-data-raw"
    echo "  🟡 Big Data Mode → genetic-bigdata-raw"  
    echo "  🔴 Node Scale Mode → genetic-nodescale-raw"
    echo "  🟣 Kafka Lag Mode → genetic-lag-demo-raw"
    echo ""
    exit 0
else
    log_error "VALIDATION FAILED!"
    log_error "Your changes may break the scaling mode separation"
    log_error "❌ Please fix the issues above before committing"
    echo ""
    echo "Need help? Check the documentation:"
    echo "  📖 docs/tutorials/04-scaling-demo.md"
    echo "  📖 docs/tutorials/05-kafka-lag-scaling.md"
    echo ""
    exit 1
fi
