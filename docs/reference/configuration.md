# Configuration Reference - Healthcare ML System

## 🎯 Overview

This reference provides comprehensive configuration details for all components in the Healthcare ML Genetic Predictor system based on the current OpenShift deployment.

## 🌐 WebSocket Service Configuration

### Application Properties


````properties
# Quarkus WebSocket Service Configuration
quarkus.application.name=healthcare-ml-websocket
quarkus.http.port=8080
quarkus.http.host=0.0.0.0

# Kafka Configuration
kafka.bootstrap.servers=genetic-data-cluster-kafka-bootstrap.healthcare-ml-demo.svc.cluster.local:9092
mp.messaging.outgoing.genetic-data-out.connector=smallrye-kafka
mp.messaging.outgoing.genetic-data-out.topic=genetic-data-raw
mp.messaging.incoming.genetic-results-in.connector=smallrye-kafka
mp.messaging.incoming.genetic-results-in.topic=genetic-data-processed
````


### Environment Variables

```yaml
# WebSocket Service Environment Configuration
env:
  - name: KAFKA_BOOTSTRAP_SERVERS
    value: "genetic-data-cluster-kafka-bootstrap.healthcare-ml-demo.svc.cluster.local:9092"
  - name: GENETIC_DATA_TOPIC
    value: "genetic-data-raw"
  - name: GENETIC_RESULTS_TOPIC  
    value: "genetic-data-processed"
  - name: QUARKUS_LOG_LEVEL
    value: "INFO"
  - name: JAVA_OPTS
    value: "-Xmx512m -Xms256m"
```

### Resource Configuration

```yaml
# WebSocket Service Resource Limits
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

## 🔬 VEP Service Configuration

### Application Properties

```properties
# VEP Service Configuration
quarkus.application.name=healthcare-ml-vep
quarkus.http.port=8080

# VEP API Configuration
vep.api.base-url=https://rest.ensembl.org
vep.api.timeout=30000
vep.api.rate-limit-delay=1000

# Kafka Configuration
kafka.bootstrap.servers=genetic-data-cluster-kafka-bootstrap.healthcare-ml-demo.svc.cluster.local:9092
mp.messaging.incoming.genetic-data-in.connector=smallrye-kafka
mp.messaging.incoming.genetic-data-in.topic=genetic-data-raw
mp.messaging.outgoing.genetic-results-out.connector=smallrye-kafka
mp.messaging.outgoing.genetic-results-out.topic=genetic-data-processed
```

### Environment Variables

```yaml
# VEP Service Environment Configuration
env:
  - name: VEP_API_BASE_URL
    value: "https://rest.ensembl.org"
  - name: VEP_API_TIMEOUT
    value: "30000"
  - name: VEP_RATE_LIMIT_DELAY
    value: "1000"
  - name: KAFKA_BOOTSTRAP_SERVERS
    value: "genetic-data-cluster-kafka-bootstrap.healthcare-ml-demo.svc.cluster.local:9092"
  - name: JAVA_OPTS
    value: "-Xmx1Gi -Xms512m"
```

### Resource Configuration

```yaml
# VEP Service Resource Limits
resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

## 📊 Kafka Configuration

### Cluster Configuration


````yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: genetic-data-cluster
spec:
  kafka:
    version: 3.6.0
    replicas: 3
    listeners:
      - name: plain
        port: 9092
        type: internal
        tls: false
    config:
      offsets.topic.replication.factor: 1
      transaction.state.log.replication.factor: 1
      transaction.state.log.min.isr: 1
      default.replication.factor: 1
      min.insync.replicas: 1
    storage:
      type: ephemeral
  zookeeper:
    replicas: 3
    storage:
      type: ephemeral
````


### Topic Configurations

#### genetic-data-raw Topic

```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaTopic
metadata:
  name: genetic-data-raw
spec:
  partitions: 3
  replicas: 1
  config:
    retention.ms: 604800000      # 7 days
    retention.bytes: 1073741824  # 1GB per partition
    segment.ms: 86400000         # 1 day
    segment.bytes: 134217728     # 128MB
    cleanup.policy: delete
    compression.type: snappy
    max.message.bytes: 1048576   # 1MB
```

#### genetic-data-processed Topic

```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaTopic
metadata:
  name: genetic-data-processed
spec:
  partitions: 3
  replicas: 1
  config:
    retention.ms: 1209600000     # 14 days
    retention.bytes: 2147483648  # 2GB per partition
    segment.ms: 86400000         # 1 day
    segment.bytes: 134217728     # 128MB
    cleanup.policy: delete
    compression.type: snappy
    max.message.bytes: 2097152   # 2MB
```

## ⚡ KEDA Configuration

### WebSocket Service Scaler

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: websocket-service-scaler
spec:
  scaleTargetRef:
    name: quarkus-websocket-service
  pollingInterval: 15
  cooldownPeriod: 120
  minReplicaCount: 1    # Maintain session continuity
  maxReplicaCount: 10
  triggers:
  - type: kafka
    metadata:
      bootstrapServers: genetic-data-cluster-kafka-bootstrap.healthcare-ml-demo.svc.cluster.local:9092
      consumerGroup: websocket-results-service-group
      topic: genetic-data-processed
      lagThreshold: "10"
      offsetResetPolicy: latest
