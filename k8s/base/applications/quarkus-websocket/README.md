# Quarkus WebSocket Service - OpenShift Deployment

This directory contains the Kustomize resources for deploying the Quarkus WebSocket service on OpenShift with BuildConfig integration.

## Deployment Options

### Option 1: OpenShift BuildConfig (Recommended)
Uses OpenShift's native build system to build the application from source.

**Resources included:**
- `buildconfig.yaml` - Builds the Quarkus application from Git source
- `imagestream.yaml` - Manages the built container image
- `deployment.yaml` - Standard Kubernetes Deployment
- `service.yaml` - ClusterIP service
- `route.yaml` - OpenShift route with TLS
- `configmap.yaml` - Application configuration

**Prerequisites:**
1. Source code available in Git repository
2. OpenShift cluster with build capabilities
3. Sufficient build resources allocated

**Deployment:**
```bash
# Deploy with BuildConfig
oc apply -k k8s/base/applications/quarkus-websocket

# Trigger a build
oc start-build quarkus-websocket-service -n healthcare-ml-demo

# Monitor build progress
oc logs -f bc/quarkus-websocket-service -n healthcare-ml-demo
```

### Option 2: OpenShift DeploymentConfig (Alternative)
Uses OpenShift's DeploymentConfig for enhanced integration with ImageStreams.

**To use DeploymentConfig instead of Deployment:**
1. Edit `kustomization.yaml`
2. Comment out `deployment.yaml`
3. Uncomment `deploymentconfig.yaml`

```yaml
resources:
  - configmap.yaml
  - imagestream.yaml
  - buildconfig.yaml
  # - deployment.yaml          # Standard Kubernetes Deployment
  - deploymentconfig.yaml      # OpenShift DeploymentConfig
  - service.yaml
  - route.yaml
```

### Option 3: External Container Registry
For pre-built images from external registries.

**To use external images:**
1. Comment out `buildconfig.yaml` and `imagestream.yaml`
2. Uncomment the `images` section in `kustomization.yaml`
3. Update the image reference

## Build Configuration

### Source Configuration
The BuildConfig is configured to:
- Pull source from Git repository
- Use `quarkus-websocket-service` as context directory
- Build with Red Hat UBI9 OpenJDK 17 base image
- Execute Maven build with `clean package -DskipTests`

### Build Triggers
- **ConfigChange**: Triggers build when BuildConfig changes
- **ImageChange**: Triggers build when base image updates

### Build Resources
- **Requests**: 500m CPU, 1Gi memory
- **Limits**: 2000m CPU, 2Gi memory

## Environment Configuration

### ConfigMap Variables
The application uses a ConfigMap for configuration:
- Kafka bootstrap servers
- Quarkus HTTP settings
- WebSocket configuration
- Health check settings
- Metrics configuration

### Environment Variables
Key environment variables:
- `KAFKA_BOOTSTRAP_SERVERS`: Kafka cluster connection
- `QUARKUS_HTTP_HOST`: HTTP bind address
- `QUARKUS_HTTP_PORT`: HTTP port

## Health Checks

### Liveness Probe
- **Path**: `/q/health/live`
- **Initial Delay**: 30 seconds
- **Period**: 10 seconds

### Readiness Probe
- **Path**: `/q/health/ready`
- **Initial Delay**: 5 seconds
- **Period**: 5 seconds

## Security

### Security Context
- **Non-root user**: UID 185
- **Dropped capabilities**: ALL
- **No privilege escalation**
- **Runtime security profile**: RuntimeDefault

### TLS Configuration
- **Route TLS**: Edge termination
- **Insecure traffic**: Redirected to HTTPS

## Monitoring and Observability

### Metrics
- Prometheus metrics enabled via Quarkus Micrometer
- Custom healthcare ML metrics available

### Logging
- Configurable log levels
- Healthcare-specific debug logging
- JSON log format for structured logging

## Troubleshooting

### Build Issues
```bash
# Check build status
oc get builds -n healthcare-ml-demo

# View build logs
oc logs build/quarkus-websocket-service-1 -n healthcare-ml-demo

# Check build config
oc describe bc/quarkus-websocket-service -n healthcare-ml-demo
```

### Deployment Issues
```bash
# Check deployment status
oc get deployment quarkus-websocket-service -n healthcare-ml-demo

# View pod logs
oc logs deployment/quarkus-websocket-service -n healthcare-ml-demo

# Check service endpoints
oc get endpoints quarkus-websocket-service -n healthcare-ml-demo
```

### Route Issues
```bash
# Check route status
oc get route quarkus-websocket-service -n healthcare-ml-demo

# Test route connectivity
curl -k https://$(oc get route quarkus-websocket-service -o jsonpath='{.spec.host}')/q/health
```

## Cost Management

All resources include cost attribution labels:
- `cost-center: "genomics-research"`
- `project: "risk-predictor-v1"`

These labels integrate with Red Hat Insights Cost Management for chargeback and cost analysis.
