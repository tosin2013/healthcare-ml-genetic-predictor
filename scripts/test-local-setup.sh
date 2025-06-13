#!/bin/bash

# Local Testing Setup for ADR-001 Implementation
# Tests the corrected WebSocket + VEP service architecture

set -e

echo "🧪 Setting up local testing environment for ADR-001..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Podman is available
if ! command -v podman &> /dev/null; then
    print_error "Podman is not installed. Please install podman first."
    exit 1
fi

# Check if Podman is working
if ! podman info > /dev/null 2>&1; then
    print_error "Podman is not working properly. Please check podman setup."
    exit 1
fi

print_status "Starting local Kafka cluster for testing..."

# Create podman-compose for local testing
cat > podman-compose.test.yml << 'EOF'
version: '3.8'
services:
  zookeeper:
    image: docker.io/confluentinc/cp-zookeeper:7.4.0
    hostname: zookeeper
    container_name: test-zookeeper
    ports:
      - "2181:2181"
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    networks:
      - healthcare-ml-test

  kafka:
    image: docker.io/confluentinc/cp-kafka:7.4.0
    hostname: kafka
    container_name: test-kafka
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
      - "9101:9101"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: 'zookeeper:2181'
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:29092,PLAINTEXT_HOST://localhost:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_JMX_PORT: 9101
      KAFKA_JMX_HOSTNAME: localhost
    networks:
      - healthcare-ml-test

  kafka-ui:
    image: docker.io/provectuslabs/kafka-ui:latest
    container_name: test-kafka-ui
    depends_on:
      - kafka
    ports:
      - "8090:8080"
    environment:
      KAFKA_CLUSTERS_0_NAME: local
      KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS: kafka:29092
      KAFKA_CLUSTERS_0_ZOOKEEPER: zookeeper:2181
    networks:
      - healthcare-ml-test

networks:
  healthcare-ml-test:
    driver: bridge
EOF

# Start the services
print_status "Starting Kafka cluster with Podman..."
podman-compose -f podman-compose.test.yml up -d

# Wait for Kafka to be ready
print_status "Waiting for Kafka to be ready..."
sleep 10

# Create the required topics
print_status "Creating Kafka topics..."
podman exec test-kafka kafka-topics --create --topic genetic-data-raw --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
podman exec test-kafka kafka-topics --create --topic genetic-data-annotated --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1

# Verify topics
print_status "Verifying topics..."
podman exec test-kafka kafka-topics --list --bootstrap-server localhost:9092

print_success "Local Kafka cluster is ready!"
print_status "Kafka UI available at: http://localhost:8090"
print_status "Kafka broker available at: localhost:9092"

echo ""
echo "🧪 Test Environment Ready!"
echo "📋 Next steps:"
echo "   1. Start WebSocket service: cd quarkus-websocket-service && ./mvnw quarkus:dev"
echo "   2. Start VEP service: cd vep-service && ./mvnw quarkus:dev -Dquarkus.http.port=8081"
echo "   3. Open browser: http://localhost:8080/genetic-client.html"
echo "   4. Test the data flow!"
echo ""
echo "🔍 Monitor topics:"
echo "   - Raw data: podman exec test-kafka kafka-console-consumer --topic genetic-data-raw --bootstrap-server localhost:9092"
echo "   - Annotated data: podman exec test-kafka kafka-console-consumer --topic genetic-data-annotated --bootstrap-server localhost:9092"
echo ""
echo "🛑 To stop: podman-compose -f podman-compose.test.yml down"
