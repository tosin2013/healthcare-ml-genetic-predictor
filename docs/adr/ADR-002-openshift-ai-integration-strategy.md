# ADR-002: OpenShift AI Integration Strategy for Healthcare ML Pipeline

**Status:** Proposed  
**Date:** 2025-06-13  
**Authors:** Healthcare ML Team  
**Reviewers:** Co-Developer Team  
**Depends On:** ADR-001 (Deployment Strategy Correction)

## Context and Problem Statement

Our healthcare ML genetic analysis system currently provides basic VEP (Variant Effect Predictor) annotations, but lacks advanced machine learning capabilities for:

- **Genetic Risk Prediction**: ML models for disease susceptibility analysis
- **Pharmacogenomics**: Drug response prediction based on genetic variants
- **Population Genetics**: Ancestry and population structure analysis
- **Clinical Decision Support**: AI-powered treatment recommendations
- **Batch Processing**: Large-scale genomic data analysis

We need to integrate **OpenShift AI** to provide enterprise-grade ML capabilities while maintaining real-time responsiveness and cost efficiency.

## Domain Analysis (DDD Approach)

### Extended Bounded Contexts

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Healthcare ML Ecosystem                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────────┐  │
│  │   User Interface │    │   Genetic       │    │   ML Intelligence       │  │
│  │   Context        │    │   Processing    │    │   Context               │  │
│  │                 │    │   Context       │    │                         │  │
│  │ • WebSocket     │    │                 │    │ • OpenShift AI          │  │
│  │   Sessions      │    │ • VEP           │    │ • Model Serving         │  │
│  │ • Real-time UI  │    │   Annotation    │    │ • Jupyter Notebooks     │  │
│  │ • User State    │    │ • Event-driven  │    │ • Model Training        │  │
│  │                 │    │   Processing    │    │ • Batch Processing      │  │
│  └─────────────────┘    └─────────────────┘    └─────────────────────────┘  │
│           │                       │                         │               │
│           │                       │                         │               │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────────┐  │
│  │   Data Storage  │    │   Event Streaming│    │   Cost Management       │  │
│  │   Context       │    │   Context       │    │   Context               │  │
│  │                 │    │                 │    │                         │  │
│  │ • S3 Storage    │    │ • Kafka Cluster │    │ • KEDA Scaling          │  │
│  │ • Data Lake     │    │ • Event Sourcing│    │ • Resource Monitoring   │  │
│  │ • Model Registry│    │ • Stream Proc.  │    │ • Cost Attribution      │  │
│  │                 │    │                 │    │                         │  │
│  └─────────────────┘    └─────────────────┘    └─────────────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### ML Processing Patterns

#### Real-time Inference Pattern
- **Trigger**: Individual genetic sequence submission
- **Processing**: VEP annotation + ML risk prediction
- **Response Time**: < 5 seconds
- **Use Case**: Clinical decision support

#### Batch Processing Pattern  
- **Trigger**: Large genomic datasets
- **Processing**: Population analysis, model training
- **Response Time**: Minutes to hours
- **Use Case**: Research, population studies

#### Streaming Analytics Pattern
- **Trigger**: Continuous genetic data stream
- **Processing**: Real-time monitoring, alerts
- **Response Time**: < 1 second
- **Use Case**: Clinical monitoring, outbreak detection

## Decision

We will integrate **OpenShift AI** as the **ML Intelligence Context** with multiple integration patterns:

### ✅ OpenShift AI Integration Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    OpenShift AI Integration Architecture                    │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────────────┐
│   WebSocket     │    │     Kafka       │    │      OpenShift AI           │
│   Service       │    │   (3 replicas)  │    │      Platform               │
│                 │    │                 │    │                             │
│ DEPLOYMENT      │    │ • genetic-data- │    │ ┌─────────────────────────┐ │
│ (Always-on)     │    │   raw           │    │ │   Model Serving         │ │
│                 │    │ • genetic-data- │    │ │                         │ │
│ • Session Mgmt  │    │   annotated     │    │ │ • ModelMesh Serving     │ │
│ • WebSocket     │    │ • ml-predictions│    │ │ • ONNX Runtime          │ │
│   Registry      │    │ • batch-results │    │ │ • TensorFlow Serving    │ │
│ • Real-time     │    │                 │    │ │ • PyTorch Serve         │ │
│   Formatting    │    │                 │    │ └─────────────────────────┘ │
└─────────┬───────┘    └─────────┬───────┘    │                             │
          │                      │            │ ┌─────────────────────────┐ │
          │ WebSocket            │ Kafka      │ │   Jupyter Notebooks     │ │
          │ (persistent)         │ (async)    │ │                         │ │
          │                      │            │ │ • Model Development     │ │
          ▼                      ▼            │ │ • Data Exploration      │ │
