package com.redhat.healthcare.vep;

import io.cloudevents.CloudEvent;
import io.cloudevents.core.builder.CloudEventBuilder;
import io.cloudevents.core.format.EventFormat;
import io.cloudevents.core.provider.EventFormatProvider;
import io.cloudevents.jackson.JsonFormat;
import io.smallrye.mutiny.Uni;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.eclipse.microprofile.rest.client.inject.RestClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import java.net.URI;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

/**
 * VEP Annotation Service for processing genetic data with Ensembl VEP API.
 * 
 * This service consumes genetic data from the genetic-data-raw Kafka topic,
 * enriches it with comprehensive VEP annotations including variant consequence
 * predictions, pathogenicity scores, and clinical significance assessments,
 * then publishes the enriched data to the genetic-data-annotated topic.
 * 
 * The service maintains CloudEvents format throughout the processing pipeline
 * and integrates seamlessly with the existing reactive messaging architecture.
 */
@ApplicationScoped
public class VepAnnotationService {

    private static final Logger LOGGER = LoggerFactory.getLogger(VepAnnotationService.class);

    @Inject
    @RestClient
    VepRestClient vepClient;

    @Inject
    @Channel("genetic-data-annotated-out")
    Emitter<String> annotatedDataEmitter;

    @Inject
    ObjectMapper objectMapper;

    /**
     * Process genetic data from the raw topic and enrich with VEP annotations.
     * 
     * This method consumes CloudEvents containing genetic sequence data,
     * calls the Ensembl VEP API for comprehensive variant annotation,
     * and publishes enriched data maintaining the CloudEvent format.
     * 
     * @param cloudEventJson CloudEvent JSON containing genetic sequence data
     * @return Uni<Void> for reactive processing completion
     */
    @Incoming("genetic-data-raw-in")
    public Uni<Void> processGeneticData(String cloudEventJson) {
        LOGGER.debug("Processing genetic data CloudEvent: {}", cloudEventJson);
        
        return parseCloudEvent(cloudEventJson)
            .chain(this::extractGeneticSequence)
            .chain(this::convertToHgvsFormat)
            .chain(this::callVepApi)
            .chain(originalData -> enrichDataWithAnnotations(originalData.cloudEvent, originalData.annotations))
            .chain(this::publishEnrichedData)
            .onFailure().invoke(throwable -> 
                LOGGER.error("Failed to process genetic data: {}", throwable.getMessage(), throwable))
            .onFailure().recoverWithNull();
    }

    /**
     * Parse CloudEvent JSON string into CloudEvent object.
     */
    private Uni<CloudEvent> parseCloudEvent(String cloudEventJson) {
        return Uni.createFrom().item(() -> {
            try {
                EventFormat format = EventFormatProvider.getInstance().resolveFormat(JsonFormat.CONTENT_TYPE);
                return format.deserialize(cloudEventJson.getBytes());
            } catch (Exception e) {
                LOGGER.error("Failed to parse CloudEvent: {}", e.getMessage());
                throw new RuntimeException("Invalid CloudEvent format", e);
            }
        });
    }

    /**
     * Extract genetic sequence from CloudEvent data payload.
     */
    private Uni<GeneticData> extractGeneticSequence(CloudEvent cloudEvent) {
        return Uni.createFrom().item(() -> {
            try {
                byte[] data = cloudEvent.getData().toBytes();
                JsonNode dataNode = objectMapper.readTree(data);
                String geneticSequence = dataNode.get("genetic_sequence").asText();
                String sessionId = dataNode.get("sessionId").asText();
                String userId = dataNode.get("userId").asText();
                
                LOGGER.debug("Extracted genetic sequence: {} for session: {}", geneticSequence, sessionId);
                return new GeneticData(cloudEvent, geneticSequence, sessionId, userId);
            } catch (Exception e) {
                LOGGER.error("Failed to extract genetic sequence from CloudEvent: {}", e.getMessage());
                throw new RuntimeException("Invalid genetic data format", e);
            }
        });
    }

    /**
     * Convert genetic sequence to HGVS format for VEP API.
     * For demonstration, this creates mock HGVS variants.
     * In production, this would implement proper sequence-to-variant conversion.
     */
    private Uni<GeneticData> convertToHgvsFormat(GeneticData geneticData) {
        return Uni.createFrom().item(() -> {
            // Mock HGVS conversion for demonstration
            // In production, implement proper sequence analysis and variant calling
            List<String> hgvsVariants = Arrays.asList(
                "9:g.22125504G>C",  // Example HGVS notation
                "17:g.43094077C>T"  // Another example variant
            );
            
            LOGGER.debug("Converted sequence to HGVS variants: {}", hgvsVariants);
            geneticData.setHgvsVariants(hgvsVariants);
            return geneticData;
        });
    }

