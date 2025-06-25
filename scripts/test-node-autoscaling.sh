#!/bin/bash

# Test Node Autoscaling - Healthcare ML Genetic Predictor
# This script demonstrates how the cluster autoscaler works by creating high-resource workloads

set -e

echo "=== Node Autoscaling Test ==="
echo "This test will create resource-intensive pods to trigger node autoscaling"
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Check current node count
print_header "Current Cluster State"
echo "Current nodes:"
oc get nodes | grep worker
echo
echo "Current resource usage:"
oc adm top nodes
echo

# Show autoscaler configuration
print_header "Autoscaler Configuration"
echo "Cluster Autoscaler:"
oc get clusterautoscaler -o yaml | grep -A 10 -B 5 "maxNodesTotal\|maxReplicas"
echo
echo "Machine Autoscalers:"
oc get machineautoscaler -n openshift-machine-api -o custom-columns=NAME:.metadata.name,MIN:.spec.minReplicas,MAX:.spec.maxReplicas,MACHINESET:.spec.scaleTargetRef.name

# Create namespace for testing
TEST_NAMESPACE="autoscaler-test"
print_header "Setting up Test Environment"
oc new-project $TEST_NAMESPACE 2>/dev/null || oc project $TEST_NAMESPACE
echo "Using namespace: $TEST_NAMESPACE"

# Create a high-resource deployment that should trigger scaling
cat << 'EOF' > /tmp/high-resource-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resource-intensive-workload
  namespace: autoscaler-test
  labels:
    app: resource-test
    component: scaling-demo
spec:
  replicas: 6  # Start with 6 replicas to force scaling
  selector:
    matchLabels:
      app: resource-test
  template:
    metadata:
      labels:
        app: resource-test
        component: scaling-demo
    spec:
      containers:
      - name: cpu-intensive
        image: busybox:1.35
        # Request significant resources to trigger node scaling
        resources:
          requests:
            cpu: "2000m"      # 2 CPU cores per pod
            memory: "4Gi"     # 4GB RAM per pod
          limits:
            cpu: "2000m"
            memory: "4Gi"
        command:
        - /bin/sh
        - -c
        - |
          echo "Starting CPU-intensive workload simulation..."
          echo "Pod: $HOSTNAME"
          echo "Requested resources: 2 CPU cores, 4GB RAM"
          # Simulate CPU-intensive work
          while true; do
            for i in $(seq 1 4); do
              dd if=/dev/zero of=/dev/null bs=1M count=100 2>/dev/null &
            done
            sleep 10
            # Kill background processes to prevent resource exhaustion
            killall dd 2>/dev/null || true
            sleep 5
          done
      # Add node affinity to prefer worker nodes
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            preference:
              matchExpressions:
              - key: node-role.kubernetes.io/worker
                operator: Exists
      # Add anti-affinity to spread pods across nodes
      podAntiAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - resource-test
            topologyKey: kubernetes.io/hostname
EOF

print_header "Deploying High-Resource Workload"
print_status "Creating deployment with 6 replicas, each requesting 2 CPU cores and 4GB RAM..."
print_status "Total resource demand: 12 CPU cores, 24GB RAM"
print_status "Current cluster capacity: ~24 CPU cores, ~96GB RAM across 3 nodes"
echo

oc apply -f /tmp/high-resource-deployment.yaml
echo "Deployment created. This should trigger node autoscaling if resources are insufficient."
echo

# Function to check scaling progress
check_scaling_progress() {
    print_header "Monitoring Scaling Progress"
    
    for i in {1..20}; do
        echo "--- Check $i ($(date)) ---"
        
        echo "Nodes:"
        oc get nodes | grep worker | awk '{print $1 " - " $2}'
        
        echo "Machine Sets:"
        oc get machinesets -n openshift-machine-api -o custom-columns=NAME:.metadata.name,DESIRED:.spec.replicas,CURRENT:.status.replicas,READY:.status.readyReplicas
        
        echo "Pods:"
        oc get pods -n $TEST_NAMESPACE -o wide | grep resource-test | head -8
        
        echo "Pending pods:"
        PENDING_PODS=$(oc get pods -n $TEST_NAMESPACE | grep Pending | wc -l)
        echo "Pending: $PENDING_PODS"
        
        if [ $PENDING_PODS -eq 0 ]; then
            print_status "All pods are scheduled! Checking if new nodes were added..."
            CURRENT_NODES=$(oc get nodes | grep worker | wc -l)
            if [ $CURRENT_NODES -gt 3 ]; then
                print_status "SUCCESS: Node autoscaling worked! New nodes were added."
                break
            else
                print_status "All pods scheduled on existing nodes - no scaling needed with current resource requests."
                break
            fi
        fi
        
        if [ $i -eq 20 ]; then
            print_warning "Reached maximum wait time. Scaling may still be in progress."
        fi
        
        sleep 30
    done
}

# Start monitoring
check_scaling_progress

print_header "Final Cluster State"
echo "Final nodes:"
oc get nodes | grep worker
echo
echo "Final resource usage:"
oc adm top nodes
echo
echo "Deployment status:"
oc get deployment -n $TEST_NAMESPACE
echo
echo "Pod distribution:"
oc get pods -n $TEST_NAMESPACE -o wide | grep resource-test

print_header "Cleanup Instructions"
echo "To clean up the test deployment:"
echo "  oc delete project $TEST_NAMESPACE"
echo
echo "To check autoscaler logs:"
echo "  oc logs -n openshift-machine-api deployment/cluster-autoscaler-default -f"
echo
echo "Note: Node scale-down will happen automatically after pods are removed,"
echo "      but may take 10+ minutes based on the configured delayAfterDelete and unneededTime."

print_header "Understanding the Results"
echo "The cluster autoscaler works as follows:"
echo "1. When pods cannot be scheduled due to insufficient resources,"
echo "2. The autoscaler identifies which MachineSet can provide the needed resources,"
echo "3. It scales up the appropriate MachineSet (within min/max limits),"
echo "4. New nodes join the cluster and pods get scheduled."
echo
echo "If no new nodes were added, it means:"
echo "- The existing nodes had sufficient capacity for the requested resources, or"
echo "- The resource requests were not high enough to trigger scaling, or"
echo "- The autoscaler determined scaling wasn't needed based on utilization thresholds."

rm -f /tmp/high-resource-deployment.yaml
