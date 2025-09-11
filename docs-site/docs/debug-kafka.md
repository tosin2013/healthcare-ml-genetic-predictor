# Debug Kafka Flow - Healthcare ML System

## 🎯 Overview

This guide provides comprehensive Kafka debugging techniques for the Healthcare ML Genetic Predictor system based on the current OpenShift deployment.

## 📋 Current Kafka Setup

### Verify Kafka Cluster Status

```bash
# Check Kafka cluster health
oc get kafka genetic-data-cluster -n healthcare-ml-demo

# Verify Kafka pods are running
oc get pods -n healthcare-ml-demo | grep genetic-data-cluster

# Expected pods:
# genetic-data-cluster-entity-operator-xxx   2/2     Running
# genetic-data-cluster-kafka-0               1/1     Running  
# genetic-data-cluster-kafka-1               1/1     Running
# genetic-data-cluster-kafka-2               1/1     Running
# genetic-data-cluster-zookeeper-0           1/1     Running
# genetic-data-cluster-zookeeper-1           1/1     Running
# genetic-data-cluster-zookeeper-2           1/1     Running
```

### Current Topic Configuration

```bash
# List all Kafka topics
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-topics.sh --bootstrap-server localhost:9092 --list

# Expected topics:
# genetic-data-raw
# genetic-data-processed

# Describe topic configurations
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-topics.sh --bootstrap-server localhost:9092 --describe
```

## 🔍 Kafka Flow Debugging

### 1. Message Production Issues

#### **Symptoms**
- WebSocket service not sending messages to Kafka
- Genetic analysis requests not appearing in topics
- Producer connection errors

#### **Diagnosis**
```bash
# Check WebSocket service logs for Kafka producer errors
oc logs deployment/quarkus-websocket-service -n healthcare-ml-demo | grep -E "(kafka|producer|genetic-data)"

# Monitor topic for incoming messages
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 \
  --topic genetic-data-raw --from-beginning --max-messages 5

# Check producer configuration
oc get configmap -n healthcare-ml-demo | grep websocket
oc describe configmap quarkus-websocket-config -n healthcare-ml-demo
```

#### **Solutions**
```bash
# Test Kafka connectivity from WebSocket service
oc exec -it deployment/quarkus-websocket-service -n healthcare-ml-demo -- \
  nc -zv genetic-data-cluster-kafka-bootstrap.healthcare-ml-demo.svc.cluster.local 9092

# Restart WebSocket service if connection issues
oc rollout restart deployment/quarkus-websocket-service -n healthcare-ml-demo

# Verify Kafka bootstrap server configuration
oc get svc genetic-data-cluster-kafka-bootstrap -n healthcare-ml-demo
```

### 2. Message Consumption Issues

#### **Symptoms**
- VEP service not processing messages
- Consumer group lag increasing
- Messages accumulating in topics

#### **Diagnosis**
```bash
# Check consumer groups
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list

# Describe consumer group details
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --describe --group vep-service-group

# Check VEP service logs
oc logs deployment/vep-service -n healthcare-ml-demo | grep -E "(kafka|consumer|genetic)"
```

#### **Solutions**
```bash
# Reset consumer group if stuck
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --reset-offsets --to-latest --group vep-service-group \
  --topic genetic-data-raw --execute

# Check if VEP service deployment exists and is scaled up
oc get deployment vep-service -n healthcare-ml-demo
oc scale deployment vep-service --replicas=1 -n healthcare-ml-demo
```

### 3. Topic Configuration Issues

#### **Check Topic Health**
```bash
# Verify topic partitions and replication
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-topics.sh --bootstrap-server localhost:9092 \
  --describe --topic genetic-data-raw

# Check topic configuration
oc get kafkatopic genetic-data-raw -n healthcare-ml-demo -o yaml

# Monitor topic size and retention
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-log-dirs.sh --bootstrap-server localhost:9092 --describe
```

#### **Topic Optimization**
```bash
# Increase partitions if needed for better parallelism
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-topics.sh --bootstrap-server localhost:9092 \
  --alter --topic genetic-data-raw --partitions 6

# Update topic retention if messages are being deleted too quickly
oc patch kafkatopic genetic-data-raw -n healthcare-ml-demo --type='merge' -p='
{
  "spec": {
    "config": {
      "retention.ms": "1209600000"
    }
  }
}'
```

## 🔧 Advanced Kafka Debugging

### Message Flow Tracing

#### **End-to-End Message Tracing**
```bash
# Produce a test message
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-console-producer.sh --bootstrap-server localhost:9092 \
  --topic genetic-data-raw << EOF
{"sequence": "ATCGATCGATCG", "sessionId": "debug-test-$(date +%s)", "timestamp": "$(date -Iseconds)"}
EOF

# Monitor message consumption
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 \
  --topic genetic-data-processed --from-beginning --timeout-ms 30000
```

#### **Message Offset Analysis**
```bash
# Check current offsets for all partitions
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-run-class.sh kafka.tools.GetOffsetShell \
  --broker-list localhost:9092 --topic genetic-data-raw

# Monitor consumer lag in real-time
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --describe --group vep-service-group | grep -E "(TOPIC|genetic-data)"
```

### Performance Analysis

