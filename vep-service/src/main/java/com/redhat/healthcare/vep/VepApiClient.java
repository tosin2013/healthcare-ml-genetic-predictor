package com.redhat.healthcare.vep;

import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;
import org.eclipse.microprofile.rest.client.annotation.ClientHeaderParam;

import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import java.util.concurrent.CompletionStage;

/**
 * REST client for Ensembl VEP (Variant Effect Predictor) API
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
     * @param request VEP request containing HGVS notations
     * @param species Species (default: human)
     * @return VEP annotation response
     */
    @POST
    @Path("/vep/{species}/hgvs")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    VepApiResponse annotateVariants(
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
    CompletionStage<VepApiResponse> annotateVariantsAsync(
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
