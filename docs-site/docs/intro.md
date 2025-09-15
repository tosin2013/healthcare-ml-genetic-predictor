---
sidebar_position: 1
---

# Healthcare ML Genetic Predictor

A real-time genetic risk prediction system built with Quarkus WebSockets, deployed on Azure Red Hat OpenShift with event-driven architecture and scale-to-zero capabilities.

## 🚀 Quick Start

### For Developers
- **[Getting Started](./tutorials/01-getting-started.md)** - Set up your development environment
- **[Local Development](./tutorials/02-local-development.md)** - Run the system locally
- **[First Genetic Analysis](./tutorials/03-first-genetic-analysis.md)** - Process your first genetic sample

### For Operators
- **[Deploy to OpenShift](./deploy-openshift.md)** - Production deployment guide
- **[Monitor Costs](./monitor-costs.md)** - Cost optimization and monitoring
- **[Troubleshooting](./troubleshoot-websocket.md)** - Common issues and solutions

## 🏗️ System Architecture

### Core Components
- **WebSocket Service**: Real-time genetic analysis with persistent connections
- **VEP Service**: Variant Effect Predictor with event-driven scaling
- **Kafka**: Message broker for event-driven architecture
- **KEDA**: Kubernetes Event-Driven Autoscaling
- **OpenShift AI**: Machine learning integration platform

### Key Features
- ⚡ **Real-time Processing**: WebSocket-based genetic analysis
- 📈 **Auto-scaling**: Scale-to-zero with KEDA and Kafka lag metrics
- 🔒 **Healthcare Security**: HIPAA-compliant architecture
- 💰 **Cost Optimization**: Pay-per-use scaling model
- 🧠 **ML Integration**: OpenShift AI for advanced genetic predictions

## 📚 Documentation Structure

### Tutorials
Step-by-step guides for common tasks and workflows:
- Getting started with development
- Local development setup
- Genetic analysis workflows
- Scaling demonstrations

### How-To Guides
Practical solutions for specific problems:
- Deployment procedures
- Troubleshooting guides
- Configuration management
- Cost optimization

### Reference
Technical specifications and API documentation:
- API references
- Architecture decisions
- Quality assurance frameworks
- Performance benchmarks

### Explanation
Conceptual background and architecture:
- System architecture deep dives
- Scaling strategies
- Design patterns and decisions

## 🎯 Use Cases

### Clinical Applications
- Real-time genetic risk assessment
- Personalized medicine recommendations
- Clinical decision support systems
- Pharmacogenomics analysis

### Research Applications
- Population genomics studies
- Genetic variant analysis
- Machine learning model development
- Collaborative research platforms

## 🔧 Technology Stack

- **Backend**: Quarkus, Java, WebSockets
- **Messaging**: Apache Kafka
- **Container Platform**: Azure Red Hat OpenShift
- **Scaling**: KEDA (Kubernetes Event-Driven Autoscaling)
- **Machine Learning**: OpenShift AI, Python, Scikit-learn
- **Monitoring**: Prometheus, Grafana
- **CI/CD**: GitHub Actions, OpenShift Pipelines

## 🚦 Getting Help

### Support Channels
- **Documentation**: This site contains comprehensive guides
- **GitHub Issues**: Report bugs and request features
- **Team Support**: Contact the development team for assistance

### Common Resources
- [Architecture Decisions](./architecture-decisions.md) - Design rationale and decisions
- [API Reference](./api-reference.md) - Complete API documentation
- [Troubleshooting Guide](./troubleshoot-websocket.md) - Common issues and solutions

## 📊 System Status

### Current Implementation
✅ **Working Features**:
- Kafka 3-replica cluster
- VEP service functionality  
- Basic genetic analysis
- OpenShift infrastructure

🔄 **In Progress**:
- WebSocket deployment optimization
- OpenShift AI integration
- Advanced ML models
- Cost management setup

## 🔗 Quick Links

- [GitHub Repository](https://github.com/tosin2013/healthcare-ml-genetic-predictor)
- [Architecture Decisions](./architecture-decisions.md)
- [API Documentation](./api-reference.md)
- [Deployment Guide](./deploy-openshift.md)

---

**Last Updated**: 2025-09-11  
**Version**: 2.0  
**Status**: Production Ready