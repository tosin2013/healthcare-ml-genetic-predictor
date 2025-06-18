# Augment Code Integration Guide - Healthcare ML Genetic Predictor

## 🎯 Augment Code Optimization

This guide provides comprehensive instructions for working with the Healthcare ML Genetic Predictor system using **Augment Code's superior context awareness** and AI-assisted development capabilities.

## 🧠 Leveraging Augment's Context Engine

### Intelligent Code Queries

Use Augment's world-leading context engine with these optimized queries:

#### **WebSocket Service Queries**
```
"Show me the WebSocket endpoint implementation for genetic analysis"
"Find the threading validation logic in Quarkus WebSocket service"
"Locate the @Blocking annotations and their usage patterns"
"Show me the CloudEvent creation and Kafka integration"
```

#### **KEDA Scaling Queries**
```
"Find KEDA scaling configurations for genetic data processing"
"Show me the ScaledObject definitions for pod and node scaling"
"Locate the Kafka topic configurations and their scaling triggers"
"Find the cost attribution labels in KEDA resources"
```

#### **VEP Service Queries**
```
"Show me the VEP service processing logic and API integration"
"Find the Ensembl VEP API integration patterns"
"Locate the genetic sequence validation and processing code"
"Show me the error handling for VEP API failures"
```

#### **OpenShift Deployment Queries**
```
"Find the Kustomize base configurations for OpenShift deployment"
"Show me the BuildConfig and ImageStream definitions"
"Locate the security context constraints and RBAC configurations"
"Find the Red Hat Insights cost management integration"
```

### Context-Aware Development Patterns

#### **1. Threading Architecture Understanding**
When working with Quarkus reactive applications, use Augment to understand:

<augment_code_snippet path="quarkus-websocket-service/src/main/java/com/healthcare/ml/controller/ScalingTestController.java" mode="EXCERPT">
````java
@Path("/api/scaling")
@ApplicationScoped
public class ScalingTestController {
    
    @POST
    @Path("/trigger-demo")
    @Blocking  // Critical: Ensures worker thread execution
    @Produces(MediaType.APPLICATION_JSON)
    public Response triggerScalingDemo(ScalingDemoRequest request) {
        // This runs on executor-thread-* (worker thread)
        // Safe for blocking operations like Kafka publishing
        return geneticAnalysisService.processScalingDemo(request);
    }
}
````
</augment_code_snippet>

#### **2. Event-Driven Architecture Patterns**
Understand the Kafka integration patterns:

<augment_code_snippet path="quarkus-websocket-service/src/main/java/com/healthcare/ml/service/GeneticAnalysisService.java" mode="EXCERPT">
````java
@ApplicationScoped
public class GeneticAnalysisService {
    
    @Channel("genetic-data-out")
    Emitter<CloudEvent> geneticDataEmitter;
    
    @Blocking  // Ensures CloudEvent creation on worker thread
    public void publishGeneticData(GeneticSequence sequence) {
        CloudEvent event = CloudEventBuilder.v1()
            .withId(UUID.randomUUID().toString())
            .withType("genetic.analysis.request")
            .withSource(URI.create("/genetic/analysis"))
            .withData("application/json", sequence)
            .build();
        
        geneticDataEmitter.send(event);
    }
}
````
</augment_code_snippet>

## 🔧 Augment Code Workflow Integration

### Development Workflow

#### **1. Context-Aware Code Analysis**
Before making changes, use Augment's context engine:

```bash
# Use Augment to understand the codebase structure
# Query: "Show me the complete data flow from WebSocket to VEP service"
# Query: "Find all KEDA scaling configurations and their relationships"
# Query: "Show me the error handling patterns across all services"
```

#### **2. AI-Assisted Development Process**
1. **Context Gathering**: Use Augment to understand existing patterns
2. **Pattern Recognition**: Leverage Augment's pattern matching for consistent code
3. **Integration Validation**: Use Augment to verify cross-service compatibility
4. **Testing Strategy**: Use Augment to identify test coverage gaps

### Local Development Setup for Augment Code

#### **Prerequisites Validation**
```bash
# Verify Java 17 (hard requirement)
java -version
# Expected: openjdk version "17.x.x"

# Verify Maven wrapper availability
ls -la quarkus-websocket-service/mvnw
ls -la vep-service/mvnw

# Verify Podman (preferred over Docker)
podman --version
```

