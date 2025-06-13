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
@Path("/vep")
public interface VepApiClient {

    /**
     * Annotate genetic variants using VEP
     * 
     * @param sequence Genetic sequence to annotate
     * @param species Species (default: human)
     * @param assembly Genome assembly (default: GRCh38)
     * @return VEP annotation response
     */
    @POST
    @Path("/{species}/hgvs")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    VepApiResponse annotateSequence(
        @QueryParam("content") String sequence,
        @PathParam("species") @DefaultValue("human") String species,
        @QueryParam("assembly") @DefaultValue("GRCh38") String assembly
    );

    /**
     * Asynchronous variant annotation
     */
    @POST
    @Path("/{species}/hgvs")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    CompletionStage<VepApiResponse> annotateSequenceAsync(
        @QueryParam("content") String sequence,
        @PathParam("species") @DefaultValue("human") String species,
        @QueryParam("assembly") @DefaultValue("GRCh38") String assembly
    );

    /**
     * Get VEP service information
     */
    @GET
    @Path("/info/{species}")
    @Produces(MediaType.APPLICATION_JSON)
    VepServiceInfo getServiceInfo(@PathParam("species") @DefaultValue("human") String species);

    /**
     * Health check endpoint
     */
    @GET
    @Path("/ping")
    @Produces(MediaType.TEXT_PLAIN)
    String ping();
}
