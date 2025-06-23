# Scaling Mode Separation of Concerns Validation

## Overview

This validation system ensures that developers cannot accidentally break the critical mapping between UI buttons, backend modes, and Kafka topics in the Healthcare ML Genetic Predictor system. It provides pre-merge validation to maintain the separation of concerns between the 4 scaling modes.

## Prerequisites

- **Node.js**: Version 20.x or higher (matches CI/CD environment)
- **npm**: Latest version (usually bundled with Node.js)
- **Dependencies**: `js-yaml` package for YAML configuration parsing

To check your Node.js version:
```bash
node --version  # Should show v20.x.x
```

## The 4 Scaling Modes

| Mode | UI Button | Backend Mode | Kafka Topic | Description |
|------|-----------|--------------|-------------|-------------|
| **Normal** | `normalModeBtn` | `normal` | `genetic-data-raw` | Standard KEDA pod scaling |
| **Big Data** | `bigDataModeBtn` | `big-data` | `genetic-bigdata-raw` | Memory-intensive processing |
| **Node Scale** | `nodeScaleModeBtn` | `node-scale` | `genetic-nodescale-raw` | Cluster autoscaler triggering |
| **Kafka Lag** | `kafkaLagModeBtn` | `kafka-lag` | `genetic-lag-demo-raw` | KEDA consumer lag scaling |

## Validation Architecture

### Configuration File
- **Location**: `quarkus-websocket-service/src/main/resources/scaling-mode-separation.yaml`
- **Purpose**: Defines the canonical mapping between UI, backend, and Kafka components
- **Format**: YAML with validation rules and expected mappings

### Validation Script
- **Location**: `scripts/validate-scaling-separation.js`
- **Purpose**: Automated validation of separation consistency
- **Dependencies**: `js-yaml` for configuration parsing
- **Usage**: `node scripts/validate-scaling-separation.js [--config path] [--fix]`

### GitHub Actions Workflow
- **Location**: `.github/workflows/separation-of-concerns-validation.yml`
- **Triggers**: 
  - Pull requests to `main` and `develop`
  - Direct pushes to `main`
  - Manual workflow dispatch
- **Validation Steps**:
  1. Configuration file validation
  2. UI button consistency check
  3. Backend mode mapping validation
  4. Kafka topic configuration verification
  5. Emitter channel injection validation
  6. Test coverage validation

## What Gets Validated

### 1. UI Button Consistency
**Files Checked**: `quarkus-websocket-service/src/main/resources/META-INF/resources/index.html`

**Validation Rules**:
- All 4 button IDs exist: `normalModeBtn`, `bigDataModeBtn`, `nodeScaleModeBtn`, `kafkaLagModeBtn`
- Button text matches expected labels
- Button click handlers are properly defined

### 2. Backend Mode Mapping
**Files Checked**: `quarkus-websocket-service/src/main/java/com/redhat/healthcare/GeneticPredictorEndpoint.java`

**Validation Rules**:
- Switch statement contains all 4 mode cases
- Each case assigns correct `kafkaTopic` and `eventType`
- Mode handling logic is complete

### 3. Kafka Configuration
**Files Checked**: `quarkus-websocket-service/src/main/resources/application.properties`

**Validation Rules**:
- All 4 Kafka topics are configured
- Emitter channels are properly defined
- Topic mappings match the configuration

### 4. Emitter Channel Injection
**Files Checked**: `quarkus-websocket-service/src/main/java/com/redhat/healthcare/GeneticPredictorEndpoint.java`

**Validation Rules**:
- All 4 emitter channels have `@Channel` injection
- Emitter fields are properly declared
- Emitters are used correctly in switch statements

### 5. Test Coverage
**Files Checked**: `scripts/test-ui-regression.js`

**Validation Rules**:
- All 4 scaling modes are tested
- Test mode names match backend modes
- Response validation exists for each mode

## How to Use the Validation System

### For Developers

#### Before Making Changes
1. Review the configuration file to understand the expected mappings
2. Ensure your changes maintain the separation of concerns
3. Run local validation before committing:
   ```bash
   node scripts/validate-scaling-separation.js
   ```

#### When Adding New Scaling Modes
1. Update `scaling-mode-separation.yaml` with the new mode
2. Add UI button with proper ID and text
3. Add backend case handling in `GeneticPredictorEndpoint.java`
4. Configure Kafka topic in `application.properties`
5. Add emitter injection and usage
6. Add test coverage in `test-ui-regression.js`
7. Run validation to ensure consistency

#### When Modifying Existing Modes
1. Check if your changes affect the mode mapping
2. Update configuration file if needed
3. Ensure all validation rules still pass
4. Test the affected scaling mode thoroughly

### For Code Reviewers

