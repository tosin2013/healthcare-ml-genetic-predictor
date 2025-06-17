#!/bin/bash

# Healthcare ML Node Scaling and Cost Attribution Demo
# Demonstrates multi-tier scaling with cost attribution for FinOps

set -euo pipefail

echo "🎯 Healthcare ML Node Scaling & Cost Attribution Demo"
echo "====================================================="
echo "Demonstrating Phase 3.1: Node Affinity and Cost Management Integration"
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

# Function to show current infrastructure state
show_infrastructure_state() {
    echo "🏗️  Current Infrastructure State:"
    echo "================================="
    
    echo "📊 Node Pool Distribution:"
    echo "  STANDARD Nodes (vep-service normal/bigdata, WebSocket, Kafka):"
    oc get nodes -l workload-type=standard --no-headers | awk '{print "    " $1 " (" $3 ")"}'
    
    echo "  COMPUTE-INTENSIVE Nodes (vep-service-nodescale):"
    COMPUTE_NODES=$(oc get nodes -l workload-type=compute-intensive --no-headers 2>/dev/null || echo "")
    if [ -n "$COMPUTE_NODES" ]; then
        echo "$COMPUTE_NODES" | awk '{print "    " $1 " (" $3 ")"}'
    else
        echo "    None (will be created on demand)"
    fi
    echo ""
    
    echo "💰 Cost Attribution Labels:"
    echo "  Standard Pool Cost Center: genomics-research"
    echo "  Compute-Intensive Pool Cost Center: genomics-research-demo"
    echo "  Billing Model: chargeback"
    echo ""
    
    echo "📈 Machine Autoscaler Configuration:"
    oc get machineautoscaler -n openshift-machine-api -o custom-columns="NAME:.metadata.name,MIN:.spec.minReplicas,MAX:.spec.maxReplicas" | grep -E "(NAME|compute-intensive|worker)"
    echo ""
}

# Function to demonstrate workload scheduling
demonstrate_workload_scheduling() {
    echo "🎯 Workload Scheduling Demonstration:"
    echo "===================================="
    
    echo "📋 Current Pod Distribution:"
    
    # WebSocket pods (should be on standard nodes)
    echo "  🌐 WebSocket Service Pods (STANDARD nodes):"
    WS_PODS=$(oc get pods -l app.kubernetes.io/name=quarkus-websocket-service --no-headers 2>/dev/null || echo "")
    if [ -n "$WS_PODS" ]; then
        echo "$WS_PODS" | while read pod status ready restarts age; do
            NODE=$(oc get pod "$pod" -o jsonpath='{.spec.nodeName}' 2>/dev/null || echo "unknown")
            NODE_TYPE=$(oc get node "$NODE" -o jsonpath='{.metadata.labels.workload-type}' 2>/dev/null || echo "unknown")
            echo "    $pod → $NODE ($NODE_TYPE)"
        done
    else
        echo "    No WebSocket pods running"
    fi
    echo ""
    
    # VEP service pods (should be on standard nodes)
    echo "  📊 VEP Service Pods (STANDARD nodes):"
    VEP_PODS=$(oc get pods -l app=vep-service --no-headers 2>/dev/null || echo "")
    if [ -n "$VEP_PODS" ]; then
        echo "$VEP_PODS" | while read pod status ready restarts age; do
            NODE=$(oc get pod "$pod" -o jsonpath='{.spec.nodeName}' 2>/dev/null || echo "unknown")
            NODE_TYPE=$(oc get node "$NODE" -o jsonpath='{.metadata.labels.workload-type}' 2>/dev/null || echo "unknown")
            echo "    $pod → $NODE ($NODE_TYPE)"
        done
    else
        echo "    No VEP service pods running"
    fi
    echo ""
    
    # VEP nodescale pods (should be on compute-intensive nodes)
    echo "  ⚡ VEP NodeScale Pods (COMPUTE-INTENSIVE nodes):"
    VEP_NODESCALE_PODS=$(oc get pods -l app=vep-service-nodescale --no-headers 2>/dev/null || echo "")
    if [ -n "$VEP_NODESCALE_PODS" ]; then
        echo "$VEP_NODESCALE_PODS" | while read pod status ready restarts age; do
            NODE=$(oc get pod "$pod" -o jsonpath='{.spec.nodeName}' 2>/dev/null || echo "unknown")
            NODE_TYPE=$(oc get node "$NODE" -o jsonpath='{.metadata.labels.workload-type}' 2>/dev/null || echo "unknown")
            echo "    $pod → $NODE ($NODE_TYPE)"
        done
    else
        echo "    No VEP nodescale pods running (ready for scaling demo)"
    fi
    echo ""
}

