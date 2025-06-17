package com.redhat.healthcare.vep;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;
import jakarta.inject.Inject;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for SequenceToHgvsConverter
 * 
 * Tests the conversion of raw genetic sequences to HGVS notations
 * to ensure proper format for Ensembl VEP API calls.
 */
@QuarkusTest
public class SequenceToHgvsConverterTest {

    @Inject
    SequenceToHgvsConverter converter;

    private String testSequence;
    private String sessionId;

    @BeforeEach
    void setUp() {
        testSequence = "ATCGATCGATCGATCGATCG"; // 20 base pairs
        sessionId = "test-session-" + System.currentTimeMillis();
    }

    @Test
    void testBasicSequenceConversion() {
        // Test basic sequence conversion
        List<String> hgvsNotations = converter.convertSequenceToHgvs(testSequence, sessionId);
        
        // Should generate at least one HGVS notation
        assertNotNull(hgvsNotations);
        assertFalse(hgvsNotations.isEmpty());
        
        System.out.println("Generated HGVS notations for test sequence:");
        hgvsNotations.forEach(notation -> {
            System.out.println("  - " + notation);
            
            // Validate HGVS format patterns
            assertTrue(
                notation.matches(".*:g\\.\\d+[ATCG]>[ATCG]") ||  // Genomic
                notation.matches(".*:c\\.\\d+[ATCG]>[ATCG]") ||  // Coding
                notation.matches(".*:g\\.\\d+_\\d+del") ||       // Deletion
                notation.matches(".*:g\\.\\d+_\\d+ins[ATCG]+"),  // Insertion
                "Invalid HGVS format: " + notation
            );
        });
    }

    @Test
    void testLargeSequenceConversion() {
        // Test with larger sequence (1KB)
        String largeSequence = "ATCG".repeat(250); // 1000 characters
        
        List<String> hgvsNotations = converter.convertSequenceToHgvs(largeSequence, sessionId);
        
        // Should generate more variants for larger sequence
        assertNotNull(hgvsNotations);
        assertFalse(hgvsNotations.isEmpty());
        
        // Should have reasonable variant density (~1 per 1000bp)
        assertTrue(hgvsNotations.size() >= 1, "Should have at least 1 variant for 1KB sequence");
        assertTrue(hgvsNotations.size() <= 20, "Should not have excessive variants");
        
        System.out.println("Generated " + hgvsNotations.size() + " HGVS notations for 1KB sequence");
    }

    @Test
    void testEmptySequenceHandling() {
        // Test empty sequence handling
        List<String> hgvsNotations = converter.convertSequenceToHgvs("", sessionId);
        
        // Should return fallback notations
        assertNotNull(hgvsNotations);
        assertFalse(hgvsNotations.isEmpty());
        
        System.out.println("Fallback HGVS notations for empty sequence:");
        hgvsNotations.forEach(notation -> System.out.println("  - " + notation));
    }

    @Test
    void testHgvsFormatValidation() {
        List<String> hgvsNotations = converter.convertSequenceToHgvs(testSequence, sessionId);
        
        for (String notation : hgvsNotations) {
            // Test common HGVS patterns
            boolean isValidFormat = 
                notation.matches("\\d+:g\\.\\d+[ATCG]>[ATCG]") ||           // Genomic SNV
                notation.matches("ENST\\d+:c\\.\\d+[ATCG]>[ATCG]") ||        // Transcript SNV
                notation.matches("\\d+:g\\.\\d+_\\d+del") ||                 // Genomic deletion
                notation.matches("\\d+:g\\.\\d+_\\d+ins[ATCG]+") ||          // Genomic insertion
                notation.matches("ENST\\d+:c\\.\\d+_\\d+del");               // Transcript deletion
            
            assertTrue(isValidFormat, "Invalid HGVS format: " + notation);
            
            // Should not contain raw sequence data
            assertFalse(notation.contains(testSequence), 
                       "HGVS notation should not contain raw sequence: " + notation);
        }
    }

    @Test
    void testVariantDensity() {
        // Test realistic variant density
        String mediumSequence = "ATCG".repeat(100); // 400 characters
        
        List<String> hgvsNotations = converter.convertSequenceToHgvs(mediumSequence, sessionId);
        
        // Should have reasonable variant count (not too many, not too few)
        int variantCount = hgvsNotations.size();
        assertTrue(variantCount >= 1, "Should have at least 1 variant");
        assertTrue(variantCount <= 10, "Should not have excessive variants for 400bp sequence");
        
        System.out.println("Variant density: " + variantCount + " variants for 400bp sequence");
        System.out.println("Density ratio: " + (400.0 / variantCount) + " bp per variant");
    }

    @Test
    void testSessionIdHandling() {
        // Test that session ID is properly handled
        String customSessionId = "custom-test-session-123";
        
        List<String> hgvsNotations = converter.convertSequenceToHgvs(testSequence, customSessionId);
        
        assertNotNull(hgvsNotations);
        assertFalse(hgvsNotations.isEmpty());
        
        // Session ID should not appear in HGVS notations
        for (String notation : hgvsNotations) {
            assertFalse(notation.contains(customSessionId), 
                       "HGVS notation should not contain session ID: " + notation);
        }
    }
}
