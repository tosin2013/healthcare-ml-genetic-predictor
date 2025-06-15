# Quarkus WebSocket Healthcare ML Service

A Quarkus-based WebSocket service for healthcare genetic analysis with ML scaling capabilities, designed for deployment on Azure Red Hat OpenShift with KEDA autoscaling.

## 🧵 Threading Validation

This service implements critical threading fixes to prevent event loop blocking in Quarkus reactive applications. All REST endpoints use `@Blocking` annotations to ensure proper thread execution.

### Threading Requirements

- **✅ Worker Thread Execution**: All blocking operations must run on `executor-thread-*` threads
- **❌ Event Loop Blocking**: No operations should block `vert.x-eventloop-thread-*` threads
- **🔄 CloudEvent Processing**: Kafka message emission must occur on worker threads

### Local Testing

Before deploying to OpenShift, validate threading fixes locally:

```bash
# Run threading validation script
./test-threading-local.sh

# Or run tests manually
./mvnw test -Dtest=ScalingTestControllerTest
```

### Expected Output

✅ **Successful Threading Validation:**
```
🧵 Local Threading Validation Script
====================================

📊 Threading Analysis:
   • Worker Thread Executions: 8+
   • Event Loop Thread Usage: 0

📨 CloudEvent Analysis:
   • Total CloudEvents Sent: 4+
   • Raw Events (normal mode): 2+
   • BigData Events (big-data mode): 2+

✅ Validation Results:
   ✅ Tests passed
   ✅ No event loop blocking detected
   ✅ @Blocking annotations working (8+ executions)
   ✅ CloudEvents created successfully (4+ events)

🎉 THREADING VALIDATION PASSED
✅ Ready for GitHub push and OpenShift deployment
```

## 🚀 Quick Start

### Prerequisites

- Java 17
- Maven 3.8+
- Access to Kafka (for production) or test profile (for local testing)

### Local Development

```bash
# Compile and run tests
./mvnw clean compile test

# Run in development mode
./mvnw quarkus:dev

# Test threading validation
./test-threading-local.sh
```

### Test Configuration

The service uses different configurations for testing vs production:

- **Test Profile**: Uses localhost Kafka configuration with graceful failure handling
- **Production Profile**: Connects to actual Kafka cluster

Test configuration is automatically activated when running tests.

## 📡 API Endpoints

### Genetic Analysis

```bash
# Normal mode analysis
curl -X POST http://localhost:8080/api/genetic/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "sequence": "ATCGATCGATCG",
    "mode": "normal",
    "resourceProfile": "standard"
  }'

# Big-data mode analysis (triggers node scaling)
curl -X POST http://localhost:8080/api/genetic/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "sequence": "ATCGATCGATCGATCGATCGATCGATCGATCGATCG",
    "mode": "bigdata",
    "resourceProfile": "high-memory"
  }'
```

### Scaling Demo

```bash
# Trigger scaling demonstration
curl -X POST http://localhost:8080/api/scaling/trigger-demo \
  -H "Content-Type: application/json" \
  -d '{
    "demoType": "genetic-analysis",
    "sequenceCount": 10,
    "sequenceSize": "medium"
  }'

# Check health
curl http://localhost:8080/api/scaling/health
```

## 🔄 CI/CD Integration

### GitHub Actions

The repository includes automated threading validation via GitHub Actions:

- **Triggers**: Pull requests, pushes to main, manual dispatch
- **Validation**: Ensures no event loop blocking occurs
- **Reports**: Generates threading validation reports on PRs
- **Quality Gates**: Prevents deployment if threading issues detected

### Workflow Files

- `.github/workflows/threading-validation.yml`: Main threading validation workflow

## 🏗️ Architecture Compliance

This service follows established ADRs:

- **ADR-004**: API Testing and Validation on OpenShift
- **MVP Phase 0**: Local Testing Requirements

### Threading Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   HTTP Request  │───▶│  @Blocking       │───▶│  Worker Thread  │
│   (Event Loop)  │    │  REST Endpoint   │    │  (executor-*)   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │  Kafka CloudEvent│
                       │  (Worker Thread) │
                       └──────────────────┘
```

## 🧪 Testing Strategy

### Test Types

1. **Threading Validation**: Ensures `@Blocking` annotations work correctly
2. **REST Endpoint Testing**: Validates API functionality and responses
3. **CloudEvent Testing**: Verifies proper event creation and serialization
4. **Error Handling**: Tests validation failures and exception scenarios

### Test Classes

- `ScalingTestControllerTest`: Main threading validation tests
- `TestConfigurationTest`: Test configuration validation
- `GeneticPredictorEndpointTest`: WebSocket endpoint tests

## 📋 Deployment Checklist

Before deploying to OpenShift:

- [ ] ✅ Local threading validation passes (`./test-threading-local.sh`)
- [ ] ✅ All tests pass (`./mvnw test`)
- [ ] ✅ GitHub Actions threading validation passes
- [ ] ✅ No event loop blocking detected in logs
- [ ] ✅ CloudEvents created successfully
- [ ] ✅ ADR-004 compliance verified

## 🔧 Troubleshooting

### Common Threading Issues

**Event Loop Blocking Detected:**
```
❌ Event loop blocking detected (N occurrences)
```
**Solution**: Add `@Blocking` annotation to REST endpoint methods that perform I/O operations.

**No Worker Thread Execution:**
```
❌ No worker thread execution detected
```
**Solution**: Verify `@Blocking` annotations are present and properly imported.

**Test Failures:**
```
❌ Tests failed (exit code: 1)
```
**Solution**: Check test logs for specific validation failures and fix accordingly.

## 📚 Related Documentation

- [ADR-004: API Testing and Validation](../docs/adr/ADR-004-api-testing-validation-openshift.md)
- [MVP Project Plan](../docs/MVP_PROJECT_PLAN.md)
- [Local Testing Guide](../docs/LOCAL_TESTING_GUIDE.md)
