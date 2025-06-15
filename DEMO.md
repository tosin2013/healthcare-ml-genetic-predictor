# Healthcare ML Demo: Event-Driven Scaling with KEDA

**Comprehensive demonstration of event-driven autoscaling for healthcare ML workloads on OpenShift**

## 🎯 **Demo Overview**

This demo showcases a production-ready healthcare ML architecture featuring:
- **Event-Driven Scaling**: CloudEvents → Kafka → KEDA → Pod Scaling
- **Genetic Analysis Pipeline**: VEP (Variant Effect Predictor) service processing genetic sequences
- **Cost Attribution**: Scaling behavior enables OpenShift cost management
- **Real-World Workloads**: Genetic analysis with varying computational requirements

## 🏗️ **Architecture**

```
API Endpoints → CloudEvents → Kafka → KEDA → VEP Service Scaling
     ↓              ↓         ↓      ↓         ↓
  REST APIs    Structured   Message  Auto-    Pod/Node
  (5 types)    Events       Queue    Scaler   Scaling
```

### **Components**
- **API Layer**: 5 REST endpoints for genetic analysis and scaling demos
- **Event Streaming**: Kafka cluster with `genetic-data-raw` topic
- **Auto-Scaling**: KEDA v1.23 with Kafka lag-based triggers
- **ML Processing**: VEP service (Deployment) consuming genetic analysis requests
- **Monitoring**: OpenShift metrics, KEDA ScaledObjects, HPA

## 🚀 **Demo Options**

### **Option 1: Automated Testing Script (Recommended)**

**Best for**: Comprehensive validation, automated testing, CI/CD integration

```bash
# Run complete KEDA scaling behavior test
./scripts/test-keda-scaling-behavior.sh
```

**What it tests**:
1. **Health Check** - No scaling (baseline validation)
2. **Small Genetic Analysis** - Minimal scaling (1→2 pods)
3. **Large Genetic Analysis** - Moderate scaling (1→3 pods)
4. **Pod Scaling Demo** - Multiple pods (1→5 pods)
5. **Node Scaling Demo** - Heavy load (1→10+ pods, node scaling)

**Output**: Detailed log file with timestamps, pod counts, Kafka lag, and scaling behavior

### **Option 2: Interactive UI Demo**

**Best for**: Live demonstrations, customer presentations, interactive exploration

**Access**: https://quarkus-websocket-service-healthcare-ml-demo.apps.b9892ub1.eastus.aroapp.io

**UI Features**:
- **Real-time WebSocket**: Live updates of scaling events
- **Interactive Controls**: Trigger different scaling scenarios
- **Visual Monitoring**: Pod counts, Kafka lag, resource utilization
- **Cost Tracking**: Real-time cost attribution based on scaling

## 📋 **Step-by-Step Demo Guide**

### **Prerequisites**

1. **OpenShift Access**: Ensure you have access to the cluster
2. **KEDA Validation**: Verify KEDA controller is running
3. **VEP Service**: Confirm VEP deployment is operational

```bash
# Quick validation
oc get pods -n openshift-keda                    # KEDA controller pods
oc get deployment vep-service -n healthcare-ml-demo  # VEP service
oc get scaledobject vep-service-scaler -n healthcare-ml-demo  # KEDA ScaledObject
```

### **Demo Scenario 1: Basic Genetic Analysis Scaling**

**Objective**: Demonstrate basic event-driven scaling with genetic analysis

#### **Using Script**:
```bash
# Run single test
./scripts/test-keda-scaling-behavior.sh | grep -A 20 "Small Genetic Analysis"
```

#### **Using UI**:
1. Open the demo UI in browser
2. Navigate to "Genetic Analysis" section
3. Enter a small DNA sequence (20-50 base pairs)
4. Click "Analyze Sequence"
5. Watch real-time scaling: 1→2 pods

#### **Using API Directly**:
```bash
# Generate genetic analysis request
curl -X POST "https://quarkus-websocket-service-healthcare-ml-demo.apps.b9892ub1.eastus.aroapp.io/api/genetic/analyze" \
  -H "Content-Type: application/json" \
  -d '{"sequence": "ATCGATCGATCGATCGATCG", "resourceProfile": "standard"}'

# Monitor scaling
watch oc get deployment vep-service -n healthcare-ml-demo
```

**Expected Results**:
- **API Response**: CloudEvent published with tracking ID
- **Kafka**: Message appears in `genetic-data-raw` topic
- **KEDA**: Detects lag > 5 messages, triggers scaling
- **VEP Service**: Scales from 1→2 pods
- **Processing**: VEP consumes message, lag returns to 0

### **Demo Scenario 2: Heavy Workload Scaling**

**Objective**: Demonstrate pod and node scaling under heavy genetic analysis load

#### **Using Script**:
```bash
# Run node scaling test
./scripts/test-keda-scaling-behavior.sh | grep -A 30 "Node Scaling Demo"
```

#### **Using UI**:
1. Navigate to "Scaling Demos" section
2. Select "Node Scaling Demo"
3. Configure: 20 sequences × 100KB each
4. Click "Start Demo"
5. Watch scaling progression: 1→10+ pods, potential node scaling

