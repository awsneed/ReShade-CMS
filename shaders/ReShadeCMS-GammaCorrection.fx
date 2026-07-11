#include "ReShadeCMS.fxh"

namespace ReShadeCMS {
namespace GammaCorrection {

#if defined(BUFFER_IS_HDR)
uniform float diffuseWhite <ui_type = "slider";
                            ui_min = 1.0;
                            ui_step = 1.0;
                            ui_max = 405.0;
                            ui_label = "Diffuse White";
                            ui_units = " nits";
                            ui_tooltip = "Input diffuse white level.";
                            > = 203.0;
#else
static const float diffuseWhite = 100.0;
#endif

uniform float gamma <ui_type = "slider";
                     ui_min = 0.155;
                     ui_step = 0.001;
                     ui_max = 2.155;
                     ui_label = "Adjustment Power";
                     > = 1.155;

/* TODO: Make this the main gamma correction formula here or elsewhere, then
 * edit SDR Direct Map to call this instead of doing it's own version */
float3 correctGamma(float4 pos : SV_POSITION,
                    float2 texcoord : TexCoord) : SV_Target
{
	float3 colour = tex2Dfetch(ReShade::BackBuffer, pos.xy).rgb;

	float normScale = diffuseWhite;
	#if BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
	normScale /= sRGB::whiteLevel;
	colour = BT709::toBT2020(colour);
	#elif BUFFER_COLOR_SPACE == COLOUR_SPACE_PQ
	normScale /= BT2100::PQ::peakWhite;
	#elif BUFFER_COLOR_SPACE == COLOUR_SPACE_HLG
	normScale /= BT2100::HLG::peakWhite;
	#endif

	colour *= normScale;

	float Y = BT2100::deriveY(colour);
	float newY = sign(Y) * pow(abs(Y), gamma);
	float scale = Y != 0.0 ? newY / Y : 0.0;
	colour *= scale;

	colour /= normScale;

	#if BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
	colour = BT2020::toBT709(colour);
	colour = clamp(colour, -125.0, 125.0);
	#endif

	return colour;
}

technique correctGamma <ui_label = "Gamma Correction"; >
{
	pass p0
	{
		VertexShader = PostProcessVS;
		PixelShader = correctGamma;
	}
}

} // namespace SdrMapping
} // namespace ReShadeCMS

// vim: filetype=shaderslang
