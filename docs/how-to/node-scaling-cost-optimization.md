# Node Scaling Cost Optimization Guide

## 🎯 Overview

This guide explains the cost-optimized approach for the Healthcare ML Genetic Predictor node scaling demo.

## 💰 Cost Optimizations Made

### **1. Reduced Instance Size**
- **Before**: `Standard_D16s_v3` (16 vCPU, 64GB RAM) - ~$460/month
- **After**: `Standard_D4s_v3` (4 vCPU, 16GB RAM) - ~$115/month
- **Savings**: 75% cost reduction per node

### **2. Reduced Resource Requests**
- **Before**: 16Gi memory, 7000m CPU per pod
- **After**: 6Gi memory, 2000m CPU per pod
- **Benefit**: More pods can fit per node, reducing total nodes needed

### **3. Lower Max Replicas**
- **Before**: 3 compute-intensive nodes max
- **After**: 2 compute-intensive nodes max
- **Savings**: 33% reduction in maximum infrastructure cost

### **4. Scale-to-Zero Configuration**
- **Min Replicas**: 0 (nodes deleted when not needed)
- **Benefit**: No idle costs when demo not running

## 🌍 Multi-Environment Support

### **Template Variables**
The `compute-intensive-machineset.yaml` uses templates that work across environments:

```yaml
# Auto-detected values:
{{CLUSTER_NAME}}           # From: oc get infrastructure cluster
{{REGION}}                 # From: cluster infrastructure or node labels  
{{RESOURCE_GROUP}}         # From: existing machine sets
{{NETWORK_RESOURCE_GROUP}} # From: existing machine sets
{{VNET_NAME}}             # From: existing machine sets
```

### **Cloud Provider Flexibility**
- **Azure**: Uses `AzureMachineProviderSpec` (current)
- **AWS**: Change to `AWSMachineProviderSpec`  
- **GCP**: Change to `GCPMachineProviderSpec`

### **Instance Type Options by Cost**

#### **Azure (cheapest to most expensive)**
```yaml
# Ultra-low cost (demo only)
vmSize: Standard_D2s_v3   # 2 vCPU, 8GB RAM  - ~$58/month

# Cost-optimized (recommended)
vmSize: Standard_D4s_v3   # 4 vCPU, 16GB RAM - ~$115/month

# Balanced performance
vmSize: Standard_D8s_v3   # 8 vCPU, 32GB RAM - ~$230/month

# High performance
vmSize: Standard_D16s_v3  # 16 vCPU, 64GB RAM - ~$460/month
```

#### **AWS Equivalents**
```yaml
# Cost-optimized
instanceType: m5.large    # 2 vCPU, 8GB RAM
instanceType: m5.xlarge   # 4 vCPU, 16GB RAM

# Balanced
instanceType: m5.2xlarge  # 8 vCPU, 32GB RAM
```

## 🚀 Deployment Instructions

### **Automatic Deployment (Recommended)**
```bash
# Auto-detects cluster configuration and deploys
./scripts/deploy-compute-intensive-machineset.sh
```

### **Manual Deployment**
```bash
# 1. Get cluster information
CLUSTER_NAME=$(oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}')
REGION=$(oc get infrastructure cluster -o jsonpath='{.status.platformStatus.azure.region}')

# 2. Replace template variables
sed "s/{{CLUSTER_NAME}}/$CLUSTER_NAME/g" k8s/base/autoscaler/compute-intensive-machineset.yaml | \
sed "s/{{REGION}}/$REGION/g" | \
oc apply -f -
```

## 📊 Cost Monitoring

### **Check Current Nodes**
```bash
# List all compute-intensive nodes
oc get nodes -l workload-type=compute-intensive

# Check machine status
oc get machines -n openshift-machine-api | grep compute-intensive
```

### **Monitor Costs**
```bash
# Check if nodes are scaling down when idle
oc get machineautoscaler -n openshift-machine-api

# Verify scale-to-zero is working
watch oc get machines -n openshift-machine-api
```

## 🎭 Demo Scenarios

### **Scenario 1: Light Demo (1 pod)**
- **Resources**: 6Gi memory, 2000m CPU
- **Nodes Triggered**: 1 × D4s_v3 node
- **Cost**: ~$115/month (pro-rated for demo duration)

### **Scenario 2: Heavy Demo (multiple pods)**  
- **Resources**: 12Gi memory, 4000m CPU total
- **Nodes Triggered**: 2 × D4s_v3 nodes  
- **Cost**: ~$230/month (pro-rated for demo duration)

### **Scenario 3: Ultra-Light Demo**
Update to `Standard_D2s_v3` for absolute minimum cost:
- **Cost**: ~$58/month per node
- **Trade-off**: Lower performance, longer processing times

## 🛡️ Safety Measures

### **Cost Controls**
- **Max Replicas**: Hard limit on total nodes
- **Scale-to-Zero**: Automatic cost reduction when idle
- **Resource Limits**: Prevent runaway resource consumption

### **Monitoring Alerts**
```bash
# Set up cost monitoring
oc get events --field-selector reason=SuccessfulCreate -n openshift-machine-api

# Watch for unexpected scaling
oc get pods -l app=vep-service-nodescale -w
```

## 🔧 Customization

### **For Different Budgets**

#### **Ultra-Low Budget** (~$50-100/month)
```yaml
vmSize: Standard_D2s_v3
maxReplicas: 1
resources:
  requests:
    memory: "3Gi"
    cpu: "1000m"
```

#### **Standard Budget** (~$100-200/month)  
```yaml
vmSize: Standard_D4s_v3  # Current configuration
maxReplicas: 2
```

#### **High Performance** (~$200-500/month)
```yaml
vmSize: Standard_D8s_v3
maxReplicas: 3
resources:
  requests:
    memory: "12Gi" 
    cpu: "4000m"
```

## 📚 Related Documentation

- [Cluster Autoscaler Configuration](../docs/reference/cluster-autoscaler.md)
- [Machine Sets and Autoscalers](../docs/how-to/configure-machine-autoscaler.md)
- [VEP Service Node Scale Mode](../docs/tutorials/04-scaling-demo.md)
- [Cost Management](../docs/how-to/cost-optimization.md)

---

**Ready to deploy?** Run `./scripts/deploy-compute-intensive-machineset.sh` to get started! 🚀
