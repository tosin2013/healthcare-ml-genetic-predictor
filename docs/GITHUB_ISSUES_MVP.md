# GitHub Issues for MVP Demo

## 🎯 **MVP Milestone: Azure Scaling & Cost Demo**

### **Phase 1: Foundation (Week 1) - CRITICAL**

#### **Issue #1: Fix WebSocket Service Deployment Strategy**
```markdown
**Title**: Convert WebSocket Service from Knative to Deployment

**Priority**: 🔥 CRITICAL
**Labels**: `mvp`, `deployment`, `websocket`, `bug-fix`
**Milestone**: Phase 1 - Foundation

**Description**:
Fix the backwards deployment strategy where WebSocket service is deployed as Knative (causing connection drops) instead of regular Deployment (persistent connections).

**Acceptance Criteria**:
- [ ] Remove Knative service configuration for WebSocket service
- [ ] Create Deployment + Service + Route configuration
- [ ] Update kustomization files
- [ ] Test external URL accessibility without timeouts
- [ ] Validate WebSocket connection persistence during scaling events
- [ ] Update documentation

**Technical Details**:
- Remove: `k8s/base/applications/quarkus-websocket/knative-service.yaml`
- Add: `k8s/base/applications/quarkus-websocket/deployment.yaml`
- Add: `k8s/base/applications/quarkus-websocket/service.yaml`
- Add: `k8s/base/applications/quarkus-websocket/route.yaml`

**Definition of Done**:
- ✅ External WebSocket URL responds without timeouts
- ✅ WebSocket connections persist during pod restarts
- ✅ All tests pass
- ✅ Documentation updated
```

#### **Issue #2: Convert VEP Service to Knative**
```markdown
**Title**: Convert VEP Service from Deployment to Knative Service

**Priority**: 🔥 CRITICAL
**Labels**: `mvp`, `knative`, `vep-service`, `scaling`
**Milestone**: Phase 1 - Foundation
**Depends On**: #1

**Description**:
Convert VEP service from always-on Deployment to event-driven Knative service for cost-efficient auto-scaling.

**Acceptance Criteria**:
- [ ] Remove Deployment configuration for VEP service
- [ ] Create Knative service configuration with auto-scaling
- [ ] Configure scale-to-zero behavior
- [ ] Test scaling from 0→N pods based on Kafka messages
- [ ] Validate genetic processing functionality
- [ ] Update monitoring and observability

**Technical Details**:
- Remove: `k8s/base/applications/vep-service/deployment.yaml`
- Add: `k8s/base/applications/vep-service/knative-service.yaml`
- Configure: `autoscaling.knative.dev/minScale: "0"`
- Configure: `autoscaling.knative.dev/maxScale: "20"`

**Definition of Done**:
- ✅ VEP service scales to zero when no genetic data
- ✅ VEP service scales up within 30s of Kafka messages
- ✅ Genetic processing works correctly
- ✅ Cost efficiency demonstrated
```

#### **Issue #3: Install and Configure KEDA**
```markdown
**Title**: Install KEDA for Kafka-based Auto-scaling

**Priority**: 🚀 HIGH
**Labels**: `mvp`, `keda`, `auto-scaling`, `infrastructure`
**Milestone**: Phase 1 - Foundation
**Depends On**: #2

**Description**:
Install KEDA operator and configure Kafka-based scaling triggers for VEP service to demonstrate Azure machine scaling.

**Acceptance Criteria**:
- [ ] Install KEDA operator on OpenShift cluster
- [ ] Create ScaledObject for VEP service with Kafka triggers
- [ ] Configure Cluster Autoscaler for node scaling
- [ ] Test pod scaling based on Kafka message volume
- [ ] Test node scaling when resource demands increase
- [ ] Monitor scaling events in OpenShift console

**Technical Details**:
- Install: KEDA operator from OperatorHub
- Create: `ScaledObject` with Kafka trigger
- Configure: `lagThreshold: '5'` for responsive scaling
- Set: `maxReplicaCount: 20` for demo scaling

**Definition of Done**:
- ✅ KEDA operator installed and running
- ✅ Pods scale based on Kafka message volume
- ✅ Nodes scale when pod resource demands increase
- ✅ Scaling events visible in monitoring
```

