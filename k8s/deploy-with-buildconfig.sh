#!/bin/bash

# Healthcare ML Quarkus WebSocket Service - BuildConfig Deployment Script
# This script deploys the Quarkus WebSocket service using OpenShift BuildConfig

set -e

echo "🚀 Deploying Quarkus WebSocket Service with BuildConfig..."
echo "========================================================"

# Check if we're in the right directory
if [ ! -f "k8s/base/applications/quarkus-websocket/kustomization.yaml" ]; then
    echo "❌ Error: Please run this script from the project root directory"
    exit 1
fi

# Check if we're logged into OpenShift
if ! oc whoami &> /dev/null; then
    echo "❌ Error: Not logged into OpenShift. Please run 'oc login' first."
    exit 1
fi

echo "✅ OpenShift login confirmed: $(oc whoami)"

# Check if the healthcare-ml-demo namespace exists
if ! oc get namespace healthcare-ml-demo &> /dev/null; then
    echo "❌ Error: healthcare-ml-demo namespace not found. Please deploy infrastructure first."
    exit 1
fi

echo "✅ Target namespace confirmed: healthcare-ml-demo"

# Deploy the Quarkus WebSocket service
echo ""
echo "📦 Deploying Quarkus WebSocket service resources..."
oc apply -k k8s/base/applications/quarkus-websocket

echo "✅ Resources deployed successfully"

# Wait for BuildConfig to be ready
echo ""
echo "⏳ Waiting for BuildConfig to be ready..."
oc wait --for=condition=Ready buildconfig/quarkus-websocket-service -n healthcare-ml-demo --timeout=60s

# Start the build
echo ""
echo "🏗️ Starting build..."
oc start-build quarkus-websocket-service -n healthcare-ml-demo --follow

# Wait for the build to complete
echo ""
echo "⏳ Waiting for build to complete..."
BUILD_NAME=$(oc get builds -n healthcare-ml-demo -l buildconfig=quarkus-websocket-service --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}')
oc wait --for=condition=Complete build/$BUILD_NAME -n healthcare-ml-demo --timeout=600s

echo "✅ Build completed successfully"

# Wait for deployment to be ready
echo ""
echo "⏳ Waiting for deployment to be ready..."
oc wait --for=condition=Available deployment/quarkus-websocket-service -n healthcare-ml-demo --timeout=300s

echo "✅ Deployment ready"

# Get the route URL
echo ""
echo "🌐 Getting route information..."
ROUTE_URL=$(oc get route quarkus-websocket-service -n healthcare-ml-demo -o jsonpath='{.spec.host}')
if [ -n "$ROUTE_URL" ]; then
    echo "✅ Route URL: https://$ROUTE_URL"
    echo "🔗 WebSocket endpoint: wss://$ROUTE_URL/genetics"
    echo "🏥 Health check: https://$ROUTE_URL/q/health"
else
    echo "⚠️  Route URL not found"
fi

# Check pod status
echo ""
echo "📊 Checking pod status..."
oc get pods -n healthcare-ml-demo -l app.kubernetes.io/name=quarkus-websocket-service

# Test health endpoint
echo ""
echo "🏥 Testing health endpoint..."
if [ -n "$ROUTE_URL" ]; then
    if curl -k -s "https://$ROUTE_URL/q/health" > /dev/null; then
        echo "✅ Health endpoint responding"
    else
        echo "⚠️  Health endpoint not responding (may still be starting up)"
    fi
fi

echo ""
echo "🎉 Quarkus WebSocket service deployment completed!"
echo ""
echo "📋 Next steps:"
echo "1. Test WebSocket connectivity: wss://$ROUTE_URL/genetics"
echo "2. Monitor logs: oc logs -f deployment/quarkus-websocket-service -n healthcare-ml-demo"
echo "3. Check metrics: https://$ROUTE_URL/q/metrics"
echo "4. Proceed with frontend deployment (Task 5)"
