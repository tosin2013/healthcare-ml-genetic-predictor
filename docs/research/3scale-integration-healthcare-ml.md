# 3scale Integration for Healthcare ML Performance Tracking

## 🎯 **Overview**

Integrating Red Hat 3scale API Management with our healthcare ML genetic predictor provides comprehensive API analytics, security, and cost management capabilities that enhance our RQ2.7 performance benchmarking framework.

## 🏗️ **3scale Architecture for Healthcare ML**

### **API Gateway Configuration**

```yaml
# 3scale APIcast Gateway Configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: healthcare-ml-3scale-config
  namespace: healthcare-ml-demo
data:
  production.lua: |
    -- Healthcare ML API Gateway Configuration
    local healthcare_ml_config = {
      services = {
        {
          id = "genetic-analysis-api",
          backend_version = "1",
          hosts = {"quarkus-websocket-service-healthcare-ml-demo.apps.b9892ub1.eastus.aroapp.io"},
          api_backend = "https://quarkus-websocket-service-healthcare-ml-demo.apps.b9892ub1.eastus.aroapp.io:443",
          error_auth_failed = "Authentication failed",
          error_auth_missing = "Authentication parameters missing",
          auth_failed_status = 403,
          auth_missing_status = 401
        }
      }
    }
    return healthcare_ml_config
```

### **Service Definition**

```yaml
# 3scale Service Configuration for Healthcare ML
apiVersion: capabilities.3scale.net/v1beta1
kind: Product
metadata:
  name: healthcare-ml-genetic-predictor
  namespace: healthcare-ml-demo
spec:
  name: "Healthcare ML Genetic Risk Predictor API"
  systemName: "healthcare-ml-genetic-predictor"
  description: "Real-time genetic risk prediction and analysis API"
  
  # Backend Configuration
  backends:
  - name: "genetic-analysis-backend"
    systemName: "genetic-analysis-backend"
    privateBaseURL: "https://quarkus-websocket-service-healthcare-ml-demo.apps.b9892ub1.eastus.aroapp.io"
    path: "/api"
    
  # Application Plans for Different Healthcare Users
  applicationPlans:
  - name: "research-tier"
    systemName: "research-tier"
    setupFee: "0.00"
    costPerMonth: "0.00"
    limits:
    - period: "minute"
      value: 100
      metricSystemName: "genetic_analysis_requests"
    - period: "day" 
      value: 10000
      metricSystemName: "genetic_analysis_requests"
      
  - name: "clinical-tier"
    systemName: "clinical-tier"
    setupFee: "0.00"
    costPerMonth: "500.00"
    limits:
    - period: "minute"
      value: 1000
      metricSystemName: "genetic_analysis_requests"
    - period: "day"
      value: 100000
      metricSystemName: "genetic_analysis_requests"
      
  - name: "enterprise-tier"
    systemName: "enterprise-tier"
    setupFee: "0.00"
    costPerMonth: "2000.00"
    limits:
    - period: "minute"
      value: 5000
      metricSystemName: "genetic_analysis_requests"
    - period: "day"
      value: 1000000
      metricSystemName: "genetic_analysis_requests"

  # Metrics for Performance Tracking
  metrics:
  - friendlyName: "Genetic Analysis Requests"
    systemName: "genetic_analysis_requests"
    unit: "request"
    description: "Number of genetic analysis API calls"
    
  - friendlyName: "VEP Annotation Requests"
    systemName: "vep_annotation_requests"
    unit: "request"
    description: "Number of VEP annotation processing requests"
    
  - friendlyName: "CloudEvent Processing"
    systemName: "cloudevent_processing"
    unit: "request"
    description: "Number of CloudEvents processed"

  # Mapping Rules for API Endpoints
  mappingRules:
  - httpMethod: "POST"
    pattern: "/api/genetic/analyze"
    metricSystemName: "genetic_analysis_requests"
    increment: 1
    
  - httpMethod: "POST"
    pattern: "/api/genetic/batch"
    metricSystemName: "genetic_analysis_requests"
    increment: 10  # Batch requests count as 10
    
  - httpMethod: "GET"
    pattern: "/api/scaling/health"
    metricSystemName: "health_checks"
    increment: 1
```

