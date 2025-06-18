# ADR-006: VEP Service Architecture Decision - Knative vs Deployment for KEDA Scaling

## Status
**DECIDED** - Convert VEP Service from Knative to Deployment for immediate KEDA compatibility

## Context

During the implementation of event-driven scaling for the healthcare ML demo, we discovered a critical compatibility issue between KEDA v1.23 and Knative Services. This ADR documents the analysis of three potential solutions and the decision to convert the VEP (Variant Effect Predictor) service from a Knative Service to a standard Kubernetes Deployment.

## Problem Statement

### Technical Issue Discovered
- **KEDA v1.23** successfully installed and operational in `openshift-keda` namespace
- **KEDA + Deployment**: ✅ Working (ScaledObject READY=True, scaling functional)
- **KEDA + Knative Service**: ❌ Failed (`services.serving.knative.dev "vep-service" not found`)
- **Root Cause**: KEDA v1.23 lacks proper support for Knative Service `/scale` subresource

### Impact on Healthcare ML Demo
- VEP service cannot scale based on Kafka message lag
- Event-driven architecture partially non-functional
- Cost attribution demonstration blocked
- Healthcare ML workload scaling requirements unmet

## Decision

**Selected Approach**: Convert VEP Service from Knative Service to Kubernetes Deployment

### Rationale

#### **Immediate Benefits**
1. **Proven Compatibility**: Test deployment with KEDA ScaledObject achieved READY=True status
2. **Full Feature Support**: Enables Kafka lag + CPU + Memory based scaling triggers
3. **Research Validated**: Aligns with comprehensive research findings on KEDA v1.23 limitations
4. **Quick Implementation**: 1-2 hour timeline vs days for KEDA upgrade

#### **Acceptable Trade-offs**
1. **Scale-to-Zero Loss**: VEP will maintain minimum 1 replica instead of true zero scaling
2. **Resource Consumption**: Slight increase in baseline resource usage
3. **Cost Impact**: Minimal - single pod resource consumption vs scaling benefits

## Implementation Plan

### Phase 1: VEP Service Conversion (Immediate)

#### **1. Create VEP Deployment Configuration**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vep-service
  namespace: healthcare-ml-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vep-service
  template:
    metadata:
      labels:
        app: vep-service
    spec:
      containers:
      - name: vep-service
        image: # VEP service image
        env:
        - name: KAFKA_CONSUMER_GROUP
          value: "vep-service-group"
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
```

#### **2. Update KEDA ScaledObject**
```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: vep-service-scaler
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: vep-service
  minReplicaCount: 1  # Changed from 0
  maxReplicaCount: 20
  triggers:
  - type: kafka
    metadata:
      consumerGroup: vep-service-group
      topic: genetic-data-raw
      lagThreshold: "5"
```

#### **3. Service and Networking**
- Create Kubernetes Service for VEP deployment
- Update ingress/route configurations
- Maintain existing API endpoints

### Phase 2: Future Enhancement Planning

#### **KEDA Upgrade Path (Long-term)**
- **Target**: Upgrade to Red Hat Custom Metrics Autoscaler v2.15.1
- **Benefits**: Restore Knative Service compatibility + scale-to-zero
- **Timeline**: Planned for Q2 2025
- **Prerequisites**: 
  - Test environment validation
  - Configuration migration planning
  - Compatibility testing with OpenShift 4.x

## Consequences

### Positive Outcomes
- **✅ Immediate KEDA Scaling**: VEP service will scale based on Kafka lag
- **✅ Full Event-Driven Architecture**: Complete CloudEvents → Kafka → KEDA → Pod scaling flow
- **✅ Cost Attribution**: Enables demonstration of scaling-based cost management
- **✅ Production Ready**: Proven architecture with research validation
- **✅ Healthcare ML Compliance**: Maintains all security and compliance requirements

### Acceptable Limitations
- **⚠️ No Scale-to-Zero**: VEP maintains minimum 1 replica (vs 0 with Knative)
- **⚠️ Resource Baseline**: ~100m CPU + 256Mi memory baseline consumption
- **⚠️ Architecture Deviation**: Temporary departure from pure serverless model

### Mitigation Strategies
1. **Resource Optimization**: Use minimal resource requests for baseline pod
2. **Future Migration**: Plan KEDA upgrade to restore Knative compatibility
3. **Cost Monitoring**: Track actual vs projected cost impact
4. **Performance Tuning**: Optimize scaling thresholds for efficiency

## Monitoring and Success Criteria

### Implementation Success Metrics
- [ ] VEP Deployment successfully created and running
- [ ] KEDA ScaledObject shows READY=True status
- [ ] VEP service scales 1→N based on Kafka lag (threshold: 5 messages)
- [ ] API endpoints maintain 100% functionality
- [ ] Consumer group `vep-service-group` shows active consumers
- [ ] End-to-end genetic analysis workflow functional

### Performance Benchmarks
- **Scaling Response Time**: Target <60 seconds for lag-based scaling
- **Message Processing**: Maintain 100% success rate
- **Resource Efficiency**: Monitor CPU/memory utilization vs scaling
- **Cost Impact**: Track resource consumption vs scaling benefits

## Alternative Approaches Considered

### Option 2: Upgrade KEDA (Rejected for Now)
**Pros**: Maintains Knative benefits, future-proof
**Cons**: Complex migration (v1.23→v2.15.1), higher risk, 1-2 day timeline
**Decision**: Deferred to future enhancement phase

### Option 3: Knative Native Autoscaling (Rejected)
**Pros**: Native integration, maintains scale-to-zero
**Cons**: No Kafka lag-based scaling, HTTP-only triggers
**Decision**: Doesn't meet event-driven requirements

## Related Documents
- [ADR-001: Healthcare ML Architecture](./ADR-001-healthcare-ml-architecture.md)
- [ADR-002: Event-Driven Scaling Strategy](./ADR-002-event-driven-scaling-strategy.md)
- [ADR-004: API Testing and Validation](./ADR-004-api-testing-validation-openshift.md)
- [ADR-005: KEDA Troubleshooting and Configuration](./ADR-005-keda-troubleshooting-configuration.md)

---

**Decision Date**: June 15, 2025  
**Status**: Decided - Ready for implementation  
**Next Review**: After VEP deployment conversion and scaling validation
