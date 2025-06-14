package com.redhat.healthcare.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

/**
 * Generic API response model for consistent REST API responses.
 * Provides standardized response format for all scaling test endpoints.
 */
public class ApiResponse<T> {
    
    @JsonProperty("status")
    private String status;
    
    @JsonProperty("message")
    private String message;
    
    @JsonProperty("data")
    private T data;
    
    @JsonProperty("timestamp")
    private String timestamp;
    
    @JsonProperty("metadata")
    private Map<String, Object> metadata;
    
    // Default constructor
    public ApiResponse() {
        this.timestamp = Instant.now().toString();
        this.metadata = new HashMap<>();
    }
    
    // Success response constructors
    public static <T> ApiResponse<T> success(String message, T data) {
        ApiResponse<T> response = new ApiResponse<>();
        response.status = "success";
        response.message = message;
        response.data = data;
        return response;
    }
    
    public static <T> ApiResponse<T> success(String message) {
        return success(message, null);
    }
    
    // Error response constructors
    public static <T> ApiResponse<T> error(String message) {
        ApiResponse<T> response = new ApiResponse<>();
        response.status = "error";
        response.message = message;
        return response;
    }
    
    public static <T> ApiResponse<T> error(String message, T data) {
        ApiResponse<T> response = new ApiResponse<>();
        response.status = "error";
        response.message = message;
        response.data = data;
        return response;
    }
    
    // Getters and setters
    public String getStatus() {
        return status;
    }
    
    public void setStatus(String status) {
        this.status = status;
    }
    
    public String getMessage() {
        return message;
    }
    
    public void setMessage(String message) {
        this.message = message;
    }
    
    public T getData() {
        return data;
    }
    
    public void setData(T data) {
        this.data = data;
    }
    
    public String getTimestamp() {
        return timestamp;
    }
    
    public void setTimestamp(String timestamp) {
        this.timestamp = timestamp;
    }
    
    public Map<String, Object> getMetadata() {
        return metadata;
    }
    
    public void setMetadata(Map<String, Object> metadata) {
        this.metadata = metadata;
    }
    
    // Utility methods
    public ApiResponse<T> addMetadata(String key, Object value) {
        this.metadata.put(key, value);
        return this;
    }
    
    public boolean isSuccess() {
        return "success".equals(status);
    }
    
    public boolean isError() {
        return "error".equals(status);
    }
}
