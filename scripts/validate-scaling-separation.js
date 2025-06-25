#!/usr/bin/env node

/**
 * Scaling Mode Separation of Concerns Validator
 * 
 * This script validates that the separation of concerns between UI buttons,
 * backend modes, and Kafka topics is maintained across all code changes.
 * 
 * It prevents developers from accidentally breaking the critical mapping between:
 * - UI button IDs and their corresponding backend modes
 * - Backend modes and their Kafka topics
 * - Kafka topics and their emitter channels
 * - Event types and their mode mappings
 * 
 * Usage:
 *   node scripts/validate-scaling-separation.js [--config path/to/config.yaml] [--fix]
 * 
 * Exit codes:
 *   0 - All validations passed
 *   1 - Validation failures found
 *   2 - Configuration or file errors
 */

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

// Configuration
const CONFIG_PATH = process.argv.includes('--config') 
    ? process.argv[process.argv.indexOf('--config') + 1]
    : 'quarkus-websocket-service/src/main/resources/scaling-mode-separation.yaml';
const FIX_MODE = process.argv.includes('--fix');
const REPO_ROOT = process.cwd();

// Colors for output
const colors = {
    reset: '\033[0m',
    red: '\033[0;31m',
    green: '\033[0;32m',
    yellow: '\033[1;33m',
    blue: '\033[0;34m',
    cyan: '\033[0;36m'
};

function colorLog(color, message) {
    console.log(`${colors[color]}${message}${colors.reset}`);
}

function logSuccess(message) { colorLog('green', `✅ ${message}`); }
function logError(message) { colorLog('red', `❌ ${message}`); }
function logWarning(message) { colorLog('yellow', `⚠️  ${message}`); }
function logInfo(message) { colorLog('cyan', `ℹ️  ${message}`); }
function logHeader(message) { 
    colorLog('blue', `\n${'='.repeat(80)}`);
    colorLog('blue', message);
    colorLog('blue', '='.repeat(80));
}

// Load configuration
function loadConfig() {
    try {
        const configPath = path.join(REPO_ROOT, CONFIG_PATH);
        if (!fs.existsSync(configPath)) {
            logError(`Configuration file not found: ${configPath}`);
            process.exit(2);
        }
        
        const configContent = fs.readFileSync(configPath, 'utf8');
        const config = yaml.load(configContent);
        logSuccess(`Loaded configuration from ${CONFIG_PATH}`);
        return config;
    } catch (error) {
        logError(`Failed to load configuration: ${error.message}`);
        process.exit(2);
    }
}

// Validation results tracking
let validationResults = [];
let totalValidations = 0;
let passedValidations = 0;

function addValidationResult(name, passed, message, details = null) {
    totalValidations++;
    if (passed) passedValidations++;
    
    validationResults.push({
        name,
        passed,
        message,
        details
    });
    
    if (passed) {
        logSuccess(`${name}: ${message}`);
    } else {
        logError(`${name}: ${message}`);
        if (details) {
            console.log(`   Details: ${details}`);
        }
    }
}

// Validation 1: UI Button Consistency
function validateUIButtons(config) {
    logHeader('Validating UI Button Consistency');
    
    const htmlFile = path.join(REPO_ROOT, 'quarkus-websocket-service/src/main/resources/META-INF/resources/index.html');
    
    if (!fs.existsSync(htmlFile)) {
        addValidationResult('UI Buttons', false, 'HTML file not found', htmlFile);
        return;
    }
    
    const htmlContent = fs.readFileSync(htmlFile, 'utf8');
    let allButtonsValid = true;
    let missingButtons = [];
    let incorrectTexts = [];
    
    for (const [modeName, modeConfig] of Object.entries(config.scaling_modes)) {
        // Check button ID exists
        const buttonIdPattern = new RegExp(`id="${modeConfig.ui_button_id}"`);
        if (!buttonIdPattern.test(htmlContent)) {
            allButtonsValid = false;
            missingButtons.push(`${modeConfig.ui_button_id} (${modeName} mode)`);
            continue;
        }
        
        // Check button text (more flexible matching)
        const buttonTextPattern = new RegExp(modeConfig.ui_button_text.replace(/[()]/g, '\\$&'));
        if (!buttonTextPattern.test(htmlContent)) {
            allButtonsValid = false;
            incorrectTexts.push(`${modeConfig.ui_button_id}: expected "${modeConfig.ui_button_text}"`);
        }
    }
    
    if (allButtonsValid) {
        addValidationResult('UI Buttons', true, 'All UI buttons are correctly defined');
    } else {
        let errorDetails = '';
        if (missingButtons.length > 0) {
            errorDetails += `Missing buttons: ${missingButtons.join(', ')}. `;
        }
        if (incorrectTexts.length > 0) {
            errorDetails += `Incorrect text: ${incorrectTexts.join(', ')}.`;
        }
        addValidationResult('UI Buttons', false, 'UI button validation failed', errorDetails);
    }
}

