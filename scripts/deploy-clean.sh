#!/bin/bash

# Healthcare ML Genetic Predictor - Clean Deployment Script
# This script deploys the complete application stack on a clean OpenShift cluster

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="healthcare-ml-demo"
PROJECT_NAME="Healthcare ML Genetic Predictor"

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
    
    # Check if logged in to OpenShift
    if ! oc whoami &> /dev/null; then
        log_error "Not logged in to OpenShift. Please run 'oc login'"
        exit 1
    fi
    
    # Check if kustomize is available
    if ! command -v kustomize &> /dev/null && ! oc kustomize --help &> /dev/null; then
        log_error "Kustomize is not available. Please install kustomize or use oc 4.1+"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Phase 1: Deploy operators
deploy_operators() {
    log_info "Phase 1: Deploying operators..."
    
    oc apply -k k8s/base/operators
    
    log_info "Waiting for operators to be ready (this may take 2-3 minutes)..."
    sleep 30
    
    # Check operator status
    log_info "Checking operator status..."
    oc get csv -n openshift-operators | grep -E "(amq-streams|serverless|keda)" || true
    
    log_success "Phase 1 completed: Operators deployed"
}

# Phase 2: Deploy infrastructure
deploy_infrastructure() {
    log_info "Phase 2: Deploying infrastructure..."
    
    oc apply -k k8s/base/infrastructure
    
    log_info "Waiting for Kafka cluster to be ready (this may take 2-3 minutes)..."
    
    # Wait for Kafka cluster
    local timeout=300
    local elapsed=0
    while [ $elapsed -lt $timeout ]; do
        if oc get kafka genetic-data-cluster -n $NAMESPACE -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | grep -q "True"; then
            log_success "Kafka cluster is ready"
            break
        fi
        sleep 10
        elapsed=$((elapsed + 10))
        log_info "Waiting for Kafka cluster... (${elapsed}s/${timeout}s)"
    done
    
    if [ $elapsed -ge $timeout ]; then
        log_warning "Kafka cluster readiness check timed out, but continuing..."
    fi
    
    log_success "Phase 2 completed: Infrastructure deployed"
}

# Phase 3: Deploy applications
deploy_applications() {
    log_info "Phase 3: Deploying applications..."
    
    # Deploy WebSocket service
    log_info "Deploying WebSocket service..."
    oc apply -k k8s/base/applications/quarkus-websocket -n $NAMESPACE
    
    # Deploy VEP service
    log_info "Deploying VEP service..."
    oc apply -k k8s/base/applications/vep-service -n $NAMESPACE
    
    # Grant image pull permissions
    log_info "Granting image pull permissions..."
    oc policy add-role-to-user system:image-puller system:serviceaccount:$NAMESPACE:vep-service -n $NAMESPACE
    
    log_success "Phase 3 completed: Applications deployed"
}

# Phase 4: Build and verify
build_and_verify() {
    log_info "Phase 4: Building and verifying deployment..."
    
    # Start builds
    log_info "Starting builds..."
    oc start-build quarkus-websocket-service -n $NAMESPACE
    oc start-build vep-service -n $NAMESPACE
    
    log_info "Builds started. Monitor progress with:"
    echo "  oc get builds -n $NAMESPACE -w"
    
    # Wait a bit for builds to start
    sleep 10
    
    # Show current status
    log_info "Current build status:"
    oc get builds -n $NAMESPACE | tail -5
    
    log_info "Current pod status:"
    oc get pods -n $NAMESPACE | grep -E "(websocket|vep|kafka)" | grep -v build
    
    log_success "Phase 4 completed: Builds initiated"
}

# Show access information
show_access_info() {
    log_info "Getting access information..."
    
    # Get route URL
    local route_url=$(oc get route quarkus-websocket-service -n $NAMESPACE -o jsonpath='{.spec.host}' 2>/dev/null || echo "Route not ready yet")
    
    echo ""
    log_success "Deployment completed successfully!"
    echo ""
    echo "📊 Access Information:"
    echo "  🌐 WebSocket Service: https://$route_url"
    echo "  🧬 Genetic Client: https://$route_url/genetic-client.html"
    echo "  📈 Health Check: https://$route_url/q/health"
    echo ""
    echo "🔍 Monitoring Commands:"
    echo "  oc get pods -n $NAMESPACE"
    echo "  oc get builds -n $NAMESPACE"
    echo "  oc get ksvc -n $NAMESPACE"
    echo "  oc logs -f deployment/quarkus-websocket-service -n $NAMESPACE"
    echo ""
}

# Main deployment function
main() {
    echo ""
    log_info "Starting $PROJECT_NAME deployment..."
    log_info "Target namespace: $NAMESPACE"
    echo ""
    
    check_prerequisites
    deploy_operators
    deploy_infrastructure
    deploy_applications
    build_and_verify
    show_access_info
    
    log_success "Clean deployment process completed!"
    echo ""
}

# Run main function
main "$@"
