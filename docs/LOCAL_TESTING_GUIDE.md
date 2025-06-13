# Local Testing Guide - ADR-001 Implementation

This guide helps you test the **ADR-001 deployment strategy corrections** locally to validate the service separation and data flow.

## 🎯 **Testing Objectives**

Validate that the **corrected architecture** works as specified in ADR-001:

- ✅ **WebSocket Service** (Deployment): Handles persistent connections, publishes raw data, consumes results
- ✅ **VEP Service** (Knative): Processes genetic data, calls VEP API, auto-scales
- ✅ **Kafka Communication**: Proper message flow between services
- ✅ **Service Separation**: No VEP logic in WebSocket service, no WebSocket logic in VEP service

## 🚀 **Quick Start**

### **Step 1: Set up local environment**
```bash
# Start local Kafka cluster
./scripts/test-local-setup.sh
```

### **Step 2: Start WebSocket service**
```bash
cd quarkus-websocket-service
./mvnw quarkus:dev -Dquarkus.profile=local
```

### **Step 3: Start VEP service (in new terminal)**
```bash
cd vep-service
./mvnw quarkus:dev -Dquarkus.profile=local -Dquarkus.http.port=8081
```

### **Step 4: Run validation tests**
```bash
./scripts/test-adr-001-dataflow.sh
```

### **Step 5: Manual testing**
1. Open: http://localhost:8080/genetic-client.html
2. Connect to WebSocket
3. Submit genetic sequence: `ATCGATCGATCG`
4. Verify data flow in Kafka UI: http://localhost:8090

## 📊 **Expected Data Flow (ADR-001)**

```
┌─────────────────────────────────────────────────────────────────┐
│                    Local Testing Data Flow                      │
└─────────────────────────────────────────────────────────────────┘

User Input (Browser)
    │
    ▼
┌─────────────────┐
│ WebSocket UI    │ 1. User submits: ATCGATCGATCG
│ localhost:8080  │
└─────────┬───────┘
          │ WebSocket Message
          ▼
┌─────────────────┐
│ WebSocket       │ 2. Receives genetic data
│ Service         │ 3. Publishes to Kafka
│ (Port 8080)     │
└─────────┬───────┘
          │ Kafka Publish
          ▼
┌─────────────────┐
│ Local Kafka     │ 4. genetic-data-raw topic
│ localhost:9092  │    (Monitor in Kafka UI)
└─────────┬───────┘
          │ Kafka Consume
          ▼
┌─────────────────┐
│ VEP Service     │ 5. Processes genetic sequence
│ (Port 8081)     │ 6. Calls Ensembl VEP API
│                 │ 7. Creates annotations
│ • Logs show     │ 8. Publishes annotated results
│   processing    │
└─────────┬───────┘
          │ Kafka Publish
          ▼
┌─────────────────┐
│ Local Kafka     │ 9. genetic-data-annotated topic
│ localhost:9092  │    (Monitor in Kafka UI)
└─────────┬───────┘
          │ Kafka Consume
          ▼
┌─────────────────┐
│ WebSocket       │ 10. Formats results
│ Service         │ 11. Sends to WebSocket client
│ (Port 8080)     │
└─────────┬───────┘
          │ WebSocket Response
          ▼
┌─────────────────┐
│ WebSocket UI    │ 12. Displays VEP annotations
│ localhost:8080  │     🧬 **Genetic Analysis Complete**
└─────────────────┘
```

## 🔍 **Monitoring and Validation**

### **1. Kafka Topic Monitoring**

**Monitor Raw Data Topic:**
```bash
docker exec test-kafka kafka-console-consumer \
  --topic genetic-data-raw \
  --bootstrap-server localhost:9092 \
  --from-beginning
```

**Monitor Annotated Data Topic:**
```bash
docker exec test-kafka kafka-console-consumer \
  --topic genetic-data-annotated \
  --bootstrap-server localhost:9092 \
  --from-beginning
```

### **2. Service Health Checks**

**WebSocket Service:**
```bash
curl http://localhost:8080/q/health
curl http://localhost:8080/q/metrics
```

