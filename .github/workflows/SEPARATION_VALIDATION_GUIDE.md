# Separation of Concerns Validation Strategy

## Overview

This document describes the comprehensive validation strategy implemented to ensure developers cannot accidentally break the critical separation of concerns between the 4 scaling mode buttons and their corresponding Kafka topics before code reaches OpenShift.

## The 4 Scaling Modes & Their Separation

The Healthcare ML Genetic Predictor implements a strict separation of concerns across 4 scaling modes:

### 1. 🟢 Normal Mode (Standard Pod Scaling)
- **UI Button**: `#normalModeBtn` → `setNormalMode()`
- **Java Mode**: `case "normal":`
- **Kafka Topic**: `genetic-data-raw`
- **Emitter**: `geneticDataEmitter`
- **CloudEvent Type**: `com.redhat.healthcare.genetic.sequence.raw`
- **Purpose**: Standard KEDA pod scaling for typical genetic analysis workloads

### 2. 🟡 Big Data Mode (Memory-Intensive Scaling)
- **UI Button**: `#bigDataModeBtn` → `setBigDataMode()`
- **Java Mode**: `case "big-data":`
- **Kafka Topic**: `genetic-bigdata-raw`
- **Emitter**: `geneticBigDataEmitter`
- **CloudEvent Type**: `com.redhat.healthcare.genetic.sequence.bigdata`
- **Purpose**: High-memory pod scaling for large genetic datasets

### 3. 🔴 Node Scale Mode (Cluster Autoscaler)
- **UI Button**: `#nodeScaleModeBtn` → `setNodeScaleMode()`
- **Java Mode**: `case "node-scale":`
- **Kafka Topic**: `genetic-nodescale-raw`
- **Emitter**: `geneticNodeScaleEmitter`
- **CloudEvent Type**: `com.redhat.healthcare.genetic.sequence.nodescale`
- **Purpose**: Cluster autoscaler triggering for massive computational workloads

### 4. 🟣 Kafka Lag Mode (KEDA Consumer Lag)
- **UI Button**: `#kafkaLagModeBtn` → `setKafkaLagMode()`
- **Java Mode**: `case "kafka-lag":`
- **Kafka Topic**: `genetic-lag-demo-raw`
- **Emitter**: `geneticLagDemoEmitter`
- **CloudEvent Type**: `com.redhat.healthcare.genetic.sequence.kafkalag`
- **Purpose**: Event-driven scaling based on consumer lag

## Why Separation of Concerns Matters

### Business Impact
- **Cost Attribution**: Each mode has different cost implications and attribution requirements
- **SLA Compliance**: Different modes have different performance and availability requirements
- **Operational Monitoring**: Separate metrics and alerting per scaling mode

### Technical Impact
- **KEDA Scaling**: Each mode uses different KEDA ScaledObjects with specific lag thresholds
- **Resource Allocation**: Different modes require different resource profiles and node types
- **Data Flow**: Separate Kafka topics enable independent processing pipelines

### Compliance Impact
- **Audit Trail**: Separate event types enable proper audit logging
- **Security**: Different modes may have different data classification requirements
- **Governance**: Independent scaling modes support regulatory compliance

## Validation Strategy

### 1. Pre-Merge Validation (GitHub Actions)

The `separation-of-concerns-validation.yml` workflow runs on every PR and validates:

#### UI Layer Validation
- ✅ Button IDs exist and map to correct JavaScript functions
- ✅ JavaScript functions exist and are properly defined
- ✅ No orphaned buttons or functions

#### Java Backend Validation
- ✅ Switch cases exist for all 4 modes
- ✅ Topic assignments are correct per mode
- ✅ Emitter usage matches expected mapping
- ✅ No missing or extra modes

#### Configuration Validation
- ✅ All 4 Kafka topics configured in `application.properties`
- ✅ All 4 emitter channels properly defined
- ✅ Bootstrap servers consistent across all topics

#### Test Coverage Validation
- ✅ All 4 modes covered in `test-ui-regression.js`
- ✅ Test mode count matches expected (exactly 4)
- ✅ No missing or extra test modes

#### CloudEvent Validation
- ✅ CloudEvent types consistent across all modes
- ✅ No duplicate or missing event types
- ✅ Event type naming follows established convention

#### Cross-Reference Validation
- ✅ Complete end-to-end chain validation per mode
- ✅ HTML → JavaScript → Java → Kafka consistency
- ✅ No broken links in the processing chain

### 2. Local Pre-Commit Validation

The `scripts/validate-separation-local.sh` script enables developers to:

- 🔍 **Validate locally** before committing changes
- 🚀 **Fast feedback** without waiting for CI/CD
- 📊 **Detailed reporting** of any separation issues
- 🛠️ **Guidance** on how to fix problems

#### Usage
```bash
# Run from project root
./scripts/validate-separation-local.sh

# Expected output on success:
✅ ALL VALIDATIONS PASSED!
✅ Your changes maintain proper separation of concerns
✅ Safe to commit and create PR
```

### 3. Integration with Existing Workflows

The separation validation integrates with existing workflows:

#### UI Regression Test Enhancement
- The existing `ui-regression-test.yml` now includes separation validation
- Ensures that functional tests align with architectural requirements
- Validates that all 4 modes are properly tested

#### Threading Validation Integration
- Threading validation ensures backend services can handle all 4 modes
- Validates that mode-specific processing doesn't introduce threading issues

## Protected Boundaries

### What Cannot Be Changed Without Validation

