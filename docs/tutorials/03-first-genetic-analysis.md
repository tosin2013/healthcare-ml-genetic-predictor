# First Genetic Analysis Tutorial

**Learn how to perform genetic sequence analysis using the healthcare ML system's VEP annotation pipeline**

## 🎯 Learning Objectives

By the end of this tutorial, you will:
- ✅ Understand genetic sequence formats and VEP annotation
- ✅ Perform your first genetic analysis using multiple interfaces
- ✅ Interpret VEP results and genetic annotations
- ✅ Monitor the complete data flow from input to results
- ✅ Understand when to use different analysis modes

**⏱️ Estimated Time**: 20-30 minutes
**👥 Audience**: Healthcare researchers, bioinformaticians, developers
**📋 Prerequisites**: Completed [Getting Started Tutorial](01-getting-started.md) or [Local Development Tutorial](02-local-development.md)

## 🧬 Understanding Genetic Analysis

### What is VEP (Variant Effect Predictor)?

The Variant Effect Predictor (VEP) is Ensembl's tool for analyzing genetic variants and their potential effects:

- **🔬 Variant Analysis**: Determines the effects of genetic variants on genes, transcripts, and proteins
- **📊 Functional Annotation**: Provides SIFT and PolyPhen predictions for protein function
- **🧬 Gene Mapping**: Maps variants to genes and transcripts
- **⚕️ Clinical Relevance**: Identifies potentially pathogenic variants

### Genetic Sequence Formats

The system accepts genetic sequences in various formats:

```bash
# Simple DNA sequence (ATCG nucleotides)
ATCGATCGATCGATCGATCG

# Larger sequences for comprehensive analysis
ATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCG

# Very large sequences for node scaling demonstrations
# (Generated programmatically for load testing)
```

## 🚀 Part 1: Web Interface Analysis

### Step 1: Access the Frontend Interface

Open the Healthcare ML Genetic Predictor interface:

```bash
# Get the application URL
echo "🌐 Frontend URL: https://quarkus-websocket-service-healthcare-ml-demo.apps.b9892ub1.eastus.aroapp.io/genetic-client.html"

# Or for local development:
echo "🌐 Local URL: http://localhost:8080/genetic-client.html"
```

### Step 2: Connect to WebSocket Service

1. **Open the frontend interface** in your web browser
2. **Click "Connect"** to establish WebSocket connection
3. **Verify connection status** shows "Connected to Healthcare ML Service"
4. **Check the real-time scaling monitor** displays current system status

### Step 3: Perform Basic Genetic Analysis

**Test Sequence**: `ATCGATCGATCGATCGATCG` (20 base pairs)

1. **Enter the test sequence** in the genetic data input field
2. **Select "Normal Mode"** for standard processing
3. **Click "Analyze Genetic Sequence"**
4. **Monitor the progress** in real-time:
   - Sequence queued for processing
   - VEP service scaling up (if needed)
   - Processing status updates
   - Final results with annotations

### Step 4: Interpret the Results

Expected VEP analysis results include:

```json
{
  "sessionId": "session-12345",
  "sequence": "ATCGATCGATCGATCGATCG",
  "analysis": {
    "variant_count": 0,
    "gene_annotations": [],
    "processing_time": "2.3s",
    "vep_version": "110"
  },
  "status": "completed"
}
```

**Key Result Components**:
- **Variant Count**: Number of genetic variants identified
- **Gene Annotations**: Mapped genes and their functions
- **Processing Time**: Time taken for VEP analysis
- **Status**: Completion status of the analysis

## 🔌 Part 2: WebSocket Client Analysis

### Step 1: Use Node.js WebSocket Client


````bash
# Test normal mode with 20bp sequence
node scripts/test-websocket-client.js normal --generate 50
````
🔄 Kafka Lag Mode (KEDA Consumer Lag)

