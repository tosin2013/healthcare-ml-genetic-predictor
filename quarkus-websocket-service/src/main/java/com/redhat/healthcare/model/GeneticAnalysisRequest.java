package com.redhat.healthcare.model;

import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Data model for genetic analysis requests from the frontend.
 * Supports both normal and big data processing modes.
 */
public class GeneticAnalysisRequest {
    
    @JsonProperty("mode")
    private String mode = "normal"; // "normal" or "bigdata"
    
    @JsonProperty("sequence")
    private String sequence;
    
    @JsonProperty("size")
    private int size;
    
    @JsonProperty("resourceProfile")
    private String resourceProfile = "normal"; // "normal" or "high-memory"
    
    @JsonProperty("timestamp")
    private long timestamp;
    
    @JsonProperty("sessionId")
    private String sessionId;
    
    // Default constructor
    public GeneticAnalysisRequest() {}
    
    // Constructor for legacy plain text messages
    public GeneticAnalysisRequest(String sequence) {
        this.sequence = sequence;
        this.size = sequence != null ? sequence.length() : 0;
        this.timestamp = System.currentTimeMillis();
        this.mode = "normal";
        this.resourceProfile = "normal";
    }
    
    // Getters and setters
    public String getMode() {
        return mode;
    }
    
    public void setMode(String mode) {
        this.mode = mode;
    }
    
    public String getSequence() {
        return sequence;
    }
    
    public void setSequence(String sequence) {
        this.sequence = sequence;
        this.size = sequence != null ? sequence.length() : 0;
    }
    
    public int getSize() {
        return size;
    }
    
    public void setSize(int size) {
        this.size = size;
    }
    
    public String getResourceProfile() {
        return resourceProfile;
    }
    
    public void setResourceProfile(String resourceProfile) {
        this.resourceProfile = resourceProfile;
    }
    
    public long getTimestamp() {
        return timestamp;
    }
    
    public void setTimestamp(long timestamp) {
        this.timestamp = timestamp;
    }
    
    public String getSessionId() {
        return sessionId;
    }
    
    public void setSessionId(String sessionId) {
        this.sessionId = sessionId;
    }
    
    // Utility methods
    public boolean isBigDataMode() {
        return "bigdata".equals(mode);
    }
    
    public boolean isHighMemoryProfile() {
        return "high-memory".equals(resourceProfile);
    }
    
    public boolean isLargeSequence() {
        return size > 10000; // Consider sequences > 10KB as large
    }
    
    @Override
    public String toString() {
        return String.format("GeneticAnalysisRequest{mode='%s', sequenceLength=%d, resourceProfile='%s', sessionId='%s'}", 
                           mode, size, resourceProfile, sessionId);
    }
}
