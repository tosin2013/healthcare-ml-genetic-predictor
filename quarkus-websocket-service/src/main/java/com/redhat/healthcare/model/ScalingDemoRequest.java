package com.redhat.healthcare.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

/**
 * Request model for triggering scaling demo via REST API.
 * Used to programmatically trigger node scaling demonstrations.
 */
public class ScalingDemoRequest {
    
    @JsonProperty("demoType")
    @NotBlank(message = "Demo type is required")
    @Pattern(regexp = "node-scaling|pod-scaling", message = "Demo type must be 'node-scaling' or 'pod-scaling'")
    private String demoType;
    
    @JsonProperty("sequenceCount")
    @Min(value = 1, message = "Sequence count must be at least 1")
    private int sequenceCount = 5;
    
    @JsonProperty("sequenceSize")
    @Pattern(regexp = "1kb|10kb|100kb|1mb", message = "Sequence size must be '1kb', '10kb', '100kb', or '1mb'")
    private String sequenceSize = "1mb";
    
    // Default constructor
    public ScalingDemoRequest() {}
    
    // Constructor
    public ScalingDemoRequest(String demoType, int sequenceCount, String sequenceSize) {
        this.demoType = demoType;
        this.sequenceCount = sequenceCount;
        this.sequenceSize = sequenceSize;
    }
    
    // Getters and setters
    public String getDemoType() {
        return demoType;
    }
    
    public void setDemoType(String demoType) {
        this.demoType = demoType;
    }
    
    public int getSequenceCount() {
        return sequenceCount;
    }
    
    public void setSequenceCount(int sequenceCount) {
        this.sequenceCount = sequenceCount;
    }
    
    public String getSequenceSize() {
        return sequenceSize;
    }
    
    public void setSequenceSize(String sequenceSize) {
        this.sequenceSize = sequenceSize;
    }
    
    // Utility methods
    public boolean isNodeScalingDemo() {
        return "node-scaling".equals(demoType);
    }
    
    public boolean isPodScalingDemo() {
        return "pod-scaling".equals(demoType);
    }
    
    public int getSequenceSizeInBytes() {
        switch (sequenceSize.toLowerCase()) {
            case "1kb": return 1024;
            case "10kb": return 10 * 1024;
            case "100kb": return 100 * 1024;
            case "1mb": return 1024 * 1024;
            default: return 1024 * 1024; // Default to 1MB
        }
    }
    
    @Override
    public String toString() {
        return String.format("ScalingDemoRequest{demoType='%s', sequenceCount=%d, sequenceSize='%s'}", 
                           demoType, sequenceCount, sequenceSize);
    }
}
