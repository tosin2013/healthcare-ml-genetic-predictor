package com.redhat.healthcare;

import java.net.URI;
import java.util.UUID;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.websocket.OnClose;
import jakarta.websocket.OnError;
import jakarta.websocket.OnMessage;
import jakarta.websocket.OnOpen;
import jakarta.websocket.Session;
import jakarta.websocket.server.ServerEndpoint;

import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.fasterxml.jackson.databind.JsonNode;

import io.cloudevents.CloudEvent;
import io.cloudevents.core.builder.CloudEventBuilder;
import io.cloudevents.jackson.JsonFormat;
import io.cloudevents.core.format.EventFormat;
import io.cloudevents.core.provider.EventFormatProvider;

@ServerEndpoint("/genetics")
@ApplicationScoped
public class GeneticPredictorEndpoint {

    private static final Logger LOGGER = LoggerFactory.getLogger(GeneticPredictorEndpoint.class);

    @Inject
    @Channel("genetic-data-raw-out")
    Emitter<String> geneticDataEmitter;

    @Inject
    ObjectMapper objectMapper;

    @OnOpen
    public void onOpen(Session session) {
        LOGGER.info("WebSocket opened: {}", session.getId());
        // Generate a consistent session ID format that matches API calls
        String apiSessionId = "api-session-" + session.getId().substring(0, 8);
        // Store the mapping between WebSocket session and API session ID
        session.getUserProperties().put("apiSessionId", apiSessionId);
        // Register session for receiving VEP results using the API session ID
        GeneticResultsService.registerSession(apiSessionId, session);
        session.getAsyncRemote().sendText("🧬 Connected to Healthcare ML Service with OpenShift AI Integration");
        LOGGER.info("Registered WebSocket session {} with API session ID: {}", session.getId(), apiSessionId);
    }

    @OnClose
    public void onClose(Session session) {
        LOGGER.info("WebSocket closed: {}", session.getId());
        // Get the API session ID and unregister it
        String apiSessionId = (String) session.getUserProperties().get("apiSessionId");
        if (apiSessionId != null) {
            GeneticResultsService.unregisterSession(apiSessionId);
            LOGGER.info("Unregistered API session ID: {}", apiSessionId);
        } else {
            // Fallback to original session ID
            GeneticResultsService.unregisterSession(session.getId());
        }
    }

    @OnError
    public void onError(Session session, Throwable throwable) {
        LOGGER.error("WebSocket error for session {}: {}", session.getId(), throwable.getMessage());
    }

    @OnMessage
    public void onMessage(String message, Session session) {
        LOGGER.info("Received message from session {}: {}", session.getId(),
                   message.length() > 100 ? message.substring(0, 100) + "..." : message);
        try {
            // Parse message to determine if it's JSON (new format) or plain text (legacy)
            String geneticSequence;
            String mode = "normal";
            String resourceProfile = "normal";
            long timestamp = System.currentTimeMillis();
            String sessionIdFromMessage = null;

            if (message.startsWith("{")) {
                // New JSON format with mode information
                JsonNode messageNode = objectMapper.readTree(message);
                geneticSequence = messageNode.get("sequence").asText();
                mode = messageNode.has("mode") ? messageNode.get("mode").asText() : "normal";
                resourceProfile = messageNode.has("resourceProfile") ?
                                messageNode.get("resourceProfile").asText() : "normal";
                timestamp = messageNode.has("timestamp") ?
                           messageNode.get("timestamp").asLong() : System.currentTimeMillis();
                sessionIdFromMessage = messageNode.has("sessionId") ?
                                     messageNode.get("sessionId").asText() : null;

                LOGGER.info("Processing {} mode genetic sequence of length {} from session {}",
                           mode, geneticSequence.length(), session.getId());
            } else {
                // Legacy plain text format
                geneticSequence = message;
                LOGGER.info("Processing legacy format genetic sequence from session {}", session.getId());
            }

            // Create enhanced data payload with mode information
            // Use the API session ID for consistency with result delivery
            String apiSessionId = (String) session.getUserProperties().get("apiSessionId");
            ObjectNode data = objectMapper.createObjectNode();
            data.put("sessionId", apiSessionId != null ? apiSessionId : session.getId());
            data.put("userId", "demo-user-" + session.getId().substring(0, 8));
            data.put("genetic_sequence", geneticSequence);
            data.put("processing_mode", mode);
            data.put("resource_profile", resourceProfile);
            data.put("sequence_length", geneticSequence.length());
            data.put("timestamp", timestamp);
            data.put("client_session_id", sessionIdFromMessage);

            // Determine CloudEvent type based on mode
            String eventType = "big-data".equals(mode) ?
                             "com.redhat.healthcare.genetic.sequence.bigdata" :
                             "com.redhat.healthcare.genetic.sequence.raw";

            // Build the CloudEvent with enhanced metadata
            // Note: CloudEvent extension names must be lowercase and use only letters, numbers, and hyphens
            CloudEvent event = CloudEventBuilder.v1()
                    .withId(UUID.randomUUID().toString())
                    .withSource(URI.create("/healthcare-ml/frontend"))
                    .withType(eventType)
                    .withSubject("Genetic Sequence Analysis - " + mode.toUpperCase() + " Mode")
                    .withExtension("processingmode", mode)
                    .withExtension("resourceprofile", resourceProfile)
                    .withExtension("sequencelength", String.valueOf(geneticSequence.length()))
                    .withData("application/json", objectMapper.writeValueAsBytes(data))
                    .build();

            // Serialize CloudEvent to JSON and send to Kafka
            EventFormat format = EventFormatProvider.getInstance().resolveFormat(JsonFormat.CONTENT_TYPE);
            byte[] cloudEventBytes = format.serialize(event);
            String cloudEventJson = new String(cloudEventBytes);
            geneticDataEmitter.send(cloudEventJson);

            LOGGER.info("Sent {} CloudEvent to Kafka for {} mode processing", eventType, mode);

            // Send appropriate acknowledgment based on mode
            if ("big-data".equals(mode)) {
                session.getAsyncRemote().sendText(
                    String.format("🚀 Big data sequence (%d chars) queued for high-memory processing",
                                geneticSequence.length()));
            } else {
                session.getAsyncRemote().sendText(
                    String.format("🧬 Genetic sequence (%d chars) queued for VEP annotation and ML analysis",
                                geneticSequence.length()));
            }

        } catch (Exception e) {
            LOGGER.error("Failed to process message and send CloudEvent", e);
            session.getAsyncRemote().sendText("❌ Error processing message: " + e.getMessage());
        }
    }
}
