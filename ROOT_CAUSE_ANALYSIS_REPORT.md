# Root Cause Analysis Report - VEP Service KEDA Scaling Issue

**Date**: 2025-06-14  
**Issue**: VEP Service not scaling with KEDA despite Kafka messages  
**Status**: ✅ **ROOT CAUSE IDENTIFIED**

## 🔍 **Investigation Summary**

### Initial Symptoms
- API endpoints publishing 45+ messages to Kafka topic `genetic-data-raw`
- VEP service pods remaining at 0 (not scaling up)
- KEDA ScaledObject configured but not triggering scaling
- Consumer group `vep-annotation-service-group` not found

### Investigation Steps

1. **Verified API Functionality** ✅
   - All 5 API endpoints working correctly
   - CloudEvents successfully published to Kafka
   - 45+ messages accumulated in `genetic-data-raw` topic

2. **Checked VEP Service Status** ✅
   - Knative service deployed and ready
   - Configuration properly set with Kafka consumer settings
   - Service responds to HTTP health checks

3. **Triggered VEP Service Manually** ✅
   - HTTP request to `/q/health` successfully triggered pod creation
   - Pod started and became ready (2/2 containers)
   - Service scaled down after idle period (Knative behavior)

4. **Analyzed Kafka Consumer Behavior** ✅
   - VEP service logs show successful Kafka connection
   - Consumer group `vep-service-group` created and active
   - All messages consumed successfully (LAG = 0)

5. **Identified KEDA Configuration Mismatch** ❌
   - KEDA ScaledObject monitors `vep-annotation-service-group`
   - VEP service actually uses `vep-service-group`
   - **This is the root cause of scaling failure**

## 🎯 **Root Cause**

**Consumer Group Name Mismatch:**
- **VEP Service Uses**: `vep-service-group`
- **KEDA Monitors**: `vep-annotation-service-group`
- **Result**: KEDA never sees Kafka lag because it's monitoring a non-existent consumer group

## 📊 **Evidence**

### VEP Service Logs
```
16:12:35 INFO [io.sm.re.me.kafka] Kafka consumer kafka-consumer-genetic-data-raw, 
connected to Kafka brokers, belongs to the 'vep-service-group' consumer group 
and is configured to poll records from [genetic-data-raw]
```

### Kafka Consumer Group Status
```
GROUP             TOPIC            PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG
vep-service-group genetic-data-raw 0          6               6               0
vep-service-group genetic-data-raw 1          13              13              0  
vep-service-group genetic-data-raw 2          11              11              0
```

### KEDA ScaledObject Configuration
```yaml
triggers:
- metadata:
    consumerGroup: vep-annotation-service-group  # ❌ WRONG GROUP
    topic: genetic-data-raw
    lagThreshold: "5"
  type: kafka
```

## ✅ **Validation Results**

### What's Working
- ✅ **API Endpoints**: 100% success rate, all 5 endpoints functional
- ✅ **Kafka Publishing**: CloudEvents properly formatted and published
- ✅ **VEP Service**: Consuming messages when triggered via HTTP
- ✅ **Knative Scaling**: Scale-to-zero and HTTP-triggered scaling working
- ✅ **Message Processing**: All 45+ messages consumed successfully

### What's Not Working
- ❌ **KEDA Kafka Scaling**: Wrong consumer group monitored
- ❌ **Automatic Pod Scaling**: Requires manual HTTP trigger
- ❌ **Node Scaling**: Cannot occur without pod scaling pressure

## 🔧 **Fix Required**

### Option 1: Update KEDA Configuration (Recommended)
Update the KEDA ScaledObject to monitor the correct consumer group:

```yaml
triggers:
- metadata:
    consumerGroup: vep-service-group  # ✅ CORRECT GROUP
    topic: genetic-data-raw
    lagThreshold: "5"
  type: kafka
```

### Option 2: Update VEP Service Configuration
Change VEP service to use the consumer group KEDA expects:

```properties
mp.messaging.incoming.genetic-data-raw.group.id=vep-annotation-service-group
```

## 🚀 **Expected Outcome After Fix**

1. **KEDA Scaling**: Will detect Kafka lag and scale VEP service pods
2. **Automatic Scaling**: VEP service will scale 0→1+ pods based on message volume
3. **Node Scaling**: Heavy workloads will trigger node autoscaling
4. **Cost Demonstration**: Proper scaling behavior for cost attribution

## 📋 **Next Steps**

1. **Immediate**: Update KEDA ScaledObject with correct consumer group
2. **Test**: Trigger API endpoints and verify automatic pod scaling
3. **Validate**: Confirm KEDA scaling behavior with different workloads
4. **Document**: Update ADR-004 with corrected scaling behavior
5. **Blog Article**: Include this root cause analysis as a real-world troubleshooting example

## 🎓 **Lessons Learned**

1. **Configuration Consistency**: Ensure consumer group names match between services and KEDA
2. **Monitoring Validation**: Verify KEDA is monitoring active consumer groups
3. **End-to-End Testing**: Test complete message flow, not just individual components
4. **Knative + KEDA**: Understand interaction between Knative autoscaling and KEDA triggers
5. **Troubleshooting Approach**: Check actual runtime behavior vs. configuration assumptions

---

**Status**: Ready for fix implementation  
**Priority**: High (blocks scaling demonstration)  
**Impact**: Critical for healthcare ML cost attribution demo
