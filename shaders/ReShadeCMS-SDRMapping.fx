#include "ReShadeCMS.fxh"

namespace ReShadeCMS {
namespace SDRMapping {

#if !defined(RESHADECMS_DEFAULT_DIFFUSE_WHITE)
	#define RESHADECMS_DEFAULT_DIFFUSE_WHITE 203.0
#endif

uniform float diffuse <ui_type = "slider";
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
	float3 rgb = tex2Dfetch(ReShade::BackBuffer, pos.xy).rgb;
	
	rgb = BT709::toBT2020(rgb);
	
	float y = BT2100::deriveY(rgb);
	float newY = (diffuse / scRGB::diffuse) * (gammaEnabled ? sPow(y, gamma)
	                                                        : y);
	float scale = y != 0.0 ? newY / y : y;
	rgb *= scale;

	#if BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
	rgb = BT2020::toBT709(rgb);
	#elif BUFFER_COLOR_SPACE == COLOUR_SPACE_PQ
	rgb /= BT2100::PQ::peak / BT1886::diffuse;
	#endif

	return rgb;
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
