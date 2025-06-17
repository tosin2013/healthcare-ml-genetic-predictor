#!/bin/bash

# Red Hat Cost Management Service Integration Setup
# Based on: https://docs.redhat.com/en/documentation/cost_management_service/1-latest/html/integrating_openshift_container_platform_data_into_cost_management/

set -euo pipefail

echo "🔧 Red Hat Cost Management Service Integration Setup"
echo "===================================================="
echo "This script will configure your OpenShift cluster for Red Hat Cost Management"
echo "Following official Red Hat documentation for cost visibility in the dashboard"
echo ""

# Check if we're connected to OpenShift
if ! oc whoami &>/dev/null; then
    echo "❌ Error: Not logged into OpenShift cluster"
    exit 1
fi

# Check if user is cluster admin
if ! oc auth can-i '*' '*' --all-namespaces &>/dev/null; then
    echo "❌ Error: You need cluster-admin privileges to install the cost management operator"
    exit 1
fi

echo "✅ Prerequisites check passed"
echo ""

# Step 1: Install the Cost Management Metrics Operator
install_cost_operator() {
    echo "📦 Step 1: Installing Cost Management Metrics Operator"
    echo "====================================================="
    
    echo "Creating operator namespace..."
    oc create namespace costmanagement-metrics-operator --dry-run=client -o yaml | oc apply -f -
    
    echo "Creating OperatorGroup..."
    cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: costmanagement-metrics-operator
  namespace: costmanagement-metrics-operator
spec:
  targetNamespaces:
  - costmanagement-metrics-operator
EOF

    echo "Creating Subscription for Cost Management Operator..."
    cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: costmanagement-metrics-operator
  namespace: costmanagement-metrics-operator
spec:
  channel: stable
  installPlanApproval: Automatic
  name: costmanagement-metrics-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

    echo "⏳ Waiting for operator to be ready..."
    sleep 30
    
    # Wait for the operator to be installed
    echo "Checking operator installation status..."
    for i in {1..12}; do
        if oc get csv -n costmanagement-metrics-operator | grep -q "Succeeded"; then
            echo "✅ Cost Management Metrics Operator installed successfully"
            break
        fi
        echo "⏳ Waiting for operator installation... ($i/12)"
        sleep 10
    done
    
    echo ""
}

# Step 2: Create authentication secret
create_auth_secret() {
    echo "🔐 Step 2: Setting up Red Hat authentication"
    echo "============================================"
    
    echo "⚠️  IMPORTANT: You need to obtain authentication credentials from Red Hat"
    echo ""
    echo "📋 To get your credentials:"
    echo "1. Go to: https://console.redhat.com/openshift/cost-management"
    echo "2. Navigate to: Settings → Sources → Add source"
    echo "3. Select: OpenShift Container Platform"
    echo "4. Copy the cluster identifier and authentication token"
    echo ""
    
    read -p "Do you have your Red Hat authentication token? (y/n): " -n 1 -r
    echo
    if [[ ! \$REPLY =~ ^[Yy]\$ ]]; then
        echo "❌ Please obtain your authentication credentials first"
        echo "📖 Documentation: https://docs.redhat.com/en/documentation/cost_management_service/1-latest/html/integrating_openshift_container_platform_data_into_cost_management/"
        exit 1
    fi
    
    echo ""
    echo "🔑 Enter your Red Hat authentication credentials:"
    read -p "Red Hat username/email: " RH_USERNAME
    read -s -p "Red Hat password or token: " RH_PASSWORD
    echo ""
    read -p "Red Hat organization ID (optional): " RH_ORG_ID
    
    echo "Creating authentication secret..."
    oc create secret generic redhat-credentials \
        --from-literal=username="\$RH_USERNAME" \
        --from-literal=password="\$RH_PASSWORD" \
        --from-literal=org_id="\$RH_ORG_ID" \
        -n costmanagement-metrics-operator \
        --dry-run=client -o yaml | oc apply -f -
    
    echo "✅ Authentication secret created"
    echo ""
}

