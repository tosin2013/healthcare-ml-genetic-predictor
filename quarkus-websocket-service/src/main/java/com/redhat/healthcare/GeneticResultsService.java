package com.redhat.healthcare;

import io.cloudevents.CloudEvent;
import io.cloudevents.core.format.EventFormat;
import io.cloudevents.core.provider.EventFormatProvider;
import io.cloudevents.jackson.JsonFormat;
import io.smallrye.mutiny.Uni;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.websocket.Session;
import java.util.concurrent.ConcurrentHashMap;
import java.util.Map;

/**
 * Service that consumes VEP-annotated genetic data and sends results back to WebSocket clients.
 * 
 * This service completes the reactive processing loop by:
 * 1. Consuming enriched genetic data from the genetic-data-annotated Kafka topic
 * 2. Extracting session information from CloudEvents
 * 3. Formatting VEP annotations for frontend display
 * 4. Sending formatted results back to the appropriate WebSocket client
 * 
 * The service maintains a registry of active WebSocket sessions to enable
 * real-time delivery of genetic analysis results to connected clients.
 */
@ApplicationScoped
public class GeneticResultsService {

    private static final Logger LOGGER = LoggerFactory.getLogger(GeneticResultsService.class);

    @Inject
    ObjectMapper objectMapper;

    // Registry to track active WebSocket sessions
    private static final Map<String, Session> activeSessions = new ConcurrentHashMap<>();

    /**
     * Register a WebSocket session for receiving results.
     * Called by the WebSocket endpoint when a client connects.
     */
    public static void registerSession(String sessionId, Session session) {
        activeSessions.put(sessionId, session);
        LOGGER.info("Registered WebSocket session: {}", sessionId);
    }

    /**
     * Unregister a WebSocket session.
     * Called by the WebSocket endpoint when a client disconnects.
     */
    public static void unregisterSession(String sessionId) {
        activeSessions.remove(sessionId);
        LOGGER.info("Unregistered WebSocket session: {}", sessionId);
    }

    /**
     * Process VEP-annotated genetic data and send results to WebSocket clients.
     * 
     * This method consumes CloudEvents containing VEP-enriched genetic data,
     * formats the annotations for frontend display, and sends the results
     * back to the appropriate WebSocket client based on session ID.
     * 
     * @param cloudEventJson CloudEvent JSON containing VEP-annotated genetic data
     * @return Uni<Void> for reactive processing completion
     */
    @Incoming("genetic-data-annotated-in")
    public Uni<Void> processAnnotatedResults(String cloudEventJson) {
        LOGGER.debug("Processing annotated genetic data: {}", cloudEventJson);
        
        return parseCloudEvent(cloudEventJson)
            .chain(this::extractSessionAndResults)
            .chain(this::formatResultsForFrontend)
            .chain(this::sendResultsToClient)
            .onFailure().invoke(throwable -> 
                LOGGER.error("Failed to process annotated results: {}", throwable.getMessage(), throwable))
            .onFailure().recoverWithNull();
    }

    /**
     * Parse CloudEvent JSON string into CloudEvent object.
     */
    private Uni<CloudEvent> parseCloudEvent(String cloudEventJson) {
        return Uni.createFrom().item(() -> {
            try {
                EventFormat format = EventFormatProvider.getInstance().resolveFormat(JsonFormat.CONTENT_TYPE);
                return format.deserialize(cloudEventJson.getBytes());
            } catch (Exception e) {
                LOGGER.error("Failed to parse CloudEvent: {}", e.getMessage());
                throw new RuntimeException("Invalid CloudEvent format", e);
            }
        });
    }

    /**
     * Extract session ID and VEP results from CloudEvent.
     */
    private Uni<AnnotatedResults> extractSessionAndResults(CloudEvent cloudEvent) {
        return Uni.createFrom().item(() -> {
            try {
                byte[] data = cloudEvent.getData().toBytes();
                JsonNode dataNode = objectMapper.readTree(data);
                
                String sessionId = dataNode.get("sessionId").asText();
                String geneticSequence = dataNode.get("genetic_sequence").asText();
                JsonNode vepAnnotations = dataNode.get("vep_annotations");
                long annotationTimestamp = dataNode.get("annotation_timestamp").asLong();
                String annotationSource = dataNode.get("annotation_source").asText();
                
                LOGGER.debug("Extracted results for session: {} with {} annotations", 
                    sessionId, vepAnnotations.size());
                
                return new AnnotatedResults(sessionId, geneticSequence, vepAnnotations, 
                    annotationTimestamp, annotationSource);
                    
            } catch (Exception e) {
                LOGGER.error("Failed to extract session and results from CloudEvent: {}", e.getMessage());
                throw new RuntimeException("Invalid annotated data format", e);
            }
        });
    }

