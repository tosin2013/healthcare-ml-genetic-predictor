#!/bin/bash

# Containerized Local Testing Script for ADR-001 Implementation
# Phase 1.5: Start all services in containers for realistic testing

set -e

echo "🐳 Starting Containerized Healthcare ML Demo (ADR-001 Compliant)"
echo "================================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if podman-compose is available
if ! command -v podman-compose &> /dev/null; then
    print_error "podman-compose is not installed. Please install podman-compose first."
    exit 1
fi

print_status "Building and starting containerized services..."

# Build and start all services
podman-compose -f podman-compose.test.yml up --build -d

print_status "Waiting for services to be healthy..."

# Wait for services to be ready
sleep 30

# Check service health
print_status "Checking service health..."

# Check Kafka
if curl -s http://localhost:8090 > /dev/null 2>&1; then
    print_success "✅ Kafka UI accessible at http://localhost:8090"
else
    print_warning "⚠️  Kafka UI not yet ready"
fi

# Check WebSocket Service
if curl -s http://localhost:8080/q/health > /dev/null 2>&1; then
    print_success "✅ WebSocket Service healthy at http://localhost:8080"
else
    print_warning "⚠️  WebSocket Service not yet ready"
fi

# Check VEP Service
if curl -s http://localhost:8081/q/health > /dev/null 2>&1; then
    print_success "✅ VEP Service healthy at http://localhost:8081"
else
    print_warning "⚠️  VEP Service not yet ready"
fi

echo ""
print_success "🎉 Containerized Demo Environment Ready!"
echo ""
echo "📋 Testing Instructions:"
echo "========================"
echo ""
echo "1. 🌐 Open WebSocket UI:"
echo "   http://localhost:8080/genetic-client.html"
echo ""
echo "2. 📊 Monitor Kafka Topics:"
echo "   http://localhost:8090"
echo ""
echo "3. 🧬 Test Genetic Sequence:"
echo "   Submit: ATCGATCGATCG"
echo ""
echo "4. 🔍 Verify ADR-001 Data Flow:"
echo "   - WebSocket Service (Port 8080) → Kafka → VEP Service (Port 8081)"
echo "   - Check container logs: podman logs test-websocket-service"
echo "   - Check container logs: podman logs test-vep-service"
echo ""
echo "5. 🏥 Health Checks:"
echo "   - WebSocket: http://localhost:8080/q/health"
echo "   - VEP Service: http://localhost:8081/q/health"
echo ""
echo "🛑 To stop all services:"
echo "   podman-compose -f podman-compose.test.yml down"
echo ""
echo "🔄 To rebuild and restart:"
echo "   podman-compose -f podman-compose.test.yml down && ./scripts/start-containerized-demo.sh"