### **Phase 2: Cost Management (Week 2) - HIGH PRIORITY**

#### **Issue #4: Install OpenShift Cost Management Operator**
```markdown
**Title**: Install and Configure Cost Management Operator

**Priority**: 💰 HIGH
**Labels**: `mvp`, `cost-management`, `monitoring`, `infrastructure`
**Milestone**: Phase 2 - Cost Management

**Description**:
Install OpenShift Cost Management Operator to track and visualize costs during scaling demo.

**Acceptance Criteria**:
- [ ] Install Cost Management Operator
- [ ] Configure cost data collection
- [ ] Set up project-level cost attribution
- [ ] Create cost visualization dashboard
- [ ] Test real-time cost tracking during scaling
- [ ] Configure chargeback reports

**Technical Details**:
- Install: Cost Management Operator from OperatorHub
- Configure: Project-level cost attribution
- Set up: Real-time cost data collection
- Create: Grafana dashboard for cost visualization

**Definition of Done**:
- ✅ Real-time cost data collection active
- ✅ Cost attribution per genetic analysis working
- ✅ Project-level chargeback reports available
- ✅ Cost dashboard accessible via UI
```

#### **Issue #5: Implement "Big Data" Button**
```markdown
**Title**: Add "Big Data" Button for Scaling Demo

**Priority**: 📊 HIGH
**Labels**: `mvp`, `ui`, `big-data`, `demo`
**Milestone**: Phase 2 - Cost Management
**Depends On**: #3, #4

**Description**:
Add "Big Data" button to WebSocket UI to trigger large-scale genetic processing and demonstrate burst scaling with cost impact.

**Acceptance Criteria**:
- [ ] Add "Big Data" button to WebSocket UI
- [ ] Create large genetic dataset generator (1000+ sequences)
- [ ] Implement burst processing workflow
- [ ] Monitor cost impact during burst loads
- [ ] Show scaling from 2→5+ nodes
- [ ] Display real-time cost increases

**Technical Details**:
- Add: Big Data button to `genetic-client.html`
- Create: Large dataset generator function
- Implement: Batch message publishing to Kafka
- Monitor: Scaling events and cost impact

**Definition of Done**:
- ✅ "Big Data" button triggers large-scale processing
- ✅ Demonstrates significant scaling (5+ nodes)
- ✅ Cost impact clearly visible in dashboard
- ✅ System returns to baseline after processing
```

### **Phase 3: Demo Polish (Week 3) - MEDIUM PRIORITY**

#### **Issue #6: Real-time Scaling Visualization**
```markdown
**Title**: Create Real-time Scaling and Cost Visualization

**Priority**: 📈 MEDIUM
**Labels**: `mvp`, `visualization`, `monitoring`, `demo`
**Milestone**: Phase 3 - Demo Polish
**Depends On**: #4, #5

**Description**:
Create real-time visualization of scaling events and cost tracking for demo presentation.

**Acceptance Criteria**:
- [ ] Real-time scaling events visible in UI
- [ ] Cost metrics update in real-time
- [ ] Performance metrics display
- [ ] Demo script and documentation
- [ ] Demo can be repeated consistently

**Technical Details**:
- Integrate: OpenShift metrics API
- Create: Real-time dashboard components
- Add: WebSocket updates for live data
- Document: Demo execution steps

**Definition of Done**:
- ✅ Live scaling events visible in UI
- ✅ Cost metrics update in real-time
- ✅ Demo can be repeated consistently
- ✅ Documentation for demo execution
```

