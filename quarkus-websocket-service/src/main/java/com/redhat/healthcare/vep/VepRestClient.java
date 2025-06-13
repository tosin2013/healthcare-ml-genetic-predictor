package com.redhat.healthcare.vep;

import io.smallrye.mutiny.Uni;
import org.eclipse.microprofile.faulttolerance.CircuitBreaker;
import org.eclipse.microprofile.faulttolerance.Retry;
import org.eclipse.microprofile.faulttolerance.Timeout;
import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;

import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import java.time.temporal.ChronoUnit;
import java.util.List;

/**
 * REST Client interface for Ensembl Variant Effect Predictor (VEP) API integration.
 * 
 * This interface provides reactive, fault-tolerant access to the Ensembl VEP REST API
 * for comprehensive genetic variant annotation including:
 * - Variant consequence prediction using Sequence Ontology terms
 * - Pathogenicity scoring with SIFT/PolyPhen-2
 * - Clinical significance assessment via ClinVar
 * - Population frequency analysis from gnomAD and 1000 Genomes
 * 
 * The implementation uses reactive programming patterns with Mutiny Uni for
 * non-blocking operations and comprehensive fault tolerance patterns for
 * production-grade resilience in healthcare ML applications.
 */
@RegisterRestClient(configKey = "vep-api")
@Path("/vep/human")
public interface VepRestClient {

    /**
     * Annotate genetic variants using HGVS notation.
     * 
     * This method accepts a list of genetic variants in HGVS (Human Genome Variation Society)
     * notation and returns comprehensive VEP annotations including consequence predictions,
     * pathogenicity scores, and clinical significance assessments.
     * 
     * @param variants List of genetic variants in HGVS notation (e.g., "9:g.22125504G>C")
     * @return Reactive Uni containing list of VEP annotations for each variant
     */
    @POST
    @Path("/hgvs")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    @Retry(maxRetries = 3, delay = 1000, delayUnit = ChronoUnit.MILLIS)
    @CircuitBreaker(requestVolumeThreshold = 4, failureRatio = 0.5, delay = 5000, delayUnit = ChronoUnit.MILLIS)
    @Timeout(value = 10, unit = ChronoUnit.SECONDS)
    Uni<List<VepAnnotation>> annotateVariantsHgvs(List<String> variants);

    /**
     * Annotate genetic variants using VCF format.
     * 
     * This method accepts genetic variant data in VCF (Variant Call Format) and
     * returns comprehensive VEP annotations. Supports both single variants and
     * batch processing for efficient genetic analysis workflows.
     * 
     * @param vcfData VCF format variant data as string
     * @return Reactive Uni containing list of VEP annotations
     */
    @POST
    @Path("/region")
    @Consumes(MediaType.TEXT_PLAIN)
    @Produces(MediaType.APPLICATION_JSON)
    @Retry(maxRetries = 3, delay = 1000, delayUnit = ChronoUnit.MILLIS)
    @CircuitBreaker(requestVolumeThreshold = 4, failureRatio = 0.5, delay = 5000, delayUnit = ChronoUnit.MILLIS)
    @Timeout(value = 15, unit = ChronoUnit.SECONDS)
    Uni<List<VepAnnotation>> annotateVariantsVcf(String vcfData);

    /**
     * Get VEP service information and available annotation sources.
     * 
     * This method provides metadata about the VEP service including available
     * annotation sources, database versions, and service capabilities.
     * Used for service health checks and configuration validation.
     * 
     * @return Reactive Uni containing VEP service information
     */
    @GET
    @Path("/info/ping")
    @Produces(MediaType.APPLICATION_JSON)
    @Timeout(value = 5, unit = ChronoUnit.SECONDS)
    Uni<VepServiceInfo> getServiceInfo();
}
