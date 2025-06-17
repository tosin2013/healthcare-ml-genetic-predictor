package com.redhat.healthcare.vep;

import jakarta.enterprise.context.ApplicationScoped;
import org.jboss.logging.Logger;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

/**
 * Converts raw genetic sequences to HGVS notation variants
 * 
 * This service simulates realistic genetic variant calling by:
 * 1. Analyzing the input sequence for potential variants
 * 2. Generating HGVS notations based on common variant patterns
 * 3. Creating clinically relevant variant examples
 * 
 * In a real implementation, this would use tools like:
 * - BWA/Bowtie2 for alignment
 * - GATK/FreeBayes for variant calling
 * - VCF to HGVS conversion tools
 */
@ApplicationScoped
public class SequenceToHgvsConverter {
    
    private static final Logger LOG = Logger.getLogger(SequenceToHgvsConverter.class);
    
    private final Random random = new Random();
    
    // Common chromosomes for variant generation
    private static final String[] CHROMOSOMES = {
        "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", 
        "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", 
        "21", "22", "X", "Y"
    };
    
    // Common transcript IDs for realistic HGVS notations
    private static final String[] TRANSCRIPT_IDS = {
        "ENST00000366667", "ENST00000380152", "ENST00000269305", 
        "ENST00000288602", "ENST00000311936", "ENST00000357654",
        "ENST00000269571", "ENST00000398958", "ENST00000346798"
    };
    
    /**
     * Converts a raw genetic sequence to HGVS notations
     * 
     * @param sequence Raw genetic sequence (ATCG...)
     * @param sessionId Session identifier for logging
     * @return List of HGVS notations representing variants
     */
    public List<String> convertSequenceToHgvs(String sequence, String sessionId) {
        LOG.infof("Converting sequence to HGVS notations for session %s (length: %d)", 
                 sessionId, sequence.length());
        
        List<String> hgvsNotations = new ArrayList<>();
        
        try {
            // Generate variants based on sequence characteristics
            int variantCount = calculateVariantCount(sequence);
            
            for (int i = 0; i < variantCount; i++) {
                String hgvsNotation = generateRealisticHgvsNotation(sequence, i);
                hgvsNotations.add(hgvsNotation);
            }
            
            LOG.infof("Generated %d HGVS notations for session %s", hgvsNotations.size(), sessionId);
            
        } catch (Exception e) {
            LOG.warnf(e, "Failed to convert sequence to HGVS for session %s, using fallback", sessionId);
            hgvsNotations.addAll(generateFallbackHgvsNotations());
        }
        
        return hgvsNotations;
    }
    
    /**
     * Calculates the number of variants to generate based on sequence length
     */
    private int calculateVariantCount(String sequence) {
        // Realistic variant density: ~1 variant per 1000 base pairs
        int baseVariants = Math.max(1, sequence.length() / 1000);
        
        // Add some randomness (±50%)
        int variation = (int) (baseVariants * 0.5);
        int minVariants = Math.max(1, baseVariants - variation);
        int maxVariants = baseVariants + variation;
        
        // Limit to reasonable range
        return Math.min(20, Math.max(1, random.nextInt(maxVariants - minVariants + 1) + minVariants));
    }
    
    /**
     * Generates a realistic HGVS notation based on sequence analysis
     */
    private String generateRealisticHgvsNotation(String sequence, int variantIndex) {
        // Choose variant type based on sequence characteristics
        double rand = random.nextDouble();
        
        if (rand < 0.6) {
            // 60% single nucleotide variants (SNVs)
            return generateSnvHgvs(sequence, variantIndex);
        } else if (rand < 0.8) {
            // 20% genomic variants
            return generateGenomicHgvs(variantIndex);
        } else {
            // 20% transcript-based variants
            return generateTranscriptHgvs(variantIndex);
        }
    }
    
