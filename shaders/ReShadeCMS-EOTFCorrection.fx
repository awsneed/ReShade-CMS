#include "ReShadeCMS.fxh"

namespace ReShadeCMS
{
namespace EOTFCorrection
{
uniform uint oldEOTF <
    ui_type = "combo";
    ui_items = 
        "None \0"
        "sRGB \0"
        "Gamma 2.2 \0"
        "BT.1886 \0"
        "PQ \0"
        "HLG \0";
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
        "PQ \0"
        "HLG \0";
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
    float2 texcoord : TexCoord
) : SV_Target
{
    float3 colour = tex2D(ReShade::BackBuffer, texcoord).rgb;

    if (oldEOTF != newEOTF)
    {
        colour = useIEOTF(colour, oldEOTF);
        colour = useEOTF(colour, newEOTF);
    }

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
