package com.redhat.healthcare.vep;

import io.quarkus.test.junit.QuarkusTest;
import io.smallrye.mutiny.Uni;
import org.junit.jupiter.api.Test;
import jakarta.inject.Inject;

import static org.junit.jupiter.api.Assertions.*;

@QuarkusTest
public class VepAnnotationServiceTest {

    @Inject
    VepAnnotationService vepAnnotationService;

    @Test
    public void testThreadingFix() {
        // Test the threading fix without Kafka dependencies
        String testInput = "test-threading-fix";

        Uni<String> result = vepAnnotationService.testThreadingFix(testInput);

        // This should not throw any threading exceptions
        String response = result.await().indefinitely();

        assertNotNull(response);
        assertTrue(response.contains("testResult"));
        assertTrue(response.contains("success"));
        assertTrue(response.contains(testInput));

        System.out.println("Threading test result: " + response);
    }

    @Test
    public void testSessionIdExtraction() {
        // Test sessionId extraction from CloudEvent JSON
        String cloudEventWithSessionId = """
            {
                "specversion": "1.0",
                "type": "com.redhat.healthcare.genetic.sequence.raw",
                "source": "/genetic-simulator/websocket",
                "id": "test-123",
                "data": {
                    "sessionId": "websocket-session-12345",
                    "genetic_sequence": "ATCGATCG",
                    "processing_mode": "normal"
                }
            }
            """;

        // Use reflection to test the private method
        try {
            java.lang.reflect.Method method = VepAnnotationService.class.getDeclaredMethod("extractSessionIdSafely", String.class);
            method.setAccessible(true);
            String extractedSessionId = (String) method.invoke(vepAnnotationService, cloudEventWithSessionId);

            assertEquals("websocket-session-12345", extractedSessionId);
            System.out.println("Successfully extracted sessionId: " + extractedSessionId);
        } catch (Exception e) {
            fail("Failed to test sessionId extraction: " + e.getMessage());
        }
    }

    @Test
    public void testGeneticSequenceDataParsing() {
        // Test plain sequence parsing
        GeneticSequenceData data = GeneticSequenceData.fromPlainSequence("ATCGATCGATCG");
        
        assertNotNull(data);
        assertEquals("ATCGATCGATCG", data.getSequence());
        assertEquals("human", data.getSpecies());
        assertEquals("plain-text", data.getSource());
        assertNotNull(data.getSequenceId());
    }

    @Test
    public void testSequenceTypeDetection() {
        GeneticSequenceData dnaData = GeneticSequenceData.fromPlainSequence("ATCGATCGATCG");
        assertFalse(dnaData.isLargeSequence());
        assertEquals("normal", dnaData.getProcessingMode());
        
        // Test large sequence
        String largeSequence = "A".repeat(15000);
        GeneticSequenceData largeData = GeneticSequenceData.fromPlainSequence(largeSequence);
        assertTrue(largeData.isLargeSequence());
        assertTrue(largeData.isBigDataMode());
    }

    @Test
    public void testVepAnnotationResult() {
        GeneticSequenceData sequenceData = GeneticSequenceData.fromPlainSequence("ATCG");
        VepAnnotationResult result = VepAnnotationResult.empty(sequenceData);

        assertNotNull(result);
        assertEquals(sequenceData.getSequenceId(), result.getSequenceId());
        assertEquals(0, result.getVariantCount());
        assertEquals("no_annotations", result.getStatus());
        assertFalse(result.hasAnnotations());
    }

    @Test
    public void testMultiTopicProcessing() {
        // Test normal mode CloudEvent
        String normalModeCloudEvent = """
            {
                "specversion": "1.0",
                "type": "com.redhat.healthcare.genetic.sequence.raw",
                "source": "/healthcare-ml/frontend",
                "id": "test-normal-123",
                "data": {
                    "sessionId": "api-session-normal",
                    "genetic_sequence": "ATCGATCGATCG",
                    "processing_mode": "normal"
                }
            }
            """;

        // Test big data mode CloudEvent
        String bigDataModeCloudEvent = """
            {
                "specversion": "1.0",
                "type": "com.redhat.healthcare.genetic.sequence.bigdata",
                "source": "/healthcare-ml/frontend",
                "id": "test-bigdata-123",
                "data": {
                    "sessionId": "api-session-bigdata",
                    "genetic_sequence": "ATCGATCGATCGATCGATCGATCGATCGATCGATCG",
                    "processing_mode": "big-data"
                }
            }
            """;

        // Test node scale mode CloudEvent
        String nodeScaleModeCloudEvent = """
            {
                "specversion": "1.0",
                "type": "com.redhat.healthcare.genetic.sequence.nodescale",
                "source": "/healthcare-ml/frontend",
                "id": "test-nodescale-123",
                "data": {
                    "sessionId": "api-session-nodescale",
                    "genetic_sequence": "ATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCG",
                    "processing_mode": "node-scale"
                }
            }
            """;

        // Test processing each mode (these would normally be called by Kafka)
        // We'll test the internal processing method directly
        try {
            java.lang.reflect.Method method = VepAnnotationService.class.getDeclaredMethod("processGeneticSequenceInternal", String.class, String.class);
            method.setAccessible(true);

            // Test normal mode
            Uni<String> normalResult = (Uni<String>) method.invoke(vepAnnotationService, normalModeCloudEvent, "normal");
            String normalResponse = normalResult.await().indefinitely();
            assertNotNull(normalResponse);
            assertTrue(normalResponse.contains("api-session-normal"));
            assertTrue(normalResponse.contains("normal"));

            // Test big data mode
            Uni<String> bigDataResult = (Uni<String>) method.invoke(vepAnnotationService, bigDataModeCloudEvent, "big-data");
            String bigDataResponse = bigDataResult.await().indefinitely();
            assertNotNull(bigDataResponse);
            assertTrue(bigDataResponse.contains("api-session-bigdata"));
            assertTrue(bigDataResponse.contains("big-data"));

            // Test node scale mode
            Uni<String> nodeScaleResult = (Uni<String>) method.invoke(vepAnnotationService, nodeScaleModeCloudEvent, "node-scale");
            String nodeScaleResponse = nodeScaleResult.await().indefinitely();
            assertNotNull(nodeScaleResponse);
            assertTrue(nodeScaleResponse.contains("api-session-nodescale"));
            assertTrue(nodeScaleResponse.contains("node-scale"));

            System.out.println("Multi-topic processing test completed successfully");

        } catch (Exception e) {
            fail("Failed to test multi-topic processing: " + e.getMessage());
        }
    }
}
