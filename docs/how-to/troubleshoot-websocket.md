# Troubleshoot WebSocket Issues - Healthcare ML System

## 🎯 Overview

This guide provides troubleshooting techniques for WebSocket connection issues in the Healthcare ML Genetic Predictor system, based on the current OpenShift deployment.

## 🔍 Current WebSocket Service Status

### Verify Service Health

```bash
# Check WebSocket service status
oc get deployment quarkus-websocket-service -n healthcare-ml-demo

# Expected output:
# NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
# quarkus-websocket-service   1/1     1            1           2d9h

# Check pod status
oc get pods -l app=quarkus-websocket-service -n healthcare-ml-demo

# Check service endpoint
oc get svc quarkus-websocket-service -n healthcare-ml-demo
```

### Test WebSocket Connectivity

```bash
# Get the route URL
WEBSOCKET_URL=$(oc get route quarkus-websocket-service -n healthcare-ml-demo -o jsonpath='{.spec.host}')
echo "WebSocket URL: https://$WEBSOCKET_URL"

# Test health endpoint
curl -k https://$WEBSOCKET_URL/q/health

# Expected response:
# {"status":"UP","checks":[...]}
```

## 🚨 Common WebSocket Issues

### Issue 1: Connection Refused

#### **Symptoms**
- WebSocket connection fails immediately
- Browser shows "Connection refused" or "WebSocket connection failed"
- Frontend cannot establish initial connection

#### **Diagnosis**
```bash
# Check if pods are running
oc get pods -l app=quarkus-websocket-service -n healthcare-ml-demo

# Check pod logs for startup errors
oc logs -f deployment/quarkus-websocket-service -n healthcare-ml-demo

# Verify route configuration
oc describe route quarkus-websocket-service -n healthcare-ml-demo
```

#### **Solutions**
```bash
# Restart the deployment if pods are failing
oc rollout restart deployment/quarkus-websocket-service -n healthcare-ml-demo

# Check for resource constraints
oc describe pod -l app=quarkus-websocket-service -n healthcare-ml-demo | grep -A 5 "Limits\|Requests"

# Verify service selector matches pod labels
oc get svc quarkus-websocket-service -n healthcare-ml-demo -o yaml | grep -A 5 selector
oc get pods -l app=quarkus-websocket-service -n healthcare-ml-demo --show-labels
```

### Issue 2: Connection Drops During Genetic Analysis

#### **Symptoms**
- WebSocket connects initially but drops during processing
- Genetic analysis requests timeout
- Intermittent connection losses

#### **Diagnosis**
```bash
# Check for threading issues in logs
oc logs deployment/quarkus-websocket-service -n healthcare-ml-demo | grep -E "(blocking|thread|timeout)"

# Monitor resource usage
oc top pods -l app=quarkus-websocket-service -n healthcare-ml-demo

# Check Kafka connectivity
oc logs deployment/quarkus-websocket-service -n healthcare-ml-demo | grep -E "(kafka|genetic-data)"
```

#### **Solutions**

**Threading Fix (Critical for Quarkus)**
<augment_code_snippet path="quarkus-websocket-service/src/main/java/com/healthcare/ml/websocket/GeneticPredictorEndpoint.java" mode="EXCERPT">
````java
@ServerEndpoint("/genetic-predictor")
public class GeneticPredictorEndpoint {
    
    @OnMessage
    public void onMessage(String message, Session session) {
        // ✅ CORRECT: Use async processing to avoid blocking
        CompletableFuture.runAsync(() -> {
            try {
                geneticAnalysisService.processSequence(message, session);
            } catch (Exception e) {
                sendErrorToSession(session, e.getMessage());
            }
        });
    }
}
````
</augment_code_snippet>

**Resource Adjustment**
```bash
# Increase memory limits if needed
oc patch deployment quarkus-websocket-service -n healthcare-ml-demo --type='merge' -p='
{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "quarkus-websocket-service",
          "resources": {
            "limits": {
              "memory": "1Gi",
              "cpu": "500m"
            },
            "requests": {
              "memory": "512Mi",
              "cpu": "250m"
            }
          }
        }]
      }
    }
  }
}'
```

### Issue 3: Kafka Integration Problems

#### **Symptoms**
- WebSocket connects but genetic analysis never completes
- No results returned from VEP service
- Messages stuck in Kafka topics

