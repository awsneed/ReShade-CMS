#include "reshade-cms.fxh"

namespace SDRInHDR {
    uniform float gamma <
        ui_type = "slider";
        ui_min = 0.055;
        ui_step = 0.001;
        ui_max = 2.255;
        ui_label = "Gamma Adjustment";
        ui_category = "SDR -> HDR Settings";
    > = 1.155;

    float3 ps(
        float4 pos : SV_POSITION,
        float2 texcoord : TexCoord
    ) : SV_Target {
        float3 colour = tex2D(ReShade::BackBuffer, texcoord).rgb;

        colour = Content::toLinear(BT709::toBT2020(colour));

        switch (BUFFER_COLOR_SPACE) {
        case COLOUR_SPACE_SCRGB:
            colour /= PQ::peakWhite / sRGB::whiteLevel;
            colour *= 
                pow(Display::diffuseWhite / sRGB::whiteLevel, 1.0 / SDRInHDR::gamma)
                * pow(sRGB::whiteLevel / PQ::peakWhite,
                        (1.0 - SDRInHDR::gamma) / SDRInHDR::gamma);
            break;
        case COLOUR_SPACE_PQ:
        default:
            colour *= 
                pow(Display::diffuseWhite / BT1886::whiteLevel, 1.0 / SDRInHDR::gamma)
                * pow(BT1886::whiteLevel / PQ::peakWhite,
                        (1.0 - SDRInHDR::gamma) / SDRInHDR::gamma);
            break;
        }

        colour = sign(colour) * pow(abs(colour), SDRInHDR::gamma);

        switch (BUFFER_COLOR_SPACE) {
        case COLOUR_SPACE_SCRGB:
            colour = clamp(colour, -1.0, 1.0);
            colour *= PQ::peakWhite / sRGB::whiteLevel;
            break;
        case COLOUR_SPACE_PQ:
            break;
        default:
            break;
        }

        colour = Content::toLinear(BT2020::toBT709(Content::toNonlinear(colour)));

        return colour;
    }
} // namespace SDRInHDR

namespace Tonemapping {
    float3 ps(
        float4 pos : SV_POSITION,
        float2 texcoord : TexCoord
    ) : SV_Target {
        float3 colour = tex2D(ReShade::BackBuffer, texcoord).rgb;

        switch (BUFFER_COLOR_SPACE) {
        case COLOUR_SPACE_SCRGB:
            colour = Content::toLinear(
                BT709::toBT2020(Content::toNonlinear(colour)));
            colour /= PQ::peakWhite / sRGB::whiteLevel;
            break;
        default:
            break;
        }

        // TODO: Add switch logic for different methods.
        colour = ICtCp::PQ::decode(
            Tonemapping::inICtCp(
                ICtCp::PQ::encode(colour)
            )
        );

        switch (BUFFER_COLOR_SPACE) {
        case COLOUR_SPACE_SCRGB:
            colour *= PQ::peakWhite / sRGB::whiteLevel;
            colour = Content::toLinear(
                BT2020::toBT709(Content::toNonlinear(colour)));
            break;
        default:
            break;
        }

        return colour;
    }
} // namespace Tonemapping

float3 TestPS(
    float4 pos : SV_POSITION,
    float2 texcoord : TexCoord
) : SV_Target {
    float3 colour = tex2D(ReShade::BackBuffer, texcoord).rgb;

    //return BT2020::toBT709(PQ::iEOTF(PQ::EOTF(BT709::toBT2020(colour))));
    //return PQ::iEOTF(PQ::EOTF(colour));

    // Testing round-trip BT709 -> BT2020 -> BT709;
    return Content::toLinear(BT2020::toBT709(BT709::toBT2020(Content::toNonlinear(colour))));

    // Testing round-trip BT1886
    //return BT1886::iEOTF(BT1886::EOTF(BT1886::EOTF(BT1886::iEOTF(colour))));
}

technique Test {
    pass p0 {
        VertexShader = PostProcessVS;
        PixelShader = TestPS;
    }
}

technique Tonemapping <
    ui_label = "BT.2408 Static Tonemapping";
> {
    pass p0 {
        VertexShader = PostProcessVS;
        PixelShader = Tonemapping::ps;
    }
}

technique SDRInHDR <
    ui_label = "BT.2408 SDR -> HDR";
> {
    pass p0 {
        VertexShader = PostProcessVS;
        PixelShader = SDRInHDR::ps;
    }
}

// vim: filetype=shaderslang ts=4 sts=4 sw=4
