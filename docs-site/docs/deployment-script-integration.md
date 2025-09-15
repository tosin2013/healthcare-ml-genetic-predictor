# Deployment Script Integration Guide

## 🎯 How the Scripts Work Together

### **Main Deployment**: `scripts/deploy-clean-enhanced.sh`
- **Purpose**: Complete end-to-end deployment of all Healthcare ML components
- **Includes**: Operators, Kafka, applications, KEDA scaling, **and compute-intensive nodes**
- **Usage**: Single command deploys everything

### **Standalone Node Scaling**: `scripts/deploy-compute-intensive-machineset.sh`  
- **Purpose**: Deploy only compute-intensive nodes for existing clusters
- **Usage**: For environments where main deployment was run without node scaling

## 🚀 Usage Scenarios

### **Scenario 1: Complete Fresh Deployment (Recommended)**
```bash
# Deploys everything including compute-intensive nodes
./scripts/deploy-clean-enhanced.sh
```

### **Scenario 2: Deployment Without Compute-Intensive Nodes**
```bash
# Skip compute-intensive nodes to save costs
DEPLOY_COMPUTE_INTENSIVE_NODES=false ./scripts/deploy-clean-enhanced.sh
```

### **Scenario 3: Add Node Scaling to Existing Deployment**
```bash
# If main deployment was run without compute-intensive nodes
./scripts/deploy-compute-intensive-machineset.sh
```

### **Scenario 4: Custom Configuration**
```bash
# Override default settings
export DEPLOY_COMPUTE_INTENSIVE_NODES=true
export NAMESPACE="my-custom-namespace"
./scripts/deploy-clean-enhanced.sh
```

## 🔧 Integration Details

### **Phase 8.5: Compute-Intensive Nodes**
The main deployment script now includes **Phase 8.5** that:

1. **Checks permissions** for machine set creation
2. **Auto-detects cluster configuration** (name, region, resource groups)
3. **Runs the standalone script** or deploys template directly
4. **Provides fallback** if standalone script not found
5. **Shows status** of node scaling configuration

### **Automatic Integration Features**
- ✅ **Auto-detection**: Cluster name, region, resource groups
- ✅ **Permission checks**: Graceful degradation if insufficient permissions
- ✅ **Cost optimization**: D4s_v3 instances, scale-to-zero
- ✅ **Multi-environment**: Template substitution for any cluster
- ✅ **Error handling**: Continues deployment if node scaling fails

## 📊 Deployment Flow

```
Phase 1: Operators
Phase 2: Infrastructure (Kafka)
Phase 2.5: Kafka Topics
Phase 3: Node Labels
Phase 4: Applications
Phase 5: Builds
Phase 6: KEDA Scaling
Phase 7: OpenShift AI
Phase 8: Cluster Autoscaler
Phase 8.5: Compute-Intensive Nodes  ← NEW!
Summary & Access Info
```

## 🎛️ Configuration Options

### **Environment Variables**
```bash
# Control compute-intensive node deployment
export DEPLOY_COMPUTE_INTENSIVE_NODES=true   # Default: true
export DEPLOY_COMPUTE_INTENSIVE_NODES=false  # Skip node scaling setup

# Override namespace
export NAMESPACE="my-healthcare-demo"        # Default: healthcare-ml-demo
```

### **Script Parameters**
```bash
# Both scripts support standard OpenShift login
oc login https://api.cluster.example.com:6443
./scripts/deploy-clean-enhanced.sh

# Check prerequisites
oc whoami  # Must be logged in
oc auth can-i create machineset -n openshift-machine-api  # For compute-intensive nodes
```

## 🔍 Monitoring Integration

### **Enhanced Summary Output**
The main script now shows:
```
✅ Compute-Intensive Nodes: 0 available for node scaling
✅ Machine Autoscalers: 4 configured
```

### **Enhanced Monitoring Commands**
```bash
# New monitoring commands included:
oc get nodes -l workload-type=compute-intensive
oc get machines -n openshift-machine-api | grep compute-intensive  
oc get machineautoscaler -n openshift-machine-api
watch oc get pods -l app=vep-service-nodescale
```

## 🚨 Error Handling

### **Permission Issues**
```bash
# If insufficient permissions for machine sets:
[WARNING] Insufficient permissions for machine set creation, skipping compute-intensive nodes...
[INFO] Node scaling demo will use existing nodes only
```

### **Template Issues**
```bash
# If auto-detection fails:
[WARNING] Could not auto-detect cluster configuration for compute-intensive nodes
[WARNING] Compute-intensive machine set template not found
```

### **Graceful Degradation**
- Main deployment **continues** even if compute-intensive nodes fail
- VEP nodescale service will be **pending** until nodes are available
- Can run standalone script later to add node scaling

## 📚 Related Documentation

- [Node Scaling Cost Optimization](node-scaling-cost-optimization.md)
- [VEP Service Architecture](ADR-006-vep-service-architecture-decision.md)
- [Separation of Concerns Guide](../../.github/workflows/SEPARATION_VALIDATION_GUIDE.md)

---

**Ready to deploy?** Run `./scripts/deploy-clean-enhanced.sh` for the complete experience! 🚀
