package com.redhat.healthcare.vep;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;
import java.util.Map;

/**
 * Data Transfer Object (DTO) for Ensembl VEP annotation response.
 * 
 * This class represents the comprehensive genetic variant annotation data
 * returned by the Ensembl Variant Effect Predictor (VEP) API, including:
 * - Variant consequence predictions using Sequence Ontology terms
 * - Pathogenicity scores (SIFT, PolyPhen-2)
 * - Clinical significance from ClinVar
 * - Population frequencies from gnomAD and 1000 Genomes
 * - Functional impact predictions and confidence scores
 * 
 * The class uses Jackson annotations for JSON serialization/deserialization
 * and ignores unknown properties for forward compatibility with VEP API updates.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public class VepAnnotation {

    /**
     * Input variant identifier (HGVS notation or VCF format)
     */
    @JsonProperty("input")
    private String input;

    /**
     * Genomic assembly version (e.g., "GRCh38")
     */
    @JsonProperty("assembly_name")
    private String assemblyName;

    /**
     * Chromosome or sequence region name
     */
    @JsonProperty("seq_region_name")
    private String seqRegionName;

    /**
     * Start position of the variant
     */
    @JsonProperty("start")
    private Long start;

    /**
     * End position of the variant
     */
    @JsonProperty("end")
    private Long end;

    /**
     * Reference allele
     */
    @JsonProperty("allele_string")
    private String alleleString;

    /**
     * Strand information (+1 or -1)
     */
    @JsonProperty("strand")
    private Integer strand;

    /**
     * Most severe consequence term from Sequence Ontology
     */
    @JsonProperty("most_severe_consequence")
    private String mostSevereConsequence;

    /**
     * List of transcript consequences with detailed annotations
     */
    @JsonProperty("transcript_consequences")
    private List<TranscriptConsequence> transcriptConsequences;

    /**
     * Colocated variants information
     */
    @JsonProperty("colocated_variants")
    private List<ColocatedVariant> colocatedVariants;

    // Constructors
    public VepAnnotation() {}

    // Getters and Setters
    public String getInput() { return input; }
    public void setInput(String input) { this.input = input; }

    public String getAssemblyName() { return assemblyName; }
    public void setAssemblyName(String assemblyName) { this.assemblyName = assemblyName; }

    public String getSeqRegionName() { return seqRegionName; }
    public void setSeqRegionName(String seqRegionName) { this.seqRegionName = seqRegionName; }

    public Long getStart() { return start; }
    public void setStart(Long start) { this.start = start; }

    public Long getEnd() { return end; }
    public void setEnd(Long end) { this.end = end; }

    public String getAlleleString() { return alleleString; }
    public void setAlleleString(String alleleString) { this.alleleString = alleleString; }

    public Integer getStrand() { return strand; }
    public void setStrand(Integer strand) { this.strand = strand; }

    public String getMostSevereConsequence() { return mostSevereConsequence; }
    public void setMostSevereConsequence(String mostSevereConsequence) { 
        this.mostSevereConsequence = mostSevereConsequence; 
    }

    public List<TranscriptConsequence> getTranscriptConsequences() { return transcriptConsequences; }
    public void setTranscriptConsequences(List<TranscriptConsequence> transcriptConsequences) { 
        this.transcriptConsequences = transcriptConsequences; 
    }

    public List<ColocatedVariant> getColocatedVariants() { return colocatedVariants; }
    public void setColocatedVariants(List<ColocatedVariant> colocatedVariants) { 
        this.colocatedVariants = colocatedVariants; 
    }

    @Override
    public String toString() {
        return "VepAnnotation{" +
                "input='" + input + '\'' +
                ", assemblyName='" + assemblyName + '\'' +
                ", seqRegionName='" + seqRegionName + '\'' +
                ", start=" + start +
                ", end=" + end +
                ", alleleString='" + alleleString + '\'' +
                ", mostSevereConsequence='" + mostSevereConsequence + '\'' +
                '}';
    }

    /**
     * Nested class representing transcript consequence information
     */
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class TranscriptConsequence {
        
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
        
        @JsonProperty("sift_prediction")
        private String siftPrediction;
        
        @JsonProperty("sift_score")
        private Double siftScore;
        
        @JsonProperty("polyphen_prediction")
        private String polyphenPrediction;
        
        @JsonProperty("polyphen_score")
        private Double polyphenScore;

        // Constructors, getters, and setters
        public TranscriptConsequence() {}

        public String getGeneId() { return geneId; }
        public void setGeneId(String geneId) { this.geneId = geneId; }

        public String getGeneSymbol() { return geneSymbol; }
        public void setGeneSymbol(String geneSymbol) { this.geneSymbol = geneSymbol; }

        public String getTranscriptId() { return transcriptId; }
        public void setTranscriptId(String transcriptId) { this.transcriptId = transcriptId; }

        public List<String> getConsequenceTerms() { return consequenceTerms; }
        public void setConsequenceTerms(List<String> consequenceTerms) { this.consequenceTerms = consequenceTerms; }

        public String getImpact() { return impact; }
        public void setImpact(String impact) { this.impact = impact; }

        public String getSiftPrediction() { return siftPrediction; }
        public void setSiftPrediction(String siftPrediction) { this.siftPrediction = siftPrediction; }

        public Double getSiftScore() { return siftScore; }
        public void setSiftScore(Double siftScore) { this.siftScore = siftScore; }

        public String getPolyphenPrediction() { return polyphenPrediction; }
        public void setPolyphenPrediction(String polyphenPrediction) { this.polyphenPrediction = polyphenPrediction; }

        public Double getPolyphenScore() { return polyphenScore; }
        public void setPolyphenScore(Double polyphenScore) { this.polyphenScore = polyphenScore; }
    }

    /**
     * Nested class representing colocated variant information
     */
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class ColocatedVariant {
        
        @JsonProperty("id")
        private String id;
        
        @JsonProperty("var_class")
        private String varClass;
        
        @JsonProperty("frequencies")
        private Map<String, Object> frequencies;
        
        @JsonProperty("clin_sig")
        private List<String> clinicalSignificance;

        // Constructors, getters, and setters
        public ColocatedVariant() {}

        public String getId() { return id; }
        public void setId(String id) { this.id = id; }

        public String getVarClass() { return varClass; }
        public void setVarClass(String varClass) { this.varClass = varClass; }

        public Map<String, Object> getFrequencies() { return frequencies; }
        public void setFrequencies(Map<String, Object> frequencies) { this.frequencies = frequencies; }

        public List<String> getClinicalSignificance() { return clinicalSignificance; }
        public void setClinicalSignificance(List<String> clinicalSignificance) { 
            this.clinicalSignificance = clinicalSignificance; 
        }
    }
}
