#!/bin/bash

# Configure Existing Cost Management for Red Hat Dashboard Visibility
# Updates existing cost management configuration to work with Red Hat Cost Management Service

set -euo pipefail

echo "🔧 Configuring Existing Cost Management for Dashboard Visibility"
echo "==============================================================="
echo "This script updates your existing cost management setup to be visible in Red Hat dashboard"
echo ""

# Check if we're connected to OpenShift
if ! oc whoami &>/dev/null; then
    echo "❌ Error: Not logged into OpenShift cluster"
    exit 1
fi

# Check if cost management operator exists
check_existing_setup() {
    echo "🔍 Checking existing cost management setup..."
    
    if oc get namespace costmanagement-metrics-operator &>/dev/null; then
        echo "✅ Cost management operator namespace exists"
    else
        echo "❌ Cost management operator not found. Please run setup-redhat-cost-management.sh first"
        exit 1
    fi
    
    if oc get costmanagementmetricsconfig healthcare-ml-demo-cost-config -n costmanagement-metrics-operator &>/dev/null; then
        echo "✅ Existing cost configuration found"
    else
        echo "❌ Cost configuration not found"
        exit 1
    fi
    echo ""
}

# Update authentication for Red Hat dashboard access
update_authentication() {
    echo "🔐 Updating authentication for Red Hat dashboard access"
    echo "======================================================"
    
    echo "⚠️  To see data in Red Hat Cost Management dashboard, you need:"
    echo "1. A Red Hat account with access to console.redhat.com"
    echo "2. Your cluster registered as a source in Red Hat Cost Management"
    echo ""
    
    echo "📋 Steps to register your cluster:"
    echo "1. Go to: https://console.redhat.com/openshift/cost-management"
    echo "2. Click 'Sources' in the left menu"
    echo "3. Click 'Add source' button"
    echo "4. Select 'OpenShift Container Platform'"
    echo "5. Follow the wizard to add your cluster"
    echo ""
    
    # Get cluster information for registration
    CLUSTER_ID=$(oc get clusterversion version -o jsonpath='{.spec.clusterID}' 2>/dev/null || echo "unknown")
    CLUSTER_NAME=$(oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}' 2>/dev/null || echo "unknown")
    CONSOLE_URL=$(oc whoami --show-console 2>/dev/null || echo "unknown")
    
    echo "📊 Your cluster information for registration:"
    echo "  Cluster ID: $CLUSTER_ID"
    echo "  Cluster Name: $CLUSTER_NAME"
    echo "  Console URL: $CONSOLE_URL"
    echo ""
    
    read -p "Have you registered your cluster in Red Hat Cost Management? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Please register your cluster first, then run this script again"
        echo "📖 Documentation: https://docs.redhat.com/en/documentation/cost_management_service/1-latest/html/integrating_openshift_container_platform_data_into_cost_management/"
        exit 1
    fi
    echo ""
}

# Update cost configuration for better dashboard visibility
update_cost_configuration() {
    echo "⚙️  Updating cost configuration for dashboard visibility"
    echo "======================================================"
    
    echo "Updating CostManagementMetricsConfig with enhanced settings..."
    
    # Update the existing configuration
    oc patch costmanagementmetricsconfig healthcare-ml-demo-cost-config \
        -n costmanagement-metrics-operator \
        --type='merge' \
        -p='{
            "metadata": {
                "labels": {
                    "app.kubernetes.io/name": "cost-management-operator",
                    "app.kubernetes.io/part-of": "healthcare-ml-demo"
                },
                "annotations": {
                    "cost-center": "genomics-research",
                    "project": "healthcare-ml-demo",
                    "description": "Cost management configuration for healthcare ML demo scaling and cost attribution"
                }
            },
            "spec": {
                "upload": {
                    "upload_cycle": 60,
                    "upload_toggle": true,
                    "upload_wait": 10,
                    "validate_cert": true
                },
                "packaging": {
                    "max_size_MB": 100,
                    "max_reports_to_store": 30
                }
            }
        }'
    
    echo "✅ Cost configuration updated"
    echo ""
}

