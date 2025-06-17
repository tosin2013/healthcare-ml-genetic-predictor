#!/bin/bash

# Healthcare ML Node Affinity Validation Script
# Validates that workloads are properly scheduled to designated node pools

set -euo pipefail

echo "🔍 Healthcare ML Node Affinity Validation"
echo "=========================================="
echo "Validating workload distribution across node pools"
echo ""

# Check if we're connected to OpenShift
if ! oc whoami &>/dev/null; then
    echo "❌ Error: Not logged into OpenShift cluster"
    exit 1
fi

# Get current project
CURRENT_PROJECT=$(oc project -q)
echo "📍 Current project: $CURRENT_PROJECT"
echo ""

# Function to check node labels
check_node_labels() {
    echo "🏷️  Node Pool Configuration:"
    echo "============================"
    
    echo "📊 STANDARD Nodes (for vep-service normal/bigdata, WebSocket, Kafka):"
    oc get nodes -l workload-type=standard --show-labels | grep -E "(NAME|workload-type=standard)" || echo "  ⚠️  No standard nodes found"
    echo ""
    
    echo "⚡ COMPUTE-INTENSIVE Nodes (for vep-service-nodescale):"
    oc get nodes -l workload-type=compute-intensive --show-labels | grep -E "(NAME|workload-type=compute-intensive)" || echo "  ⚠️  No compute-intensive nodes found"
    echo ""
}

# Function to check pod scheduling
check_pod_scheduling() {
    echo "🎯 Pod Scheduling Validation:"
    echo "============================="
    
    # Check VEP service pods (should be on standard nodes)
    echo "📋 VEP Service Pods (should be on STANDARD nodes):"
    VEP_PODS=$(oc get pods -l app=vep-service --no-headers 2>/dev/null | awk '{print $1}' || echo "")
    if [ -n "$VEP_PODS" ]; then
        for pod in $VEP_PODS; do
            NODE=$(oc get pod "$pod" -o jsonpath='{.spec.nodeName}' 2>/dev/null || echo "unknown")
            NODE_TYPE=$(oc get node "$NODE" -o jsonpath='{.metadata.labels.workload-type}' 2>/dev/null || echo "unknown")
            echo "  Pod: $pod → Node: $NODE (Type: $NODE_TYPE)"
            if [ "$NODE_TYPE" = "standard" ]; then
                echo "    ✅ Correctly scheduled on STANDARD node"
            else
                echo "    ❌ Incorrectly scheduled on $NODE_TYPE node"
            fi
        done
    else
        echo "  ℹ️  No VEP service pods currently running"
    fi
    echo ""
    
    # Check VEP nodescale pods (should be on compute-intensive nodes)
    echo "⚡ VEP NodeScale Pods (should be on COMPUTE-INTENSIVE nodes):"
    VEP_NODESCALE_PODS=$(oc get pods -l app=vep-service-nodescale --no-headers 2>/dev/null | awk '{print $1}' || echo "")
    if [ -n "$VEP_NODESCALE_PODS" ]; then
        for pod in $VEP_NODESCALE_PODS; do
            NODE=$(oc get pod "$pod" -o jsonpath='{.spec.nodeName}' 2>/dev/null || echo "unknown")
            NODE_TYPE=$(oc get node "$NODE" -o jsonpath='{.metadata.labels.workload-type}' 2>/dev/null || echo "unknown")
            echo "  Pod: $pod → Node: $NODE (Type: $NODE_TYPE)"
            if [ "$NODE_TYPE" = "compute-intensive" ]; then
                echo "    ✅ Correctly scheduled on COMPUTE-INTENSIVE node"
            else
                echo "    ❌ Incorrectly scheduled on $NODE_TYPE node"
            fi
        done
    else
        echo "  ℹ️  No VEP nodescale pods currently running"
    fi
    echo ""
    
    # Check WebSocket service pods (should be on standard nodes)
    echo "🌐 WebSocket Service Pods (should be on STANDARD nodes):"
    WS_PODS=$(oc get pods -l app.kubernetes.io/name=quarkus-websocket-service --no-headers 2>/dev/null | awk '{print $1}' || echo "")
    if [ -n "$WS_PODS" ]; then
        for pod in $WS_PODS; do
            NODE=$(oc get pod "$pod" -o jsonpath='{.spec.nodeName}' 2>/dev/null || echo "unknown")
            NODE_TYPE=$(oc get node "$NODE" -o jsonpath='{.metadata.labels.workload-type}' 2>/dev/null || echo "unknown")
            echo "  Pod: $pod → Node: $NODE (Type: $NODE_TYPE)"
            if [ "$NODE_TYPE" = "standard" ]; then
                echo "    ✅ Correctly scheduled on STANDARD node"
            else
                echo "    ❌ Incorrectly scheduled on $NODE_TYPE node"
            fi
        done
    else
        echo "  ℹ️  No WebSocket service pods currently running"
    fi
    echo ""
}

