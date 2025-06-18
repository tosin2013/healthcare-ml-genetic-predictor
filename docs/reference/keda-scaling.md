# KEDA Scaling Reference - Healthcare ML System

## 🎯 Overview

This reference provides comprehensive details about KEDA (Kubernetes Event-driven Autoscaling) configurations in the Healthcare ML Genetic Predictor system based on the current OpenShift deployment.

## ⚡ Current KEDA Setup

### KEDA Operator Status

```bash
# Verify KEDA operators
oc get operators -A | grep keda

# Expected operators:
# keda.openshift-operators                                          5d10h
# openshift-custom-metrics-autoscaler-operator.openshift-keda       3d

# Check KEDA controller pods
oc get pods -n openshift-keda
oc get pods -n openshift-operators | grep keda
```

### Active ScaledObjects

```bash
# List all ScaledObjects
oc get scaledobjects -n healthcare-ml-demo

# Current ScaledObjects:
# NAME                           SCALETARGETKIND      SCALETARGETNAME             MIN   MAX   TRIGGERS
# vep-service-nodescale-scaler   apps/v1.Deployment   vep-service-nodescale       0     20    kafka
# vep-service-scaler             apps/v1.Deployment   vep-service                 0     50    kafka
# websocket-service-scaler       apps/v1.Deployment   quarkus-websocket-service   1     10    kafka
```

## 📊 ScaledObject Specifications

### websocket-service-scaler

#### **Purpose**
Scales WebSocket service based on VEP-annotated genetic data results for real-time frontend updates.

#### **Configuration**
```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: websocket-service-scaler
  namespace: healthcare-ml-demo
  labels:
    app: quarkus-websocket-service
    component: websocket
    cost-center: "genomics-research"
    project: "risk-predictor-v1"
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: quarkus-websocket-service
  pollingInterval: 15      # Check metrics every 15 seconds
  cooldownPeriod: 120      # Wait 2 minutes before scaling down
  minReplicaCount: 1       # Always maintain 1 replica for session continuity
  maxReplicaCount: 10      # Maximum replicas for cost control
  triggers:
  - type: kafka
    metadata:
      bootstrapServers: genetic-data-cluster-kafka-bootstrap.healthcare-ml-demo.svc.cluster.local:9092
      consumerGroup: websocket-results-service-group
      topic: genetic-data-annotated  # VEP-annotated results for frontend
      lagThreshold: "10"     # Scale up when lag > 10 messages
      offsetResetPolicy: latest
```

#### **Scaling Behavior**
- **Scale Up**: When `genetic-data-annotated` topic lag > 10 messages
- **Scale Down**: After 2 minutes of lag < 10 messages
- **Min Replicas**: 1 (maintains WebSocket session continuity)
- **Max Replicas**: 10 (cost optimization)

#### **Monitoring Commands**
```bash
# Check scaler status
oc describe scaledobject websocket-service-scaler -n healthcare-ml-demo

# Monitor HPA created by KEDA
oc get hpa keda-hpa-websocket-service-scaler -n healthcare-ml-demo

# Check current scaling metrics
oc describe hpa keda-hpa-websocket-service-scaler -n healthcare-ml-demo | grep -A 10 "Current metrics"
```

### vep-service-scaler

#### **Purpose**
Multi-topic KEDA scaler for VEP service supporting normal and big-data processing modes with scale-to-zero capability.

#### **Configuration**
```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: vep-service-scaler
  namespace: healthcare-ml-demo
  labels:
    app: vep-service
    component: vep-processor
    cost-center: "genomics-research"
    project: "risk-predictor-v1"
  annotations:
    description: "Multi-topic KEDA scaler for VEP service supporting normal, big-data, and node-scale modes"
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: vep-service
  pollingInterval: 5       # Check metrics every 5 seconds
  cooldownPeriod: 30       # Wait 30 seconds before scaling down
  minReplicaCount: 0       # Scale to zero for cost optimization
  maxReplicaCount: 50      # High max for burst processing
  triggers:
  - type: kafka
    metadata:
      bootstrapServers: genetic-data-cluster-kafka-bootstrap.healthcare-ml-demo.svc.cluster.local:9092
      consumerGroup: vep-service-group
      topic: genetic-data-raw
      lagThreshold: "5"      # Scale up when lag > 5 messages
      offsetResetPolicy: latest
      allowIdleConsumers: "false"
      scaleToZeroOnInvalidOffset: "true"
  - type: kafka
    metadata:
      bootstrapServers: genetic-data-cluster-kafka-bootstrap.healthcare-ml-demo.svc.cluster.local:9092
      consumerGroup: vep-bigdata-service-group
      topic: genetic-bigdata-raw
      lagThreshold: "2"      # More sensitive for big data processing
      offsetResetPolicy: latest
      allowIdleConsumers: "false"
      scaleToZeroOnInvalidOffset: "true"
```

