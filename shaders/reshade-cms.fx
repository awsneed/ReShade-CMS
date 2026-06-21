#include "reshade-cms.fxh"

namespace SDRInHDR {
    uniform float gamma <
        ui_type = "slider";
        ui_min = 1.000;
        ui_step = 0.001;
        ui_max = 1.160;
        ui_label = "Gamma Adjustment";
        ui_category = "SDR -> HDR Settings";
    > = 1.155;

    float3 ps(
        float4 pos : SV_POSITION,
        float2 texcoord : TexCoord
    ) : SV_Target {
        float3 colour = tex2D(ReShade::BackBuffer, texcoord).rgb;

        if (Content::overrideEOTF == EOTF_NONE) {
            // TODO: Make this smarter. For now, assume sRGB
            colour = sRGB::iEOTF(colour);
        };
        colour = Content::toLinear(BT709::toBT2020(colour));

        float Y = dot(float3(0.2627, 0.6780, 0.0593), colour);
        float Y203 = (BT2100::diffuseWhite / scRGB::diffuseWhite)
            * (sign(Y) * pow(abs(Y), SDRInHDR::gamma));
        float scale = Y != 0.0 ? Y203 / Y : 0.0;
        colour *= scale;

        colour = Content::toLinear(BT2020::toBT709(Content::toNonlinear(colour)));

        switch (BUFFER_COLOR_SPACE) {
        case COLOUR_SPACE_PQ:
            break;
        case COLOUR_SPACE_SCRGB:
        default:
            colour = clamp(colour, -125.0, 125.0);
            break;
        }

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
