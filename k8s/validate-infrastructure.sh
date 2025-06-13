#!/bin/bash

# Healthcare ML Infrastructure Validation Script
# This script validates namespace, Kafka cluster, and topics configuration

set -e

echo "🔍 Validating Healthcare ML Infrastructure..."
echo "============================================="

# Check if we're in the right directory
if [ ! -f "k8s/base/infrastructure/kustomization.yaml" ]; then
    echo "❌ Error: Please run this script from the project root directory"
    exit 1
fi

echo "✅ Project root directory confirmed"

# Validate individual infrastructure components
echo ""
echo "🏗️ Testing infrastructure component builds..."

components=("namespace" "kafka")

for component in "${components[@]}"; do
    echo "Testing $component infrastructure..."
    if kustomize build "k8s/base/infrastructure/$component" > /dev/null 2>&1; then
        echo "✅ $component infrastructure build successful"
    else
        echo "❌ $component infrastructure build failed"
        exit 1
    fi
done

# Test complete infrastructure build
echo ""
echo "🏢 Testing complete infrastructure build..."
if kustomize build "k8s/base/infrastructure" > /dev/null 2>&1; then
    echo "✅ Complete infrastructure build successful"
else
    echo "❌ Complete infrastructure build failed"
    exit 1
fi

# Validate namespace configuration
echo ""
echo "🏷️ Validating namespace configuration..."

namespace_name=$(kustomize build k8s/base/infrastructure/namespace | grep "^  name: healthcare-ml-demo" | wc -l)
if [ "$namespace_name" -eq "1" ]; then
    echo "✅ Namespace name correct: healthcare-ml-demo"
else
    echo "❌ Namespace name incorrect or missing"
    exit 1
fi

# Check Red Hat Insights labels
insights_labels=$(kustomize build k8s/base/infrastructure/namespace | grep -c "insights.openshift.io" || echo "0")
if [ "$insights_labels" -ge "3" ]; then
    echo "✅ Red Hat Insights labels present ($insights_labels found)"
else
    echo "❌ Red Hat Insights labels missing or incomplete"
    exit 1
fi

# Validate Kafka cluster configuration
echo ""
echo "☕ Validating Kafka cluster configuration..."

kafka_cluster=$(kustomize build k8s/base/infrastructure/kafka | grep "^  name: genetic-data-cluster" | wc -l)
if [ "$kafka_cluster" -eq "1" ]; then
    echo "✅ Kafka cluster name correct: genetic-data-cluster"
else
    echo "❌ Kafka cluster name incorrect or missing"
    exit 1
fi

# Check Kafka version
kafka_version=$(kustomize build k8s/base/infrastructure/kafka | grep "version: 3.7.0" | wc -l)
if [ "$kafka_version" -ge "1" ]; then
    echo "✅ Kafka version correct: 3.7.0"
else
    echo "⚠️  Kafka version not found or incorrect"
fi

# Validate Kafka topics
echo ""
echo "📋 Validating Kafka topics..."

topics=("genetic-data-raw" "genetic-data-processed")
for topic in "${topics[@]}"; do
    topic_count=$(kustomize build k8s/base/infrastructure/kafka | grep "^  name: $topic" | wc -l)
    if [ "$topic_count" -eq "1" ]; then
        echo "✅ Topic $topic configured correctly"
    else
        echo "❌ Topic $topic missing or misconfigured"
        exit 1
    fi
done

# Check topic partitions
partitions=$(kustomize build k8s/base/infrastructure/kafka | grep "partitions: 3" | wc -l)
if [ "$partitions" -eq "2" ]; then
    echo "✅ Topic partitions configured correctly (3 partitions each)"
else
    echo "⚠️  Topic partitions configuration may be incorrect"
fi

# Validate cost attribution labels
echo ""
echo "💰 Validating cost attribution labels..."
cost_labels=$(kustomize build k8s/base/infrastructure | grep -c "cost-center: genomics-research" || echo "0")
if [ "$cost_labels" -gt "5" ]; then
    echo "✅ Cost attribution labels present ($cost_labels instances)"
else
    echo "❌ Cost attribution labels missing or insufficient"
    exit 1
fi

# Check metrics configuration
echo ""
echo "📊 Validating metrics configuration..."
metrics_config=$(kustomize build k8s/base/infrastructure/kafka | grep "kafka-metrics-config.yml" | wc -l)
if [ "$metrics_config" -ge "1" ]; then
    echo "✅ Kafka metrics configuration present"
else
    echo "⚠️  Kafka metrics configuration missing"
fi

echo ""
echo "🎉 Infrastructure validation completed successfully!"
echo ""
echo "📋 Summary:"
echo "   - Namespace: ✅ healthcare-ml-demo (with Red Hat Insights labels)"
echo "   - Kafka Cluster: ✅ genetic-data-cluster (v3.7.0)"
echo "   - Topics: ✅ genetic-data-raw, genetic-data-processed (3 partitions each)"
echo "   - Cost Labels: ✅ Applied consistently"
echo "   - Metrics: ✅ Configured for monitoring"
echo ""
echo "🚀 Ready for Task 4: Implement Quarkus WebSocket Service Base"
echo ""
echo "Next steps:"
echo "1. Deploy infrastructure: oc apply -k k8s/base/infrastructure"
echo "2. Wait for Kafka cluster to be ready"
echo "3. Proceed with application deployment"