#### **Scaling Behavior**
- **Multi-Topic Scaling**: Responds to lag in EITHER topic (OR logic)
- **Normal Mode**: Scale up when `genetic-data-raw` topic lag > 5 messages
- **Big Data Mode**: Scale up when `genetic-bigdata-raw` topic lag > 2 messages (more sensitive)
- **Scale Down**: After 30 seconds of lag < threshold on ALL topics
- **Scale to Zero**: When no messages in either queue for cooldown period
- **Max Replicas**: 50 (handles burst genetic analysis requests)
- **Consumer Groups**: Uses different consumer groups for each topic

#### **Monitoring Commands**
```bash
# Check scaler status
oc describe scaledobject vep-service-scaler -n healthcare-ml-demo

# Monitor consumer group lag for both topics
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --describe --group vep-service-group

oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --describe --group vep-bigdata-service-group

# Check deployment scaling
oc get deployment vep-service -n healthcare-ml-demo -w

# Monitor multi-topic KEDA metrics
oc describe scaledobject vep-service-scaler -n healthcare-ml-demo | grep -A 10 "External Metric Names"
```

### vep-service-nodescale-scaler

#### **Purpose**
Scales VEP service for large genetic datasets that require cluster autoscaler to provision additional nodes.

#### **Configuration**
```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: vep-service-nodescale-scaler
  namespace: healthcare-ml-demo
  labels:
    app: vep-service
    component: nodescale-mode
    scaling-type: cluster-autoscaler
    cost-center: "genomics-research"
    project: "risk-predictor-v1"
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: vep-service-nodescale
  pollingInterval: 5       # Check metrics every 5 seconds (more responsive)
  cooldownPeriod: 300      # Wait 5 minutes before scaling down (VEP processing time)
  minReplicaCount: 0       # Scale to zero when no work
  maxReplicaCount: 20      # High enough to trigger cluster autoscaler
  triggers:
  - type: kafka
    metadata:
      bootstrapServers: genetic-data-cluster-kafka-bootstrap.healthcare-ml-demo.svc.cluster.local:9092
      consumerGroup: vep-nodescale-service-group
      topic: genetic-nodescale-raw
      lagThreshold: "1"      # Very sensitive - scale up immediately
      offsetResetPolicy: latest
      allowIdleConsumers: "false"
      scaleToZeroOnInvalidOffset: "true"
```

#### **Scaling Behavior**
- **Scale Up**: When any message appears in `genetic-nodescale-raw` topic
- **Scale Down**: After 5 minutes of no messages (allows VEP processing completion)
- **Node Scaling**: High replica count triggers OpenShift cluster autoscaler
- **Resource Requirements**: Configured for compute-intensive nodes

#### **Monitoring Commands**
```bash
# Check scaler status
oc describe scaledobject vep-service-nodescale-scaler -n healthcare-ml-demo

# Monitor node scaling events
oc get events -A | grep -E "(node|autoscaler)"

# Check cluster autoscaler status
oc get clusterautoscaler -o yaml
```

## 🔧 KEDA Configuration Parameters

### Common Parameters

| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| pollingInterval | How often to check metrics (seconds) | 30 | 1-600 |
| cooldownPeriod | Wait time before scaling down (seconds) | 300 | 0-3600 |
| minReplicaCount | Minimum number of replicas | 0 | 0-100 |
| maxReplicaCount | Maximum number of replicas | 100 | 1-1000 |

### Kafka Trigger Parameters

| Parameter | Description | Example | Notes |
|-----------|-------------|---------|-------|
| bootstrapServers | Kafka broker endpoints | kafka:9092 | Required |
| consumerGroup | Consumer group name | my-group | Required |
| topic | Kafka topic name | my-topic | Required |
| lagThreshold | Messages lag threshold | "5" | String format |
| offsetResetPolicy | Offset reset behavior | latest | latest/earliest |

### Healthcare ML Optimizations

| Service | pollingInterval | cooldownPeriod | lagThreshold | Topics | Rationale |
|---------|----------------|----------------|--------------|--------|-----------|
| WebSocket | 15s | 120s | "10" | genetic-data-annotated | Balance responsiveness with stability |
| VEP Multi-Topic | 5s | 30s | "5"/"2" | genetic-data-raw, genetic-bigdata-raw | Multi-topic scaling for different modes |
| VEP NodeScale | 5s | 300s | "1" | genetic-nodescale-raw | Immediate scaling for cluster autoscaler |

## 📊 Scaling Metrics and Monitoring

### KEDA Metrics

```bash
# Check KEDA metrics endpoint
oc port-forward -n openshift-keda svc/keda-operator-metrics-apiserver 8080:8080 &
curl http://localhost:8080/metrics | grep keda

# Monitor ScaledObject metrics
oc get scaledobjects -n healthcare-ml-demo -o json | \
  jq '.items[] | {name: .metadata.name, currentReplicas: .status.currentReplicas, desiredReplicas: .status.desiredReplicas}'
```