// Validation 2: Backend Mode Mapping
function validateBackendModes(config) {
    logHeader('Validating Backend Mode Mapping');
    
    const javaFile = path.join(REPO_ROOT, 'quarkus-websocket-service/src/main/java/com/redhat/healthcare/GeneticPredictorEndpoint.java');
    
    if (!fs.existsSync(javaFile)) {
        addValidationResult('Backend Modes', false, 'Java endpoint file not found', javaFile);
        return;
    }
    
    const javaContent = fs.readFileSync(javaFile, 'utf8');
    let allModesValid = true;
    let missingModes = [];
    let incorrectTopics = [];
    let incorrectEventTypes = [];
    
    for (const [modeName, modeConfig] of Object.entries(config.scaling_modes)) {
        // Check mode case exists in switch statement
        const casePattern = new RegExp(`case\\s+"${modeConfig.backend_mode}":`);
        if (!casePattern.test(javaContent)) {
            allModesValid = false;
            missingModes.push(modeConfig.backend_mode);
            continue;
        }
        
        // Check Kafka topic assignment
        const topicPattern = new RegExp(`kafkaTopic\\s*=\\s*"${modeConfig.kafka_topic}"`);
        if (!topicPattern.test(javaContent)) {
            allModesValid = false;
            incorrectTopics.push(`${modeName}: expected topic "${modeConfig.kafka_topic}"`);
        }
        
        // Check event type assignment
        const eventTypePattern = new RegExp(`eventType\\s*=\\s*"${modeConfig.event_type}"`);
        if (!eventTypePattern.test(javaContent)) {
            allModesValid = false;
            incorrectEventTypes.push(`${modeName}: expected event type "${modeConfig.event_type}"`);
        }
    }
    
    if (allModesValid) {
        addValidationResult('Backend Modes', true, 'All backend modes are correctly mapped');
    } else {
        let errorDetails = '';
        if (missingModes.length > 0) {
            errorDetails += `Missing modes: ${missingModes.join(', ')}. `;
        }
        if (incorrectTopics.length > 0) {
            errorDetails += `Incorrect topics: ${incorrectTopics.join(', ')}. `;
        }
        if (incorrectEventTypes.length > 0) {
            errorDetails += `Incorrect event types: ${incorrectEventTypes.join(', ')}.`;
        }
        addValidationResult('Backend Modes', false, 'Backend mode validation failed', errorDetails);
    }
}

// Validation 3: Kafka Configuration
function validateKafkaConfiguration(config) {
    logHeader('Validating Kafka Configuration');
    
    const propsFile = path.join(REPO_ROOT, 'quarkus-websocket-service/src/main/resources/application.properties');
    
    if (!fs.existsSync(propsFile)) {
        addValidationResult('Kafka Config', false, 'Application properties file not found', propsFile);
        return;
    }
    
    const propsContent = fs.readFileSync(propsFile, 'utf8');
    let allConfigValid = true;
    let missingChannels = [];
    let incorrectTopics = [];
    
    for (const [modeName, modeConfig] of Object.entries(config.scaling_modes)) {
        // Check emitter channel configuration
        const channelPattern = new RegExp(`mp\\.messaging\\.outgoing\\.${modeConfig.emitter_channel}\\.`);
        if (!channelPattern.test(propsContent)) {
            allConfigValid = false;
            missingChannels.push(modeConfig.emitter_channel);
            continue;
        }
        
        // Check topic configuration
        const topicPattern = new RegExp(`mp\\.messaging\\.outgoing\\.${modeConfig.emitter_channel}\\.topic=${modeConfig.kafka_topic}`);
        if (!topicPattern.test(propsContent)) {
            allConfigValid = false;
            incorrectTopics.push(`${modeName}: channel "${modeConfig.emitter_channel}" should map to topic "${modeConfig.kafka_topic}"`);
        }
    }
    
    if (allConfigValid) {
        addValidationResult('Kafka Config', true, 'All Kafka configurations are correct');
    } else {
        let errorDetails = '';
        if (missingChannels.length > 0) {
            errorDetails += `Missing channels: ${missingChannels.join(', ')}. `;
        }
        if (incorrectTopics.length > 0) {
            errorDetails += `Incorrect topic mappings: ${incorrectTopics.join(', ')}.`;
        }
        addValidationResult('Kafka Config', false, 'Kafka configuration validation failed', errorDetails);
    }
}

