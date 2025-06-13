package com.redhat.healthcare.vep;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.HashMap;
import java.util.Map;

/**
 * Represents the final annotated genetic data output
 */
public class AnnotatedGeneticData {
    
    @JsonProperty("sequenceId")
    private String sequenceId;
    
    @JsonProperty("originalSequence")
    private String originalSequence;
    
    @JsonProperty("processingMode")
    private String processingMode;
    
    @JsonProperty("timestamp")
    private String timestamp;
    
    @JsonProperty("source")
    private String source;
    
    @JsonProperty("status")
    private String status;
    
    @JsonProperty("message")
    private String message;
    
    @JsonProperty("sequenceLength")
    private int sequenceLength;
    
    @JsonProperty("variantCount")
    private int variantCount;
    
    @JsonProperty("annotationResult")
    private VepAnnotationResult annotationResult;
    
    @JsonProperty("metadata")
    private Map<String, String> metadata = new HashMap<>();

    // Constructors
    public AnnotatedGeneticData() {}

    // Helper methods
    public void addMetadata(String key, String value) {
        metadata.put(key, value);
    }

    public String toJson() {
        try {
            ObjectMapper mapper = new ObjectMapper();
            return mapper.writeValueAsString(this);
        } catch (JsonProcessingException e) {
            // Fallback to simple JSON format
            return String.format("""
                {
                    "sequenceId": "%s",
                    "status": "%s",
                    "message": "%s",
                    "variantCount": %d,
                    "timestamp": "%s",
                    "source": "%s"
                }
                """, 
                sequenceId, status, message, variantCount, timestamp, source);
        }
    }

    // Getters and Setters
    public String getSequenceId() {
        return sequenceId;
    }

    public void setSequenceId(String sequenceId) {
        this.sequenceId = sequenceId;
    }

    public String getOriginalSequence() {
        return originalSequence;
    }

    public void setOriginalSequence(String originalSequence) {
        this.originalSequence = originalSequence;
    }

    public String getProcessingMode() {
        return processingMode;
    }

    public void setProcessingMode(String processingMode) {
        this.processingMode = processingMode;
    }

    public String getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(String timestamp) {
        this.timestamp = timestamp;
    }

    public String getSource() {
        return source;
    }

    public void setSource(String source) {
        this.source = source;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public int getSequenceLength() {
        return sequenceLength;
    }

    public void setSequenceLength(int sequenceLength) {
        this.sequenceLength = sequenceLength;
    }

    public int getVariantCount() {
        return variantCount;
    }

    public void setVariantCount(int variantCount) {
        this.variantCount = variantCount;
    }

    public VepAnnotationResult getAnnotationResult() {
        return annotationResult;
    }

    public void setAnnotationResult(VepAnnotationResult annotationResult) {
        this.annotationResult = annotationResult;
    }

    public Map<String, String> getMetadata() {
        return metadata;
    }

    public void setMetadata(Map<String, String> metadata) {
        this.metadata = metadata;
    }
}
