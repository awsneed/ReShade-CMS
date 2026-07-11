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
                     ui_min = 1.000;
                     ui_step = 0.001;
                     ui_max = 1.2;
                     ui_label = "Adjustment Power";
                     > = 1.155;

/* TODO: Make this the main gamma correction formula here or elsewhere, then
 * edit SDR Direct Map to call this instead of doing it's own version */
float3 correctGamma(float4 pos : SV_POSITION,
                    float2 texcoord : TexCoord) : SV_Target
{
	float3 colour = tex2Dfetch(ReShade::BackBuffer, pos.xy).rgb;

	#if BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
	colour = BT709::toBT2020(colour);
	colour /= diffuseWhite / sRGB::whiteLevel;
	float oldY = BT709::deriveY(colour);
	#elif BUFFER_COLOR_SPACE == COLOUR_SPACE_PQ
	colour *= BT2100::PQ::peakWhite / BT1886::whiteLevel;
	colour /= diffuseWhite / BT1886::whiteLevel;
	float oldY = BT2100::deriveY(colour);
	#elif BUFFER_COLOR_SPACE == COLOUR_SPACE_HLG
	colour *= BT2100::HLG::peakWhite / BT1886::whiteLevel;
	colour /= diffuseWhite / BT1886::whiteLevel;
	float oldY = BT2100::deriveY(colour);
	#endif

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
