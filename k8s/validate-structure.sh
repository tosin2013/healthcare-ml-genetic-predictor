#!/bin/bash

# Healthcare ML Kustomize Structure Validation Script
# This script validates the Kustomize directory structure and configuration

set -e

echo "🔍 Validating Healthcare ML Kustomize Structure..."
echo "=================================================="

# Check if we're in the right directory
if [ ! -f "k8s/base/kustomization.yaml" ]; then
    echo "❌ Error: Please run this script from the project root directory"
    exit 1
fi

echo "✅ Project root directory confirmed"

# Validate directory structure
echo ""
echo "📁 Checking directory structure..."

required_dirs=(
    "k8s/base/operators/amq-streams"
    "k8s/base/operators/serverless" 
    "k8s/base/operators/keda"
    "k8s/base/operators/openshift-ai"
    "k8s/base/infrastructure/namespace"
    "k8s/base/infrastructure/kafka"
    "k8s/base/applications/quarkus-websocket"
    "k8s/base/applications/frontend"
    "k8s/base/applications/ml-inference"
    "k8s/base/eventing/kafka-source"
    "k8s/base/eventing/keda-scaler"
    "k8s/overlays/dev"
    "k8s/overlays/staging"
    "k8s/overlays/prod"
    "k8s/components/cost-labels"
    "k8s/components/security-context"
)

for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        echo "✅ $dir"
    else
        echo "❌ Missing: $dir"
        exit 1
    fi
done

# Validate kustomization.yaml files exist
echo ""
echo "📄 Checking kustomization.yaml files..."

required_files=(
    "k8s/base/kustomization.yaml"
    "k8s/overlays/dev/kustomization.yaml"
    "k8s/overlays/staging/kustomization.yaml"
    "k8s/overlays/prod/kustomization.yaml"
    "k8s/components/cost-labels/kustomization.yaml"
    "k8s/components/security-context/kustomization.yaml"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ Missing: $file"
        exit 1
    fi
done

# Check if kustomize is available
echo ""
echo "🔧 Checking kustomize availability..."
if command -v kustomize &> /dev/null; then
    echo "✅ kustomize found: $(kustomize version --short 2>/dev/null || echo 'version check failed')"
else
    echo "⚠️  kustomize not found in PATH, checking oc kustomize support..."
    if oc kustomize --help &> /dev/null; then
        echo "✅ oc kustomize support available"
    else
        echo "❌ Neither kustomize nor oc kustomize available"
        exit 1
    fi
fi

# Validate YAML syntax (basic check)
echo ""
echo "📝 Validating YAML syntax..."
for file in $(find k8s/ -name "*.yaml" -type f); do
    if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
        echo "✅ $file"
    else
        echo "❌ Invalid YAML: $file"
        exit 1
    fi
done

echo ""
echo "🎉 Kustomize structure validation completed successfully!"
echo ""
echo "📋 Summary:"
echo "   - Directory structure: ✅ Complete"
echo "   - Kustomization files: ✅ Present"
echo "   - YAML syntax: ✅ Valid"
echo "   - Tools: ✅ Available"
echo ""
echo "🚀 Ready for Task 2: Implement Operator Subscriptions"
echo ""
echo "Next steps:"
echo "1. Implement operator subscription manifests"
echo "2. Add infrastructure resources (namespace, Kafka)"
echo "3. Deploy application components"
echo "4. Configure eventing and autoscaling"
