#include "ReShadeCMS.fxh"

namespace ReShadeCMS { namespace ToneMapping
{

float3 toneMap(
    float4 pos : SV_POSITION,
    float2 texcoord : TexCoord
) : SV_Target
{
    float3 colour = tex2D(ReShade::BackBuffer, texcoord).rgb;

    switch (BUFFER_COLOR_SPACE)
    {
    case COLOUR_SPACE_SCRGB:
        colour = Content::EOTF(
            BT709::toBT2020(Content::iEOTF(colour)));
        colour /= BT2100::PQ::peakWhite / sRGB::whiteLevel;
        break;
    default:
        break;
    }

    // TODO: Add switch logic for different methods.
    // TODO: Fix for new naming conventions
    /*
    colour = ICtCp::PQ::decode(
        ToneMapping::inICtCp(
            ICtCp::PQ::encode(colour)
        )
    );
    */

    switch (BUFFER_COLOR_SPACE)
    {
    case COLOUR_SPACE_SCRGB:
        colour *= BT2100::PQ::peakWhite / sRGB::whiteLevel;
        colour = Content::EOTF(
            BT2020::toBT709(Content::iEOTF(colour)));
        break;
    default:
        break;
    }

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

}} // namespace ReShadeCMS::ToneMapping

// vim: filetype=shaderslang ts=4 sts=4 sw=4
