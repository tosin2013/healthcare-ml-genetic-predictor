---
name: Cost Management Console Access Issue
about: Report issues with Red Hat Cost Management console access
title: "[COST-ACCESS] Validate Red Hat Cost Management Console Access"
labels: ["cost-management", "access-issue", "red-hat-console", "validation-needed"]
assignees: []
---

## 🚨 **Cost Management Console Access Issue**

### **Problem Description**
Users cannot access the Red Hat Cost Management console at `https://console.redhat.com/openshift/cost-management` to view cost attribution data for the healthcare ML system.

### **Current Impact**
- ❌ Cost attribution reports reference inaccessible dashboard URLs
- ❌ Users cannot validate cost data collection in Red Hat console
- ❌ Cost management integration appears incomplete to end users
- ❌ Documentation references non-functional dashboard links

### **Expected Behavior**
- ✅ Users should be able to access Red Hat Cost Management console
- ✅ Healthcare ML cluster should appear in the cost management dashboard
- ✅ Cost attribution data should be visible with proper filtering
- ✅ Cost center breakdown should show genomics-research vs genomics-research-demo

### **Current Configuration Status**
- ✅ Cost Management Metrics Operator: Deployed
- ✅ CostManagementMetricsConfig: Active
- ✅ Cost attribution labels: Applied
- ✅ Data collection: Enabled
- ❌ Console access: **NOT VALIDATED**

### **Affected Components**
- [ ] Cost attribution report CronJob
- [ ] Red Hat Cost Management dashboard links
- [ ] Documentation references to console.redhat.com
- [ ] Cost validation scripts
- [ ] User onboarding documentation

### **Files Referencing console.redhat.com**
- `k8s/overlays/environments/demo/cost-management-config.yaml` (lines 242, 252, 253)
- `scripts/show-cost-attribution.sh` (line 98)
- `scripts/configure-existing-cost-management.sh` (lines 50, 171, 220)
- `scripts/setup-redhat-cost-management.sh` (line 253)
- `scripts/setup-redhat-cost-management-official.sh` (line 270)
- `docs/how-to/monitor-costs.md` (multiple references)

### **Validation Requirements**
1. **Account Access Validation**
   - [ ] Verify user has Red Hat account with console.redhat.com access
   - [ ] Confirm user has appropriate permissions for cost management
   - [ ] Validate organization/subscription access

2. **Cluster Registration Validation**
   - [ ] Verify cluster is registered as a source in Red Hat Cost Management
   - [ ] Confirm cluster appears in the sources list
   - [ ] Validate data collection is active

3. **Data Visibility Validation**
   - [ ] Confirm healthcare-ml-demo project data is visible
   - [ ] Validate cost center filtering works (genomics-research, genomics-research-demo)
   - [ ] Verify cost attribution labels are properly displayed

### **Proposed Solutions**

#### **Option 1: Alternative Dashboard Access**
- Implement OpenShift Web Console cost viewing
- Use local Prometheus/Grafana dashboards
- Create custom cost visualization within the application

#### **Option 2: Access Validation & Setup**
- Create step-by-step Red Hat account setup guide
- Implement automated cluster registration validation
- Add access verification to setup scripts

#### **Option 3: Hybrid Approach**
- Provide both Red Hat console and local dashboard options
- Add access validation with fallback to local dashboards
- Update documentation with multiple access methods

### **Immediate Actions Needed**
1. **Validate Current Access**
   - [ ] Test console.redhat.com access with current user credentials
   - [ ] Document specific access errors or permission issues
   - [ ] Identify required Red Hat subscription/account type

2. **Update Documentation**
   - [ ] Add access validation steps to setup guides
   - [ ] Provide alternative cost viewing methods
   - [ ] Update troubleshooting sections

3. **Enhance Cost Attribution Report**
   - [ ] Add access validation to cost attribution CronJob
   - [ ] Provide fallback cost reporting when console is inaccessible
   - [ ] Include access status in report output

### **Testing Checklist**
- [ ] Test console.redhat.com access with different user types
- [ ] Validate cluster registration process
- [ ] Confirm cost data visibility in dashboard
- [ ] Test cost center filtering functionality
- [ ] Verify project-level cost attribution

### **Additional Context**
The healthcare ML system has comprehensive Cost Management Metrics Operator integration configured, but the end-user experience is incomplete without validated access to the Red Hat Cost Management console. This issue blocks full cost attribution validation and user adoption.

### **Priority**: High
**Reason**: Affects user experience and cost management validation workflows

### **Related Issues**
- Cost attribution report enhancements
- Documentation updates for cost management
- User onboarding improvements

---
**Environment**: Azure Red Hat OpenShift (ARO)  
**Cost Management Operator Version**: 3.3.2  
**Cluster**: healthcare-ml-demo-cluster
