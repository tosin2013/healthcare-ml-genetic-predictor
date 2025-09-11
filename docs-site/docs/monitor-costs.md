# Monitor Costs - Healthcare ML System

## 🎯 Overview

This guide shows how to monitor and manage costs for the Healthcare ML Genetic Predictor system using Red Hat Insights Cost Management and OpenShift native tools.

## 💰 Current Cost Management Setup

### Verify Cost Management Operator

```bash
# Check cost management operator status
oc get operators -A | grep cost

# Expected output:
# costmanagement-metrics-operator.costmanagement-metrics-operator   3d21h

# Check cost management pods
oc get pods -n costmanagement-metrics-operator
```

### Cost Attribution Labels

```bash
# Verify cost labels on healthcare ML resources
oc get pods -n healthcare-ml-demo --show-labels | grep -E "(cost-center|project)"

# Check deployment labels
oc get deployment quarkus-websocket-service -n healthcare-ml-demo -o yaml | grep -A 5 labels

# Expected labels:
# cost-center: "genomics-research"
# project: "risk-predictor-v1"
```

## 📊 Cost Monitoring Commands

### Resource Usage Analysis

```bash
# Check current resource consumption
oc top pods -n healthcare-ml-demo

# Monitor resource usage over time
oc top nodes

# Check resource requests vs limits
oc describe deployment quarkus-websocket-service -n healthcare-ml-demo | grep -A 10 "Limits\|Requests"
oc describe deployment vep-service -n healthcare-ml-demo | grep -A 10 "Limits\|Requests"
```

### Cost Attribution Reports

The healthcare ML system includes an automated cost attribution report that runs daily via CronJob. This report provides comprehensive cost analysis across workload types and node pools.

#### Configuration and Setup

The cost attribution report is configured in `k8s/overlays/environments/demo/cost-management-config.yaml`:

```bash
# Verify the CronJob is deployed
oc get cronjob cost-attribution-report -n healthcare-ml-demo

# Check CronJob schedule (daily at 6 AM UTC)
oc describe cronjob cost-attribution-report -n healthcare-ml-demo | grep Schedule

# Verify ServiceAccount and RBAC permissions
oc get serviceaccount cost-reporter -n healthcare-ml-demo
oc get clusterrole cost-reporter
oc get clusterrolebinding cost-reporter
```

#### Manual Execution

You can trigger the cost attribution report manually for immediate analysis:

```bash
# Create a manual job from the CronJob
oc create job cost-attribution-manual-$(date +%Y%m%d-%H%M) \
  --from=cronjob/cost-attribution-report -n healthcare-ml-demo

# Monitor job execution
oc get jobs -n healthcare-ml-demo | grep cost-attribution

# View job logs (replace with actual job name)
oc logs job/cost-attribution-manual-$(date +%Y%m%d-%H%M) -n healthcare-ml-demo

# Alternative: View logs from CronJob execution
oc logs job/cost-attribution-report-$(date +%Y%m%d) -n healthcare-ml-demo
```

#### Report Content Analysis

The cost attribution report includes:

1. **Resource Usage by Workload Type**: Compute-intensive vs standard workloads
2. **Node Scaling Events**: Recent scaling activities and machine creation
3. **Cost Attribution Summary**: Node cost center assignments and billing models

```bash
# View recent report output
LATEST_JOB=$(oc get jobs -n healthcare-ml-demo -l job-name=cost-attribution-report --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}')
oc logs job/$LATEST_JOB -n healthcare-ml-demo

# Check for failed jobs
oc get jobs -n healthcare-ml-demo -l job-name=cost-attribution-report --field-selector status.successful!=1

# View job history
oc get jobs -n healthcare-ml-demo | grep cost-attribution | head -10
```

#### Troubleshooting Cost Attribution Reports

If you encounter issues with the cost attribution report, here are common problems and solutions:

