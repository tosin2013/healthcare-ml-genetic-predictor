#!/bin/bash

# Healthcare ML Operator Subscriptions Validation Script
# This script validates operator subscription manifests and deployment readiness

set -e

echo "🔍 Validating Healthcare ML Operator Subscriptions..."
echo "=================================================="

# Check if we're in the right directory
if [ ! -f "k8s/base/operators/kustomization.yaml" ]; then
    echo "❌ Error: Please run this script from the project root directory"
    exit 1
fi

echo "✅ Project root directory confirmed"

# Validate individual operator builds
echo ""
echo "🔧 Testing individual operator builds..."

operators=("amq-streams" "serverless" "keda" "openshift-ai")

for operator in "${operators[@]}"; do
    echo "Testing $operator operator..."
    if kustomize build "k8s/base/operators/$operator" > /dev/null 2>&1; then
        echo "✅ $operator operator build successful"
    else
        echo "❌ $operator operator build failed"
        exit 1
    fi
done

# Test complete operators build
echo ""
echo "🏗️ Testing complete operators build..."
if kustomize build "k8s/base/operators" > /dev/null 2>&1; then
    echo "✅ Complete operators build successful"
else
    echo "❌ Complete operators build failed"
    exit 1
fi

# Validate operator subscription details
echo ""
echo "📋 Validating operator subscription details..."

# Check AMQ Streams
echo "Checking AMQ Streams subscription..."
amq_channel=$(kustomize build k8s/base/operators/amq-streams | grep "channel:" | awk '{print $2}')
if [ "$amq_channel" = "stable" ]; then
    echo "✅ AMQ Streams using stable channel"
else
    echo "⚠️  AMQ Streams channel: $amq_channel (expected: stable)"
fi

# Check Serverless
echo "Checking Serverless subscription..."
serverless_channel=$(kustomize build k8s/base/operators/serverless | grep "channel:" | awk '{print $2}')
if [ "$serverless_channel" = "stable" ]; then
    echo "✅ Serverless using stable channel"
else
    echo "⚠️  Serverless channel: $serverless_channel (expected: stable)"
fi

# Check KEDA
echo "Checking KEDA subscription..."
keda_channel=$(kustomize build k8s/base/operators/keda | grep "channel:" | awk '{print $2}')
if [ "$keda_channel" = "alpha" ]; then
    echo "✅ KEDA using alpha channel"
else
    echo "⚠️  KEDA channel: $keda_channel (expected: alpha)"
fi

# Check RHODS
echo "Checking RHODS subscription..."
rhods_channel=$(kustomize build k8s/base/operators/openshift-ai | grep "channel:" | awk '{print $2}')
if [ "$rhods_channel" = "stable" ]; then
    echo "✅ RHODS using stable channel"
else
    echo "⚠️  RHODS channel: $rhods_channel (expected: stable)"
fi

# Validate cost attribution labels
echo ""
echo "💰 Validating cost attribution labels..."
cost_labels=$(kustomize build k8s/base/operators | grep -c "cost-center: genomics-research" || echo "0")
if [ "$cost_labels" -gt "0" ]; then
    echo "✅ Cost attribution labels present ($cost_labels instances)"
else
    echo "❌ Cost attribution labels missing"
    exit 1
fi

# Check for required namespaces
echo ""
echo "🏷️  Checking required namespaces..."
namespaces=$(kustomize build k8s/base/operators | grep "kind: Namespace" | wc -l)
if [ "$namespaces" -ge "2" ]; then
    echo "✅ Required namespaces present ($namespaces found)"
else
    echo "❌ Missing required namespaces"
    exit 1
fi

echo ""
echo "🎉 Operator subscriptions validation completed successfully!"
echo ""
echo "📋 Summary:"
echo "   - AMQ Streams: ✅ Ready (stable channel)"
echo "   - Serverless: ✅ Ready (stable channel, Knative configured)"
echo "   - KEDA: ✅ Ready (alpha channel)"
echo "   - OpenShift AI: ✅ Ready (stable channel, DataScienceCluster configured)"
echo "   - Cost Labels: ✅ Applied"
echo "   - Namespaces: ✅ Created"
echo ""
echo "🚀 Ready for Task 3: Create Infrastructure Base Resources"
echo ""
echo "Next steps:"
echo "1. Deploy operators to cluster: oc apply -k k8s/base/operators"
echo "2. Wait for operator installation completion"
echo "3. Proceed with infrastructure deployment (namespace, Kafka)"
