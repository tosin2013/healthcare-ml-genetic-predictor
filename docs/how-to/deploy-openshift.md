# How to Deploy to OpenShift - Healthcare ML Genetic Predictor

## 🎯 Overview

This guide provides step-by-step instructions for deploying the Healthcare ML Genetic Predictor to Azure Red Hat OpenShift (ARO) with proper KEDA scaling, cost management, and production-ready configurations.

**⏱️ Estimated Time**: 60-90 minutes  
**👥 Audience**: DevOps engineers, platform administrators  
**📋 Prerequisites**: OpenShift cluster admin access, required operators installed

## 📋 Prerequisites

### OpenShift Cluster Requirements
- **Azure Red Hat OpenShift (ARO)** cluster (4.12+)
- **Cluster admin** privileges
- **Internet connectivity** for pulling images and accessing APIs

### Required Operators
Ensure these operators are installed via OperatorHub:

```bash
# Check installed operators
oc get csv -A | grep -E "(keda|amq-streams|cost-management)"

# Expected operators:
# - keda.v2.x.x (KEDA)
# - amqstreams.v2.x.x (Red Hat Integration - AMQ Streams)
# - cost-management-metrics-operator.v1.x.x (Cost Management)
```

### Install Missing Operators
```bash
# Install KEDA operator
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: keda
  namespace: openshift-keda
spec:
  channel: stable
  name: keda
  source: community-operators
  sourceNamespace: openshift-marketplace
EOF

# Install AMQ Streams operator
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: amq-streams
  namespace: openshift-operators
spec:
  channel: stable
  name: amq-streams
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF
```

## 🚀 Deployment Methods

### Method 1: Automated Deployment (Recommended)

#### Quick Deployment
```bash
# Clone repository
git clone https://github.com/tosin2013/healthcare-ml-genetic-predictor.git
cd healthcare-ml-genetic-predictor

# Run automated deployment script
./k8s/deploy-enhanced-infrastructure.sh

# This script will:
# 1. Create namespace with cost labels
# 2. Deploy Kafka infrastructure
# 3. Deploy applications with BuildConfigs
# 4. Configure KEDA scaling
# 5. Set up cost management
# 6. Validate deployment
```

#### Monitor Deployment Progress
```bash
# Watch deployment progress
watch oc get pods -n healthcare-ml-demo

# Check build progress
oc get builds -n healthcare-ml-demo
oc logs -f bc/quarkus-websocket-service -n healthcare-ml-demo
oc logs -f bc/vep-service -n healthcare-ml-demo
```

### Method 2: Manual Step-by-Step Deployment

#### Step 1: Create Namespace
```bash
# Create namespace with cost management labels
oc apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: healthcare-ml-demo
  labels:
    cost-center: genomics-research
    project: healthcare-ml-genetic-predictor
    environment: production
  annotations:
    openshift.io/display-name: "Healthcare ML Genetic Predictor"
    openshift.io/description: "Real-time genetic risk prediction with ML scaling"
EOF

# Set current project
oc project healthcare-ml-demo
```

#### Step 2: Deploy Kafka Infrastructure
```bash
# Deploy Kafka cluster
oc apply -k k8s/base/infrastructure/kafka/

# Wait for Kafka cluster to be ready (5-10 minutes)
oc wait --for=condition=Ready kafka/genetic-data-cluster --timeout=600s

# Verify Kafka pods
oc get pods | grep kafka
# Should show: genetic-data-cluster-kafka-* and genetic-data-cluster-zookeeper-*
```

#### Step 3: Deploy Applications
```bash
# Deploy VEP service
oc apply -k k8s/base/applications/vep-service/

# Deploy WebSocket service
oc apply -k k8s/base/applications/quarkus-websocket/

# Start builds
oc start-build vep-service --follow
oc start-build quarkus-websocket-service --follow
```

#### Step 4: Configure KEDA Scaling
```bash
# Deploy KEDA scalers
oc apply -k k8s/base/keda/

# Verify scalers are created
oc get scaledobject
# Should show: vep-service-scaler, websocket-service-scaler

# Check scaler status
oc describe scaledobject vep-service-scaler
```

#### Step 5: Set Up Cost Management
```bash
# Deploy cost management configuration
oc apply -k k8s/base/cost-management/

# Verify cost management operator
oc get pods -n openshift-cost-management
```

## 🔧 Configuration Customization

### Environment-Specific Overlays
```bash
# Deploy to specific environment
oc apply -k k8s/overlays/environments/demo/

# Available environments:
# - demo: Demo environment with cost tracking
# - production: Production-ready configuration
# - development: Development environment
```

### Custom Resource Limits
```bash
# Edit resource limits for VEP service
oc edit deployment vep-service

# Recommended production limits:
resources:
  limits:
    cpu: "2"
    memory: "4Gi"
  requests:
    cpu: "500m"
    memory: "1Gi"
```

### Scaling Configuration
```bash
# Customize KEDA scaling parameters
oc edit scaledobject vep-service-scaler

# Key parameters:
# - minReplicaCount: Minimum pods (0 for scale-to-zero)
# - maxReplicaCount: Maximum pods
# - lagThreshold: Kafka lag threshold for scaling
# - pollingInterval: How often to check metrics
# - cooldownPeriod: Time before scaling down
```

## 🌐 Networking and Routes

### Create Routes
```bash
# Create route for WebSocket service
oc expose service quarkus-websocket-service

# Get the route URL
oc get route quarkus-websocket-service -o jsonpath='{.spec.host}'

# Test the route
curl https://$(oc get route quarkus-websocket-service -o jsonpath='{.spec.host}')/q/health
```

