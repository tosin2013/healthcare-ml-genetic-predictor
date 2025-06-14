package com.redhat.healthcare;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.redhat.healthcare.model.*;
import io.cloudevents.CloudEvent;
import io.cloudevents.core.builder.CloudEventBuilder;
import io.cloudevents.core.format.EventFormat;
import io.cloudevents.core.provider.EventFormatProvider;
import io.cloudevents.jackson.JsonFormat;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.validation.Valid;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.net.URI;
import java.time.OffsetDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;

/**
 * REST API Controller for Scaling Mode Testing and Validation.
 * 
 * Provides programmatic access to scaling functionality for automated testing,
 * CI/CD integration, and demo execution. Mirrors the functionality of the
 * genetic-client.html interface for consistent behavior.
 * 
 * Endpoints:
 * - POST /api/scaling/mode - Set scaling mode (normal/bigdata)
 * - POST /api/genetic/analyze - Process genetic sequences
 * - POST /api/scaling/trigger-demo - Trigger node scaling demo
 * - GET /api/scaling/status/{trackingId} - Monitor scaling status
 * - GET /api/scaling/health - Health check
 */
@Path("/api")
@ApplicationScoped
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class ScalingTestController {

    private static final Logger LOGGER = LoggerFactory.getLogger(ScalingTestController.class);
    
    @Inject
    @Channel("genetic-data-raw-out")
    Emitter<String> geneticDataEmitter;
    
    @Inject
    ObjectMapper objectMapper;
    
    // Current scaling mode (shared state for API consistency)
    private volatile String currentMode = "normal";
    
    /**
     * Set the scaling mode for subsequent operations.
     * 
     * @param request Scaling mode request (normal/bigdata)
     * @return API response with mode confirmation
     */
    @POST
    @Path("/scaling/mode")
    public Response setScalingMode(@Valid ScalingModeRequest request) {
        try {
            LOGGER.info("Setting scaling mode to: {}", request.getMode());
            
            this.currentMode = request.getMode();
            
            String modeMessage = request.isBigDataMode() ? 
                "🚀 Big Data Mode activated - node scaling demonstration" :
                "📊 Normal Mode activated - pod scaling demonstration";
            
            Map<String, Object> responseData = new HashMap<>();
            responseData.put("mode", request.getMode());
            responseData.put("previousMode", currentMode);
            responseData.put("description", request.getDescription());
            
            ApiResponse<Map<String, Object>> response = ApiResponse.success(modeMessage, responseData)
                .addMetadata("scalingMode", request.getMode())
                .addMetadata("expectedScaling", request.isBigDataMode() ?
                    "1→10+ pods, 6→7+ nodes" : "1→2+ pods");
            
            return Response.ok(response).build();
            
        } catch (Exception e) {
            LOGGER.error("Failed to set scaling mode: {}", e.getMessage(), e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                .entity(ApiResponse.error("Failed to set scaling mode: " + e.getMessage()))
                .build();
        }
    }
    
    /**
     * Process genetic sequence with specified mode and batch size.
     * 
     * @param request Genetic analysis request
     * @return API response with processing confirmation
     */
    @POST
    @Path("/genetic/analyze")
    public Response analyzeGeneticSequence(@Valid GeneticAnalysisRequest request) {
        try {
            // Use current mode if not specified in request
            String processingMode = request.getMode() != null ? request.getMode() : currentMode;
            request.setMode(processingMode);
            
            // Set defaults if not provided
            if (request.getTimestamp() == 0) {
                request.setTimestamp(System.currentTimeMillis());
            }
            if (request.getSessionId() == null) {
                request.setSessionId("api-session-" + UUID.randomUUID().toString().substring(0, 8));
            }
            
            LOGGER.info("Processing genetic sequence in {} mode: {} chars", 
                       processingMode, request.getSequence().length());
            
            // Create CloudEvent for Kafka publishing (same logic as WebSocket endpoint)
            ObjectNode data = objectMapper.createObjectNode();
            data.put("sessionId", request.getSessionId());
            data.put("userId", "api-user-" + request.getSessionId().substring(0, 8));
            data.put("genetic_sequence", request.getSequence());
            data.put("processing_mode", processingMode);
            data.put("resource_profile", request.getResourceProfile());
            data.put("sequence_length", request.getSequence().length());
            data.put("timestamp", request.getTimestamp());
            data.put("api_request", true);
            
            // Determine CloudEvent type based on mode
            String eventType = "big-data".equals(processingMode) ?
                "com.redhat.healthcare.genetic.sequence.bigdata" :
                "com.redhat.healthcare.genetic.sequence.raw";
            
            CloudEvent event = CloudEventBuilder.v1()
                .withId(UUID.randomUUID().toString())
                .withSource(URI.create("https://healthcare-ml-demo/api/genetic/analyze"))
                .withType(eventType)
                .withDataContentType("application/json")
                .withData(data.toString().getBytes())
                .withTime(OffsetDateTime.now())
                .build();
            
            // Serialize and send to Kafka
            EventFormat format = EventFormatProvider.getInstance().resolveFormat(JsonFormat.CONTENT_TYPE);
            byte[] cloudEventBytes = format.serialize(event);
            String cloudEventJson = new String(cloudEventBytes);
            geneticDataEmitter.send(cloudEventJson);
            
            LOGGER.info("Sent {} CloudEvent to Kafka for {} mode processing", eventType, processingMode);
            
            // Prepare response
            Map<String, Object> responseData = new HashMap<>();
            responseData.put("sequencesSubmitted", 1);
            responseData.put("processingMode", processingMode);
            responseData.put("sequenceLength", request.getSequence().length());
            responseData.put("sessionId", request.getSessionId());
            responseData.put("trackingId", event.getId());
            
            String expectedScaling = "big-data".equals(processingMode) ?
                "1→10+ pods, 6→7+ nodes" : "1→2+ pods";
            
            ApiResponse<Map<String, Object>> response = ApiResponse.success(
                String.format("🧬 Genetic sequence (%d chars) queued for %s processing", 
                             request.getSequence().length(), processingMode), 
                responseData)
                .addMetadata("expectedScaling", expectedScaling)
                .addMetadata("eventType", eventType);
            
            return Response.ok(response).build();

        } catch (Exception e) {
            LOGGER.error("Failed to analyze genetic sequence: {}", e.getMessage(), e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                .entity(ApiResponse.error("Failed to analyze genetic sequence: " + e.getMessage()))
                .build();
        }
    }

    /**
     * Trigger scaling demonstration with multiple large sequences.
     *
     * @param request Scaling demo request
     * @return API response with demo confirmation
     */
    @POST
    @Path("/scaling/trigger-demo")
    public Response triggerScalingDemo(@Valid ScalingDemoRequest request) {
        try {
            LOGGER.info("Triggering {} demo with {} sequences of size {}",
                       request.getDemoType(), request.getSequenceCount(), request.getSequenceSize());

            String demoSessionId = "demo-session-" + UUID.randomUUID().toString().substring(0, 8);
            int sequenceSize = request.getSequenceSizeInBytes();
            int sequenceCount = request.getSequenceCount();

            // Generate and send multiple large sequences (similar to genetic-client.html triggerBigDataScaling)
            for (int i = 0; i < sequenceCount; i++) {
                String largeSequence = generateLargeGeneticSequence(sequenceSize);

                // Create genetic analysis request for each sequence
                GeneticAnalysisRequest analysisRequest = new GeneticAnalysisRequest();
                analysisRequest.setSequence(largeSequence);
                analysisRequest.setMode("big-data");
                analysisRequest.setResourceProfile("high-memory");
                analysisRequest.setTimestamp(System.currentTimeMillis());
                analysisRequest.setSessionId(demoSessionId + "-seq-" + (i + 1));

                // Process the sequence (reuse the analyze logic)
                processSequenceForDemo(analysisRequest, i + 1, sequenceCount);

                // Add delay between sequences to simulate realistic load
                if (i < sequenceCount - 1) {
                    Thread.sleep(2000); // 2 second delay
                }
            }

            // Prepare response
            Map<String, Object> responseData = new HashMap<>();
            responseData.put("sequencesQueued", sequenceCount);
            responseData.put("demoType", request.getDemoType());
            responseData.put("sequenceSize", request.getSequenceSize());
            responseData.put("totalDataSize", String.format("%.1f MB", (sequenceSize * sequenceCount) / (1024.0 * 1024.0)));
            responseData.put("demoSessionId", demoSessionId);

            String expectedScaling = request.isNodeScalingDemo() ?
                "1→10+ pods, 6→7+ nodes" : "1→5+ pods";

            ApiResponse<Map<String, Object>> response = ApiResponse.success(
                String.format("⚡ %s demo triggered with %d sequences (%s each)",
                             request.getDemoType(), sequenceCount, request.getSequenceSize()),
                responseData)
                .addMetadata("expectedScaling", expectedScaling)
                .addMetadata("estimatedDuration", "2-5 minutes");

            return Response.ok(response).build();

        } catch (Exception e) {
            LOGGER.error("Failed to trigger scaling demo: {}", e.getMessage(), e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                .entity(ApiResponse.error("Failed to trigger scaling demo: " + e.getMessage()))
                .build();
        }
    }

    /**
     * Get scaling status for a specific tracking ID.
     *
     * @param trackingId Tracking ID from previous requests
     * @return API response with scaling status
     */
    @GET
    @Path("/scaling/status/{trackingId}")
    public Response getScalingStatus(@PathParam("trackingId") String trackingId) {
        try {
            LOGGER.debug("Getting scaling status for tracking ID: {}", trackingId);

            // In a real implementation, this would query KEDA metrics, Kafka lag, etc.
            // For now, we'll return simulated status based on current mode
            Map<String, Object> statusData = new HashMap<>();
            statusData.put("trackingId", trackingId);
            statusData.put("status", "processing");
            statusData.put("currentMode", currentMode);

            // Simulate scaling metrics (in real implementation, query actual metrics)
            if ("big-data".equals(currentMode)) {
                statusData.put("currentPods", ThreadLocalRandom.current().nextInt(5, 15));
                statusData.put("currentNodes", ThreadLocalRandom.current().nextInt(6, 8));
                statusData.put("kafkaLag", ThreadLocalRandom.current().nextInt(10, 50));
            } else {
                statusData.put("currentPods", ThreadLocalRandom.current().nextInt(1, 3));
                statusData.put("currentNodes", 6);
                statusData.put("kafkaLag", ThreadLocalRandom.current().nextInt(0, 10));
            }

            ApiResponse<Map<String, Object>> response = ApiResponse.success(
                "Scaling status retrieved", statusData)
                .addMetadata("note", "Simulated metrics - integrate with actual KEDA/Prometheus metrics");

            return Response.ok(response).build();

        } catch (Exception e) {
            LOGGER.error("Failed to get scaling status: {}", e.getMessage(), e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                .entity(ApiResponse.error("Failed to get scaling status: " + e.getMessage()))
                .build();
        }
    }

    /**
     * Health check endpoint for infrastructure readiness.
     *
     * @return API response with health status
     */
    @GET
    @Path("/scaling/health")
    public Response getHealthStatus() {
        try {
            LOGGER.debug("Performing health check");

            Map<String, Object> healthData = new HashMap<>();
            healthData.put("application", "ready");
            healthData.put("kafka", "ready"); // In real implementation, check Kafka connectivity
            healthData.put("keda", "ready");  // In real implementation, check KEDA operator status
            healthData.put("clusterAutoscaler", "ready"); // Check cluster autoscaler status
            healthData.put("currentMode", currentMode);

            ApiResponse<Map<String, Object>> response = ApiResponse.success(
                "All systems ready for scaling demonstration", healthData)
                .addMetadata("version", "1.0.0")
                .addMetadata("capabilities", "pod-scaling,node-scaling,cost-tracking");

            return Response.ok(response).build();

        } catch (Exception e) {
            LOGGER.error("Health check failed: {}", e.getMessage(), e);
            return Response.status(Response.Status.SERVICE_UNAVAILABLE)
                .entity(ApiResponse.error("Health check failed: " + e.getMessage()))
                .build();
        }
    }

    // Utility methods

    /**
     * Generate large genetic sequence for scaling demonstrations.
     *
     * @param sizeInBytes Target size in bytes
     * @return Generated genetic sequence
     */
    private String generateLargeGeneticSequence(int sizeInBytes) {
        StringBuilder sequence = new StringBuilder(sizeInBytes);
        String[] bases = {"A", "T", "C", "G"};

        for (int i = 0; i < sizeInBytes; i++) {
            sequence.append(bases[ThreadLocalRandom.current().nextInt(bases.length)]);
        }

        return sequence.toString();
    }

    /**
     * Process sequence for demo with logging.
     *
     * @param request Genetic analysis request
     * @param sequenceNumber Current sequence number
     * @param totalSequences Total sequences in demo
     */
    private void processSequenceForDemo(GeneticAnalysisRequest request, int sequenceNumber, int totalSequences) {
        try {
            // Create CloudEvent for demo sequence
            ObjectNode data = objectMapper.createObjectNode();
            data.put("sessionId", request.getSessionId());
            data.put("userId", "demo-api-user");
            data.put("genetic_sequence", request.getSequence());
            data.put("processing_mode", request.getMode());
            data.put("resource_profile", request.getResourceProfile());
            data.put("sequence_length", request.getSequence().length());
            data.put("timestamp", request.getTimestamp());
            data.put("demo_sequence", true);
            data.put("sequence_number", sequenceNumber);
            data.put("total_sequences", totalSequences);

            CloudEvent event = CloudEventBuilder.v1()
                .withId(UUID.randomUUID().toString())
                .withSource(URI.create("https://healthcare-ml-demo/api/scaling/trigger-demo"))
                .withType("com.redhat.healthcare.genetic.sequence.bigdata")
                .withDataContentType("application/json")
                .withData(data.toString().getBytes())
                .withTime(OffsetDateTime.now())
                .build();

            // Serialize and send to Kafka
            EventFormat format = EventFormatProvider.getInstance().resolveFormat(JsonFormat.CONTENT_TYPE);
            byte[] cloudEventBytes = format.serialize(event);
            String cloudEventJson = new String(cloudEventBytes);
            geneticDataEmitter.send(cloudEventJson);

            LOGGER.info("Sent demo sequence {}/{} to Kafka: {} bytes",
                       sequenceNumber, totalSequences, request.getSequence().length());

        } catch (Exception e) {
            LOGGER.error("Failed to process demo sequence {}/{}: {}",
                        sequenceNumber, totalSequences, e.getMessage(), e);
        }
    }
}