# Step 3: Create CostManagementMetricsConfig
create_cost_config() {
    echo "⚙️  Step 3: Creating Cost Management Configuration"
    echo "================================================"
    
    # Get cluster ID
    CLUSTER_ID=\$(oc get clusterversion version -o jsonpath='{.spec.clusterID}')
    echo "📋 Cluster ID: \$CLUSTER_ID"
    
    echo "Creating CostManagementMetricsConfig..."
    cat <<EOF | oc apply -f -
apiVersion: costmanagement-metrics-cfg.openshift.io/v1beta1
kind: CostManagementMetricsConfig
metadata:
  name: healthcare-ml-cost-config
  namespace: costmanagement-metrics-operator
  labels:
    app.kubernetes.io/name: cost-management-operator
    app.kubernetes.io/part-of: healthcare-ml-demo
  annotations:
    cost-center: genomics-research
    project: healthcare-ml-demo
    description: "Cost management configuration for healthcare ML demo scaling and cost attribution"
spec:
  # Red Hat Cost Management API configuration
  api_url: https://console.redhat.com
  
  # Authentication configuration
  authentication:
    type: token
    token_url: https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token
  
  # Source configuration
  source:
    name: healthcare-ml-demo-cluster
    create_source: true
    check_cycle: 1440  # Check every 24 hours
    sources_path: /api/sources/v1.0/
  
  # Prometheus configuration
  prometheus_config:
    service_address: https://thanos-querier.openshift-monitoring.svc:9091
    skip_tls_verification: false
    collect_previous_data: true
    context_timeout: 120
    disable_metrics_collection_cost_management: false
    disable_metrics_collection_resource_optimization: false
  
  # Upload configuration
  upload:
    upload_cycle: 60  # Upload every hour
    upload_toggle: true
    upload_wait: 10
    validate_cert: true
    ingress_path: /api/ingress/v1/upload
  
  # Packaging configuration
  packaging:
    max_size_MB: 100
    max_reports_to_store: 30
  
  # Volume claim template for cost data storage
  volume_claim_template:
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: healthcare-ml-cost-data
      labels:
        app.kubernetes.io/name: cost-management-operator
        app.kubernetes.io/part-of: healthcare-ml-demo
    spec:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 10Gi
EOF

    echo "✅ Cost Management configuration created"
    echo ""
}

# Step 4: Configure namespace labels for cost optimization
configure_namespace_labels() {
    echo "🏷️  Step 4: Configuring namespace labels for cost tracking"
    echo "========================================================="
    
    echo "Adding cost management labels to healthcare-ml-demo namespace..."
    oc label namespace healthcare-ml-demo \
        insights_cost_management_optimizations="true" \
        cost-center="genomics-research" \
        billing-model="chargeback" \
        project="healthcare-ml-demo" \
        --overwrite
    
    echo "✅ Namespace labels configured"
    echo ""
}

# Step 5: Verify installation and configuration
verify_installation() {
    echo "🔍 Step 5: Verifying Cost Management Integration"
    echo "==============================================="
    
    echo "Checking operator status..."
    oc get csv -n costmanagement-metrics-operator
    echo ""
    
    echo "Checking CostManagementMetricsConfig status..."
    oc get costmanagementmetricsconfig -n costmanagement-metrics-operator
    echo ""
    
    echo "Checking cost management pods..."
    oc get pods -n costmanagement-metrics-operator
    echo ""
    
    echo "Checking configuration details..."
    oc describe costmanagementmetricsconfig healthcare-ml-cost-config -n costmanagement-metrics-operator | head -50
    echo ""
}

# Step 6: Provide next steps and dashboard access
provide_next_steps() {
    echo "🚀 Step 6: Next Steps and Dashboard Access"
    echo "=========================================="
    
    echo "✅ Red Hat Cost Management integration setup complete!"
    echo ""
    
    echo "📊 Accessing your cost data:"
    echo "1. 🌐 Red Hat Hybrid Cloud Console:"
    echo "   URL: https://console.redhat.com/openshift/cost-management"
    echo "   - Filter by cluster: healthcare-ml-demo-cluster"
    echo "   - View by project: healthcare-ml-demo"
    echo "   - Cost center breakdown: genomics-research vs genomics-research-demo"
    echo ""
    
    echo "2. ⏱️  Data availability:"
    echo "   - Initial data collection: 1-2 hours"
    echo "   - Full cost reports: 24-48 hours"
    echo "   - Real-time metrics: Available immediately"
    echo ""
    
    echo "3. 🎯 What you'll see in the dashboard:"
    echo "   - Node-level cost attribution by cost-center"
    echo "   - Project-level cost breakdown"
    echo "   - Resource utilization trends"
    echo "   - Cost spikes when compute-intensive nodes scale"
    echo ""
    
    echo "4. 📈 Testing cost visibility:"
    echo "   - Run: ./scripts/test-websocket-client.js node-scale"
    echo "   - Monitor cost escalation in Red Hat console"
    echo "   - Check cost attribution by node type"
    echo ""
    
    echo "5. 🔧 Troubleshooting:"
    echo "   - Check operator logs: oc logs -n costmanagement-metrics-operator -l app=cost-mgmt-operator"
    echo "   - Verify authentication: oc get secret redhat-credentials -n costmanagement-metrics-operator"
    echo "   - Check data collection: oc describe costmanagementmetricsconfig healthcare-ml-cost-config -n costmanagement-metrics-operator"
    echo ""
}

# Main execution
echo "Starting Red Hat Cost Management Service integration..."
echo ""

install_cost_operator
create_auth_secret
create_cost_config
configure_namespace_labels
verify_installation
provide_next_steps

echo "🎉 Red Hat Cost Management Service integration completed!"
echo "📊 Your healthcare ML cost data will be available in the Red Hat dashboard within 1-2 hours"
