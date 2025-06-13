#!/bin/bash

# Enhanced Healthcare ML Infrastructure Validation Script
# Validates VEP Service and OpenShift AI Integration

set -euo pipefail

# Configuration
NAMESPACE="healthcare-ml-demo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validation functions
validate_operators() {
    log_info "Validating operators..."
    
    local operators=("amq-streams" "serverless-operator" "keda" "rhods-operator")
    local all_ready=true
    
    for operator in "${operators[@]}"; do
        if oc get csv -n openshift-operators | grep -q "${operator}.*Succeeded"; then
            log_success "Operator ${operator} is ready"
        else
            log_error "Operator ${operator} is not ready"
            all_ready=false
        fi
    done
    
    if [ "$all_ready" = true ]; then
        log_success "All operators are ready"
        return 0
    else
        log_error "Some operators are not ready"
        return 1
    fi
}

validate_infrastructure() {
    log_info "Validating infrastructure components..."
    
    # Check Kafka cluster
    if oc get kafka genetic-data-cluster -n "${NAMESPACE}" &> /dev/null; then
        local kafka_status=$(oc get kafka genetic-data-cluster -n "${NAMESPACE}" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
        if [ "$kafka_status" = "True" ]; then
            log_success "Kafka cluster is ready"
        else
            log_error "Kafka cluster is not ready"
            return 1
        fi
    else
        log_error "Kafka cluster not found"
        return 1
    fi
    
    # Check Kafka topics
    local topics=("genetic-data-raw" "genetic-data-annotated" "genetic-data-processed")
    for topic in "${topics[@]}"; do
        if oc exec -n "${NAMESPACE}" genetic-data-cluster-kafka-0 -c kafka -- bin/kafka-topics.sh --bootstrap-server localhost:9092 --list | grep -q "${topic}"; then
            log_success "Kafka topic ${topic} exists"
        else
            log_warning "Kafka topic ${topic} not found"
        fi
    done
    
    return 0
}

validate_applications() {
    log_info "Validating application components..."
    
    # Check Quarkus WebSocket service
    if oc get ksvc quarkus-websocket-knative -n "${NAMESPACE}" &> /dev/null; then
        local ws_status=$(oc get ksvc quarkus-websocket-knative -n "${NAMESPACE}" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
        if [ "$ws_status" = "True" ]; then
            log_success "Quarkus WebSocket service is ready"
            local ws_url=$(oc get ksvc quarkus-websocket-knative -n "${NAMESPACE}" -o jsonpath='{.status.url}')
            echo "  URL: ${ws_url}"
        else
            log_error "Quarkus WebSocket service is not ready"
        fi
    else
        log_error "Quarkus WebSocket service not found"
    fi
    
    # Check VEP service
    if oc get ksvc vep-service -n "${NAMESPACE}" &> /dev/null; then
        local vep_status=$(oc get ksvc vep-service -n "${NAMESPACE}" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
        if [ "$vep_status" = "True" ]; then
            log_success "VEP service is ready"
            local vep_url=$(oc get ksvc vep-service -n "${NAMESPACE}" -o jsonpath='{.status.url}')
            echo "  URL: ${vep_url}"
        else
            log_warning "VEP service is not ready (may need to be built)"
        fi
    else
        log_warning "VEP service not found (may need to be deployed)"
    fi
    
    # Check ML inference service
    if oc get deployment ml-inference-service -n "${NAMESPACE}" &> /dev/null; then
        local ml_ready=$(oc get deployment ml-inference-service -n "${NAMESPACE}" -o jsonpath='{.status.readyReplicas}')
        local ml_desired=$(oc get deployment ml-inference-service -n "${NAMESPACE}" -o jsonpath='{.spec.replicas}')
        if [ "${ml_ready:-0}" -eq "${ml_desired:-1}" ]; then
            log_success "ML inference service is ready"
        else
            log_warning "ML inference service is not ready"
        fi
    else
        log_warning "ML inference service not found"
    fi
    
    return 0
}

validate_openshift_ai() {
    log_info "Validating OpenShift AI components..."
    
    # Check if OpenShift AI namespace exists
    if oc get namespace redhat-ods-applications &> /dev/null; then
        log_success "OpenShift AI namespace exists"
    else
        log_warning "OpenShift AI namespace not found"
        return 1
    fi
    
    # Check Data Science Project
    if oc get datascienceproject genetic-risk-prediction -n "${NAMESPACE}" &> /dev/null; then
        log_success "Data Science Project exists"
    else
        log_warning "Data Science Project not found"
    fi
    
    # Check Notebook
    if oc get notebook genetic-analysis-workbench -n "${NAMESPACE}" &> /dev/null; then
        local notebook_status=$(oc get notebook genetic-analysis-workbench -n "${NAMESPACE}" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
        if [ "$notebook_status" = "True" ]; then
            log_success "Jupyter notebook is ready"
        else
            log_warning "Jupyter notebook is not ready"
        fi
    else
        log_warning "Jupyter notebook not found"
    fi
    
    # Check Inference Service
    if oc get inferenceservice genetic-risk-model -n "${NAMESPACE}" &> /dev/null; then
        local inference_status=$(oc get inferenceservice genetic-risk-model -n "${NAMESPACE}" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
        if [ "$inference_status" = "True" ]; then
            log_success "Inference service is ready"
        else
            log_warning "Inference service is not ready"
        fi
    else
        log_warning "Inference service not found"
    fi
    
    # Check Storage
    local pvcs=("genetic-analysis-workspace" "genetic-data-storage" "genetic-models-storage")
    for pvc in "${pvcs[@]}"; do
        if oc get pvc "${pvc}" -n "${NAMESPACE}" &> /dev/null; then
            local pvc_status=$(oc get pvc "${pvc}" -n "${NAMESPACE}" -o jsonpath='{.status.phase}')
            if [ "$pvc_status" = "Bound" ]; then
                log_success "PVC ${pvc} is bound"
            else
                log_warning "PVC ${pvc} is not bound (status: ${pvc_status})"
            fi
        else
            log_warning "PVC ${pvc} not found"
        fi
    done
    
    return 0
}

validate_eventing() {
    log_info "Validating eventing components..."
    
    # Check KEDA scalers
    local scalers=("quarkus-websocket-knative-scaler" "vep-service-scaler" "genetic-risk-model-scaler")
    for scaler in "${scalers[@]}"; do
        if oc get scaledobject "${scaler}" -n "${NAMESPACE}" &> /dev/null; then
            local scaler_status=$(oc get scaledobject "${scaler}" -n "${NAMESPACE}" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
            if [ "$scaler_status" = "True" ]; then
                log_success "KEDA scaler ${scaler} is ready"
            else
                log_warning "KEDA scaler ${scaler} is not ready"
            fi
        else
            log_warning "KEDA scaler ${scaler} not found"
        fi
    done
    
    return 0
}

validate_networking() {
    log_info "Validating networking and connectivity..."
    
    # Check routes/ingress
    if oc get route -n "${NAMESPACE}" &> /dev/null; then
        log_info "Routes found:"
        oc get route -n "${NAMESPACE}" -o custom-columns=NAME:.metadata.name,HOST:.spec.host
    else
        log_info "No routes found (using Knative services)"
    fi
    
    # Check Knative services
    if oc get ksvc -n "${NAMESPACE}" &> /dev/null; then
        log_info "Knative services:"
        oc get ksvc -n "${NAMESPACE}" -o custom-columns=NAME:.metadata.name,URL:.status.url,READY:.status.conditions[0].status
    fi
    
    return 0
}

validate_cost_management() {
    log_info "Validating cost management configuration..."
    
    # Check cost labels on namespace
    local cost_labels=$(oc get namespace "${NAMESPACE}" -o jsonpath='{.metadata.labels}' | grep -o 'insights\.openshift\.io' | wc -l)
    if [ "$cost_labels" -gt 0 ]; then
        log_success "Cost management labels found on namespace"
    else
        log_warning "Cost management labels not found on namespace"
    fi
    
    # Check cost labels on resources
    local labeled_resources=$(oc get all -n "${NAMESPACE}" -o jsonpath='{range .items[*]}{.metadata.annotations.insights\.openshift\.io/billing-model}{"\n"}{end}' | grep -c chargeback || echo 0)
    if [ "$labeled_resources" -gt 0 ]; then
        log_success "Cost management labels found on ${labeled_resources} resources"
    else
        log_warning "Cost management labels not found on resources"
    fi
    
    return 0
}

# Main validation function
main() {
    log_info "Starting enhanced healthcare ML infrastructure validation..."
    log_info "Namespace: ${NAMESPACE}"
    
    local validation_passed=true
    
    # Run all validations
    validate_operators || validation_passed=false
    validate_infrastructure || validation_passed=false
    validate_applications || validation_passed=false
    validate_openshift_ai || validation_passed=false
    validate_eventing || validation_passed=false
    validate_networking || validation_passed=false
    validate_cost_management || validation_passed=false
    
    # Summary
    echo ""
    log_info "Validation Summary:"
    if [ "$validation_passed" = true ]; then
        log_success "All validations passed!"
    else
        log_warning "Some validations failed or showed warnings"
    fi
    
    # Next steps
    echo ""
    log_info "Next steps for complete setup:"
    echo "  1. Build VEP service if not ready: oc start-build vep-service -n ${NAMESPACE}"
    echo "  2. Access Jupyter notebook for ML model development"
    echo "  3. Train genetic risk prediction model"
    echo "  4. Deploy trained model to inference service"
    echo "  5. Test end-to-end pipeline with genetic sequences"
    echo "  6. Monitor scaling and costs in OpenShift console"
}

# Run main function
main "$@"
