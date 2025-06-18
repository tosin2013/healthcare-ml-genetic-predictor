# Configure KEDA Scaling - Healthcare ML System

## 🎯 Overview

This guide shows how to configure KEDA (Kubernetes Event-driven Autoscaling) for the Healthcare ML Genetic Predictor system based on the current OpenShift deployment.

## 📋 Prerequisites

- OpenShift cluster with KEDA operator installed
- Healthcare ML demo namespace deployed
- Kafka cluster running with genetic data topics

## 🔍 Current KEDA Configuration

### Verify KEDA Installation

```bash
# Check KEDA operator status
oc get operators -A | grep keda

# Expected output:
# keda.openshift-operators                                          5d10h
# openshift-custom-metrics-autoscaler-operator.openshift-keda       3d

# Check KEDA controller pods
oc get pods -n openshift-keda
```

### Current ScaledObjects

```bash
# List all KEDA ScaledObjects in healthcare-ml-demo
oc get scaledobjects -n healthcare-ml-demo

# Expected output:
# NAME                           SCALETARGETKIND      SCALETARGETNAME             MIN   MAX   TRIGGERS
# vep-service-nodescale-scaler   apps/v1.Deployment   vep-service-nodescale       0     20    kafka
# vep-service-scaler             apps/v1.Deployment   vep-service                 0     50    kafka
# websocket-service-scaler       apps/v1.Deployment   quarkus-websocket-service   1     10    kafka
```

## ⚙️ KEDA Configuration Details

### 1. WebSocket Service Scaler


````yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: websocket-service-scaler
spec:
  scaleTargetRef:
    name: quarkus-websocket-service
  minReplicaCount: 1  # Always keep 1 instance for WebSocket sessions
  maxReplicaCount: 10
  triggers:
  - type: kafka
    metadata:
      bootstrapServers: genetic-data-cluster-kafka-bootstrap.healthcare-ml-demo.svc.cluster.local:9092
      consumerGroup: websocket-results-service-group
      topic: genetic-data-processed
      lagThreshold: "10"
````


### 2. VEP Service Scaler


````yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: vep-service-scaler
spec:
  scaleTargetRef:
    name: vep-service
  minReplicaCount: 0  # Scale to zero when no work
  maxReplicaCount: 50
  triggers:
  - type: kafka
    metadata:
      bootstrapServers: genetic-data-cluster-kafka-bootstrap.healthcare-ml-demo.svc.cluster.local:9092
      consumerGroup: vep-service-group
      topic: genetic-data-raw
      lagThreshold: "3"
````


## 🔧 Configuration Tasks

### Monitor KEDA Scaling Behavior

```bash
# Watch ScaledObject status
oc get scaledobjects -n healthcare-ml-demo -w

# Check HPA created by KEDA
oc get hpa -n healthcare-ml-demo

# Monitor scaling events
oc get events -n healthcare-ml-demo --field-selector reason=ScalingReplicaSet
```

### Verify Kafka Connectivity

```bash
# Test Kafka bootstrap server connectivity
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-topics.sh --bootstrap-server localhost:9092 --list

# Expected topics:
# genetic-data-raw
# genetic-data-processed

# Check consumer group lag
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --describe --group vep-service-group
```

### Adjust Scaling Parameters

#### Modify Lag Threshold
```bash
# Edit the ScaledObject to adjust sensitivity
oc edit scaledobject vep-service-scaler -n healthcare-ml-demo

# Change lagThreshold value:
# - Lower value (1-2): More sensitive, scales up quickly
# - Higher value (5-10): Less sensitive, scales up with more lag
```

#### Modify Replica Limits
```bash
# Adjust min/max replicas based on workload requirements
oc patch scaledobject vep-service-scaler -n healthcare-ml-demo --type='merge' -p='
{
  "spec": {
    "minReplicaCount": 0,
    "maxReplicaCount": 20
  }
}'
```

## 📊 Monitoring and Troubleshooting

### Check Scaling Metrics

```bash
# View KEDA metrics
oc describe scaledobject vep-service-scaler -n healthcare-ml-demo

# Check current replica count
oc get deployment vep-service -n healthcare-ml-demo

# Monitor pod scaling events
oc get events -n healthcare-ml-demo | grep -E "(Scaled|Created|Started)"
```

### Common Issues and Solutions

#### **Issue: ScaledObject not scaling**
```bash
# Check KEDA controller logs
oc logs -n openshift-keda deployment/keda-operator

# Verify Kafka connectivity from KEDA
oc exec -n openshift-keda deployment/keda-operator -- \
  nslookup genetic-data-cluster-kafka-bootstrap.healthcare-ml-demo.svc.cluster.local
```

#### **Issue: Scaling too aggressive**
```bash
# Increase cooldown period
oc patch scaledobject vep-service-scaler -n healthcare-ml-demo --type='merge' -p='
{
  "spec": {
    "cooldownPeriod": 300
  }
}'
```

#### **Issue: Not scaling to zero**
```bash
# Verify no active consumers
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --describe --group vep-service-group

# Check for stuck messages
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-run-class.sh kafka.tools.GetOffsetShell \
  --broker-list localhost:9092 --topic genetic-data-raw
```

## 🎯 Best Practices

### Healthcare ML Workload Optimization

1. **WebSocket Service**: Keep minimum 1 replica for session continuity
2. **VEP Service**: Allow scale-to-zero for cost optimization
3. **Lag Threshold**: Set based on processing time requirements
4. **Cooldown Period**: Allow sufficient time for genetic analysis completion

### Cost Management Integration

```bash
# Verify cost attribution labels on ScaledObjects
oc get scaledobject vep-service-scaler -n healthcare-ml-demo -o yaml | grep -A 5 labels

# Expected labels:
# cost-center: "genomics-research"
# project: "risk-predictor-v1"
```

### Performance Tuning

```bash
# Monitor resource usage during scaling
oc top pods -n healthcare-ml-demo

# Adjust resource requests/limits based on scaling behavior
oc describe deployment vep-service -n healthcare-ml-demo | grep -A 10 "Limits\|Requests"
```

---

**🎯 This configuration enables efficient autoscaling for healthcare ML workloads while maintaining cost optimization and session continuity!**
