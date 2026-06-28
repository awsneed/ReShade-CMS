#include "ReShadeCMS.fxh"

namespace ReShadeCMS
{
namespace GammaCorrection
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
#else
static const LinearColour diffuseWhite = 100.0;
#endif

uniform float gamma <
    ui_type = "slider";
    ui_min = 1.000;
    ui_step = 0.001;
    ui_max = 1.2;
    ui_label = "Adjustment Power";
> = 1.155;

float3 correctGammaPS(
    float4 pos : SV_POSITION,
    float2 texcoord : TexCoord) : SV_Target
{
    float3 colour = tex2D(ReShade::BackBuffer, texcoord).rgb;

    #if defined(BUFFER_IS_HDR)
    // Return to SDR nits as if it had been mapped up
    #if BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
    colour = BT709::toBT2020(colour);
    colour /= diffuseWhite / sRGB::whiteLevel;
    #elif BUFFER_COLOR_SPACE == COLOUR_SPACE_PQ
    colour *= BT2100::PQ::peakWhite / BT1886::whiteLevel;
    colour /= diffuseWhite / BT1886::whiteLevel;
    #elif BUFFER_COLOR_SPACE == COLOUR_SPACE_HLG
    colour *= BT2100::HLG::peakWhite / BT1886::whiteLevel;
    colour /= diffuseWhite / BT1886::whiteLevel;
    #endif

    // TODO: Look into if I from ICtCp would be better over Y from YRGB.
    float oldY = dot(float3(0.2627, 0.6780, 0.0593), colour);

    float newY = (diffuseWhite / 
        #if BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
        scRGB::diffuseWhite
        #else
        BT1886::whiteLevel
        #endif
        ) * (sign(oldY) * pow(abs(oldY), gamma));
    float scale = oldY != 0.0 ? newY / oldY : 0.0;
    colour *= scale;

    #if BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
    colour = BT2020::toBT709(colour);
    colour = clamp(colour, -125.0, 125.0);
    #elif BUFFER_COLOR_SPACE == COLOUR_SPACE_PQ
    colour /= BT2100::PQ::peakWhite / BT1886::whiteLevel;
    #endif

    #else // SDR
    colour = pow(colour, gamma);
    #endif

    return colour;
}

technique correctGamma <
    ui_label = "Gamma Correction";
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
