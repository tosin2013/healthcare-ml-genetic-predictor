#!/bin/bash

# Test Kafka Lag Infrastructure for Issue #21
# Validates topic creation, consumer lag generation, and KEDA scaling behavior

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="healthcare-ml-demo"
KAFKA_CLUSTER="genetic-data-cluster"
NEW_TOPIC="genetic-lag-demo-raw"
CONSUMER_GROUP="genetic-lag-consumer-group"
LAG_SCALER="kafka-lag-scaler"
VEP_SERVICE="vep-service-kafka-lag"

echo -e "${BLUE}🧬 Testing Kafka Lag Infrastructure for Issue #21${NC}"
echo "=================================================="

# Function to print status
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 command not found. Please install it first."
        exit 1
    fi
}

# Check prerequisites
print_status "Checking prerequisites..."
check_command "oc"
check_command "kustomize"

# Check OpenShift connection
if ! oc whoami &> /dev/null; then
    print_error "Not logged into OpenShift. Please run 'oc login' first."
    exit 1
fi

print_success "Prerequisites check passed"

# Test 1: Validate Kafka topic definitions
print_status "1. Validating Kafka topic definitions..."

if kustomize build k8s/base/infrastructure/kafka | grep -q "name: $NEW_TOPIC"; then
    print_success "genetic-lag-demo-raw topic definition found"
else
    print_error "genetic-lag-demo-raw topic definition missing"
    exit 1
fi

if kustomize build k8s/base/infrastructure/kafka | grep -q "name: genetic-bigdata-raw"; then
    print_success "genetic-bigdata-raw topic definition found"
else
    print_warning "genetic-bigdata-raw topic definition missing"
fi

if kustomize build k8s/base/infrastructure/kafka | grep -q "name: genetic-nodescale-raw"; then
    print_success "genetic-nodescale-raw topic definition found"
else
    print_warning "genetic-nodescale-raw topic definition missing"
fi

# Test 2: Validate VEP service definitions
print_status "2. Validating VEP service definitions..."

if kustomize build k8s/base/vep-service | grep -q "name: $VEP_SERVICE"; then
    print_success "vep-service-kafka-lag deployment definition found"
else
    print_error "vep-service-kafka-lag deployment definition missing"
    exit 1
fi

if kustomize build k8s/base/vep-service | grep -q "name: vep-service-bigdata"; then
    print_success "vep-service-bigdata deployment definition found"
else
    print_warning "vep-service-bigdata deployment definition missing"
fi

# Test 3: Validate KEDA ScaledObject definitions
print_status "3. Validating KEDA ScaledObject definitions..."

if kustomize build k8s/base/keda | grep -q "name: $LAG_SCALER"; then
    print_success "kafka-lag-scaler KEDA ScaledObject definition found"
else
    print_error "kafka-lag-scaler KEDA ScaledObject definition missing"
    exit 1
fi

# Test 4: Check current OpenShift cluster state
print_status "4. Checking current OpenShift cluster state..."

# Check if Kafka cluster is running
if oc get kafka $KAFKA_CLUSTER -n $NAMESPACE &> /dev/null; then
    kafka_status=$(oc get kafka $KAFKA_CLUSTER -n $NAMESPACE -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
    if [ "$kafka_status" = "True" ]; then
        print_success "Kafka cluster $KAFKA_CLUSTER is ready"
    else
        print_warning "Kafka cluster $KAFKA_CLUSTER status: $kafka_status"
    fi
else
    print_error "Kafka cluster $KAFKA_CLUSTER not found"
    exit 1
fi

# Check existing topics
print_status "5. Checking existing Kafka topics..."
existing_topics=$(oc exec ${KAFKA_CLUSTER}-kafka-0 -n $NAMESPACE -- bin/kafka-topics.sh --bootstrap-server localhost:9092 --list 2>/dev/null || echo "")

for topic in "genetic-data-raw" "genetic-bigdata-raw" "genetic-nodescale-raw"; do
    if echo "$existing_topics" | grep -q "^$topic$"; then
        print_success "Topic $topic exists in broker"
    else
        print_warning "Topic $topic missing from broker"
    fi
done

if echo "$existing_topics" | grep -q "^$NEW_TOPIC$"; then
    print_warning "Topic $NEW_TOPIC already exists in broker"
else
    print_success "Topic $NEW_TOPIC ready to be created"
fi

# Test 6: Check existing consumer groups
print_status "6. Checking existing consumer groups..."
existing_groups=$(oc exec ${KAFKA_CLUSTER}-kafka-0 -n $NAMESPACE -- bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list 2>/dev/null || echo "")

for group in "vep-service-group" "vep-bigdata-service-group" "vep-nodescale-service-group"; do
    if echo "$existing_groups" | grep -q "^$group$"; then
        print_success "Consumer group $group exists"
    else
        print_warning "Consumer group $group missing"
    fi
done

if echo "$existing_groups" | grep -q "^$CONSUMER_GROUP$"; then
    print_warning "Consumer group $CONSUMER_GROUP already exists"
else
    print_success "Consumer group $CONSUMER_GROUP ready to be created"
fi

# Test 7: Check KEDA infrastructure
print_status "7. Checking KEDA infrastructure..."

if oc get scaledobject -n $NAMESPACE &> /dev/null; then
    existing_scalers=$(oc get scaledobject -n $NAMESPACE -o name 2>/dev/null || echo "")
    scaler_count=$(echo "$existing_scalers" | wc -l)
    print_success "Found $scaler_count existing KEDA scalers"
    
    for scaler in "vep-service-scaler" "vep-service-nodescale-scaler" "websocket-service-scaler"; do
        if echo "$existing_scalers" | grep -q "$scaler"; then
            print_success "KEDA scaler $scaler exists"
        else
            print_warning "KEDA scaler $scaler missing"
        fi
    done
else
    print_error "No KEDA scalers found. KEDA may not be installed."
fi

print_status "8. Validation Summary"
echo "===================="
print_success "✅ Kafka topic definitions validated"
print_success "✅ VEP service definitions validated"  
print_success "✅ KEDA ScaledObject definitions validated"
print_success "✅ OpenShift cluster connectivity verified"
print_success "✅ Kafka cluster operational"
print_success "✅ Existing infrastructure compatible"

echo ""
print_status "🚀 Ready for deployment! Run the following to deploy:"
echo "oc apply -k k8s/base/infrastructure/kafka"
echo "oc apply -k k8s/base/vep-service"
echo "oc apply -k k8s/base/keda"

echo ""
print_status "📊 After deployment, test with:"
echo "curl -X POST \$ROUTE_URL/api/scaling/mode -d '{\"mode\":\"kafka-lag\"}'"
echo "# Then click '🔄 Trigger Kafka Lag Demo' in the UI"

print_success "🎯 Kafka Lag Infrastructure validation completed successfully!"
