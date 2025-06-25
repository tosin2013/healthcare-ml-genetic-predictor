#!/bin/bash

# Healthcare ML - Dynamic Cluster Autoscaler Configuration Script
# Detects current cluster machinesets and generates correct autoscaler config

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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites for cluster autoscaler setup..."
    
    # Check if oc is installed and we're logged in
    if ! oc whoami &> /dev/null; then
        log_error "Not logged in to OpenShift. Please run 'oc login'"
        exit 1
    fi
    
    # Check if we have permissions to view machinesets
    if ! oc auth can-i get machinesets -n openshift-machine-api &>/dev/null; then
        log_error "Insufficient permissions to view machinesets"
        exit 1
    fi
    
    # Check if we have permissions to create cluster autoscaler
    if ! oc auth can-i create clusterautoscaler &>/dev/null; then
        log_warning "No permissions to create cluster autoscaler (cluster-admin required)"
        log_info "Will generate config file for manual application"
    fi
    
    log_success "Prerequisites check completed"
}

# Detect cluster machinesets
detect_machinesets() {
    log_info "Detecting cluster machinesets..."
    
    # Get all worker machinesets
    MACHINESETS=$(oc get machinesets -n openshift-machine-api --no-headers | grep worker | awk '{print $1}')
    
    if [ -z "$MACHINESETS" ]; then
        log_error "No worker machinesets found"
        exit 1
    fi
    
    log_info "Found worker machinesets:"
    for ms in $MACHINESETS; do
        echo "  - $ms"
    done
    
    # Extract cluster name from first machineset
    CLUSTER_NAME=$(echo "$MACHINESETS" | head -1 | cut -d'-' -f1-3)
    log_info "Detected cluster name: $CLUSTER_NAME"
    
    # Count availability zones
    AZ_COUNT=$(echo "$MACHINESETS" | wc -l)
    log_info "Detected $AZ_COUNT availability zones"
}

# Generate cluster autoscaler configuration
generate_cluster_autoscaler_config() {
    log_info "Generating cluster autoscaler configuration..."
    
    local config_file="/tmp/cluster-autoscaler-${CLUSTER_NAME}.yaml"
    
    cat > "$config_file" << EOF
apiVersion: autoscaling.openshift.io/v1
kind: ClusterAutoscaler
metadata:
  name: default
  annotations:
    description: "Cluster autoscaler for healthcare ML node scaling demo"
    insights.openshift.io/cost-center: "genomics-research"
    insights.openshift.io/project: "node-scaling-demo"
    cluster-name: "${CLUSTER_NAME}"
spec:
  # Resource limits for autoscaling
  resourceLimits:
    maxNodesTotal: 20  # Maximum total nodes in cluster
    cores:
      min: 24          # Minimum total CPU cores (current: ~24)
      max: 160         # Maximum total CPU cores (20 nodes * 8 cores)
    memory:
      min: 98304       # Minimum total memory in MiB (current: ~96GB)
      max: 655360      # Maximum total memory in MiB (20 nodes * 32GB avg)

  # Scaling behavior
  scaleDown:
    enabled: true
    delayAfterAdd: 10m           # Wait 10 minutes after adding node before considering scale down
    delayAfterDelete: 10s        # Wait 10 seconds after deleting node
    delayAfterFailure: 3m        # Wait 3 minutes after failed scale down
    unneededTime: 10m            # Node must be unneeded for 10 minutes before scale down
    utilizationThreshold: "0.5"  # Scale down if node utilization < 50%
  
  # Pod disruption settings
  podPriorityThreshold: -10      # Only consider pods with priority >= -10 for scaling decisions
  skipNodesWithLocalStorage: true
  skipNodesWithSystemPods: true
  
  # Balancing policy
  balanceSimilarNodeGroups: false
  ignoreDaemonSetsUtilization: false
  maxPodGracePeriod: 600         # 10 minutes max for pod termination
  maxNodeProvisionTime: 15m      # 15 minutes max for new node to become ready
  
  # Logging
  logVerbosity: 1

EOF

    log_success "Generated cluster autoscaler config: $config_file"
    echo "$config_file"
}

