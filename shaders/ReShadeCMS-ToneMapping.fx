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

uniform float displayWhite <ui_type = "slider";
                            ui_min = 80.0;
                            ui_step = 1.0;
                            ui_max = 10000.0;
                            ui_label = "Peak White";
                            ui_category = "Output Settings";
                            ui_units = " nits";
                            > = RESHADECMS_DEFAULT_DISPLAY_WHITE;

#if !defined(RESHADECMS_DEFAULT_DISPLAY_BLACK)
	#define RESHADECMS_DEFAULT_DISPLAY_BLACK 0.0
#endif

uniform float displayBlack <ui_type = "slider";
                            ui_min = 0.0;
                            ui_step = 0.0001;
                            ui_max = 1.0;
                            ui_label = "Black Level";
                            ui_category = "Output Settings";
                            ui_units = " nits";
                            > = RESHADECMS_DEFAULT_DISPLAY_BLACK;

uniform float contentWhite <ui_type = "slider";
                            ui_min = 80.0;
                            ui_step = 1.0;
                            ui_max = 10000.0;
                            ui_label = "Peak White";
                            ui_category = "Content Settings";
                            ui_units = " nits";
                            > = 4000.0;

uniform float contentBlack <ui_type = "slider";
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
	float3 colour = tex2Dfetch(ReShade::BackBuffer, pos.xy).rgb;
	
	#if BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
	colour = BT709::toBT2020(colour);
	colour /= BT2100::PQ::peakWhite / sRGB::whiteLevel;
	#endif
	
	switch (mappingSpace) {
	case MAPPING_SPACE_ICTCP:
		colour = RGB::toLMS(colour);
		
		#if BUFFER_COLOR_SPACE == COLOUR_SPACE_HLG
		colour = LMS::HLG::toICtCp(colour);
		#else
		colour = LMS::PQ::toICtCp(colour);
		#endif
		
		colour = inICtCp(colour, displayWhite, displayBlack,
		                         contentWhite, contentBlack);
		
		#if BUFFER_COLOR_SPACE == COLOUR_SPACE_HLG
		colour = ICtCp::HLG::toLMS(colour);
		#else
		colour = ICtCp::PQ::toLMS(colour);
		#endif
		
		colour = LMS::toRGB(colour);
		break;
	case MAPPING_SPACE_YRGB:
		colour = inYRGB(colour, displayWhite, displayBlack,
		                        contentWhite, contentBlack);
		break;
	case MAPPING_SPACE_RGB:
		colour = inRGB(colour, displayWhite, displayBlack,
		                       contentWhite, contentBlack);
		break;
	case MAPPING_SPACE_MAXRGB:
		colour = inMaxRGB(colour, displayWhite, displayBlack,
		                          contentWhite, contentBlack);
		break;
	default:
		break;
	}

	#if BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
	colour = BT2020::toBT709(colour);
	colour *= BT2100::PQ::peakWhite / sRGB::whiteLevel;
	#endif

	return colour;
}

#if BUFFER_COLOR_SPACE != COLOUR_SPACE_SRGB
technique staticToneMap <ui_label = "Static Tone Mapping"; >
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
