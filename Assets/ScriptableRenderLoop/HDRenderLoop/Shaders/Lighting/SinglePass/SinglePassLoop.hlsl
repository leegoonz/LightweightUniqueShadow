//-----------------------------------------------------------------------------
// LightLoop
// ----------------------------------------------------------------------------

// bakeDiffuseLighting is part of the prototype so a user is able to implement a "base pass" with GI and multipass direct light (aka old unity rendering path)
void LightLoop(	float3 V, float3 positionWS, PreLightData prelightData, BSDFData bsdfData, float3 bakeDiffuseLighting,
                out float4 diffuseLighting,
                out float4 specularLighting)
{
    LightLoopContext context;
    ZERO_INITIALIZE(LightLoopContext, context);

    diffuseLighting  = float4(0.0, 0.0, 0.0, 0.0);
    specularLighting = float4(0.0, 0.0, 0.0, 0.0);

    int i = 0; // Declare once to avoid the D3D11 compiler warning.

    for (i = 0; i < _PunctualLightCount; ++i)
    {
        float4 localDiffuseLighting, localSpecularLighting;

        EvaluateBSDF_Punctual(context, V, positionWS, prelightData, _PunctualLightList[i], bsdfData,
                              localDiffuseLighting, localSpecularLighting);

        diffuseLighting  += localDiffuseLighting;
        specularLighting += localSpecularLighting;
    }

    for (i = 0; i < _AreaLightCount; ++i)
    {
        float4 localDiffuseLighting, localSpecularLighting;

        EvaluateBSDF_Area(context, V, positionWS, prelightData, _AreaLightList[i], bsdfData,
                          localDiffuseLighting, localSpecularLighting);

        diffuseLighting  += localDiffuseLighting;
        specularLighting += localSpecularLighting;
    }

    float4 iblDiffuseLighting  = float4(0.0, 0.0, 0.0, 0.0);
    float4 iblSpecularLighting = float4(0.0, 0.0, 0.0, 0.0);

    for (i = 0; i < _EnvLightCount; ++i)
    {
        float4 localDiffuseLighting, localSpecularLighting;
        context.sampleReflection = SINGLE_PASS_CONTEXT_SAMPLE_REFLECTION_PROBES;
        EvaluateBSDF_Env(context, V, positionWS, prelightData, _EnvLightList[i], bsdfData, localDiffuseLighting, localSpecularLighting);
        iblDiffuseLighting.rgb = lerp(iblDiffuseLighting.rgb, localDiffuseLighting.rgb, localDiffuseLighting.a); // Should be remove by the compiler if it is smart as all is constant 0
        iblSpecularLighting.rgb = lerp(iblSpecularLighting.rgb, localSpecularLighting.rgb, localSpecularLighting.a);
    }

    /*
    // Sky Ibl
    {
        float4 localDiffuseLighting, localSpecularLighting;
        context.sampleReflection = SINGLE_PASS_CONTEXT_SAMPLE_SKY;
        EvaluateBSDF_Env(context, V, positionWS, prelightData, _EnvLightSky, bsdfData, localDiffuseLighting, localSpecularLighting);
        iblDiffuseLighting.rgb = lerp(iblDiffuseLighting.rgb, localDiffuseLighting.rgb, localDiffuseLighting.a); // Should be remove by the compiler if it is smart as all is constant 0
        iblSpecularLighting.rgb = lerp(iblSpecularLighting.rgb, localSpecularLighting.rgb, localSpecularLighting.a);
    }
    */

    diffuseLighting  += iblDiffuseLighting;
    specularLighting += iblSpecularLighting;

    diffuseLighting.rgb += bakeDiffuseLighting;
}