#### **Augment-Optimized Local Testing**
```bash
# Use project's Maven wrapper (Augment Code best practice)
cd quarkus-websocket-service
./mvnw clean compile test

# Run threading validation (critical for Quarkus reactive)
./test-threading-local.sh

# Start development mode with live reload
./mvnw quarkus:dev
```

### Code Quality Patterns for Augment Code

#### **1. Threading Compliance Patterns**
Always use `@Blocking` for operations that:
- Publish to Kafka
- Make external API calls
- Perform database operations
- Execute long-running computations

#### **2. Error Handling Patterns**
Implement consistent error handling:

<augment_code_snippet path="quarkus-websocket-service/src/main/java/com/healthcare/ml/exception/GeneticAnalysisException.java" mode="EXCERPT">
````java
@ApplicationScoped
public class ErrorHandler {
    
    public Response handleGeneticAnalysisError(GeneticAnalysisException e) {
        return Response.status(Response.Status.BAD_REQUEST)
            .entity(Map.of(
                "error", "genetic_analysis_failed",
                "message", e.getMessage(),
                "timestamp", Instant.now(),
                "session_id", e.getSessionId()
            ))
            .build();
    }
}
````
</augment_code_snippet>

## 🎯 Augment Code Best Practices

### Context-Aware Code Navigation

#### **Service Dependencies**
Use Augment to understand service relationships:
- **WebSocket Service** → **Kafka Topics** → **VEP Service**
- **KEDA Scalers** → **Kafka Lag Metrics** → **Pod/Node Scaling**
- **Cost Management** → **Resource Labels** → **Red Hat Insights**

#### **Configuration Management**
Leverage Augment to understand Kustomize patterns:
- **Base configurations**: `k8s/base/`
- **Environment overlays**: `k8s/overlays/{dev,staging,prod}/`
- **Reusable components**: `k8s/components/`

### AI-Assisted Debugging

#### **Common Issues and Augment Queries**
1. **Threading Issues**: "Find all @Blocking annotations and verify worker thread usage"
2. **Kafka Connectivity**: "Show me Kafka connection configurations and error handling"
3. **KEDA Scaling**: "Find ScaledObject configurations and their trigger conditions"
4. **OpenShift Deployment**: "Show me BuildConfig and deployment status checks"

## 📊 Performance Optimization with Augment

### Context-Aware Performance Analysis

#### **Scaling Behavior Understanding**
Use Augment to analyze scaling patterns:
- **Normal Mode**: Pod scaling based on `genetic-data-raw` topic lag
- **Big Data Mode**: Memory-intensive processing on `genetic-bigdata-raw`
- **Node Scale Mode**: Cluster autoscaler triggers via `genetic-nodescale-raw`

#### **Resource Optimization**
Leverage Augment to understand resource allocation:

<augment_code_snippet path="k8s/base/applications/vep-service/deployment.yaml" mode="EXCERPT">
````yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "2Gi"
    cpu: "1000m"
# Optimized for VEP API processing workloads
````
</augment_code_snippet>

## 🔒 Security Patterns for Augment Code

### Healthcare-Grade Security Understanding

#### **Security Context Patterns**
Use Augment to understand security configurations:
- **Non-root execution**: All containers run as non-root users
- **Security Context Constraints**: OpenShift SCC compliance
- **RBAC**: Service account permissions and role bindings
- **Network Policies**: Traffic isolation between services

## 📚 Documentation Integration

### Augment-Optimized Documentation Queries

#### **Architecture Understanding**
```
"Show me the complete system architecture from frontend to VEP API"
"Find all ADR documents and their implementation status"
"Locate the cost management integration patterns"
"Show me the HIPAA compliance configurations"
```

#### **Deployment Understanding**
```
"Find the complete OpenShift deployment pipeline"
"Show me the Kustomize overlay structure and environment differences"
"Locate the KEDA scaling configurations and their relationships"
"Find the Red Hat Insights cost attribution setup"
```

---

**🎉 This guide optimizes your development workflow for Augment Code's superior context awareness and AI-assisted development capabilities!**
