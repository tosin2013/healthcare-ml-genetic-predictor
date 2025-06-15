package com.redhat.healthcare;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import jakarta.inject.Inject;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Test to verify that the test configuration is properly loaded
 * and in-memory messaging is configured correctly.
 */
@QuarkusTest
public class TestConfigurationTest {

    @Inject
    @ConfigProperty(name = "kafka.bootstrap.servers")
    String kafkaBootstrapServers;



    @Inject
    @ConfigProperty(name = "quarkus.application.name")
    String applicationName;

    @Test
    public void testKafkaConfiguration() {
        // Verify that Kafka configuration is set for test profile
        assertEquals("localhost:9092", kafkaBootstrapServers,
            "Kafka bootstrap servers should be configured for tests");
    }



    @Test
    public void testApplicationConfiguration() {
        // Verify that test application configuration is loaded
        assertEquals("genetic-risk-predictor-websocket-test", applicationName,
            "Application name should be set to test variant");
    }
}
