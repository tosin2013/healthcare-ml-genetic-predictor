# ADR-001: Correct Deployment Strategy for WebSocket and VEP Services

**Status:** Proposed  
**Date:** 2025-06-13  
**Authors:** Healthcare ML Team  
**Reviewers:** Co-Developer Team  

## Context and Problem Statement

Our current healthcare ML genetic analysis system has a fundamental architectural issue where deployment strategies are misaligned with service characteristics, causing:

- External WebSocket URL timeouts and connection instability
- Resource waste from always-running VEP processing services
- Inability to scale genetic analysis processing based on demand
- Limited integration with OpenShift AI for advanced ML capabilities

### Current Architecture Issues

**Problem:** We have the deployment strategies backwards:
- **WebSocket Service** (stateful, persistent connections) → Deployed as Knative (scale-to-zero)
- **VEP Service** (stateless, event-driven processing) → Deployed as regular Deployment (always-on)

## Domain Analysis (DDD Approach)

### Bounded Contexts

```
┌─────────────────────────────────────────────────────────────────┐
│                    Healthcare ML Domain                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌──────────────┐ │
│  │   User Interface │    │   Genetic       │    │   ML Analysis│ │
│  │   Context        │    │   Processing    │    │   Context    │ │
│  │                 │    │   Context       │    │              │ │
│  │ • WebSocket     │    │                 │    │ • OpenShift  │ │
│  │   Sessions      │    │ • VEP           │    │   AI Models  │ │
│  │ • Real-time UI  │    │   Annotation    │    │ • Batch      │ │
│  │ • User State    │    │ • Event-driven  │    │   Processing │ │
│  │                 │    │   Processing    │    │              │ │
│  └─────────────────┘    └─────────────────┘    └──────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Service Characteristics Analysis

#### WebSocket Service (User Interface Context)
- **Nature:** Stateful, connection-oriented
- **Lifecycle:** Long-lived connections (minutes to hours)
- **Scaling Pattern:** Based on concurrent users
- **State Management:** Session registry, active connections
- **Availability Requirement:** Always available for real-time interaction

#### VEP Service (Genetic Processing Context)
- **Nature:** Stateless, event-driven
- **Lifecycle:** Short-lived processing tasks (seconds)
- **Scaling Pattern:** Based on genetic data volume
- **State Management:** Stateless processing
- **Availability Requirement:** On-demand processing

## Decision

We will **reverse the deployment strategies** to align with Domain-Driven Design principles:

### ✅ New Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Corrected Architecture                      │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web Browser   │    │     Kafka       │    │  OpenShift AI   │
│                 │    │   (3 replicas)  │    │   Notebooks     │
│ • Genetic UI    │    │                 │    │                 │
│ • Real-time     │    │ • genetic-data- │    │ • ML Models     │
│   Results       │    │   raw           │    │ • Batch        │
│                 │    │ • genetic-data- │    │   Analysis      │
└─────────┬───────┘    │   annotated     │    └─────────┬───────┘
          │            └─────────┬───────┘              │
          │ WebSocket            │                      │ HTTP/gRPC
          │ (persistent)         │ Kafka                │ (stateless)
          │                      │ (async)              │
          ▼                      ▼                      ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ WebSocket       │    │ VEP Service     │    │ ML Inference    │
│ Service         │    │                 │    │ Service         │
│                 │    │ • Stateless     │    │                 │
│ DEPLOYMENT      │◄───┤ • Event-driven  ├───►│ KNATIVE         │
│ (Always-on)     │    │ • Auto-scaling  │    │ (Scale-to-zero) │
│                 │    │                 │    │                 │
│ • Session Mgmt  │    │ KNATIVE         │    │ • Model         │
│ • WebSocket     │    │ (Scale-to-zero) │    │   Inference     │
│   Registry      │    │                 │    │ • Batch Jobs    │
│ • Real-time     │    │ • VEP API       │    │                 │
│   Formatting    │    │ • Genetic       │    │                 │
│                 │    │   Annotation    │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Deployment Strategy Changes

#### 1. WebSocket Service → Regular Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: quarkus-websocket-service
spec:
  replicas: 2  # Fixed replicas for persistent connections
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
```

**Rationale:**
- **Persistent Connections:** WebSocket sessions must remain active
- **Session State:** Maintains user session registry
- **Predictable Scaling:** Manual scaling based on concurrent users
- **High Availability:** Rolling updates preserve connections

#### 2. VEP Service → Knative Service
```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: vep-service
spec:
  template:
    metadata:
      annotations:
        autoscaling.knative.dev/minScale: "0"
        autoscaling.knative.dev/maxScale: "10"
        autoscaling.knative.dev/target: "5"
```

**Rationale:**
- **Event-Driven:** Responds to Kafka messages
- **Stateless Processing:** No session state to maintain
- **Cost Efficiency:** Scales to zero when no genetic data
- **Burst Handling:** Auto-scales for high genetic analysis loads

