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
        // Test that the VEP service can handle different processing modes
        // This is a simplified test that validates the multi-topic architecture exists

        // Verify that the service has the required methods for multi-topic processing
        try {
            // Check that the service has methods for each topic
            java.lang.reflect.Method normalMethod = VepAnnotationService.class.getDeclaredMethod("processGeneticSequence", String.class);
            java.lang.reflect.Method bigDataMethod = VepAnnotationService.class.getDeclaredMethod("processBigDataGeneticSequence", String.class);
            java.lang.reflect.Method nodeScaleMethod = VepAnnotationService.class.getDeclaredMethod("processNodeScaleGeneticSequence", String.class);

            assertNotNull(normalMethod, "Normal mode processing method should exist");
            assertNotNull(bigDataMethod, "Big data mode processing method should exist");
            assertNotNull(nodeScaleMethod, "Node scale mode processing method should exist");

            // Verify the methods exist and are public
            assertTrue(java.lang.reflect.Modifier.isPublic(normalMethod.getModifiers()), "Normal method should be public");
            assertTrue(java.lang.reflect.Modifier.isPublic(bigDataMethod.getModifiers()), "Big data method should be public");
            assertTrue(java.lang.reflect.Modifier.isPublic(nodeScaleMethod.getModifiers()), "Node scale method should be public");

            System.out.println("✅ Multi-topic processing methods validated successfully");
            System.out.println("✅ Normal mode method: " + normalMethod.getName());
            System.out.println("✅ Big data mode method: " + bigDataMethod.getName());
            System.out.println("✅ Node scale mode method: " + nodeScaleMethod.getName());

        } catch (Exception e) {
            fail("Failed to validate multi-topic processing methods: " + e.getMessage());
        }
    }
}