┌─────────────────┐    ┌─────────────────┐    │ │ • Research Analysis     │ │
│ Genetic Client  │    │ VEP Service     │    │ │ • Collaborative Work    │ │
│ (Browser)       │    │                 │◄───┤ └─────────────────────────┘ │
│                 │    │ KNATIVE         │    │                             │
│ • Genetic UI    │    │ (Scale-to-zero) │    │ ┌─────────────────────────┐ │
│ • Real-time     │    │                 │    │ │   Data Science Pipeline │ │
│   Results       │    │ • VEP API       │    │ │                         │ │
│ • ML Insights   │    │ • ML Inference  │    │ │ • Elyra Pipelines       │ │
│                 │    │ • Batch Jobs    │    │ │ • Kubeflow Integration  │ │
└─────────────────┘    └─────────┬───────┘    │ │ • MLflow Tracking       │ │
                                 │            │ │ • Model Registry        │ │
                                 │ HTTP/gRPC  │ └─────────────────────────┘ │
                                 │ (stateless)│                             │
                                 ▼            │ ┌─────────────────────────┐ │
                       ┌─────────────────┐    │ │   Resource Management   │ │
                       │ ML Models       │    │ │                         │ │
                       │                 │    │ │ • GPU Scheduling        │ │
                       │ • Risk Predictor│    │ │ • Auto-scaling          │ │
                       │ • Drug Response │    │ │ • Cost Optimization     │ │
                       │ • Ancestry      │    │ │ • Resource Quotas       │ │
                       │ • Clinical AI   │    │ └─────────────────────────┘ │
                       └─────────────────┘    └─────────────────────────────┘
```

## Integration Patterns

### 1. Real-time ML Inference Pattern

**Data Flow:**
```
User Input → WebSocket Service → Kafka → VEP Service → OpenShift AI Models → Results
```

**Implementation:**
- VEP Service calls ModelMesh Serving endpoints
- Synchronous inference for real-time results
- Caching for frequently requested predictions
- Fallback to basic VEP if ML unavailable

### 2. Batch Processing Pattern

**Data Flow:**
```
Large Dataset → S3 Storage → Jupyter Notebooks → Elyra Pipelines → Batch Results
```

**Implementation:**
- Scheduled batch jobs for population analysis
- Distributed processing across multiple nodes
- Results stored in data lake for research
- Integration with existing research workflows

### 3. Model Training Pattern

**Data Flow:**
```
Historical Data → Feature Engineering → Model Training → Model Registry → Deployment
```

**Implementation:**
- Continuous model improvement
- A/B testing for model performance
- Automated model deployment pipelines
- Version control for model artifacts

## Technical Implementation

### ModelMesh Serving Configuration

```yaml
apiVersion: serving.kserve.io/v1beta1
kind: InferenceService
metadata:
  name: genetic-risk-predictor
  namespace: healthcare-ml-demo
spec:
  predictor:
    model:
      modelFormat:
        name: onnx
      runtime: onnx-runtime
      storageUri: s3://healthcare-ml-models/genetic-risk-predictor/v1.0
    resources:
      requests:
        cpu: 100m
        memory: 512Mi
      limits:
        cpu: 1000m
        memory: 2Gi
    scaleTarget: 0
    scaleMetric: concurrency
    targetConcurrencyPerReplica: 10
```

### VEP Service ML Integration

```java
@ApplicationScoped
public class MLInferenceService {
    
    @RestClient
    MLModelClient mlModelClient;
    
    public Uni<MLPrediction> predictGeneticRisk(VepAnnotationResult vepResult) {
        return mlModelClient.predict(
            MLInferenceRequest.builder()
                .features(extractFeatures(vepResult))
                .modelName("genetic-risk-predictor")
                .version("v1.0")
                .build()
        ).onFailure().recoverWithItem(
            // Fallback to rule-based prediction
            () -> createFallbackPrediction(vepResult)
        );
    }
    
    private MLFeatures extractFeatures(VepAnnotationResult vepResult) {
        return MLFeatures.builder()
            .consequence(vepResult.getMostSevereConsequence())
            .geneSymbol(vepResult.getGeneSymbol())
            .siftScore(vepResult.getSiftScore())
            .polyphenScore(vepResult.getPolyphenScore())
            .alleleFrequency(vepResult.getAlleleFrequency())
            .build();
    }
}
```

### Jupyter Notebook Integration

```python
# healthcare_ml_notebook.ipynb
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
import joblib
import s3fs

# Connect to data lake
fs = s3fs.S3FileSystem()

# Load genetic data
genetic_data = pd.read_parquet('s3://healthcare-ml-data/genetic-variants.parquet')

# Feature engineering
features = engineer_genetic_features(genetic_data)

# Train model
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(features, labels)

# Save to model registry
joblib.dump(model, 's3://healthcare-ml-models/genetic-risk-predictor/v1.1/model.pkl')

