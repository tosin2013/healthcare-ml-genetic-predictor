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
}
