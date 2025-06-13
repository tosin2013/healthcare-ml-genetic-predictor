package com.redhat.healthcare.vep;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Represents intergenic consequence from VEP API
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public class IntergenicConsequence {
    
    @JsonProperty("consequence_terms")
    private String[] consequenceTerms;
    
    @JsonProperty("impact")
    private String impact;
    
    @JsonProperty("variant_allele")
    private String variantAllele;

    // Constructors
    public IntergenicConsequence() {}

    // Getters and Setters
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
