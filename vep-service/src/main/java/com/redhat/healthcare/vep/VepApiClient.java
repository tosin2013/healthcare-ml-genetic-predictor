package com.redhat.healthcare.vep;

import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;
import org.eclipse.microprofile.rest.client.annotation.ClientHeaderParam;

import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import java.util.List;
import java.util.concurrent.CompletionStage;

/**
 * REST client for Ensembl VEP (Variant Effect Predictor) API
 *
 * API Documentation: https://rest.ensembl.org/documentation/info/vep_hgvs_post
 * Base URL: https://rest.ensembl.org
 * Endpoint: POST /vep/{species}/hgvs
 *
 * WHY THIS API:
 * - Industry standard for variant annotation (used by 23andMe, GATK, etc.)
 * - Free, public API with no authentication required
 * - Supports HGVS notation (Human Genome Variation Society standard)
 * - Returns comprehensive variant consequence predictions
 * - Maintained by EMBL-EBI (European Bioinformatics Institute)
 *
 * REQUEST FORMAT:
 * Content-Type: application/json
 * Body: {"hgvs_notations": ["ENST00000366667:c.803C>T", "9:g.22125504G>C"]}
 *
 * RESPONSE FORMAT:
 * Returns: Array of variant objects (NOT single object)
 * Each variant contains: input, transcript_consequences, regulatory_feature_consequences, etc.
 *
 * RATE LIMITS:
 * - 55,000 requests per hour per IP
 * - 15 requests per second per IP
 * - POST requests limited to 1000 variants per request
 *
 * This client interfaces with the Ensembl REST API to annotate genetic variants.
 * It supports both synchronous and asynchronous operations with proper error handling.
 */
@RegisterRestClient(configKey = "vep-api")
@ClientHeaderParam(name = "User-Agent", value = "Healthcare-ML-VEP-Service/1.0")
@ClientHeaderParam(name = "Content-Type", value = MediaType.APPLICATION_JSON)
public interface VepApiClient {

    /**
     * Annotate genetic variants using VEP with HGVS notations
     *
     * API Reference: https://rest.ensembl.org/documentation/info/vep_hgvs_post
     * Example Request: POST https://rest.ensembl.org/vep/human/hgvs
     *
     * CRITICAL: VEP API returns an ARRAY of variant objects, not a single object
     * This was the root cause of our "Cannot deserialize from Array value" error
     *
     * Example Response:
     * [
     *   {
     *     "input": "ENST00000366667:c.803C>T",
     *     "transcript_consequences": [...],
     *     "most_severe_consequence": "missense_variant"
     *   }
     * ]
     *
     * @param request VEP request containing HGVS notations (max 1000 per request)
     * @param species Species (default: human) - supports human, mouse, etc.
     * @return Array of VEP annotation responses (one per input HGVS notation)
     */
    @POST
    @Path("/vep/{species}/hgvs")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    List<VepApiResponse> annotateVariants(
        VepHgvsRequest request,
        @PathParam("species") @DefaultValue("human") String species
    );

    /**
     * Asynchronous variant annotation with HGVS notations
     */
    @POST
    @Path("/vep/{species}/hgvs")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    CompletionStage<List<VepApiResponse>> annotateVariantsAsync(
        VepHgvsRequest request,
        @PathParam("species") @DefaultValue("human") String species
    );

    /**
     * Get VEP service information
     */
    @GET
    @Path("/info/species/{species}")
    @Produces(MediaType.APPLICATION_JSON)
    VepServiceInfo getServiceInfo(@PathParam("species") @DefaultValue("human") String species);

    /**
     * Health check endpoint
     */
    @GET
    @Path("/info/software")
    @Produces(MediaType.TEXT_HTML)
    String ping();
}
