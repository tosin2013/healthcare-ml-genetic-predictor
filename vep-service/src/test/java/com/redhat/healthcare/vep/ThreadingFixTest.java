package com.redhat.healthcare.vep;

import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.TestProfile;
import io.quarkus.test.junit.QuarkusTestProfile;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.Timeout;
import jakarta.inject.Inject;
import java.util.concurrent.TimeUnit;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Test to validate VEP service threading fix
 * This test runs without Kafka dependencies to isolate threading issues
 */
@QuarkusTest
@TestProfile(ThreadingFixTest.TestProfileWithoutKafka.class)
public class ThreadingFixTest {

    @Inject
    VepAnnotationService vepService;

    /**
     * Test profile that disables Kafka for isolated testing
     */
    public static class TestProfileWithoutKafka implements QuarkusTestProfile {
        @Override
        public Map<String, String> getConfigOverrides() {
            return Map.of(
                "quarkus.kafka.devservices.enabled", "false",
                "mp.messaging.incoming.genetic-data-raw.connector", "smallrye-in-memory",
                "mp.messaging.incoming.genetic-nodescale-raw.connector", "smallrye-in-memory",
                "mp.messaging.incoming.genetic-bigdata-raw.connector", "smallrye-in-memory",
                "mp.messaging.outgoing.genetic-data-annotated.connector", "smallrye-in-memory"
            );
        }
    }

    @Test
    @Timeout(value = 10, unit = TimeUnit.SECONDS)
    public void testThreadingFixBasic() {
        System.out.println("🧪 Testing VEP Service Threading Fix");
        
        // Test the simple threading fix method
        String testInput = "ATCGATCGATCGATCGATCG";
        
        // This should not throw BlockingNotAllowedException
        assertDoesNotThrow(() -> {
            String result = vepService.testThreadingFix(testInput).await().indefinitely();
            
            assertNotNull(result, "Result should not be null");
            assertTrue(result.contains("testResult"), "Result should contain test result");
            assertTrue(result.contains("success"), "Result should indicate success");
            
            System.out.println("✅ Threading fix test passed!");
            System.out.println("📄 Result: " + result);
        });
    }

    @Test
    @Timeout(value = 15, unit = TimeUnit.SECONDS)
    public void testVepAnnotationWithoutBlocking() {
        System.out.println("🔬 Testing VEP annotation without blocking exceptions");

        // Create test genetic sequence data
        GeneticSequenceData testData = GeneticSequenceData.fromPlainSequence("ATCGATCGATCGATCGATCGATCGATCGATCGATCG");
        testData.setSequenceId("test-session-123");
        testData.setProcessingMode("test-mode");

        // This should not throw BlockingNotAllowedException
        assertDoesNotThrow(() -> {
            VepAnnotationResult result = vepService.annotateWithVep(testData);

            assertNotNull(result, "Annotation result should not be null");
            assertTrue(result.getVariantCount() >= 0, "Variant count should be non-negative");

            System.out.println("✅ VEP annotation test passed!");
            System.out.println("📄 Variant count: " + result.getVariantCount());
        });
    }

    @Test
    public void testServiceInjection() {
        System.out.println("🔧 Testing service injection");
        
        assertNotNull(vepService, "VepAnnotationService should be injected");
        System.out.println("✅ Service injection test passed!");
    }
}