#### **Diagnosis**
```bash
# Check Kafka topic status
oc get kafkatopics -n healthcare-ml-demo

# Verify message flow
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 \
  --topic genetic-data-raw --from-beginning --max-messages 5

# Check consumer group lag
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --describe --group websocket-results-service-group
```

#### **Solutions**
```bash
# Reset consumer group if stuck
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --reset-offsets --to-latest --group websocket-results-service-group \
  --topic genetic-data-processed --execute

# Restart WebSocket service to reconnect to Kafka
oc rollout restart deployment/quarkus-websocket-service -n healthcare-ml-demo
```

## 🔧 Advanced Troubleshooting

### WebSocket Session Management

#### **Check Active Sessions**
```bash
# Look for session-related logs
oc logs deployment/quarkus-websocket-service -n healthcare-ml-demo | grep -E "(session|connect|disconnect)"

# Monitor WebSocket endpoint metrics
curl -k https://$WEBSOCKET_URL/q/metrics | grep websocket
```

#### **Session Cleanup Issues**
```bash
# Check for memory leaks in session management
oc exec -it deployment/quarkus-websocket-service -n healthcare-ml-demo -- \
  jcmd 1 GC.run_finalization

# Monitor heap usage
oc exec -it deployment/quarkus-websocket-service -n healthcare-ml-demo -- \
  jcmd 1 VM.memory_summary
```

### Network and Route Issues

#### **TLS/SSL Problems**
```bash
# Check route TLS configuration
oc get route quarkus-websocket-service -n healthcare-ml-demo -o yaml | grep -A 10 tls

# Test TLS handshake
openssl s_client -connect $WEBSOCKET_URL:443 -servername $WEBSOCKET_URL
```

#### **Load Balancer Issues**
```bash
# Check if multiple pods are causing session affinity issues
oc get pods -l app=quarkus-websocket-service -n healthcare-ml-demo

# Verify service configuration for session affinity
oc get svc quarkus-websocket-service -n healthcare-ml-demo -o yaml | grep sessionAffinity
```

## 📊 Monitoring and Metrics

### Health Check Endpoints

```bash
# Application health
curl -k https://$WEBSOCKET_URL/q/health

# Readiness probe
curl -k https://$WEBSOCKET_URL/q/health/ready

# Liveness probe  
curl -k https://$WEBSOCKET_URL/q/health/live

# Metrics endpoint
curl -k https://$WEBSOCKET_URL/q/metrics
```

### Performance Monitoring

```bash
# Monitor WebSocket connection metrics
curl -k https://$WEBSOCKET_URL/q/metrics | grep -E "(websocket|genetic|session)"

# Check thread pool usage
curl -k https://$WEBSOCKET_URL/q/metrics | grep -E "(thread|executor)"

# Monitor Kafka producer metrics
curl -k https://$WEBSOCKET_URL/q/metrics | grep kafka
```

## 🎯 Prevention and Best Practices

### Configuration Validation

```bash
# Verify WebSocket configuration
oc get configmap -n healthcare-ml-demo | grep websocket
oc describe configmap quarkus-websocket-config -n healthcare-ml-demo
```

### Resource Management

```bash
# Set appropriate resource limits
oc describe deployment quarkus-websocket-service -n healthcare-ml-demo | grep -A 10 "Limits\|Requests"

# Monitor resource usage trends
oc top pods -l app=quarkus-websocket-service -n healthcare-ml-demo --containers
```

### KEDA Scaling Considerations

```bash
# Ensure WebSocket service maintains minimum replicas for session continuity
oc get scaledobject websocket-service-scaler -n healthcare-ml-demo -o yaml | grep -A 5 "minReplicaCount"

# Monitor scaling events that might affect WebSocket sessions
oc get events -n healthcare-ml-demo | grep websocket-service-scaler
```

## 🚨 Emergency Recovery

### Complete Service Reset

```bash
# Full service restart
oc rollout restart deployment/quarkus-websocket-service -n healthcare-ml-demo

# Wait for rollout completion
oc rollout status deployment/quarkus-websocket-service -n healthcare-ml-demo

# Verify service is healthy
curl -k https://$WEBSOCKET_URL/q/health
```

### Kafka Connection Recovery

```bash
# Reset all consumer groups if needed
oc exec -it genetic-data-cluster-kafka-0 -n healthcare-ml-demo -- \
  bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list | \
  grep websocket | xargs -I {} bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 --reset-offsets --to-latest --group {} --all-topics --execute
```

---

**🎯 This troubleshooting guide addresses the most common WebSocket issues in healthcare ML environments with real-time genetic analysis requirements!**
