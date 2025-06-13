package com.redhat.healthcare.vep;

import io.quarkus.cache.CacheResult;
import io.smallrye.reactive.messaging.annotations.Blocking;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.eclipse.microprofile.reactive.messaging.Outgoing;
import org.eclipse.microprofile.rest.client.inject.RestClient;
import org.jboss.logging.Logger;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import java.time.Instant;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionStage;

/**
 * VEP (Variant Effect Predictor) Annotation Service
 * 
 * This service processes genetic sequences from Kafka, annotates them using
 * the Ensembl VEP API, and publishes the annotated results back to Kafka.
 * 
 * Features:
 * - Kafka-based message processing
 * - VEP API integration with caching
 * - Error handling and retry logic
 * - Health checks and metrics
 * - Independent scaling with KEDA
 */
@ApplicationScoped
public class VepAnnotationService {

    private static final Logger LOG = Logger.getLogger(VepAnnotationService.class);

    @Inject
    @RestClient
    VepApiClient vepApiClient;

    @Inject
    VepAnnotationProcessor annotationProcessor;

    /**
     * Processes genetic sequences from the raw data topic
     * 
     * @param geneticData Raw genetic sequence data from Kafka
     * @return Annotated genetic data for downstream processing
     */
    @Incoming("genetic-data-raw")
    @Outgoing("genetic-data-annotated")
    @Blocking
    public CompletionStage<String> processGeneticSequence(String geneticData) {
        LOG.infof("Processing genetic sequence: %s", 
                  geneticData.length() > 50 ? geneticData.substring(0, 50) + "..." : geneticData);

        return CompletableFuture.supplyAsync(() -> {
            try {
                // Parse the incoming genetic data
                GeneticSequenceData sequenceData = parseGeneticData(geneticData);
                
                // Annotate with VEP
                VepAnnotationResult annotation = annotateWithVep(sequenceData);
                
                // Process and enrich the annotation
                AnnotatedGeneticData annotatedData = annotationProcessor.processAnnotation(
                    sequenceData, annotation);
                
                // Convert to JSON for downstream processing
                String result = annotatedData.toJson();
                
                LOG.infof("Successfully annotated sequence with %d variants", 
                         annotation.getVariantCount());
                
                return result;
                
            } catch (Exception e) {
                LOG.errorf(e, "Error processing genetic sequence: %s", e.getMessage());
                
                // Return error result for downstream handling
                return createErrorResult(geneticData, e.getMessage());
            }
        });
    }

    /**
     * Annotates genetic sequence using VEP API with caching
     */
    @CacheResult(cacheName = "vep-annotations")
    public VepAnnotationResult annotateWithVep(GeneticSequenceData sequenceData) {
        try {
            LOG.debugf("Calling VEP API for sequence: %s", sequenceData.getSequenceId());
            
            // Call VEP API
            VepApiResponse response = vepApiClient.annotateSequence(
                sequenceData.getSequence(),
                sequenceData.getSpecies(),
                sequenceData.getAssembly()
            );
            
            // Convert API response to internal format
            return VepAnnotationResult.fromApiResponse(response, sequenceData);
            
        } catch (Exception e) {
            LOG.warnf(e, "VEP API call failed for sequence %s: %s", 
                     sequenceData.getSequenceId(), e.getMessage());
            
            // Return empty annotation result for graceful degradation
            return VepAnnotationResult.empty(sequenceData);
        }
    }

    /**
     * Parses incoming genetic data from JSON or plain text
     */
    private GeneticSequenceData parseGeneticData(String geneticData) {
        try {
            // Try to parse as JSON first
            if (geneticData.trim().startsWith("{")) {
                return GeneticSequenceData.fromJson(geneticData);
            } else {
                // Treat as plain sequence
                return GeneticSequenceData.fromPlainSequence(geneticData);
            }
        } catch (Exception e) {
            LOG.warnf("Failed to parse genetic data, using fallback: %s", e.getMessage());
            return GeneticSequenceData.fromPlainSequence(geneticData);
        }
    }

    /**
     * Creates error result for failed processing
     */
    private String createErrorResult(String originalData, String errorMessage) {
        return String.format("""
            {
                "sequenceId": "error-%d",
                "originalData": "%s",
                "status": "error",
                "errorMessage": "%s",
                "timestamp": "%s",
                "source": "vep-annotation-service",
                "annotations": []
            }
            """, 
            System.currentTimeMillis(),
            originalData.length() > 100 ? originalData.substring(0, 100) + "..." : originalData,
            errorMessage.replace("\"", "\\\""),
            Instant.now().toString()
        );
    }
}
