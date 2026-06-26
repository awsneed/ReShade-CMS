#include "ReShadeCMS.fxh"

namespace ReShadeCMS
{
namespace HDRGammaCorrection
{
uniform LinearColour diffuseWhite <
    ui_type = "slider";
    ui_min = 1.0;
    ui_step = 1.0;
    ui_max = 405.0;
    ui_label = "Diffuse White";
    ui_units = " nits";
    ui_tooltip = "The game's diffuse white level.";
> = 203.0;

uniform float gamma <
    ui_type = "slider";
    ui_min = 1.000;
    ui_step = 0.001;
    ui_max = 1.2;
    ui_label = "Gamma Power";
> = 1.155;

float3 correctGammaPS(
    float4 pos : SV_POSITION,
    float2 texcoord : TexCoord
) : SV_Target
{
    float3 colour = tex2D(ReShade::BackBuffer, texcoord).rgb;

    // Return to SDR nits as if it had been mapped up
    #if BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
    colour = BT709::toBT2020(colour);
    colour /= diffuseWhite / sRGB::whiteLevel;
    #elif BUFFER_COLOR_SPACE == COLOUR_SPACE_PQ
    colour *= BT2100::PQ::peakWhite / BT1886::whiteLevel;
    colour /= diffuseWhite / BT1886::whiteLevel;
    #endif

    float Y = dot(float3(0.2627, 0.6780, 0.0593), colour);

    #if BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
    float Y203 = (diffuseWhite / scRGB::diffuseWhite)
    #else
    float Y203 = (diffuseWhite / BT1886::whiteLevel)
    #endif
        * (sign(Y) * pow(abs(Y), gamma));
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

technique correctGamma <
    ui_label = "HDR Gamma Correction";
>
{
    pass p0
    {
        VertexShader = PostProcessVS;
        PixelShader = correctGammaPS;
    }
}

} // namespace SdrMapping
} // namespace ReShadeCMS

// vim: filetype=shaderslang ts=4 sts=4 sw=4
