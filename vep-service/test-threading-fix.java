import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.URI;
import java.time.Duration;

/**
 * Simple test to validate VEP service threading fix locally
 * This tests the REST endpoint without Kafka dependencies
 */
public class TestThreadingFix {
    
    public static void main(String[] args) {
        System.out.println("🧪 Testing VEP Service Threading Fix Locally");
        System.out.println("============================================");
        
        try {
            // Create HTTP client
            HttpClient client = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(10))
                .build();
            
            // Test data - simple genetic sequence
            String testSequence = "ATCGATCGATCGATCGATCGATCGATCGATCGATCG";
            
            // Create test request to health endpoint first
            HttpRequest healthRequest = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:8080/q/health"))
                .timeout(Duration.ofSeconds(5))
                .GET()
                .build();
            
            System.out.println("📡 Testing health endpoint...");
            HttpResponse<String> healthResponse = client.send(healthRequest, 
                HttpResponse.BodyHandlers.ofString());
            
            System.out.println("✅ Health Status: " + healthResponse.statusCode());
            System.out.println("📄 Health Response: " + healthResponse.body());
            
            // Test the VEP annotation endpoint if available
            if (healthResponse.statusCode() == 200) {
                System.out.println("\n🔬 Testing VEP annotation endpoint...");
                
                String jsonPayload = String.format("""
                    {
                        "genetic_sequence": "%s",
                        "sessionId": "test-session-local",
                        "processing_mode": "local-test"
                    }
                    """, testSequence);
                
                HttpRequest vepRequest = HttpRequest.newBuilder()
                    .uri(URI.create("http://localhost:8080/annotate"))
                    .timeout(Duration.ofSeconds(30))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(jsonPayload))
                    .build();
                
                HttpResponse<String> vepResponse = client.send(vepRequest, 
                    HttpResponse.BodyHandlers.ofString());
                
                System.out.println("✅ VEP Status: " + vepResponse.statusCode());
                System.out.println("📄 VEP Response: " + vepResponse.body());
                
                if (vepResponse.statusCode() == 200) {
                    System.out.println("\n🎉 SUCCESS: VEP service is working locally!");
                    System.out.println("🔧 Threading fix appears to be working correctly.");
                } else {
                    System.out.println("\n⚠️  VEP endpoint returned non-200 status");
                }
            }
            
        } catch (Exception e) {
            System.err.println("❌ Error testing VEP service: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
