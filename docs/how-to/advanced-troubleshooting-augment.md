# Advanced Troubleshooting Guide - Augment Code Optimized

## 🎯 Augment Code Troubleshooting Strategy

This guide provides advanced troubleshooting techniques specifically optimized for **Augment Code's superior context awareness** and the Healthcare ML Genetic Predictor system.

## 🧠 Context-Aware Debugging with Augment

### Intelligent Issue Diagnosis

#### **Step 1: Context Gathering**
Before debugging, use Augment's context engine to understand the system state:

```bash
# Use these Augment queries for comprehensive context:
"Show me the current WebSocket service deployment status and recent changes"
"Find all KEDA scaling events and their triggers in the last 24 hours"
"Locate error patterns in VEP service logs and their correlation with API failures"
"Show me the Kafka topic lag metrics and consumer group status"
```

#### **Step 2: Pattern Recognition**
Leverage Augment's pattern matching for common issues:

```bash
# Threading Issues
"Find all @Blocking annotations and verify proper worker thread usage"
"Show me event loop blocking patterns in Quarkus reactive code"

# Scaling Issues  
"Locate KEDA ScaledObject configurations and their current metrics"
"Find pod resource constraints and scaling behavior patterns"

# Integration Issues
"Show me Kafka connection configurations and error handling patterns"
"Find VEP API integration points and failure recovery mechanisms"
```

## 🔧 Advanced Debugging Scenarios

### Scenario 1: WebSocket Connection Failures

#### **Symptoms**
- WebSocket connections dropping unexpectedly
- Genetic analysis requests timing out
- Frontend showing connection errors

#### **Augment-Assisted Diagnosis**
```bash
# Query Augment for WebSocket implementation details
"Show me the WebSocket endpoint configuration and session management"
"Find the genetic analysis request handling and response patterns"
"Locate WebSocket error handling and reconnection logic"
```

#### **Investigation Steps**
```bash
# 1. Check WebSocket service health
oc get pods -l app=quarkus-websocket-service
oc logs -f deployment/quarkus-websocket-service --tail=100

# 2. Verify route configuration
oc get route quarkus-websocket-service -o yaml
oc describe route quarkus-websocket-service

# 3. Check service endpoints
oc get endpoints quarkus-websocket-service
oc describe service quarkus-websocket-service

# 4. Test WebSocket connectivity
curl -I https://$(oc get route quarkus-websocket-service -o jsonpath='{.spec.host}')/q/health
```

#### **Common Root Causes & Solutions**

**Threading Issues (Event Loop Blocking)**

````java
@ServerEndpoint("/genetic-predictor")
public class GeneticPredictorEndpoint {
    
    @OnMessage
    public void onMessage(String message, Session session) {
        // ❌ WRONG: This blocks the event loop
        // geneticAnalysisService.processSequence(message);
        
        // ✅ CORRECT: Use async processing
        CompletableFuture.runAsync(() -> {
            geneticAnalysisService.processSequence(message, session);
        });
    }
}
````


**Solution**: Ensure all WebSocket message processing is asynchronous.

### Scenario 2: KEDA Scaling Not Triggering

#### **Symptoms**
- Pods not scaling despite Kafka lag
- Node scaling not occurring for large workloads
- Cost management showing unexpected resource usage

#### **Augment-Assisted Diagnosis**
```bash
# Use Augment to understand KEDA configuration
"Show me all KEDA ScaledObject definitions and their trigger conditions"
"Find the Kafka topic configurations and consumer group settings"
"Locate the node affinity rules and cluster autoscaler configuration"
```

#### **Investigation Steps**
```bash
# 1. Check KEDA operator status
oc get pods -n openshift-keda
oc logs -n openshift-keda deployment/keda-operator

# 2. Verify ScaledObject status
oc get scaledobject -n healthcare-ml-demo
oc describe scaledobject vep-service-scaler -n healthcare-ml-demo

# 3. Check HPA created by KEDA
oc get hpa -n healthcare-ml-demo
oc describe hpa keda-hpa-vep-service-scaler -n healthcare-ml-demo

# 4. Verify Kafka metrics
oc exec -it genetic-data-cluster-kafka-0 -- bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 --describe --group vep-service-group
```

#### **Common Root Causes & Solutions**

**Incorrect Kafka Topic Configuration**

````yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: vep-service-scaler
spec:
  scaleTargetRef:
    name: vep-service
  triggers:
  - type: kafka
    metadata:
      bootstrapServers: genetic-data-cluster-kafka-bootstrap:9092
      consumerGroup: vep-service-group
      topic: genetic-data-raw  # ✅ Ensure correct topic name
      lagThreshold: '5'        # ✅ Appropriate threshold
````


**Solution**: Verify topic names match between Kafka configuration and KEDA triggers.

### Scenario 3: VEP Service API Integration Failures

#### **Symptoms**
- Genetic sequences not being annotated
- VEP service returning 500 errors
- Kafka messages accumulating without processing

