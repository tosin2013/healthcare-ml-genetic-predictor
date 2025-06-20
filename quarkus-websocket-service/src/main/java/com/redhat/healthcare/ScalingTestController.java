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
import io.smallrye.common.annotation.Blocking;
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
    // Multi-topic emitters for different scaling modes (same as WebSocket implementation)
    @Channel("genetic-data-raw-out")
    Emitter<String> geneticDataEmitter;

    @Channel("genetic-bigdata-raw-out")
    Emitter<String> geneticBigDataEmitter;

    @Channel("genetic-nodescale-raw-out")
    Emitter<String> geneticNodeScaleEmitter;

    @Channel("genetic-lag-demo-raw-out")
    Emitter<String> geneticLagDemoEmitter;
    
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
            
            String modeMessage;
            if (request.isBigDataMode()) {
                modeMessage = "🚀 Big Data Mode activated - memory-intensive scaling demonstration";
            } else if (request.isNodeScaleMode()) {
                modeMessage = "⚡ Node Scale Mode activated - cluster autoscaler demonstration";
            } else if (request.isKafkaLagMode()) {
                modeMessage = "🔄 Kafka Lag Mode activated - consumer lag scaling demonstration";
            } else {
                modeMessage = "📊 Normal Mode activated - standard pod scaling demonstration";
            }
            
            Map<String, Object> responseData = new HashMap<>();
            responseData.put("mode", request.getMode());
            responseData.put("previousMode", currentMode);
            responseData.put("description", request.getDescription());
            
            String expectedScaling;
            if (request.isBigDataMode()) {
                expectedScaling = "1→10+ pods (memory-intensive)";
            } else if (request.isNodeScaleMode()) {
                expectedScaling = "1→10+ pods, 6→7+ nodes (cluster autoscaler)";
            } else if (request.isKafkaLagMode()) {
                expectedScaling = "0→10+ pods (consumer lag-based)";
            } else {
                expectedScaling = "1→2+ pods (standard scaling)";
            }

            ApiResponse<Map<String, Object>> response = ApiResponse.success(modeMessage, responseData)
                .addMetadata("scalingMode", request.getMode())
                .addMetadata("expectedScaling", expectedScaling);
            
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
    @Blocking  // Ensure this runs on worker thread to avoid event loop blocking
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
            
            // Determine CloudEvent type and topic based on mode (same logic as WebSocket)
            String eventType;
            String kafkaTopic;

            switch (processingMode) {
                case "bigdata":
                case "big-data":
                    eventType = "com.redhat.healthcare.genetic.sequence.bigdata";
                    kafkaTopic = "genetic-bigdata-raw";
                    break;
                case "node-scale":
                case "nodescale":
                    eventType = "com.redhat.healthcare.genetic.sequence.nodescale";
                    kafkaTopic = "genetic-nodescale-raw";
                    break;
                case "kafka-lag":
                    eventType = "com.redhat.healthcare.genetic.sequence.kafkalag";
                    kafkaTopic = "genetic-lag-demo-raw";
                    break;
                default: // "normal"
                    eventType = "com.redhat.healthcare.genetic.sequence.raw";
                    kafkaTopic = "genetic-data-raw";
                    break;
            }

            CloudEvent event = CloudEventBuilder.v1()
                .withId(UUID.randomUUID().toString())
                .withSource(URI.create("https://healthcare-ml-demo/api/genetic/analyze"))
                .withType(eventType)
                .withSubject("Genetic Sequence Analysis - " + processingMode.toUpperCase() + " Mode")
                .withExtension("processingmode", processingMode)
                .withExtension("resourceprofile", request.getResourceProfile())
                .withExtension("sequencelength", String.valueOf(request.getSequence().length()))
                .withData("application/json", data.toString().getBytes())
                .withTime(OffsetDateTime.now())
                .build();

            // Serialize CloudEvent to JSON
            EventFormat format = EventFormatProvider.getInstance().resolveFormat(JsonFormat.CONTENT_TYPE);
            byte[] cloudEventBytes = format.serialize(event);
            String cloudEventJson = new String(cloudEventBytes);

            // Send to appropriate topic based on mode (same logic as WebSocket)
            switch (processingMode) {
                case "bigdata":
                case "big-data":
                    geneticBigDataEmitter.send(cloudEventJson);
                    break;
                case "node-scale":
                case "nodescale":
                    geneticNodeScaleEmitter.send(cloudEventJson);
                    break;
                case "kafka-lag":
                    geneticLagDemoEmitter.send(cloudEventJson);
                    break;
                default: // "normal"
                    geneticDataEmitter.send(cloudEventJson);
                    break;
            }

            LOGGER.info("Sent {} CloudEvent to {} topic for {} mode processing", eventType, kafkaTopic, processingMode);
            
            // Prepare response
            Map<String, Object> responseData = new HashMap<>();
            responseData.put("sequencesSubmitted", 1);
            responseData.put("processingMode", processingMode);
            responseData.put("sequenceLength", request.getSequence().length());
            responseData.put("sessionId", request.getSessionId());
            responseData.put("trackingId", event.getId());
            
            String expectedScaling = "bigdata".equals(processingMode) ?
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
    @Blocking  // Ensure this runs on worker thread due to Thread.sleep()
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
                analysisRequest.setMode("bigdata");
                analysisRequest.setResourceProfile("high-memory");
                analysisRequest.setTimestamp(System.currentTimeMillis());
                analysisRequest.setSessionId(demoSessionId + "-seq-" + (i + 1));

                // Process the sequence (reuse the analyze logic)
                processSequenceForDemo(analysisRequest, i + 1, sequenceCount);

                // Add delay between sequences to simulate realistic load
                if (i < sequenceCount - 1) {
                    try {
                        Thread.sleep(2000); // 2 second delay - TODO: Replace with reactive delay
                    } catch (InterruptedException e) {
                        Thread.currentThread().interrupt();
                        LOGGER.warn("Demo sequence delay interrupted");
                        break;
                    }
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
            if ("bigdata".equals(currentMode)) {
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
     * Get real-time VEP service status including pod count and scaling information.
     *
     * @return API response with VEP service status
     */
    @GET
    @Path("/scaling/vep-status")
    @Produces(MediaType.APPLICATION_JSON)
    public Response getVepServiceStatus() {
        try {
            LOGGER.debug("Getting VEP service status");

            // This would typically call OpenShift API to get real pod counts
            // For now, we'll return mock data that can be updated with real API calls
            Map<String, Object> vepStatus = new HashMap<>();
            vepStatus.put("serviceName", "vep-service");
            vepStatus.put("currentPods", 1); // This should be fetched from OpenShift API
            vepStatus.put("targetPods", 1);
            vepStatus.put("maxPods", 20);
            vepStatus.put("kedaActive", true);
            vepStatus.put("kafkaLag", 0); // This should be fetched from Kafka
            vepStatus.put("scalingStatus", "ready");
            vepStatus.put("estimatedWaitTime", "15-30 seconds");
            vepStatus.put("lastScalingEvent", System.currentTimeMillis() - 30000);

            Map<String, Object> responseData = new HashMap<>();
            responseData.put("vepService", vepStatus);
            responseData.put("lastUpdated", System.currentTimeMillis());
            responseData.put("refreshInterval", 2000); // Suggest 2-second refresh

            ApiResponse<Map<String, Object>> response = ApiResponse.success(
                "VEP service status retrieved successfully",
                responseData
            );

            return Response.ok(response).build();

        } catch (Exception e) {
            LOGGER.error("Failed to get VEP service status: {}", e.getMessage(), e);
            ApiResponse<String> response = ApiResponse.error(
                "Failed to retrieve VEP service status: " + e.getMessage()
            );
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).entity(response).build();
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

            // Serialize CloudEvent to JSON
            EventFormat format = EventFormatProvider.getInstance().resolveFormat(JsonFormat.CONTENT_TYPE);
            byte[] cloudEventBytes = format.serialize(event);
            String cloudEventJson = new String(cloudEventBytes);

            // Send to appropriate topic based on mode
            switch (request.getMode()) {
                case "bigdata":
                case "big-data":
                    geneticBigDataEmitter.send(cloudEventJson);
                    break;
                case "node-scale":
                case "nodescale":
                    geneticNodeScaleEmitter.send(cloudEventJson);
                    break;
                default: // "normal"
                    geneticDataEmitter.send(cloudEventJson);
                    break;
            }

            LOGGER.info("Sent demo sequence {}/{} to Kafka: {} bytes",
                       sequenceNumber, totalSequences, request.getSequence().length());

        } catch (Exception e) {
            LOGGER.error("Failed to process demo sequence {}/{}: {}",
                        sequenceNumber, totalSequences, e.getMessage(), e);
        }
    }
}
