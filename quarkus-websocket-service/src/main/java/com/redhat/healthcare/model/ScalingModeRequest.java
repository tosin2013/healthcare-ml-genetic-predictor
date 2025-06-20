package com.redhat.healthcare.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

/**
 * Request model for setting scaling mode via REST API.
 * Used by the Testing API to programmatically control scaling modes.
 */
public class ScalingModeRequest {
    
    @JsonProperty("mode")
    @NotBlank(message = "Mode is required")
    @Pattern(regexp = "normal|bigdata|node-scale|kafka-lag", message = "Mode must be 'normal', 'bigdata', 'node-scale', or 'kafka-lag'")
    private String mode;
    
    @JsonProperty("description")
    private String description;
    
    // Default constructor
    public ScalingModeRequest() {}
    
    // Constructor
    public ScalingModeRequest(String mode, String description) {
        this.mode = mode;
        this.description = description;
    }
    
    // Getters and setters
    public String getMode() {
        return mode;
    }
    
    public void setMode(String mode) {
        this.mode = mode;
    }
    
    public String getDescription() {
        return description;
    }
    
    public void setDescription(String description) {
        this.description = description;
    }
    
    // Utility methods
    public boolean isNormalMode() {
        return "normal".equals(mode);
    }

    public boolean isBigDataMode() {
        return "bigdata".equals(mode);
    }

    public boolean isNodeScaleMode() {
        return "node-scale".equals(mode);
    }

    public boolean isKafkaLagMode() {
        return "kafka-lag".equals(mode);
    }
    
    @Override
    public String toString() {
        return String.format("ScalingModeRequest{mode='%s', description='%s'}", mode, description);
    }
}
