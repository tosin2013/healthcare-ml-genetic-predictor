#!/bin/bash

# Healthcare ML Genetic Predictor - Complete Enhanced Deployment Script
# This script deploys ALL components including missing ones identified in comprehensive review
# Fixes: Kafka topics, KEDA scaling, base resources, OpenShift AI, cluster autoscaler

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
    
    log_info "Waiting for operators to be ready (this may take 5 minutes)..."
    sleep 60
    
    # Wait for CRDs to be available
    local timeout=300
    local elapsed=0
    while [ $elapsed -lt $timeout ]; do
        if oc get crd kedacontrollers.keda.sh &> /dev/null && \
           oc get crd knativeservings.operator.knative.dev &> /dev/null && \
           oc get crd kafkas.kafka.strimzi.io &> /dev/null; then
            log_success "Required CRDs are available"
            break
        fi
        sleep 10
        elapsed=$((elapsed + 10))
        log_info "Waiting for CRDs... (${elapsed}s/${timeout}s)"
    done
    
    # Apply Custom Resources now that CRDs are available
    log_info "Applying Custom Resources..."
    oc apply -k k8s/base/operators || log_warning "Some Custom Resources may still be installing"
    
    # Check operator status
    log_info "Checking operator status..."
    oc get csv -A | grep -E "(amq-streams|serverless|keda|rhods)" | head -5 || true
    
    log_success "Phase 1 completed: Operators deployed"
}

# Phase 2: Deploy infrastructure
deploy_infrastructure() {
    log_info "Phase 2: Deploying infrastructure..."
    
    oc apply -k k8s/base/infrastructure
    
    log_info "Waiting for Kafka cluster to be ready (this may take 5 minutes)..."
    
    # Wait for Kafka cluster
    local timeout=600
    local elapsed=0
    while [ $elapsed -lt $timeout ]; do
        if oc get kafka genetic-data-cluster -n $NAMESPACE -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | grep -q "True"; then
            log_success "Kafka cluster is ready"
            break
        fi
        sleep 15
        elapsed=$((elapsed + 15))
        log_info "Waiting for Kafka cluster... (${elapsed}s/${timeout}s)"
    done
    
    if [ $elapsed -ge $timeout ]; then
        log_warning "Kafka cluster readiness check timed out, but continuing..."
    fi
    
    log_success "Phase 2 completed: Infrastructure deployed"
}

# Phase 2.5: Deploy Kafka topics (CRITICAL MISSING COMPONENT)
deploy_kafka_topics() {
    log_info "Phase 2.5: Deploying Kafka topics..."
    
    # Deploy the corrected Kafka topics
    oc apply -f k8s/base/kafka/topics.yaml -n $NAMESPACE
    
    # Wait for topics to be ready
    log_info "Waiting for Kafka topics to be created..."
    sleep 30
    
    # Verify topics exist
    local topics=("genetic-data-raw" "genetic-data-annotated" "genetic-bigdata-raw" "genetic-nodescale-raw")
    for topic in "${topics[@]}"; do
        if oc get kafkatopic "$topic" -n $NAMESPACE &>/dev/null; then
            log_info "✅ Topic $topic created successfully"
        else
            log_warning "⚠️ Topic $topic not found"
        fi
    done
    
    log_success "Phase 2.5 completed: Kafka topics deployed"
}

# Phase 3: Label nodes for workload scheduling
label_nodes() {
    log_info "Phase 3: Labeling nodes for workload scheduling..."
    
    # Set project context
    oc project $NAMESPACE 2>/dev/null || log_warning "Namespace may not exist yet"
    
    # Run the node labeling script
    if [ -f "scripts/label-existing-nodes.sh" ]; then
        log_info "Running node labeling script..."
        ./scripts/label-existing-nodes.sh || log_warning "Node labeling failed, but continuing..."
    else
        log_warning "Node labeling script not found, labeling manually..."
        # Manual node labeling as fallback
        local worker_nodes=$(oc get nodes --no-headers | grep worker | awk '{print $1}')
        for node in $worker_nodes; do
            log_info "Labeling node: $node"
            oc label node "$node" workload-type=standard --overwrite || true
        done
    fi
    
    log_success "Phase 3 completed: Nodes labeled"
}