**Expected Output**:
```
🧬 Healthcare ML WebSocket Client Test
=====================================
WebSocket URL: wss://quarkus-websocket-service-healthcare-ml-demo.apps.b9892ub1.eastus.aroapp.io/genetics
Mode: normal
Sequence: ATCGATCGATCGATCGATCG (20 chars)
Timeout: 120 seconds

🔌 Connecting to WebSocket...
✅ Connected in 234ms

📤 Sending normal mode genetic sequence...
📨 Message sent at 2024-01-15T10:30:45.123Z
⏳ Waiting for VEP processing results...

📥 Message received at 2024-01-15T10:30:47.456Z
⏱️  Response time: 2333ms
🎉 VEP RESULTS RECEIVED!
📊 Results: **Genetic Analysis Complete** - Sequence: ATCGATCGATCGATCGATCG...
```

### Step 2: Test Different Sequence Sizes

```bash
# Small sequence (20bp) - Normal processing
node scripts/test-websocket-client.js normal "ATCGATCGATCGATCGATCG" 60

# Medium sequence (100bp) - Still normal processing
MEDIUM_SEQ=$(printf 'ATCG%.0s' {1..25})
node scripts/test-websocket-client.js normal "$MEDIUM_SEQ" 90

# Large sequence (1KB) - May trigger different processing
LARGE_SEQ=$(printf 'ATCG%.0s' {1..250})
node scripts/test-websocket-client.js big-data "$LARGE_SEQ" 180
```

### Step 3: Monitor Processing Flow

While running the WebSocket client, monitor the backend processing:

```bash
# Monitor VEP service pods
watch 'oc get pods -l app=vep-service'

# Monitor Kafka consumer lag
watch 'oc exec genetic-data-cluster-kafka-0 -- /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 --describe --group vep-service-group'

# Check VEP service logs
oc logs -f -l app=vep-service
```

## 🌐 Part 3: API-Based Analysis

### Step 1: Direct API Testing

Test the genetic analysis API endpoints directly:

```bash
# Set the base URL
BASE_URL="https://quarkus-websocket-service-healthcare-ml-demo.apps.b9892ub1.eastus.aroapp.io"

# Test normal mode analysis
curl -X POST $BASE_URL/api/genetic/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "sequence": "ATCGATCGATCGATCGATCG",
    "resourceProfile": "standard"
  }'
```

**Expected Response**:
```json
{
  "status": "success",
  "message": "Genetic sequence queued for analysis",
  "data": {
    "sessionId": "session-abc123",
    "sequence": "ATCGATCGATCGATCGATCG",
    "mode": "normal",
    "estimatedProcessingTime": "15-30 seconds"
  }
}
```

### Step 2: Test Different Resource Profiles

```bash
# Standard processing (normal mode)
curl -X POST $BASE_URL/api/genetic/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "sequence": "ATCGATCGATCGATCGATCG",
    "resourceProfile": "standard"
  }'

# High-memory processing (big data mode)
LARGE_SEQUENCE=$(printf 'ATCG%.0s' {1..500})
curl -X POST $BASE_URL/api/genetic/analyze \
  -H "Content-Type: application/json" \
  -d "{
    \"sequence\": \"$LARGE_SEQUENCE\",
    \"resourceProfile\": \"high-memory\"
  }"

# Cluster-scale processing (node scale mode)
HUGE_SEQUENCE=$(printf 'ATCG%.0s' {1..2500})
curl -X POST $BASE_URL/api/genetic/analyze \
  -H "Content-Type: application/json" \
  -d "{
    \"sequence\": \"$HUGE_SEQUENCE\",
    \"resourceProfile\": \"cluster-scale\"
  }"
```

### Step 3: Monitor API Processing