# Generate machine autoscaler configurations
generate_machine_autoscaler_configs() {
    log_info "Generating machine autoscaler configurations..."
    
    local config_file="/tmp/machine-autoscaler-${CLUSTER_NAME}.yaml"
    
    cat > "$config_file" << EOF
# Machine Autoscaler configurations for cluster: ${CLUSTER_NAME}
# Generated on: $(date)
EOF

    local count=1
    for machineset in $MACHINESETS; do
        # Extract zone from machineset name
        local zone=""
        if [[ "$machineset" == *"eastus1"* ]]; then
            zone="eastus1"
        elif [[ "$machineset" == *"eastus2"* ]]; then
            zone="eastus2" 
        elif [[ "$machineset" == *"eastus3"* ]]; then
            zone="eastus3"
        else
            zone="zone${count}"
        fi
        
        cat >> "$config_file" << EOF

---
apiVersion: autoscaling.openshift.io/v1beta1
kind: MachineAutoscaler
metadata:
  name: worker-${zone}-autoscaler
  namespace: openshift-machine-api
  annotations:
    description: "Machine autoscaler for ${zone} worker nodes"
    insights.openshift.io/cost-center: "genomics-research"
    cluster-name: "${CLUSTER_NAME}"
    machineset-name: "${machineset}"
spec:
  minReplicas: 1
  maxReplicas: 5  # Adjust based on your needs
  scaleTargetRef:
    apiVersion: machine.openshift.io/v1beta1
    kind: MachineSet
    name: ${machineset}
EOF

        count=$((count + 1))
    done
    
    log_success "Generated machine autoscaler configs: $config_file"
    echo "$config_file"
}

# Apply configurations
apply_configurations() {
    local cluster_config="$1"
    local machine_config="$2"
    
    log_info "Applying autoscaler configurations..."
    
    # Apply cluster autoscaler
    if oc auth can-i create clusterautoscaler &>/dev/null; then
        log_info "Applying cluster autoscaler..."
        oc apply -f "$cluster_config"
        log_success "Cluster autoscaler applied"
    else
        log_warning "No permissions to apply cluster autoscaler"
        log_info "Manual application required: oc apply -f $cluster_config"
    fi
    
    # Apply machine autoscalers
    if oc auth can-i create machineautoscaler -n openshift-machine-api &>/dev/null; then
        log_info "Applying machine autoscalers..."
        oc apply -f "$machine_config"
        log_success "Machine autoscalers applied"
    else
        log_warning "No permissions to apply machine autoscalers"
        log_info "Manual application required: oc apply -f $machine_config"
    fi
}

# Verify autoscaler setup
verify_setup() {
    log_info "Verifying autoscaler setup..."
    
    # Check cluster autoscaler
    if oc get clusterautoscaler default &>/dev/null; then
        log_success "✅ Cluster autoscaler is configured"
        oc get clusterautoscaler default -o jsonpath='{.metadata.annotations.cluster-name}' 2>/dev/null || echo ""
    else
        log_warning "⚠️ Cluster autoscaler not found"
    fi
    
    # Check machine autoscalers
    local ma_count=$(oc get machineautoscaler -n openshift-machine-api --no-headers 2>/dev/null | wc -l)
    if [ "$ma_count" -gt 0 ]; then
        log_success "✅ $ma_count machine autoscaler(s) configured"
        oc get machineautoscaler -n openshift-machine-api
    else
        log_warning "⚠️ No machine autoscalers found"
    fi
    
    # Show current machinesets and their replica counts
    log_info "Current machinesets:"
    oc get machinesets -n openshift-machine-api
}

# Show usage information
show_usage() {
    echo ""
    log_info "🎯 Cluster Autoscaler Setup Complete!"
    echo ""
    echo "📊 What was configured:"
    echo "  ✅ Cluster Autoscaler: Manages overall scaling policies"
    echo "  ✅ Machine Autoscalers: Manages individual machineset scaling"
    echo "  ✅ Resource Limits: Max 20 nodes, 160 cores, 655GB RAM"
    echo ""
    echo "🚀 How it works:"
    echo "  1. KEDA scales pods based on Kafka lag"
    echo "  2. When pods can't schedule (no resources), they stay Pending"
    echo "  3. Cluster Autoscaler detects Pending pods"
    echo "  4. Machine Autoscaler adds new nodes to machinesets"
    echo "  5. New nodes become available and pods schedule"
    echo ""
    echo "🧪 Test scaling:"
    echo "  # Generate high load to trigger node scaling"
    echo "  ./scripts/test-vep-scaling-simple.sh"
    echo "  ./scripts/test-all-scaling-modes.sh"
    echo ""
    echo "🔍 Monitor scaling:"
    echo "  watch oc get nodes"
    echo "  watch oc get machinesets -n openshift-machine-api"
    echo "  oc logs -f deployment/cluster-autoscaler -n openshift-cluster-autoscaler"
    echo ""
}

# Main function
main() {
    echo ""
    log_info "🔧 Healthcare ML - Dynamic Cluster Autoscaler Setup"
    log_info "Detecting and configuring autoscaling for your specific cluster"
    echo ""
    
    check_prerequisites
    detect_machinesets
    
    local cluster_config=$(generate_cluster_autoscaler_config)
    local machine_config=$(generate_machine_autoscaler_configs)
    
    apply_configurations "$cluster_config" "$machine_config"
    verify_setup
    show_usage
    
    log_success "Dynamic cluster autoscaler setup completed!"
    echo ""
}

# Run main function
main "$@"