```

### VEP Service Scaler

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: vep-service-scaler
spec:
  scaleTargetRef:
    name: vep-service
  pollingInterval: 10
  cooldownPeriod: 60
  minReplicaCount: 0    # Scale to zero for cost optimization
  maxReplicaCount: 50
  triggers:
  - type: kafka
    metadata:
      bootstrapServers: genetic-data-cluster-kafka-bootstrap.healthcare-ml-demo.svc.cluster.local:9092
      consumerGroup: vep-service-group
      topic: genetic-data-raw
      lagThreshold: "3"
      offsetResetPolicy: latest
```

### VEP NodeScale Service Scaler

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: vep-service-nodescale-scaler
spec:
  scaleTargetRef:
    name: vep-service-nodescale
  pollingInterval: 5
  cooldownPeriod: 300   # 5 minutes for VEP processing
  minReplicaCount: 0
  maxReplicaCount: 20   # Triggers cluster autoscaler
  triggers:
  - type: kafka
    metadata:
      bootstrapServers: genetic-data-cluster-kafka-bootstrap.healthcare-ml-demo.svc.cluster.local:9092
      consumerGroup: vep-nodescale-service-group
      topic: genetic-data-raw
      lagThreshold: "1"
      offsetResetPolicy: latest
```

## 🏗️ OpenShift Configuration

### Namespace Configuration

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: healthcare-ml-demo
  labels:
    cost-center: "genomics-research"
    project: "risk-predictor-v1"
    app.kubernetes.io/name: healthcare-ml-demo
    app.kubernetes.io/part-of: healthcare-ml-system
  annotations:
    cost-center: "genomics-research"
    project: "risk-predictor-v1"
    deployment-method: "kustomize"
```

### Security Context Configuration

```yaml
# Security Context for Healthcare Compliance
securityContext:
  runAsNonRoot: true
  runAsUser: 1001
  fsGroup: 1001
  seccompProfile:
    type: RuntimeDefault
containers:
- name: service-container
  securityContext:
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: true
    capabilities:
      drop: ["ALL"]
```

### Network Configuration

```yaml
# Service Configuration
apiVersion: v1
kind: Service
metadata:
  name: quarkus-websocket-service
spec:
  selector:
    app: quarkus-websocket-service
  ports:
  - name: http
    port: 8080
    targetPort: 8080
    protocol: TCP
  type: ClusterIP
```

```yaml
# Route Configuration
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: quarkus-websocket-service
spec:
  to:
    kind: Service
    name: quarkus-websocket-service
  port:
    targetPort: http
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
```

## 💰 Cost Management Configuration

### Cost Attribution Labels

```yaml
# Required labels for all resources
metadata:
  labels:
    cost-center: "genomics-research"
    project: "risk-predictor-v1"
    app.kubernetes.io/name: "component-name"
    app.kubernetes.io/part-of: "healthcare-ml-demo"
    app.kubernetes.io/managed-by: "kustomize"
  annotations:
    cost-center: "genomics-research"
    project: "risk-predictor-v1"
    deployment-method: "kustomize"
```

### Cost Management Operator Configuration

```yaml
# Cost Management Metrics Config
apiVersion: costmanagement.openshift.io/v1alpha1
kind: CostManagementMetricsConfig
metadata:
  name: cost-mgmt-metrics-config
spec:
  clusterAlias: "healthcare-ml-cluster"
  packaging:
    max_size: "100"
    max_reports_to_store: "30"
  promconfig:
    collect_previous_data: true
```

## 🔧 Build Configuration

### WebSocket Service BuildConfig

```yaml
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  name: quarkus-websocket-service
spec:
  source:
    type: Git
    git:
      uri: https://github.com/your-repo/healthcare-ml-genetic-predictor.git
    contextDir: quarkus-websocket-service
  strategy:
    type: Source
    sourceStrategy:
      from:
        kind: ImageStreamTag
        name: openjdk-17:latest
        namespace: openshift
  output:
    to:
      kind: ImageStreamTag
      name: quarkus-websocket-service:latest
```

### VEP Service BuildConfig

```yaml
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  name: vep-service
spec:
  source:
    type: Git
    git:
      uri: https://github.com/your-repo/healthcare-ml-genetic-predictor.git
    contextDir: vep-service
  strategy:
    type: Source
    sourceStrategy:
      from:
        kind: ImageStreamTag
        name: openjdk-17:latest
        namespace: openshift
  output:
    to:
      kind: ImageStreamTag
      name: vep-service:latest
```

## 📋 Configuration Validation

### Health Check Endpoints

```yaml
# Liveness and Readiness Probes
livenessProbe:
  httpGet:
    path: /q/health/live
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /q/health/ready
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 3
```

### Configuration Verification Commands

```bash
# Verify WebSocket service configuration
oc get configmap quarkus-websocket-config -n healthcare-ml-demo -o yaml

# Check Kafka cluster configuration
oc get kafka genetic-data-cluster -n healthcare-ml-demo -o yaml

# Verify KEDA scaler configuration
oc get scaledobjects -n healthcare-ml-demo -o yaml

# Check cost management labels
oc get all -n healthcare-ml-demo --show-labels | grep cost-center
```

---

**🎯 This configuration reference provides complete details for all components in the healthcare ML genetic prediction system!**
