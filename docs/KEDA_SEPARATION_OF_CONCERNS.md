# KEDA Separation of Concerns - Healthcare ML Genetic Predictor

## Overview

This document defines the **strict separation of concerns** for KEDA ScaledObjects in the Healthcare ML Genetic Predictor system. This separation is **critical for workflow integrity** and must be maintained to ensure proper scaling behavior across all 4 scaling modes.

## 🎯 Core Principle

**Each scaling mode MUST have its own dedicated:**
- Kafka topic
- VEP service deployment  
- KEDA ScaledObject
- Consumer group

**Violation of this separation will break the scaling workflow and cost attribution.**

## 📊 Required Mappings

| Mode | Kafka Topic | VEP Deployment | KEDA ScaledObject | Consumer Group | Max Replicas |
|------|-------------|----------------|-------------------|----------------|--------------|
| **Normal** | `genetic-data-raw` | `vep-service-normal` | `vep-service-normal-scaler` | `vep-service-group` | 10 |
| **Big Data** | `genetic-bigdata-raw` | `vep-service-bigdata` | `vep-service-bigdata-scaler` | `vep-bigdata-service-group` | 15 |
| **Node Scale** | `genetic-nodescale-raw` | `vep-service-nodescale` | `vep-service-nodescale-scaler` | `vep-nodescale-service-group` | 5 |
| **Kafka Lag** | `genetic-lag-demo-raw` | `vep-service-kafka-lag` | `kafka-lag-scaler` | `vep-kafka-lag-service-group` | 8 |

## 🚫 Critical Rules - DO NOT VIOLATE

### Rule 1: Topic-to-Deployment Mapping
```yaml
# ✅ CORRECT - Each mode has dedicated deployment
normal mode → genetic-data-raw → vep-service-normal
bigdata mode → genetic-bigdata-raw → vep-service-bigdata
nodescale mode → genetic-nodescale-raw → vep-service-nodescale
kafka-lag mode → genetic-lag-demo-raw → vep-service-kafka-lag

# ❌ WRONG - Multiple modes sharing deployments
normal mode → genetic-data-raw → vep-service  # Breaks separation!
bigdata mode → genetic-bigdata-raw → vep-service  # Breaks separation!
```

### Rule 2: ScaledObject Naming Convention
```yaml
# ✅ CORRECT - Descriptive names matching mode
vep-service-normal-scaler    # For normal mode
vep-service-bigdata-scaler   # For big data mode  
vep-service-nodescale-scaler # For node scale mode
kafka-lag-scaler             # For kafka lag mode

# ❌ WRONG - Generic or conflicting names
vep-service-scaler           # Too generic, conflicts with separation
scaler-1, scaler-2           # Non-descriptive, breaks traceability
```

### Rule 3: Consumer Group Isolation
```yaml
# ✅ CORRECT - Unique consumer groups per mode
normal: vep-service-group
bigdata: vep-bigdata-service-group
nodescale: vep-nodescale-service-group
kafka-lag: vep-kafka-lag-service-group

# ❌ WRONG - Shared consumer groups
all modes: vep-service-group  # Breaks message isolation!
```

### Rule 4: Max Replicas Limits
```yaml
# ✅ CORRECT - Mode-specific limits for cost control
normal: maxReplicaCount: 10      # Standard workload
bigdata: maxReplicaCount: 15     # Higher for big data processing
nodescale: maxReplicaCount: 5    # Limited to force cluster autoscaler
kafka-lag: maxReplicaCount: 8    # Moderate for lag demonstration

# ❌ WRONG - Unlimited or inappropriate limits
nodescale: maxReplicaCount: 100  # Defeats node scaling purpose!
normal: maxReplicaCount: 1       # Too restrictive for normal workload
```

## 🔧 Implementation Guidelines

### When Creating New ScaledObjects

