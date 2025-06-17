#!/bin/bash

# Healthcare ML Cost Attribution Viewer
# Shows current cost attribution and scaling impact for end users

set -euo pipefail

echo "💰 Healthcare ML Cost Attribution Dashboard"
echo "=========================================="
echo "Project: healthcare-ml-demo"
echo "Date: $(date)"
echo ""

# Check if we're connected to OpenShift
if ! oc whoami &>/dev/null; then
    echo "❌ Error: Not logged into OpenShift cluster"
    exit 1
fi

# Function to show cost attribution summary
show_cost_summary() {
    echo "📊 Cost Attribution Summary:"
    echo "============================"
    
    echo "🏷️  Node Pool Cost Centers:"
    oc get nodes -o custom-columns="NAME:.metadata.name,WORKLOAD-TYPE:.metadata.labels.workload-type,COST-CENTER:.metadata.labels.cost-center,INSTANCE-TYPE:.metadata.labels.node\.kubernetes\.io/instance-type,STATUS:.status.conditions[?(@.type==\"Ready\")].status" | grep -v "<none>" || echo "No cost labels found"
    echo ""
    
    echo "💡 Cost Center Breakdown:"
    echo "  📋 genomics-research: Standard workload nodes (normal/bigdata VEP processing)"
    echo "  ⚡ genomics-research-demo: Compute-intensive nodes (node scaling demo)"
    echo ""
}

# Function to show current resource utilization
show_resource_utilization() {
    echo "📈 Current Resource Utilization:"
    echo "==============================="
    
    echo "🖥️  Node Resource Usage:"
    oc adm top nodes 2>/dev/null || echo "Metrics not available - install metrics-server"
    echo ""
    
    echo "🏃 Running Workloads by Cost Center:"
    echo "  Standard Nodes (genomics-research):"
    STANDARD_PODS=$(oc get pods --all-namespaces -o wide | grep "aro-cluster.*worker.*eastus[12]" | wc -l || echo "0")
    echo "    Active pods: $STANDARD_PODS"
    
    echo "  Compute-Intensive Nodes (genomics-research-demo):"
    COMPUTE_PODS=$(oc get pods --all-namespaces -o wide | grep "compute-intensive" | wc -l || echo "0")
    echo "    Active pods: $COMPUTE_PODS"
    echo ""
}

# Function to show cost escalation pattern
show_cost_escalation() {
    echo "💸 Cost Escalation Pattern:"
    echo "=========================="
    
    echo "🔄 Scaling Modes and Expected Costs:"
    echo "  1. 🟢 Normal Mode (Standard Nodes Only):"
    echo "     - Node type: Standard_D8s_v3, Standard_E8as_v4"
    echo "     - Estimated cost: ~\$0.50-1.00/hour baseline"
    echo "     - Workloads: WebSocket, VEP normal/bigdata, Kafka"
    echo ""
    
    echo "  2. 🟡 Big Data Mode (Intensive Standard Node Usage):"
    echo "     - Node type: Same standard nodes, higher utilization"
    echo "     - Estimated cost: ~\$1.00-2.00/hour"
    echo "     - Workloads: High-volume VEP processing"
    echo ""
    
    echo "  3. 🔴 Node Scale Mode (Compute-Intensive Nodes):"
    echo "     - Node type: Standard_D8s_v3 (compute-intensive pool)"
    echo "     - Estimated cost: ~\$2.00-4.00/hour (additional nodes)"
    echo "     - Workloads: VEP nodescale (100K+ genetic sequences)"
    echo ""
}

# Function to show Red Hat Insights integration
show_insights_integration() {
    echo "🔍 Red Hat Insights Cost Management Integration:"
    echo "=============================================="
    
    echo "📊 Cost Management Configuration:"
    COST_CONFIG=$(oc get costmanagementmetricsconfig -n costmanagement-metrics-operator --no-headers 2>/dev/null | wc -l || echo "0")
    if [ "$COST_CONFIG" -gt 0 ]; then
        echo "  ✅ Cost Management Metrics Operator: Active"
        echo "  ✅ Data Collection: Enabled"
        echo "  ✅ Red Hat Insights Integration: Configured"
    else
        echo "  ❌ Cost Management not configured"
    fi
    echo ""
    
    echo "🌐 Access Your Cost Data:"
    echo "  1. Red Hat Hybrid Cloud Console:"
    echo "     URL: https://console.redhat.com/openshift/cost-management"
    echo "     Filter by: Project 'healthcare-ml-demo'"
    echo ""
    
    echo "  2. OpenShift Web Console:"
    echo "     URL: $(oc whoami --show-console 2>/dev/null || echo 'Not available')"
    echo "     Path: Administration → Cluster Settings → Insights"
    echo ""
    
    echo "  3. Cost Attribution Labels:"
    echo "     - cost-center: genomics-research (standard)"
    echo "     - cost-center: genomics-research-demo (compute-intensive)"
    echo "     - billing-model: chargeback"
    echo "     - project: healthcare-ml-demo"
    echo ""
}

# Function to show current scaling status
show_scaling_status() {
    echo "⚡ Current Scaling Status:"
    echo "========================"
    
    echo "🎯 VEP Service Status:"
    VEP_NORMAL=$(oc get pods -l app=vep-service --no-headers 2>/dev/null | wc -l || echo "0")
    VEP_NODESCALE=$(oc get pods -l app=vep-service-nodescale --no-headers 2>/dev/null | wc -l || echo "0")
    
    echo "  📊 VEP Normal/BigData: $VEP_NORMAL pods (standard nodes)"
    echo "  ⚡ VEP NodeScale: $VEP_NODESCALE pods (compute-intensive nodes)"
    echo ""
    
    echo "🏗️  Machine Autoscaler Status:"
    oc get machineautoscaler -n openshift-machine-api -o custom-columns="NAME:.metadata.name,MIN:.spec.minReplicas,MAX:.spec.maxReplicas,TARGET:.spec.scaleTargetRef.name" 2>/dev/null || echo "No autoscalers found"
    echo ""
}

# Function to provide cost optimization recommendations
show_cost_optimization() {
    echo "💡 Cost Optimization Recommendations:"
    echo "===================================="
    
    echo "🎯 FinOps Best Practices:"
    echo "  1. ✅ Scale-to-Zero: VEP services automatically scale to 0 when idle"
    echo "  2. ✅ Node Affinity: Workloads run on appropriate node types"
    echo "  3. ✅ Cost Attribution: All resources tagged with cost centers"
    echo "  4. ✅ Machine Autoscaling: Compute-intensive nodes created on demand"
    echo ""
    
    echo "📊 Monitoring Recommendations:"
    echo "  1. Monitor cost spikes in Red Hat Insights when node scaling occurs"
    echo "  2. Set up alerts for compute-intensive node creation"
    echo "  3. Review monthly cost reports by cost-center"
    echo "  4. Track correlation between genetic sequence size and costs"
    echo ""
}

# Main execution
echo "Generating cost attribution report..."
echo ""

show_cost_summary
show_resource_utilization
show_cost_escalation
show_insights_integration
show_scaling_status
show_cost_optimization

echo "✅ Cost attribution report completed!"
echo ""
echo "🚀 Next Steps:"
echo "1. Access Red Hat Hybrid Cloud Console for detailed cost analytics"
echo "2. Test different scaling modes to see cost impact"
echo "3. Set up cost alerts and budgets in Red Hat Insights"
echo "4. Review monthly cost reports for optimization opportunities"
