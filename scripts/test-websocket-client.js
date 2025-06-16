#!/usr/bin/env node

/**
 * WebSocket Client Test for Healthcare ML Genetic Analysis
 * 
 * Tests the complete end-to-end flow:
 * 1. Connect to WebSocket endpoint
 * 2. Send genetic sequence for analysis
 * 3. Keep connection alive and wait for VEP results
 * 4. Monitor timing and session management
 * 
 * Usage:
 *   node test-websocket-client.js [mode] [sequence] [timeout]
 * 
 * Examples:
 *   node test-websocket-client.js normal "ATCGATCGATCGATCGATCG" 60
 *   node test-websocket-client.js big-data "ATCGATCGATCGATCGATCGATCGATCGATCGATCG" 120
 *   node test-websocket-client.js node-scale "ATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCG" 180
 */

const WebSocket = require('ws');

// Configuration
const WEBSOCKET_URL = process.env.WEBSOCKET_URL || 'wss://quarkus-websocket-knative-healthcare-ml-demo.apps.b9892ub1.eastus.aroapp.io/genetics';
const mode = process.argv[2] || 'normal';
const sequence = process.argv[3] || 'ATCGATCGATCGATCGATCG';
const timeoutSeconds = parseInt(process.argv[4]) || 120;

console.log('🧬 Healthcare ML WebSocket Client Test');
console.log('=====================================');
console.log(`WebSocket URL: ${WEBSOCKET_URL}`);
console.log(`Mode: ${mode}`);
console.log(`Sequence: ${sequence} (${sequence.length} chars)`);
console.log(`Timeout: ${timeoutSeconds} seconds`);
console.log('');

// Test state
let startTime = Date.now();
let connectionTime = null;
let messageTime = null;
let responseTime = null;
let sessionId = null;
let responseReceived = false;

// Create WebSocket connection
console.log('🔌 Connecting to WebSocket...');
const ws = new WebSocket(WEBSOCKET_URL);

// Connection opened
ws.on('open', function open() {
    connectionTime = Date.now();
    console.log(`✅ Connected in ${connectionTime - startTime}ms`);
    console.log('');
    
    // Prepare message based on mode
    let message;
    if (mode === 'normal') {
        // Simple string for normal mode
        message = sequence;
    } else {
        // JSON format for advanced modes
        message = JSON.stringify({
            sequence: sequence,
            mode: mode,
            resourceProfile: mode === 'big-data' ? 'high-memory' : 'cluster-scale',
            timestamp: Date.now()
        });
    }
    
    console.log(`📤 Sending ${mode} mode genetic sequence...`);
    console.log(`Message: ${message.substring(0, 100)}${message.length > 100 ? '...' : ''}`);
    
    messageTime = Date.now();
    ws.send(message);
    
    console.log(`📨 Message sent at ${new Date(messageTime).toISOString()}`);
    console.log('⏳ Waiting for VEP processing results...');
    console.log('');
});

// Message received
ws.on('message', function message(data) {
    const currentTime = Date.now();
    const messageStr = data.toString();
    
    console.log(`📥 Message received at ${new Date(currentTime).toISOString()}`);
    console.log(`⏱️  Response time: ${currentTime - messageTime}ms`);
    console.log(`📋 Content: ${messageStr}`);
    console.log('');
    
    // Check if this is the initial connection message
    if (messageStr.includes('Connected to Healthcare ML Service')) {
        console.log('ℹ️  Initial connection confirmation received');
        return;
    }
    
    // Check if this is a processing status message
    if (messageStr.includes('queued for') || messageStr.includes('Processing')) {
        console.log('ℹ️  Processing status message received');
        return;
    }
    
    // Check if this is a progress update (starts with timestamp)
    if (messageStr.match(/^\[\d{2}:\d{2}:\d{2}\]/)) {
        console.log('📈 Progress update received');
        return;
    }

    // Check if this contains actual VEP results (with detailed annotations)
    if (messageStr.includes('**Genetic Analysis Complete**') ||
        messageStr.includes('Gene:') ||
        messageStr.includes('SIFT:') ||
        messageStr.includes('PolyPhen:') ||
        (messageStr.includes('annotation') && messageStr.includes('variant_count'))) {

        responseTime = currentTime;
        responseReceived = true;

        console.log('🎉 VEP RESULTS RECEIVED!');
        console.log(`⏱️  Total processing time: ${responseTime - messageTime}ms`);
        console.log(`📊 Results: ${messageStr.substring(0, 300)}${messageStr.length > 300 ? '...' : ''}`);

        // Try to extract session ID
        try {
            const jsonMatch = messageStr.match(/\{.*\}/);
            if (jsonMatch) {
                const resultData = JSON.parse(jsonMatch[0]);
                sessionId = resultData.sessionId || resultData.session_id;
                console.log(`🔑 Session ID: ${sessionId}`);
            }
        } catch (e) {
            console.log('ℹ️  Could not parse JSON from results');
        }

        // Close connection after receiving results
        console.log('');
        console.log('✅ Test completed successfully - closing connection');
        ws.close();
        return;
    }
    
    console.log('ℹ️  Other message type received');
});

// Connection error
ws.on('error', function error(err) {
    console.error('❌ WebSocket error:', err.message);
    process.exit(1);
});

// Connection closed
ws.on('close', function close(code, reason) {
    const endTime = Date.now();
    console.log('');
    console.log('🔌 WebSocket connection closed');
    console.log(`📊 Close code: ${code}`);
    console.log(`📋 Reason: ${reason || 'No reason provided'}`);
    console.log('');
    
    // Test summary
    console.log('📊 TEST SUMMARY');
    console.log('===============');
    console.log(`Connection time: ${connectionTime ? connectionTime - startTime : 'N/A'}ms`);
    console.log(`Message sent time: ${messageTime ? messageTime - startTime : 'N/A'}ms`);
    console.log(`Total session duration: ${endTime - startTime}ms`);
    
    if (responseReceived) {
        console.log(`✅ VEP response received: ${responseTime - messageTime}ms`);
        console.log(`🎯 Session ID: ${sessionId || 'Not extracted'}`);
        console.log('');
        console.log('🎉 SUCCESS: Complete end-to-end flow working!');
        process.exit(0);
    } else {
        console.log('❌ No VEP response received');
        console.log('');
        console.log('🔍 ANALYSIS:');
        console.log('- WebSocket connection worked');
        console.log('- Message was sent successfully');
        console.log('- VEP service may be scaling up (check OpenShift pods)');
        console.log('- Session may have timed out before VEP processing completed');
        console.log('');
        console.log('💡 RECOMMENDATIONS:');
        console.log('- Check VEP service pod status: oc get pods | grep vep-service');
        console.log('- Check KEDA scaling: oc describe scaledobject vep-service-scaler');
        console.log('- Check Kafka lag: scripts/test-vep-scaling-simple.sh');
        console.log('- Increase WebSocket timeout in application.properties');
        process.exit(1);
    }
});

// Set timeout
setTimeout(() => {
    if (!responseReceived) {
        console.log('');
        console.log(`⏰ TIMEOUT: No VEP response received within ${timeoutSeconds} seconds`);
        console.log('');
        console.log('🔍 TIMEOUT ANALYSIS:');
        console.log('- VEP service may still be scaling up from 0 pods');
        console.log('- Cold start can take 15-60 seconds');
        console.log('- WebSocket session may need longer timeout');
        console.log('');
        ws.close();
    }
}, timeoutSeconds * 1000);

// Handle process termination
process.on('SIGINT', () => {
    console.log('');
    console.log('🛑 Test interrupted by user');
    ws.close();
    process.exit(0);
});
