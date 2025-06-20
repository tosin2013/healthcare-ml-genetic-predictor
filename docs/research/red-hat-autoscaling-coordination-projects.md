# Red Hat-Supported Open Source Projects for Kubernetes Autoscaling Coordination and HPA Conflict Resolution

**Research Date**: June 20, 2025  
**Context**: Healthcare ML system experiencing HPA selector conflicts preventing proper Kafka lag scaling demonstration  
**Requirement**: Solutions must be Red Hat-supported or have Red Hat involvement  

## Executive Summary

Based on comprehensive research, there are **three primary Red Hat-supported or Red Hat-involved projects** that could potentially address HPA conflicts and improve Kubernetes autoscaling coordination. However, **none of these projects are currently production-ready** for resolving the specific HPA selector conflict issue identified in your healthcare ML system.

## Key Findings

### 1. **Red Hat Custom Metrics Autoscaler (Production Ready)**

**Status**: ✅ **Production Ready** - Available in OpenShift 4.11+  
**Red Hat Involvement**: ✅ **Fully Supported** - Red Hat-maintained operator based on KEDA  

**Capabilities**:
- Based on KEDA (Kubernetes Event Driven Autoscaler)
- Red Hat is a **co-founder and principal maintainer** of KEDA
- Zbynek Roubalik (Red Hat) is a key KEDA maintainer
- Supports Kafka consumer lag scaling (your current use case)

**Limitations for Your Issue**:
- ❌ **Does NOT resolve HPA selector conflicts**
- ❌ **Still creates standard HPAs** that can conflict with existing ones
- ❌ **No coordination mechanism** between multiple autoscalers

### 2. **Multi-dimensional Pod Autoscaler (AEP-5342) - Development Phase**

**Status**: 🚧 **In Development** - Enhancement proposal stage  
**Red Hat Involvement**: ✅ **Active Contributor** - Red Hat has fork and roadmap mentions  

**Capabilities**:
- **Designed specifically to coordinate multiple autoscaling dimensions**
- Could theoretically handle HPA conflicts by managing multiple metrics in one autoscaler
- Mentioned in Red Hat OpenShift 2025 roadmap
- Available in Red Hat's kubernetes-autoscaler fork

**Limitations for Your Issue**:
- ❌ **Not production ready** - Still in enhancement proposal phase
- ❌ **No clear timeline** for production availability
- ❌ **Limited documentation** and implementation details
- ❌ **Uncertain Red Hat support timeline**

### 3. **KEDA v2.15+ Roadmap Enhancements**

**Status**: 🔄 **Future Development** - Planned for 2025  
**Red Hat Involvement**: ✅ **Co-maintainer** - Red Hat drives KEDA development  

**Capabilities**:
- Red Hat is actively working on KEDA improvements
- Potential for better autoscaler coordination in future versions
- Integration with OpenShift-specific features

**Limitations for Your Issue**:
- ❌ **Future timeline** - No immediate solution
- ❌ **No specific HPA conflict resolution** mentioned in current roadmap
- ❌ **Speculative** - No concrete implementation details

## Critical Gap Analysis

### **What You Need vs What's Available**:

| **Requirement** | **Available Solutions** | **Gap** |
|-----------------|------------------------|---------|
| **Immediate HPA conflict resolution** | None | ❌ **No Red Hat solution exists** |
| **Production-ready coordination** | Red Hat Custom Metrics Autoscaler | ❌ **Still creates conflicting HPAs** |
| **Multi-autoscaler management** | Multi-dimensional Pod Autoscaler | ❌ **Not production ready** |
| **Red Hat support requirement** | All three projects | ✅ **Requirement met** |

## Current Problem Analysis

### **Identified Issue in Healthcare ML System**:
```yaml
# Current Problem: Overlapping selectors
vep-service-multi-hpa:     app=vep-service (matches all VEP pods)
kafka-lag-demo-hpa:        app=vep-service,mode=kafka-lag

# Result: AmbiguousSelector warnings → Scaling disabled → Max 1 pod
```

### **Impact**:
- **Expected**: 15 consumer lag → 2+ pods (15 ÷ 10 = 2 pods)
- **Actual**: 15 consumer lag → 1 pod (due to HPA conflicts)
- **Demo Value**: Significantly reduced scaling demonstration impact

## Recommendations

### **Short-term Solution (Immediate)**:
**Fix the HPA selector conflicts manually** using Red Hat-supported Kubernetes features:

```yaml
# Solution: Exclusive selectors
vep-service-multi-hpa:     app=vep-service,mode!=kafka-lag  
kafka-lag-demo-hpa:        app=vep-service,mode=kafka-lag
```

**Implementation Steps**:
1. Update HPA selectors to be mutually exclusive
2. Ensure deployment labels support the new selector logic
3. Test scaling behavior with resolved conflicts
4. Verify multi-pod scaling works as expected

### **Medium-term Solution (6-12 months)**:
**Monitor Multi-dimensional Pod Autoscaler development** and evaluate for adoption when Red Hat provides production support.

**Tracking**:
- Watch Red Hat OpenShift roadmap updates
- Monitor AEP-5342 progress in kubernetes/autoscaler
- Evaluate Red Hat's kubernetes-autoscaler fork developments

### **Long-term Solution (2025+)**:
**Leverage KEDA roadmap enhancements** as Red Hat continues to improve autoscaling coordination.

**Benefits**:
- Native coordination between multiple scalers
- Improved conflict resolution mechanisms
- Better integration with OpenShift features

## Research Sources

### **Key Projects Investigated**:
1. **Red Hat Custom Metrics Autoscaler**: OpenShift 4.11+ operator
2. **Multi-dimensional Pod Autoscaler**: AEP-5342 in kubernetes/autoscaler
3. **KEDA Project**: Co-founded and maintained by Red Hat
4. **Red Hat OpenShift Roadmap**: 2025 autoscaling enhancements

### **Red Hat Personnel**:
- **Zbynek Roubalik**: Principal KEDA maintainer at Red Hat
- **Red Hat Engineering**: Active contributors to autoscaling projects

## Conclusion

**The project you were thinking of is likely the Multi-dimensional Pod Autoscaler (AEP-5342)**, which is the only Red Hat-involved project specifically designed to address autoscaling coordination. However, it's **not yet production-ready**.

**For your immediate needs**, the most pragmatic approach is to **fix the HPA label selectors** to eliminate conflicts while continuing to use the Red Hat Custom Metrics Autoscaler (KEDA-based) for Kafka lag scaling.

**Red Hat's involvement in KEDA** ensures long-term support and improvements, but current KEDA versions don't solve HPA coordination conflicts - they still create standard HPAs that can conflict with existing ones.

## Next Steps

1. **Immediate**: Implement HPA selector fix to resolve current conflicts
2. **Monitor**: Track Multi-dimensional Pod Autoscaler development progress  
3. **Evaluate**: Assess future KEDA enhancements for coordination features
4. **Document**: Update system documentation with scaling behavior expectations

---

**Research Methodology**: Web search, Red Hat documentation review, GitHub project analysis, OpenShift roadmap investigation  
**Confidence Level**: High - Based on official Red Hat sources and project documentation  
**Last Updated**: June 20, 2025
