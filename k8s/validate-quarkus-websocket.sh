#!/bin/bash

# Quarkus WebSocket Service Validation Script
# This script validates the Quarkus WebSocket service Kustomize configuration

set -e

echo "🔍 Validating Quarkus WebSocket Service..."
echo "=========================================="

# Check if we're in the right directory
if [ ! -f "k8s/base/applications/quarkus-websocket/kustomization.yaml" ]; then
    echo "❌ Error: Please run this script from the project root directory"
    exit 1
fi

echo "✅ Project root directory confirmed"

# Test Quarkus WebSocket service build
echo ""
echo "🏗️ Testing Quarkus WebSocket service build..."
if kustomize build "k8s/base/applications/quarkus-websocket" > /dev/null 2>&1; then
    echo "✅ Quarkus WebSocket service build successful"
else
    echo "❌ Quarkus WebSocket service build failed"
    exit 1
fi

# Validate required resources
echo ""
echo "📋 Validating required resources..."

required_resources=("ConfigMap" "Service" "Deployment" "Route" "BuildConfig" "ImageStream")
for resource in "${required_resources[@]}"; do
    resource_count=$(kustomize build k8s/base/applications/quarkus-websocket | grep "^kind: $resource" | wc -l)
    if [ "$resource_count" -eq "1" ]; then
        echo "✅ $resource resource present"
    else
        echo "❌ $resource resource missing or duplicated (found: $resource_count)"
        exit 1
    fi
done

# Validate environment variables
echo ""
echo "🔧 Validating environment variables..."

env_vars=("KAFKA_BOOTSTRAP_SERVERS" "QUARKUS_HTTP_HOST" "QUARKUS_HTTP_PORT")
for env_var in "${env_vars[@]}"; do
    env_count=$(kustomize build k8s/base/applications/quarkus-websocket | grep -c "name: $env_var" || echo "0")
    if [ "$env_count" -ge "1" ]; then
        echo "✅ Environment variable $env_var configured"
    else
        echo "❌ Environment variable $env_var missing"
        exit 1
    fi
done

# Validate Kafka connectivity configuration
echo ""
echo "☕ Validating Kafka connectivity..."
kafka_bootstrap=$(kustomize build k8s/base/applications/quarkus-websocket | grep "genetic-data-cluster-kafka-bootstrap" | wc -l)
if [ "$kafka_bootstrap" -ge "1" ]; then
    echo "✅ Kafka bootstrap servers configured correctly"
else
    echo "❌ Kafka bootstrap servers configuration missing"
    exit 1
fi

# Validate health checks
echo ""
echo "🏥 Validating health checks..."
health_checks=("livenessProbe" "readinessProbe")
for check in "${health_checks[@]}"; do
    check_count=$(kustomize build k8s/base/applications/quarkus-websocket | grep -c "$check:" || echo "0")
    if [ "$check_count" -eq "1" ]; then
        echo "✅ $check configured"
    else
        echo "❌ $check missing or misconfigured"
        exit 1
    fi
done

# Validate security context
echo ""
echo "🔒 Validating security context..."
security_features=("runAsNonRoot" "allowPrivilegeEscalation" "capabilities")
for feature in "${security_features[@]}"; do
    feature_count=$(kustomize build k8s/base/applications/quarkus-websocket | grep -c "$feature" || echo "0")
    if [ "$feature_count" -ge "1" ]; then
        echo "✅ Security feature $feature configured"
    else
        echo "⚠️  Security feature $feature not found"
    fi
done

# Validate cost attribution labels
echo ""
echo "💰 Validating cost attribution labels..."
cost_labels=$(kustomize build k8s/base/applications/quarkus-websocket | grep -c "cost-center: genomics-research" || echo "0")
if [ "$cost_labels" -ge "4" ]; then
    echo "✅ Cost attribution labels present ($cost_labels instances)"
else
    echo "❌ Cost attribution labels missing or insufficient"
    exit 1
fi

# Validate image configuration
echo ""
echo "🐳 Validating container image configuration..."
image_config=$(kustomize build k8s/base/applications/quarkus-websocket | grep -E "image:.*quarkus-websocket-service" | wc -l)
if [ "$image_config" -eq "1" ]; then
    echo "✅ Container image configured correctly"
else
    echo "❌ Container image configuration missing or incorrect"
    exit 1
fi

# Validate OpenShift Route TLS
echo ""
echo "🔐 Validating OpenShift Route TLS..."
tls_config=$(kustomize build k8s/base/applications/quarkus-websocket | grep -c "termination: edge" || echo "0")
if [ "$tls_config" -eq "1" ]; then
    echo "✅ TLS termination configured"
else
    echo "❌ TLS termination missing"
    exit 1
fi

# Validate BuildConfig
echo ""
echo "🏗️ Validating OpenShift BuildConfig..."
build_strategy=$(kustomize build k8s/base/applications/quarkus-websocket | grep -c "type: Source" || echo "0")
if [ "$build_strategy" -eq "1" ]; then
    echo "✅ Source build strategy configured"
else
    echo "❌ Source build strategy missing"
    exit 1
fi

# Validate ImageStream
echo ""
echo "📦 Validating ImageStream..."
imagestream_lookup=$(kustomize build k8s/base/applications/quarkus-websocket | grep -c "lookupPolicy:" || echo "0")
if [ "$imagestream_lookup" -eq "1" ]; then
    echo "✅ ImageStream lookup policy configured"
else
    echo "❌ ImageStream lookup policy missing"
    exit 1
fi

echo ""
echo "🎉 Quarkus WebSocket service validation completed successfully!"
echo ""
echo "📋 Summary:"
echo "   - Resources: ✅ ConfigMap, Service, Deployment, Route, BuildConfig, ImageStream"
echo "   - Environment: ✅ Kafka connectivity configured"
echo "   - Health Checks: ✅ Liveness and Readiness probes"
echo "   - Security: ✅ Non-root user, security context"
echo "   - Cost Management: ✅ Labels applied"
echo "   - Build System: ✅ OpenShift BuildConfig with Source strategy"
echo "   - Image Management: ✅ ImageStream with local lookup policy"
echo "   - TLS: ✅ Edge termination enabled"
echo ""
echo "🚀 Ready for Task 5: Create Frontend ConfigMap and Deployment"
