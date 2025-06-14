# Healthcare ML Genetic Risk Predictor

A real-time genetic risk prediction system built with Quarkus WebSockets, deployed on Azure Red Hat OpenShift with event-driven architecture and scale-to-zero capabilities.

## 🧬 Overview

This project implements a healthcare ML application that processes genetic data in real-time using WebSocket connections, Kafka event streaming, and machine learning inference. The system is designed for cost-effective deployment on OpenShift with comprehensive monitoring and HIPAA-compliant security.

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Web Client    │───▶│  Quarkus WebSocket │───▶│  Kafka Cluster  │
│  (Genetic UI)   │    │     Service        │    │ (AMQ Streams)   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                         │
                                ▼                         ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │   Health Checks  │    │  ML Inference   │
                       │   & Metrics      │    │   (Knative)     │
                       └──────────────────┘    └─────────────────┘
```

### Key Components

- **Quarkus WebSocket Service**: Real-time genetic data processing
- **Apache Kafka**: Event streaming for genetic data pipeline
- **Knative Serving**: Scale-to-zero ML inference services
- **KEDA**: Event-driven autoscaling based on Kafka lag
- **Red Hat Insights**: Cost management and observability

## 🚀 Quick Start

### Prerequisites

- Azure Red Hat OpenShift cluster
- OpenShift CLI (`oc`) installed and logged in
- Git repository access

### Deploy to OpenShift

**📖 For complete deployment instructions, see [DEPLOYMENT.md](DEPLOYMENT.md)**

**✅ Automated Deployment (Recommended):**
```bash
# Clone repository
git clone https://github.com/tosin2013/healthcare-ml-genetic-predictor.git
cd healthcare-ml-genetic-predictor

# Run validated deployment script
./scripts/deploy-clean.sh

# Access application (get URL from script output)
```

**Manual Quick Start:**
```bash
# 1. Clone repository
git clone https://github.com/tosin2013/healthcare-ml-genetic-predictor.git
cd healthcare-ml-genetic-predictor

# 2. Deploy operators
oc apply -k k8s/base/operators

# 3. Deploy infrastructure
oc apply -k k8s/base/infrastructure

# 4. Deploy applications
oc apply -k k8s/base/applications/quarkus-websocket -n healthcare-ml-demo
oc apply -k k8s/base/applications/vep-service -n healthcare-ml-demo

# 5. Grant permissions and start builds
oc policy add-role-to-user system:image-puller system:serviceaccount:healthcare-ml-demo:vep-service -n healthcare-ml-demo
oc start-build quarkus-websocket-service -n healthcare-ml-demo
oc start-build vep-service -n healthcare-ml-demo

# 6. Access application
oc get route quarkus-websocket-service -n healthcare-ml-demo
# Open: https://<route-url>/genetic-client.html
```

## 📁 Project Structure

```
healthcare-ml-genetic-predictor/
├── quarkus-websocket-service/          # Quarkus WebSocket application
│   ├── src/main/java/                  # Java source code
│   ├── src/main/resources/             # Application resources
│   └── pom.xml                         # Maven configuration
├── k8s/                                # OpenShift/Kubernetes manifests
│   ├── base/                           # Base Kustomize resources
│   │   ├── operators/                  # Operator subscriptions
│   │   ├── infrastructure/             # Kafka, namespace
│   │   ├── applications/               # Application deployments
│   │   └── eventing/                   # KEDA, Knative eventing
│   ├── overlays/                       # Environment-specific configs
│   │   ├── dev/                        # Development environment
│   │   ├── staging/                    # Staging environment
│   │   └── prod/                       # Production environment
│   └── components/                     # Reusable components
├── docs/                               # Documentation
├── research.md                         # Technical research notes
└── README.md                           # This file
```

## 🔧 Technology Stack

### Application Layer
- **Quarkus 3.8.6**: Cloud-native Java framework
- **WebSockets**: Real-time genetic data communication
- **SmallRye Reactive Messaging**: Kafka integration
- **Micrometer**: Metrics and monitoring

### Infrastructure Layer
- **Azure Red Hat OpenShift**: Container orchestration
- **AMQ Streams (Kafka)**: Event streaming platform
- **OpenShift Serverless (Knative)**: Scale-to-zero services
- **KEDA**: Event-driven autoscaling
- **OpenShift AI**: ML model serving

### Deployment & Operations
- **Kustomize**: Configuration management
- **OpenShift BuildConfig**: Source-to-Image builds
- **Red Hat Insights**: Cost management
- **Prometheus**: Metrics collection

## 🧪 Testing

### Local Development
```bash
cd quarkus-websocket-service
./mvnw quarkus:dev
```

### WebSocket Testing
Open `http://localhost:8080/genetic-client.html` and test with sample genetic sequences:
- Basic DNA: `ATCGATCGATCG`
- Complex: `ATGCGTACGTAGCTAGCTA`

### Health Checks
```bash
curl http://localhost:8080/q/health
curl http://localhost:8080/q/metrics
```

## 📊 Monitoring & Observability

### Cost Management
- **Red Hat Insights**: Integrated cost tracking
- **Cost Center**: `genomics-research`
- **Project**: `risk-predictor-v1`
- **Billing Model**: Chargeback

### Metrics
- Application metrics via Micrometer/Prometheus
- Kafka metrics for genetic data processing
- KEDA scaling metrics
- Custom healthcare ML metrics

## 🔒 Security & Compliance

### HIPAA Compliance
- Non-root container execution
- Security Context Constraints (SCC)
- Network policies for traffic isolation
- Audit logging enabled

### Security Features
- TLS encryption for all communications
- RBAC for service account permissions
- Secure secrets management
- Container image scanning

## 🌍 Environment Configuration

### Development
- Minimal resource allocation
- Ephemeral storage
- Debug logging enabled
- Single replicas

### Production
- High availability setup
- Persistent storage with backup
- Strict resource limits
- Production monitoring

## 📈 Scaling & Performance

### Scale-to-Zero
- **KEDA**: Kafka lag-based scaling
- **Knative**: HTTP traffic-based scaling
- **Cold Start**: <10 seconds
- **Cost Optimization**: Zero cost when idle

### Performance Targets
- WebSocket connection: <100ms latency
- Genetic sequence processing: <500ms
- Kafka message throughput: 1000 msg/sec
- Concurrent connections: 100+

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally and on OpenShift
5. Submit a pull request

## 📚 Documentation

- [Quarkus WebSocket Service](./quarkus-websocket-service/README.md)
- [OpenShift Deployment Guide](./k8s/README.md)
- [Technical Research](./research.md)
- [Development Specification](./dev.spec.md)

## 📞 Support

For questions or issues:
1. Check the documentation
2. Review OpenShift logs: `oc logs -f deployment/quarkus-websocket-service -n healthcare-ml-demo`
3. Validate configurations: `kustomize build k8s/base`
4. Contact the development team

## 📄 License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.

---

**Built with ❤️ for healthcare innovation on Azure Red Hat OpenShift**