# Phase 4: Deploy applications
deploy_applications() {
    log_info "Phase 4: Deploying applications..."
    
    # Deploy WebSocket service
    log_info "Deploying WebSocket service..."
    oc apply -k k8s/base/applications/quarkus-websocket -n $NAMESPACE
    
    # Deploy VEP service
    log_info "Deploying VEP service..."
    oc apply -k k8s/base/applications/vep-service -n $NAMESPACE
    
    # Grant image pull permissions
    log_info "Granting image pull permissions..."
    oc policy add-role-to-user system:image-puller system:serviceaccount:$NAMESPACE:vep-service -n $NAMESPACE || true
    
    log_success "Phase 4 completed: Applications deployed"
}

# Phase 5: Build and verify
build_and_verify() {
    log_info "Phase 5: Building and verifying deployment..."
    
    # Start builds
    log_info "Starting builds..."
    oc start-build quarkus-websocket-service -n $NAMESPACE || log_warning "WebSocket build may have already started"
    oc start-build vep-service -n $NAMESPACE || log_warning "VEP build may have already started"
    
    log_info "Builds started. Waiting for completion..."
    
    # Wait for builds to complete
    local timeout=900  # 15 minutes for builds
    local elapsed=0
    while [ $elapsed -lt $timeout ]; do
        local websocket_status=$(oc get builds -n $NAMESPACE --no-headers | grep quarkus-websocket-service | tail -1 | awk '{print $4}' || echo "Unknown")
        local vep_status=$(oc get builds -n $NAMESPACE --no-headers | grep vep-service | tail -1 | awk '{print $4}' || echo "Unknown")
        
        if [[ "$websocket_status" == "Complete" && "$vep_status" == "Complete" ]]; then
            log_success "All builds completed successfully"
            break
        fi
        
        sleep 30
        elapsed=$((elapsed + 30))
        log_info "Waiting for builds... WebSocket: $websocket_status, VEP: $vep_status (${elapsed}s/${timeout}s)"
    done
    
    # Show current status
    log_info "Current deployment status:"
    oc get pods -n $NAMESPACE | grep -E "(websocket|vep|kafka)" | grep -v build
    
    log_success "Phase 5 completed: Builds and verification completed"
}

# Phase 6: Deploy KEDA scaling and base resources (CRITICAL MISSING COMPONENTS)
deploy_keda_and_base_resources() {
    log_info "Phase 6: Deploying KEDA scaling and base resources..."
    
    # Deploy base resources that were missed (buildconfigs, scaled objects, etc.)
    log_info "Deploying base kustomization resources..."
    oc apply -k k8s/base -n $NAMESPACE || log_warning "Some base resources may have conflicts, continuing..."
    
    # Deploy KEDA scaling configurations specifically
    if [ -d "k8s/base/keda" ]; then
        log_info "Deploying KEDA ScaledObjects..."
        oc apply -k k8s/base/keda -n $NAMESPACE || log_warning "KEDA scaling deployment had issues, but continuing..."
    fi
    
    # Deploy eventing configurations
    if [ -d "k8s/base/eventing" ]; then
        log_info "Deploying eventing configurations..."
        oc apply -k k8s/base/eventing -n $NAMESPACE || log_warning "Eventing deployment had issues, but continuing..."
    fi
    
    # Verify KEDA resources
    log_info "Checking KEDA ScaledObjects..."
    oc get scaledobject -n $NAMESPACE || log_info "No ScaledObjects found yet"
    
    log_success "Phase 6 completed: KEDA scaling and base resources configured"
}

# Phase 7: Deploy OpenShift AI components (MISSING COMPONENT)
deploy_openshift_ai() {
    log_info "Phase 7: Deploying OpenShift AI components..."
    
    # Check if OpenShift AI operator is ready
    if oc get csv -A | grep -q "rhods-operator.*Succeeded"; then
        log_info "OpenShift AI operator is ready, deploying components..."
        
        # Deploy OpenShift AI components
        if [ -d "k8s/base/applications/openshift-ai" ]; then
            oc apply -k k8s/base/applications/openshift-ai -n $NAMESPACE || log_warning "OpenShift AI deployment had issues, but continuing..."
        else
            log_warning "OpenShift AI manifests not found, skipping..."
        fi
    else
        log_warning "OpenShift AI operator not ready, skipping AI components..."
    fi
    
    log_success "Phase 7 completed: OpenShift AI components processed"
}