# Deploy to ModelMesh
deploy_model_to_serving(model, version="v1.1")
```

## Data Flow Integration

### Enhanced Genetic Analysis Pipeline

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Enhanced Data Flow with OpenShift AI                     │
└─────────────────────────────────────────────────────────────────────────────┘

User Input (Genetic Sequence)
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
│ VEP Service     │ 5. VEP annotation
│ (KNATIVE)       │ 6. ML feature extraction
│                 │ 7. Call OpenShift AI models
│ • Auto-scales   │ 8. Combine VEP + ML results
│ • ML Integration│ 9. Publish enhanced results
└─────────┬───────┘
          │ Multiple Outputs
          ├─────────────────────────────────────────┐
          │                                         │
          ▼                                         ▼
┌─────────────────┐                       ┌─────────────────┐
│ Kafka Cluster   │ 10. genetic-data-     │ OpenShift AI    │ 7. ML Inference
│ (3 replicas)    │     annotated topic   │ Platform        │
└─────────┬───────┘                       │                 │
          │ Kafka Consume                 │ • Risk Prediction│
          ▼                               │ • Drug Response  │
┌─────────────────┐                       │ • Clinical AI    │
│ WebSocket       │ 11. Format results    └─────────────────┘
│ Service         │ 12. Send to client
│ (DEPLOYMENT)    │
└─────────┬───────┘
          │ WebSocket Response
          ▼
┌─────────────────┐
│ WebSocket UI    │ 13. Display enhanced
│ (Browser)       │     genetic analysis
│                 │     + ML insights
└─────────────────┘
```

## Benefits and Consequences

### Positive Consequences

#### ✅ Enhanced Clinical Value
- **Risk Prediction**: ML-powered genetic risk assessment
- **Personalized Medicine**: Drug response predictions
- **Clinical Decision Support**: AI-powered treatment recommendations
- **Population Health**: Large-scale genomic analysis capabilities

#### ✅ Scalable ML Operations
- **Auto-scaling**: ML inference scales with demand
- **Cost Efficiency**: Pay-per-use model serving
- **Model Management**: Centralized model registry and versioning
- **Collaborative Development**: Jupyter notebooks for data scientists

#### ✅ Enterprise Integration
- **Security**: OpenShift AI security and compliance
- **Monitoring**: Integrated observability and logging
- **Resource Management**: GPU scheduling and optimization
- **Data Governance**: Controlled access to sensitive genetic data

### Challenges and Mitigations

#### ⚠️ Model Performance
- **Challenge**: ML model accuracy and reliability
- **Mitigation**: A/B testing, fallback to VEP-only results, continuous monitoring

#### ⚠️ Latency Considerations
- **Challenge**: ML inference adds processing time
- **Mitigation**: Model caching, async processing for non-critical predictions

#### ⚠️ Resource Requirements
- **Challenge**: GPU resources for complex models
- **Mitigation**: Efficient model serving, auto-scaling, cost monitoring

## Success Metrics

### ML Integration Metrics
- **Model Accuracy**: >95% for genetic risk predictions
- **Inference Latency**: <2s for real-time predictions
- **Model Availability**: 99.9% uptime for ML services
- **Cost Efficiency**: <$0.10 per genetic analysis

### System Performance Metrics
- **End-to-End Latency**: <7s including ML inference
- **Throughput**: 1000+ genetic analyses per hour
- **Resource Utilization**: 80% GPU utilization during peak
- **Auto-scaling Response**: <30s for ML model scaling

## Implementation Phases

### Phase 1: Basic ML Integration (Week 1-2)
- Deploy ModelMesh Serving
- Integrate simple risk prediction model
- Test VEP + ML pipeline

### Phase 2: Advanced Models (Week 3-4)
- Deploy pharmacogenomics models
- Add ancestry prediction
- Implement batch processing

### Phase 3: Research Platform (Week 5-6)
- Set up Jupyter notebooks
- Create data science pipelines
- Enable collaborative research

### Phase 4: Production Optimization (Week 7-8)
- Performance tuning
- Cost optimization
- Monitoring and alerting

## Related Decisions

- **ADR-001:** Deployment Strategy Correction (Prerequisite)
- **ADR-003:** Data Lake and Model Registry Strategy (Future)
- **ADR-004:** Cost Management and Resource Optimization (Future)
- **ADR-005:** Security and Compliance for Healthcare ML (Future)

## References

- [OpenShift AI Documentation](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed)
- [ModelMesh Serving](https://github.com/kserve/modelmesh-serving)
- [Jupyter Notebooks on OpenShift](https://jupyter-on-openshift.readthedocs.io/)
- [Healthcare ML Best Practices](https://www.nature.com/articles/s41591-019-0548-6)
- [ONNX Runtime](https://onnxruntime.ai/)
- [MLflow Model Registry](https://mlflow.org/docs/latest/model-registry.html)
