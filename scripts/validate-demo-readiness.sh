#!/bin/bash

# Demo Readiness Validation Script
# Validates all components are ready for healthcare ML demo

set -e

echo "🔍 Healthcare ML Demo Readiness Validation"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Validation results
TOTAL_CHECKS=0
PASSED_CHECKS=0

# Function to check component status
check_component() {
    local component=$1
    local command=$2
    local expected=$3
    local description=$4
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -n "  Checking $component: "
    
    if result=$(eval "$command" 2>/dev/null); then
        if [[ "$result" == *"$expected"* ]]; then
            echo -e "${GREEN}✅ PASS${NC} - $description"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
        else
            echo -e "${RED}❌ FAIL${NC} - $description (Got: $result)"
        fi
    else
        echo -e "${RED}❌ FAIL${NC} - $description (Command failed)"
    fi
}

echo -e "${BLUE}1. KEDA Controller Validation${NC}"
echo "------------------------------"

check_component "KEDA Namespace" \
    "oc get namespace openshift-keda -o jsonpath='{.status.phase}'" \
    "Active" \
    "openshift-keda namespace exists and active"

check_component "KEDA Operator" \
    "oc get pods -n openshift-keda -l app.kubernetes.io/name=keda-operator --no-headers | wc -l" \
    "1" \
    "KEDA operator pod running"

check_component "KEDA Metrics Server" \
    "oc get pods -n openshift-keda -l app.kubernetes.io/name=keda-metrics-apiserver --no-headers | wc -l" \
    "1" \
    "KEDA metrics server running"

check_component "KedaController" \
    "oc get kedacontroller keda -n openshift-keda -o jsonpath='{.status.phase}'" \
    "Installation Succeeded" \
    "KedaController installation successful"

echo ""
echo -e "${BLUE}2. VEP Service Validation${NC}"
echo "-------------------------"

check_component "VEP Deployment" \
    "oc get deployment vep-service -n healthcare-ml-demo -o jsonpath='{.status.readyReplicas}'" \
    "1" \
    "VEP deployment has 1 ready replica"

check_component "VEP Service" \
    "oc get service vep-service -n healthcare-ml-demo -o jsonpath='{.spec.type}'" \
    "ClusterIP" \
    "VEP service exists and accessible"

check_component "VEP Pods" \
    "oc get pods -l app=vep-service -n healthcare-ml-demo --no-headers | grep Running | wc -l" \
    "1" \
    "VEP pod running successfully"

echo ""
echo -e "${BLUE}3. KEDA ScaledObject Validation${NC}"
echo "-------------------------------"

check_component "VEP ScaledObject" \
    "oc get scaledobject vep-service-scaler -n healthcare-ml-demo -o jsonpath='{.status.conditions[?(@.type==\"Ready\")].status}'" \
    "True" \
    "VEP ScaledObject ready for scaling"

check_component "HPA Created" \
    "oc get hpa keda-hpa-vep-service-scaler -n healthcare-ml-demo --no-headers | wc -l" \
    "1" \
    "HPA created by KEDA for VEP service"

echo ""
echo -e "${BLUE}4. Kafka Integration Validation${NC}"
echo "--------------------------------"

check_component "Kafka Cluster" \
    "oc get kafka genetic-data-cluster -n healthcare-ml-demo -o jsonpath='{.status.conditions[?(@.type==\"Ready\")].status}'" \
    "True" \
    "Kafka cluster ready and operational"

check_component "Kafka Topic" \
    "oc exec genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list | grep genetic-data-raw | wc -l" \
    "1" \
    "genetic-data-raw topic exists"

check_component "Consumer Group" \
    "oc exec genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- /opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list | grep vep-service-group | wc -l" \
    "1" \
    "vep-service-group consumer group exists"

echo ""
echo -e "${BLUE}5. API Endpoints Validation${NC}"
echo "----------------------------"

API_BASE="https://quarkus-websocket-service-healthcare-ml-demo.apps.b9892ub1.eastus.aroapp.io/api"

check_component "Health Endpoint" \
    "curl -s -o /dev/null -w '%{http_code}' $API_BASE/scaling/health" \
    "200" \
    "Health endpoint responding"

check_component "Genetic Analysis Endpoint" \
    "curl -s -o /dev/null -w '%{http_code}' -X POST $API_BASE/genetic/analyze -H 'Content-Type: application/json' -d '{\"sequence\":\"ATCG\"}'" \
    "200" \
    "Genetic analysis endpoint responding"

echo ""
echo -e "${BLUE}6. Demo Script Validation${NC}"
echo "-------------------------"

check_component "Test Script" \
    "test -x scripts/test-keda-scaling-behavior.sh && echo 'executable'" \
    "executable" \
    "KEDA scaling test script is executable"

check_component "Demo Guide" \
    "test -f DEMO.md && echo 'exists'" \
    "exists" \
    "Demo guide documentation exists"

echo ""
echo -e "${BLUE}7. Network Connectivity Validation${NC}"
echo "-----------------------------------"

check_component "KEDA to Kafka" \
    "oc run connectivity-test --image=busybox --rm -i --restart=Never -n openshift-keda -- nc -zv genetic-data-cluster-kafka-bootstrap.healthcare-ml-demo.svc.cluster.local 9092 2>&1 | grep 'open' | wc -l" \
    "1" \
    "KEDA can reach Kafka cluster"

echo ""
echo "=========================================="
echo -e "${BLUE}Demo Readiness Summary${NC}"
echo "=========================================="

if [ $PASSED_CHECKS -eq $TOTAL_CHECKS ]; then
    echo -e "${GREEN}🎉 ALL CHECKS PASSED ($PASSED_CHECKS/$TOTAL_CHECKS)${NC}"
    echo ""
    echo -e "${GREEN}✅ Demo is READY for presentation!${NC}"
    echo ""
    echo "Available demo options:"
    echo "  1. Automated Script: ./scripts/test-keda-scaling-behavior.sh"
    echo "  2. Interactive UI: $API_BASE/../"
    echo "  3. Manual API: See DEMO.md for step-by-step guide"
    echo ""
    echo "Quick demo test:"
    echo "  curl -X POST $API_BASE/genetic/analyze -H 'Content-Type: application/json' -d '{\"sequence\":\"ATCGATCGATCGATCGATCG\"}'"
    echo "  watch oc get deployment vep-service -n healthcare-ml-demo"
else
    echo -e "${RED}❌ DEMO NOT READY ($PASSED_CHECKS/$TOTAL_CHECKS checks passed)${NC}"
    echo ""
    echo -e "${YELLOW}Please fix the failing components before running the demo.${NC}"
    echo "See troubleshooting section in DEMO.md for guidance."
fi

echo ""
