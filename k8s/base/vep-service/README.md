# VEP Service - Clean Separation of Concerns Architecture

## 🎯 Overview

This directory contains the **clean, organized structure** for the Healthcare ML Genetic Predictor VEP (Variant Effect Predictor) services. Each scaling mode has its own dedicated files, ensuring perfect separation of concerns and enabling independent experimentation.

## 📁 Directory Structure

```
k8s/base/vep-service/
├── README.md                            # This file - explains the architecture
├── kustomization.yaml                   # Kustomize configuration
├── knative-service.yaml                 # Knative service (legacy, may be removed)
│
├── vep-service-normal.yaml             # Normal mode: deployment + service
├── vep-service-normal-keda.yaml        # Normal mode: KEDA ScaledObject
│
├── vep-service-bigdata.yaml            # Big data mode: deployment + service
├── vep-service-bigdata-keda.yaml       # Big data mode: KEDA ScaledObject
│
├── vep-service-nodescale.yaml          # Node scale mode: deployment + service
├── vep-service-nodescale-keda.yaml     # Node scale mode: KEDA ScaledObject
│
├── vep-service-kafka-lag.yaml          # Kafka lag mode: deployment + service
└── vep-service-kafka-lag-keda.yaml     # Kafka lag mode: KEDA ScaledObject
```

## 🎯 Perfect 1:1 Mapping

| UI Button | Deployment File | KEDA File | Kafka Topic | Consumer Group | Purpose |
|-----------|----------------|-----------|-------------|----------------|---------|
| `#normalModeBtn` | `vep-service-normal.yaml` | `vep-service-normal-keda.yaml` | `genetic-data-raw` | `vep-service-group` | Standard genetic processing |
| `#bigDataModeBtn` | `vep-service-bigdata.yaml` | `vep-service-bigdata-keda.yaml` | `genetic-bigdata-raw` | `vep-bigdata-service-group` | Memory-intensive processing |
| `#nodeScaleModeBtn` | `vep-service-nodescale.yaml` | `vep-service-nodescale-keda.yaml` | `genetic-nodescale-raw` | `vep-nodescale-service-group` | Cluster autoscaler demo |
| `#kafkaLagModeBtn` | `vep-service-kafka-lag.yaml` | `vep-service-kafka-lag-keda.yaml` | `genetic-lag-demo-raw` | `vep-kafka-lag-service-group` | Consumer lag demonstration |

## 🚀 Why We Did This Restructure

### **Problem: Previous Messy Structure**
- ❌ `multi-mode-deployments.yaml` - All deployments in one file
- ❌ `deployment.yaml` - Legacy generic deployment causing conflicts
- ❌ `vep-service-nodescale-hpa.yaml` - HPA conflicting with KEDA
- ❌ Mixed responsibilities and unclear ownership
- ❌ Difficult to experiment with individual modes

### **Solution: Clean Separation of Concerns**
- ✅ **One file per mode** - Clear ownership and responsibility
- ✅ **Perfect UI mapping** - Each button maps to specific files
- ✅ **Independent experimentation** - Modify one mode without affecting others
- ✅ **Future-ready** - Ready for Red Hat autoscaling coordination experiments
- ✅ **No conflicts** - KEDA and HPA properly separated
- ✅ **Clear documentation** - Each file explains its purpose

## 🔧 Key Benefits

### 1. **Independent Experimentation**
```bash
# Want to experiment with kafka lag scaling?
# Only modify these files:
- vep-service-kafka-lag.yaml
- vep-service-kafka-lag-keda.yaml

# Other modes remain completely unaffected
```

### 2. **Clear Troubleshooting**
```bash
# Issue with big data mode?
# Check only these files:
- vep-service-bigdata.yaml
- vep-service-bigdata-keda.yaml

# No need to dig through multi-mode files
```

### 3. **Perfect Separation of Concerns**
- Each mode has dedicated Kafka topic
- Each mode has dedicated deployment
- Each mode has dedicated KEDA ScaledObject
- Each mode has isolated consumer group
- No cross-contamination between modes

### 4. **Future Red Hat Autoscaling Experiments**
The kafka lag mode is now perfectly isolated for implementing advanced autoscaling coordination based on `docs/research/red-hat-autoscaling-coordination-projects.md`:

