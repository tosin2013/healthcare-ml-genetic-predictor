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

    @Inject
    ProcessingProgressService progressService;

    // Registry to track active WebSocket sessions
    private static final Map<String, Session> activeSessions = new ConcurrentHashMap<>();

    /**
     * Register a WebSocket session for receiving results.
     * Called by the WebSocket endpoint when a client connects.
     */
    public static void registerSession(String sessionId, Session session) {
        activeSessions.put(sessionId, session);
        LOGGER.info("📝 SESSION REGISTRY: Registered WebSocket session: {}", sessionId);
        LOGGER.info("📊 SESSION REGISTRY: Total active sessions: {}", activeSessions.size());
    }

    /**
     * Unregister a WebSocket session.
     * Called by the WebSocket endpoint when a client disconnects.
     */
    public static void unregisterSession(String sessionId) {
        Session removed = activeSessions.remove(sessionId);
        if (removed != null) {
            LOGGER.info("📝 SESSION REGISTRY: Unregistered WebSocket session: {}", sessionId);
        } else {
            LOGGER.warn("⚠️  SESSION REGISTRY: Attempted to unregister non-existent session: {}", sessionId);
        }
        LOGGER.info("📊 SESSION REGISTRY: Total active sessions: {}", activeSessions.size());
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
        LOGGER.info("🔥 WEBSOCKET CONSUMER: Received message from genetic-data-annotated topic");
        LOGGER.info("📥 WEBSOCKET CONSUMER: Message size: {} chars", cloudEventJson.length());
        LOGGER.debug("📄 WEBSOCKET CONSUMER: Full message content: {}", cloudEventJson);

        return parseCloudEvent(cloudEventJson)
            .onItem().invoke(cloudEvent -> {
                LOGGER.info("✅ WEBSOCKET CONSUMER: Successfully parsed CloudEvent");
                LOGGER.info("📋 WEBSOCKET CONSUMER: CloudEvent type: {}", cloudEvent.getType());
                LOGGER.info("📋 WEBSOCKET CONSUMER: CloudEvent source: {}", cloudEvent.getSource());
            })
            .onFailure().invoke(throwable -> {
                LOGGER.error("❌ WEBSOCKET CONSUMER: Failed to parse CloudEvent: {}", throwable.getMessage());
                LOGGER.error("📄 WEBSOCKET CONSUMER: Problematic content: {}", cloudEventJson);
            })
            .chain(this::extractSessionAndResults)
            .onItem().invoke(results -> {
                LOGGER.info("✅ WEBSOCKET CONSUMER: Successfully extracted session and results");
                LOGGER.info("📋 WEBSOCKET CONSUMER: Session ID: {}", results.sessionId);
                LOGGER.info("📋 WEBSOCKET CONSUMER: Annotations count: {}", results.vepAnnotations.size());
            })
            .onFailure().invoke(throwable -> {
                LOGGER.error("❌ WEBSOCKET CONSUMER: Failed to extract session and results: {}", throwable.getMessage());
            })
            .chain(this::formatResultsForFrontend)
            .chain(this::sendResultsToClient)
            .onItem().invoke(() -> {
                LOGGER.info("🎉 WEBSOCKET CONSUMER: Successfully processed and sent results to client");
            })
            .onFailure().invoke(throwable -> {
                LOGGER.error("💥 WEBSOCKET CONSUMER: Failed to process annotated results: {}", throwable.getMessage(), throwable);
                LOGGER.error("🚨 WEBSOCKET CONSUMER: This message will be lost due to recoverWithNull()");
            })
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
            LOGGER.info("📤 WEBSOCKET DELIVERY: Attempting to send results to session: {}", formattedResults.sessionId);
            LOGGER.info("📊 WEBSOCKET DELIVERY: Current active sessions: {}", activeSessions.keySet());

            Session session = activeSessions.get(formattedResults.sessionId);

            // Enhanced session validation before delivery
            if (session != null && isSessionReadyForDelivery(session, formattedResults.sessionId)) {
                try {
                    LOGGER.info("✅ WEBSOCKET DELIVERY: Found active session for: {}", formattedResults.sessionId);

                    // Stop progress updates before sending final results
                    progressService.stopProcessingUpdates(formattedResults.sessionId);

                    // Send final results
                    session.getAsyncRemote().sendText(formattedResults.message);
                    LOGGER.info("🎉 WEBSOCKET DELIVERY: Successfully sent VEP results to session: {}", formattedResults.sessionId);
                    LOGGER.info("📄 WEBSOCKET DELIVERY: Message preview: {}",
                               formattedResults.message.substring(0, Math.min(100, formattedResults.message.length())) + "...");
                } catch (Exception e) {
                    LOGGER.error("💥 WEBSOCKET DELIVERY: Failed to send results to session {}: {}",
                        formattedResults.sessionId, e.getMessage());
                }
            } else if (session != null) {
                LOGGER.warn("🔌 WEBSOCKET DELIVERY: Session {} found but closed, cannot send results", formattedResults.sessionId);
                progressService.stopProcessingUpdates(formattedResults.sessionId);
            } else {
                LOGGER.warn("❌ WEBSOCKET DELIVERY: Session {} not found in registry, cannot send results", formattedResults.sessionId);
                LOGGER.warn("🕐 WEBSOCKET DELIVERY: Session may have timed out or disconnected before results arrived");
                progressService.stopProcessingUpdates(formattedResults.sessionId);
            }

            return null;
        });
    }

    /**
     * Enhanced session validation before result delivery.
     *
     * @param session The WebSocket session to validate
     * @param sessionId The session ID for logging
     * @return true if session is ready for result delivery
     */
    private boolean isSessionReadyForDelivery(Session session, String sessionId) {
        try {
            // Check if session is open
            if (!session.isOpen()) {
                LOGGER.warn("📋 SESSION VALIDATION: Session {} is closed, cannot deliver results", sessionId);
                return false;
            }

            // Verify session is not in closing state
            if (session.isSecure() && !session.isOpen()) {
                LOGGER.warn("📋 SESSION VALIDATION: Session {} is in closing state, cannot deliver results", sessionId);
                return false;
            }

            // Send validation ping to ensure connection is alive
            try {
                session.getAsyncRemote().sendPing(java.nio.ByteBuffer.wrap("validation".getBytes()));
                LOGGER.debug("📋 SESSION VALIDATION: Session {} passed validation checks", sessionId);
                return true;
            } catch (Exception pingException) {
                LOGGER.warn("📋 SESSION VALIDATION: Session {} failed ping validation: {}",
                           sessionId, pingException.getMessage());
                return false;
            }

        } catch (Exception e) {
            LOGGER.error("📋 SESSION VALIDATION: Error validating session {}: {}", sessionId, e.getMessage());
            return false;
        }
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
