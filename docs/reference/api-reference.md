# API Reference - Healthcare ML Genetic Predictor

## 🎯 Overview

The Healthcare ML Genetic Predictor provides REST APIs for genetic sequence analysis with three scaling modes and real-time WebSocket communication. All APIs are designed for healthcare-grade reliability with comprehensive error handling.

**Base URL**: `https://<your-openshift-route>/`  
**API Version**: v1  
**Content-Type**: `application/json`

## 🔐 Authentication

Currently, the system uses OpenShift route-based access control. Future versions will include:
- OAuth 2.0 integration
- JWT token authentication
- Role-based access control (RBAC)

## 📊 Health and Status Endpoints

### Health Check
Check the overall health of the WebSocket service.

```http
GET /q/health
```

**Response**:
```json
{
  "status": "UP",
  "checks": [
    {
      "name": "Kafka connection health check",
      "status": "UP"
    },
    {
      "name": "WebSocket endpoint health",
      "status": "UP"
    }
  ]
}
```

### Readiness Check
Check if the service is ready to accept requests.

```http
GET /q/health/ready
```

### Liveness Check
Check if the service is alive and responsive.

```http
GET /q/health/live
```

### Metrics
Prometheus-compatible metrics for monitoring.

```http
GET /q/metrics
```

## 🧬 Genetic Analysis Endpoints

### Normal Mode Analysis
Process genetic sequences with standard pod scaling.

```http
POST /api/genetic/analyze/normal
```

**Request Body**:
```json
{
  "genetic_sequence": "ATCGATCGATCG",
  "session_id": "user-session-123",
  "metadata": {
    "species": "human",
    "assembly": "GRCh38",
    "description": "Sample genetic sequence"
  }
}
```

**Parameters**:
- `genetic_sequence` (string, required): DNA sequence using IUPAC nucleotide codes
- `session_id` (string, required): Unique session identifier for WebSocket delivery
- `metadata` (object, optional): Additional sequence metadata

**Response**:
```json
{
  "status": "processing",
  "session_id": "user-session-123",
  "processing_mode": "normal",
  "estimated_time": "30-60 seconds",
  "message": "Genetic sequence submitted for VEP annotation"
}
```

**Kafka Topic**: `genetic-data-raw`  
**Scaling**: Pod scaling only (0-3 replicas)

### Big Data Mode Analysis
Process large genetic sequences with memory-intensive scaling.

```http
POST /api/genetic/analyze/big-data
```

**Request Body**: Same as Normal Mode

**Response**:
```json
{
  "status": "processing",
  "session_id": "user-session-123",
  "processing_mode": "big-data",
  "estimated_time": "2-5 minutes",
  "message": "Large genetic sequence submitted for intensive processing"
}
```

**Kafka Topic**: `genetic-bigdata-raw`  
**Scaling**: Memory-intensive pod scaling with higher resource limits

### Node Scale Mode Analysis
Trigger cluster autoscaler with compute-intensive processing.

```http
POST /api/genetic/analyze/node-scale
```

**Request Body**: Same as Normal Mode

**Response**:
```json
{
  "status": "processing",
  "session_id": "user-session-123",
  "processing_mode": "node-scale",
  "estimated_time": "5-10 minutes",
  "message": "Sequence submitted for node-scale processing"
}
```

**Kafka Topic**: `genetic-nodescale-raw`  
**Scaling**: Triggers cluster autoscaler for dedicated compute nodes

## 📈 Scaling and Status Endpoints

### Get Scaling Status
Check current scaling status for all modes.

```http
GET /api/scaling/status
```

**Response**:
```json
{
  "normal_mode": {
    "current_replicas": 2,
    "desired_replicas": 2,
    "kafka_lag": 0,
    "last_scaled": "2024-01-15T10:30:00Z"
  },
  "big_data_mode": {
    "current_replicas": 1,
    "desired_replicas": 1,
    "kafka_lag": 5,
    "last_scaled": "2024-01-15T10:25:00Z"
  },
  "node_scale_mode": {
    "current_replicas": 0,
    "desired_replicas": 0,
    "kafka_lag": 0,
    "nodes_available": 3,
    "compute_intensive_nodes": 1
  }
}
```

### Trigger Scaling Demo
Manually trigger scaling for demonstration purposes.

```http
POST /api/scaling/demo/{mode}
```

**Path Parameters**:
- `mode`: One of `normal`, `big-data`, `node-scale`

**Request Body**:
```json
{
  "load_level": "high",
  "duration_seconds": 300,
  "sequence_count": 50
}
```

## 🌐 WebSocket API

### Connection Endpoint
Connect to the WebSocket for real-time genetic analysis results.

```javascript
const ws = new WebSocket('wss://<your-route>/genetics');
```

### WebSocket Events

