#!/bin/bash

# Local Threading Validation Script
# This script validates threading fixes locally before pushing to GitHub
# Aligns with ADR-004 and MVP Phase 0 requirements

set -e

echo "🧵 Local Threading Validation Script"
echo "===================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Set JAVA_HOME if not set
if [ -z "$JAVA_HOME" ]; then
    export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
    echo -e "${YELLOW}JAVA_HOME not set, using: $JAVA_HOME${NC}"
fi

# Check Java version
echo -e "${BLUE}Checking Java version...${NC}"
echo "JAVA_HOME: $JAVA_HOME"
java -version
echo ""

# Check if we're in the right directory
if [ ! -f "pom.xml" ]; then
    echo -e "${RED}❌ Error: Must be run from quarkus-websocket-service directory${NC}"
    exit 1
fi

# Clean and compile
echo -e "${BLUE}Cleaning and compiling project...${NC}"
./mvnw clean compile test-compile -q

# Run threading tests with detailed logging
echo -e "${BLUE}Running threading validation tests...${NC}"
echo ""

# Create log file
LOG_FILE="threading-validation-$(date +%Y%m%d-%H%M%S).log"

# Run the tests and capture output
./mvnw test -Dtest=ScalingTestControllerTest \
    -Dquarkus.log.level=INFO \
    -Dquarkus.log.category."com.redhat.healthcare".level=DEBUG \
    > "$LOG_FILE" 2>&1

TEST_EXIT_CODE=$?

echo "📋 Test Results Analysis"
echo "========================"
echo ""

# Analyze the results
WORKER_THREADS=$(grep -c "executor-thread" "$LOG_FILE" || echo "0")
EVENT_LOOP_BLOCKS=$(grep -c "vert.x-eventloop-thread" "$LOG_FILE" || echo "0")
CLOUDEVENTS_SENT=$(grep -c "Sent.*CloudEvent to Kafka" "$LOG_FILE" || echo "0")
RAW_EVENTS=$(grep -c "genetic.sequence.raw" "$LOG_FILE" || echo "0")
BIGDATA_EVENTS=$(grep -c "genetic.sequence.bigdata" "$LOG_FILE" || echo "0")

# Display results
echo -e "📊 ${BLUE}Threading Analysis:${NC}"
echo "   • Worker Thread Executions: $WORKER_THREADS"
echo "   • Event Loop Thread Usage: $EVENT_LOOP_BLOCKS"
echo ""

echo -e "📨 ${BLUE}CloudEvent Analysis:${NC}"
echo "   • Total CloudEvents Sent: $CLOUDEVENTS_SENT"
echo "   • Raw Events (normal mode): $RAW_EVENTS"
echo "   • BigData Events (big-data mode): $BIGDATA_EVENTS"
echo ""

# Validation checks
echo -e "✅ ${BLUE}Validation Results:${NC}"

VALIDATION_PASSED=true

# Check 1: Tests must pass
if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo -e "   ✅ ${GREEN}Tests passed${NC}"
else
    echo -e "   ❌ ${RED}Tests failed (exit code: $TEST_EXIT_CODE)${NC}"
    VALIDATION_PASSED=false
fi

# Check 2: No event loop blocking
if [ $EVENT_LOOP_BLOCKS -eq 0 ]; then
    echo -e "   ✅ ${GREEN}No event loop blocking detected${NC}"
else
    echo -e "   ❌ ${RED}Event loop blocking detected ($EVENT_LOOP_BLOCKS occurrences)${NC}"
    VALIDATION_PASSED=false
fi

# Check 3: Worker threads are being used
if [ $WORKER_THREADS -gt 0 ]; then
    echo -e "   ✅ ${GREEN}@Blocking annotations working ($WORKER_THREADS executions)${NC}"
else
    echo -e "   ❌ ${RED}No worker thread execution detected${NC}"
    VALIDATION_PASSED=false
fi

# Check 4: CloudEvents are being created
if [ $CLOUDEVENTS_SENT -gt 0 ]; then
    echo -e "   ✅ ${GREEN}CloudEvents created successfully ($CLOUDEVENTS_SENT events)${NC}"
else
    echo -e "   ⚠️  ${YELLOW}No CloudEvents detected (may be expected in some test scenarios)${NC}"
fi

echo ""

# Final result
if [ "$VALIDATION_PASSED" = true ]; then
    echo -e "🎉 ${GREEN}THREADING VALIDATION PASSED${NC}"
    echo ""
    echo -e "${GREEN}✅ Ready for GitHub push and OpenShift deployment${NC}"
    echo ""
    echo "ADR Compliance:"
    echo "• ADR-004: API Testing and Validation ✅"
    echo "• MVP Phase 0: Local Testing Requirements ✅"
    echo ""
    echo "Next steps:"
    echo "1. Commit your changes"
    echo "2. Push to GitHub (will trigger automated validation)"
    echo "3. Proceed with OpenShift deployment"
else
    echo -e "💥 ${RED}THREADING VALIDATION FAILED${NC}"
    echo ""
    echo -e "${RED}❌ NOT ready for OpenShift deployment${NC}"
    echo ""
    echo "Issues detected:"
    if [ $TEST_EXIT_CODE -ne 0 ]; then
        echo "• Test failures - check test implementation"
    fi
    if [ $EVENT_LOOP_BLOCKS -gt 0 ]; then
        echo "• Event loop blocking - add @Blocking annotations"
    fi
    if [ $WORKER_THREADS -eq 0 ]; then
        echo "• No worker thread usage - verify @Blocking annotations"
    fi
    echo ""
    echo "Please fix these issues before proceeding."
fi

echo ""
echo "📄 Detailed logs saved to: $LOG_FILE"
echo ""

# Show recent log entries for debugging
if [ "$VALIDATION_PASSED" = false ]; then
    echo -e "${YELLOW}Recent log entries for debugging:${NC}"
    echo "=================================="
    tail -20 "$LOG_FILE"
    echo ""
fi

exit $TEST_EXIT_CODE
