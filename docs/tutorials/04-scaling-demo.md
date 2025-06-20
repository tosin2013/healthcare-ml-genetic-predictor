# Multi-Tier Scaling Demonstration Tutorial

**Learn how to demonstrate and understand the healthcare ML system's sophisticated multi-tier scaling capabilities**

## Overview

This tutorial guides you through hands-on demonstrations of the healthcare ML system's four-tier scaling architecture:

- **🟢 Normal Mode**: Standard pod scaling for typical genetic analysis workloads
- **🟡 Big Data Mode**: Memory-intensive pod scaling for large genetic datasets
- **🔴 Node Scale Mode**: Cluster autoscaler triggering for massive computational workloads
- **🟣 Kafka Lag Mode**: KEDA consumer lag-based scaling for event-driven workloads

You'll use the Node.js WebSocket client to test complete end-to-end flows while monitoring KEDA scaling behavior and cost attribution.

## Prerequisites

### Required Tools
```bash
# Verify OpenShift CLI access
oc whoami
oc project healthcare-ml-demo

# Verify Node.js is available
node --version  # Should be v16+ for WebSocket support

# Verify curl for API testing
curl --version
```

### Environment Verification
Run the demo readiness validation script:


````bash
#!/bin/bash
# Validate that all components are ready for scaling demo
./scripts/validate-demo-readiness.sh
````


Expected output should show:
- ✅ All Kafka topics available (7 topics including genetic-data-raw, genetic-bigdata-raw, genetic-nodescale-raw)
- ✅ KEDA ScaledObjects configured and ready
- ✅ VEP services deployments available
- ✅ WebSocket service accessible

## Part 1: Normal Mode Scaling Demo

### Step 1: Verify Baseline State

Check initial pod counts before scaling:

```bash
# Check VEP service pods (should be 0 initially)
oc get pods -l app=vep-service --no-headers | wc -l

# Check KEDA scaler status
oc describe scaledobject vep-service-scaler | grep -A 5 "Status:"

# Check Kafka consumer group lag
oc exec genetic-data-cluster-kafka-0 -- /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 --describe --group vep-service-group
```

### Step 2: Test Normal Mode with Node.js WebSocket Client

Use the Node.js script to test normal mode scaling:


````bash
# Test normal mode with 20bp sequence (triggers genetic-data-raw topic)
node scripts/test-websocket-client.js normal --generate 120
````


**Expected Behavior:**
- WebSocket connection established in <1000ms
- Genetic sequence sent to backend
- KEDA detects lag in `genetic-data-raw` topic
- VEP service scales from 0→1 pods
- VEP processing completes and results returned via WebSocket

### Step 3: Monitor Normal Mode Scaling

In a separate terminal, monitor the scaling behavior:

```bash
# Watch pod scaling in real-time
watch 'oc get pods -l app=vep-service'

# Monitor KEDA metrics
watch 'oc describe scaledobject vep-service-scaler | grep -A 10 "External Metric Names"'

# Check Kafka lag during processing
watch 'oc exec genetic-data-cluster-kafka-0 -- /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 --describe --group vep-service-group | grep genetic-data-raw'
```

### Step 4: Verify Normal Mode Results

After the Node.js script completes:

```bash
# Verify VEP pod scaled up and processed the request
oc logs -l app=vep-service --tail=20

# Check that pod scales back down to 0 after cooldown (30 seconds)
sleep 45
oc get pods -l app=vep-service
```

**✅ Success Criteria:**
- Node.js script receives VEP results with genetic annotations
- Pod scaling: 0→1→0 (scale-to-zero after processing)
- Total processing time: 15-60 seconds (including cold start)

## Part 2: Big Data Mode Scaling Demo

### Step 1: Configure Big Data Mode

Set the system to big data mode:

```bash
# Configure big data mode via API
curl -X POST https://quarkus-websocket-service-healthcare-ml-demo.apps.b9892ub1.eastus.aroapp.io/api/scaling/mode \
  -H "Content-Type: application/json" \
  -d '{"mode": "bigdata", "description": "Tutorial demo - big data mode"}'
```

### Step 2: Test Big Data Mode with Larger Sequence


````bash
# Test big data mode with auto-generated 100KB sequence
node scripts/test-websocket-client.js bigdata --generate 180
````


**Expected Behavior:**
- WebSocket sends JSON message with `resourceProfile: "high-memory"`
- KEDA detects lag in `genetic-bigdata-raw` topic (more sensitive: lagThreshold=2)
- VEP service scales more aggressively for memory-intensive processing
- Longer processing time due to larger sequence size

