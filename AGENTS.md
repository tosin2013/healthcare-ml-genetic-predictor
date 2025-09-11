# Healthcare ML Genetic Predictor - AI Agent Accessibility Guide

## 🎯 Purpose
This document provides guidance for AI assistants and developers working with the Healthcare ML Genetic Prediction system. It enables AI agents to understand, interact with, and extend the system effectively.

## 📋 System Overview

A real-time genetic risk prediction system built with:
- **Quarkus WebSockets** for real-time communication
- **Apache Kafka** for event streaming
- **KEDA** for event-driven autoscaling
- **Python ML** for genetic analysis (Jupyter notebooks)
- **OpenShift** for container orchestration

## 🔌 API Endpoints & Integration Points

### WebSocket Service (Primary Interface)
- **URL**: `ws://quarkus-websocket-service-healthcare-ml-demo.<cluster-domain>/genetic-ws`
- **Protocol**: JSON messages over WebSocket
- **Authentication**: OpenShift service account tokens or OAuth

**Message Format:**
```json
{
  "type": "analysis_request",
  "sequence": "ATCGATCGATCG",
  "analysisType": "risk_prediction",
  "metadata": {
    "species": "human",
    "assembly": "GRCh38"
  }
}
```

### REST APIs
- **Health Check**: `GET /q/health` - System health status
- **Metrics**: `GET /q/metrics` - Prometheus metrics
- **Info**: `GET /q/info` - Application information

### Kafka Topics (Event Streaming)
- **Input**: `genetic-data-raw` - Raw genetic sequences for processing
- **Output**: `genetic-data-annotated` - Annotated results from VEP service
- **Big Data**: `genetic-bigdata-raw` - Memory-intensive processing
- **Node Scale**: `genetic-nodescale-raw` - Cluster autoscaling triggers

### OpenShift Resources
- **Namespace**: `healthcare-ml-demo`
- **Services**: quarkus-websocket-service, vep-service
- **Routes**: quarkus-websocket-service route for external access

## 🐍 Python ML Components

### Location
- `./notebooks/genetic-analysis/` - Jupyter notebooks for ML
- **01_genetic_risk_prediction.ipynb** - ML model training
- **02_kafka_realtime_processing.ipynb** - Real-time processing
- **03_cost_monitoring_scaling.ipynb** - Cost analysis

### Dependencies
See `requirements.txt` for pinned versions:
```bash
# Install all dependencies
pip install -r requirements.txt

# Or core dependencies only
pip install kafka-python pandas numpy scikit-learn matplotlib seaborn biopython requests
```

### Usage Examples

**Kafka Producer Example:**
```python
from kafka import KafkaProducer
import json

producer = KafkaProducer(
    bootstrap_servers='genetic-data-cluster-kafka-bootstrap.healthcare-ml-demo.svc.cluster.local:9092',
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

# Send genetic sequence
message = {
    'sequence': 'ATCGATCGATCG',
    'analysis_type': 'risk_prediction',
    'metadata': {'species': 'human'}
}
producer.send('genetic-data-raw', message)
```

**Kafka Consumer Example:**
```python
from kafka import KafkaConsumer
import json

consumer = KafkaConsumer(
    'genetic-data-annotated',
    bootstrap_servers='genetic-data-cluster-kafka-bootstrap.healthcare-ml-demo.svc.cluster.local:9092',
    value_deserializer=lambda x: json.loads(x.decode('utf-8'))
)

for message in consumer:
    print(f"Received annotated result: {message.value}")
```

## 🚀 Quick Start for AI Agents

### 1. Deploy the System
```bash
# Comprehensive deployment (recommended)
./scripts/deploy-clean-enhanced.sh

# Or basic deployment
./scripts/deploy-clean.sh
```

### 2. Access the Application
```bash
# Get WebSocket URL
oc get route quarkus-websocket-service -n healthcare-ml-demo -o jsonpath='{.spec.host}'

# Access web client
# https://<route-url>/genetic-client.html
```

### 3. Send Genetic Data
**Via WebSocket Client:**
- Open the genetic-client.html page
- Connect to WebSocket endpoint
- Send genetic sequences for processing

**Via Python Script:**
```python
# Use the kafka-python examples above
# Or use requests to trigger processing
import requests

response = requests.post(
    'http://quarkus-websocket-service:8080/api/analyze',
    json={'sequence': 'ATCGATCGATCG', 'type': 'risk'}
)
```

### 4. Monitor the System
```bash
# Check pods and scaling
oc get pods -n healthcare-ml-demo
oc get scaledobject -n healthcare-ml-demo

# Check Kafka topics
oc exec -n healthcare-ml-demo genetic-data-cluster-kafka-0 -- \
  kafka-topics.sh --list --bootstrap-server localhost:9092
```

## 🛠️ Development & Extension

### Adding New ML Models
1. Create new notebook in `notebooks/genetic-analysis/`
2. Train model using scikit-learn/xgboost
3. Export model using joblib/pickle
4. Integrate with Quarkus service via REST/WebSocket

### Creating New Kafka Consumers
1. Add new consumer group in Kafka configuration
2. Create new ScaledObject for KEDA autoscaling
3. Update deployment scripts to include new service

### Modifying Scaling Behavior
1. Edit KEDA ScaledObject configurations in `k8s/base/eventing/`
2. Adjust scaling thresholds and metrics
3. Test with different workload patterns

## 📊 Monitoring & Debugging

### Key Metrics to Monitor
- **Kafka Lag**: Message processing backlog
- **Pod Count**: Current number of running pods
- **CPU/Memory**: Resource utilization
- **WebSocket Connections**: Active client connections
- **Processing Latency**: Time from input to result

### Debugging Commands
```bash
# Check application logs
oc logs -f deployment/quarkus-websocket-service -n healthcare-ml-demo
oc logs -f deployment/vep-service -n healthcare-ml-demo

# Check Kafka status
oc get kafka -n healthcare-ml-demo
oc describe kafka genetic-data-cluster -n healthcare-ml-demo

# Check KEDA status
oc get pods -n openshift-keda
oc get scaledobject -n healthcare-ml-demo
```

## 🔒 Security Considerations

### For AI Agents Interacting with System
- Use service account tokens for authentication
- Respect resource limits and scaling constraints
- Validate all inputs to prevent injection attacks
- Follow HIPAA compliance guidelines for healthcare data

### For Development
- Never hardcode secrets in notebooks
- Use OpenShift secrets for sensitive configuration
- Implement proper input validation in ML models
- Regular security scanning of dependencies

## 📚 Additional Resources

- **[Main README](../README.md)** - Comprehensive project overview
- **[Deployment Guide](../DEPLOYMENT.md)** - Detailed deployment instructions
- **[API Documentation](../docs/reference/api-reference.md)** - Complete API reference
- **[Contributing Guide](../CONTRIBUTING.md)** - How to contribute to the project
- **[Diátaxis Documentation](../docs/README.md)** - Full documentation framework

## 🆘 Getting Help

### For AI Agents
- Check this AGENTS.md file first
- Review the main documentation in `docs/` directory
- Examine existing scripts in `scripts/` for examples
- Look at Kubernetes manifests in `k8s/` for configuration

### For Developers
- Use the advanced troubleshooting guide: `docs/how-to/advanced-troubleshooting-augment.md`
- Check GitHub issues for known problems
- Review OpenShift documentation for cluster-specific issues

---
*This AGENTS.md file was generated to enhance AI accessibility and should be maintained as the system evolves.*
*Last updated: 2025-09-11*