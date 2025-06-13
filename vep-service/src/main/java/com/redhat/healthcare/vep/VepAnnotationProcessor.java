package com.redhat.healthcare.vep;

import org.jboss.logging.Logger;

import jakarta.enterprise.context.ApplicationScoped;
import java.time.Instant;

/**
 * Processes and enriches VEP annotations
 */
@ApplicationScoped
public class VepAnnotationProcessor {

    private static final Logger LOG = Logger.getLogger(VepAnnotationProcessor.class);

    /**
     * Processes VEP annotation results and creates enriched output
     */
    public AnnotatedGeneticData processAnnotation(GeneticSequenceData sequenceData, 
                                                 VepAnnotationResult annotation) {
        
        LOG.debugf("Processing annotation for sequence: %s", sequenceData.getSequenceId());
        
        AnnotatedGeneticData result = new AnnotatedGeneticData();
        result.setSequenceId(sequenceData.getSequenceId());
        result.setOriginalSequence(sequenceData.getSequence());
        result.setProcessingMode(sequenceData.getProcessingMode());
        result.setTimestamp(Instant.now().toString());
        result.setSource("vep-annotation-service");
        
        // Set annotation results
        result.setAnnotationResult(annotation);
        
        // Calculate processing metrics
        result.setSequenceLength(sequenceData.getSequence() != null ? 
                                sequenceData.getSequence().length() : 0);
        result.setVariantCount(annotation.getVariantCount());
        
        // Determine processing status
        if (annotation.hasAnnotations()) {
            result.setStatus("annotated");
            result.setMessage("Successfully annotated with VEP");
        } else {
            result.setStatus("no_annotations");
            result.setMessage("No VEP annotations found for this sequence");
        }
        
        // Add processing metadata
        result.addMetadata("vep_service_version", "1.0.0");
        result.addMetadata("processing_timestamp", Instant.now().toString());
        result.addMetadata("sequence_type", determineSequenceType(sequenceData.getSequence()));
        
        LOG.infof("Processed annotation for %s: %d variants found", 
                 sequenceData.getSequenceId(), annotation.getVariantCount());
        
        return result;
    }

    /**
     * Determines the type of genetic sequence
     */
    private String determineSequenceType(String sequence) {
        if (sequence == null || sequence.isEmpty()) {
            return "unknown";
        }
        
        // Simple heuristic to determine sequence type
        String upperSeq = sequence.toUpperCase();
        long dnaCount = upperSeq.chars()
                               .filter(c -> c == 'A' || c == 'T' || c == 'G' || c == 'C')
                               .count();
        
        double dnaRatio = (double) dnaCount / sequence.length();
        
        if (dnaRatio > 0.8) {
            return "dna";
        } else if (upperSeq.contains("U")) {
            return "rna";
        } else {
            return "mixed";
        }
    }
}
