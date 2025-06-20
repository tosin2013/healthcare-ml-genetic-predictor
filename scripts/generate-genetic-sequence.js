#!/usr/bin/env node

/**
 * Genetic Sequence Generator for Healthcare ML Scaling Demonstrations
 * 
 * Generates appropriate genetic sequences for different scaling modes:
 * - Normal Mode: Small sequences (20-100 chars) for standard pod scaling
 * - Big Data Mode: Large sequences (100KB-1MB) for memory-intensive scaling
 * - Node Scale Mode: Very large sequences (1MB+) for cluster autoscaler
 * - Kafka Lag Mode: Batch sequences (1KB each) for consumer lag demonstration
 */

const fs = require('fs');
const path = require('path');

// Genetic sequence building blocks
const DNA_BASES = ['A', 'T', 'C', 'G'];
const CODON_PATTERNS = [
    'ATG', 'TAA', 'TAG', 'TGA', // Start/Stop codons
    'GCA', 'GCC', 'GCG', 'GCT', // Alanine
    'TGC', 'TGT', // Cysteine
    'GAC', 'GAT', // Aspartic acid
    'GAA', 'GAG', // Glutamic acid
    'TTT', 'TTC', // Phenylalanine
    'GGA', 'GGC', 'GGG', 'GGT', // Glycine
    'CAC', 'CAT', // Histidine
    'ATA', 'ATC', 'ATT', // Isoleucine
    'AAA', 'AAG', // Lysine
    'CTA', 'CTC', 'CTG', 'CTT', 'TTA', 'TTG', // Leucine
    'ATG', // Methionine
    'AAC', 'AAT', // Asparagine
    'CCA', 'CCC', 'CCG', 'CCT', // Proline
    'CAA', 'CAG', // Glutamine
    'AGA', 'AGG', 'CGA', 'CGC', 'CGG', 'CGT', // Arginine
    'AGC', 'AGT', 'TCA', 'TCC', 'TCG', 'TCT', // Serine
    'ACA', 'ACC', 'ACG', 'ACT', // Threonine
    'GTA', 'GTC', 'GTG', 'GTT', // Valine
    'TGG', // Tryptophan
    'TAC', 'TAT'  // Tyrosine
];

/**
 * Generates a realistic genetic sequence with proper codon structure
 */
function generateGeneticSequence(targetLength, useRealisticPattern = true) {
    let sequence = '';
    
    if (useRealisticPattern && targetLength > 100) {
        // Start with start codon for longer sequences
        sequence = 'ATG';
        
        // Add realistic codon patterns
        while (sequence.length < targetLength - 6) {
            const randomCodon = CODON_PATTERNS[Math.floor(Math.random() * CODON_PATTERNS.length)];
            sequence += randomCodon;
        }
        
        // End with stop codon for longer sequences
        const stopCodons = ['TAA', 'TAG', 'TGA'];
        sequence += stopCodons[Math.floor(Math.random() * stopCodons.length)];
        
        // Trim to exact length
        sequence = sequence.substring(0, targetLength);
        
        // Ensure we end on a codon boundary for very long sequences
        if (targetLength > 1000) {
            const remainder = sequence.length % 3;
            if (remainder !== 0) {
                sequence = sequence.substring(0, sequence.length - remainder);
            }
        }
    } else {
        // Simple random generation for short sequences
        for (let i = 0; i < targetLength; i++) {
            sequence += DNA_BASES[Math.floor(Math.random() * DNA_BASES.length)];
        }
    }
    
    return sequence;
}

/**
 * Gets the appropriate sequence length for each scaling mode
 */
function getSequenceLengthForMode(mode) {
    switch (mode.toLowerCase()) {
        case 'normal':
            return 50; // Small sequence for standard processing
        case 'bigdata':
        case 'big-data':
            return 100 * 1024; // 100KB for memory-intensive processing
        case 'nodescale':
        case 'node-scale':
            return 1024 * 1024; // 1MB for cluster autoscaler triggering
        case 'kafkalag':
        case 'kafka-lag':
            return 1024; // 1KB for lag demonstration (multiple will be sent)
        default:
            return 50; // Default to normal mode
    }
}

/**
 * Main function to generate and optionally save genetic sequence
 */
function main() {
    const args = process.argv.slice(2);
    
    if (args.length === 0) {
        console.log(`
Usage: node generate-genetic-sequence.js <mode> [options]

Modes:
  normal      - Generate small sequence (50 chars) for standard pod scaling
  bigdata     - Generate large sequence (100KB) for memory-intensive scaling  
  node-scale  - Generate very large sequence (1MB) for cluster autoscaler
  kafka-lag   - Generate medium sequence (1KB) for consumer lag demonstration

Options:
  --length <n>     - Override default length for mode
  --save <file>    - Save sequence to file instead of stdout
  --realistic      - Use realistic codon patterns (default for >100 chars)
  --simple         - Use simple random generation
  --help           - Show this help message

Examples:
  node generate-genetic-sequence.js normal
  node generate-genetic-sequence.js bigdata --save bigdata-sequence.txt
  node generate-genetic-sequence.js kafka-lag --length 2048
  node generate-genetic-sequence.js node-scale --simple
        `);
        process.exit(0);
    }

    const mode = args[0];
    let length = getSequenceLengthForMode(mode);
    let saveFile = null;
    let useRealistic = length > 100; // Default to realistic for longer sequences
    
    // Parse options
    for (let i = 1; i < args.length; i++) {
        switch (args[i]) {
            case '--length':
                length = parseInt(args[++i]);
                if (isNaN(length) || length <= 0) {
                    console.error('Error: Invalid length specified');
                    process.exit(1);
                }
                break;
            case '--save':
                saveFile = args[++i];
                break;
            case '--realistic':
                useRealistic = true;
                break;
            case '--simple':
                useRealistic = false;
                break;
            case '--help':
                main(); // Show help and exit
                break;
            default:
                console.error(`Error: Unknown option ${args[i]}`);
                process.exit(1);
        }
    }

    // Generate the sequence
    console.error(`Generating ${mode} mode sequence (${length} chars)...`);
    const sequence = generateGeneticSequence(length, useRealistic);
    
    // Validate sequence
    if (sequence.length !== length) {
        console.error(`Warning: Generated sequence length (${sequence.length}) differs from requested (${length})`);
    }
    
    // Output or save
    if (saveFile) {
        fs.writeFileSync(saveFile, sequence);
        console.error(`Sequence saved to ${saveFile}`);
        console.error(`File size: ${fs.statSync(saveFile).size} bytes`);
    } else {
        console.log(sequence);
    }
    
    // Show sequence info
    console.error(`Generated sequence info:`);
    console.error(`  Mode: ${mode}`);
    console.error(`  Length: ${sequence.length} characters`);
    console.error(`  Size: ${Buffer.byteLength(sequence, 'utf8')} bytes`);
    console.error(`  Pattern: ${useRealistic ? 'Realistic codons' : 'Random bases'}`);
    console.error(`  A: ${(sequence.match(/A/g) || []).length}, T: ${(sequence.match(/T/g) || []).length}, C: ${(sequence.match(/C/g) || []).length}, G: ${(sequence.match(/G/g) || []).length}`);
}

// Run if called directly
if (require.main === module) {
    main();
}

module.exports = {
    generateGeneticSequence,
    getSequenceLengthForMode,
    DNA_BASES,
    CODON_PATTERNS
};
