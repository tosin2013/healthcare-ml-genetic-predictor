# Architecture Decision Records (ADRs)

This directory contains Architecture Decision Records for the Healthcare ML platform on Azure Red Hat OpenShift.

## ADR Index

### ✅ Approved & Implemented

| ADR | Title | Status | Priority | Dependencies |
|-----|-------|--------|----------|--------------|
| [ADR-001](./ADR-001-correct-deployment-strategy-websocket-vep-services.md) | Correct Deployment Strategy for WebSocket and VEP Services | ✅ **CRITICAL** | 🔥 HIGH | None |
| [ADR-004](./ADR-004-api-testing-validation-openshift.md) | API Testing and Validation on OpenShift | ✅ **VALIDATED** | 🧪 HIGH | ADR-001 |

### 🔄 In Progress

| ADR | Title | Status | Priority | Dependencies |
|-----|-------|--------|----------|--------------|
| [ADR-002](./ADR-002-openshift-ai-integration-strategy.md) | OpenShift AI Integration Strategy | 🔄 **PROPOSED** | 🚀 HIGH | ADR-001 |
| [ADR-003](./ADR-003-healthcare-ml-ecosystem-architecture.md) | Healthcare ML Ecosystem - Complete Architecture | 🔄 **PROPOSED** | 🎯 MEDIUM | ADR-001, ADR-002 |

### 📋 Planned

| ADR | Title | Status | Priority | Dependencies |
|-----|-------|--------|----------|--------------|
| ADR-005 | Security and Compliance Framework | 📋 **PLANNED** | 🔒 HIGH | ADR-003 |
| ADR-006 | Data Lake and Research Platform | 📋 **PLANNED** | 🔬 MEDIUM | ADR-002, ADR-003 |
| ADR-007 | Cost Management and KEDA Integration | 📋 **PLANNED** | 💰 HIGH | ADR-001, ADR-004 |

## Quick Navigation

### 🚨 **Start Here: Critical Architecture Fix**
**[ADR-001: Deployment Strategy Correction](./ADR-001-correct-deployment-strategy-websocket-vep-services.md)**

**Problem:** WebSocket and VEP services have backwards deployment strategies causing timeouts and resource waste.

**Solution:** 
- WebSocket Service → Regular Deployment (persistent connections)
- VEP Service → Knative Service (event-driven scaling)

**Impact:** Resolves external URL timeouts, enables proper scaling, prepares for OpenShift AI integration.

---

### 🧠 **ML Integration Strategy**
**[ADR-002: OpenShift AI Integration](./ADR-002-openshift-ai-integration-strategy.md)**

**Problem:** Need advanced ML capabilities for genetic analysis beyond basic VEP annotations.

**Solution:** Integrate OpenShift AI platform with ModelMesh Serving, Jupyter notebooks, and ML pipelines.

**Impact:** Enables genetic risk prediction, pharmacogenomics, clinical decision support, and research collaboration.

---

### 🏗️ **Big Picture Architecture**
**[ADR-003: Complete Ecosystem Architecture](./ADR-003-healthcare-ml-ecosystem-architecture.md)**

**Problem:** Need unified architecture vision for healthcare ML platform on Azure Red Hat OpenShift.

**Solution:** 5-layer architecture with presentation, application, integration, data, and infrastructure layers.

**Impact:** Provides complete roadmap for enterprise-grade healthcare ML platform with cost management and compliance.

---

### 🧪 **API Testing and Validation**
**[ADR-004: API Testing and Validation on OpenShift](./ADR-004-api-testing-validation-openshift.md)**

**Problem:** Need comprehensive testing framework to validate API endpoints on live OpenShift cluster.

**Solution:** Implemented 5 REST API endpoints with comprehensive testing suite and validation on live Azure Red Hat OpenShift cluster.

**Impact:** Validated API reliability (100% success rate), scaling integration, input validation, and production readiness.

## Architecture Overview

### Current System State

