package com.redhat.healthcare.vep;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;
import java.util.ArrayList;

/**
 * Represents the response from Ensembl VEP API
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public class VepApiResponse {
    
    @JsonProperty("input")
    private String input;
    
    @JsonProperty("transcript_consequences")
    private List<TranscriptConsequence> transcriptConsequences = new ArrayList<>();
    
    @JsonProperty("regulatory_feature_consequences")
    private List<RegulatoryFeatureConsequence> regulatoryFeatureConsequences = new ArrayList<>();
    
    @JsonProperty("intergenic_consequences")
    private List<IntergenicConsequence> intergenicConsequences = new ArrayList<>();
    
    @JsonProperty("most_severe_consequence")
    private String mostSevereConsequence;
    
    @JsonProperty("variant_class")
    private String variantClass;
    
    @JsonProperty("assembly_name")
    private String assemblyName;
    
    @JsonProperty("seq_region_name")
    private String seqRegionName;
    
    @JsonProperty("start")
    private Integer start;
    
    @JsonProperty("end")
    private Integer end;
    
    @JsonProperty("strand")
    private Integer strand;
    
    @JsonProperty("allele_string")
    private String alleleString;

    // Constructors
    public VepApiResponse() {}

    // Helper methods
    public int getTotalConsequences() {
        return transcriptConsequences.size() + 
               regulatoryFeatureConsequences.size() + 
               intergenicConsequences.size();
    }

    public boolean hasConsequences() {
        return getTotalConsequences() > 0;
    }

    // Getters and Setters
    public String getInput() {
        return input;
    }

    public void setInput(String input) {
        this.input = input;
    }

    public List<TranscriptConsequence> getTranscriptConsequences() {
        return transcriptConsequences;
    }

    public void setTranscriptConsequences(List<TranscriptConsequence> transcriptConsequences) {
        this.transcriptConsequences = transcriptConsequences;
    }

    public List<RegulatoryFeatureConsequence> getRegulatoryFeatureConsequences() {
        return regulatoryFeatureConsequences;
    }

    public void setRegulatoryFeatureConsequences(List<RegulatoryFeatureConsequence> regulatoryFeatureConsequences) {
        this.regulatoryFeatureConsequences = regulatoryFeatureConsequences;
    }

    public List<IntergenicConsequence> getIntergenicConsequences() {
        return intergenicConsequences;
    }

    public void setIntergenicConsequences(List<IntergenicConsequence> intergenicConsequences) {
        this.intergenicConsequences = intergenicConsequences;
    }

    public String getMostSevereConsequence() {
        return mostSevereConsequence;
    }

    public void setMostSevereConsequence(String mostSevereConsequence) {
        this.mostSevereConsequence = mostSevereConsequence;
    }

    public String getVariantClass() {
        return variantClass;
    }

    public void setVariantClass(String variantClass) {
        this.variantClass = variantClass;
    }

    public String getAssemblyName() {
        return assemblyName;
    }

    public void setAssemblyName(String assemblyName) {
        this.assemblyName = assemblyName;
    }

    public String getSeqRegionName() {
        return seqRegionName;
    }

    public void setSeqRegionName(String seqRegionName) {
        this.seqRegionName = seqRegionName;
    }

    public Integer getStart() {
        return start;
    }

    public void setStart(Integer start) {
        this.start = start;
    }

    public Integer getEnd() {
        return end;
    }

    public void setEnd(Integer end) {
        this.end = end;
    }

    public Integer getStrand() {
        return strand;
    }

    public void setStrand(Integer strand) {
        this.strand = strand;
    }

    public String getAlleleString() {
        return alleleString;
    }

    public void setAlleleString(String alleleString) {
        this.alleleString = alleleString;
    }

    @Override
    public String toString() {
        return String.format("VepApiResponse{input='%s', consequences=%d, mostSevere='%s'}", 
                           input, getTotalConsequences(), mostSevereConsequence);
    }
}