**Problem 1: "jq: command not found" Error**
```bash
# This error was fixed in the latest version
# The script now uses oc custom-columns instead of jq
# Verify the fix by checking the CronJob configuration:
oc get cronjob cost-attribution-report -n healthcare-ml-demo -o yaml | grep -A 20 "command:"
```

**Problem 2: "unknown flag: --since" Error**
```bash
# This error was fixed by replacing --since with --sort-by
# The script now uses proper event filtering:
# oc get events --field-selector reason=ScalingReplicaSet --sort-by='.lastTimestamp' --no-headers | tail -10
```

**Problem 3: "No resources found" Errors**
```bash
# Fixed with proper label selectors and fallback handling
# Check if nodes have proper cost attribution labels:
oc get nodes -o custom-columns="NAME:.metadata.name,WORKLOAD-TYPE:.metadata.labels.workload-type,COST-CENTER:.metadata.labels.cost-center"

# If nodes lack labels, apply them:
# See: scripts/label-existing-nodes.sh
```

**Problem 4: Job Fails to Execute**
```bash
# Check ServiceAccount permissions
oc auth can-i get pods --as=system:serviceaccount:healthcare-ml-demo:cost-reporter
oc auth can-i get nodes --as=system:serviceaccount:healthcare-ml-demo:cost-reporter
oc auth can-i get events --as=system:serviceaccount:healthcare-ml-demo:cost-reporter

# Check job status and events
oc describe job $LATEST_JOB -n healthcare-ml-demo
oc get events -n healthcare-ml-demo | grep cost-attribution
```

#### Reference Links

- **Cost Management Configuration**: [`k8s/overlays/environments/demo/cost-management-config.yaml`](../../k8s/overlays/environments/demo/cost-management-config.yaml)
- **Working Cost Attribution Script**: [`scripts/show-cost-attribution.sh`](../../scripts/show-cost-attribution.sh)
- **Node Labeling Strategy**: [`k8s/base/node-management/node-labeling-strategy.yaml`](../../k8s/base/node-management/node-labeling-strategy.yaml)
- **Red Hat Cost Management Setup**: [`scripts/setup-redhat-cost-management-official.sh`](../../scripts/setup-redhat-cost-management-official.sh)

### Kafka Resource Monitoring

```bash
# Monitor Kafka cluster resource usage
oc top pods -n healthcare-ml-demo | grep genetic-data-cluster

# Check Kafka storage usage
oc get pvc -n healthcare-ml-demo | grep kafka

# Monitor Kafka topic retention and size
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-log-dirs.sh --bootstrap-server localhost:9092 --describe
```

## 🔍 Cost Analysis by Component

### WebSocket Service Costs

```bash
# Monitor WebSocket service resource usage
oc top pods -l app=quarkus-websocket-service -n healthcare-ml-demo

# Check scaling behavior impact on costs
oc get scaledobject websocket-service-scaler -n healthcare-ml-demo -o yaml | grep -A 5 "minReplicaCount\|maxReplicaCount"

# Calculate cost per genetic analysis session
echo "Current WebSocket replicas:"
oc get deployment quarkus-websocket-service -n healthcare-ml-demo -o jsonpath='{.status.replicas}'
```

### VEP Service Costs

```bash
# Monitor VEP service scaling and costs
oc get deployment vep-service -n healthcare-ml-demo
oc get deployment vep-service-nodescale -n healthcare-ml-demo

# Check KEDA scaling events for cost impact
oc get events -n healthcare-ml-demo | grep -E "(vep-service|Scaled)"

# Monitor VEP processing efficiency
oc describe scaledobject vep-service-scaler -n healthcare-ml-demo | grep -A 10 "Current Metrics"
```

### Kafka Infrastructure Costs

```bash
# Monitor Kafka cluster resource allocation
oc get kafka genetic-data-cluster -n healthcare-ml-demo -o yaml | grep -A 10 resources

# Check Kafka topic storage costs
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-topics.sh --bootstrap-server localhost:9092 --describe

# Monitor message retention costs
oc get kafkatopic -n healthcare-ml-demo -o yaml | grep -E "(retention|segment)"
```