## Data Flow with Corrected Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Data Flow Diagram                        │
└─────────────────────────────────────────────────────────────────┘

User Input
    │
    ▼
┌─────────────────┐
│ WebSocket UI    │ 1. User submits genetic sequence
│ (Browser)       │
└─────────┬───────┘
          │ WebSocket Message
          ▼
┌─────────────────┐
│ WebSocket       │ 2. Receives genetic data
│ Service         │ 3. Publishes to Kafka
│ (DEPLOYMENT)    │
└─────────┬───────┘
          │ Kafka Publish
          ▼
┌─────────────────┐
│ Kafka Cluster   │ 4. genetic-data-raw topic
│ (3 replicas)    │
└─────────┬───────┘
          │ Kafka Consume
          ▼
┌─────────────────┐
│ VEP Service     │ 5. Processes genetic sequence
│ (KNATIVE)       │ 6. Calls Ensembl VEP API
│                 │ 7. Calls OpenShift AI models
│ • Auto-scales   │ 8. Publishes annotated results
│ • Scale-to-zero │
└─────────┬───────┘
          │ Kafka Publish
          ▼
┌─────────────────┐
│ Kafka Cluster   │ 9. genetic-data-annotated topic
│ (3 replicas)    │
└─────────┬───────┘
          │ Kafka Consume
          ▼
┌─────────────────┐
│ WebSocket       │ 10. Formats results
│ Service         │ 11. Sends to WebSocket client
│ (DEPLOYMENT)    │
└─────────┬───────┘
          │ WebSocket Response
          ▼
┌─────────────────┐
│ WebSocket UI    │ 12. Displays genetic analysis
│ (Browser)       │
└─────────────────┘
```

## Consequences

### Positive Consequences

#### ✅ WebSocket Service as Deployment
- **Connection Stability:** No more dropped WebSocket connections
- **Session Persistence:** User sessions maintained during processing
- **Predictable Performance:** Consistent response times
- **Real-time Capability:** Always available for immediate interaction

#### ✅ VEP Service as Knative
- **Cost Efficiency:** Scales to zero when no genetic data to process
- **Auto-scaling:** Handles burst loads of genetic analysis requests
- **OpenShift AI Integration:** Perfect for stateless ML model calls
- **Resource Optimization:** Only consumes resources when processing

#### ✅ System-wide Benefits
- **Resolved Timeouts:** External URL accessibility restored
- **Better Resource Utilization:** Right-sized deployments
- **Enhanced ML Capabilities:** Seamless OpenShift AI integration
- **Improved Scalability:** Each service scales according to its nature

### Negative Consequences

#### ⚠️ Migration Complexity
- **Deployment Reconfiguration:** Need to recreate services with different types
- **Testing Required:** Validate WebSocket persistence and VEP scaling
- **Monitoring Updates:** Adjust monitoring for new scaling patterns

#### ⚠️ Operational Changes
- **WebSocket Scaling:** Manual scaling decisions for concurrent users
- **VEP Cold Starts:** Initial genetic analysis requests may have slight delay

## Implementation Plan

### Phase 1: WebSocket Service Migration
1. Create new Deployment configuration for WebSocket service
2. Update Kustomize overlays
3. Test WebSocket connection persistence
4. Deploy and validate

### Phase 2: VEP Service Migration  
1. Create new Knative Service configuration for VEP service
2. Configure auto-scaling parameters
3. Test scale-to-zero and scale-up behavior
4. Deploy and validate

### Phase 3: OpenShift AI Integration
1. Add OpenShift AI model endpoints to VEP service
2. Implement ML inference calls
3. Test end-to-end genetic analysis with ML enhancement

### Phase 4: Validation and Monitoring
1. Load testing for both services
2. Monitor scaling behavior
3. Validate cost efficiency improvements
4. Document operational procedures

## Related Decisions

- **ADR-002:** OpenShift AI Integration Strategy (Future)
- **ADR-003:** Kafka Topic Partitioning for Genetic Data (Future)
- **ADR-004:** Cost Management and Scaling Policies (Future)

## Technical Implementation Details

### WebSocket Service Configuration Changes

**Current Knative Service → New Deployment**

```yaml
# Remove: k8s/base/applications/quarkus-websocket/knative-service.yaml
# Add: k8s/base/applications/quarkus-websocket/deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: quarkus-websocket-service
  labels:
    app: quarkus-websocket-service
    version: v1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: quarkus-websocket-service
  template:
    metadata:
      labels:
        app: quarkus-websocket-service
        version: v1
    spec:
      containers:
      - name: quarkus-websocket-service
        image: image-registry.openshift-image-registry.svc:5000/healthcare-ml-demo/quarkus-websocket-service:latest
        ports:
        - containerPort: 8080
          protocol: TCP
        env:
        - name: KAFKA_BOOTSTRAP_SERVERS
          value: "genetic-data-cluster-kafka-bootstrap.healthcare-ml-demo.svc.cluster.local:9092"
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /q/health/live
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /q/health/ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: quarkus-websocket-service
spec:
  selector:
    app: quarkus-websocket-service
  ports:
  - port: 8080
    targetPort: 8080
    protocol: TCP
  type: ClusterIP
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: quarkus-websocket-service
spec:
  to:
    kind: Service
    name: quarkus-websocket-service
  port:
    targetPort: 8080
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
```

### VEP Service Configuration Changes

**Current Deployment → New Knative Service**

```yaml
# Remove: k8s/base/applications/vep-service/deployment.yaml
# Add: k8s/base/applications/vep-service/knative-service.yaml

apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: vep-service
  labels:
    app: vep-service
    version: v1
spec:
  template:
    metadata:
      annotations:
        # Scaling configuration
        autoscaling.knative.dev/minScale: "0"
        autoscaling.knative.dev/maxScale: "10"
        autoscaling.knative.dev/target: "5"
        autoscaling.knative.dev/targetUtilizationPercentage: "70"

        # Cold start optimization
        autoscaling.knative.dev/scaleDownDelay: "30s"
        autoscaling.knative.dev/scaleToZeroGracePeriod: "60s"

        # Resource allocation
        autoscaling.knative.dev/class: "kpa.autoscaling.knative.dev"
        autoscaling.knative.dev/metric: "concurrency"
      labels:
        app: vep-service
        version: v1
    spec:
      containers:
      - name: vep-service
        image: image-registry.openshift-image-registry.svc:5000/healthcare-ml-demo/vep-service:latest
        ports:
        - containerPort: 8080
          protocol: TCP
        env:
        - name: KAFKA_BOOTSTRAP_SERVERS
          value: "genetic-data-cluster-kafka-bootstrap.healthcare-ml-demo.svc.cluster.local:9092"
        - name: VEP_API_URL
          value: "https://rest.ensembl.org/vep/human/hgvs"
        - name: OPENSHIFT_AI_ENDPOINT
          value: "http://modelmesh-serving.openshift-ai-demo.svc.cluster.local:8008"
        resources:
          requests:
            memory: "512Mi"
            cpu: "200m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /q/health/live
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /q/health/ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
```

### Kustomization Updates

**Update base/applications/kustomization.yaml:**

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- quarkus-websocket/deployment.yaml  # Changed from knative-service.yaml
- vep-service/knative-service.yaml   # Changed from deployment.yaml
- namespace.yaml

components:
- ../../components/cost-labels
- ../../components/security-context
```

## Migration Commands

### Step 1: Backup Current Configuration
```bash
# Backup current services
oc get ksvc quarkus-websocket-knative -o yaml > backup-websocket-knative.yaml
oc get deployment vep-service -o yaml > backup-vep-deployment.yaml
```

### Step 2: Apply New Configuration
```bash
# Apply the corrected architecture
oc apply -k k8s/overlays/prod/

# Verify deployments
oc get deployment quarkus-websocket-service -n healthcare-ml-demo
oc get ksvc vep-service -n healthcare-ml-demo
```

### Step 3: Validate Functionality
```bash
# Test WebSocket persistence
curl -k https://quarkus-websocket-service-healthcare-ml-demo.apps.cluster.local/genetic-client.html

# Test VEP service scaling
oc get pods -n healthcare-ml-demo -w | grep vep-service
```

## Success Metrics

### WebSocket Service (Deployment)
- ✅ **Connection Persistence**: WebSocket connections survive pod restarts
- ✅ **Session Continuity**: User sessions maintained during genetic analysis
- ✅ **Response Time**: < 100ms for WebSocket message handling
- ✅ **Availability**: 99.9% uptime for real-time interactions

### VEP Service (Knative)
- ✅ **Scale-to-Zero**: Pods terminate after 60s of inactivity
- ✅ **Auto-scaling**: Scales up within 10s of genetic data arrival
- ✅ **Cost Efficiency**: 70% reduction in idle resource consumption
- ✅ **Processing Throughput**: Handles 10x burst loads automatically

### System Integration
- ✅ **End-to-End Latency**: < 5s for complete genetic analysis
- ✅ **OpenShift AI Integration**: ML model calls complete within 2s
- ✅ **External URL Access**: 100% success rate for external connections
- ✅ **Resource Utilization**: Optimal resource allocation per service type

## References

- [Knative Serving Documentation](https://knative.dev/docs/serving/)
- [OpenShift AI Documentation](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed)
- [Domain-Driven Design Principles](https://martinfowler.com/bliki/DomainDrivenDesign.html)
- [WebSocket Connection Management Best Practices](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API)
- [Kubernetes Deployment Strategies](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [OpenShift Route Configuration](https://docs.openshift.com/container-platform/4.14/networking/routes/route-configuration.html)
