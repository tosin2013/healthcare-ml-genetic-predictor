package com.redhat.healthcare.vep;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Represents VEP service information
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public class VepServiceInfo {
    
    @JsonProperty("version")
    private String version;
    
    @JsonProperty("species")
    private String species;
    
    @JsonProperty("assembly")
    private String assembly;

    // Constructors
    public VepServiceInfo() {}

    // Getters and Setters
    public String getVersion() {
        return version;
    }

    public void setVersion(String version) {
        this.version = version;
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
}
