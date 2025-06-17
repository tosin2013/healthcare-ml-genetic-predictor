#!/bin/bash

# Healthcare ML Node Labeling Script - Standard Workload Pool
# Labels existing worker nodes for vep-service (normal/bigdata modes)

set -euo pipefail

echo "🏷️  Healthcare ML Standard Node Pool Labeling"
echo "============================================="
echo "Purpose: Label existing nodes for vep-service (normal/bigdata modes)"
echo "Target workloads: vep-service-normal, vep-service-bigdata, WebSocket, Kafka"
echo ""

# Check if we're connected to OpenShift
if ! oc whoami &>/dev/null; then
    echo "❌ Error: Not logged into OpenShift cluster"
    exit 1
fi

# Get current project
CURRENT_PROJECT=$(oc project -q)
echo "📍 Current project: $CURRENT_PROJECT"

# Define node labeling function for standard workload pool
label_standard_node() {
    local node_name=$1
    local zone=$2

    echo "🏷️  Labeling STANDARD node: $node_name (zone: $zone)"
    echo "   Target workloads: vep-service (normal/bigdata), WebSocket, Kafka"

    # Apply healthcare ML standard workload labels
    oc label node "$node_name" \
        workload-type=standard \
        cost-center=genomics-research \
        billing-model=chargeback \
        resource-profile=balanced \
        availability-zone="$zone" \
        workload.healthcare-ml/type=genetic-analysis \
        workload.healthcare-ml/mode=normal-bigdata \
        workload.healthcare-ml/priority=standard \
        --overwrite

    # Apply Red Hat Insights cost management annotations
    oc annotate node "$node_name" \
        insights.openshift.io/cost-center="genomics-research" \
        insights.openshift.io/billing-model="chargeback" \
        insights.openshift.io/environment="production" \
        insights.openshift.io/project="healthcare-ml-demo" \
        insights.openshift.io/workload-pool="standard" \
        --overwrite

    echo "✅ Successfully labeled STANDARD node: $node_name"
}

# Label existing worker nodes as STANDARD workload pool
echo ""
echo "🔍 Identifying existing worker nodes for STANDARD pool..."

# Get worker nodes and their zones
WORKER_NODES=$(oc get nodes --no-headers | grep worker | awk '{print $1}')

if [ -z "$WORKER_NODES" ]; then
    echo "❌ No worker nodes found"
    exit 1
fi

echo "📋 Found worker nodes (will be labeled as STANDARD pool):"
echo "$WORKER_NODES"
echo ""

# Label each worker node as standard workload pool
for node in $WORKER_NODES; do
    # Extract zone from node name
    if [[ $node == *"eastus1"* ]]; then
        zone="eastus1"
    elif [[ $node == *"eastus2"* ]]; then
        zone="eastus2"
    elif [[ $node == *"eastus3"* ]]; then
        zone="eastus3"
    else
        zone="unknown"
    fi

    label_standard_node "$node" "$zone"
    echo ""
done

echo "🎯 Standard node pool labeling completed!"
echo ""

# Verify labeling
echo "🔍 Verification: Checking applied STANDARD labels..."
echo "===================================================="

for node in $WORKER_NODES; do
    echo "Node: $node (STANDARD pool)"
    oc get node "$node" --show-labels | grep -E "(workload-type=standard|cost-center|billing-model)" || echo "  ⚠️  Standard labels not found"
    echo ""
done

echo "✅ Healthcare ML STANDARD node pool labeling completed!"
echo ""
echo "📊 Summary:"
echo "- Labeled $(echo "$WORKER_NODES" | wc -l) worker nodes as STANDARD pool"
echo "- Applied workload-type=standard (for vep-service normal/bigdata modes)"
echo "- Applied cost-center=genomics-research labels"
echo "- Applied Red Hat Insights cost management annotations"
echo ""
echo "🚀 Next steps:"
echo "1. Deploy compute-intensive node pool: oc apply -k k8s/overlays/environments/demo/"
echo "2. This will create COMPUTE-INTENSIVE nodes for vep-service-nodescale"
echo "3. Validate node affinity: scripts/validate-node-affinity.sh"
echo "4. Test workload scheduling: scripts/test-node-scaling.sh"
echo ""
echo "🎯 Architecture Summary:"
echo "- STANDARD nodes: vep-service (normal/bigdata), WebSocket, Kafka"
echo "- COMPUTE-INTENSIVE nodes: vep-service-nodescale (node scaling demo)"