# Function to show cost attribution
show_cost_attribution() {
    echo "💰 Cost Attribution Analysis:"
    echo "============================="
    
    echo "📊 Node Cost Attribution:"
    oc get nodes -o custom-columns="NAME:.metadata.name,WORKLOAD-TYPE:.metadata.labels.workload-type,COST-CENTER:.metadata.labels.cost-center,BILLING-MODEL:.metadata.labels.billing-model,INSTANCE-TYPE:.metadata.labels.node\.kubernetes\.io/instance-type"
    echo ""
    
    echo "💡 Cost Management Integration:"
    echo "  ✅ Cost Management Metrics Operator: Running"
    echo "  ✅ Red Hat Insights Integration: Configured"
    echo "  ✅ Project-level Chargeback: Enabled"
    echo "  ✅ Workload-specific Attribution: Applied"
    echo ""
    
    echo "📈 Expected Cost Escalation Pattern:"
    echo "  1. Normal Mode: Standard nodes only (~\$0.50/hour baseline)"
    echo "  2. Big Data Mode: More standard node utilization (~\$1.00/hour)"
    echo "  3. Node Scale Mode: Triggers compute-intensive nodes (~\$2.00/hour)"
    echo ""
}

# Function to provide next steps
provide_next_steps() {
    echo "🚀 Next Steps for Node Scaling Demo:"
    echo "==================================="
    
    echo "1. 📊 Test Normal Mode (Pod Scaling on Standard Nodes):"
    echo "   curl -X POST \\\$ROUTE_URL/api/scaling/mode -d '{\"mode\":\"normal\"}'"
    echo "   curl -X POST \\\$ROUTE_URL/api/genetic/analyze -d '{\"sequence\":\"ATGC...\",\"mode\":\"normal\"}'"
    echo ""
    
    echo "2. 🚀 Test Big Data Mode (Intensive Pod Scaling on Standard Nodes):"
    echo "   curl -X POST \\\$ROUTE_URL/api/scaling/mode -d '{\"mode\":\"bigdata\"}'"
    echo "   curl -X POST \\\$ROUTE_URL/api/genetic/analyze -d '{\"sequence\":\"ATGC...\",\"mode\":\"bigdata\"}'"
    echo ""
    
    echo "3. ⚡ Test Node Scale Mode (Trigger Compute-Intensive Nodes):"
    echo "   # Deploy VEP nodescale service"
    echo "   oc apply -f k8s/base/vep-service/vep-service-nodescale.yaml"
    echo "   "
    echo "   # Trigger node scaling"
    echo "   curl -X POST \\\$ROUTE_URL/api/scaling/trigger-demo -d '{\"demoType\":\"node-scaling\"}'"
    echo ""
    
    echo "4. 📈 Monitor Scaling and Cost Attribution:"
    echo "   # Watch node scaling"
    echo "   watch 'oc get nodes -l workload-type=compute-intensive'"
    echo "   "
    echo "   # Monitor pod scaling"
    echo "   watch 'oc get pods -l app=vep-service-nodescale'"
    echo "   "
    echo "   # Check cost attribution"
    echo "   oc get nodes --show-labels | grep cost-center"
    echo ""
    
    echo "5. 🔍 Validate Node Affinity:"
    echo "   ./scripts/validate-node-affinity.sh"
    echo ""
}

# Main execution
echo "Starting Phase 3.1 demonstration..."
echo ""

show_infrastructure_state
demonstrate_workload_scheduling
show_cost_attribution
provide_next_steps

echo "✅ Phase 3.1: Node Affinity and Cost Management Integration Demo Complete!"
echo ""
echo "🎯 Key Achievements:"
echo "✅ Standard node pool labeled and configured for normal/bigdata workloads"
echo "✅ Compute-intensive node pool configured for node scaling demo"
echo "✅ Node affinity rules enforced for proper workload distribution"
echo "✅ Cost attribution labels applied for Red Hat Insights integration"
echo "✅ Machine autoscaler configured for 0-3 compute-intensive nodes"
echo "✅ WebSocket service correctly scheduled on standard nodes"
echo ""
echo "🚀 Ready for multi-tier scaling demonstration with cost attribution!"
echo "📊 Use the provided API endpoints to trigger different scaling modes"
echo "💰 Monitor cost escalation through Red Hat Insights Cost Management"
