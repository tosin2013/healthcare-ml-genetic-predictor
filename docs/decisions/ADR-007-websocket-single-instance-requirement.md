# ADR-007: WebSocket Service Single Instance Requirement

**Status**: Accepted  
**Date**: 2025-06-23  
**Deciders**: Healthcare ML Team  
**Technical Story**: [GitHub Issue - WebSocket Session Management](https://github.com/tosin2013/healthcare-ml-genetic-predictor/issues/websocket-scaling)

## Context and Problem Statement

The healthcare ML genetic analysis system uses WebSocket connections for real-time communication between the frontend and backend services. During system deployment and scaling configuration, we discovered that the WebSocket service was configured with multiple replicas and KEDA autoscaling, which caused significant issues with session management and user experience.

**Key Issues Identified:**
- WebSocket service deployed with 2 replicas instead of 1
- KEDA ScaledObject configured for WebSocket service autoscaling
- Session loss during scaling events
- Connection routing inconsistencies
- Poor user experience with dropped connections

## Decision Drivers

- **Session Consistency**: WebSocket connections are stateful and tied to specific pod instances
- **User Experience**: Real-time genetic analysis requires stable, persistent connections
- **System Reliability**: Avoid connection drops during critical analysis phases
- **Architectural Simplicity**: Reduce complexity in session management
- **Cost Optimization**: Single instance sufficient for current load requirements

## Considered Options

### Option 1: Multiple Replicas with Session Affinity
**Pros:**
- Higher availability during pod failures
- Load distribution across multiple instances
- Potential for handling higher concurrent connections

**Cons:**
- Complex session affinity configuration required
- Session loss during rolling updates
- Increased complexity in state management
- WebSocket connections don't benefit from traditional load balancing
- Higher resource consumption

### Option 2: Single Replica with High Availability Measures
**Pros:**
- Simple session management (all sessions on one pod)
- No session loss during normal operations
- Consistent connection routing
- Lower resource consumption
- Easier debugging and monitoring

**Cons:**
- Single point of failure
- Limited concurrent connection capacity
- Potential downtime during pod restarts

### Option 3: Stateless WebSocket with External Session Store
**Pros:**
- Scalable across multiple replicas
- Session persistence across pod failures
- Better fault tolerance

**Cons:**
- Significant architectural complexity
- External dependencies (Redis, database)
- Increased latency for session operations
- Over-engineering for current requirements

## Decision Outcome

**Chosen Option**: **Option 2 - Single Replica with High Availability Measures**

### Rationale

1. **Current Load Requirements**: The healthcare ML system currently handles moderate concurrent users, well within single pod capacity
2. **WebSocket Nature**: WebSocket connections are inherently stateful and work best with consistent pod assignment
3. **Simplicity**: Single replica eliminates session management complexity
4. **User Experience**: Ensures stable connections during genetic analysis workflows
5. **Cost Efficiency**: Optimal resource utilization for current scale

### Implementation Details

```yaml
# Deployment Configuration
spec:
  replicas: 1  # CRITICAL: Must be exactly 1
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0  # Ensure zero downtime during updates
      maxSurge: 1        # Allow temporary second pod during updates
```

**High Availability Measures:**
- Rolling update strategy with maxUnavailable: 0
- Comprehensive health checks (liveness and readiness probes)
- Node affinity for stable node placement
- Resource requests/limits for guaranteed resources
- Monitoring and alerting for pod health

## Consequences

### Positive
- ✅ **Stable WebSocket Sessions**: No session loss during normal operations
- ✅ **Simplified Architecture**: Easier to understand and maintain
- ✅ **Consistent User Experience**: Reliable real-time updates during analysis
- ✅ **Lower Resource Usage**: Optimal resource allocation
- ✅ **Easier Debugging**: Single instance simplifies troubleshooting

### Negative
- ❌ **Single Point of Failure**: Pod failure affects all active sessions
- ❌ **Limited Concurrent Capacity**: Single pod connection limits
- ❌ **Brief Downtime During Updates**: Rolling updates may cause temporary disconnections

### Mitigation Strategies

1. **Pod Failure Mitigation**:
   - Comprehensive monitoring and alerting
   - Fast pod restart capabilities
   - Client-side reconnection logic
   - Graceful degradation in frontend

2. **Capacity Management**:
   - Monitor concurrent connection metrics
   - Scale vertically (increase pod resources) if needed
   - Implement connection limits and queuing

3. **Update Downtime Mitigation**:
   - Use rolling updates with maxUnavailable: 0
   - Implement client reconnection with exponential backoff
   - Schedule updates during low-usage periods

## Configuration Changes Made

### 1. Deployment Configurations Fixed
```yaml
# k8s/base/applications/quarkus-websocket/deployment.yaml
spec:
  replicas: 1  # Changed from 2 to 1

# k8s/base/websocket-service/deployment.yaml  
spec:
  replicas: 1  # Changed from 2 to 1
```

### 2. KEDA ScaledObjects Removed
```yaml
# k8s/base/keda/scaledobject.yaml
# Removed websocket-service-scaler ScaledObject

# k8s/base/keda/multi-topic-scaledobjects.yaml
# Removed websocket-service-scaler ScaledObject
```

### 3. OpenShift Deployment Scaled
```bash
oc delete scaledobject websocket-service-scaler -n healthcare-ml-demo
oc scale deployment quarkus-websocket-service --replicas=1 -n healthcare-ml-demo
```

## Monitoring and Validation

### Key Metrics to Monitor
- **Connection Count**: Number of active WebSocket connections
- **Connection Duration**: Average session length
- **Reconnection Rate**: Frequency of client reconnections
- **Pod Health**: CPU, memory, and connection pool utilization
- **Response Times**: WebSocket message latency

### Success Criteria
- ✅ Zero session loss during normal operations
- ✅ Stable connection count without unexpected drops
- ✅ Successful rolling updates with minimal disruption
- ✅ Consistent response times for WebSocket messages

## Future Considerations

### When to Reconsider This Decision
- **High Load**: If concurrent connections exceed single pod capacity (>1000 connections)
- **Global Scale**: If system needs to serve multiple geographic regions
- **High Availability Requirements**: If 99.99% uptime becomes critical
- **Complex Session State**: If session data becomes too large for in-memory storage

### Potential Evolution Path
1. **Vertical Scaling**: Increase pod resources before horizontal scaling
2. **Connection Pooling**: Implement connection limits and queuing
3. **External Session Store**: Add Redis/database for session persistence
4. **Multi-Region Deployment**: Deploy separate instances per region
5. **Service Mesh**: Use Istio/Linkerd for advanced traffic management

## Related Decisions

- [ADR-001: Event-Driven Architecture](ADR-001-event-driven-architecture.md) - WebSocket integration with Kafka
- [ADR-006: KEDA Scaling Strategy](ADR-006-keda-scaling-strategy.md) - Why VEP services scale but WebSocket doesn't

## References

- [WebSocket RFC 6455](https://tools.ietf.org/html/rfc6455)
- [Kubernetes Rolling Updates](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-update-deployment)
- [KEDA ScaledObject Documentation](https://keda.sh/docs/2.10/concepts/scaling-deployments/)
- [Quarkus WebSocket Guide](https://quarkus.io/guides/websockets)

---

**Implementation Status**: ✅ Complete  
**Validation**: ✅ Single pod confirmed running in OpenShift  
**Next Review**: 2025-09-23 (3 months) or when load requirements change