```yaml
# vep-service-kafka-lag-keda.yaml is ready for:
# - Multi-dimensional Pod Autoscaler (AEP-5342)
# - Custom Metrics Autoscaler experiments
# - Advanced lag-based scaling patterns
# - Red Hat autoscaling coordination
```

## 📊 Scaling Characteristics

### Normal Mode
- **Resource Profile**: Standard (256Mi-512Mi memory, 100m-500m CPU)
- **Scaling**: 0→10 pods based on 2+ message lag
- **Use Case**: Standard genetic sequence processing

### Big Data Mode  
- **Resource Profile**: High memory (1Gi-2Gi memory, 500m-1000m CPU)
- **Scaling**: 0→15 pods based on 2+ message lag
- **Use Case**: Large dataset processing, memory-intensive workloads

### Node Scale Mode
- **Resource Profile**: Standard (256Mi-512Mi memory, 100m-500m CPU)  
- **Scaling**: 0→5 pods (LIMITED to force cluster autoscaler)
- **Use Case**: Demonstrating cluster autoscaler with node scaling

### Kafka Lag Mode
- **Resource Profile**: Moderate (512Mi-1Gi memory, 250m-500m CPU)
- **Scaling**: 0→8 pods based on 3+ message lag (higher threshold)
- **Use Case**: Consumer lag demonstration, future autoscaling experiments

## 🛡️ Separation Rules (CRITICAL)

### **DO NOT VIOLATE THESE MAPPINGS:**

1. **Topic Isolation**: Each mode MUST use its dedicated topic only
2. **Deployment Isolation**: Each mode MUST target its dedicated deployment only  
3. **Consumer Group Isolation**: Each mode MUST use its unique consumer group only
4. **KEDA Isolation**: Each mode MUST have its own dedicated ScaledObject only

### **Before Making Changes:**
1. Read `docs/KEDA_SEPARATION_OF_CONCERNS.md`
2. Verify changes don't break topic→deployment→scaler mappings
3. Test changes in isolation
4. Update documentation if mappings change

## 🔍 Validation

### Check Current Status
```bash
# Verify all modes have correct separation
oc get scaledobject -o custom-columns="NAME:.metadata.name,TARGET:.spec.scaleTargetRef.name,TOPIC:.spec.triggers[0].metadata.topic"

# Expected output:
# kafka-lag-scaler                vep-service-kafka-lag    genetic-lag-demo-raw
# vep-service-bigdata-scaler      vep-service-bigdata      genetic-bigdata-raw
# vep-service-nodescale-scaler    vep-service-nodescale    genetic-nodescale-raw
# vep-service-normal-scaler       vep-service-normal       genetic-data-raw
```

### Test Individual Modes
```bash
# Test normal mode
curl -X POST ".../api/test/genetic/analyze" -d '{"mode": "normal", ...}'

# Test big data mode  
curl -X POST ".../api/test/genetic/analyze" -d '{"mode": "big-data", ...}'

# Test node scale mode
curl -X POST ".../api/test/genetic/analyze" -d '{"mode": "node-scale", ...}'

# Test kafka lag mode
curl -X POST ".../api/test/genetic/analyze" -d '{"mode": "kafka-lag", ...}'
```

## 📚 Related Documentation

- **Main Rules**: `docs/KEDA_SEPARATION_OF_CONCERNS.md`
- **Current Status**: `docs/CURRENT_KEDA_STATUS.md`
- **GitHub Validation**: `.github/workflows/SEPARATION_VALIDATION_GUIDE.md`
- **Research**: `docs/research/red-hat-autoscaling-coordination-projects.md`

## 🎯 Future Experiments

This clean structure enables:

1. **Red Hat Autoscaling Coordination**: Experiment with kafka lag mode using Red Hat's autoscaling projects
2. **Multi-dimensional Pod Autoscaler**: Implement AEP-5342 in kafka lag mode
3. **Custom Metrics**: Add custom metrics to any mode independently
4. **Advanced Scaling Patterns**: Test new scaling algorithms per mode
5. **Cost Optimization**: Fine-tune resource allocation per mode

## 🏆 Conclusion

This restructure provides:
- ✅ **Perfect separation of concerns**
- ✅ **Clean, maintainable code structure**  
- ✅ **Independent experimentation capability**
- ✅ **Future-ready architecture**
- ✅ **Clear documentation and traceability**

**Each UI button now has its own dedicated files. Each mode is completely isolated. Ready for advanced autoscaling experiments!** 🚀
