#include "ReShadeCMS.fxh"

namespace ReShadeCMS {
namespace EOTFCorrection {

#if defined(BUFFER_IS_HDR)
uniform float SDRWhite <ui_type = "slider";
                        ui_min = 1.0;
                        ui_step = 1.0;
                        ui_max = 405.0;
                        ui_label = "SDR White";
                        ui_units = " nits";
                        ui_tooltip = "White level for SDR EOTFs.";
                        > = 80.0;
#else
static const float diffuseWhite = 100.0;
#endif

uniform uint oldEOTF <ui_type = "combo";
                      ui_items = "None \0"
                                 "sRGB \0"
                                 "Gamma 2.2 \0"
                                 "BT.1886 \0"
                                 #if defined(BUFFER_IS_HDR)
                                 "PQ \0"
                                 "HLG \0"
                                 #endif
                                 ;
                      ui_label = "Original EOTF";
                      > = EOTF_DEFAULT;

uniform uint newEOTF <ui_type = "combo";
                      ui_items = "None \0"
                                 "sRGB \0"
                                 "Gamma 2.2 \0"
                                 "BT.1886 \0"
                                 #if defined(BUFFER_IS_HDR)
                                 "PQ \0"
                                 "HLG \0"
                                 #endif
                                 ;
                      ui_label = "Override EOTF";
                      > = EOTF_DEFAULT;

float3 correctEOTF(float4 pos : SV_POSITION,
                   float2 texcoord : TexCoord) : SV_Target
{
	float3 colour = tex2Dfetch(ReShade::BackBuffer, pos.xy).rgb;
	
	// Scale normalized values to what the old EOTF is expecting
	#if defined(BUFFER_IS_HDR)
	switch (oldEOTF) {
	case EOTF_SRGB:
	case EOTF_G22:
	case EOTF_BT1886:
		#if   BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
		colour *= sRGB::whiteLevel / SDRWhite;
		#elif BUFFER_COLOR_SPACE == COLOUR_SPACE_PQ
		colour *= BT2100::PQ::peakWhite / SDRWhite;
		#elif BUFFER_COLOR_SPACE == COLOUR_SPACE_HLG
		colour *= BT2100::HLG::peakWhite / SDRWhite;
		#endif
		break;
	case EOTF_PQ:
		#if   BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
		colour *= BT2100::PQ::scaleToSRGB;
		#elif BUFFER_COLOR_SPACE == COLOUR_SPACE_HLG
		colour *= BT2100::PQ::scaleToHLG;
		#endif
		break;
	case EOTF_HLG:
		#if   BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
		colour *= BT2100::HLG::scaleToSRGB;
		#elif BUFFER_COLOR_SPACE == COLOUR_SPACE_PQ
		colour *= BT2100::HLG::scaleToPQ;
		#endif
		break;
	case EOTF_NONE:
		// Might need to add something here in the future?
	default:
		break;
	}
	#endif

	colour = applyInverseEOTF(colour, oldEOTF);
	colour = applyEOTF(colour, newEOTF);

	// TODO: Double-check that this reverse scaling is right
	#if defined(BUFFER_IS_HDR)
	switch (newEOTF) {
	case EOTF_SRGB:
	case EOTF_G22:
	case EOTF_BT1886:
		#if   BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
		colour /= sRGB::whiteLevel / SDRWhite;
		#elif BUFFER_COLOR_SPACE == COLOUR_SPACE_PQ
		colour /= BT2100::PQ::peakWhite / SDRWhite;
		#elif BUFFER_COLOR_SPACE == COLOUR_SPACE_HLG
		colour /= BT2100::HLG::peakWhite / SDRWhite;
		#endif
		break;
	case EOTF_PQ:
		#if   BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
		colour /= BT2100::PQ::scaleToSRGB;
		#elif BUFFER_COLOR_SPACE == COLOUR_SPACE_HLG
		colour /= BT2100::PQ::scaleToHLG;
		#endif
		break;
	case EOTF_HLG:
		#if   BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
		colour /= BT2100::HLG::scaleToSRGB;
		#elif BUFFER_COLOR_SPACE == COLOUR_SPACE_PQ
		colour /= BT2100::HLG::scaleToPQ;
		#endif
		break;
	case EOTF_NONE:
	default:
		break;
	}
	#endif
	
	#if   BUFFER_COLOR_SPACE == COLOUR_SPACE_SRGB
	colour = sRGB::iEOTF(colour);
	#elif BUFFER_COLOR_SPACE == COLOUR_SPACE_PQ
	colour = BT2100::PQ::iEOTF(colour);
	#elif BUFFER_COLOR_SPACE == COLOUR_SPACE_HLG
	colour = BT2100::HLG::iEOTF(colour);
	#endif

	return colour;
}

technique correctEOTF < ui_label = "EOTF Correction"; >
{
	pass p0
	{
		VertexShader = PostProcessVS;
		PixelShader = correctEOTF;
	}
}

} // namespace EOTFCorrection
} // namespace ReShadeCMS

// vim: filetype=shaderslang