## 📊 **Performance Tracking Integration**

### **3scale Analytics Dashboard Configuration**

```yaml
# Custom Analytics Dashboard for Healthcare ML
apiVersion: v1
kind: ConfigMap
metadata:
  name: healthcare-ml-analytics-dashboard
  namespace: healthcare-ml-demo
data:
  dashboard.json: |
    {
      "dashboard": {
        "title": "Healthcare ML API Performance",
        "panels": [
          {
            "title": "Genetic Analysis Request Volume",
            "type": "graph",
            "targets": [
              {
                "expr": "sum(rate(threescale_backend_api_time_seconds_count{service=\"healthcare-ml-genetic-predictor\"}[5m]))",
                "legendFormat": "Requests/sec"
              }
            ]
          },
          {
            "title": "API Response Times (P95)",
            "type": "graph", 
            "targets": [
              {
                "expr": "histogram_quantile(0.95, sum(rate(threescale_backend_api_time_seconds_bucket{service=\"healthcare-ml-genetic-predictor\"}[5m])) by (le))",
                "legendFormat": "P95 Latency"
              }
            ]
          },
          {
            "title": "Error Rate by Endpoint",
            "type": "graph",
            "targets": [
              {
                "expr": "sum(rate(threescale_backend_api_time_seconds_count{service=\"healthcare-ml-genetic-predictor\",code!~\"2..\"}[5m])) by (endpoint)",
                "legendFormat": "{{endpoint}} errors/sec"
              }
            ]
          },
          {
            "title": "Cost Attribution by Application",
            "type": "table",
            "targets": [
              {
                "expr": "sum(threescale_backend_api_time_seconds_count{service=\"healthcare-ml-genetic-predictor\"}) by (application_id)",
                "format": "table"
              }
            ]
          }
        ]
      }
    }
```

### **Enhanced Benchmarking Script with 3scale**

```bash
#!/bin/bash
# Enhanced performance benchmarking with 3scale integration

# 3scale Configuration
THREESCALE_ADMIN_URL="https://healthcare-ml-admin.3scale.net"
THREESCALE_ACCESS_TOKEN="your-3scale-access-token"
API_KEY="your-api-key"

# Enhanced API calls with 3scale tracking
measure_api_with_3scale() {
    local endpoint=$1
    local payload=$2
    local description=$3
    local app_id=$4
    
    echo -e "${YELLOW}📊 Testing with 3scale: $description${NC}"
    
    # Make API call through 3scale gateway
    local response_time=$(curl -w "%{time_total}" -s -o /dev/null \
        -X POST "$API_BASE/$endpoint" \
        -H "Content-Type: application/json" \
        -H "X-API-Key: $API_KEY" \
        -H "X-App-ID: $app_id" \
        -d "$payload")
    
    # Get 3scale analytics
    local analytics=$(curl -s \
        "$THREESCALE_ADMIN_URL/admin/api/analytics/applications/$app_id.json" \
        -H "Authorization: Bearer $THREESCALE_ACCESS_TOKEN")
    
    echo "  Response Time: ${response_time}s"
    echo "  3scale Analytics: $analytics"
    
    log_result "$description" "response_time_3scale" "$response_time" "seconds"
    log_result "$description" "3scale_analytics" "$analytics" "json"
}

# Test different application tiers
test_application_tiers() {
    echo -e "${GREEN}🧪 Testing Different Healthcare Application Tiers${NC}"
    
    # Research Tier (Rate Limited)
    for i in {1..5}; do
        measure_api_with_3scale "genetic/analyze" \
            '{"sequence": "ATCGATCGATCGATCGATCG", "resourceProfile": "standard"}' \
            "research_tier_request_$i" \
            "research-app-001"
        sleep 1
    done
    
    # Clinical Tier (Higher Limits)
    for i in {1..10}; do
        measure_api_with_3scale "genetic/analyze" \
            '{"sequence": "ATCGATCGATCGATCGATCG", "resourceProfile": "standard"}' \
            "clinical_tier_request_$i" \
            "clinical-app-001"
    done
    
    # Enterprise Tier (Highest Limits)
    for i in {1..20}; do
        measure_api_with_3scale "genetic/analyze" \
            '{"sequence": "ATCGATCGATCGATCGATCG", "resourceProfile": "high-memory"}' \
            "enterprise_tier_request_$i" \
            "enterprise-app-001" &
    done
    wait
}
```

