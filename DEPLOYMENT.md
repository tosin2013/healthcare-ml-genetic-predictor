# Healthcare ML Genetic Predictor - Clean Deployment Guide

## 🎯 **Complete Clean Deployment from Scratch**

This guide provides the **definitive deployment process** for deploying the Healthcare ML application on a clean Azure Red Hat OpenShift cluster using Kustomize.

## 📋 **Prerequisites**

- Azure Red Hat OpenShift cluster (4.12+)
- OpenShift CLI (`oc`) installed and logged in as cluster-admin
- Git repository cloned locally
- Internet connectivity for operator installations

## 🚀 **Deployment Process**

### **Phase 1: Operators (5-10 minutes)**

Deploy required operators via OpenShift Operator Lifecycle Manager:

```bash
# Deploy all operators at once
oc apply -k k8s/base/operators

# Verify operators are installed (wait 2-3 minutes)
oc get csv -n openshift-operators | grep -E "(amq-streams|serverless|keda)"
```

**Expected Output:**
```
amq-streams.v2.5.0-5                    Red Hat Integration - AMQ Streams       Succeeded
serverless-operator.v1.31.0             Red Hat OpenShift Serverless            Succeeded  
keda.v2.12.0-202311281405               Custom Metrics Autoscaler               Succeeded
```

### **Phase 2: Infrastructure (3-5 minutes)**

Deploy core infrastructure components:

```bash
# Deploy namespace and Kafka cluster
oc apply -k k8s/base/infrastructure

# Wait for Kafka cluster to be ready (2-3 minutes)
oc get kafka genetic-data-cluster -n healthcare-ml-demo
# Wait until READY column shows "True"
```

### **Phase 3: Applications (2-3 minutes)**

Deploy application services:

```bash
# Deploy WebSocket service
oc apply -k k8s/base/applications/quarkus-websocket -n healthcare-ml-demo

# Deploy VEP service  
oc apply -k k8s/base/applications/vep-service -n healthcare-ml-demo

# Grant image pull permissions for VEP service
oc policy add-role-to-user system:image-puller system:serviceaccount:healthcare-ml-demo:vep-service -n healthcare-ml-demo
```

### **Phase 4: Build and Deploy (5-10 minutes)**

Trigger builds and verify deployment:

```bash
# Start builds for both services
oc start-build quarkus-websocket-service -n healthcare-ml-demo
oc start-build vep-service -n healthcare-ml-demo

# Monitor build progress
oc get builds -n healthcare-ml-demo -w

# Verify pods are running
oc get pods -n healthcare-ml-demo | grep -E "(websocket|vep)" | grep -v build
```

## 🔍 **Verification**

### **Check Service Status:**
```bash
# WebSocket service (should show 2/2 Running)
oc get deployment quarkus-websocket-service -n healthcare-ml-demo

# VEP service (should show Ready=True)
oc get ksvc vep-service -n healthcare-ml-demo

# Kafka cluster (should show Ready=True)
oc get kafka genetic-data-cluster -n healthcare-ml-demo
```

### **Access Application:**
```bash
# Get WebSocket service URL
oc get route quarkus-websocket-service -n healthcare-ml-demo

# Access the genetic client at:
# https://<route-url>/genetic-client.html
```

## 🛠️ **Troubleshooting**

### **Common Issues:**

1. **Pod Security Context Errors:**
   - **Symptom:** `runAsUser: Invalid value: 185: must be in the ranges`
   - **Solution:** Remove hardcoded `runAsUser` from deployment specs

2. **Image Pull Errors for VEP Service:**
   - **Symptom:** `401 Unauthorized` when pulling VEP service image
   - **Solution:** Ensure service account has image-puller role (included in Phase 3)

3. **Kafka Not Ready:**
   - **Symptom:** Applications fail to connect to Kafka
   - **Solution:** Wait for Kafka cluster to show `READY=True` before deploying apps

## 📊 **Expected Timeline**

- **Total Deployment Time:** 15-20 minutes
- **Phase 1 (Operators):** 5-10 minutes
- **Phase 2 (Infrastructure):** 3-5 minutes  
- **Phase 3 (Applications):** 2-3 minutes
- **Phase 4 (Build/Deploy):** 5-10 minutes

## 🎯 **Success Criteria**

✅ All operators showing `Succeeded` status  
✅ Kafka cluster showing `READY=True`  
✅ WebSocket service pods `2/2 Running`  
✅ VEP service showing `READY=True`  
✅ Genetic client UI accessible via route  
✅ WebSocket connection successful in browser console

## 🔄 **Clean Restart Process**

To completely restart on a clean cluster:

```bash
# Delete the project (if it exists)
oc delete project healthcare-ml-demo

# Wait for project deletion to complete
oc get projects | grep healthcare-ml-demo
# Should return no results

# Follow deployment process from Phase 1
```

---

**Note:** This guide reflects the **tested and validated** deployment process based on successful container builds and OpenShift deployment experience.