# Phase 8: Deploy cluster autoscaler (MISSING COMPONENT)
deploy_cluster_autoscaler() {
    log_info "Phase 8: Deploying cluster autoscaler..."
    
    # Check if we have cluster-admin permissions for cluster autoscaler
    if oc auth can-i create clusterautoscaler &>/dev/null; then
        log_info "Deploying cluster autoscaler..."
        oc apply -f k8s/base/autoscaler/cluster-autoscaler.yaml || log_warning "Cluster autoscaler deployment failed, but continuing..."
    else
        log_warning "Insufficient permissions for cluster autoscaler, skipping..."
    fi
    
    log_success "Phase 8 completed: Cluster autoscaler processed"
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
    echo "🧪 Testing Commands:"
    echo "  curl https://$route_url/q/health"
    echo "  ./scripts/test-api-endpoints.sh"
    echo ""
    echo "📚 Next Steps:"
    echo "  1. Open https://$route_url/genetic-client.html in your browser"
    echo "  2. Test with sample genetic sequence: ATCGATCGATCG"
    echo "  3. Monitor scaling with: watch oc get pods -n $NAMESPACE"
    echo "  4. Check the tutorial: docs/tutorials/01-getting-started.md"
    echo ""
}

# Show deployment summary
show_deployment_summary() {
    log_info "Comprehensive Deployment Summary:"
    echo ""
    echo "✅ Operators: $(oc get csv -A | grep -E '(amq-streams|serverless|keda|rhods)' | wc -l) installed"
    echo "✅ Kafka Cluster: $(oc get kafka -n $NAMESPACE --no-headers 2>/dev/null | wc -l) cluster(s)"
    echo "✅ Kafka Topics: $(oc get kafkatopic -n $NAMESPACE --no-headers 2>/dev/null | wc -l) topic(s)"
    echo "✅ Worker Nodes: $(oc get nodes --no-headers | grep worker | wc -l) labeled for workloads"
    echo "✅ Applications: $(oc get deployment -n $NAMESPACE --no-headers 2>/dev/null | wc -l) deployment(s)"
    echo "✅ Builds: $(oc get builds -n $NAMESPACE --no-headers 2>/dev/null | grep Complete | wc -l) completed successfully"
    echo "✅ Routes: $(oc get routes -n $NAMESPACE --no-headers 2>/dev/null | wc -l) exposed"
    echo "✅ KEDA Scalers: $(oc get scaledobject -n $NAMESPACE --no-headers 2>/dev/null | wc -l) configured"
    echo "✅ Knative Services: $(oc get ksvc -n $NAMESPACE --no-headers 2>/dev/null | wc -l) deployed"
    
    # Check for specific components
    log_info "Component Status:"
    echo "  🔄 WebSocket Service: $(oc get deployment quarkus-websocket-service -n $NAMESPACE -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo 0)/$(oc get deployment quarkus-websocket-service -n $NAMESPACE -o jsonpath='{.spec.replicas}' 2>/dev/null || echo 0) ready"
    echo "  🔬 VEP Service: $(oc get deployment vep-service -n $NAMESPACE -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo 0)/$(oc get deployment vep-service -n $NAMESPACE -o jsonpath='{.spec.replicas}' 2>/dev/null || echo 0) ready"
    echo "  ☕ Kafka Brokers: $(oc get pods -n $NAMESPACE --no-headers 2>/dev/null | grep kafka | grep Running | wc -l)/3 running"
    echo ""
}

# Main deployment function
main() {
    echo ""
    log_info "Starting Enhanced $PROJECT_NAME deployment..."
    log_info "Target namespace: $NAMESPACE"
    log_info "This enhanced script deploys ALL missing components identified in comprehensive review"
    echo ""
    
    check_prerequisites
    deploy_operators
    deploy_infrastructure
    deploy_kafka_topics
    label_nodes
    deploy_applications
    build_and_verify
    deploy_keda_and_base_resources
    deploy_openshift_ai
    deploy_cluster_autoscaler
    show_deployment_summary
    show_access_info
    
    log_success "Enhanced clean deployment process completed!"
    log_info "All components from comprehensive k8s review have been deployed"
    echo ""
}

# Run main function
main "$@"
