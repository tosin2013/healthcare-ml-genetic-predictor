package com.redhat.healthcare.vep;

import org.eclipse.microprofile.health.HealthCheck;
import org.eclipse.microprofile.health.HealthCheckResponse;
import org.eclipse.microprofile.health.Liveness;
import org.eclipse.microprofile.health.Readiness;
import org.eclipse.microprofile.rest.client.inject.RestClient;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

/**
 * Health checks for VEP annotation service
 */
@ApplicationScoped
public class VepHealthCheck {

    @Inject
    @RestClient
    VepApiClient vepApiClient;

    @Liveness
    public HealthCheck livenessCheck() {
        return () -> HealthCheckResponse.named("vep-service-liveness")
                .status(true)
                .withData("service", "vep-annotation-service")
                .withData("version", "1.0.0")
                .build();
    }

    @Readiness
    public HealthCheck readinessCheck() {
        return () -> {
            try {
                // Try to ping the VEP API
                String response = vepApiClient.ping();
                boolean isReady = response != null && response.contains("ping");

                return HealthCheckResponse.named("vep-api-readiness")
                        .status(isReady)
                        .withData("vep_api_status", isReady ? "available" : "unavailable")
                        .withData("vep_api_response_length", response != null ? response.length() : 0)
                        .withData("contains_ping", response != null && response.contains("ping"))
                        .build();

            } catch (Exception e) {
                return HealthCheckResponse.named("vep-api-readiness")
                        .status(false)
                        .withData("vep_api_status", "error")
                        .withData("error_message", e.getMessage())
                        .build();
            }
        };
    }
}
