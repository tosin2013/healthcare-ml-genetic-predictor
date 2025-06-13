# Genetic Analysis Notebooks

This directory contains Jupyter notebooks for the Healthcare ML Demo on OpenShift AI.

## 📚 Notebooks Overview

### 1. `01_genetic_risk_prediction.ipynb`
**Genetic Risk Prediction Analysis**
- Load and analyze genetic sequence data
- Build machine learning models for risk prediction
- Exploratory data analysis and visualization
- Feature engineering from genetic sequences
- Model training and evaluation

**Key Features:**
- Random Forest classifier for risk prediction
- GC content analysis and sequence pattern recognition
- Synthetic genetic data generation
- Performance metrics and feature importance

### 2. `02_kafka_realtime_processing.ipynb`
**Real-time Genetic Data Processing with Kafka**
- Connect to Kafka cluster for real-time processing
- Send genetic sequences for VEP annotation
- Monitor annotated results from VEP service
- Trigger KEDA scaling events
- Demonstrate multi-tier scaling

**Key Features:**
- Kafka producer/consumer integration
- Real-time message processing
- Scaling event triggers
- Big data mode simulation

### 3. `03_cost_monitoring_scaling.ipynb`
**Cost Monitoring and Scaling Analysis**
- Monitor OpenShift resource usage
- Track KEDA scaling events
- Analyze cost attribution
- Generate cost reports
- Live monitoring dashboard

**Key Features:**
- Resource usage visualization
- Cost calculation and attribution
- Scaling pattern analysis
- Real-time monitoring functions

## 🗂️ Data Files

### `sample_genetic_data.csv`
Sample genetic sequence data with:
- Sequence ID and DNA sequence
- Species and genome assembly information
- Risk scores and classifications
- GC content and sequence metrics

## 🚀 Getting Started

### Prerequisites
```bash
# Install required packages (run in notebook)
pip install kafka-python pandas numpy scikit-learn matplotlib seaborn biopython requests
```

### Environment Setup
The notebooks are configured to work with:
- **Kafka Cluster**: `genetic-data-cluster-kafka-bootstrap.healthcare-ml-demo.svc.cluster.local:9092`
- **Topics**: 
  - `genetic-data-raw` (input)
  - `genetic-data-annotated` (output)
- **VEP Service**: Independent annotation service
- **KEDA Scalers**: Configured for auto-scaling

### Running the Notebooks

1. **Start with Notebook 1**: Basic genetic analysis and ML model training
2. **Move to Notebook 2**: Real-time Kafka processing and scaling
3. **Use Notebook 3**: Monitor costs and scaling patterns

## 🎯 Demo Scenarios

### Scenario 1: Basic ML Analysis
- Run notebook 1 to demonstrate genetic risk prediction
- Show model training and evaluation
- Visualize genetic sequence patterns

### Scenario 2: Real-time Processing
- Use notebook 2 to send genetic data to Kafka
- Monitor VEP service processing
- Trigger scaling events with large batches

### Scenario 3: Cost Monitoring
- Run notebook 3 to monitor resource usage
- Generate cost reports
- Analyze scaling impact on costs

## 🔧 Integration Points

### Kafka Integration
- **Producer**: Sends genetic sequences to `genetic-data-raw` topic
- **Consumer**: Receives annotated results from `genetic-data-annotated` topic
- **VEP Service**: Processes sequences and adds annotations

### KEDA Scaling
- **Kafka Lag Scaler**: Scales VEP service based on message lag
- **CPU/Memory Scalers**: Scales based on resource usage
- **Custom Metrics**: Supports custom scaling triggers

### Cost Attribution
- **Resource Monitoring**: Tracks CPU and memory usage
- **Cost Calculation**: Estimates costs based on usage
- **Scaling Impact**: Shows cost changes during scaling events

## 📊 Expected Outputs

### Machine Learning Results
- Risk prediction accuracy: ~85-90%
- Feature importance rankings
- Confusion matrices and performance metrics

### Scaling Demonstrations
- Pod scaling from 1 to 3+ replicas
- Message processing rate improvements
- Cost attribution changes

### Cost Analysis
- Hourly cost estimates: $0.10-0.50/hour
- Component-level cost breakdown
- Scaling impact on total costs

## 🔍 Troubleshooting

### Kafka Connection Issues
```python
# Check Kafka connectivity
KAFKA_BOOTSTRAP_SERVERS = 'genetic-data-cluster-kafka-bootstrap.healthcare-ml-demo.svc.cluster.local:9092'
```

### VEP Service Issues
- Ensure VEP service is running and healthy
- Check topic configuration and message format
- Verify KEDA scalers are active

### Resource Monitoring
- OpenShift API access may be limited in notebook environment
- Some metrics are simulated for demonstration purposes
- Real production deployment would use OpenShift monitoring APIs

## 📚 References

- **PMC7613081**: Machine learning approaches for genetic risk prediction
- **VEP Documentation**: Ensembl Variant Effect Predictor
- **KEDA Documentation**: Kubernetes Event-driven Autoscaling
- **OpenShift AI**: Red Hat OpenShift AI platform

## 🎉 Demo Tips

1. **Start Small**: Begin with small batches to show basic functionality
2. **Scale Up**: Gradually increase batch sizes to trigger scaling
3. **Monitor Costs**: Use cost monitoring to show real-time attribution
4. **Show Integration**: Demonstrate end-to-end pipeline from notebook to VEP service
5. **Highlight Benefits**: Emphasize scale-to-zero, cost efficiency, and real-time processing

---

**Healthcare ML Demo on OpenShift AI**  
*Demonstrating multi-tier scaling, cost attribution, and real-time genetic analysis*
