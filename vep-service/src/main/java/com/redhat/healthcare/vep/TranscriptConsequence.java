package com.redhat.healthcare.vep;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

/**
 * Represents transcript consequence from VEP API
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public class TranscriptConsequence {
    
    @JsonProperty("gene_id")
    private String geneId;
    
    @JsonProperty("gene_symbol")
    private String geneSymbol;
    
    @JsonProperty("transcript_id")
    private String transcriptId;
    
    @JsonProperty("consequence_terms")
    private List<String> consequenceTerms;
    
    @JsonProperty("impact")
    private String impact;
    
    @JsonProperty("variant_allele")
    private String variantAllele;
    
    @JsonProperty("biotype")
    private String biotype;

    // Constructors
    public TranscriptConsequence() {}

    // Getters and Setters
    public String getGeneId() {
        return geneId;
    }

    public void setGeneId(String geneId) {
        this.geneId = geneId;
    }

    public String getGeneSymbol() {
        return geneSymbol;
    }

    public void setGeneSymbol(String geneSymbol) {
        this.geneSymbol = geneSymbol;
    }

    public String getTranscriptId() {
        return transcriptId;
    }

    public void setTranscriptId(String transcriptId) {
        this.transcriptId = transcriptId;
    }

    public List<String> getConsequenceTerms() {
        return consequenceTerms;
    }

    public void setConsequenceTerms(List<String> consequenceTerms) {
        this.consequenceTerms = consequenceTerms;
    }

    public String getImpact() {
        return impact;
    }

    public void setImpact(String impact) {
        this.impact = impact;
    }

    public String getVariantAllele() {
        return variantAllele;
    }

    public void setVariantAllele(String variantAllele) {
        this.variantAllele = variantAllele;
    }

    public String getBiotype() {
        return biotype;
    }

    public void setBiotype(String biotype) {
        this.biotype = biotype;
    }
}
