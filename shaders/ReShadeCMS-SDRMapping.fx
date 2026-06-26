#include "ReShadeCMS.fxh"

namespace ReShadeCMS
{
namespace SDRMapping
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

    /* First, let's go ahead and get the content to Display Linear light. How do
     * we always ensure that happens?
     * a. Forced to scRGB and is in nonlinear BT601/BT709/BT2020 light (common).
     * b. Forced to scRGB and is in linear light already (uncommon).
     * c. Forced to HDR10, unkown linear/nonlinear.
     */
    
    if (Content::oldEOTF != Content::newEOTF)
    {
        colour = Content::toOldIEOTF(colour);
        colour = Content::toNewEOTF(colour);
    }

    colour = BT709::toBT2020(colour);

    float Y = dot(float3(0.2627, 0.6780, 0.0593), colour);
    float Y203 = (Output::diffuseWhite / scRGB::diffuseWhite)
        * (gammaEnabled ? (sign(Y) * pow(abs(Y), gamma)) : abs(Y));
    float scale = Y != 0.0 ? Y203 / Y : 0.0;
    colour *= scale;

    #if BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
    colour = BT2020::toBT709(colour);
    colour = clamp(colour, -125.0, 125.0);
    #elif BUFFER_COLOR_SPACE == COLOUR_SPACE_PQ
    colour /= BT2100::PQ::peakWhite / BT1886::whiteLevel;
    #endif

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

} // namespace SdrMapping
} // namespace ReShadeCMS

// vim: filetype=shaderslang ts=4 sts=4 sw=4
