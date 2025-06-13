document.addEventListener('DOMContentLoaded', () => {
    const connectBtn = document.getElementById('connectBtn');
    const sendBtn = document.getElementById('sendBtn');
    const autoStreamBtn = document.getElementById('autoStreamBtn');
    const statusIndicator = document.getElementById('statusIndicator');
    const statusText = document.getElementById('statusText');
    const log = document.getElementById('log');

    let socket;
    let autoStreamInterval;

    function logMessage(message) {
        log.textContent += `> ${message}\n`;
        log.scrollTop = log.scrollHeight;
    }

    function connect() {
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const host = window.location.host;
        const path = '/genetics';
        const wsUrl = `${protocol}//${host}${path}`;

        logMessage(`Connecting to ${wsUrl}...`);
        socket = new WebSocket(wsUrl);

        socket.onopen = () => {
            logMessage('Connection established.');
            statusIndicator.className = 'connected';
            statusText.textContent = 'Connected';
            connectBtn.disabled = true;
            sendBtn.disabled = false;
            autoStreamBtn.disabled = false;
        };

        socket.onmessage = (event) => {
            logMessage(`Received: ${event.data}`);
        };

        socket.onclose = () => {
            logMessage('Connection closed.');
            statusIndicator.className = 'disconnected';
            statusText.textContent = 'Disconnected';
            connectBtn.disabled = false;
            sendBtn.disabled = true;
            autoStreamBtn.disabled = true;
            stopAutoStream();
        };

        socket.onerror = (error) => {
            logMessage(`WebSocket Error: ${error.message || 'Unknown error'}`);
        };
    }

    function generateRandom8BitSequence() {
        let sequence = '';
        for (let i = 0; i < 8; i++) {
            sequence += Math.round(Math.random());
        }
        return sequence;
    }

    function sendSequence() {
        if (socket && socket.readyState === WebSocket.OPEN) {
            const sequence = generateRandom8BitSequence();
            logMessage(`Sending: ${sequence}`);
            socket.send(sequence);
        }
    }

    function startAutoStream() {
        logMessage('Starting auto-stream...');
        autoStreamBtn.textContent = 'Stop Auto-Stream';
        autoStreamBtn.onclick = stopAutoStream;
        sendBtn.disabled = true; // Disable manual send during auto-stream
        autoStreamInterval = setInterval(sendSequence, 1000);
    }

    function stopAutoStream() {
        if (autoStreamInterval) {
            logMessage('Stopping auto-stream.');
            clearInterval(autoStreamInterval);
            autoStreamInterval = null;
            autoStreamBtn.textContent = 'Start Auto-Stream';
            autoStreamBtn.onclick = startAutoStream;
            sendBtn.disabled = false;
        }
    }

    connectBtn.onclick = connect;
    sendBtn.onclick = sendSequence;
    autoStreamBtn.onclick = startAutoStream;
});