#### **Throughput Monitoring**
```bash
# Monitor producer performance
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-producer-perf-test.sh --topic genetic-data-raw \
  --num-records 100 --record-size 1024 --throughput 10 \
  --producer-props bootstrap.servers=localhost:9092

# Monitor consumer performance  
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-consumer-perf-test.sh --topic genetic-data-raw \
  --messages 100 --bootstrap-server localhost:9092
```

#### **Resource Usage Analysis**
```bash
# Monitor Kafka broker resource usage
oc top pods -n healthcare-ml-demo | grep genetic-data-cluster-kafka

# Check Kafka JVM metrics
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  jcmd 1 VM.memory_summary

# Monitor disk usage for Kafka logs
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  df -h /var/lib/kafka/data
```

## 🚨 Common Kafka Issues and Solutions

### Issue 1: Consumer Group Lag

#### **Diagnosis**
```bash
# Check consumer group lag
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --describe --group vep-service-group

# Monitor lag over time
watch -n 5 'oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --describe --group vep-service-group | grep genetic-data-raw'
```

#### **Solutions**
```bash
# Scale up VEP service to process more messages
oc scale deployment vep-service --replicas=3 -n healthcare-ml-demo

# Verify KEDA is scaling based on lag
oc describe scaledobject vep-service-scaler -n healthcare-ml-demo

# Adjust KEDA lag threshold if needed
oc patch scaledobject vep-service-scaler -n healthcare-ml-demo --type='merge' -p='
{
  "spec": {
    "triggers": [{
      "type": "kafka",
      "metadata": {
        "lagThreshold": "2"
      }
    }]
  }
}'
```

### Issue 2: Message Serialization Errors

#### **Diagnosis**
```bash
# Check for serialization errors in producer logs
oc logs deployment/quarkus-websocket-service -n healthcare-ml-demo | grep -E "(serializ|json|parse)"

# Check for deserialization errors in consumer logs
oc logs deployment/vep-service -n healthcare-ml-demo | grep -E "(deserializ|json|parse)"

# Examine message format in topic
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 \
  --topic genetic-data-raw --from-beginning --max-messages 1 --property print.headers=true
```

#### **Solutions**
```bash
# Validate message format with schema
cat > /tmp/test-message.json << EOF
{
  "sequence": "ATCGATCGATCG",
  "sessionId": "test-session",
  "timestamp": "$(date -Iseconds)",
  "mode": "normal"
}
EOF

# Test message production with correct format
oc exec -i genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-console-producer.sh --bootstrap-server localhost:9092 \
  --topic genetic-data-raw < /tmp/test-message.json
```

### Issue 3: Kafka Broker Connectivity

#### **Diagnosis**
```bash
# Test broker connectivity from different pods
oc exec -it deployment/quarkus-websocket-service -n healthcare-ml-demo -- \
  nc -zv genetic-data-cluster-kafka-bootstrap.healthcare-ml-demo.svc.cluster.local 9092

oc exec -it deployment/vep-service -n healthcare-ml-demo -- \
  nc -zv genetic-data-cluster-kafka-bootstrap.healthcare-ml-demo.svc.cluster.local 9092

# Check Kafka service endpoints
oc get endpoints genetic-data-cluster-kafka-bootstrap -n healthcare-ml-demo

# Verify DNS resolution
oc exec -it deployment/quarkus-websocket-service -n healthcare-ml-demo -- \
  nslookup genetic-data-cluster-kafka-bootstrap.healthcare-ml-demo.svc.cluster.local
```

#### **Solutions**
```bash
# Restart Kafka cluster if needed
oc annotate kafka genetic-data-cluster -n healthcare-ml-demo strimzi.io/manual-rolling-update=true

# Check network policies that might block traffic
oc get networkpolicies -n healthcare-ml-demo

# Verify service account permissions
oc describe serviceaccount default -n healthcare-ml-demo
```

## 📊 Kafka Monitoring and Metrics

### Built-in Kafka Metrics

```bash
# Access Kafka JMX metrics
oc port-forward genetic-data-cluster-kafka-0 9999:9999 -n healthcare-ml-demo &
curl http://localhost:9999/metrics

# Monitor Kafka exporter metrics
oc get svc genetic-data-cluster-kafka-exporter -n healthcare-ml-demo
oc port-forward svc/genetic-data-cluster-kafka-exporter 9308:9308 -n healthcare-ml-demo &
curl http://localhost:9308/metrics | grep kafka
```

### Custom Monitoring Scripts

```bash
# Create comprehensive Kafka health check
cat > scripts/kafka-health-check.sh << 'EOF'
#!/bin/bash
echo "🔍 Kafka Health Check - $(date)"
echo "================================"

echo "📊 Cluster Status:"
oc get kafka genetic-data-cluster -n healthcare-ml-demo

echo "🏃 Running Pods:"
oc get pods -n healthcare-ml-demo | grep genetic-data-cluster

echo "📝 Topics:"
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-topics.sh --bootstrap-server localhost:9092 --list

echo "👥 Consumer Groups:"
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list

echo "📈 Consumer Group Lag:"
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --all-groups
EOF

chmod +x scripts/kafka-health-check.sh
```

---

**🎯 This Kafka debugging guide provides comprehensive tools for maintaining reliable message flow in healthcare ML genetic analysis workflows!**
