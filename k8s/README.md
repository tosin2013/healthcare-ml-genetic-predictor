# Healthcare ML Application - Kustomize Deployment

This directory contains the Kustomize-based deployment structure for the event-driven healthcare ML application on Azure Red Hat OpenShift (ARO).

## Directory Structure

```
k8s/
├── base/                           # Base Kustomize resources
│   ├── operators/                  # OpenShift operator subscriptions
│   │   ├── amq-streams/           # AMQ Streams (Kafka) operator
│   │   ├── serverless/            # OpenShift Serverless operator
│   │   ├── keda/                  # KEDA autoscaling operator
│   │   └── openshift-ai/          # OpenShift AI operator
│   ├── infrastructure/            # Core infrastructure components
│   │   ├── namespace/             # Project namespace with cost labels
│   │   └── kafka/                 # Kafka cluster and topics
│   ├── applications/              # Application deployments
│   │   ├── quarkus-websocket/     # Quarkus WebSocket service
│   │   ├── ml-inference/          # ML inference Knative service
│   │   └── frontend/              # 8-bit genetic simulator frontend
│   ├── eventing/                  # Event-driven components
│   │   ├── kafka-source/          # Knative Kafka event source
│   │   └── keda-scaler/           # KEDA scaling configuration
│   └── kustomization.yaml         # Base kustomization file
├── overlays/                      # Environment-specific configurations
│   ├── dev/                       # Development environment
│   ├── staging/                   # Staging environment
│   └── prod/                      # Production environment
├── components/                    # Reusable Kustomize components
│   ├── cost-labels/               # Cost attribution labels
│   └── security-context/         # Security context configurations
└── README.md                      # This documentation
```

## Deployment Strategy

### Phase 1: Operators
Deploy required OpenShift operators via OLM subscriptions:
- AMQ Streams for Kafka management
- OpenShift Serverless for Knative services
- KEDA for event-driven autoscaling
- OpenShift AI for ML model serving

### Phase 2: Infrastructure
Deploy core infrastructure components:
- Namespace with Red Hat Insights cost labels
- Kafka cluster and topics for event streaming

### Phase 3: Applications
Deploy application components:
- Quarkus WebSocket service for real-time communication
- 8-bit frontend game for genetic data simulation
- ML inference service with scale-to-zero capability

### Phase 4: Eventing
Configure event-driven architecture:
- KafkaSource for event routing
- KEDA ScaledObject for autoscaling based on Kafka lag

## Environment Management

### Development (dev)
- Minimal resource allocation
- Ephemeral storage
- Single replicas
- Debug logging enabled

### Staging (staging)
- Production-like configuration
- Persistent storage
- Moderate resource allocation
- Performance testing ready

### Production (prod)
- High availability setup
- Persistent storage with backup
- Strict resource limits
- Production monitoring

## Cost Management

All resources include consistent cost attribution labels:
- `cost-center: "genomics-research"`
- `project: "risk-predictor-v1"`

These labels integrate with Red Hat Insights Cost Management for granular chargeback and cost analysis.

## Usage

### Build and Validate
```bash
# Validate base configuration
kustomize build k8s/base

# Build environment-specific configuration
kustomize build k8s/overlays/dev
kustomize build k8s/overlays/staging
kustomize build k8s/overlays/prod
```

### Deploy to OpenShift
```bash
# Deploy to development environment
oc apply -k k8s/overlays/dev

# Deploy to staging environment
oc apply -k k8s/overlays/staging

# Deploy to production environment
oc apply -k k8s/overlays/prod
```

### GitOps Integration
This structure is compatible with:
- OpenShift GitOps (ArgoCD)
- Tekton Pipelines
- Red Hat Advanced Cluster Management

## Security Considerations

- All containers run as non-root users
- OpenShift Security Context Constraints (SCC) compliance
- Network policies for traffic isolation
- RBAC for service account permissions
- Healthcare-grade security standards

## Monitoring and Observability

- OpenShift monitoring integration
- Custom metrics for ML workload performance
- Cost correlation with workload activity
- Event-driven scaling metrics via KEDA

## Support

For questions or issues:
1. Review this documentation
2. Check OpenShift logs: `oc logs -f deployment/<service-name>`
3. Validate Kustomize builds: `kustomize build <path>`
4. Consult Red Hat OpenShift documentation
