#!/bin/bash

# Red Hat Cost Management Service Integration - Official Procedure
# Based on: https://docs.redhat.com/en/documentation/cost_management_service/1-latest/html/integrating_openshift_container_platform_data_into_cost_management/

set -euo pipefail

echo "🔧 Red Hat Cost Management Service Integration (Official Procedure)"
echo "=================================================================="
echo "Following the exact Red Hat documentation for service account authentication"
echo ""

# Check prerequisites
check_prerequisites() {
    echo "✅ Checking prerequisites..."
    
    if ! oc whoami &>/dev/null; then
        echo "❌ Error: Not logged into OpenShift cluster"
        exit 1
    fi
    
    if ! oc auth can-i '*' '*' --all-namespaces &>/dev/null; then
        echo "❌ Error: You need cluster-admin privileges"
        exit 1
    fi
    
    echo "✅ Prerequisites satisfied"
    echo ""
}

# Step 1: Verify package manifests
verify_package_manifests() {
    echo "📦 Step 1: Verifying Cost Management Operator package manifests"
    echo "=============================================================="
    
    echo "Checking available package manifests..."
    oc describe packagemanifests costmanagement-metrics-operator -n openshift-marketplace | head -20
    echo ""
}

# Step 2: Install the operator
install_operator() {
    echo "🚀 Step 2: Installing Cost Management Metrics Operator"
    echo "====================================================="
    
    echo "Creating costmanagement-metrics-operator namespace..."
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

    echo "Creating Subscription..."
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

    echo "⏳ Waiting for operator installation..."
    for i in {1..24}; do
        if oc get csv -n costmanagement-metrics-operator 2>/dev/null | grep -q "Succeeded"; then
            echo "✅ Cost Management Metrics Operator installed successfully"
            break
        fi
        echo "⏳ Waiting for operator installation... ($i/24)"
        sleep 15
    done
    echo ""
}

# Step 3: Configure service account authentication
configure_service_account_auth() {
    echo "🔐 Step 3: Configuring Service Account Authentication"
    echo "===================================================="
    
    echo "⚠️  IMPORTANT: You need Red Hat service account credentials"
    echo ""
    echo "📋 To get your service account credentials:"
    echo "1. Go to: https://console.redhat.com/iam/service-accounts"
    echo "2. Create a new service account or use existing one"
    echo "3. Ensure the service account has 'Cost Administrator' role"
    echo "4. Copy the client_id and client_secret"
    echo ""
    
    read -p "Do you have your Red Hat service account credentials? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Please obtain service account credentials first"
        echo "📖 Documentation: https://console.redhat.com/iam/service-accounts"
        exit 1
    fi
    
    echo ""
    echo "🔑 Enter your Red Hat service account credentials:"
    read -p "Service Account Client ID: " CLIENT_ID
    read -s -p "Service Account Client Secret: " CLIENT_SECRET
    echo ""
    
    # Encode credentials in base64
    echo "Encoding credentials..."
    CLIENT_ID_B64=$(echo -n "$CLIENT_ID" | base64 -w 0)
    CLIENT_SECRET_B64=$(echo -n "$CLIENT_SECRET" | base64 -w 0)
    
    echo "Creating service account authentication secret..."
    cat <<EOF | oc apply -f -
kind: Secret
apiVersion: v1
metadata:
  name: service-account-auth-secret
  namespace: costmanagement-metrics-operator
  labels:
    app.kubernetes.io/name: cost-management-operator
    app.kubernetes.io/part-of: healthcare-ml-demo
  annotations:
    description: "Red Hat service account authentication for cost management"
data:
  client_id: $CLIENT_ID_B64
  client_secret: $CLIENT_SECRET_B64
EOF

    echo "✅ Service account authentication secret created"
    echo ""
}

# Step 4: Create CostManagementMetricsConfig with service account auth
create_cost_config() {
    echo "⚙️  Step 4: Creating CostManagementMetricsConfig"
    echo "==============================================="
    
    echo "Creating cost management configuration with service account authentication..."
    cat <<EOF | oc apply -f -
kind: CostManagementMetricsConfig
apiVersion: costmanagement-metrics-cfg.openshift.io/v1beta1
metadata:
  name: healthcare-ml-cost-config
  namespace: costmanagement-metrics-operator
  labels:
    app.kubernetes.io/name: cost-management-operator
    app.kubernetes.io/part-of: healthcare-ml-demo
  annotations:
    cost-center: genomics-research
    project: healthcare-ml-demo
    description: "Cost management configuration for healthcare ML demo with service account auth"
spec:
  # Service account authentication (required for dashboard visibility)
  authentication:
    type: service-account
    secret_name: service-account-auth-secret
  
  # Packaging configuration
  packaging:
    max_reports_to_store: 30
    max_size_MB: 100
  
  # Prometheus configuration
  prometheus_config:
    collect_previous_data: true
    context_timeout: 120
    disable_metrics_collection_cost_management: false
    disable_metrics_collection_resource_optimization: false
    service_address: https://thanos-querier.openshift-monitoring.svc:9091
    skip_tls_verification: false
  
  # Source configuration (automatic source creation)
  source:
    check_cycle: 1440  # Check every 24 hours
    create_source: true  # Automatically create source in Red Hat console
    name: 'healthcare-ml-demo-cluster'  # Source name in Red Hat console
  
  # Upload configuration
  upload:
    upload_cycle: 60  # Upload every hour (faster than default 360)
    upload_toggle: true
    upload_wait: 10
    validate_cert: true
    ingress_path: /api/ingress/v1/upload
  
  # Volume claim for cost data storage
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

    echo "✅ CostManagementMetricsConfig created with service account authentication"
    echo ""
}