## 📈 Cost Optimization Strategies

### Scale-to-Zero Optimization

```bash
# Verify VEP service can scale to zero
oc get scaledobject vep-service-scaler -n healthcare-ml-demo -o yaml | grep minReplicaCount

# Monitor zero-scaling effectiveness
oc get deployment vep-service -n healthcare-ml-demo -w

# Check idle time vs active time ratio
oc get events -n healthcare-ml-demo | grep -E "(ScaledUp|ScaledDown)" | tail -20
```

### Resource Right-Sizing

```bash
# Analyze actual vs requested resources
oc top pods -n healthcare-ml-demo --containers

# Check for over-provisioned resources
oc describe nodes | grep -A 10 "Allocated resources"

# Optimize resource requests based on usage
oc adm top pods -n healthcare-ml-demo --sort-by=memory
oc adm top pods -n healthcare-ml-demo --sort-by=cpu
```

### Kafka Topic Optimization

```bash
# Review topic retention policies for cost optimization
oc get kafkatopic genetic-data-raw -n healthcare-ml-demo -o yaml | grep -A 5 config

# Optimize partition count based on throughput
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic genetic-data-raw

# Monitor topic size growth
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-log-dirs.sh --bootstrap-server localhost:9092 --describe | grep size
```

## 🎯 Cost Management Best Practices

### Automated Cost Monitoring

```bash
# Set up cost monitoring alerts (example script)
cat > scripts/cost-monitoring.sh << 'EOF'
#!/bin/bash
echo "🔍 Healthcare ML Cost Monitoring Report"
echo "======================================"

# Resource usage summary
echo "📊 Current Resource Usage:"
oc top pods -n healthcare-ml-demo

# Scaling status
echo "⚡ KEDA Scaling Status:"
oc get scaledobjects -n healthcare-ml-demo

# Cost attribution
echo "💰 Cost Attribution:"
oc get pods -n healthcare-ml-demo --show-labels | grep -E "(cost-center|project)"

# Kafka efficiency
echo "📨 Kafka Topic Efficiency:"
oc get kafkatopics -n healthcare-ml-demo
EOF

chmod +x scripts/cost-monitoring.sh
```

### Resource Cleanup Automation

```bash
# Create cleanup script for completed jobs
cat > scripts/cleanup-cost-jobs.sh << 'EOF'
#!/bin/bash
echo "🧹 Cleaning up completed cost attribution jobs..."

# Remove completed cost attribution jobs older than 7 days
oc get jobs -n healthcare-ml-demo | grep cost-attribution-report | \
  awk '$3=="1/1" && $4 ~ /[7-9]d|[1-9][0-9]d/ {print $1}' | \
  xargs -r oc delete job -n healthcare-ml-demo

echo "✅ Cleanup completed"
EOF

chmod +x scripts/cleanup-cost-jobs.sh
```

## 📊 Red Hat Insights Integration

### Cost Management Dashboard Access

The healthcare ML system integrates with Red Hat Insights Cost Management for comprehensive cost visibility and chargeback reporting.

```bash
# Get cluster ID for Red Hat Insights
CLUSTER_ID=$(oc get clusterversion version -o jsonpath='{.spec.clusterID}')
echo "Cluster ID: $CLUSTER_ID"

# Verify cost management metrics collection
oc get pods -n costmanagement-metrics-operator

# Check cost management configuration
oc get costmanagementmetricsconfig -A

# Verify cost management metrics config for healthcare ML
oc describe costmanagementmetricsconfig healthcare-ml-demo-cost-config -n costmanagement-metrics-operator
```

### Cost Center Attribution

The system uses structured cost attribution for accurate chargeback:

```bash
# View cost center assignments
echo "📊 Cost Center Breakdown:"
echo "  📋 genomics-research: Standard workload nodes (normal/bigdata VEP processing)"
echo "  ⚡ genomics-research-demo: Compute-intensive nodes (node scaling demo)"

# Check node cost attribution
oc get nodes -o custom-columns="NAME:.metadata.name,WORKLOAD-TYPE:.metadata.labels.workload-type,COST-CENTER:.metadata.labels.cost-center,BILLING-MODEL:.metadata.labels.billing-model"

# Verify Red Hat Insights annotations
oc get nodes -o yaml | grep -A 5 "insights.openshift.io"
```

### Access Red Hat Cost Management Console

1. **Red Hat Hybrid Cloud Console**: https://console.redhat.com/openshift/cost-management
   - Filter by Project: `healthcare-ml-demo`
   - Cost Center: `genomics-research` or `genomics-research-demo`

2. **OpenShift Web Console**:
   ```bash
   # Get console URL
   oc whoami --show-console
   # Navigate to: Administration → Cluster Settings → Insights
   ```

3. **Cost Attribution Labels Used**:
   - `cost-center: genomics-research` (standard nodes)
   - `cost-center: genomics-research-demo` (compute-intensive nodes)
   - `billing-model: chargeback`
   - `project: healthcare-ml-demo`

### Cost Data Export

```bash
# Export cost data for analysis (using oc native commands, no jq required)
echo "💰 Healthcare ML Resource Analysis"
echo "=================================="

# Pod resource allocation
oc get pods -n healthcare-ml-demo -o custom-columns="NAME:.metadata.name,CPU-REQUEST:.spec.containers[0].resources.requests.cpu,MEMORY-REQUEST:.spec.containers[0].resources.requests.memory,COST-CENTER:.metadata.labels.cost-center"

# Node cost attribution
oc get nodes -o custom-columns="NAME:.metadata.name,WORKLOAD-TYPE:.metadata.labels.workload-type,COST-CENTER:.metadata.labels.cost-center,INSTANCE-TYPE:.metadata.labels.node\.kubernetes\.io/instance-type"

# Generate comprehensive cost report
cat > scripts/generate-cost-report.sh << 'EOF'
#!/bin/bash
echo "💰 Healthcare ML Cost Report - $(date)"
echo "========================================="

echo "🏷️  Cost Attribution by Resource:"
echo "Pods with Cost Centers:"
oc get pods -n healthcare-ml-demo -o custom-columns="NAME:.metadata.name,COST-CENTER:.metadata.labels.cost-center,PROJECT:.metadata.labels.project" --no-headers | grep -v "<none>"

echo ""
echo "Deployments with Cost Centers:"
oc get deployments -n healthcare-ml-demo -o custom-columns="NAME:.metadata.name,COST-CENTER:.metadata.labels.cost-center,PROJECT:.metadata.labels.project" --no-headers | grep -v "<none>"

echo ""
echo "📊 Resource Utilization:"
oc top pods -n healthcare-ml-demo 2>/dev/null || echo "Metrics not available"

echo ""
echo "⚡ Scaling Efficiency:"
oc get scaledobjects -n healthcare-ml-demo -o custom-columns=NAME:.metadata.name,MIN:.spec.minReplicaCount,MAX:.spec.maxReplicaCount,CURRENT:.status.currentReplicas 2>/dev/null || echo "No ScaledObjects found"

echo ""
echo "🏗️  Node Cost Attribution:"
oc get nodes -o custom-columns="NAME:.metadata.name,WORKLOAD-TYPE:.metadata.labels.workload-type,COST-CENTER:.metadata.labels.cost-center" --no-headers | grep -v "<none>" || echo "No cost-attributed nodes found"

echo ""
echo "📈 Recent Scaling Events:"
oc get events --field-selector reason=ScalingReplicaSet --sort-by='.lastTimestamp' --no-headers 2>/dev/null | tail -5 || echo "No scaling events found"
EOF

chmod +x scripts/generate-cost-report.sh
```

## 🚨 Cost Alerts and Thresholds

### Resource Usage Monitoring

