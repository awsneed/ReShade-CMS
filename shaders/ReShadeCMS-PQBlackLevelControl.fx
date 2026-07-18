#include "ReShadeCMS.fxh"

namespace ReShadeCMS {
namespace BlackLevelControl {

#if !defined(RESHADECMS_DEFAULT_DISPLAY_WHITE)
	#define RESHADECMS_DEFAULT_DISPLAY_WHITE 1000.0
#endif

uniform float peak <ui_type = "slider";
                    ui_min = 80.0;
                    ui_step = 1.0;
                    ui_max = 10000.0;
                    ui_label = "Peak White";
                    ui_units = " nits";
                    > = RESHADECMS_DEFAULT_DISPLAY_WHITE;

#if !defined(RESHADECMS_DEFAULT_DISPLAY_BLACK)
	#define RESHADECMS_DEFAULT_DISPLAY_BLACK 0.0
#endif

uniform float black <ui_type = "slider";
                     ui_min = 0.0;
                     ui_step = 0.0001;
                     ui_max = 5.0;
                     ui_label = "Black Level";
                     ui_units = " nits";
                     > = RESHADECMS_DEFAULT_DISPLAY_BLACK;

// Applies the BT.814 PQ black level adjustment for non-reference viewing
// environments. Should be paired with a PLUGE black level pattern to set
// correctly.
float3 blackLevelControl(float4 pos : SV_POSITION,
                         float2 texcoord : TexCoord) : SV_Target
{
	float3 rgb = tex2Dfetch(ReShade::BackBuffer, pos.xy).rgb;
	
	if (BUFFER_COLOR_SPACE != COLOUR_SPACE_PQ)
		rgb = Buffer::linearize(rgb);
	if (BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB)
		rgb = BT709::toBT2020(rgb);
	if (BUFFER_COLOR_SPACE != COLOUR_SPACE_PQ) {
		rgb = Buffer::normalizeTo(rgb, COLOUR_SPACE_PQ);
		rgb = BT2100::PQ::iEOTF(rgb);
	}

	float nlLm = BT2100::PQ::iEOTF(peak / BT2100::PQ::peak);
	float nlB = BT2100::PQ::iEOTF(black / BT2100::PQ::peak);
	float a = 1.0 - nlB / nlLm;

	rgb = max(0.0, a * rgb + nlB);

	if (BUFFER_COLOR_SPACE != COLOUR_SPACE_PQ) {
		rgb = BT2100::PQ::EOTF(rgb);
		rgb = Buffer::normalizeFrom(rgb, COLOUR_SPACE_PQ);
	}
	if (BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB)
		rgb = BT2020::toBT709(rgb);
	if (BUFFER_COLOR_SPACE != COLOUR_SPACE_PQ)
		rgb = Buffer::unlinearize(rgb);
	
	return rgb;
}

technique blackLevelControl <ui_label = "PQ Black Level Control"; >
{
	pass p0
	{
		VertexShader = PostProcessVS;
		PixelShader = blackLevelControl;
	}
}

} // namespace ReShadeCMS::BlackLevelControl
} // namespace ReShadeCMS

// vim: filetype=shaderslang
