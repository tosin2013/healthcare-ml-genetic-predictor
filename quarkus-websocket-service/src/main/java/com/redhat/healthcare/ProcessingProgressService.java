package com.redhat.healthcare;

import io.quarkus.scheduler.Scheduled;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.websocket.Session;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

/**
 * Service that sends periodic progress updates to WebSocket clients during VEP processing.
 * 
 * This service addresses the issue where VEP service cold start can take 15-60 seconds,
 * causing WebSocket sessions to timeout before results are delivered. By sending periodic
 * "still processing" messages, we keep the WebSocket connection alive and provide user feedback.
 * 
 * Features:
 * - Tracks active processing sessions
 * - Sends progress updates every 15 seconds
 * - Automatically stops updates when results are delivered
 * - Provides estimated completion times
 * - Handles session cleanup
 */
@ApplicationScoped
public class ProcessingProgressService {

    private static final Logger LOGGER = LoggerFactory.getLogger(ProcessingProgressService.class);
    
    // Track sessions that are currently processing
    private final ConcurrentMap<String, ProcessingSession> processingSessions = new ConcurrentHashMap<>();
    
    /**
     * Register a session for progress updates during VEP processing.
     * 
     * @param sessionId The API session ID
     * @param websocketSession The WebSocket session
     * @param mode The processing mode (normal, big-data, node-scale)
     * @param sequenceLength The length of the genetic sequence
     */
    public void startProcessingUpdates(String sessionId, Session websocketSession, String mode, int sequenceLength) {
        ProcessingSession processingSession = new ProcessingSession(
            sessionId, websocketSession, mode, sequenceLength, System.currentTimeMillis()
        );
        
        processingSessions.put(sessionId, processingSession);
        
        LOGGER.info("Started progress updates for session {} ({} mode, {} chars)", 
                   sessionId, mode, sequenceLength);
        
        // Send initial processing message
        sendProgressUpdate(processingSession, 0);
    }
    
    /**
     * Stop progress updates for a session (called when results are delivered).
     * 
     * @param sessionId The API session ID
     */
    public void stopProcessingUpdates(String sessionId) {
        ProcessingSession session = processingSessions.remove(sessionId);
        if (session != null) {
            long processingTime = System.currentTimeMillis() - session.startTime;
            LOGGER.info("Stopped progress updates for session {} after {}ms", sessionId, processingTime);
        }
    }
    
    /**
     * Scheduled method that sends progress updates every 15 seconds.
     */
    @Scheduled(every = "15s")
    public void sendPeriodicUpdates() {
        if (processingSessions.isEmpty()) {
            return;
        }
        
        LOGGER.debug("Sending progress updates to {} active sessions", processingSessions.size());
        
        long currentTime = System.currentTimeMillis();
        
        // Send updates to all active processing sessions
        processingSessions.entrySet().removeIf(entry -> {
            String sessionId = entry.getKey();
            ProcessingSession session = entry.getValue();
            
            // Enhanced session validation with keepalive
            if (!isSessionHealthy(session.websocketSession, sessionId)) {
                LOGGER.info("📋 SESSION HEALTH: WebSocket session {} is unhealthy, removing from progress updates", sessionId);
                return true; // Remove from map
            }
            
            // Calculate elapsed time
            long elapsedTime = currentTime - session.startTime;
            int elapsedSeconds = (int) (elapsedTime / 1000);
            
            // Stop updates after 15 minutes (900 seconds) to accommodate VEP processing + Kafka delay
            if (elapsedSeconds > 900) {
                LOGGER.warn("Progress updates for session {} exceeded 15 minutes, stopping", sessionId);
                sendTimeoutMessage(session);
                return true; // Remove from map
            }
            
            // Send progress update
            sendProgressUpdate(session, elapsedSeconds);
            
            return false; // Keep in map
        });
    }
    
    /**
     * Send a progress update message to the WebSocket client.
     */
    private void sendProgressUpdate(ProcessingSession session, int elapsedSeconds) {
        try {
            String progressMessage = buildProgressMessage(session, elapsedSeconds);
            session.websocketSession.getAsyncRemote().sendText(progressMessage);
            
            LOGGER.debug("Sent progress update to session {} ({}s elapsed)", 
                        session.sessionId, elapsedSeconds);
                        
        } catch (Exception e) {
            LOGGER.error("Failed to send progress update to session {}: {}", 
                        session.sessionId, e.getMessage());
        }
    }
    
