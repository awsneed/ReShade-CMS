#include "ReShadeCMS.fxh"

namespace ReShadeCMS {
namespace EOTFCorrection {

uniform uint srcEOTF <ui_type = "combo";
                      ui_items = "None \0"
                                 "sRGB \0"
                                 "Gamma 2.2 \0"
                                 "BT.1886 \0"
                                 #if defined(BUFFER_IS_HDR)
                                 "PQ \0"
                                 "HLG \0"
                                 #endif
                                 ;
                      ui_text = "BUFFER_COLOR_SPACE: " BUFFER_COLOR_SPACE_STRING;
                      ui_label = "Original EOTF";
                      > = EOTF_DEFAULT;

uniform uint dstEOTF <ui_type = "combo";
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

#if defined(BUFFER_IS_HDR)
uniform float diffuse <ui_type = "slider";
                       ui_min = 1.0;
                       ui_step = 1.0;
                       ui_max = 405.0;
                       ui_label = "SDR White";
                       ui_units = " nits";
                       ui_tooltip = "Diffuse white for SDR EOTFs.";
                       > = 80.0;
#else
static const float diffuse = 80.0;
#endif

// Replaces the original source EOTF with an override destination EOTF, mainly
// for correcting games that have been forced into HDR and have no EOTF (very
// bright and washed out), or for correcting the gamma between sRGB <-> Gamma
// 2.2 / BT.1886.
float3 correctEOTF(float4 pos : SV_POSITION,
                   float2 texcoord : TexCoord) : SV_Target
{
	float3 rgb = tex2Dfetch(ReShade::BackBuffer, pos.xy).rgb;

	// First, depending on the source EOTF, we may need to first apply the
	// natural EOTF of content to get to linear display light
	// (display-referred mapping)
	
	rgb = Buffer::linearize(rgb);

	switch (srcEOTF) {
	case EOTF_SRGB:
	case EOTF_G22:
	case EOTF_BT1886:
		rgb = Buffer::normalizeTo(rgb, COLOUR_SPACE_SCRGB);
		rgb *= sRGB::diffuse / diffuse;
		break;
	case EOTF_PQ:
		rgb = Buffer::normalizeTo(rgb, COLOUR_SPACE_PQ);
		break;
	case EOTF_HLG:
		rgb = Buffer::normalizeTo(rgb, COLOUR_SPACE_HLG);
		break;
	default:
		break;
	}

	rgb = applyInverseEOTF(rgb, srcEOTF);
	rgb = applyEOTF(rgb, dstEOTF);

	switch (dstEOTF) {
	case EOTF_SRGB:
	case EOTF_G22:
	case EOTF_BT1886:
		rgb = Buffer::normalizeFrom(rgb, COLOUR_SPACE_SCRGB);
		rgb *= diffuse / sRGB::diffuse;
		break;
	case EOTF_PQ:
		rgb = Buffer::normalizeFrom(rgb, COLOUR_SPACE_PQ);
		break;
	case EOTF_HLG:
		rgb = Buffer::normalizeFrom(rgb, COLOUR_SPACE_HLG);
		break;
	default:
		break;
	}

	rgb = Buffer::unlinearize(rgb);
	
	return rgb;
}

technique correctEOTF <ui_label = "EOTF Correction"; >
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