```
┌─────────────────────────────────────────────────────────────────┐
│                    Current Implementation                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ ✅ WORKING                    🔄 IN PROGRESS                    │
│ • Kafka 3-replica cluster    • WebSocket deployment fix        │
│ • VEP service functionality  • OpenShift AI integration        │
│ • Basic genetic analysis     • Advanced ML models             │
│ • OpenShift infrastructure   • Cost management setup          │
│                                                                 │
│ ❌ ISSUES RESOLVED            📋 PLANNED                        │
│ • Consumer group rebalancing • KEDA auto-scaling              │
│ • Single broker instability  • Security hardening            │
│ • External URL timeouts      • Research platform              │
│ • Resource waste             • Compliance framework           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Target Architecture Vision

```
┌─────────────────────────────────────────────────────────────────┐
│                    Target Architecture                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ 🏥 CLINICAL EXCELLENCE       🔬 RESEARCH INNOVATION            │
│ • Real-time genetic analysis • Collaborative ML development    │
│ • Clinical decision support  • Population genomics studies     │
│ • Personalized medicine     • Advanced model training          │
│ • Treatment optimization     • Data exploration platform       │
│                                                                 │
│ 💰 COST EFFICIENCY          🔒 SECURITY & COMPLIANCE           │
│ • Scale-to-zero services    • Healthcare-grade security        │
│ • Auto-scaling with KEDA    • HIPAA compliance                 │
│ • Real-time cost attribution• Confidential containers          │
│ • Resource optimization     • Audit trails & governance        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Implementation Priority

### Phase 1: Foundation (Weeks 1-2) 🔥 **CRITICAL**
1. **[ADR-001](./ADR-001-correct-deployment-strategy-websocket-vep-services.md)** - Fix deployment strategies
2. Validate external URL accessibility
3. Confirm stable WebSocket connections
4. Test VEP service auto-scaling

### Phase 2: ML Integration (Weeks 3-4) 🚀 **HIGH**
1. **[ADR-002](./ADR-002-openshift-ai-integration-strategy.md)** - Deploy OpenShift AI
2. Implement basic ML models
3. Set up Jupyter notebook environment
4. Create ML inference pipeline

### Phase 3: Complete Platform (Weeks 5-8) 🎯 **MEDIUM**
1. **[ADR-003](./ADR-003-healthcare-ml-ecosystem-architecture.md)** - Full ecosystem
2. KEDA integration for cost management
3. Security and compliance framework
4. Research platform capabilities

## Decision Process

### ADR Lifecycle

```
📝 DRAFT → 🔄 PROPOSED → ✅ ACCEPTED → 🚀 IMPLEMENTED → 📊 VALIDATED
```

### Review Criteria

1. **Technical Feasibility** - Can be implemented with current resources
2. **Business Value** - Addresses clinical or research needs
3. **Cost Impact** - Aligns with budget and cost optimization goals
4. **Security Compliance** - Meets healthcare security requirements
5. **Maintainability** - Sustainable long-term solution

### Approval Process

1. **Author** creates ADR with technical analysis
2. **Co-Developer** reviews architecture and implementation
3. **Team** discusses trade-offs and alternatives
4. **Stakeholders** approve business impact and priorities
5. **Implementation** begins with monitoring and validation

## Related Documentation

- **[Architecture Summary](../ARCHITECTURE_CORRECTION_SUMMARY.md)** - Quick reference guide
- **[Implementation Guides](../implementation/)** - Step-by-step procedures
- **[Monitoring & Observability](../monitoring/)** - System health and metrics
- **[Security & Compliance](../security/)** - Healthcare-grade security policies

## Contact & Support

- **Architecture Questions**: Healthcare ML Team
- **Implementation Support**: Co-Developer Team  
- **Security & Compliance**: Security Team
- **Cost Management**: FinOps Team

---

**Last Updated:** 2025-06-13  
**Next Review:** 2025-06-20  
**Version:** 1.0
