#include "ReShadeCMS.fxh"

namespace ReShadeCMS {
namespace ToneMapping {

#define MAPPING_SPACE_ICTCP  0
#define MAPPING_SPACE_YRGB   1
#define MAPPING_SPACE_RGB    2
#define MAPPING_SPACE_MAXRGB 3

uniform uint mappingSpace <ui_type = "combo";
                           ui_items = "ICtCp\0"
                                      "YRGB\0"
                                      "R'G'B'\0"
                                      "maxRGB\0";
                           ui_label = "Mapping Space";
                           > = MAPPING_SPACE_ICTCP;

#if !defined(RESHADECMS_DEFAULT_DISPLAY_WHITE)
	#define RESHADECMS_DEFAULT_DISPLAY_WHITE 1000.0
#endif

uniform float dstPeak <ui_type = "slider";
                            ui_min = 80.0;
                            ui_step = 1.0;
                            ui_max = 10000.0;
                            ui_label = "Peak White";
                            ui_category = "Display Settings";
                            ui_units = " nits";
                            > = RESHADECMS_DEFAULT_DISPLAY_WHITE;

#if !defined(RESHADECMS_DEFAULT_DISPLAY_BLACK)
	#define RESHADECMS_DEFAULT_DISPLAY_BLACK 0.0
#endif

uniform float dstBlack <ui_type = "slider";
                            ui_min = 0.0;
                            ui_step = 0.0001;
                            ui_max = 1.0;
                            ui_label = "Black Level";
                            ui_category = "Display Settings";
                            ui_units = " nits";
                            > = RESHADECMS_DEFAULT_DISPLAY_BLACK;

uniform float srcPeak <ui_type = "slider";
                            ui_min = 80.0;
                            ui_step = 1.0;
                            ui_max = 10000.0;
                            ui_label = "Peak White";
                            ui_category = "Content Settings";
                            ui_units = " nits";
                            > = 4000.0;

uniform float srcBlack <ui_type = "slider";
                            ui_min = 0.0;
                            ui_step = 0.0001;
                            ui_max = 1.0;
                            ui_label = "Black Level";
                            ui_category = "Content Settings";
                            ui_units = " nits";
                            > = 0.0;

float3 staticToneMap(float4 pos : SV_POSITION,
                     float2 texcoord : TexCoord) : SV_Target
{
	float3 rgb = tex2Dfetch(ReShade::BackBuffer, pos.xy).rgb;

	rgb = Buffer::linearize(rgb);
	
	if (BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB)
		rgb = BT709::toBT2020(rgb);

	rgb = Buffer::normalizeTo(rgb, COLOUR_SPACE_PQ);
	
	switch (mappingSpace) {
	case MAPPING_SPACE_ICTCP:
		float3 iCtCp = LMS::PQ::toICtCp(RGB::toLMS(rgb));
		iCtCp = inICtCp(iCtCp, dstPeak, dstBlack, srcPeak, srcBlack);
		rgb = LMS::toRGB(ICtCp::PQ::toLMS(iCtCp));
		break;
	case MAPPING_SPACE_YRGB:
		rgb = inYRGB(rgb, dstPeak, dstBlack, srcPeak, srcBlack);
		break;
	case MAPPING_SPACE_RGB:
		rgb = BT2100::PQ::EOTF(inNlRGB(BT2100::PQ::iEOTF(rgb),
		                               dstPeak, dstBlack,
		                               srcPeak, srcBlack));
		break;
	case MAPPING_SPACE_MAXRGB:
		rgb = inMaxRGB(rgb, dstPeak, dstBlack, srcPeak, srcBlack);
		break;
	default:
		break;
	}

	rgb = Buffer::normalizeFrom(rgb, COLOUR_SPACE_PQ);

	if (BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB)
		rgb = BT2020::toBT709(rgb);

	rgb = Buffer::unlinearize(rgb);

	return rgb;
}

#if defined(BUFFER_IS_HDR)
technique staticToneMap <ui_label = "BT.2408 Tone Mapping"; >
{
	pass p0
	{
		VertexShader = PostProcessVS;
		PixelShader = staticToneMap;
	}
}
#endif

} // namespace ToneMapping
} // namespace ReShadeCMS

// vim: filetype=shaderslang