#### Pre-Merge Checklist
- [ ] Separation validation workflow passed
- [ ] All 4 scaling modes still work
- [ ] No new modes added without proper validation
- [ ] UI button changes don't break backend mapping
- [ ] Kafka topic changes are consistent across all files

#### Common Issues to Watch For
- Missing UI button IDs or incorrect text
- Backend mode cases missing from switch statement
- Kafka topic configuration mismatches
- Missing `@Channel` injection for new emitters
- Test coverage gaps for scaling modes

## Validation Workflow Behavior

### On Pull Requests
1. **Automatic Trigger**: Runs on any PR to `main` or `develop` that touches relevant files
2. **Validation Steps**: Full validation including structure, consistency, and test coverage
3. **PR Comment**: Adds validation report as PR comment
4. **Merge Blocking**: PR cannot be merged if validation fails

### On Direct Pushes
1. **Automatic Trigger**: Runs on pushes to `main` branch
2. **Validation Steps**: Full validation to catch any direct commits
3. **Notification**: Fails the workflow if separation is broken

### Manual Execution
1. **Workflow Dispatch**: Can be triggered manually from GitHub Actions
2. **Options**: 
   - `validate_only`: Skip additional tests, run only separation validation
   - `fix_mode`: Attempt automatic fixes (experimental)

## Error Handling and Troubleshooting

### Common Validation Errors

#### UI Button Missing
```
❌ UI button validation failed
Missing buttons: bigDataModeBtn (big-data mode)
```
**Fix**: Add the missing button ID to the HTML file

#### Backend Mode Case Missing
```
❌ Backend mode validation failed
Missing modes: kafka-lag
```
**Fix**: Add the missing case to the switch statement in `GeneticPredictorEndpoint.java`

#### Kafka Topic Configuration Missing
```
❌ Kafka configuration validation failed
Missing channels: genetic-lag-demo-raw-out
```
**Fix**: Add the missing topic configuration to `application.properties`

#### Emitter Injection Missing
```
❌ Emitter injection validation failed
Missing injections: @Channel("genetic-lag-demo-raw-out")
```
**Fix**: Add the missing `@Channel` injection in the Java file

#### Test Coverage Gap
```
❌ Test coverage validation failed
Missing modes: kafka-lag
```
**Fix**: Add the missing test mode to `test-ui-regression.js`

### Manual Validation

If automated validation fails and you need to debug:

```bash
# Run validation with verbose output
node scripts/validate-scaling-separation.js

# Check specific configuration
cat quarkus-websocket-service/src/main/resources/scaling-mode-separation.yaml

# Verify file structure
ls -la quarkus-websocket-service/src/main/resources/META-INF/resources/
ls -la quarkus-websocket-service/src/main/java/com/redhat/healthcare/
```

## Configuration Reference

### Scaling Mode Configuration Schema

```yaml
scaling_modes:
  mode_name:
    ui_button_id: "buttonId"           # HTML button ID
    ui_button_text: "Button Text"      # Expected button text
    backend_mode: "backend-mode"       # Switch case value
    kafka_topic: "topic-name"          # Kafka topic name
    emitter_channel: "channel-name"    # Emitter channel name
    event_type: "event.type.name"      # CloudEvent type
    resource_profile: "profile"        # Resource profile
    description: "Mode description"    # Human-readable description
```

### Validation Rules Schema

```yaml
validation_rules:
  - name: "Rule Name"
    description: "What this rule validates"
    files: ["file1.ext", "file2.ext"]  # Files to check
```

## Benefits of This System

### Prevents Breaking Changes
- Catches separation violations before merge
- Ensures all scaling modes remain functional
- Prevents accidental topic misconfigurations

### Improves Developer Experience
- Clear error messages with fix suggestions
- Automated validation reduces manual review time
- Configuration-driven approach makes changes explicit

### Maintains System Integrity
- Ensures UI and backend stay synchronized
- Validates test coverage for all modes
- Enforces consistent naming conventions

### Enables Safe Refactoring
- Confident code changes with validation safety net
- Easy to add new scaling modes following the pattern
- Clear documentation of expected mappings

## Future Enhancements

### Planned Features
- [ ] Automatic fix suggestions with `--fix` flag
- [ ] Integration with IDE for real-time validation
- [ ] Performance benchmarking per scaling mode
- [ ] Visual validation report with diagrams

### Extension Points
- Additional validation rules can be added to the configuration
- Custom validators for specific file types
- Integration with other CI/CD tools beyond GitHub Actions
- Support for multiple environments (dev, staging, prod)

---

This validation system ensures that the critical separation of concerns between UI buttons and Kafka topics is maintained, providing developers with confidence when making changes to the Healthcare ML Genetic Predictor system.