**VEP Service:**
```bash
curl http://localhost:8081/q/health
curl http://localhost:8081/q/metrics
```

### **3. Log Analysis**

**WebSocket Service Logs Should Show:**
- ✅ WebSocket connection events
- ✅ Publishing to `genetic-data-raw` topic
- ✅ Consuming from `genetic-data-annotated` topic
- ❌ NO VEP API calls
- ❌ NO genetic sequence processing

**VEP Service Logs Should Show:**
- ✅ Consuming from `genetic-data-raw` topic
- ✅ VEP API calls to Ensembl
- ✅ Publishing to `genetic-data-annotated` topic
- ❌ NO WebSocket connections
- ❌ NO WebSocket message handling

## ✅ **Success Criteria**

### **Service Separation (ADR-001)**
- [ ] WebSocket service has NO VEP processing code
- [ ] VEP service has NO WebSocket handling code
- [ ] Each service has distinct responsibilities
- [ ] Services communicate only via Kafka

### **Data Flow Validation**
- [ ] Raw genetic data appears in `genetic-data-raw` topic
- [ ] VEP service processes the data (visible in logs)
- [ ] Annotated results appear in `genetic-data-annotated` topic
- [ ] WebSocket UI displays VEP annotation results
- [ ] End-to-end latency < 10 seconds

### **Configuration Validation**
- [ ] WebSocket service uses `application-local.properties`
- [ ] VEP service uses `application-local.properties`
- [ ] No port conflicts (8080 vs 8081)
- [ ] Kafka connectivity working for both services

## 🐛 **Troubleshooting**

### **Common Issues**

**1. Kafka Connection Errors**
```bash
# Check if Kafka is running
docker ps | grep kafka
# Restart if needed
./scripts/test-local-setup.sh
```

**2. Port Conflicts**
```bash
# Check what's using ports
lsof -i :8080
lsof -i :8081
lsof -i :9092
```

**3. Service Startup Issues**
```bash
# Clean and rebuild
cd quarkus-websocket-service
./mvnw clean compile
cd ../vep-service
./mvnw clean compile
```

**4. VEP API Rate Limiting**
- Ensembl VEP API has rate limits
- Use small test sequences
- Check VEP service logs for API errors

### **Debug Commands**

**Check Kafka Topics:**
```bash
docker exec test-kafka kafka-topics --list --bootstrap-server localhost:9092
```

**Check Consumer Groups:**
```bash
docker exec test-kafka kafka-consumer-groups --list --bootstrap-server localhost:9092
```

**Reset Consumer Group (if needed):**
```bash
docker exec test-kafka kafka-consumer-groups \
  --bootstrap-server localhost:9092 \
  --group vep-annotation-service-group \
  --reset-offsets --to-earliest \
  --topic genetic-data-raw --execute
```

## 🧪 **Test Scenarios**

### **Scenario 1: Basic Data Flow**
1. Submit: `ATCGATCGATCG`
2. Verify: Message flow through both topics
3. Expect: VEP annotations in UI

### **Scenario 2: Big Data Mode**
1. Switch to "Big Data Mode" in UI
2. Submit large sequence (1KB+)
3. Verify: Higher resource usage in VEP service

### **Scenario 3: Service Restart**
1. Stop VEP service
2. Submit genetic sequence
3. Restart VEP service
4. Verify: Queued messages are processed

### **Scenario 4: Error Handling**
1. Disconnect from internet (to break VEP API)
2. Submit genetic sequence
3. Verify: Graceful error handling

## 🛑 **Cleanup**

```bash
# Stop services (Ctrl+C in terminals)
# Stop Kafka
docker-compose -f docker-compose.test.yml down
# Clean up volumes (optional)
docker-compose -f docker-compose.test.yml down -v
```

## 📋 **Next Steps**

After successful local testing:

1. **Deploy to OpenShift** with corrected configurations
2. **Install KEDA** for auto-scaling demonstration
3. **Set up Cost Management Operator** for cost tracking
4. **Test the MVP demo** with "Big Data" button

---

**🎯 This testing validates that ADR-001 implementation correctly separates WebSocket and VEP service responsibilities while maintaining proper data flow through Kafka messaging.**