    /**
     * Call VEP API to annotate genetic variants.
     */
    private Uni<AnnotatedGeneticData> callVepApi(GeneticData geneticData) {
        LOGGER.debug("Calling VEP API for variants: {}", geneticData.getHgvsVariants());
        
        return vepClient.annotateVariantsHgvs(geneticData.getHgvsVariants())
            .map(annotations -> {
                LOGGER.debug("Received {} VEP annotations", annotations.size());
                return new AnnotatedGeneticData(geneticData.cloudEvent, geneticData, annotations);
            })
            .onFailure().invoke(throwable -> 
                LOGGER.error("VEP API call failed: {}", throwable.getMessage()))
            .onFailure().recoverWithItem(() -> {
                // Fallback: return data without annotations
                LOGGER.warn("Using fallback - no VEP annotations available");
                return new AnnotatedGeneticData(geneticData.cloudEvent, geneticData, List.of());
            });
    }

    /**
     * Enrich original data with VEP annotations and create new CloudEvent.
     */
    private Uni<String> enrichDataWithAnnotations(CloudEvent originalEvent, List<VepAnnotation> annotations) {
        return Uni.createFrom().item(() -> {
            try {
                // Parse original data
                byte[] originalData = originalEvent.getData().toBytes();
                JsonNode originalDataNode = objectMapper.readTree(originalData);
                
                // Create enriched data payload
                ObjectNode enrichedData = objectMapper.createObjectNode();
                enrichedData.setAll((ObjectNode) originalDataNode);
                
                // Add VEP annotations
                enrichedData.set("vep_annotations", objectMapper.valueToTree(annotations));
                enrichedData.put("annotation_timestamp", System.currentTimeMillis());
                enrichedData.put("annotation_source", "ensembl_vep");
                
                // Create new CloudEvent with enriched data
                CloudEvent enrichedEvent = CloudEventBuilder.v1()
                    .withId(UUID.randomUUID().toString())
                    .withSource(URI.create("/genetic-simulator/vep-service"))
                    .withType("com.healthcare.genetic.sequence.annotated")
                    .withSubject("VEP Annotated Genetic Sequence")
                    .withData("application/json", objectMapper.writeValueAsBytes(enrichedData))
                    .build();

                // Serialize to JSON
                EventFormat format = EventFormatProvider.getInstance().resolveFormat(JsonFormat.CONTENT_TYPE);
                byte[] cloudEventBytes = format.serialize(enrichedEvent);
                String cloudEventJson = new String(cloudEventBytes);
                
                LOGGER.debug("Created enriched CloudEvent with {} annotations", annotations.size());
                return cloudEventJson;
                
            } catch (Exception e) {
                LOGGER.error("Failed to enrich data with VEP annotations: {}", e.getMessage());
                throw new RuntimeException("Data enrichment failed", e);
            }
        });
    }

    /**
     * Publish enriched data to the annotated topic.
     */
    private Uni<Void> publishEnrichedData(String enrichedCloudEventJson) {
        return Uni.createFrom().item(() -> {
            annotatedDataEmitter.send(enrichedCloudEventJson);
            LOGGER.info("Published enriched genetic data to annotated topic");
            return null;
        });
    }

    // Helper classes for data transfer
    private static class GeneticData {
        final CloudEvent cloudEvent;
        final String geneticSequence;
        final String sessionId;
        final String userId;
        List<String> hgvsVariants;

        GeneticData(CloudEvent cloudEvent, String geneticSequence, String sessionId, String userId) {
            this.cloudEvent = cloudEvent;
            this.geneticSequence = geneticSequence;
            this.sessionId = sessionId;
            this.userId = userId;
        }

        void setHgvsVariants(List<String> hgvsVariants) {
            this.hgvsVariants = hgvsVariants;
        }

        List<String> getHgvsVariants() {
            return hgvsVariants;
        }
    }

    private static class AnnotatedGeneticData {
        final CloudEvent cloudEvent;
        final GeneticData geneticData;
        final List<VepAnnotation> annotations;

        AnnotatedGeneticData(CloudEvent cloudEvent, GeneticData geneticData, List<VepAnnotation> annotations) {
            this.cloudEvent = cloudEvent;
            this.geneticData = geneticData;
            this.annotations = annotations;
        }
    }
}
