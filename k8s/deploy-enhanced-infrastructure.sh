#!/bin/bash

# Enhanced Healthcare ML Infrastructure Deployment Script
# Includes VEP Service Extraction and OpenShift AI Integration

set -euo pipefail

# Configuration
NAMESPACE="healthcare-ml-demo"
PROJECT_NAME="healthcare-ml-genetic-predictor"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="${SCRIPT_DIR}/base"
OVERLAY_DIR="${SCRIPT_DIR}/overlays/dev"

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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if oc is installed
    if ! command -v oc &> /dev/null; then
        log_error "OpenShift CLI (oc) is not installed"
        exit 1
    fi
    
    # Check if kustomize is installed
    if ! command -v kustomize &> /dev/null; then
        log_error "Kustomize is not installed"
        exit 1
    fi
    
    # Check if logged into OpenShift
    if ! oc whoami &> /dev/null; then
        log_error "Not logged into OpenShift cluster"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Create namespace if it doesn't exist
create_namespace() {
    log_info "Creating namespace: ${NAMESPACE}"
    
    if oc get namespace "${NAMESPACE}" &> /dev/null; then
        log_warning "Namespace ${NAMESPACE} already exists"
    else
        oc create namespace "${NAMESPACE}"
        log_success "Namespace ${NAMESPACE} created"
    fi
    
    # Add cost management labels
    oc label namespace "${NAMESPACE}" \
        insights.openshift.io/billing-model=chargeback \
        insights.openshift.io/cost-center=genomics-research \
        insights.openshift.io/project=risk-predictor-v1 \
        --overwrite
}

# Deploy operators (Phase 1)
deploy_operators() {
    log_info "Deploying operators..."
    
    # AMQ Streams (Kafka)
    log_info "Deploying AMQ Streams operator..."
    kustomize build "${BASE_DIR}/operators/amq-streams" | oc apply -f -
    
    # Serverless
    log_info "Deploying Serverless operator..."
    kustomize build "${BASE_DIR}/operators/serverless" | oc apply -f -
    
    # KEDA
    log_info "Deploying KEDA operator..."
    kustomize build "${BASE_DIR}/operators/keda" | oc apply -f -
    
    # OpenShift AI
    log_info "Deploying OpenShift AI operator..."
    kustomize build "${BASE_DIR}/operators/openshift-ai" | oc apply -f -
    
    log_success "Operators deployment initiated"
    
    # Wait for operators to be ready
    log_info "Waiting for operators to be ready..."
    sleep 30
    
    # Check operator status
    oc get csv -n openshift-operators | grep -E "(amq-streams|serverless|keda|rhods)"
}

# Deploy infrastructure (Phase 2)
deploy_infrastructure() {
    log_info "Deploying infrastructure components..."
    
    # Kafka cluster
    log_info "Deploying Kafka cluster..."
    kustomize build "${BASE_DIR}/infrastructure/kafka" | oc apply -f - -n "${NAMESPACE}"
    
    # Wait for Kafka to be ready
    log_info "Waiting for Kafka cluster to be ready..."
    oc wait --for=condition=Ready kafka/genetic-data-cluster -n "${NAMESPACE}" --timeout=300s
    
    log_success "Infrastructure deployment completed"
}

# Deploy applications (Phase 3)
deploy_applications() {
    log_info "Deploying application components..."
    
    # Deploy in order: WebSocket service, VEP service, ML inference, OpenShift AI, Frontend
    
    # Quarkus WebSocket service
    log_info "Deploying Quarkus WebSocket service..."
    kustomize build "${BASE_DIR}/applications/quarkus-websocket" | oc apply -f - -n "${NAMESPACE}"
    
    # VEP service
    log_info "Deploying VEP annotation service..."
    kustomize build "${BASE_DIR}/applications/vep-service" | oc apply -f - -n "${NAMESPACE}"
    
    # ML inference service
    log_info "Deploying ML inference service..."
    kustomize build "${BASE_DIR}/applications/ml-inference" | oc apply -f - -n "${NAMESPACE}"
    
    # OpenShift AI components
    log_info "Deploying OpenShift AI components..."
    kustomize build "${BASE_DIR}/applications/openshift-ai" | oc apply -f - -n "${NAMESPACE}"
    
    # Frontend
    log_info "Deploying frontend..."
    kustomize build "${BASE_DIR}/applications/frontend" | oc apply -f - -n "${NAMESPACE}"
    
    log_success "Applications deployment completed"
}

# Deploy eventing (Phase 4)
deploy_eventing() {
    log_info "Deploying eventing components..."
    
    # Kafka sources
    log_info "Deploying Kafka sources..."
    kustomize build "${BASE_DIR}/eventing/kafka-source" | oc apply -f - -n "${NAMESPACE}"
    
    # KEDA scalers
    log_info "Deploying KEDA scalers..."
    kustomize build "${BASE_DIR}/eventing/keda-scaler" | oc apply -f - -n "${NAMESPACE}"
    
    # VEP KEDA scaler
    log_info "Deploying VEP KEDA scaler..."
    oc apply -f "${BASE_DIR}/eventing/vep-keda-scaler.yaml" -n "${NAMESPACE}"
    
    log_success "Eventing deployment completed"
}

# Validate deployment
validate_deployment() {
    log_info "Validating deployment..."
    
    # Check pods
    log_info "Checking pod status..."
    oc get pods -n "${NAMESPACE}"
    
    # Check services
    log_info "Checking services..."
    oc get svc -n "${NAMESPACE}"
    
    # Check Knative services
    log_info "Checking Knative services..."
    oc get ksvc -n "${NAMESPACE}"
    
    # Check KEDA scalers
    log_info "Checking KEDA scalers..."
    oc get scaledobject -n "${NAMESPACE}"
    
    # Check OpenShift AI components
    log_info "Checking OpenShift AI components..."
    oc get notebook -n "${NAMESPACE}" || log_warning "No notebooks found"
    oc get inferenceservice -n "${NAMESPACE}" || log_warning "No inference services found"
    
    # Get application URLs
    log_info "Application URLs:"
    WEBSOCKET_URL=$(oc get ksvc quarkus-websocket-knative -n "${NAMESPACE}" -o jsonpath='{.status.url}' 2>/dev/null || echo "Not available")
    VEP_URL=$(oc get ksvc vep-service -n "${NAMESPACE}" -o jsonpath='{.status.url}' 2>/dev/null || echo "Not available")
    
    echo "  WebSocket Service: ${WEBSOCKET_URL}"
    echo "  VEP Service: ${VEP_URL}"
    
    log_success "Deployment validation completed"
}

# Main deployment function
main() {
    log_info "Starting enhanced healthcare ML infrastructure deployment..."
    log_info "Project: ${PROJECT_NAME}"
    log_info "Namespace: ${NAMESPACE}"
    
    check_prerequisites
    create_namespace
    deploy_operators
    deploy_infrastructure
    deploy_applications
    deploy_eventing
    validate_deployment
    
    log_success "Enhanced healthcare ML infrastructure deployment completed!"
    log_info "Next steps:"
    echo "  1. Build VEP service: oc start-build vep-service -n ${NAMESPACE}"
    echo "  2. Create Jupyter notebook for ML model development"
    echo "  3. Train and deploy genetic risk prediction model"
    echo "  4. Test multi-tier scaling with big data mode"
    echo "  5. Monitor costs with Red Hat Insights Cost Management"
}

# Run main function
main "$@"
