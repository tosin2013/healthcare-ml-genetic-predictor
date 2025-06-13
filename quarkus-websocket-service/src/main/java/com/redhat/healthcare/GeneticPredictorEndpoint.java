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
        session.getAsyncRemote().sendText("Connection opened");
    }

    @OnClose
    public void onClose(Session session) {
        LOGGER.info("WebSocket closed: {}", session.getId());
    }

    @OnError
    public void onError(Session session, Throwable throwable) {
        LOGGER.error("WebSocket error for session {}: {}", session.getId(), throwable.getMessage());
    }

    @OnMessage
    public void onMessage(String message, Session session) {
        LOGGER.info("Received message: {} from session: {}", message, session.getId());
        try {
            // Create a JSON object for the data payload
            ObjectNode data = objectMapper.createObjectNode();
            data.put("sessionId", session.getId());
            data.put("userId", "user-123"); // Example user ID
            data.put("genetic_sequence", message);

            // Build the CloudEvent
            CloudEvent event = CloudEventBuilder.v1()
                    .withId(UUID.randomUUID().toString())
                    .withSource(URI.create("/genetic-simulator/frontend"))
                    .withType("com.redhat.healthcare.genetic.sequence.raw")
                    .withSubject("Genetic Sequence")
                    .withData("application/json", objectMapper.writeValueAsBytes(data))
                    .build();

            // Serialize CloudEvent to JSON and send to Kafka
            EventFormat format = EventFormatProvider.getInstance().resolveFormat(JsonFormat.CONTENT_TYPE);
            byte[] cloudEventBytes = format.serialize(event);
            String cloudEventJson = new String(cloudEventBytes);
            geneticDataEmitter.send(cloudEventJson);

            LOGGER.info("Sent CloudEvent to Kafka: {}", cloudEventJson);
            session.getAsyncRemote().sendText("Message processed as CloudEvent");

        } catch (Exception e) {
            LOGGER.error("Failed to process message and send CloudEvent", e);
            session.getAsyncRemote().sendText("Error processing message: " + e.getMessage());
        }
    }
}
