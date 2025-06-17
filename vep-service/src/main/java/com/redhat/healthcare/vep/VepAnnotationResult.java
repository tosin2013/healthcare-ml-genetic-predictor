package com.redhat.healthcare.vep;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

/**
 * Internal representation of VEP annotation results
 */
public class VepAnnotationResult {
    
    @JsonProperty("sequenceId")
    private String sequenceId;
    
    @JsonProperty("annotations")
    private List<VepApiResponse> annotations = new ArrayList<>();
    
    @JsonProperty("variantCount")
    private int variantCount;
    
    @JsonProperty("mostSevereConsequence")
    private String mostSevereConsequence;
    
    @JsonProperty("processingTime")
    private long processingTime;
    
    @JsonProperty("timestamp")
    private String timestamp;
    
    @JsonProperty("status")
    private String status = "success";

    // Constructors
    public VepAnnotationResult() {
        this.timestamp = Instant.now().toString();
    }

    public VepAnnotationResult(String sequenceId) {
        this();
        this.sequenceId = sequenceId;
    }

    // Static factory methods
    public static VepAnnotationResult fromApiResponse(VepApiResponse response, GeneticSequenceData sequenceData) {
        VepAnnotationResult result = new VepAnnotationResult(sequenceData.getSequenceId());

        if (response != null) {
            result.annotations.add(response);
            result.variantCount = response.getTotalConsequences();
            result.mostSevereConsequence = response.getMostSevereConsequence();
        }

        return result;
    }

    public static VepAnnotationResult fromApiResponseList(List<VepApiResponse> responses, GeneticSequenceData sequenceData) {
        VepAnnotationResult result = new VepAnnotationResult(sequenceData.getSequenceId());

        if (responses != null && !responses.isEmpty()) {
            result.annotations.addAll(responses);

            // Calculate total variant count and find most severe consequence
            int totalVariants = 0;
            String mostSevere = null;

            for (VepApiResponse response : responses) {
                if (response != null) {
                    totalVariants += response.getTotalConsequences();

                    // Update most severe consequence (prioritize first non-null)
                    if (mostSevere == null && response.getMostSevereConsequence() != null) {
                        mostSevere = response.getMostSevereConsequence();
                    }
                }
            }

            result.variantCount = totalVariants;
            result.mostSevereConsequence = mostSevere;
        }

        return result;
    }

    public static VepAnnotationResult empty(GeneticSequenceData sequenceData) {
        VepAnnotationResult result = new VepAnnotationResult(sequenceData.getSequenceId());
        result.status = "no_annotations";
        result.variantCount = 0;
        return result;
    }

    // Helper methods
    public boolean hasAnnotations() {
        return !annotations.isEmpty() && variantCount > 0;
    }

    public String toJson() throws JsonProcessingException {
        ObjectMapper mapper = new ObjectMapper();
        return mapper.writeValueAsString(this);
    }

    // Getters and Setters
    public String getSequenceId() {
        return sequenceId;
    }

    public void setSequenceId(String sequenceId) {
        this.sequenceId = sequenceId;
    }

    public List<VepApiResponse> getAnnotations() {
        return annotations;
    }

    public void setAnnotations(List<VepApiResponse> annotations) {
        this.annotations = annotations;
    }

    public int getVariantCount() {
        return variantCount;
    }

    public void setVariantCount(int variantCount) {
        this.variantCount = variantCount;
    }

    public String getMostSevereConsequence() {
        return mostSevereConsequence;
    }

    public void setMostSevereConsequence(String mostSevereConsequence) {
        this.mostSevereConsequence = mostSevereConsequence;
    }

    public long getProcessingTime() {
        return processingTime;
    }

    public void setProcessingTime(long processingTime) {
        this.processingTime = processingTime;
    }

    public String getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(String timestamp) {
        this.timestamp = timestamp;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }
}
