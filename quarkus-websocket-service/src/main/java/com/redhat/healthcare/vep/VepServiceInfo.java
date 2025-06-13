package com.redhat.healthcare.vep;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;
import java.util.Map;

/**
 * Data Transfer Object (DTO) for Ensembl VEP service information.
 * 
 * This class represents the service metadata returned by the VEP API
 * info/ping endpoint, including service version, available annotation
 * sources, database versions, and service capabilities.
 * 
 * Used for service health checks, configuration validation, and
 * ensuring compatibility with the VEP API version.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public class VepServiceInfo {

    /**
     * VEP service version
     */
    @JsonProperty("version")
    private String version;

    /**
     * API version
     */
    @JsonProperty("api_version")
    private String apiVersion;

    /**
     * Available species for annotation
     */
    @JsonProperty("species")
    private List<String> species;

    /**
     * Available assemblies
     */
    @JsonProperty("assemblies")
    private Map<String, Object> assemblies;

    /**
     * Service status
     */
    @JsonProperty("ping")
    private Integer ping;

    // Constructors
    public VepServiceInfo() {}

    // Getters and Setters
    public String getVersion() {
        return version;
    }

    public void setVersion(String version) {
        this.version = version;
    }

    public String getApiVersion() {
        return apiVersion;
    }

    public void setApiVersion(String apiVersion) {
        this.apiVersion = apiVersion;
    }

    public List<String> getSpecies() {
        return species;
    }

    public void setSpecies(List<String> species) {
        this.species = species;
    }

    public Map<String, Object> getAssemblies() {
        return assemblies;
    }

    public void setAssemblies(Map<String, Object> assemblies) {
        this.assemblies = assemblies;
    }

    public Integer getPing() {
        return ping;
    }

    public void setPing(Integer ping) {
        this.ping = ping;
    }

    @Override
    public String toString() {
        return "VepServiceInfo{" +
                "version='" + version + '\'' +
                ", apiVersion='" + apiVersion + '\'' +
                ", species=" + species +
                ", ping=" + ping +
                '}';
    }
}
