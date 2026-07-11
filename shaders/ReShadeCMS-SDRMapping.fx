#include "ReShadeCMS.fxh"

namespace ReShadeCMS {
namespace SDRMapping {

#if !defined(RESHADECMS_DEFAULT_DIFFUSE_WHITE)
	#define RESHADECMS_DEFAULT_DIFFUSE_WHITE 203.0
#endif

uniform float diffuseWhite <ui_type = "slider";
                            ui_min = 1.0;
                            ui_step = 1.0;
                            ui_max = 405.0;
                            ui_label = "Diffuse White";
                            ui_units = " nits";
                            > = RESHADECMS_DEFAULT_DIFFUSE_WHITE;

uniform bool gammaEnabled <ui_label = "Adjust Gamma"; > = true;

uniform float gamma <ui_type = "slider";
                     ui_min = 1.000;
                     ui_step = 0.001;
                     ui_max = 1.2;
                     ui_label = "Power";
                     > = 1.155;

float3 directMapPS(float4 pos : SV_POSITION,
                   float2 texcoord : TexCoord) : SV_Target
{
	float3 colour = tex2Dfetch(ReShade::BackBuffer, pos.xy).rgb;
	
	colour = BT709::toBT2020(colour);
	
	float Y = BT2100::deriveY(colour);
	float Y203 = (diffuseWhite / scRGB::diffuseWhite)
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

#if BUFFER_COLOR_SPACE != COLOUR_SPACE_SRGB
technique directMap <ui_label = "Direct-Map SDR"; >
{
	pass p0
	{
		VertexShader = PostProcessVS;
		PixelShader = directMapPS;
	}
}
#endif

} // namespace SDRMapping
} // namespace ReShadeCMS

// vim: filetype=shaderslang
