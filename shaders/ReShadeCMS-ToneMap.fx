#include "ReShadeCMS.fxh"

namespace ReShadeCMS
{
namespace ToneMapping
{

float3 toneMap(
    float4 pos : SV_POSITION,
    float2 texcoord : TexCoord
) : SV_Target
{
    float3 colour = tex2D(ReShade::BackBuffer, texcoord).rgb;

    #if BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
    colour = BT709::toBT2020(colour);
    colour /= BT2100::PQ::peakWhite / sRGB::whiteLevel;
    #endif

    colour = 
        LMS::toRGB(
            ICtCp::PQ::toLMS(
                ToneMapping::inICtCp(
            LMS::PQ::toICtCp(
        RGB::toLMS(colour)))));

    #if BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
    colour = BT2020::toBT709(colour);
    colour *= BT2100::PQ::peakWhite / sRGB::whiteLevel;
    #endif

    return colour;
}

technique toneMap <
    ui_label = "Static Tone Mapping";
>
{
    pass p0
    {
        VertexShader = PostProcessVS;
        PixelShader = toneMap;
    }
}

} // namespace ToneMapping
} // namespace ReShadeCMS

// vim: filetype=shaderslang ts=4 sts=4 sw=4