#### Connection Established
```json
{
  "type": "connection",
  "message": "🧬 Connected to Healthcare ML Service with OpenShift AI Integration",
  "session_id": "api-session-abc123",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

#### Processing Status Updates
```json
{
  "type": "status",
  "session_id": "api-session-abc123",
  "status": "processing",
  "progress": 45,
  "message": "VEP annotation in progress...",
  "estimated_remaining": "30 seconds"
}
```

#### Analysis Results
```json
{
  "type": "result",
  "session_id": "api-session-abc123",
  "status": "completed",
  "processing_mode": "normal",
  "results": {
    "sequence_id": "api-session-abc123",
    "original_sequence": "ATCGATCGATCG",
    "vep_annotations": [
      {
        "variant_id": "rs123456",
        "consequence": "missense_variant",
        "impact": "MODERATE",
        "gene": "BRCA1",
        "transcript": "ENST00000357654",
        "protein_position": "185",
        "amino_acids": "V/A"
      }
    ],
    "risk_score": 0.75,
    "processing_time_ms": 2500
  },
  "timestamp": "2024-01-15T10:32:30Z"
}
```

#### Error Messages
```json
{
  "type": "error",
  "session_id": "api-session-abc123",
  "error_code": "INVALID_SEQUENCE",
  "message": "Invalid nucleotide characters in sequence",
  "details": "Sequence contains invalid character 'X' at position 5"
}
```

## 🔬 VEP Service API (Internal)

### Process Genetic Sequence
Internal API used by the VEP service for processing.

```http
POST /api/vep/process
```

**Request Body**:
```json
{
  "sequence": "ATCGATCGATCG",
  "session_id": "internal-session-123",
  "species": "human",
  "assembly": "GRCh38"
}
```

**Response**:
```json
{
  "session_id": "internal-session-123",
  "annotations": [
    {
      "input": "1:g.230710048A>G",
      "allele_string": "A/G",
      "variant_class": "SNV",
      "most_severe_consequence": "missense_variant",
      "transcript_consequences": [
        {
          "gene_id": "ENSG00000012048",
          "gene_symbol": "BRCA1",
          "transcript_id": "ENST00000357654",
          "consequence_terms": ["missense_variant"],
          "impact": "MODERATE"
        }
      ]
    }
  ],
  "processing_time_ms": 1500
}
```

## 📊 Error Codes and Responses

### HTTP Status Codes
- `200 OK`: Request successful
- `202 Accepted`: Request accepted for processing
- `400 Bad Request`: Invalid request parameters
- `422 Unprocessable Entity`: Valid request but processing failed
- `500 Internal Server Error`: Server error
- `503 Service Unavailable`: Service temporarily unavailable

### Error Response Format
```json
{
  "error": {
    "code": "INVALID_SEQUENCE",
    "message": "The provided genetic sequence contains invalid characters",
    "details": "Invalid nucleotide 'X' found at position 5",
    "timestamp": "2024-01-15T10:30:00Z",
    "request_id": "req-abc123"
  }
}
```

### Common Error Codes
- `INVALID_SEQUENCE`: Genetic sequence contains invalid nucleotides
- `SESSION_NOT_FOUND`: Session ID not found or expired
- `PROCESSING_TIMEOUT`: VEP processing exceeded timeout limit
- `KAFKA_CONNECTION_ERROR`: Unable to connect to Kafka
- `VEP_API_ERROR`: External VEP API returned an error
- `SCALING_LIMIT_REACHED`: Maximum scaling limit reached

## 🧪 Testing and Examples

### cURL Examples

#### Normal Mode Analysis
```bash
curl -X POST https://your-route/api/genetic/analyze/normal \
  -H "Content-Type: application/json" \
  -d '{
    "genetic_sequence": "ATCGATCGATCG",
    "session_id": "test-session-1",
    "metadata": {
      "species": "human",
      "description": "Test sequence"
    }
  }'
```

#### Health Check
```bash
curl https://your-route/q/health
```

### JavaScript WebSocket Example
```javascript
const ws = new WebSocket('wss://your-route/genetics');

ws.onopen = function(event) {
  console.log('Connected to Healthcare ML Service');
};

ws.onmessage = function(event) {
  const data = JSON.parse(event.data);
  console.log('Received:', data);
  
  if (data.type === 'result') {
    console.log('Analysis complete:', data.results);
  }
};

// Send analysis request via REST API
fetch('/api/genetic/analyze/normal', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    genetic_sequence: 'ATCGATCGATCG',
    session_id: 'js-session-123'
  })
});
```

## 📝 Rate Limits and Quotas

### Current Limits
- **API Requests**: 100 requests per minute per IP
- **WebSocket Connections**: 10 concurrent connections per IP
- **Sequence Length**: Maximum 1MB per sequence
- **Session Duration**: 15 minutes maximum

### Scaling Limits
- **Normal Mode**: 0-3 replicas
- **Big Data Mode**: 0-5 replicas  
- **Node Scale Mode**: 0-10 replicas, triggers cluster autoscaler

## 🔄 Versioning

The API follows semantic versioning:
- **Current Version**: v1
- **Backward Compatibility**: Maintained for major versions
- **Deprecation Policy**: 6 months notice for breaking changes

---

**📚 For more detailed examples and integration patterns, see the [How-To Guides](../how-to/) and [Tutorials](../tutorials/).**