### Configure TLS
```bash
# Enable TLS termination
oc patch route quarkus-websocket-service -p '{"spec":{"tls":{"termination":"edge"}}}'

# Verify TLS configuration
oc describe route quarkus-websocket-service | grep -A 5 "TLS"
```

## 📊 Monitoring and Observability

### Health Checks
```bash
# Check application health
curl https://$(oc get route quarkus-websocket-service -o jsonpath='{.spec.host}')/q/health

# Check VEP service health (internal)
oc exec -it $(oc get pods -l app=vep-service -o name | head -1) -- \
  curl http://localhost:8080/q/health
```

### Metrics and Monitoring
```bash
# Check Prometheus metrics
curl https://$(oc get route quarkus-websocket-service -o jsonpath='{.spec.host}')/q/metrics

# View KEDA metrics
oc get --raw /apis/external.metrics.k8s.io/v1beta1 | jq .
```

### Log Aggregation
```bash
# View application logs
oc logs -f deployment/quarkus-websocket-service
oc logs -f deployment/vep-service

# View Kafka logs
oc logs -f genetic-data-cluster-kafka-0
```

## 💰 Cost Management Setup

### Configure Cost Attribution
```bash
# Apply cost labels to all resources
oc label pods --all cost-center=genomics-research
oc label pods --all project=healthcare-ml-genetic-predictor

# Verify cost labels
oc get pods --show-labels | grep cost-center
```

### Set Up Red Hat Insights Integration
```bash
# Run cost management setup script
./scripts/setup-redhat-cost-management-official.sh

# This configures:
# - Service account for cost reporting
# - Automatic source creation
# - Cost attribution labels
```

## 🧪 Deployment Validation

### Comprehensive Validation
```bash
# Run validation script
./k8s/validate-complete-infrastructure.sh

# This checks:
# - All pods are running
# - Services are accessible
# - Kafka topics exist
# - KEDA scalers are active
# - Routes are working
```

### Manual Validation Steps
```bash
# 1. Check all pods are running
oc get pods
# All pods should be in "Running" state

# 2. Verify Kafka topics
oc exec -it genetic-data-cluster-kafka-0 -- \
  bin/kafka-topics.sh --bootstrap-server localhost:9092 --list

# 3. Test API endpoints
BASE_URL="https://$(oc get route quarkus-websocket-service -o jsonpath='{.spec.host}')"
curl -X POST $BASE_URL/api/genetic/analyze/normal \
  -H "Content-Type: application/json" \
  -d '{"genetic_sequence": "ATCGATCGATCG", "session_id": "validation-test"}'

# 4. Check KEDA scaling
oc get hpa
oc describe scaledobject vep-service-scaler
```

## 🔄 Scaling and Performance

### Test Scaling Behavior
```bash
# Generate load to trigger scaling
./scripts/generate-scaling-load.sh

# Monitor scaling in real-time
watch oc get pods

# Check KEDA scaling metrics
oc describe scaledobject vep-service-scaler | grep -A 10 "Current Metrics"
```

### Performance Tuning
```bash
# Optimize Kafka configuration
oc edit kafka genetic-data-cluster

# Key settings for performance:
config:
  num.network.threads: 8
  num.io.threads: 16
  socket.send.buffer.bytes: 102400
  socket.receive.buffer.bytes: 102400
```

## 🚨 Troubleshooting

### Common Issues

#### Build Failures
```bash
# Check build logs
oc logs -f bc/quarkus-websocket-service

# Common fixes:
# 1. Ensure Java 17 base image
# 2. Check Maven wrapper permissions
# 3. Verify source repository access
```

#### Pod Startup Issues
```bash
# Check pod events
oc describe pod <pod-name>

# Check resource constraints
oc get limitrange
oc get resourcequota
```

#### Kafka Connection Issues
```bash
# Check Kafka cluster status
oc get kafka genetic-data-cluster -o yaml

# Verify service endpoints
oc get svc | grep kafka

# Test Kafka connectivity
oc exec -it genetic-data-cluster-kafka-0 -- \
  bin/kafka-broker-api-versions.sh --bootstrap-server localhost:9092
```

#### KEDA Scaling Issues
```bash
# Check KEDA operator logs
oc logs -n openshift-keda deployment/keda-operator

# Verify scaler configuration
oc describe scaledobject vep-service-scaler

# Check HPA status
oc get hpa
oc describe hpa <hpa-name>
```

## 🔒 Security Considerations

### Network Policies
```bash
# Apply network policies for isolation
oc apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: healthcare-ml-network-policy
  namespace: healthcare-ml-demo
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: openshift-ingress
  egress:
  - to: []
EOF
```

### Security Context
```bash
# Verify security contexts
oc get pods -o yaml | grep -A 10 securityContext

# Ensure non-root execution
oc get pods -o jsonpath='{.items[*].spec.securityContext.runAsNonRoot}'
```

## 🎉 Success Criteria

Your deployment is successful when:
- ✅ All pods are in "Running" state
- ✅ Routes are accessible and return healthy responses
- ✅ Kafka topics are created and accessible
- ✅ KEDA scalers are active and monitoring
- ✅ Cost management labels are applied
- ✅ API endpoints respond correctly
- ✅ WebSocket connections work properly

## 🔄 Next Steps

After successful deployment:
1. **Configure Monitoring**: Set up alerts and dashboards
2. **Performance Testing**: Run load tests to validate scaling
3. **Backup Strategy**: Implement backup for Kafka data
4. **CI/CD Integration**: Set up automated deployments
5. **Security Hardening**: Implement additional security measures

---

**🎯 Your Healthcare ML Genetic Predictor is now running on OpenShift with enterprise-grade scaling and cost management!**