# Function to check machine sets
check_machine_sets() {
    echo "🏗️  Machine Set Configuration:"
    echo "=============================="
    
    echo "📊 All Machine Sets:"
    oc get machinesets -n openshift-machine-api -o custom-columns="NAME:.metadata.name,DESIRED:.spec.replicas,CURRENT:.status.replicas,READY:.status.readyReplicas,AVAILABLE:.status.availableReplicas"
    echo ""
    
    echo "⚡ Compute-Intensive Machine Set Details:"
    COMPUTE_MS=$(oc get machinesets -n openshift-machine-api -o name | grep compute-intensive || echo "")
    if [ -n "$COMPUTE_MS" ]; then
        oc describe "$COMPUTE_MS" -n openshift-machine-api | grep -A 10 -B 5 "Labels\|Annotations\|Replicas"
    else
        echo "  ⚠️  No compute-intensive machine set found"
    fi
    echo ""
}

# Function to check machine autoscaler
check_machine_autoscaler() {
    echo "📈 Machine Autoscaler Configuration:"
    echo "==================================="
    
    oc get machineautoscaler -n openshift-machine-api -o custom-columns="NAME:.metadata.name,REF:.spec.scaleTargetRef.name,MIN:.spec.minReplicas,MAX:.spec.maxReplicas"
    echo ""
}

# Function to provide recommendations
provide_recommendations() {
    echo "💡 Recommendations:"
    echo "=================="
    
    # Check if compute-intensive nodes exist
    COMPUTE_NODES=$(oc get nodes -l workload-type=compute-intensive --no-headers 2>/dev/null | wc -l || echo "0")
    if [ "$COMPUTE_NODES" -eq 0 ]; then
        echo "⚠️  No compute-intensive nodes found. To trigger node scaling:"
        echo "   1. Deploy a workload that requires compute-intensive nodes"
        echo "   2. Use: oc apply -f k8s/base/vep-service/vep-service-nodescale.yaml"
        echo "   3. Send messages to genetic-nodescale-raw topic"
        echo ""
    fi
    
    # Check if VEP nodescale deployment exists
    VEP_NODESCALE_DEPLOY=$(oc get deployment vep-service-nodescale --no-headers 2>/dev/null | wc -l || echo "0")
    if [ "$VEP_NODESCALE_DEPLOY" -eq 0 ]; then
        echo "ℹ️  VEP nodescale deployment not found. To test node scaling:"
        echo "   1. Deploy: oc apply -f k8s/base/vep-service/vep-service-nodescale.yaml"
        echo "   2. Test scaling: scripts/test-node-scaling.sh"
        echo ""
    fi
    
    echo "🚀 Next Steps:"
    echo "1. Test normal mode scaling: scripts/test-api-endpoints.sh"
    echo "2. Test node scaling: scripts/test-vep-scaling-simple.sh"
    echo "3. Monitor cost attribution: oc get nodes --show-labels | grep cost-center"
    echo "4. View scaling events: oc get events --field-selector reason=ScalingReplicaSet"
}

# Main execution
echo "Starting node affinity validation..."
echo ""

check_node_labels
check_pod_scheduling
check_machine_sets
check_machine_autoscaler
provide_recommendations

echo ""
echo "✅ Node affinity validation completed!"
echo ""
echo "🎯 Summary:"
echo "- STANDARD nodes: Run vep-service (normal/bigdata), WebSocket, Kafka"
echo "- COMPUTE-INTENSIVE nodes: Run vep-service-nodescale (node scaling demo)"
echo "- Cost attribution: Applied via insights.openshift.io labels"
echo "- Machine autoscaler: Configured for 0-3 compute-intensive nodes"