#### **Augment-Assisted Diagnosis**
```bash
# Query Augment for VEP integration patterns
"Show me the VEP service API integration and error handling"
"Find the Ensembl VEP API request/response patterns"
"Locate the genetic sequence validation and processing logic"
```

#### **Investigation Steps**
```bash
# 1. Check VEP service health
oc get pods -l app=vep-service
oc logs -f deployment/vep-service --tail=100

# 2. Test VEP API connectivity
oc exec -it deployment/vep-service -- curl -I https://rest.ensembl.org/info/ping

# 3. Check Kafka message consumption
oc exec -it genetic-data-cluster-kafka-0 -- bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 --topic genetic-data-raw --from-beginning

# 4. Verify service configuration
oc get configmap vep-service-config -o yaml
```

#### **Common Root Causes & Solutions**

**API Rate Limiting**

````java
@ApplicationScoped
public class VepApiService {
    
    @ConfigProperty(name = "vep.api.rate.limit.delay", defaultValue = "1000")
    int rateLimitDelay;
    
    @Retry(maxRetries = 3, delay = 2000)
    @Fallback(fallbackMethod = "fallbackVepAnnotation")
    public VepAnnotation annotateSequence(String sequence) {
        // Add rate limiting
        Thread.sleep(rateLimitDelay);
        return vepClient.annotate(sequence);
    }
    
    public VepAnnotation fallbackVepAnnotation(String sequence) {
        // Return cached or simplified annotation
        return VepAnnotation.createFallback(sequence);
    }
}
````


**Solution**: Implement proper rate limiting and fallback mechanisms.

## 🚨 Emergency Response Procedures

### Critical System Failure

#### **Immediate Actions**
```bash
# 1. Check overall system health
./scripts/validate-demo-readiness.sh

# 2. Scale down to prevent resource exhaustion
oc scale deployment quarkus-websocket-service --replicas=1
oc scale deployment vep-service --replicas=1

# 3. Check resource constraints
oc describe nodes | grep -A 5 "Allocated resources"
oc get events --sort-by='.lastTimestamp' | tail -20
```

#### **Recovery Steps**
```bash
# 1. Restart core services
oc rollout restart deployment/quarkus-websocket-service
oc rollout restart deployment/vep-service

# 2. Clear Kafka lag if needed
oc exec -it genetic-data-cluster-kafka-0 -- bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 --reset-offsets --to-latest \
  --group vep-service-group --topic genetic-data-raw --execute

# 3. Verify system recovery
./scripts/test-api-endpoints.sh
```

## 📊 Performance Debugging

### Memory and CPU Analysis

#### **Resource Monitoring**
```bash
# Check pod resource usage
oc top pods -n healthcare-ml-demo

# Monitor resource trends
oc adm top pods --containers -n healthcare-ml-demo

# Check node resource allocation
oc describe nodes | grep -A 10 "Allocated resources"
```

#### **JVM Performance Analysis**
```bash
# Enable JVM debugging (add to deployment)
env:
  - name: JAVA_OPTS
    value: "-XX:+PrintGCDetails -XX:+PrintGCTimeStamps -Xloggc:/tmp/gc.log"

# Analyze GC logs
oc exec -it deployment/vep-service -- cat /tmp/gc.log
```

### Network Connectivity Issues

#### **Service Mesh Analysis**
```bash
# Check service connectivity
oc exec -it deployment/quarkus-websocket-service -- \
  curl -I http://genetic-data-cluster-kafka-bootstrap:9092

# Verify DNS resolution
oc exec -it deployment/vep-service -- \
  nslookup genetic-data-cluster-kafka-bootstrap.healthcare-ml-demo.svc.cluster.local
```

## 🔍 Augment Code Debugging Queries

### System-Wide Analysis
```bash
# Complete system health check
"Show me the health status of all services and their dependencies"
"Find all error patterns across WebSocket, VEP, and Kafka components"
"Locate performance bottlenecks in the genetic analysis pipeline"

# Configuration validation
"Show me all environment-specific configurations and their differences"
"Find security context constraints and RBAC configurations"
"Locate cost management labels and their consistency across resources"

# Integration analysis
"Show me the complete data flow from WebSocket to VEP API and back"
"Find all Kafka topic configurations and consumer group mappings"
"Locate KEDA scaling triggers and their current metric values"
```

### Code-Level Debugging
```bash
# Threading and performance
"Find all blocking operations and verify they use @Blocking annotation"
"Show me async processing patterns and their error handling"
"Locate resource allocation patterns and memory usage optimization"

# Error handling
"Find all exception handling patterns and their consistency"
"Show me retry mechanisms and circuit breaker implementations"
"Locate logging patterns and their correlation with monitoring metrics"
```

---

**🎯 This advanced troubleshooting guide leverages Augment Code's superior context awareness for efficient problem resolution in healthcare ML environments!**
