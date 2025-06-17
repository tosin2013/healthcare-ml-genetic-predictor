#!/usr/bin/env node

/**
 * Test WebSocket + Kafka integration for VEP results
 * 
 * This script tests the complete flow:
 * 1. Connect to WebSocket service
 * 2. Send genetic sequence for processing
 * 3. Keep connection alive and wait for VEP results from Kafka
 * 4. Verify results are received via WebSocket
 */

const WebSocket = require('ws');

// Configuration
const WEBSOCKET_URL = 'wss://quarkus-websocket-knative-healthcare-ml-demo.apps.b9892ub1.eastus.aroapp.io/genetics';
const TEST_SEQUENCE = 'ATCGATCGATCGATCGATCGATCGATCGATCGATCGATCG'; // 40 chars
const TIMEOUT_MS = 10 * 60 * 1000; // 10 minutes
const KEEPALIVE_INTERVAL = 30 * 1000; // 30 seconds

console.log('🧬 Testing WebSocket + Kafka Integration for VEP Results');
console.log('========================================================');
console.log(`WebSocket URL: ${WEBSOCKET_URL}`);
console.log(`Test Sequence: ${TEST_SEQUENCE} (${TEST_SEQUENCE.length} chars)`);
console.log(`Timeout: ${TIMEOUT_MS / 1000} seconds`);
console.log('');

let ws;
let sessionId;
let startTime;
let keepaliveTimer;
let timeoutTimer;

function connect() {
    console.log('📡 Connecting to WebSocket...');
    
    ws = new WebSocket(WEBSOCKET_URL);
    startTime = Date.now();

    ws.on('open', function open() {
        console.log('✅ WebSocket connected successfully');
        console.log('📤 Sending genetic sequence for node-scale processing...');
        
        // Send genetic sequence for processing
        const message = JSON.stringify({
            mode: 'node-scale',
            sequence: TEST_SEQUENCE
        });
        
        ws.send(message);
        console.log(`📤 Sent: ${message.substring(0, 100)}...`);
        
        // Start keepalive to prevent timeout
        startKeepalive();
        
        // Set overall timeout
        timeoutTimer = setTimeout(() => {
            console.log('⏰ Test timeout reached - no results received');
            cleanup();
            process.exit(1);
        }, TIMEOUT_MS);
    });

    ws.on('message', function message(data) {
        const elapsed = Math.round((Date.now() - startTime) / 1000);
        const messageStr = data.toString();
        
        console.log(`📥 [${elapsed}s] Received: ${messageStr.substring(0, 200)}...`);
        
        // Check if this is the final VEP results
        if (messageStr.includes('Genetic Analysis Complete') || 
            messageStr.includes('VEP Annotations Found') ||
            messageStr.includes('annotation_source')) {
            
            console.log('');
            console.log('🎉 SUCCESS! VEP results received via WebSocket!');
            console.log('==============================================');
            console.log('Full message:');
            console.log(messageStr);
            console.log('');
            console.log(`⏱️  Total processing time: ${elapsed} seconds`);
            console.log('✅ WebSocket + Kafka integration working correctly!');
            
            cleanup();
            process.exit(0);
        }
        
        // Extract session ID from progress messages
        if (messageStr.includes('session') && !sessionId) {
            const match = messageStr.match(/session[:\s]+([a-zA-Z0-9_-]+)/);
            if (match) {
                sessionId = match[1];
                console.log(`🔑 Session ID: ${sessionId}`);
            }
        }
    });

    ws.on('error', function error(err) {
        console.error('❌ WebSocket error:', err.message);
        cleanup();
        process.exit(1);
    });

    ws.on('close', function close(code, reason) {
        console.log(`🔌 WebSocket closed: ${code} ${reason}`);
        cleanup();
        process.exit(1);
    });
}

function startKeepalive() {
    keepaliveTimer = setInterval(() => {
        if (ws && ws.readyState === WebSocket.OPEN) {
            const elapsed = Math.round((Date.now() - startTime) / 1000);
            console.log(`💓 [${elapsed}s] Keepalive - connection active, waiting for VEP results...`);
        }
    }, KEEPALIVE_INTERVAL);
}

function cleanup() {
    if (keepaliveTimer) {
        clearInterval(keepaliveTimer);
    }
    if (timeoutTimer) {
        clearTimeout(timeoutTimer);
    }
    if (ws) {
        ws.close();
    }
}

// Handle process termination
process.on('SIGINT', () => {
    console.log('\n🛑 Test interrupted by user');
    cleanup();
    process.exit(0);
});

process.on('SIGTERM', () => {
    console.log('\n🛑 Test terminated');
    cleanup();
    process.exit(0);
});

// Start the test
connect();
