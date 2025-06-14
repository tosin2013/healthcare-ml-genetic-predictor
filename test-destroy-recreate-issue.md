# Issue: Validate Complete Destroy/Recreate Cycle Against ADRs and MVP Plan

## 🎯 **Objective**

Validate the complete destroy and recreate cycle of the Healthcare ML application on OpenShift to ensure our deployment process aligns with ADR decisions and MVP project plan requirements.

## 📋 **Background**

Following the successful completion of Issue #6 (Fix OpenShift Builds and Deploy Services), we now have:
- ✅ Working Kustomize-based deployment process
- ✅ Definitive DEPLOYMENT.md guide  
- ✅ Automated deploy-clean.sh script
- ✅ All core services running successfully

However, we need to validate that our deployment process:
1. **Completely destroys** all resources cleanly
2. **Recreates from scratch** reliably 
3. **Aligns with ADR decisions** (especially ADR-001)
4. **Meets MVP project plan** requirements

## 🔍 **Test Scenarios**

### **Scenario 1: Complete Clean Slate**
```bash
# 1. Destroy everything
oc delete project healthcare-ml-demo
# Wait for complete deletion

# 2. Recreate from scratch  
./scripts/deploy-clean.sh

# 3. Validate MVP readiness
# Test genetic sequence submission
# Verify scaling infrastructure ready
```

### **Scenario 2: ADR-001 Compliance Validation**

**WebSocket Service (Deployment Strategy):**
- [ ] Deploys as Kubernetes Deployment (not Knative)
- [ ] Maintains persistent connections
- [ ] Always-on behavior (no scale-to-zero)
- [ ] Proper resource allocation

**VEP Service (Knative Strategy):**
- [ ] Deploys as Knative Service
- [ ] Scale-to-zero capability working
- [ ] Event-driven scaling behavior
- [ ] Proper autoscaling configuration

### **Scenario 3: MVP Project Plan Alignment**

**Core Demo Features Readiness:**
- [ ] **🚀 Azure Machine Scaling Demo**
  - KEDA operator installed and configured
  - Kafka topics created for scaling triggers
  - Pod scaling configuration ready
  - Cluster Autoscaler prerequisites met

- [ ] **💰 Cost Tracking & Attribution**
  - Cost labels properly applied: `genomics-research`
  - Project labels: `risk-predictor-v1`
  - Red Hat Insights integration ready

**Infrastructure Requirements:**
- [ ] Azure Red Hat OpenShift cluster ✅
- [ ] KEDA operator installed ✅  
- [ ] Kafka cluster (3 replicas) ✅
- [ ] OpenShift Cost Management Operator (validate)

## 📊 **Success Criteria**

### **Deployment Reliability:**
- [ ] ✅ Complete destruction takes < 5 minutes
- [ ] ✅ Clean recreation completes in 15-20 minutes  
- [ ] ✅ 100% success rate across 3 test runs
- [ ] ✅ No manual intervention required

### **ADR Compliance:**
- [ ] ✅ WebSocket service: Deployment strategy (persistent)
- [ ] ✅ VEP service: Knative strategy (scale-to-zero)
- [ ] ✅ All cost management labels applied
- [ ] ✅ Security contexts OpenShift-compliant

### **MVP Readiness:**
- [ ] ✅ Genetic client UI accessible
- [ ] ✅ WebSocket connections successful
- [ ] ✅ Kafka message processing working
- [ ] ✅ KEDA scaling infrastructure ready
- [ ] ✅ Cost tracking infrastructure ready

## 🎯 **Deliverables**

1. **Validation Report**: Complete test results with timings
2. **Updated Documentation**: Any corrections to DEPLOYMENT.md
3. **Script Improvements**: Enhanced deploy-clean.sh if needed
4. **ADR Compliance Matrix**: Verification of all ADR requirements
5. **MVP Readiness Checklist**: Status of all MVP prerequisites