# Step 5: Configure namespace labels for cost optimization
configure_namespace_labels() {
    echo "🏷️  Step 5: Configuring namespace labels for cost optimization"
    echo "============================================================="
    
    echo "Adding Red Hat cost management labels to healthcare-ml-demo namespace..."
    oc label namespace healthcare-ml-demo \
        insights_cost_management_optimizations="true" \
        cost-center="genomics-research" \
        billing-model="chargeback" \
        project="healthcare-ml-demo" \
        environment="production" \
        --overwrite
    
    echo "✅ Namespace labels configured for cost optimization tracking"
    echo ""
}

# Step 6: Verify installation and provide status
verify_installation() {
    echo "🔍 Step 6: Verifying Installation and Configuration"
    echo "=================================================="
    
    echo "📊 Operator Status:"
    oc get csv -n costmanagement-metrics-operator
    echo ""
    
    echo "⚙️  Configuration Status:"
    oc get costmanagementmetricsconfig -n costmanagement-metrics-operator
    echo ""
    
    echo "🔐 Authentication Secret:"
    oc get secret service-account-auth-secret -n costmanagement-metrics-operator
    echo ""
    
    echo "📈 Cost Management Pods:"
    oc get pods -n costmanagement-metrics-operator
    echo ""
    
    echo "📋 Configuration Details:"
    oc describe costmanagementmetricsconfig healthcare-ml-cost-config -n costmanagement-metrics-operator | head -30
    echo ""
}

# Step 7: Provide dashboard access and next steps
provide_dashboard_access() {
    echo "🌐 Step 7: Red Hat Cost Management Dashboard Access"
    echo "=================================================="
    
    echo "✅ Setup complete! Your cluster will automatically appear in Red Hat Cost Management"
    echo ""
    
    echo "📊 Accessing your cost data:"
    echo "1. 🌐 Red Hat Hybrid Cloud Console:"
    echo "   URL: https://console.redhat.com/openshift/cost-management"
    echo "   - Your cluster 'healthcare-ml-demo-cluster' will appear automatically"
    echo "   - Filter by project: healthcare-ml-demo"
    echo "   - View cost breakdown by cost-center labels"
    echo ""
    
    echo "2. ⏱️  Data Timeline:"
    echo "   - Source creation: 5-10 minutes"
    echo "   - First data upload: 1 hour"
    echo "   - Cost data visibility: 2-4 hours"
    echo "   - Historical data: 24-48 hours"
    echo ""
    
    echo "3. 🎯 What you'll see:"
    echo "   - Node-level costs by workload-type (standard vs compute-intensive)"
    echo "   - Project-level cost breakdown (healthcare-ml-demo)"
    echo "   - Cost attribution by cost-center (genomics-research vs genomics-research-demo)"
    echo "   - Resource utilization trends and cost spikes"
    echo ""
    
    echo "4. 🧪 Testing Cost Visibility:"
    echo "   # Trigger node scaling to see cost impact"
    echo "   WEBSOCKET_URL=\"wss://quarkus-websocket-service-healthcare-ml-demo.apps.b9892ub1.eastus.aroapp.io/genetics\" node scripts/test-websocket-client.js node-scale \"\$(python3 -c \"import random; print(''.join(random.choices('ATCG', k=100000)))\")\""
    echo ""
    echo "   # Monitor cost escalation in Red Hat dashboard"
    echo "   # Standard nodes: ~\$1-2/hour baseline"
    echo "   # + Compute-intensive nodes: ~\$2-4/hour additional"
    echo ""
    
    echo "5. 🔧 Monitoring and Troubleshooting:"
    echo "   # Check operator logs"
    echo "   oc logs -n costmanagement-metrics-operator -l app=cost-mgmt-operator"
    echo ""
    echo "   # Check configuration status"
    echo "   oc describe costmanagementmetricsconfig healthcare-ml-cost-config -n costmanagement-metrics-operator"
    echo ""
    echo "   # Verify data upload"
    echo "   oc get events -n costmanagement-metrics-operator --sort-by='.lastTimestamp'"
    echo ""
}

# Main execution
echo "Starting Red Hat Cost Management Service integration (official procedure)..."
echo ""

check_prerequisites
verify_package_manifests
install_operator
configure_service_account_auth
create_cost_config
configure_namespace_labels
verify_installation
provide_dashboard_access

echo "🎉 Red Hat Cost Management Service integration completed!"
echo "📊 Your healthcare ML cluster will appear in the Red Hat dashboard within 1-2 hours"
echo "🌐 Access: https://console.redhat.com/openshift/cost-management"
