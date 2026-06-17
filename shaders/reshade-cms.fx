#include "reshade-cms.fxh"

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
    float3 colour = tex2D(ReShade::BackBuffer, texcoord).rgb;

    // Display-referred mapping into PQ. Scene-referred is not compatible with
    // overbright bits in scRGB
    switch(Output::EOTF)
    {
        case OUTPUT_EOTF_SRGB:
            colour = sRGB::EOTF(colour);
            break;
        case OUTPUT_EOTF_GAMMA22:
            colour = Gamma22::EOTF(colour);
            break;
        case OUTPUT_EOTF_BT1886:
            colour = BT1886::EOTF(colour);
            break;
        case OUTPUT_EOTF_LINEAR:
        default:
            break;
    }

    switch (BUFFER_COLOUR_SPACE) {
    case COLOUR_SPACE_SCRGB:
        colour /= PQ::peak / sRGB::peak;
        colour *= 
            pow(Output::diffuse / sRGB::peak, 1.0 / SDRToHDR::gamma)
            * pow(sRGB::peak / PQ::peak,
                    (1.0 - SDRToHDR::gamma) / SDRToHDR::gamma);
        break;
    case COLOUR_SPACE_PQ:
    default:
        colour *= 
            pow(Output::diffuse / BT1886::peak, 1.0 / SDRToHDR::gamma)
            * pow(BT1886::peak / PQ::peak,
                    (1.0 - SDRToHDR::gamma) / SDRToHDR::gamma);
        break;
    }

    colour = sign(colour) * pow(abs(colour), SDRToHDR::gamma);

    switch (BUFFER_COLOUR_SPACE) {
    case COLOUR_SPACE_SCRGB:
        colour = min(colour,  1.0);
        colour = max(colour, -1.0);
        colour *= PQ::peak / sRGB::peak;
        break;
    case COLOUR_SPACE_PQ:
        break;
    default:
        break;
    }


    return colour;
}
} // namespace SDRToHDR

namespace Tonemapping {

float3 ps(float4 pos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float3 colour = tex2D(ReShade::BackBuffer, texcoord).rgb;

    switch (BUFFER_COLOUR_SPACE) {
    case COLOUR_SPACE_SCRGB:
        colour /= PQ::peak / sRGB::peak;
        break;
    default:
        break;
    }

    // TODO: Add BT.709 -> BT.2020 conversion before this, since it works in PQ
    colour = PQ::EOTF(Tonemapping::RGB(PQ::inverseEOTF(colour)));

    switch (BUFFER_COLOUR_SPACE) {
    case COLOUR_SPACE_SCRGB:
        colour *= PQ::peak / sRGB::peak;
        break;
    default:
        break;
    }


    return colour;
}
} // namespace Tonemapping

technique Tonemapping <
    ui_label = "BT.2408 Static Tonemapping";
>
{
    pass p0
    {
        VertexShader = PostProcessVS;
        PixelShader = Tonemapping::ps;
    }
}

technique SDRToHDR <
    ui_label = "BT.2408 SDR -> HDR";
>
{
    pass p0
    {
        VertexShader = PostProcessVS;
        PixelShader = SDRToHDR::ps;
    }
}

// vim: filetype=shaderslang ts=4 sts=4 sw=4
