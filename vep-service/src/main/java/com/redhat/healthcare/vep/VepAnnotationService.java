package com.redhat.healthcare.vep;


import io.smallrye.reactive.messaging.annotations.Blocking;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.eclipse.microprofile.reactive.messaging.Outgoing;
import org.eclipse.microprofile.rest.client.inject.RestClient;
import org.jboss.logging.Logger;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import java.time.Instant;

import io.cloudevents.CloudEvent;
import io.cloudevents.core.builder.CloudEventBuilder;
import io.cloudevents.core.format.EventFormat;
import io.cloudevents.core.provider.EventFormatProvider;
import io.cloudevents.jackson.JsonFormat;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import java.net.URI;
import java.util.UUID;

/**
 * VEP (Variant Effect Predictor) Annotation Service
 * 
 * This service processes genetic sequences from Kafka, annotates them using
 * the Ensembl VEP API, and publishes the annotated results back to Kafka.
 * 
 * Features:
 * - Kafka-based message processing
 * - VEP API integration with caching
 * - Error handling and retry logic
 * - Health checks and metrics
 * - Independent scaling with KEDA
 */
@ApplicationScoped
public class VepAnnotationService {

    private static final Logger LOG = Logger.getLogger(VepAnnotationService.class);

    @Inject
    @RestClient
    VepApiClient vepApiClient;

    @Inject
    VepAnnotationProcessor annotationProcessor;

    @Inject
    ObjectMapper objectMapper;

    /**
     * Processes genetic sequences from the raw data topic
     *
     * @param geneticData Raw genetic sequence data from Kafka
     * @return Annotated genetic data for downstream processing
     */
    @Incoming("genetic-data-raw")
    @Outgoing("genetic-data-annotated")
    @Blocking(value = "vep-worker-pool", ordered = false)
    public String processGeneticSequence(String cloudEventJson) {
        LOG.infof("Processing genetic sequence: %s",
                  cloudEventJson.length() > 50 ? cloudEventJson.substring(0, 50) + "..." : cloudEventJson);

        try {
            // RQ1.1 Solution: CloudEvent processing on dedicated worker thread pool
            LOG.infof("Processing CloudEvent on Worker Thread: %s", Thread.currentThread().getName());

            // Parse CloudEvent and extract genetic data (now safe to block on Virtual Thread)
            GeneticSequenceData sequenceData = parseCloudEventData(cloudEventJson);

            // Process genetic sequence with VEP annotation (blocking operations now safe)
            VepAnnotationResult annotation = annotateWithVep(sequenceData);

            // Process and enrich the annotation
            AnnotatedGeneticData annotatedData = annotationProcessor.processAnnotation(
                sequenceData, annotation);

            // Create CloudEvent for downstream processing
            String result = createAnnotatedCloudEvent(annotatedData, sequenceData);

            LOG.infof("Successfully annotated sequence with %d variants on Worker Thread",
                     annotation.getVariantCount());

            return result;

        } catch (Exception e) {
            LOG.errorf(e, "Error processing genetic sequence: %s", e.getMessage());

            // Return error result for downstream handling
            return createErrorResult(cloudEventJson, e.getMessage());
        }
    }

    /**
     * Annotates genetic sequence using VEP API (Worker Thread safe)
     * RQ1.1 Solution: Can safely block on dedicated worker threads
     */
    public VepAnnotationResult annotateWithVep(GeneticSequenceData sequenceData) {
        try {
            LOG.debugf("Calling VEP API for sequence: %s on worker thread: %s",
                      sequenceData.getSequenceId(), Thread.currentThread().getName());

            // Call VEP API (blocking operation now safe on Virtual Thread)
            VepApiResponse response = vepApiClient.annotateSequence(
                sequenceData.getSequence(),
                sequenceData.getSpecies(),
                sequenceData.getAssembly()
            );

            // Convert API response to internal format
            return VepAnnotationResult.fromApiResponse(response, sequenceData);

        } catch (Exception e) {
            LOG.warnf(e, "VEP API call failed for sequence %s: %s",
                     sequenceData.getSequenceId(), e.getMessage());

            // Return empty annotation result for graceful degradation
            return VepAnnotationResult.empty(sequenceData);
        }
    }