1. **Check existing mappings** - Ensure no conflicts with the table above
2. **Use descriptive names** - Follow the naming convention
3. **Set appropriate limits** - Use mode-specific max replicas
4. **Add required labels** - Include separation tracking labels
5. **Document the purpose** - Add comments explaining the separation

### Required Labels for All ScaledObjects

```yaml
metadata:
  labels:
    scaling-mode: "normal|bigdata|nodescale|kafka-lag"
    app.kubernetes.io/component: "keda-scaler"
    app.kubernetes.io/part-of: "healthcare-ml-genetic-predictor"
    separation-of-concerns: "enforced"
  annotations:
    description: "Purpose and separation rationale"
    separation-mode: "Mode this scaler handles"
```

### Lag Threshold Recommendations

```yaml
# Optimized for each mode's characteristics
normal: lagThreshold: "2"      # Standard responsiveness
bigdata: lagThreshold: "2"     # Same as normal, but higher max replicas
nodescale: lagThreshold: "1"   # Immediate response for demo
kafka-lag: lagThreshold: "3"   # Higher to demonstrate lag accumulation
```

## 🚨 Common Violations to Avoid

### 1. Legacy ScaledObject Conflicts
```yaml
# ❌ PROBLEM: Old generic scaler conflicts with separation
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: vep-service-scaler  # Generic name!
spec:
  scaleTargetRef:
    name: vep-service       # Generic deployment!
  triggers:
  - type: kafka
    metadata:
      topic: genetic-data-raw  # Should target vep-service-normal!
```

### 2. Incorrect Topic Routing
```yaml
# ❌ PROBLEM: Wrong topic for deployment
spec:
  scaleTargetRef:
    name: vep-service-bigdata
  triggers:
  - type: kafka
    metadata:
      topic: genetic-data-raw  # Should be genetic-bigdata-raw!
```

### 3. Shared Consumer Groups
```yaml
# ❌ PROBLEM: Multiple scalers using same consumer group
# ScaledObject 1:
metadata:
  name: vep-service-normal-scaler
spec:
  triggers:
  - type: kafka
    metadata:
      consumerGroup: vep-service-group

# ScaledObject 2:
metadata:
  name: vep-service-bigdata-scaler  
spec:
  triggers:
  - type: kafka
    metadata:
      consumerGroup: vep-service-group  # CONFLICT!
```

## 🔍 Validation Checklist

Before deploying any KEDA ScaledObject, verify:

- [ ] Topic-deployment mapping matches the required table
- [ ] ScaledObject name follows naming convention
- [ ] Consumer group is unique for this mode
- [ ] Max replicas appropriate for the mode
- [ ] Required labels are present
- [ ] No conflicts with existing ScaledObjects
- [ ] Comments explain the separation rationale

## 🎯 Why This Matters

### Cost Attribution
Each mode has different cost characteristics:
- **Normal**: Standard compute costs
- **Big Data**: Higher memory/CPU usage
- **Node Scale**: Triggers cluster autoscaler (node costs)
- **Kafka Lag**: Demonstrates lag-based scaling patterns

### Workflow Integrity
The separation ensures:
- **Predictable scaling behavior** per mode
- **Independent testing** of each scaling pattern
- **Clear troubleshooting** when issues occur
- **Accurate performance metrics** per mode

### Compliance and Auditing
Proper separation enables:
- **Cost center attribution** per scaling mode
- **Resource usage tracking** by mode
- **Compliance reporting** for healthcare workloads
- **Performance benchmarking** across modes

## 📚 Related Documentation

- [Separation Validation Guide](.github/workflows/SEPARATION_VALIDATION_GUIDE.md)
- [GitHub Actions Validation](.github/workflows/separation-of-concerns-validation.yml)
- [KEDA Configuration Files](k8s/base/vep-service/)
- [Architecture Decision Records](docs/adr/)

---

**⚠️ CRITICAL**: Any changes to KEDA ScaledObjects must maintain this separation. Violations will break the workflow integrity and cost attribution system.