#### **Using API Directly**:
```bash
# Generate heavy workload
curl -X POST "https://quarkus-websocket-service-healthcare-ml-demo.apps.b9892ub1.eastus.aroapp.io/api/scaling/trigger-demo" \
  -H "Content-Type: application/json" \
  -d '{"demoType": "node-scaling", "sequenceCount": 20, "sequenceSize": "100kb"}'

# Monitor scaling
watch oc get deployment vep-service -n healthcare-ml-demo
watch oc get nodes
```

**Expected Results**:
- **Kafka Lag**: Builds up to 20+ messages
- **KEDA Scaling**: Aggressive scaling to handle lag
- **Pod Scaling**: 1→10+ VEP pods
- **Node Scaling**: Potential new node provisioning (if resource pressure)
- **Cost Impact**: Visible increase in resource consumption

### **Demo Scenario 3: Cost Attribution**

**Objective**: Demonstrate how scaling behavior enables cost management

#### **Monitoring Commands**:
```bash
# Monitor resource consumption
oc top pods -n healthcare-ml-demo
oc top nodes

# Check HPA scaling metrics
oc get hpa keda-hpa-vep-service-scaler -n healthcare-ml-demo

# View KEDA ScaledObject status
oc describe scaledobject vep-service-scaler -n healthcare-ml-demo
```

#### **Cost Calculation**:
- **Baseline Cost**: 1 pod × (100m CPU + 256Mi memory)
- **Scaled Cost**: N pods × resource consumption
- **Node Cost**: Additional nodes × hourly rate
- **Attribution**: Costs directly tied to genetic analysis workload

## 🔍 **Monitoring and Validation**

### **Real-Time Monitoring**

```bash
# Watch VEP service scaling
watch oc get deployment vep-service -n healthcare-ml-demo

# Monitor Kafka consumer lag
watch 'oc exec genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- /opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group vep-service-group'

# Check KEDA ScaledObject status
watch oc get scaledobject vep-service-scaler -n healthcare-ml-demo
```

### **Validation Checklist**

- [ ] **API Endpoints**: All 5 endpoints responding (200 OK)
- [ ] **CloudEvents**: Messages published to Kafka topic
- [ ] **KEDA Controller**: All 4 pods running in `openshift-keda`
- [ ] **ScaledObject**: READY=True, ACTIVE=True when scaling
- [ ] **VEP Service**: Scaling 1→N based on Kafka lag
- [ ] **Consumer Group**: `vep-service-group` active and consuming
- [ ] **HPA**: Created and managing deployment scaling

## 🎯 **Demo Success Criteria**

### **Functional Requirements**
- ✅ **Event-Driven Flow**: API → CloudEvents → Kafka → KEDA → Scaling
- ✅ **Scaling Accuracy**: Appropriate pod counts for workload size
- ✅ **Message Processing**: 100% success rate, no lost messages
- ✅ **Response Times**: API responses < 500ms, scaling < 60s

### **Performance Benchmarks**
- **Small Analysis**: 1→2 pods, ~30s scaling time
- **Large Analysis**: 1→3 pods, ~45s scaling time  
- **Pod Demo**: 1→5 pods, ~60s scaling time
- **Node Demo**: 1→10+ pods, ~90s scaling time

### **Cost Attribution**
- **Resource Tracking**: CPU/memory consumption per pod
- **Scaling Correlation**: Costs directly tied to workload
- **Node Utilization**: Efficient resource allocation

## 🛠️ **Troubleshooting**

### **Common Issues**

#### **KEDA ScaledObject Not Ready**
```bash
# Check ScaledObject status
oc describe scaledobject vep-service-scaler -n healthcare-ml-demo

# Verify KEDA controller
oc get pods -n openshift-keda
```

#### **VEP Service Not Scaling**
```bash
# Check deployment status
oc get deployment vep-service -n healthcare-ml-demo

# Verify Kafka connectivity
oc exec vep-service-xxx -- nc -zv genetic-data-cluster-kafka-bootstrap 9092
```

#### **No Kafka Messages**
```bash
# Check API endpoint
curl -I https://quarkus-websocket-service-healthcare-ml-demo.apps.b9892ub1.eastus.aroapp.io/api/scaling/health

# Verify Kafka topic
oc exec genetic-data-cluster-kafka-0 -- /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list
```

## 📊 **Demo Results Documentation**

After running the demo, document results in this format:

### **Test Results Summary**
- **Date**: [Date]
- **Duration**: [Total demo time]
- **Scenarios Tested**: [List of scenarios]
- **Success Rate**: [Percentage]

### **Scaling Behavior**
- **Baseline**: 1 VEP pod
- **Peak Scaling**: [Max pods reached]
- **Node Scaling**: [Yes/No, details]
- **Response Times**: [Average scaling time]

### **Cost Impact**
- **Baseline Cost**: [Resource consumption]
- **Peak Cost**: [Maximum resource consumption]
- **Cost Attribution**: [Workload correlation]

## 🔗 **Related Documentation**

- [ADR-004: API Testing and Validation](docs/adr/ADR-004-api-testing-validation-openshift.md)
- [ADR-005: KEDA Troubleshooting](docs/adr/ADR-005-keda-troubleshooting-configuration.md)
- [ADR-006: VEP Service Architecture](docs/adr/ADR-006-vep-service-architecture-decision.md)
- [KEDA Scaling Validation Report](KEDA_SCALING_VALIDATION_REPORT.md)

---

**Demo Status**: ✅ **Production Ready**  
**Last Updated**: June 15, 2025  
**Architecture**: Event-Driven Scaling with KEDA v1.23 + VEP Deployment