## 💰 **Cost Attribution and Billing**

### **Healthcare Department Cost Tracking**

```yaml
# Application Configuration for Different Departments
apiVersion: capabilities.3scale.net/v1alpha1
kind: Application
metadata:
  name: radiology-department
  namespace: healthcare-ml-demo
spec:
  productCR:
    name: healthcare-ml-genetic-predictor
  applicationPlanName: clinical-tier
  name: "Radiology Department - Genetic Analysis"
  description: "Genetic analysis for radiology correlation studies"
  
  # Custom fields for cost attribution
  extraFields:
    department: "radiology"
    cost_center: "RAD-001"
    billing_contact: "radiology-admin@hospital.com"
    project_code: "genetic-imaging-correlation"
---
apiVersion: capabilities.3scale.net/v1alpha1
kind: Application
metadata:
  name: oncology-research
  namespace: healthcare-ml-demo
spec:
  productCR:
    name: healthcare-ml-genetic-predictor
  applicationPlanName: research-tier
  name: "Oncology Research - Genetic Studies"
  description: "Research-grade genetic analysis for oncology studies"
  
  extraFields:
    department: "oncology"
    cost_center: "ONC-RES-001"
    billing_contact: "oncology-research@hospital.com"
    project_code: "cancer-genetics-study"
```

### **Cost Reporting Dashboard**

```sql
-- 3scale Analytics SQL Queries for Cost Attribution
SELECT 
    app.name as application_name,
    app.extra_fields->>'department' as department,
    app.extra_fields->>'cost_center' as cost_center,
    COUNT(t.id) as total_requests,
    SUM(CASE WHEN t.response_code >= 200 AND t.response_code < 300 THEN 1 ELSE 0 END) as successful_requests,
    AVG(t.response_time) as avg_response_time,
    SUM(t.response_time) as total_processing_time
FROM transactions t
JOIN applications app ON t.application_id = app.id
WHERE t.created_at >= NOW() - INTERVAL '30 days'
GROUP BY app.id, app.name, app.extra_fields->>'department', app.extra_fields->>'cost_center'
ORDER BY total_requests DESC;
```

## 🔧 **Implementation Steps**

### **1. Deploy 3scale on OpenShift**
```bash
# Install 3scale Operator
oc apply -f https://raw.githubusercontent.com/3scale/3scale-operator/master/deploy/olm-catalog/3scale-operator/0.8.0/3scale-operator.v0.8.0.clusterserviceversion.yaml

# Create 3scale API Manager
oc new-project 3scale-amp
oc apply -f 3scale-apimanager.yaml
```

### **2. Configure Healthcare ML Service**
```bash
# Apply service configuration
oc apply -f healthcare-ml-3scale-service.yaml

# Configure application plans
oc apply -f healthcare-ml-application-plans.yaml
```

### **3. Set up Analytics and Monitoring**
```bash
# Deploy analytics dashboard
oc apply -f healthcare-ml-analytics-dashboard.yaml

# Configure Prometheus integration
oc apply -f 3scale-prometheus-config.yaml
```

## 📈 **Benefits for Healthcare ML**

### **Performance Insights**
- **Real-time API analytics** with sub-second granularity
- **Cost per genetic analysis** tracking
- **Department-level usage** attribution
- **SLA compliance** monitoring

### **Security and Compliance**
- **API key management** for different healthcare applications
- **Rate limiting** to prevent system overload
- **Audit trails** for regulatory compliance
- **IP whitelisting** for hospital networks

### **Operational Excellence**
- **Capacity planning** based on usage trends
- **Error rate analysis** by endpoint and consumer
- **Performance optimization** insights
- **Cost optimization** recommendations

---

**Status**: 📋 **DESIGN COMPLETE - READY FOR IMPLEMENTATION**  
**Impact**: Enhanced API management, cost tracking, and performance analytics  
**Next Steps**: Deploy 3scale, configure services, integrate with benchmarking framework
