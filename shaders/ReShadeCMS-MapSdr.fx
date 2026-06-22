#include "ReShadeCMS.fxh"

namespace ReShadeCMS { namespace SDRMapping
{

uniform bool gammaEnabled <
    ui_tooltip = "When scaling SDR from 100 nits to 203 nits, an adjustment of "
        "1.15 - 1.16 is recommended to preserve the look of shadows and midtones.";
    ui_label = "Adjust Gamma";
> = true;

uniform float gamma <
    ui_type = "slider";
    ui_min = 1.000;
    ui_step = 0.001;
    ui_max = 1.2;
    ui_label = "Gamma Power";
> = 1.155;

float3 directMap(
    float4 pos : SV_POSITION,
    float2 texcoord : TexCoord
) : SV_Target
{
    float3 colour = tex2D(ReShade::BackBuffer, texcoord).rgb;

    if (Content::newEOTF == EOTF_NONE)
    {
        // TODO: Make this smarter. For now, assume sRGB
        colour = sRGB::iEOTF(colour);
    };
    colour = Content::EOTF(BT709::toBT2020(colour));

    float Y = dot(float3(0.2627, 0.6780, 0.0593), colour);
    float Y203 = (BT2100::diffuseWhite / scRGB::diffuseWhite)
        * (gammaEnabled ? (sign(Y) * pow(abs(Y), gamma)) : 1.0);
    float scale = Y != 0.0 ? Y203 / Y : 0.0;
    colour *= scale;

    colour = Content::EOTF(BT2020::toBT709(Content::iEOTF(colour)));

    switch (BUFFER_COLOR_SPACE)
    {
    case COLOUR_SPACE_PQ:
        break;
    case COLOUR_SPACE_SCRGB:
    default:
        colour = clamp(colour, -125.0, 125.0);
        break;
    }

    return colour;
}

technique directMap <
    ui_label = "Direct-Map SDR";
>
{
    pass p0
    {
        VertexShader = PostProcessVS;
        PixelShader = directMap;
    }
}

}} // namespace ReShadeCMS::SdrMapping

// vim: filetype=shaderslang ts=4 sts=4 sw=4
