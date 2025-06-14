# Create Testing API for Scaling Mode Validation

## 🎯 Objective

Create a dedicated REST API to programmatically test and validate the three scaling modes from genetic-client.html, enabling automated end-to-end testing.

## 📋 Background

Currently, genetic-client.html has three critical scaling buttons:
- **📊 Normal Mode (Pod Scaling)** - Triggers VEP pod scaling via KEDA
- **🚀 Big Data Mode (Node Scaling)** - Enables high-volume processing mode  
- **⚡ Trigger Node Scaling Demo** - Sends 5x 1MB sequences for node scaling

**Problem:** Manual browser testing is unreliable for CI/CD validation.
**Solution:** Create REST API endpoints that mirror button functionality.

## 🔧 Technical Requirements

### New REST Endpoints

#### 1. Scaling Mode Control
```
POST /api/scaling/mode
{
  "mode": "normal" | "bigdata",
  "description": "Set scaling mode"
}
```

#### 2. Genetic Sequence Processing
```
POST /api/genetic/analyze
{
  "sequence": "ATGCGTACGTAGCTAGCTA",
  "mode": "normal" | "bigdata",
  "batchSize": 1
}
```

#### 3. Node Scaling Demo Trigger
```
POST /api/scaling/trigger-demo
{
  "demoType": "node-scaling",
  "sequenceCount": 5,
  "sequenceSize": "1mb"
}
```

#### 4. Scaling Status Monitoring
```
GET /api/scaling/status/{trackingId}
```

#### 5. Health Check
```
GET /api/scaling/health
```

## 🧪 Testing Benefits

### Automated Test Suite
```bash
# Test Normal Mode Pod Scaling
curl -X POST $ROUTE_URL/api/scaling/mode -d '{"mode":"normal"}'
curl -X POST $ROUTE_URL/api/genetic/analyze -d '{"sequence":"ATGCGTACGTAGCTAGCTA"}'

# Test Big Data Mode Node Scaling  
curl -X POST $ROUTE_URL/api/scaling/mode -d '{"mode":"bigdata"}'
curl -X POST $ROUTE_URL/api/scaling/trigger-demo -d '{"demoType":"node-scaling"}'
```

### CI/CD Integration
- Automated scaling validation in deployment pipeline
- Consistent, repeatable testing
- Real-time scaling metrics
- Performance regression detection

## 📊 Success Criteria

**API Functionality:**
- [ ] All 5 endpoints working correctly
- [ ] Mode switching matches genetic-client.html behavior
- [ ] Sequence processing triggers correct scaling
- [ ] Real-time monitoring provides scaling status

**Scaling Validation:**
- [ ] Normal Mode: VEP scales 0→1→0 pods
- [ ] Big Data Mode: VEP scales 0→10+ pods  
- [ ] Node Scaling: Cluster scales 2→5+ nodes
- [ ] Cost tracking works throughout scaling

**Testing Automation:**
- [ ] Automated test scripts work reliably
- [ ] CI/CD pipeline validates scaling
- [ ] End-to-end testing takes < 15 minutes
- [ ] Results match manual testing

## 🚀 Implementation Plan

**Phase 1:** Core API Development
- Create ScalingTestController.java
- Implement mode switching logic
- Add sequence processing endpoints

**Phase 2:** Integration
- Connect to existing WebSocket service
- Integrate with Kafka publishing
- Add KEDA scaling monitoring

**Phase 3:** Testing & Validation
- Create automated test scripts
- Validate against genetic-client.html
- Test all three scaling modes

**Phase 4:** CI/CD Integration
- Add API tests to deployment pipeline
- Create scaling validation workflows
- Implement regression testing

## 🔗 Dependencies

**Prerequisites:**
- Issue #6: Fix OpenShift Builds ✅
- Issue #7: Deploy Missing Infrastructure (in progress)

**Benefits:**
- Reliable, automated scaling validation
- CI/CD integration for consistent testing
- Real-time monitoring and debugging
- Perfect for MVP demo automation

This API will make scaling validation reliable and automated while maintaining compatibility with the existing genetic-client.html interface!
