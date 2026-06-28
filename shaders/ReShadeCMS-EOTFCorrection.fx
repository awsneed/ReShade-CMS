#include "ReShadeCMS.fxh"

namespace ReShadeCMS
{
namespace EOTFCorrection
{
#if defined(BUFFER_IS_HDR)
uniform LinearColour diffuseWhite <
    ui_type = "slider";
    ui_min = 1.0;
    ui_step = 1.0;
    ui_max = 405.0;
    ui_label = "Diffuse White";
    ui_units = " nits";
    ui_tooltip = "Input diffuse white level.";
> = 203.0;
#endif

uniform uint oldEOTF <
    ui_type = "combo";
    ui_items = 
        "None \0"
        "sRGB \0"
        "Gamma 2.2 \0"
        "BT.1886 \0"
        #if defined(BUFFER_IS_HDR)
        "PQ \0"
        "HLG \0"
        #endif
        ;
    ui_label = "Original EOTF";
#if BUFFER_COLOR_SPACE == COLOUR_SPACE_PQ
> = EOTF_PQ;
#elif BUFFER_COLOR_SPACE == COLOUR_SPACE_HLG
> = EOTF_HLG;
#else
> = EOTF_SRGB;
#endif

uniform uint newEOTF <
    ui_type = "combo";
    ui_items = 
        "None \0"
        "sRGB \0"
        "Gamma 2.2 \0"
        "BT.1886 \0"
        #if defined(BUFFER_IS_HDR)
        "PQ \0"
        "HLG \0"
        #endif
        ;
    ui_label = "Override EOTF";
#if BUFFER_COLOR_SPACE == COLOUR_SPACE_PQ
> = EOTF_PQ;
#elif BUFFER_COLOR_SPACE == COLOUR_SPACE_HLG
> = EOTF_HLG;
#else
> = EOTF_SRGB;
#endif

float3 correctEOTFPS(
    float4 pos : SV_POSITION,
    float2 texcoord : TexCoord) : SV_Target
{
    float3 colour = tex2D(ReShade::BackBuffer, texcoord).rgb;

    if (oldEOTF == newEOTF)
    {
        return colour;
    }

    #if defined(BUFFER_IS_HDR)
    switch (oldEOTF)
    {
        case EOTF_SRGB:
        case EOTF_G22:
        case EOTF_BT1886:
            colour = scaleTo(colour, diffuseWhite);
            break;
        case EOTF_PQ:
        case EOTF_HLG:
        case EOTF_NONE:
        default:
            break;
    }
    #endif

    /* TODO: Probably need some special adjustment from PQ to HLG? */
    colour = useIEOTF(colour, oldEOTF);
    colour = useEOTF(colour, newEOTF);
    
    #if defined(BUFFER_IS_HDR)
    switch (newEOTF)
    {
        case EOTF_SRGB:
        case EOTF_G22:
        case EOTF_BT1886:
            colour = scaleFrom(colour, diffuseWhite);
            break;
        case EOTF_PQ:
        case EOTF_HLG:
        case EOTF_NONE:
        default:
            break;
    }
    #else
    colour = sRGB::iEOTF(colour);
    #endif

    return colour;
}

technique correctEOTF <
    ui_label = "EOTF Correction";
>
{
    pass p0
    {
        VertexShader = PostProcessVS;
        PixelShader = correctEOTFPS;
    }
}

} // namespace EOTFCorrection
} // namespace ReShadeCMS
// vim: filetype=shaderslang ts=4 sts=4 sw=4