#### **Issue #7: Demo Optimization and Reset**
```markdown
**Title**: Optimize Demo Performance and Add Reset Functionality

**Priority**: ⚡ MEDIUM
**Labels**: `mvp`, `optimization`, `demo`, `performance`
**Milestone**: Phase 3 - Demo Polish
**Depends On**: #6

**Description**:
Optimize demo performance and add reset functionality for reliable demo execution.

**Acceptance Criteria**:
- [ ] Optimize scaling response times (<30s)
- [ ] Tune cost collection frequency (<10s updates)
- [ ] Improve UI responsiveness during scaling
- [ ] Add demo reset functionality
- [ ] Create demo execution script

**Technical Details**:
- Tune: KEDA scaling parameters
- Optimize: Cost data collection frequency
- Add: Demo reset script
- Create: Automated demo execution

**Definition of Done**:
- ✅ Scaling response < 30 seconds
- ✅ Cost data updates < 10 seconds
- ✅ UI remains responsive during scaling
- ✅ Demo can be reset and re-run
```

## 🌟 **Community Project Issues (Nice-to-Have)**

#### **Issue #8: OpenShift AI Integration**
```markdown
**Title**: Integrate OpenShift AI for Advanced Genetic Analysis

**Priority**: 🌟 NICE-TO-HAVE
**Labels**: `community`, `openshift-ai`, `ml`, `enhancement`
**Milestone**: Phase 4 - Community Extensions

**Description**:
Integrate OpenShift AI platform for advanced ML capabilities in genetic analysis.

**Acceptance Criteria**:
- [ ] Deploy ModelMesh Serving
- [ ] Create basic ML models for genetic analysis
- [ ] Set up Jupyter notebook environment
- [ ] Implement ML inference pipeline
- [ ] Document ML model development process

**Community Contribution**:
This issue is open for community contributions. Contributors can:
- Develop new ML models for genetic analysis
- Create Jupyter notebooks for research
- Improve ML inference performance
- Add new genetic analysis capabilities
```

#### **Issue #9: Research Collaboration Platform**
```markdown
**Title**: Create Research Collaboration Platform

**Priority**: 🌟 NICE-TO-HAVE
**Labels**: `community`, `research`, `collaboration`, `enhancement`
**Milestone**: Phase 5 - Advanced Features

**Description**:
Create platform for researchers to collaborate on genetic analysis projects.

**Community Contribution**:
Open for community development of:
- Collaborative research workflows
- Data sharing capabilities
- Research project management
- Publication and citation tools
```

#### **Issue #10: Security and Compliance Framework**
```markdown
**Title**: Implement Healthcare Security and Compliance

**Priority**: 🌟 NICE-TO-HAVE
**Labels**: `community`, `security`, `compliance`, `healthcare`
**Milestone**: Phase 5 - Advanced Features

**Description**:
Implement healthcare-grade security and compliance features.

**Community Contribution**:
Open for community development of:
- HIPAA compliance features
- Data encryption and protection
- Audit logging and trails
- Access control and governance
```

## 📋 **GitHub Project Setup**

### **Milestones**
1. **Phase 1 - Foundation** (Week 1)
2. **Phase 2 - Cost Management** (Week 2)  
3. **Phase 3 - Demo Polish** (Week 3)
4. **Phase 4 - Community Extensions** (Ongoing)
5. **Phase 5 - Advanced Features** (Ongoing)

### **Labels**
- `mvp` - MVP demo requirements
- `community` - Community contribution opportunities
- `critical` - Must-have for demo
- `enhancement` - Nice-to-have features
- `bug-fix` - Fixes for existing issues
- `documentation` - Documentation updates

### **Project Board Columns**
1. **📋 Backlog** - All issues
2. **🔄 In Progress** - Currently being worked on
3. **👀 Review** - Ready for review
4. **✅ Done** - Completed issues
5. **🌟 Community** - Open for community contributions

---

**Next Steps**:
1. Create GitHub repository (if not exists)
2. Set up GitHub project with these issues
3. Assign MVP issues to development team
4. Mark community issues as "good first issue" for contributors
5. Begin Phase 1 implementation