    /**
     * Format VEP annotation results for frontend display.
     */
    private Uni<FormattedResults> formatResultsForFrontend(AnnotatedResults results) {
        return Uni.createFrom().item(() -> {
            try {
                StringBuilder formattedMessage = new StringBuilder();
                formattedMessage.append("🧬 **Genetic Analysis Complete**\n\n");
                formattedMessage.append("**Sequence:** ").append(results.geneticSequence).append("\n");
                formattedMessage.append("**Analysis Source:** ").append(results.annotationSource).append("\n\n");
                
                if (results.vepAnnotations.isArray() && results.vepAnnotations.size() > 0) {
                    formattedMessage.append("**🔬 VEP Annotations Found:**\n");
                    
                    for (JsonNode annotation : results.vepAnnotations) {
                        formattedMessage.append("• **Variant:** ").append(annotation.get("input").asText("N/A")).append("\n");
                        formattedMessage.append("  - **Consequence:** ").append(annotation.get("most_severe_consequence").asText("Unknown")).append("\n");
                        
                        JsonNode transcripts = annotation.get("transcript_consequences");
                        if (transcripts != null && transcripts.isArray() && transcripts.size() > 0) {
                            JsonNode firstTranscript = transcripts.get(0);
                            if (firstTranscript.has("gene_symbol")) {
                                formattedMessage.append("  - **Gene:** ").append(firstTranscript.get("gene_symbol").asText()).append("\n");
                            }
                            if (firstTranscript.has("impact")) {
                                formattedMessage.append("  - **Impact:** ").append(firstTranscript.get("impact").asText()).append("\n");
                            }
                            if (firstTranscript.has("sift_prediction")) {
                                formattedMessage.append("  - **SIFT:** ").append(firstTranscript.get("sift_prediction").asText()).append("\n");
                            }
                            if (firstTranscript.has("polyphen_prediction")) {
                                formattedMessage.append("  - **PolyPhen:** ").append(firstTranscript.get("polyphen_prediction").asText()).append("\n");
                            }
                        }
                        formattedMessage.append("\n");
                    }
                } else {
                    formattedMessage.append("**ℹ️ No VEP annotations available**\n");
                    formattedMessage.append("This may indicate:\n");
                    formattedMessage.append("• No known variants in this sequence\n");
                    formattedMessage.append("• VEP service temporarily unavailable\n");
                    formattedMessage.append("• Sequence requires further analysis\n\n");
                }
                
                formattedMessage.append("**⏱️ Analysis completed at:** ")
                    .append(new java.util.Date(results.annotationTimestamp).toString()).append("\n");
                formattedMessage.append("**✅ Ready for next analysis**");
                
                LOGGER.debug("Formatted results for session: {}", results.sessionId);
                return new FormattedResults(results.sessionId, formattedMessage.toString());
                
            } catch (Exception e) {
                LOGGER.error("Failed to format results: {}", e.getMessage());
                // Fallback formatting
                String fallbackMessage = "🧬 Genetic analysis completed for sequence: " + results.geneticSequence + 
                    "\n⚠️ Detailed results formatting failed. Raw data available in logs.";
                return new FormattedResults(results.sessionId, fallbackMessage);
            }
        });
    }

    /**
     * Send formatted results to the appropriate WebSocket client.
     */
    private Uni<Void> sendResultsToClient(FormattedResults formattedResults) {
        return Uni.createFrom().item(() -> {
            Session session = activeSessions.get(formattedResults.sessionId);
            
            if (session != null && session.isOpen()) {
                try {
                    session.getAsyncRemote().sendText(formattedResults.message);
                    LOGGER.info("Sent VEP results to WebSocket session: {}", formattedResults.sessionId);
                } catch (Exception e) {
                    LOGGER.error("Failed to send results to WebSocket session {}: {}", 
                        formattedResults.sessionId, e.getMessage());
                }
            } else {
                LOGGER.warn("WebSocket session {} not found or closed, cannot send results", 
                    formattedResults.sessionId);
            }
            
            return null;
        });
    }

    // Helper classes for data transfer
    private static class AnnotatedResults {
        final String sessionId;
        final String geneticSequence;
        final JsonNode vepAnnotations;
        final long annotationTimestamp;
        final String annotationSource;

        AnnotatedResults(String sessionId, String geneticSequence, JsonNode vepAnnotations, 
                        long annotationTimestamp, String annotationSource) {
            this.sessionId = sessionId;
            this.geneticSequence = geneticSequence;
            this.vepAnnotations = vepAnnotations;
            this.annotationTimestamp = annotationTimestamp;
            this.annotationSource = annotationSource;
        }
    }

    private static class FormattedResults {
        final String sessionId;
        final String message;

        FormattedResults(String sessionId, String message) {
            this.sessionId = sessionId;
            this.message = message;
        }
    }
}
