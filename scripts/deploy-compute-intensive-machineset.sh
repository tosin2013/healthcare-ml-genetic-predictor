#!/bin/bash

# Deploy Compute-Intensive MachineSet for Node Scaling Demo
# This script automatically detects cluster configuration and deploys cost-optimized compute-intensive nodes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

log_info "🚀 Deploying Compute-Intensive MachineSet for Node Scaling Demo"
log_info "   Cost-optimized for demo environments"
echo ""

# Check prerequisites
if ! command -v oc &> /dev/null; then
    log_error "OpenShift CLI (oc) is not installed"
    exit 1
fi

if ! oc whoami &> /dev/null; then
    log_error "Not logged in to OpenShift. Please run 'oc login'"
    exit 1
fi

# Auto-detect cluster configuration
log_info "🔍 Auto-detecting cluster configuration..."

CLUSTER_NAME=$(oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}' 2>/dev/null)
if [ -z "$CLUSTER_NAME" ]; then
    log_error "Could not detect cluster name"
    exit 1
fi
log_info "   Cluster Name: $CLUSTER_NAME"

REGION=$(oc get infrastructure cluster -o jsonpath='{.status.platformStatus.azure.region}' 2>/dev/null)
if [ -z "$REGION" ]; then
    # Try alternative methods for different cloud providers
    REGION=$(oc get nodes -o jsonpath='{.items[0].metadata.labels.topology\.kubernetes\.io/region}' 2>/dev/null)
    if [ -z "$REGION" ]; then
        log_error "Could not detect region"
        exit 1
    fi
fi
log_info "   Region: $REGION"

# Get resource group from existing machine set
RESOURCE_GROUP=$(oc get machineset -n openshift-machine-api -o jsonpath='{.items[0].spec.template.spec.providerSpec.value.resourceGroup}' 2>/dev/null)
if [ -z "$RESOURCE_GROUP" ]; then
    log_error "Could not detect resource group"
    exit 1
fi
log_info "   Resource Group: $RESOURCE_GROUP"

# Get network resource group
NETWORK_RESOURCE_GROUP=$(oc get machineset -n openshift-machine-api -o jsonpath='{.items[0].spec.template.spec.providerSpec.value.networkResourceGroup}' 2>/dev/null)
if [ -z "$NETWORK_RESOURCE_GROUP" ]; then
    NETWORK_RESOURCE_GROUP=$RESOURCE_GROUP
    log_warning "Using same resource group for network: $NETWORK_RESOURCE_GROUP"
fi
log_info "   Network Resource Group: $NETWORK_RESOURCE_GROUP"

# Get VNet name
VNET_NAME=$(oc get machineset -n openshift-machine-api -o jsonpath='{.items[0].spec.template.spec.providerSpec.value.vnet}' 2>/dev/null)
if [ -z "$VNET_NAME" ]; then
    log_error "Could not detect VNet name"
    exit 1
fi
log_info "   VNet Name: $VNET_NAME"

echo ""
log_info "📝 Creating compute-intensive machine set configuration..."

# Create temporary file with substituted values
TEMP_FILE=$(mktemp)
sed "s/{{CLUSTER_NAME}}/$CLUSTER_NAME/g; s/{{REGION}}/$REGION/g; s/{{RESOURCE_GROUP}}/$RESOURCE_GROUP/g; s/{{NETWORK_RESOURCE_GROUP}}/$NETWORK_RESOURCE_GROUP/g; s/{{VNET_NAME}}/$VNET_NAME/g" \
    k8s/base/autoscaler/compute-intensive-machineset.yaml > "$TEMP_FILE"

# Show what will be deployed
log_info "📋 Configuration Summary:"
echo "   Machine Set: ${CLUSTER_NAME}-worker-compute-intensive-${REGION}1"
echo "   Instance Type: Standard_D8s_v3 (8 vCPU, 32GB RAM)"
echo "   Max Replicas: 2 nodes"
echo "   Cost Optimization: Scale to zero when idle"
echo ""

# Deploy the machine set
log_info "🚀 Deploying compute-intensive machine set..."
if oc apply -f "$TEMP_FILE"; then
    log_success "Compute-intensive machine set deployed successfully!"
else
    log_error "Failed to deploy machine set"
    rm "$TEMP_FILE"
    exit 1
fi

# Clean up
rm "$TEMP_FILE"

echo ""
log_info "🔍 Checking deployment status..."
oc get machineset "${CLUSTER_NAME}-worker-compute-intensive-${REGION}1" -n openshift-machine-api
oc get machineautoscaler "compute-intensive-${REGION}1-autoscaler" -n openshift-machine-api

echo ""
log_success "✅ Compute-intensive autoscaler is ready!"
echo ""
echo "🎯 What happens next:"
echo "   1. When VEP nodescale pods need compute-intensive nodes"
echo "   2. Cluster autoscaler will provision new D4s_v3 instances"  
echo "   3. Nodes will be labeled as workload-type=compute-intensive"
echo "   4. VEP pods will schedule and trigger the node scaling demo"
echo ""
echo "💡 Monitor with:"
echo "   oc get machines -n openshift-machine-api"
echo "   oc get nodes -l workload-type=compute-intensive"
echo "   oc get pods -l app=vep-service-nodescale"
echo ""