    /**
     * Generates SNV (Single Nucleotide Variant) HGVS notation
     */
    private String generateSnvHgvs(String sequence, int variantIndex) {
        // Find a position in the sequence for the variant
        int position = Math.min(variantIndex * 100 + random.nextInt(100), sequence.length() - 1);
        char originalBase = sequence.charAt(position);
        char newBase = getAlternativeBase(originalBase);
        
        // Generate genomic coordinate (realistic chromosome positions)
        String chromosome = CHROMOSOMES[random.nextInt(CHROMOSOMES.length)];
        int genomicPosition = 10000000 + random.nextInt(90000000); // Realistic genomic positions
        
        return String.format("%s:g.%d%c>%c", chromosome, genomicPosition, originalBase, newBase);
    }
    
    /**
     * Generates genomic HGVS notation
     */
    private String generateGenomicHgvs(int variantIndex) {
        String chromosome = CHROMOSOMES[random.nextInt(CHROMOSOMES.length)];
        int position = 10000000 + random.nextInt(90000000);
        
        // Generate different types of genomic variants
        double variantType = random.nextDouble();
        
        if (variantType < 0.7) {
            // Point mutation
            char[] bases = {'A', 'T', 'C', 'G'};
            char from = bases[random.nextInt(4)];
            char to = getAlternativeBase(from);
            return String.format("%s:g.%d%c>%c", chromosome, position, from, to);
        } else if (variantType < 0.85) {
            // Deletion
            int delSize = 1 + random.nextInt(5);
            return String.format("%s:g.%d_%ddel", chromosome, position, position + delSize - 1);
        } else {
            // Insertion
            String insertSeq = generateRandomSequence(1 + random.nextInt(3));
            return String.format("%s:g.%d_%dins%s", chromosome, position, position + 1, insertSeq);
        }
    }
    
    /**
     * Generates transcript-based HGVS notation
     */
    private String generateTranscriptHgvs(int variantIndex) {
        String transcriptId = TRANSCRIPT_IDS[random.nextInt(TRANSCRIPT_IDS.length)];
        int position = 100 + random.nextInt(2000); // Realistic coding sequence positions
        
        // Generate coding sequence variants
        double variantType = random.nextDouble();
        
        if (variantType < 0.8) {
            // Missense variant
            char[] bases = {'A', 'T', 'C', 'G'};
            char from = bases[random.nextInt(4)];
            char to = getAlternativeBase(from);
            return String.format("%s:c.%d%c>%c", transcriptId, position, from, to);
        } else {
            // Small deletion in coding sequence
            int delSize = 1 + random.nextInt(3);
            return String.format("%s:c.%d_%ddel", transcriptId, position, position + delSize - 1);
        }
    }
    
    /**
     * Gets an alternative base for SNV generation
     */
    private char getAlternativeBase(char originalBase) {
        char[] alternatives;
        switch (Character.toUpperCase(originalBase)) {
            case 'A': alternatives = new char[]{'T', 'C', 'G'}; break;
            case 'T': alternatives = new char[]{'A', 'C', 'G'}; break;
            case 'C': alternatives = new char[]{'A', 'T', 'G'}; break;
            case 'G': alternatives = new char[]{'A', 'T', 'C'}; break;
            default: alternatives = new char[]{'A', 'T', 'C', 'G'}; break;
        }
        return alternatives[random.nextInt(alternatives.length)];
    }
    
    /**
     * Generates a random DNA sequence of specified length
     */
    private String generateRandomSequence(int length) {
        char[] bases = {'A', 'T', 'C', 'G'};
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < length; i++) {
            sb.append(bases[random.nextInt(4)]);
        }
        return sb.toString();
    }
    
    /**
     * Provides fallback HGVS notations when conversion fails
     */
    private List<String> generateFallbackHgvsNotations() {
        return List.of(
            "17:g.43094692G>A",  // BRCA1 variant
            "13:g.32339832T>C",  // BRCA2 variant
            "7:g.140753336A>T"   // BRAF variant
        );
    }
}