```bash
# Monitor for cost spikes
cat > scripts/cost-alert-check.sh << 'EOF'
#!/bin/bash
# Check for unexpected resource usage spikes

MAX_REPLICAS_THRESHOLD=5
CURRENT_WEBSOCKET_REPLICAS=$(oc get deployment quarkus-websocket-service -n healthcare-ml-demo -o jsonpath='{.status.replicas}')
CURRENT_VEP_REPLICAS=$(oc get deployment vep-service -n healthcare-ml-demo -o jsonpath='{.status.replicas}')

if [ "$CURRENT_WEBSOCKET_REPLICAS" -gt "$MAX_REPLICAS_THRESHOLD" ]; then
  echo "🚨 ALERT: WebSocket service scaled to $CURRENT_WEBSOCKET_REPLICAS replicas (threshold: $MAX_REPLICAS_THRESHOLD)"
fi

if [ "$CURRENT_VEP_REPLICAS" -gt "$MAX_REPLICAS_THRESHOLD" ]; then
  echo "🚨 ALERT: VEP service scaled to $CURRENT_VEP_REPLICAS replicas (threshold: $MAX_REPLICAS_THRESHOLD)"
fi
EOF

chmod +x scripts/cost-alert-check.sh
```

### Kafka Cost Monitoring

```bash
# Monitor Kafka storage growth
cat > scripts/kafka-cost-monitor.sh << 'EOF'
#!/bin/bash
echo "📊 Kafka Cost Monitoring"

# Check topic sizes
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-log-dirs.sh --bootstrap-server localhost:9092 --describe | \
  grep -E "(topic|size)" | head -20

# Check retention effectiveness
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-topics.sh --bootstrap-server localhost:9092 --describe | \
  grep -E "(Topic|retention)"
EOF

chmod +x scripts/kafka-cost-monitor.sh
```

## 🎯 Cost Optimization Results

### Expected Cost Savings

- **Scale-to-Zero**: 60-80% cost reduction during idle periods
- **Right-Sizing**: 20-30% reduction in over-provisioned resources  
- **Kafka Optimization**: 15-25% reduction in storage costs
- **Automated Cleanup**: 10-15% reduction in accumulated job costs

### Monitoring Schedule

The healthcare ML system includes automated cost monitoring with the following schedule:

```bash
# Automated Cost Attribution Report (CronJob)
# Schedule: Daily at 6:00 AM UTC
# Configured in: k8s/overlays/environments/demo/cost-management-config.yaml
oc get cronjob cost-attribution-report -n healthcare-ml-demo

# Additional monitoring scripts (add to crontab if needed)
# 0 8 * * * /path/to/scripts/cost-monitoring.sh          # Daily cost summary
# 0 0 * * 0 /path/to/scripts/cleanup-cost-jobs.sh        # Weekly cleanup
# */15 * * * * /path/to/scripts/cost-alert-check.sh      # Real-time alerts
```

### Quick Reference Commands

```bash
# Manual cost attribution report
oc create job cost-attribution-manual-$(date +%Y%m%d-%H%M) --from=cronjob/cost-attribution-report -n healthcare-ml-demo

# View latest report
LATEST_JOB=$(oc get jobs -n healthcare-ml-demo -l job-name=cost-attribution-report --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}')
oc logs job/$LATEST_JOB -n healthcare-ml-demo

# Check cost attribution status
./scripts/show-cost-attribution.sh

# Generate comprehensive cost report
./scripts/generate-cost-report.sh
```

---

**💰 This enhanced cost monitoring setup provides comprehensive visibility into healthcare ML infrastructure costs with automated reporting, Red Hat Insights integration, and real-time cost attribution across genomics research workloads!**

**🔧 Recent Improvements:**
- ✅ Fixed jq dependency issues in cost attribution reports
- ✅ Corrected event querying syntax for proper scaling event tracking
- ✅ Enhanced resource discovery with robust fallback handling
- ✅ Added comprehensive cost center attribution for chargeback accuracy
- ✅ Integrated with Red Hat Cost Management Metrics Operator