### Step 3: Monitor Big Data Scaling

```bash
# Monitor both consumer groups (normal and bigdata)
watch 'oc exec genetic-data-cluster-kafka-0 -- /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 --describe --group vep-bigdata-service-group'

# Watch for higher pod counts
watch 'oc get pods -l app=vep-service --show-labels'
```

**✅ Success Criteria:**
- Higher pod scaling due to lower lag threshold (lagThreshold=2 vs 5)
- Successful processing of larger genetic sequence
- Memory-intensive processing visible in pod resource usage

## Part 3: Node Scale Mode Scaling Demo

### Step 1: Configure Node Scale Mode

Set the system to node scale mode for cluster autoscaler demonstration:

```bash
# Configure node scale mode via API
curl -X POST https://quarkus-websocket-service-healthcare-ml-demo.apps.b9892ub1.eastus.aroapp.io/api/scaling/mode \
  -H "Content-Type: application/json" \
  -d '{"mode": "node-scale", "description": "Tutorial demo - node scale mode"}'
```

### Step 2: Test Node Scale Mode with Very Large Sequence


````bash
# Test node scale mode with auto-generated 1MB sequence
node scripts/test-websocket-client.js node-scale --generate 300
````


**Expected Behavior:**
- WebSocket sends JSON message with `resourceProfile: "cluster-scale"`
- KEDA detects lag in `genetic-nodescale-raw` topic (very sensitive: lagThreshold=1)
- VEP NodeScale service scales aggressively
- High pod count may trigger OpenShift cluster autoscaler

### Step 3: Monitor Node Scaling Behavior

```bash
# Monitor node scaling (may take 3-5 minutes for new nodes)
watch 'oc get nodes --show-labels | grep workload-type'

# Monitor VEP NodeScale pods
watch 'oc get pods -l app=vep-service-nodescale'

# Check cluster autoscaler activity
oc logs -n openshift-machine-api deployment/cluster-autoscaler-operator --tail=20
```

### Step 4: Trigger Heavy Load Demo

For more dramatic node scaling, use the API demo endpoint:

```bash
# Trigger heavy load demo (20 sequences of 50KB each = 1MB total)
curl -X POST https://quarkus-websocket-service-healthcare-ml-demo.apps.b9892ub1.eastus.aroapp.io/api/scaling/trigger-demo \
  -H "Content-Type: application/json" \
  -d '{"demoType": "node-scaling", "sequenceCount": 20, "sequenceSize": "50kb"}'
```

**✅ Success Criteria:**
- VEP NodeScale service scales to 10+ pods
- Cluster autoscaler may add new compute-intensive nodes
- Cost attribution visible with `cost-center=genomics-research` labels

## Part 4: Kafka Lag Mode Scaling Demo

> **📖 Comprehensive Tutorial**: For detailed coverage of Kafka lag-based scaling, see [Tutorial 5: Kafka Lag-Based Scaling with KEDA](05-kafka-lag-scaling.md)

### Step 1: Configure Kafka Lag Mode

Set the system to Kafka lag mode for KEDA consumer lag demonstration:

```bash
# Configure Kafka lag mode via API
curl -X POST https://quarkus-websocket-service-healthcare-ml-demo.apps.b9892ub1.eastus.aroapp.io/api/scaling/mode \
  -H "Content-Type: application/json" \
  -d '{"mode": "kafka-lag", "description": "Tutorial demo - Kafka consumer lag mode"}'
```

### Step 2: Test Kafka Lag Mode with Batch Messages

Use the UI trigger button to create sustained consumer lag:

**Using UI Trigger Button:**
1. Open the Healthcare ML Genetic Predictor interface
2. Select "🔄 Kafka Lag Mode (KEDA Consumer Lag)"
3. Click "🔄 Trigger Kafka Lag Demo" button
4. Monitor consumer lag and scaling behavior

**Expected Behavior:**
- Multiple batches of messages sent to create sustained lag
- KEDA monitors consumer lag and triggers HPA scaling
- VEP service scales based on lag thresholds
- Demonstrates lag-based scaling vs. CPU/memory-based scaling

### Step 3: Monitor Kafka Lag Scaling Behavior

```bash
# Monitor consumer lag and scaling
watch 'oc get scaledobject kafka-lag-scaler -o yaml | grep -A 5 "currentMetrics"'

# Monitor VEP service scaling
watch 'oc get pods -l app=vep-service-kafka-lag'

# Check Kafka topic lag
oc exec -it kafka-cluster-kafka-0 -- bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --describe --group genetic-lag-consumer-group
```

