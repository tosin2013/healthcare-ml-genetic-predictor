package com.redhat.healthcare;

import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.common.http.TestHTTPResource;
import org.junit.jupiter.api.Test;

import jakarta.websocket.*;
import java.net.URI;
import java.util.concurrent.LinkedBlockingDeque;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.*;

@QuarkusTest
public class GeneticPredictorEndpointTest {

    @TestHTTPResource("/genetics")
    URI uri;

    @Test
    public void testWebSocketEndpoint() throws Exception {
        try (Session session = ContainerProvider.getWebSocketContainer().connectToServer(Client.class, uri)) {
            assertEquals("🧬 Connected to Healthcare ML Service with OpenShift AI Integration", Client.MESSAGES.poll(10, TimeUnit.SECONDS));
            session.getAsyncRemote().sendText("ATCGATCGATCG");
            String response = Client.MESSAGES.poll(10, TimeUnit.SECONDS);
            assertNotNull(response);
            assertTrue(response.contains("Message processed as CloudEvent"));
        }
    }

    @ClientEndpoint
    public static class Client {

        private static final LinkedBlockingDeque<String> MESSAGES = new LinkedBlockingDeque<>();

        @OnOpen
        public void open(Session session) {
            // Session opened
        }

        @OnMessage
        void message(String msg) {
            MESSAGES.add(msg);
        }

    }
}