```bash
# Check scaling status
curl -X GET $BASE_URL/api/scaling/status

# Check system health
curl -X GET $BASE_URL/api/scaling/health

# Monitor processing mode
curl -X GET $BASE_URL/api/scaling/mode

## 📊 Part 4: Understanding VEP Results

### Interpreting Genetic Annotations

VEP analysis provides several types of annotations:

#### Basic Sequence Information
```json
{
  "input_sequence": "ATCGATCGATCGATCGATCG",
  "sequence_length": 20,
  "gc_content": 50.0,
  "analysis_timestamp": "2024-01-15T10:30:45Z"
}
```

#### Variant Analysis Results
```json
{
  "variant_count": 2,
  "variants": [
    {
      "position": 5,
      "reference": "A",
      "alternate": "T",
      "consequence": "missense_variant",
      "gene": "BRCA1",
      "transcript": "ENST00000357654",
      "sift_prediction": "deleterious",
      "polyphen_prediction": "probably_damaging"
    }
  ]
}
```

#### Gene Mapping Information
```json
{
  "mapped_genes": [
    {
      "gene_id": "ENSG00000012048",
      "gene_symbol": "BRCA1",
      "gene_description": "BRCA1 DNA repair associated",
      "chromosome": "17",
      "strand": "-1"
    }
  ]
}
```

### Clinical Significance

**SIFT Predictions**:
- **Tolerated**: Variant likely has no effect on protein function
- **Deleterious**: Variant likely affects protein function

**PolyPhen Predictions**:
- **Benign**: Variant likely harmless
- **Possibly Damaging**: Variant may affect protein function
- **Probably Damaging**: Variant likely affects protein function

## 🔍 Part 5: Data Flow Monitoring

### Step 1: Monitor Kafka Message Flow

Track messages through the complete pipeline:

```bash
# Monitor input topic (genetic-data-raw)
oc exec genetic-data-cluster-kafka-0 -- /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 --topic genetic-data-raw --from-beginning

# Monitor output topic (genetic-data-annotated) in another terminal
oc exec genetic-data-cluster-kafka-0 -- /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 --topic genetic-data-annotated --from-beginning
```

### Step 2: Monitor VEP Service Processing

```bash
# Watch VEP service logs for processing activity
oc logs -f -l app=vep-service | grep -E "(Processing|CloudEvent|genetic|VEP|annotation)"

# Monitor VEP service scaling
watch 'oc get pods -l app=vep-service --show-labels'

# Check KEDA scaling metrics
oc describe scaledobject vep-service-scaler | grep -A 10 "External Metric Names"
```

### Step 3: End-to-End Flow Verification

```bash
# Send a test sequence and monitor complete flow
echo "🧬 Sending test sequence..."
curl -X POST $BASE_URL/api/genetic/analyze \
  -H "Content-Type: application/json" \
  -d '{"sequence": "ATCGATCGATCGATCGATCG", "resourceProfile": "standard"}'

# Monitor the flow:
# 1. Message appears in genetic-data-raw topic
# 2. VEP service pod scales up (if at 0)
# 3. VEP processing logs show activity
# 4. Annotated results appear in genetic-data-annotated topic
# 5. WebSocket service delivers results to frontend
```

## 🧪 Part 6: Advanced Analysis Scenarios

### Scenario 1: Batch Processing

Process multiple sequences for comparative analysis:

```bash
# Generate multiple test sequences
for i in {1..5}; do
  SEQUENCE=$(printf 'ATCG%.0s' {1..20})
  curl -X POST $BASE_URL/api/genetic/analyze \
    -H "Content-Type: application/json" \
    -d "{\"sequence\": \"$SEQUENCE\", \"resourceProfile\": \"standard\"}"
  sleep 2
done
```

### Scenario 2: Large Sequence Analysis

Test with progressively larger sequences:

```bash
# 100bp sequence
SEQ_100=$(printf 'ATCG%.0s' {1..25})
node scripts/test-websocket-client.js normal "$SEQ_100" 90

# 1KB sequence (triggers big-data mode)
SEQ_1K=$(printf 'ATCG%.0s' {1..250})
node scripts/test-websocket-client.js big-data "$SEQ_1K" 180

# 10KB sequence (may trigger node scaling)
SEQ_10K=$(printf 'ATCG%.0s' {1..2500})
node scripts/test-websocket-client.js node-scale "$SEQ_10K" 300
```

### Scenario 3: Real-Time Monitoring

Monitor system behavior during analysis:

```bash
# Start monitoring in multiple terminals:

