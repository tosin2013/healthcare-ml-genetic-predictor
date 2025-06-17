# Healthcare ML Multi-Environment Deployment Strategy

## 🎯 Environment-Agnostic Architecture

This directory contains **Kustomize overlays** for deploying the healthcare ML genetic predictor across different environments with consistent node affinity and cost management.

## 📁 Directory Structure

```
k8s/
├── base/                           # Base configurations (environment-agnostic)
│   ├── vep-service/
│   ├── keda/
│   ├── autoscaler/
│   └── node-management/
├── overlays/
│   ├── environments/
│   │   ├── dev/                    # Development environment
│   │   ├── staging/                # Staging environment  
│   │   ├── production/             # Production environment
│   │   └── demo/                   # Demo/POC environment
│   └── cloud-providers/
│       ├── azure-aro/              # Azure Red Hat OpenShift
│       ├── aws-rosa/               # AWS Red Hat OpenShift Service
│       ├── gcp-osd/                # Google Cloud OpenShift Dedicated
│       └── on-premise/             # On-premise OpenShift
```

## 🔧 Environment Configuration Pattern

### Base Configuration (Cloud/Environment Agnostic)
- **VEP Services**: Resource requests/limits as percentages
- **KEDA Scalers**: Topic-based scaling rules
- **Node Affinity**: Label-based workload placement
- **Cost Management**: Template labels for attribution

### Environment Overlays
Each environment customizes:
- **Node pool sizes** (dev: 1-2 nodes, prod: 1-10 nodes)
- **Resource limits** (dev: 2GB RAM, prod: 8GB RAM)
- **Scaling thresholds** (dev: higher lag tolerance, prod: aggressive)
- **Cost center labels** (dev: development, prod: genomics-research)

### Cloud Provider Overlays
Each cloud provider customizes:
- **Machine types** (Azure: Standard_D4s_v3, AWS: m5.xlarge)
- **Storage classes** (Azure: managed-premium, AWS: gp3)
- **Network policies** (cloud-specific security groups)
- **Cost management integration** (Azure Cost Management, AWS Cost Explorer)

## 🚀 Deployment Commands

### Development Environment on Azure ARO
```bash
# Deploy base + dev + azure overlays
kustomize build k8s/overlays/environments/dev | oc apply -f -

# Or using oc kustomize
oc apply -k k8s/overlays/environments/dev
```

### Production Environment on AWS ROSA
```bash
# Deploy base + production + aws overlays  
oc apply -k k8s/overlays/environments/production
```

### Demo Environment (Any Cloud)
```bash
# Deploy base + demo overlay (minimal resources)
oc apply -k k8s/overlays/environments/demo
```

## 📊 Environment Specifications

| Environment | Node Pool Size | VEP Resources | KEDA Threshold | Cost Center |
|-------------|----------------|---------------|----------------|-------------|
| **dev**     | 1-2 nodes      | 1GB RAM       | lag > 10       | development |
| **staging** | 1-4 nodes      | 4GB RAM       | lag > 5        | testing     |
| **demo**    | 1-3 nodes      | 2GB RAM       | lag > 3        | demo        |
| **prod**    | 1-10 nodes     | 8GB RAM       | lag > 1        | genomics-research |

## 🏷️ Consistent Labeling Strategy

### Node Labels (Applied via MachineSet templates)
```yaml
# Standard across all environments
workload-type: compute-intensive
cost-center: ${ENVIRONMENT}-${PROJECT}
billing-model: chargeback
resource-profile: high-memory
environment: ${ENV_NAME}
```

### Pod Labels (Applied via deployments)
```yaml
# Consistent workload identification
workload.healthcare-ml/type: genetic-analysis
workload.healthcare-ml/mode: nodescale
workload.healthcare-ml/service: vep-annotation
app.kubernetes.io/part-of: healthcare-ml-genetic-predictor
```

## 🔄 Automation Scripts

### Environment Setup Script
```bash
#!/bin/bash
# scripts/deploy-environment.sh
ENVIRONMENT=${1:-demo}
CLOUD_PROVIDER=${2:-azure-aro}

echo "Deploying healthcare ML to $ENVIRONMENT on $CLOUD_PROVIDER"
oc apply -k k8s/overlays/environments/$ENVIRONMENT
```

### Cost Management Setup
```bash
#!/bin/bash  
# scripts/setup-cost-management.sh
ENVIRONMENT=${1:-demo}
COST_CENTER=${2:-genomics-research}

# Apply cost management labels and policies
# Configure billing integration
# Set up cost dashboards
```

## 📋 Environment Checklist

### Pre-Deployment Requirements
- [ ] OpenShift cluster with cluster-admin access
- [ ] KEDA operator installed
- [ ] Cluster autoscaler configured
- [ ] Cost management operator (if using Red Hat Insights)
- [ ] Kafka operator installed

### Post-Deployment Validation
- [ ] Node pools created with correct labels
- [ ] VEP services scheduled on appropriate nodes
- [ ] KEDA scalers active and monitoring
- [ ] Cost attribution labels applied
- [ ] Autoscaler responding to resource pressure

## 🔗 Integration Points

### CI/CD Pipeline Integration
```yaml
# .github/workflows/deploy.yml
- name: Deploy to Environment
  run: |
    oc apply -k k8s/overlays/environments/${{ matrix.environment }}
    scripts/validate-deployment.sh ${{ matrix.environment }}
```

### GitOps Integration (ArgoCD)
```yaml
# argocd/healthcare-ml-app.yaml
spec:
  source:
    path: k8s/overlays/environments/production
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: healthcare-ml-demo
```

This approach ensures **consistent, repeatable deployments** across any OpenShift environment while maintaining environment-specific customizations.