    /**
     * Build a progress message based on processing mode and elapsed time.
     */
    private String buildProgressMessage(ProcessingSession session, int elapsedSeconds) {
        String timeStr = LocalDateTime.now().format(DateTimeFormatter.ofPattern("HH:mm:ss"));
        
        if (elapsedSeconds == 0) {
            // Initial message
            switch (session.mode) {
                case "big-data":
                    return String.format("[%s] 🚀 Starting big data analysis (%d chars)...", timeStr, session.sequenceLength);
                case "node-scale":
                    return String.format("[%s] ⚡ Starting cluster-scale analysis (%d chars)...", timeStr, session.sequenceLength);
                default:
                    return String.format("[%s] 🔬 Starting VEP annotation analysis (%d chars)...", timeStr, session.sequenceLength);
            }
        }
        
        // Progress messages based on elapsed time
        if (elapsedSeconds <= 15) {
            return String.format("[%s] ⏳ VEP service scaling up... (%ds)", timeStr, elapsedSeconds);
        } else if (elapsedSeconds <= 30) {
            return String.format("[%s] 🧬 VEP service processing genetic sequence... (%ds)", timeStr, elapsedSeconds);
        } else if (elapsedSeconds <= 60) {
            return String.format("[%s] 🔍 Analyzing variants and generating annotations... (%ds)", timeStr, elapsedSeconds);
        } else if (elapsedSeconds <= 120) {
            return String.format("[%s] 📊 Finalizing ML predictions and results... (%ds)", timeStr, elapsedSeconds);
        } else if (elapsedSeconds <= 300) {
            return String.format("[%s] 🧬 VEP annotation service processing... (%ds)", timeStr, elapsedSeconds);
        } else if (elapsedSeconds <= 600) {
            return String.format("[%s] 📤 Publishing results and preparing delivery... (%ds)", timeStr, elapsedSeconds);
        } else {
            return String.format("[%s] ⏳ Extended analysis in progress, maintaining connection... (%ds)", timeStr, elapsedSeconds);
        }
    }
    
    /**
     * Send a timeout message when processing takes too long.
     */
    private void sendTimeoutMessage(ProcessingSession session) {
        try {
            String timeStr = LocalDateTime.now().format(DateTimeFormatter.ofPattern("HH:mm:ss"));
            String timeoutMessage = String.format(
                "[%s] ⚠️ Analysis is taking longer than expected. " +
                "VEP service may be under heavy load. " +
                "Results will be delivered when processing completes.", timeStr);
            
            session.websocketSession.getAsyncRemote().sendText(timeoutMessage);
            
        } catch (Exception e) {
            LOGGER.error("Failed to send timeout message to session {}: {}", 
                        session.sessionId, e.getMessage());
        }
    }
    
    /**
     * Enhanced session health check with keepalive validation.
     *
     * @param websocketSession The WebSocket session to check
     * @param sessionId The session ID for logging
     * @return true if session is healthy and active
     */
    private boolean isSessionHealthy(Session websocketSession, String sessionId) {
        try {
            // Check if session is open
            if (!websocketSession.isOpen()) {
                LOGGER.info("📋 SESSION HEALTH: Session {} is closed", sessionId);
                return false;
            }

            // Send keepalive ping to verify connection
            try {
                websocketSession.getAsyncRemote().sendPing(java.nio.ByteBuffer.wrap("keepalive".getBytes()));
                LOGGER.debug("📋 SESSION HEALTH: Sent keepalive ping to session {}", sessionId);
                return true;
            } catch (Exception pingException) {
                LOGGER.warn("📋 SESSION HEALTH: Failed to send keepalive ping to session {}: {}",
                           sessionId, pingException.getMessage());
                return false;
            }

        } catch (Exception e) {
            LOGGER.error("📋 SESSION HEALTH: Error checking session {} health: {}", sessionId, e.getMessage());
            return false;
        }
    }

    /**
     * Get the number of currently active processing sessions.
     */
    public int getActiveSessionCount() {
        return processingSessions.size();
    }
    
    /**
     * Data class to track processing session information.
     */
    private static class ProcessingSession {
        final String sessionId;
        final Session websocketSession;
        final String mode;
        final int sequenceLength;
        final long startTime;
        
        ProcessingSession(String sessionId, Session websocketSession, String mode, 
                         int sequenceLength, long startTime) {
            this.sessionId = sessionId;
            this.websocketSession = websocketSession;
            this.mode = mode;
            this.sequenceLength = sequenceLength;
            this.startTime = startTime;
        }
    }
}