# Terminal 1: Pod scaling
watch 'oc get pods -l app=vep-service'

# Terminal 2: Kafka lag
watch 'oc exec genetic-data-cluster-kafka-0 -- /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 --describe --group vep-service-group'

# Terminal 3: System resources
watch 'oc top pods -l app=vep-service'

# Terminal 4: Run analysis
node scripts/test-websocket-client.js normal "ATCGATCGATCGATCGATCG" 120
```

## 🔧 Troubleshooting Common Issues

### Issue: No VEP Results Received

**Symptoms**: WebSocket client times out without receiving results

**Diagnosis**:
```bash
# Check VEP service status
oc get pods -l app=vep-service

# Check VEP service logs
oc logs -l app=vep-service --tail=20

# Check Kafka consumer lag
oc exec genetic-data-cluster-kafka-0 -- /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 --describe --group vep-service-group
```

**Solutions**:
- Wait for VEP service cold start (15-60 seconds)
- Increase WebSocket timeout
- Check KEDA scaler configuration
- Verify Kafka topic connectivity

### Issue: WebSocket Connection Fails

**Symptoms**: Cannot establish WebSocket connection

**Diagnosis**:
```bash
# Test WebSocket service health
curl -k https://quarkus-websocket-service-healthcare-ml-demo.apps.b9892ub1.eastus.aroapp.io/q/health

# Check WebSocket service logs
oc logs -l app=quarkus-websocket-service --tail=20
```

**Solutions**:
- Verify route accessibility
- Check WebSocket service pod status
- Validate network connectivity
- Try alternative WebSocket URL format

### Issue: Slow Processing Times

**Symptoms**: VEP analysis takes longer than expected

**Diagnosis**:
```bash
# Check VEP service resource usage
oc top pods -l app=vep-service

# Monitor Ensembl VEP API response times
oc logs -l app=vep-service | grep -E "(VEP API|response time)"
```

**Solutions**:
- Consider using big-data mode for large sequences
- Check Ensembl VEP API availability
- Monitor network latency to external APIs
- Scale up VEP service replicas if needed

## 🎉 Congratulations!

You've successfully:
- ✅ **Performed genetic analysis** using multiple interfaces (Web, WebSocket, API)
- ✅ **Interpreted VEP results** with variant annotations and gene mapping
- ✅ **Monitored data flow** through Kafka topics and VEP processing
- ✅ **Tested different sequence sizes** and resource profiles
- ✅ **Understood scaling behavior** based on workload characteristics

## 🔄 Next Steps

### Explore Advanced Features
1. **[Scaling Demo Tutorial](04-scaling-demo.md)** - Deep dive into multi-tier scaling
2. **[System Architecture](../explanation/system-architecture.md)** - Understand the complete design
3. **[API Reference](../reference/api-reference.md)** - Explore all available endpoints

### Real-World Applications
- **Research Workflows**: Integrate with existing bioinformatics pipelines
- **Clinical Analysis**: Use for variant interpretation in clinical settings
- **Educational Use**: Demonstrate genetic analysis concepts
- **Performance Testing**: Validate system capacity with large datasets

### Further Learning
- **VEP Documentation**: [Ensembl VEP User Guide](https://ensembl.org/info/docs/tools/vep/index.html)
- **Genetic Variants**: Understanding SNPs, indels, and structural variants
- **Clinical Genomics**: Interpreting genetic variants in clinical context

## Summary

The healthcare ML genetic analysis system provides:
- **🔬 Comprehensive VEP Analysis**: Variant effect prediction with clinical annotations
- **⚡ Scalable Processing**: Automatic scaling based on workload size
- **🌐 Multiple Interfaces**: Web UI, WebSocket, and REST API access
- **📊 Real-Time Monitoring**: Complete visibility into processing pipeline
- **💰 Cost Optimization**: Scale-to-zero capabilities with cost attribution

You're now ready to perform sophisticated genetic analysis using the healthcare ML system's powerful VEP annotation pipeline!