# Configure namespace labels for cost optimization tracking
configure_namespace_labels() {
    echo "🏷️  Configuring namespace labels for cost optimization"
    echo "====================================================="
    
    echo "Adding Red Hat cost management labels..."
    oc label namespace healthcare-ml-demo \
        insights_cost_management_optimizations="true" \
        cost-center="genomics-research" \
        billing-model="chargeback" \
        project="healthcare-ml-demo" \
        environment="production" \
        --overwrite
    
    echo "Adding labels to costmanagement-metrics-operator namespace..."
    oc label namespace costmanagement-metrics-operator \
        cost-center="platform-operations" \
        billing-model="chargeback" \
        project="healthcare-ml-demo" \
        --overwrite
    
    echo "✅ Namespace labels configured"
    echo ""
}

# Verify configuration and provide status
verify_configuration() {
    echo "🔍 Verifying cost management configuration"
    echo "========================================="
    
    echo "📊 Cost Management Status:"
    oc get costmanagementmetricsconfig healthcare-ml-demo-cost-config \
        -n costmanagement-metrics-operator \
        -o custom-columns="NAME:.metadata.name,AGE:.metadata.creationTimestamp,STATUS:.status.reports.data_collected"
    echo ""
    
    echo "📈 Upload Status:"
    oc describe costmanagementmetricsconfig healthcare-ml-demo-cost-config \
        -n costmanagement-metrics-operator | grep -A 5 -B 5 "Upload\|Packaging\|Reports" || echo "Status information not available yet"
    echo ""
    
    echo "🏷️  Namespace Labels:"
    oc get namespace healthcare-ml-demo --show-labels | grep -E "(cost-center|billing-model|insights_cost)" || echo "Labels not found"
    echo ""
}

# Provide dashboard access instructions
provide_dashboard_access() {
    echo "🌐 Red Hat Cost Management Dashboard Access"
    echo "==========================================="
    
    echo "📊 Your cost data should now be visible in:"
    echo "  URL: https://console.redhat.com/openshift/cost-management"
    echo ""
    
    echo "🔍 What to look for in the dashboard:"
    echo "  1. Navigate to 'OpenShift' in the left menu"
    echo "  2. Select your cluster: healthcare-ml-demo-cluster"
    echo "  3. Filter by project: healthcare-ml-demo"
    echo "  4. View cost breakdown by:"
    echo "     - Node (see standard vs compute-intensive costs)"
    echo "     - Project (healthcare-ml-demo)"
    echo "     - Labels (cost-center: genomics-research vs genomics-research-demo)"
    echo ""
    
    echo "⏱️  Data Timeline:"
    echo "  - Configuration changes: Immediate"
    echo "  - First data collection: 1-2 hours"
    echo "  - Historical data: 24-48 hours"
    echo "  - Full cost reports: 2-3 days"
    echo ""
    
    echo "🎯 Testing Cost Visibility:"
    echo "  1. Trigger node scaling:"
    echo "     WEBSOCKET_URL=\"wss://quarkus-websocket-service-healthcare-ml-demo.apps.b9892ub1.eastus.aroapp.io/genetics\" node scripts/test-websocket-client.js node-scale \"\$(python3 -c \"import random; print(''.join(random.choices('ATCG', k=100000)))\")\""
    echo ""
    echo "  2. Monitor in Red Hat dashboard:"
    echo "     - Watch for cost spikes when compute-intensive nodes are created"
    echo "     - Compare costs between genomics-research and genomics-research-demo"
    echo "     - Track resource utilization trends"
    echo ""
    
    echo "🔧 Troubleshooting:"
    echo "  - If no data appears after 2 hours, check cluster registration"
    echo "  - Verify authentication in Red Hat console"
    echo "  - Check operator logs: oc logs -n costmanagement-metrics-operator -l app=cost-mgmt-operator"
    echo ""
}

# Main execution
echo "Starting cost management configuration update..."
echo ""

check_existing_setup
update_authentication
update_cost_configuration
configure_namespace_labels
verify_configuration
provide_dashboard_access

echo "✅ Cost management configuration updated for Red Hat dashboard visibility!"
echo "🌐 Access your cost data at: https://console.redhat.com/openshift/cost-management"
echo "📊 Data should be available within 1-2 hours"