### HPA Integration

```bash
# List HPAs created by KEDA
oc get hpa -n healthcare-ml-demo

# Check HPA metrics
oc describe hpa keda-hpa-vep-service-scaler -n healthcare-ml-demo

# Monitor HPA events
oc get events -n healthcare-ml-demo | grep HorizontalPodAutoscaler
```

### Kafka Lag Monitoring

```bash
# Monitor consumer group lag for all services
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --describe --all-groups

# Real-time lag monitoring
watch -n 5 'oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --describe --group vep-service-group'
```

## 🎯 Scaling Optimization

### Performance Tuning

#### **Adjust Lag Thresholds**
```bash
# More sensitive scaling (lower threshold)
oc patch scaledobject vep-service-scaler -n healthcare-ml-demo --type='merge' -p='
{
  "spec": {
    "triggers": [{
      "type": "kafka",
      "metadata": {
        "lagThreshold": "1"
      }
    }]
  }
}'

# Less sensitive scaling (higher threshold)
oc patch scaledobject vep-service-scaler -n healthcare-ml-demo --type='merge' -p='
{
  "spec": {
    "triggers": [{
      "type": "kafka",
      "metadata": {
        "lagThreshold": "10"
      }
    }]
  }
}'
```

#### **Adjust Cooldown Periods**
```bash
# Faster scale-down (shorter cooldown)
oc patch scaledobject vep-service-scaler -n healthcare-ml-demo --type='merge' -p='
{
  "spec": {
    "cooldownPeriod": 30
  }
}'

# Slower scale-down (longer cooldown)
oc patch scaledobject vep-service-scaler -n healthcare-ml-demo --type='merge' -p='
{
  "spec": {
    "cooldownPeriod": 300
  }
}'
```

### Cost Optimization

#### **Scale-to-Zero Configuration**
```bash
# Enable scale-to-zero for cost savings
oc patch scaledobject vep-service-scaler -n healthcare-ml-demo --type='merge' -p='
{
  "spec": {
    "minReplicaCount": 0
  }
}'

# Maintain minimum replicas for faster response
oc patch scaledobject websocket-service-scaler -n healthcare-ml-demo --type='merge' -p='
{
  "spec": {
    "minReplicaCount": 1
  }
}'
```

#### **Resource-Based Scaling Limits**
```bash
# Adjust max replicas based on cluster capacity
oc patch scaledobject vep-service-scaler -n healthcare-ml-demo --type='merge' -p='
{
  "spec": {
    "maxReplicaCount": 20
  }
}'
```

## 🚨 Troubleshooting

### Common Issues

#### **ScaledObject Not Scaling**
```bash
# Check KEDA operator logs
oc logs -n openshift-keda deployment/keda-operator

# Verify Kafka connectivity
oc exec -n openshift-keda deployment/keda-operator -- \
  nslookup genetic-data-cluster-kafka-bootstrap.healthcare-ml-demo.svc.cluster.local

# Check ScaledObject status
oc describe scaledobject vep-service-scaler -n healthcare-ml-demo | grep -A 10 "Conditions"
```

#### **Scaling Too Aggressive**
```bash
# Increase cooldown period
oc patch scaledobject vep-service-scaler -n healthcare-ml-demo --type='merge' -p='
{
  "spec": {
    "cooldownPeriod": 300
  }
}'

# Increase lag threshold
oc patch scaledobject vep-service-scaler -n healthcare-ml-demo --type='merge' -p='
{
  "spec": {
    "triggers": [{
      "type": "kafka",
      "metadata": {
        "lagThreshold": "10"
      }
    }]
  }
}'
```

#### **Not Scaling to Zero**
```bash
# Check for stuck consumer groups
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --describe --group vep-service-group

# Reset consumer group if needed
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --reset-offsets --to-latest --group vep-service-group \
  --topic genetic-data-raw --execute
```

#### **Multi-Topic Scaling Issues**
```bash
# Check all consumer groups for VEP service multi-topic scaler
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --describe --group vep-service-group

oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --describe --group vep-bigdata-service-group

# Check KEDA metrics for both topics
oc describe scaledobject vep-service-scaler -n healthcare-ml-demo | grep -A 20 "External Metric Names"

# Reset both consumer groups if needed
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --reset-offsets --to-latest --group vep-service-group \
  --topic genetic-data-raw --execute

oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --reset-offsets --to-latest --group vep-bigdata-service-group \
  --topic genetic-bigdata-raw --execute
```

---

**⚡ This KEDA scaling reference provides complete configuration details for efficient autoscaling in healthcare ML genetic analysis workflows!**
