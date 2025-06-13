package com.redhat.healthcare.vep;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Represents regulatory feature consequence from VEP API
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public class RegulatoryFeatureConsequence {
    
    @JsonProperty("regulatory_feature_id")
    private String regulatoryFeatureId;
    
    @JsonProperty("biotype")
    private String biotype;
    
    @JsonProperty("consequence_terms")
    private String[] consequenceTerms;
    
    @JsonProperty("impact")
    private String impact;
    
    @JsonProperty("variant_allele")
    private String variantAllele;

    // Constructors
    public RegulatoryFeatureConsequence() {}

    // Getters and Setters
    public String getRegulatoryFeatureId() {
        return regulatoryFeatureId;
    }

    public void setRegulatoryFeatureId(String regulatoryFeatureId) {
        this.regulatoryFeatureId = regulatoryFeatureId;
    }

    public String getBiotype() {
        return biotype;
    }

    public void setBiotype(String biotype) {
        this.biotype = biotype;
    }

    public String[] getConsequenceTerms() {
        return consequenceTerms;
    }

    public void setConsequenceTerms(String[] consequenceTerms) {
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
}
