package com.redhat.healthcare.vep;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;
import java.util.ArrayList;

/**
 * Request object for VEP HGVS API calls
 *
 * API Documentation: https://rest.ensembl.org/documentation/info/vep_hgvs_post
 *
 * This class represents the EXACT JSON structure expected by the Ensembl VEP API
 * for HGVS notation-based variant annotation requests.
 *
 * WHY HGVS FORMAT:
 * - HGVS (Human Genome Variation Society) is the international standard
 * - Required by Ensembl VEP API (raw sequences cause 400 Bad Request)
 * - Enables precise variant description and clinical interpretation
 * - Supported by all major genomics tools (GATK, ClinVar, dbSNP)
 *
 * SUPPORTED HGVS FORMATS:
 * - Genomic: "17:g.43094692G>A" (chromosome:g.position>change)
 * - Transcript: "ENST00000366667:c.803C>T" (transcript:c.position>change)
 * - Protein: "ENSP00000355632:p.Arg268Cys" (protein:p.change)
 *
 * Example JSON Request:
 * {
 *   "hgvs_notations": [
 *     "ENST00000366667:c.803C>T",  // BRCA1 missense variant
 *     "9:g.22125504G>C",           // Genomic variant on chr9
 *     "17:g.43094692G>A"           // BRCA1 genomic variant
 *   ]
 * }
 *
 * LIMITS:
 * - Maximum 1000 HGVS notations per request
 * - Each notation must be valid HGVS format
 * - Invalid notations will cause API errors
 */
public class VepHgvsRequest {
    
    @JsonProperty("hgvs_notations")
    private List<String> hgvsNotations;
    
    public VepHgvsRequest() {
        this.hgvsNotations = new ArrayList<>();
    }
    
    public VepHgvsRequest(List<String> hgvsNotations) {
        this.hgvsNotations = hgvsNotations != null ? hgvsNotations : new ArrayList<>();
    }
    
    public List<String> getHgvsNotations() {
        return hgvsNotations;
    }
    
    public void setHgvsNotations(List<String> hgvsNotations) {
        this.hgvsNotations = hgvsNotations != null ? hgvsNotations : new ArrayList<>();
    }
    
    public void addHgvsNotation(String notation) {
        if (notation != null && !notation.trim().isEmpty()) {
            this.hgvsNotations.add(notation.trim());
        }
    }
    
    public boolean isEmpty() {
        return hgvsNotations == null || hgvsNotations.isEmpty();
    }
    
    public int size() {
        return hgvsNotations != null ? hgvsNotations.size() : 0;
    }
    
    @Override
    public String toString() {
        return "VepHgvsRequest{" +
                "hgvsNotations=" + hgvsNotations +
                '}';
    }
    
    /**
     * Creates a VEP request from a single HGVS notation
     */
    public static VepHgvsRequest fromSingle(String hgvsNotation) {
        VepHgvsRequest request = new VepHgvsRequest();
        request.addHgvsNotation(hgvsNotation);
        return request;
    }
    
    /**
     * Creates a VEP request from multiple HGVS notations
     */
    public static VepHgvsRequest fromMultiple(List<String> hgvsNotations) {
        return new VepHgvsRequest(hgvsNotations);
    }
}
