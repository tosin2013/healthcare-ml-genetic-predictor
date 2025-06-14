# GitHub Issue: Create Testing API for Scaling Mode Validation

**Title:** Create Testing API for Scaling Mode Validation - Normal/Big Data/Node Scaling

**Labels:** api, testing, scaling, automation, enhancement

## 🎯 Objective

Create REST API endpoints to programmatically test the three scaling modes from genetic-client.html for automated end-to-end testing.

## 📋 Background

The genetic-client.html has three scaling buttons that need automated testing:
- **📊 Normal Mode (Pod Scaling)** - KEDA pod scaling via Kafka lag
- **🚀 Big Data Mode (Node Scaling)** - High-volume processing mode  
- **⚡ Trigger Node Scaling Demo** - Sends 5x 1MB sequences for node scaling

**Problem:** Manual browser testing is unreliable for CI/CD validation.
**Solution:** Create REST API endpoints that mirror the button functionality.

## 🔧 Required Endpoints

### 1. Scaling Mode Control
```
POST /api/scaling/mode
Content-Type: application/json

{
  "mode": "normal" | "bigdata",
  "description": "Set scaling mode for subsequent operations"
}

Response:
{
  "status": "success",
  "mode": "normal",
  "message": "📊 Normal Mode activated - pod scaling demonstration"
}
```

### 2. Genetic Sequence Processing
```
POST /api/genetic/analyze
Content-Type: application/json

{
  "sequence": "ATGCGTACGTAGCTAGCTA",
  "mode": "normal" | "bigdata",
  "batchSize": 1
}

Response:
{
  "status": "success",
  "sequencesSubmitted": 1,
  "expectedScaling": "0→1→0 pods"
}
```

### 3. Node Scaling Demo Trigger
```
POST /api/scaling/trigger-demo
Content-Type: application/json

{
  "demoType": "node-scaling",
  "sequenceCount": 5,
  "sequenceSize": "1mb"
}

Response:
{
  "status": "success",
  "sequencesQueued": 5,
  "expectedScaling": "0→10+ pods, 2→5+ nodes"
}
```

### 4. Scaling Status Monitoring
```
GET /api/scaling/status/{trackingId}

Response:
{
  "status": "scaling",
  "currentPods": 8,
  "currentNodes": 4,
  "kafkaLag": 15
}
```

### 5. Health Check
```
GET /api/scaling/health

Response:
{
  "status": "ready",
  "keda": "ready",
  "kafka": "ready",
  "clusterAutoscaler": "ready"
}
```

## 🧪 Testing Benefits

### Automated Test Suite Example
```bash
ROUTE_URL="https://quarkus-websocket-service-healthcare-ml-demo.apps.cluster.local"

# Test Normal Mode Pod Scaling
curl -X POST $ROUTE_URL/api/scaling/mode \
  -H "Content-Type: application/json" \
  -d '{"mode":"normal"}'

curl -X POST $ROUTE_URL/api/genetic/analyze \
  -H "Content-Type: application/json" \
  -d '{"sequence":"ATGCGTACGTAGCTAGCTA","mode":"normal"}'

# Test Big Data Mode Node Scaling  
curl -X POST $ROUTE_URL/api/scaling/mode \
  -H "Content-Type: application/json" \
  -d '{"mode":"bigdata"}'

curl -X POST $ROUTE_URL/api/scaling/trigger-demo \
  -H "Content-Type: application/json" \
  -d '{"demoType":"node-scaling","sequenceCount":5}'
```

### CI/CD Integration
- Automated scaling validation in deployment pipeline
- Consistent, repeatable testing across environments
- Real-time scaling metrics and monitoring
- Performance regression detection

## 📊 Success Criteria

### API Functionality
- [ ] All 5 endpoints working correctly
- [ ] Mode switching matches genetic-client.html behavior
- [ ] Sequence processing triggers correct scaling
- [ ] Real-time monitoring provides scaling status

### Scaling Validation
- [ ] **Normal Mode**: VEP scales 0→1→0 pods
- [ ] **Big Data Mode**: VEP scales 0→10+ pods  
- [ ] **Node Scaling**: Cluster scales 2→5+ nodes
- [ ] Cost tracking works throughout scaling

### Testing Automation
- [ ] Automated test scripts work reliably
- [ ] CI/CD pipeline validates scaling
- [ ] End-to-end testing takes < 15 minutes
- [ ] Results match manual testing

## 🚀 Implementation Plan

### Phase 1: Core API Development
- Create `ScalingTestController.java` in quarkus-websocket-service
- Implement mode switching logic
- Add sequence processing endpoints
- Create tracking and monitoring capabilities

### Phase 2: Integration
- Connect to existing WebSocket service
- Integrate with Kafka message publishing
- Add KEDA scaling monitoring
- Implement cost tracking integration

### Phase 3: Testing & Validation
- Create automated test scripts
- Validate against genetic-client.html behavior
- Test all three scaling modes
- Document API usage and examples

### Phase 4: CI/CD Integration
- Add API tests to deployment pipeline
- Create scaling validation workflows
- Implement automated regression testing

## 🔗 Dependencies

**Prerequisites:**
- ✅ Issue #6: Fix OpenShift Builds and Deploy Services (COMPLETED)
- 🔄 Issue #7: Deploy Missing Infrastructure (IN PROGRESS)

**Related Components:**
- `quarkus-websocket-service` - Add new REST endpoints
- `genetic-client.html` - Reference implementation
- `k8s/base/eventing/` - KEDA scaling configuration
- `scripts/deploy-clean.sh` - Deployment automation

## 🎯 Benefits

### Development Benefits
- **Reliable Testing**: Consistent, repeatable scaling tests
- **CI/CD Integration**: Automated validation in deployment pipeline
- **Debugging**: Clear API responses for troubleshooting
- **Performance Monitoring**: Real-time scaling metrics

### Demo Benefits
- **Automated Demos**: Programmatic demo execution
- **Consistent Results**: Predictable scaling behavior
- **Monitoring Integration**: Real-time scaling visualization

### Operational Benefits
- **Health Checks**: Infrastructure readiness validation
- **Regression Testing**: Automated scaling regression detection
- **Performance Baselines**: Consistent performance measurement

This API will make scaling validation reliable, automated, and perfect for CI/CD integration while maintaining compatibility with the existing genetic-client.html interface!
