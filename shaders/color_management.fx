#include "ReShade.fxh"
#include "color_management.fxh"

namespace SDRToHDR {
uniform float gamma <
    ui_type = "slider";
    ui_min = 0.001;
    ui_step = 0.001;
    ui_max = 2.400;
    ui_label = "Gamma Adjustment";
    ui_category = "SDR -> HDR Settings";
> = 1.155;

float4 ps(float4 pos : SV_Position) : SV_TARGET
{
    float4 color = tex2Dfetch(ReShade::BackBuffer, pos.xy);

    // NOTE: Using scRGB output with Special K, 1.0 = 80 nits. So, where are we
    // in the process? Switching all the functions to output [0.0, 1.0]
    // normalized values is probably best for right now.

    // Decode back to scene light
    switch(Content::encoding)
    {
        case CONTENT_ENCODING_SRGB:
        case CONTENT_ENCODING_BT1886:
        case CONTENT_ENCODING_GAMMA22:
            color.rgb = Rec709::inverseOETF(color.rgb);
            break;
        case CONTENT_ENCODING_PQ:
            color.rgb = PQ::inverseOETF(color.rgb);
            break;
        case CONTENT_ENCODING_HLG:
            color.rgb = HLG::inverseOETF(color.rgb);
            break;
        case CONTENT_ENCODING_LINEAR:
        default:
            break;
    }

    // SDR to HDR adjustment perceptually match SDR when scaling up.
    // See BT.2048 for details.
    color.rgb = pow(color.rgb, SDRToHDR::gamma);

    // Encode back to nonlinear
    switch(Content::encoding)
    {
        case CONTENT_ENCODING_SRGB:
        case CONTENT_ENCODING_BT1886:
        case CONTENT_ENCODING_GAMMA22:
            color.rgb = Rec709::OETF(color.rgb);
            break;
        case CONTENT_ENCODING_PQ:
            color.rgb = PQ::OETF(color.rgb);
            break;
        case CONTENT_ENCODING_HLG:
            color.rgb = HLG::OETF(color.rgb);
            break;
        case CONTENT_ENCODING_LINEAR:
        default:
            break;
    }

    // Encode to normalized display light
    switch(Content::encoding)
    {
        case CONTENT_ENCODING_SRGB:
            color.rgb = sRGB::EOTF(color.rgb);
            break;
        case CONTENT_ENCODING_BT1886:
            color.rgb = BT1886::EOTF(color.rgb);
            break;
        case CONTENT_ENCODING_GAMMA22:
            color.rgb = Gamma22::EOTF(color.rgb);
            break;
        case CONTENT_ENCODING_PQ:
            color.rgb = PQ::EOTF(color.rgb);
            break;
        case CONTENT_ENCODING_HLG:
            //color.rgb = HLG::EOTF(color.rgb);
            break;
        case CONTENT_ENCODING_LINEAR:
        default:
            break;
    }

    // Scale to output diffuse white
    color.rgb *= Output::diffuseWhite;

    // Normalize output to scRGB's 1.0 = 80 nits.
    color.rgb /= sRGB::white;

    return color;
}
} // namespace MapSDR


technique SDRToHDR <
    ui_label = "SDR -> HDR";
>
{
    pass p0
    {
        VertexShader = PostProcessVS;
        PixelShader = SDRToHDR::ps;
    }
}

// vim: filetype=glsl ts=4 sts=4 sw=4