// Validation 4: Emitter Channel Injection
function validateEmitterInjection(config) {
    logHeader('Validating Emitter Channel Injection');
    
    const javaFile = path.join(REPO_ROOT, 'quarkus-websocket-service/src/main/java/com/redhat/healthcare/GeneticPredictorEndpoint.java');
    
    if (!fs.existsSync(javaFile)) {
        addValidationResult('Emitter Injection', false, 'Java endpoint file not found', javaFile);
        return;
    }
    
    const javaContent = fs.readFileSync(javaFile, 'utf8');
    let allInjectionsValid = true;
    let missingInjections = [];
    let incorrectUsage = [];
    
    for (const [modeName, modeConfig] of Object.entries(config.scaling_modes)) {
        // Check @Channel injection
        const injectionPattern = new RegExp(`@Channel\\("${modeConfig.emitter_channel}"\\)`);
        if (!injectionPattern.test(javaContent)) {
            allInjectionsValid = false;
            missingInjections.push(modeConfig.emitter_channel);
            continue;
        }
        
        // Check emitter usage in switch statement
        const emitterFieldName = modeConfig.emitter_channel.replace(/-([a-z])/g, (match, letter) => letter.toUpperCase());
        const usagePattern = new RegExp(`${emitterFieldName}Emitter\\.send\\(cloudEventJson\\)`);
        if (!usagePattern.test(javaContent)) {
            allInjectionsValid = false;
            incorrectUsage.push(`${modeName}: emitter "${emitterFieldName}Emitter" not used correctly`);
        }
    }
    
    if (allInjectionsValid) {
        addValidationResult('Emitter Injection', true, 'All emitter channels are properly injected and used');
    } else {
        let errorDetails = '';
        if (missingInjections.length > 0) {
            errorDetails += `Missing injections: ${missingInjections.join(', ')}. `;
        }
        if (incorrectUsage.length > 0) {
            errorDetails += `Incorrect usage: ${incorrectUsage.join(', ')}.`;
        }
        addValidationResult('Emitter Injection', false, 'Emitter injection validation failed', errorDetails);
    }
}

// Validation 5: Test Coverage
function validateTestCoverage(config) {
    logHeader('Validating Test Coverage');
    
    const testFile = path.join(REPO_ROOT, 'scripts/test-ui-regression.js');
    
    if (!fs.existsSync(testFile)) {
        addValidationResult('Test Coverage', false, 'UI regression test file not found', testFile);
        return;
    }
    
    const testContent = fs.readFileSync(testFile, 'utf8');
    let allModesTested = true;
    let missingTestModes = [];
    
    for (const [modeName, modeConfig] of Object.entries(config.scaling_modes)) {
        // Check if mode is in TEST_MODES array
        const testModePattern = new RegExp(`name:\\s*'${modeConfig.backend_mode}'`);
        if (!testModePattern.test(testContent)) {
            allModesTested = false;
            missingTestModes.push(modeConfig.backend_mode);
        }
    }
    
    if (allModesTested) {
        addValidationResult('Test Coverage', true, 'All scaling modes are covered in UI regression tests');
    } else {
        addValidationResult('Test Coverage', false, 'Some scaling modes are missing from tests', 
                          `Missing modes: ${missingTestModes.join(', ')}`);
    }
}

// Main validation function
function runValidation() {
    logHeader('Healthcare ML Scaling Mode Separation Validation');
    logInfo(`Repository root: ${REPO_ROOT}`);
    logInfo(`Configuration: ${CONFIG_PATH}`);
    logInfo(`Fix mode: ${FIX_MODE ? 'ENABLED' : 'DISABLED'}`);
    
    const config = loadConfig();
    
    // Display configuration summary
    logInfo(`Validating ${Object.keys(config.scaling_modes).length} scaling modes:`);
    for (const [modeName, modeConfig] of Object.entries(config.scaling_modes)) {
        console.log(`   ${modeName}: ${modeConfig.ui_button_text} → ${modeConfig.kafka_topic}`);
    }
    
    // Run all validations
    validateUIButtons(config);
    validateBackendModes(config);
    validateKafkaConfiguration(config);
    validateEmitterInjection(config);
    validateTestCoverage(config);
    
    // Summary
    logHeader('Validation Summary');
    console.log(`Total validations: ${totalValidations}`);
    console.log(`Passed: ${passedValidations}`);
    console.log(`Failed: ${totalValidations - passedValidations}`);
    
    // Detailed results
    if (validationResults.some(r => !r.passed)) {
        logError('\nFailed Validations:');
        validationResults.filter(r => !r.passed).forEach(result => {
            console.log(`   ❌ ${result.name}: ${result.message}`);
            if (result.details) {
                console.log(`      ${result.details}`);
            }
        });
        
        logError('\n💡 To fix these issues:');
        console.log('   1. Review the scaling-mode-separation.yaml configuration');
        console.log('   2. Update the corresponding source files to match the configuration');
        console.log('   3. Ensure all UI buttons, backend modes, and Kafka topics are aligned');
        console.log('   4. Run this validation script again to verify fixes');
    } else {
        logSuccess('\n🎉 All scaling mode separation validations passed!');
        logSuccess('The separation of concerns is properly maintained.');
    }
    
    // Exit with appropriate code
    process.exit(passedValidations === totalValidations ? 0 : 1);
}

// Handle dependencies
try {
    // Check if js-yaml is available
    require.resolve('js-yaml');
} catch (error) {
    logError('Missing dependency: js-yaml');
    logInfo('Run: npm install js-yaml');
    process.exit(2);
}

// Run validation
runValidation();
