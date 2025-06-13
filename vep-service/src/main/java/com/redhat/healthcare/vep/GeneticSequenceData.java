package com.redhat.healthcare.vep;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.time.Instant;
import java.util.UUID;

/**
 * Represents genetic sequence data for VEP annotation
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public class GeneticSequenceData {
    
    @JsonProperty("sequenceId")
    private String sequenceId;
    
    @JsonProperty("sequence")
    private String sequence;
    
    @JsonProperty("species")
    private String species = "human";
    
    @JsonProperty("assembly")
    private String assembly = "GRCh38";
    
    @JsonProperty("timestamp")
    private String timestamp;
    
    @JsonProperty("source")
    private String source;
    
    @JsonProperty("processingMode")
    private String processingMode = "normal";

    // Constructors
    public GeneticSequenceData() {
        this.timestamp = Instant.now().toString();
    }

    public GeneticSequenceData(String sequence) {
        this();
        this.sequence = sequence;
        this.sequenceId = generateSequenceId();
    }

    // Static factory methods
    public static GeneticSequenceData fromJson(String json) throws JsonProcessingException {
        ObjectMapper mapper = new ObjectMapper();
        return mapper.readValue(json, GeneticSequenceData.class);
    }

    public static GeneticSequenceData fromPlainSequence(String sequence) {
        GeneticSequenceData data = new GeneticSequenceData(sequence.trim());
        data.setSource("plain-text");
        return data;
    }

    // Helper methods
    private String generateSequenceId() {
        return "seq-" + UUID.randomUUID().toString().substring(0, 8);
    }

    public String toJson() throws JsonProcessingException {
        ObjectMapper mapper = new ObjectMapper();
        return mapper.writeValueAsString(this);
    }

    public boolean isLargeSequence() {
        return sequence != null && sequence.length() > 10000;
    }

    public boolean isBigDataMode() {
        return "big-data".equals(processingMode) || isLargeSequence();
    }

    // Getters and Setters
    public String getSequenceId() {
        return sequenceId;
    }

    public void setSequenceId(String sequenceId) {
        this.sequenceId = sequenceId;
    }

    public String getSequence() {
        return sequence;
    }

    public void setSequence(String sequence) {
        this.sequence = sequence;
    }

    public String getSpecies() {
        return species;
    }

    public void setSpecies(String species) {
        this.species = species;
    }

    public String getAssembly() {
        return assembly;
    }

    public void setAssembly(String assembly) {
        this.assembly = assembly;
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

    public String getProcessingMode() {
        return processingMode;
    }

    public void setProcessingMode(String processingMode) {
        this.processingMode = processingMode;
    }

    @Override
    public String toString() {
        return String.format("GeneticSequenceData{id='%s', length=%d, mode='%s'}", 
                           sequenceId, 
                           sequence != null ? sequence.length() : 0, 
                           processingMode);
    }
}