1. **UI Button IDs**: `normalModeBtn`, `bigDataModeBtn`, `nodeScaleModeBtn`, `kafkaLagModeBtn`
2. **JavaScript Functions**: `setNormalMode()`, `setBigDataMode()`, `setNodeScaleMode()`, `setKafkaLagMode()`
3. **Java Mode Values**: `"normal"`, `"big-data"`, `"node-scale"`, `"kafka-lag"`
4. **Kafka Topics**: `genetic-data-raw`, `genetic-bigdata-raw`, `genetic-nodescale-raw`, `genetic-lag-demo-raw`
5. **Emitter Fields**: `geneticDataEmitter`, `geneticBigDataEmitter`, `geneticNodeScaleEmitter`, `geneticLagDemoEmitter`
6. **CloudEvent Types**: `com.redhat.healthcare.genetic.sequence.*`

### What Can Be Safely Modified

1. **UI Styling**: Button colors, fonts, layouts (as long as IDs remain)
2. **Processing Logic**: Internal VEP processing, ML inference logic
3. **Monitoring**: Adding metrics, logs, alerts
4. **Documentation**: Updates to tutorials, ADRs, README files
5. **Dependencies**: Updating Maven dependencies, Node.js packages

## Enforcement Mechanisms

### GitHub Actions Workflow
- **Trigger**: Every PR to `main` or `develop` branches
- **Blocking**: PR cannot be merged if validation fails
- **Reporting**: Detailed validation report posted as PR comment
- **Artifacts**: Validation reports stored for 30 days

### Local Validation Script
- **Pre-commit Hook**: Can be added to git hooks
- **IDE Integration**: Can be run from IDE task runner
- **CI/CD Integration**: Can be called from other CI/CD systems

### Code Review Guidelines
- **Required Review**: Changes to scaling modes require architectural review
- **Documentation**: Any changes must update corresponding documentation
- **Testing**: All changes must maintain 100% test coverage

## Adding New Scaling Modes

If new scaling modes are needed, follow this process:

### 1. Update Core Components
```bash
# 1. Add UI button in index.html
<button id="newModeBtn" onclick="setNewMode()" class="mode-btn new">
    🆕 New Mode
</button>

# 2. Add JavaScript function
function setNewMode() {
    currentMode = 'new-mode';
    // ... mode-specific logic
}

# 3. Add Java switch case
case "new-mode":
    eventType = "com.redhat.healthcare.genetic.sequence.newmode";
    kafkaTopic = "genetic-newmode-raw";
    break;

# 4. Add Kafka configuration
mp.messaging.outgoing.genetic-newmode-raw-out.connector=smallrye-kafka
mp.messaging.outgoing.genetic-newmode-raw-out.topic=genetic-newmode-raw

# 5. Add emitter field
@Channel("genetic-newmode-raw-out")
Emitter<String> geneticNewModeEmitter;

# 6. Add test coverage
{
    name: 'new-mode',
    description: 'New Mode Description',
    expectedResponse: ['expected', 'response', 'elements']
}
```

### 2. Update Validation
```bash
# Update local validation script
BUTTON_MAPPINGS["newModeBtn"]="setNewMode"
MODE_MAPPINGS["new-mode"]="genetic-newmode-raw"
EMITTER_MAPPINGS["new-mode"]="geneticNewModeEmitter"
CLOUDEVENT_TYPES["new-mode"]="com.redhat.healthcare.genetic.sequence.newmode"

# Update GitHub Actions workflow
# (Add to cross-reference validation script)
```

### 3. Update Documentation
- Add to this document
- Update tutorial 04-scaling-demo.md
- Update ADR if architectural changes
- Update README with new capabilities

## Troubleshooting

### Common Issues

#### ❌ Button ID Missing or Incorrect
```bash
# Error: Button normalModeBtn missing or incorrect onclick function
# Fix: Check HTML file for correct id and onclick attributes
<button id="normalModeBtn" onclick="setNormalMode()">
```

#### ❌ Java Switch Case Missing
```bash
# Error: Missing big-data case in switch statement
# Fix: Add case to switch statement in GeneticPredictorEndpoint.java
case "big-data":
    eventType = "com.redhat.healthcare.genetic.sequence.bigdata";
    kafkaTopic = "genetic-bigdata-raw";
    break;
```

#### ❌ Kafka Topic Not Configured
```bash
# Error: Topic genetic-bigdata-raw not configured
# Fix: Add topic configuration to application.properties
mp.messaging.outgoing.genetic-bigdata-raw-out.topic=genetic-bigdata-raw
```

#### ❌ Emitter Not Used Correctly
```bash
# Error: big-data mode not using correct emitter
# Fix: Use correct emitter in switch case
case "big-data":
    geneticBigDataEmitter.send(cloudEventJson);
    break;
```

### Debug Commands

```bash
# Check UI mappings
grep -n "id.*ModeBtn" quarkus-websocket-service/src/main/resources/META-INF/resources/index.html

# Check Java switch cases
grep -A3 "case.*:" quarkus-websocket-service/src/main/java/com/redhat/healthcare/GeneticPredictorEndpoint.java

# Check Kafka configuration
grep "topic=" quarkus-websocket-service/src/main/resources/application.properties

# Check test coverage
grep "name: '" scripts/test-ui-regression.js
```

## References

- [Tutorial 04: Scaling Demo](../docs/tutorials/04-scaling-demo.md)
- [Tutorial 05: Kafka Lag Scaling](../docs/tutorials/05-kafka-lag-scaling.md)
- [ADR-008: Multi-dimensional Pod Autoscaler](../docs/adr/008-multi-dimensional-pod-autoscaler.md)
- [GitHub Actions Workflows](../.github/workflows/)
- [UI Regression Tests](../scripts/test-ui-regression.js)

## Contact

For questions about separation of concerns validation:
- 📧 Architecture Review Board
- 💬 #healthcare-ml-architecture Slack channel
- 📋 Create issue with label `architecture/separation-of-concerns`