**✅ Success Criteria:**
- Consumer lag accumulates and triggers KEDA scaling
- VEP service scales based on lag thresholds (not CPU/memory)
- Demonstrates event-driven scaling with Kafka consumer lag
- Clear differentiation from other scaling modes

## Part 5: Monitoring and Validation

### Real-Time Scaling Monitoring

Use the comprehensive monitoring script to track all scaling activities:


````bash
# Run comprehensive scaling behavior test
./scripts/test-keda-scaling-behavior.sh --all
````


This script provides:
- Automated testing of all three scaling modes
- Real-time pod and node monitoring
- KEDA metrics tracking
- VEP processing logs
- Comprehensive scaling behavior documentation

### Cost Attribution Verification

Check that cost attribution is working correctly:

```bash
# Verify cost center labels on nodes
oc get nodes --show-labels | grep cost-center=genomics-research

# Check pod cost attribution
oc get pods -l cost-center=genomics-research --show-labels

# Monitor Red Hat Cost Management integration
oc get pods -n openshift-cost-management
```

### Frontend Interface Testing

Test the complete user experience through the web interface:

```bash
# Open the frontend interface
echo "🌐 Frontend URL: https://quarkus-websocket-service-healthcare-ml-demo.apps.b9892ub1.eastus.aroapp.io/genetic-client.html"
```

**Frontend Testing Steps:**
1. Open the Healthcare ML Genetic Predictor interface
2. Use the Multi-Tier Scaling Demo Controls
3. Test each scaling mode with dedicated trigger buttons:
   - **Normal Mode**: No trigger button (use manual sequence input)
   - **Big Data Mode**: Click "🚀 Trigger Big Data Demo" button
   - **Node Scale Mode**: Click "⚡ Trigger Node Scale Demo" button
   - **Kafka Lag Mode**: Click "🔄 Trigger Kafka Lag Demo" button
4. Monitor real-time scaling & cost display
5. Verify VEP annotation results appear in the UI

## Troubleshooting

### Common Issues and Solutions

**Issue: Node.js script times out**
```bash
# Check VEP service pod status
oc get pods -l app=vep-service

# Check KEDA scaler status
oc describe scaledobject vep-service-scaler

# Increase timeout in Node.js script
node scripts/test-websocket-client.js normal "ATCG..." 300  # 5 minutes
```

**Issue: Pods not scaling**
```bash
# Check Kafka consumer group lag
oc exec genetic-data-cluster-kafka-0 -- /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 --describe --group vep-service-group

# Reset consumer group if stuck
oc exec genetic-data-cluster-kafka-0 -- /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 --reset-offsets --to-latest \
  --group vep-service-group --topic genetic-data-raw --execute
```

**Issue: WebSocket connection fails**
```bash
# Check WebSocket service status
oc get pods -l app=quarkus-websocket-service

# Check service route
oc get route quarkus-websocket-service

# Test WebSocket endpoint directly
curl -k https://quarkus-websocket-service-healthcare-ml-demo.apps.b9892ub1.eastus.aroapp.io/api/scaling/health
```

## Next Steps

After completing this tutorial, explore:

1. **[Scaling Strategy](../explanation/scaling-strategy.md)** - Understand when to use each scaling mode
2. **[KEDA Scaling Reference](../reference/keda-scaling.md)** - Deep dive into KEDA configuration
3. **[Cost Management](../how-to/monitor-costs.md)** - Optimize costs with scaling strategies
4. **[System Architecture](../explanation/system-architecture.md)** - Understand the complete system design

## Summary

You've successfully demonstrated:
- ✅ **Normal Mode**: Standard pod scaling with genetic-data-raw topic
- ✅ **Big Data Mode**: Memory-intensive scaling with genetic-bigdata-raw topic
- ✅ **Node Scale Mode**: Cluster autoscaler with genetic-nodescale-raw topic
- ✅ **Kafka Lag Mode**: KEDA consumer lag-based scaling with genetic-lag-demo-raw topic
- ✅ **End-to-End Flow**: WebSocket → Kafka → VEP → Results
- ✅ **Cost Attribution**: Genomics research cost center tracking
- ✅ **Multi-Topic KEDA**: Different lag thresholds for different workloads
- ✅ **Individual Trigger Buttons**: Mode-specific demonstration controls

The healthcare ML system's multi-tier scaling architecture enables cost-effective processing of genetic analysis workloads from small research samples to large-scale genomic datasets.