#include "color_management.fxh"

namespace SDRToHDR {
uniform float gamma <
    ui_type = "slider";
    ui_min = 0.055;
    ui_step = 0.001;
    ui_max = 2.255;
    ui_label = "Gamma Adjustment";
    ui_category = "SDR -> HDR Settings";
> = 1.155;

float3 ps(float4 pos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

    // Display-referred mapping into PQ. Scene-referred is not compatible with
    // overbright bits in scRGB
    switch(Output::EOTF)
    {
        case OUTPUT_EOTF_SRGB:
            color = sRGB::EOTF(color);
            break;
        case OUTPUT_EOTF_GAMMA22:
            color = Gamma22::EOTF(color);
            break;
        case OUTPUT_EOTF_BT1886:
            color = BT1886::EOTF(color);
            break;
        case OUTPUT_EOTF_LINEAR:
        default:
            break;
    }

    switch (BUFFER_COLOR_SPACE) {
    case COLOR_SPACE_SCRGB:
        color /= PQ::peak / sRGB::peak;
        color *= 
            pow(Output::diffuse / sRGB::peak, 1.0 / SDRToHDR::gamma)
            * pow(sRGB::peak / PQ::peak,
                    (1.0 - SDRToHDR::gamma) / SDRToHDR::gamma);
        break;
    case COLOR_SPACE_PQ:
    default:
        color *= 
            pow(Output::diffuse / BT1886::peak, 1.0 / SDRToHDR::gamma)
            * pow(BT1886::peak / PQ::peak,
                    (1.0 - SDRToHDR::gamma) / SDRToHDR::gamma);
        break;
    }

    color = sign(color) * pow(abs(color), SDRToHDR::gamma);

    switch (BUFFER_COLOR_SPACE) {
    case COLOR_SPACE_SCRGB:
        color *= PQ::peak / sRGB::peak;
        break;
    case COLOR_SPACE_PQ:
    default:
        break;
    }

    return color;
}
} // namespace SDRToHDR

namespace Tonemapping {

float3 ps(float4 pos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

    switch (BUFFER_COLOR_SPACE) {
    case COLOR_SPACE_SCRGB:
        color /= PQ::peak / sRGB::peak;
        break;
    default:
        break;
    }

    color = Tonemapping::RGB(color);

    switch (BUFFER_COLOR_SPACE) {
    case COLOR_SPACE_SCRGB:
        color *= PQ::peak / sRGB::peak;
        break;
    default:
        break;
    }


    return color;
}
} // namespace Tonemapping

technique Tonemapping <
    ui_label = "(EARLY WIP) Tonemapping";
>
{
    pass p0
    {
        VertexShader = PostProcessVS;
        PixelShader = Tonemapping::ps;
    }
}

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

// vim: filetype=shaderslang ts=4 sts=4 sw=4
