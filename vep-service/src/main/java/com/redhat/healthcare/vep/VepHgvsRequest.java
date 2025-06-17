package com.redhat.healthcare.vep;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;
import java.util.ArrayList;

/**
 * Request object for VEP HGVS API calls
 * 
 * This class represents the JSON structure expected by the Ensembl VEP API
 * for HGVS notation-based variant annotation requests.
 * 
 * Example JSON:
 * {
 *   "hgvs_notations": ["ENST00000366667:c.803C>T", "9:g.22125504G>C"]
 * }
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