    /**
     * Parses CloudEvent and extracts genetic sequence data
     */
    private GeneticSequenceData parseCloudEventData(String cloudEventJson) {
        try {
            // Parse CloudEvent
            EventFormat format = EventFormatProvider.getInstance().resolveFormat(JsonFormat.CONTENT_TYPE);
            CloudEvent cloudEvent = format.deserialize(cloudEventJson.getBytes());

            // Extract data payload
            byte[] data = cloudEvent.getData().toBytes();
            JsonNode dataNode = objectMapper.readTree(data);

            // Extract genetic sequence information
            String sequence = dataNode.get("genetic_sequence").asText();
            String sessionId = dataNode.has("sessionId") ? dataNode.get("sessionId").asText() : "unknown";
            String processingMode = dataNode.has("processing_mode") ? dataNode.get("processing_mode").asText() : "normal";

            // Create GeneticSequenceData object
            GeneticSequenceData sequenceData = GeneticSequenceData.fromPlainSequence(sequence);
            sequenceData.setSequenceId(sessionId);
            sequenceData.setProcessingMode(processingMode);
            sequenceData.setSource("cloudevent");

            LOG.infof("Parsed CloudEvent: sessionId=%s, sequence length=%d, mode=%s",
                     sessionId, sequence.length(), processingMode);

            return sequenceData;

        } catch (Exception e) {
            LOG.warnf(e, "Failed to parse CloudEvent, attempting fallback parsing: %s", e.getMessage());
            // Fallback to old parsing method
            return parseGeneticDataFallback(cloudEventJson);
        }
    }

    /**
     * Fallback method for parsing genetic data from JSON or plain text
     */
    private GeneticSequenceData parseGeneticDataFallback(String geneticData) {
        try {
            // Try to parse as JSON first
            if (geneticData.trim().startsWith("{")) {
                return GeneticSequenceData.fromJson(geneticData);
            } else {
                // Treat as plain sequence
                return GeneticSequenceData.fromPlainSequence(geneticData);
            }
        } catch (Exception e) {
            LOG.warnf("Failed to parse genetic data, using fallback: %s", e.getMessage());
            return GeneticSequenceData.fromPlainSequence(geneticData);
        }
    }

    /**
     * Creates CloudEvent for annotated genetic data
     */
    private String createAnnotatedCloudEvent(AnnotatedGeneticData annotatedData, GeneticSequenceData originalData) {
        try {
            // Create data payload
            ObjectNode data = objectMapper.createObjectNode();
            data.put("sessionId", originalData.getSequenceId());
            data.put("genetic_sequence", originalData.getSequence());
            data.put("processing_mode", originalData.getProcessingMode());
            data.put("annotation_timestamp", System.currentTimeMillis());
            data.put("annotation_source", "vep-annotation-service");
            data.put("status", annotatedData.getStatus());
            data.put("variant_count", annotatedData.getVariantCount());
            data.put("sequence_length", annotatedData.getSequenceLength());

            // Add VEP annotations (simplified for now)
            data.set("vep_annotations", objectMapper.createArrayNode());

            // Create CloudEvent
            CloudEvent event = CloudEventBuilder.v1()
                    .withId(UUID.randomUUID().toString())
                    .withSource(URI.create("/vep-annotation-service"))
                    .withType("com.redhat.healthcare.genetic.sequence.annotated")
                    .withSubject("VEP Annotation Complete")
                    .withExtension("sessionid", originalData.getSequenceId())
                    .withExtension("processingmode", originalData.getProcessingMode())
                    .withExtension("variantcount", String.valueOf(annotatedData.getVariantCount()))
                    .withData("application/json", objectMapper.writeValueAsBytes(data))
                    .build();

            // Serialize CloudEvent
            EventFormat format = EventFormatProvider.getInstance().resolveFormat(JsonFormat.CONTENT_TYPE);
            byte[] cloudEventBytes = format.serialize(event);
            return new String(cloudEventBytes);

        } catch (Exception e) {
            LOG.errorf(e, "Failed to create CloudEvent, falling back to simple JSON");
            return annotatedData.toJson();
        }
    }

    /**
     * Creates error result for failed processing
     */
    private String createErrorResult(String originalData, String errorMessage) {
        return String.format("""
            {
                "sequenceId": "error-%d",
                "originalData": "%s",
                "status": "error",
                "errorMessage": "%s",
                "timestamp": "%s",
                "source": "vep-annotation-service",
                "annotations": []
            }
            """,
            System.currentTimeMillis(),
            originalData.length() > 100 ? originalData.substring(0, 100) + "..." : originalData,
            errorMessage.replace("\"", "\\\""),
            Instant.now().toString()
        );
    }
}
