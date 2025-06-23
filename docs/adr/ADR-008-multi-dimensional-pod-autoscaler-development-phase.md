# ADR-008: Multi-dimensional Pod Autoscaler (AEP-5342) - Development Phase

**Date**: 2025-06-23  
**Status**: Accepted  
**Context**: Healthcare ML Genetic Predictor - Kafka Lag Mode Implementation  

## Context

The healthcare ML system implements 4 distinct scaling modes:
1. **Normal Mode** → Standard resource-based scaling
2. **Big Data Mode** → Memory-intensive scaling  
3. **Node Scale Mode** → Cluster autoscaler demonstration
4. **Kafka Lag Mode** → Event-driven scaling based on message queue depth

Currently, **Kafka Lag Mode experiences HPA selector conflicts** that prevent proper multi-pod scaling demonstrations.

## Problem

### Current HPA Conflict Issue:
```yaml
# Overlapping selectors cause conflicts
vep-service-multi-hpa:     app=vep-service (matches all VEP pods)
kafka-lag-demo-hpa:        app=vep-service,mode=kafka-lag

# Result: AmbiguousSelector warnings → Scaling disabled → Max 1 pod
# Expected: 15 consumer lag → 2+ pods (15 ÷ 10 = 2 pods)
# Actual: 15 consumer lag → 1 pod (due to HPA conflicts)
```

### Impact on Demonstrations:
- **Reduced scaling demonstration value**
- **Inability to show true Kafka lag-based scaling**
- **Confusion between different scaling paradigms**

## Decision

**Implement Multi-dimensional Pod Autoscaler (AEP-5342) as a future development phase** for Kafka Lag Mode coordination.

### Implementation Strategy:

#### **Phase 1: Feature Flag Implementation (Current)**
```yaml
# Environment Variables
KAFKA_LAG_MODE_ENABLED=true                    # Enable/disable button
MULTI_DIMENSIONAL_AUTOSCALER_ENABLED=false     # Development phase flag
```

#### **Phase 2: Multi-dimensional Pod Autoscaler Integration (Future)**
- **Technology**: AEP-5342 (Enhancement Proposal 5342)
- **Red Hat Involvement**: ✅ Active contributor with fork and roadmap
- **Purpose**: Coordinate multiple autoscaling dimensions in one autoscaler
- **Benefit**: Resolve HPA conflicts by managing multiple metrics

#### **Phase 3: Production Deployment (When Ready)**
- **Timeline**: Dependent on Red Hat production support
- **Monitoring**: Track AEP-5342 development progress
- **Evaluation**: Assess when suitable for healthcare ML production use

## Rationale

### **Why Multi-dimensional Pod Autoscaler?**

1. **Red Hat Support**: Red Hat is an active contributor to AEP-5342
2. **Purpose-Built**: Specifically designed to coordinate multiple autoscaling dimensions
3. **Conflict Resolution**: Addresses the exact HPA selector conflict issue
4. **Future-Proof**: Aligns with Red Hat OpenShift 2025 roadmap

### **Why Feature Flag Approach?**

1. **Immediate Value**: Kafka Lag Mode button available for development/testing
2. **Flexibility**: Can enable/disable based on deployment environment
3. **Progressive Enhancement**: Smooth transition when AEP-5342 becomes production-ready
4. **Risk Mitigation**: No impact on existing scaling modes

## Implementation Details

### **Current State (Phase 1)**:
```yaml
# Kafka Lag Mode available but with limitations
healthcare.ml.features.kafka-lag-mode.enabled=true
healthcare.ml.features.multi-dimensional-autoscaler.enabled=false

# UI shows Kafka Lag Mode button
# Backend implements basic Kafka lag scaling
# HPA conflicts may limit scaling to 1 pod
```

### **Future State (Phase 2)**:
```yaml
# Multi-dimensional Pod Autoscaler deployed
healthcare.ml.features.multi-dimensional-autoscaler.enabled=true

# Single autoscaler manages multiple dimensions:
# - CPU/Memory metrics (existing modes)
# - Kafka consumer lag metrics (Kafka Lag Mode)
# - Custom metrics coordination
```

### **Architecture Integration**:
```
Current: KEDA → Multiple HPAs → Conflicts
Future:  KEDA → Multi-dimensional Pod Autoscaler → Coordinated Scaling
```

## Consequences

### **Positive**:
- ✅ **Maintains 4-mode architecture** as designed
- ✅ **Provides immediate development value** with feature flags
- ✅ **Future-proofs system** for advanced autoscaling coordination
- ✅ **Aligns with Red Hat roadmap** and support strategy
- ✅ **Enables proper Kafka lag scaling** when ready

### **Negative**:
- ❌ **Kafka Lag Mode limitations** until AEP-5342 production-ready
- ❌ **Additional complexity** in feature flag management
- ❌ **Dependency on external project** timeline

### **Neutral**:
- 🔄 **No impact on existing modes** (Normal, Big Data, Node Scale)
- 🔄 **Gradual implementation** allows for testing and validation

## Monitoring and Success Criteria

### **Phase 1 Success Criteria**:
- [x] Feature flag implementation complete
- [x] Kafka Lag Mode button functional
- [x] Basic Kafka lag scaling operational
- [x] Documentation updated

### **Phase 2 Readiness Indicators**:
- [ ] AEP-5342 reaches production maturity
- [ ] Red Hat provides official support
- [ ] Healthcare ML system testing validates integration
- [ ] Performance benchmarks meet requirements

### **Phase 3 Success Criteria**:
- [ ] Multi-pod Kafka lag scaling (15 messages → 2+ pods)
- [ ] No HPA selector conflicts
- [ ] Coordinated scaling across all 4 modes
- [ ] Production stability validation

## Related Documentation

- [Research: KEDA Kafka Lag Scaling vs Node Autoscaling](../research/keda-kafka-lag-scaling-vs-node-autoscaling.md)
- [Research: Red Hat Autoscaling Coordination Projects](../research/red-hat-autoscaling-coordination-projects.md)
- [ADR-007: Multi-Topic KEDA and Node Scaling Architecture](./ADR-007-multi-topic-keda-node-scaling-architecture.md)
- [Tutorial: Kafka Lag-Based Scaling](../tutorials/05-kafka-lag-scaling.md)

## References

- **AEP-5342**: Multi-dimensional Pod Autoscaler Enhancement Proposal
- **Red Hat OpenShift Roadmap**: 2025 autoscaling enhancements
- **KEDA Project**: Red Hat co-founded and maintained
- **Healthcare ML System**: 4-mode scaling architecture requirements
