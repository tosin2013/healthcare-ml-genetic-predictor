package com.redhat.healthcare;

import com.redhat.healthcare.model.ApiResponse;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Resource Pressure Controller for Node Scale Mode
 * 
 * Generates CPU and memory intensive workloads to trigger resource pressure HPA
 * scaling, which forces cluster autoscaler to provision new compute-intensive nodes.
 * 
 * This replaces Kafka lag-based scaling with direct resource consumption for
 * clear architectural separation between Node Scale Mode and Kafka Lag Mode.
 */
@Path("/api/scaling")
@ApplicationScoped
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class ResourcePressureController {

    private static final Logger LOGGER = LoggerFactory.getLogger(ResourcePressureController.class);
    
    // Workload control
    private final AtomicBoolean workloadActive = new AtomicBoolean(false);
    private final AtomicLong workloadStartTime = new AtomicLong(0);
    private ExecutorService workloadExecutor;
    private final List<Future<?>> activeTasks = new ArrayList<>();
    
    // Memory pressure data structures
    private final List<byte[]> memoryConsumers = new ArrayList<>();
    private final Map<String, Object> complexDataStructures = new ConcurrentHashMap<>();
    
    /**
     * Trigger resource pressure workload for Node Scale Mode
     * 
     * @param durationMinutes Duration to run the workload (default: 8 minutes)
     * @return API response with workload status
     */
    @POST
    @Path("/trigger-resource-pressure")
    public Response triggerResourcePressure(@QueryParam("duration") @DefaultValue("8") int durationMinutes) {
        try {
            if (workloadActive.get()) {
                return Response.status(Response.Status.CONFLICT)
                    .entity(ApiResponse.error("Resource pressure workload is already running"))
                    .build();
            }
            
            LOGGER.info("🚀 Starting resource pressure workload for Node Scale Mode (duration: {} minutes)", durationMinutes);
            
            // Initialize workload
            workloadActive.set(true);
            workloadStartTime.set(System.currentTimeMillis());
            
            // Create thread pool for CPU-intensive tasks
            int cpuCores = Runtime.getRuntime().availableProcessors();
            workloadExecutor = Executors.newFixedThreadPool(cpuCores * 2); // Oversubscribe for pressure
            
            // Start CPU-intensive tasks
            startCpuIntensiveTasks(cpuCores, durationMinutes);
            
            // Start memory-intensive tasks
            startMemoryIntensiveTasks(durationMinutes);
            
            // Schedule workload termination
            scheduleWorkloadTermination(durationMinutes);
            
            Map<String, Object> responseData = new HashMap<>();
            responseData.put("workloadActive", true);
            responseData.put("durationMinutes", durationMinutes);
            responseData.put("cpuCores", cpuCores);
            responseData.put("threadsCreated", cpuCores * 2);
            responseData.put("startTime", new Date(workloadStartTime.get()));
            
            return Response.ok(ApiResponse.success(
                "⚡ Resource pressure workload started - Node Scale Mode activated", 
                responseData
            )).build();
            
        } catch (Exception e) {
            LOGGER.error("Failed to start resource pressure workload", e);
            workloadActive.set(false);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                .entity(ApiResponse.error("Failed to start workload: " + e.getMessage()))
                .build();
        }
    }
    
    /**
     * Get current resource pressure workload status
     */
    @GET
    @Path("/resource-pressure-status")
    public Response getResourcePressureStatus() {
        Map<String, Object> status = new HashMap<>();
        status.put("workloadActive", workloadActive.get());
        status.put("startTime", workloadStartTime.get() > 0 ? new Date(workloadStartTime.get()) : null);
        status.put("runningTimeMinutes", workloadStartTime.get() > 0 ? 
            (System.currentTimeMillis() - workloadStartTime.get()) / 60000.0 : 0);
        status.put("activeTasks", activeTasks.size());
        status.put("memoryConsumers", memoryConsumers.size());
        
        return Response.ok(ApiResponse.success("Resource pressure status", status)).build();
    }
    
    /**
     * Stop resource pressure workload
     */
    @POST
    @Path("/stop-resource-pressure")
    public Response stopResourcePressure() {
        try {
            LOGGER.info("🛑 Stopping resource pressure workload");
            stopWorkload();
            
            return Response.ok(ApiResponse.success("Resource pressure workload stopped", null)).build();
        } catch (Exception e) {
            LOGGER.error("Failed to stop resource pressure workload", e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                .entity(ApiResponse.error("Failed to stop workload: " + e.getMessage()))
                .build();
        }
    }
    
    /**
     * Start CPU-intensive tasks to consume CPU resources
     */
    private void startCpuIntensiveTasks(int cpuCores, int durationMinutes) {
        LOGGER.info("🔥 Starting {} CPU-intensive tasks", cpuCores * 2);
        
        for (int i = 0; i < cpuCores * 2; i++) {
            final int taskId = i;
            Future<?> task = workloadExecutor.submit(() -> {
                LOGGER.info("CPU task {} started", taskId);
                
                while (workloadActive.get()) {
                    // Genetic sequence analysis simulation
                    performGeneticAnalysisSimulation();
                    
                    // Prime number calculations
                    calculatePrimes(100000);
                    
                    // Matrix operations
                    performMatrixOperations(500);
                    
                    // Brief pause to allow monitoring
                    try {
                        Thread.sleep(100);
                    } catch (InterruptedException e) {
                        Thread.currentThread().interrupt();
                        break;
                    }
                }
                
                LOGGER.info("CPU task {} completed", taskId);
            });
            
            activeTasks.add(task);
        }
    }
    
    /**
     * Start memory-intensive tasks to consume memory resources
     */
    private void startMemoryIntensiveTasks(int durationMinutes) {
        LOGGER.info("💾 Starting memory-intensive tasks");
        
        Future<?> memoryTask = workloadExecutor.submit(() -> {
            while (workloadActive.get()) {
                try {
                    // Allocate large byte arrays (simulate genetic data processing)
                    byte[] largeArray = new byte[50 * 1024 * 1024]; // 50MB chunks
                    Arrays.fill(largeArray, (byte) 'A');
                    memoryConsumers.add(largeArray);
                    
                    // Create complex data structures
                    String key = "genetic_data_" + System.currentTimeMillis();
                    Map<String, Object> complexData = createComplexGeneticDataStructure();
                    complexDataStructures.put(key, complexData);
                    
                    // Limit memory growth to prevent OOM
                    if (memoryConsumers.size() > 20) { // Max ~1GB
                        memoryConsumers.remove(0);
                    }
                    
                    if (complexDataStructures.size() > 100) {
                        String oldestKey = complexDataStructures.keySet().iterator().next();
                        complexDataStructures.remove(oldestKey);
                    }
                    
                    Thread.sleep(5000); // Allocate every 5 seconds
                    
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    break;
                } catch (OutOfMemoryError e) {
                    LOGGER.warn("Memory pressure reached - clearing some allocations");
                    memoryConsumers.clear();
                    complexDataStructures.clear();
                }
            }
        });
        
        activeTasks.add(memoryTask);
    }
    
    /**
     * Simulate genetic analysis computation
     */
    private void performGeneticAnalysisSimulation() {
        // Simulate VEP annotation processing
        Random random = new Random();
        StringBuilder sequence = new StringBuilder();
        
        // Generate large genetic sequence
        for (int i = 0; i < 10000; i++) {
            sequence.append("ATCG".charAt(random.nextInt(4)));
        }
        
        // Simulate analysis operations
        String seq = sequence.toString();
        seq.hashCode(); // Force string processing
        seq.toUpperCase(); // String manipulation
        seq.replace("A", "T"); // Pattern matching
    }
    
    /**
     * Calculate prime numbers (CPU intensive)
     */
    private void calculatePrimes(int limit) {
        List<Integer> primes = new ArrayList<>();
        for (int i = 2; i < limit; i++) {
            boolean isPrime = true;
            for (int j = 2; j * j <= i; j++) {
                if (i % j == 0) {
                    isPrime = false;
                    break;
                }
            }
            if (isPrime) {
                primes.add(i);
            }
        }
    }
    
    /**
     * Perform matrix operations (CPU intensive)
     */
    private void performMatrixOperations(int size) {
        double[][] matrix1 = new double[size][size];
        double[][] matrix2 = new double[size][size];
        double[][] result = new double[size][size];
        
        // Initialize matrices
        Random random = new Random();
        for (int i = 0; i < size; i++) {
            for (int j = 0; j < size; j++) {
                matrix1[i][j] = random.nextDouble();
                matrix2[i][j] = random.nextDouble();
            }
        }
        
        // Matrix multiplication
        for (int i = 0; i < size; i++) {
            for (int j = 0; j < size; j++) {
                for (int k = 0; k < size; k++) {
                    result[i][j] += matrix1[i][k] * matrix2[k][j];
                }
            }
        }
    }
    
    /**
     * Create complex genetic data structure (memory intensive)
     */
    private Map<String, Object> createComplexGeneticDataStructure() {
        Map<String, Object> data = new HashMap<>();
        
        // Simulate genetic variant data
        List<Map<String, Object>> variants = new ArrayList<>();
        for (int i = 0; i < 1000; i++) {
            Map<String, Object> variant = new HashMap<>();
            variant.put("chromosome", "chr" + (i % 22 + 1));
            variant.put("position", i * 1000);
            variant.put("reference", "A");
            variant.put("alternate", "T");
            variant.put("quality", Math.random() * 100);
            variant.put("annotations", Arrays.asList("missense", "coding", "pathogenic"));
            variants.add(variant);
        }
        
        data.put("variants", variants);
        data.put("sampleId", "sample_" + System.currentTimeMillis());
        data.put("analysisDate", new Date());
        data.put("metadata", Map.of("version", "1.0", "pipeline", "node-scale-demo"));
        
        return data;
    }
    
    /**
     * Schedule workload termination
     */
    private void scheduleWorkloadTermination(int durationMinutes) {
        ScheduledExecutorService scheduler = Executors.newSingleThreadScheduledExecutor();
        scheduler.schedule(() -> {
            LOGGER.info("⏰ Workload duration reached - stopping resource pressure");
            stopWorkload();
            scheduler.shutdown();
        }, durationMinutes, TimeUnit.MINUTES);
    }
    
    /**
     * Stop all workload tasks and clean up resources
     */
    private void stopWorkload() {
        workloadActive.set(false);
        
        // Cancel all active tasks
        for (Future<?> task : activeTasks) {
            task.cancel(true);
        }
        activeTasks.clear();
        
        // Shutdown executor
        if (workloadExecutor != null) {
            workloadExecutor.shutdownNow();
        }
        
        // Clear memory consumers
        memoryConsumers.clear();
        complexDataStructures.clear();
        
        LOGGER.info("✅ Resource pressure workload stopped and cleaned up");
    }
}
