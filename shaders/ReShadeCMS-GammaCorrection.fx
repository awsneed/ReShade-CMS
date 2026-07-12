#include "ReShadeCMS.fxh"

namespace ReShadeCMS {
namespace GammaCorrection {

#if defined(BUFFER_IS_HDR)
uniform float srcDiffuse <ui_type = "slider";
                               ui_min = 1.0;
                               ui_step = 1.0;
                               ui_max = 405.0;
                               ui_label = "Original SDR White";
                               ui_units = " nits";
                               ui_text = "This shader can emulate the gamma adjustment typically done to SDR content being direct-mapped into HDR by setting the original SDR white level.";
                               > = 100.0;
uniform float dstDiffuse <ui_type = "slider";
                            ui_min = 1.0;
                            ui_step = 1.0;
                            ui_max = 405.0;
                            ui_label = "Diffuse White";
                            ui_units = " nits";
                            > = 203.0;
#else
static const float srcDiffuse = 80.0;
static const float dstDiffuse = 80.0;
#endif

uniform float gamma <ui_type = "slider";
                     ui_min = 0.155;
                     ui_step = 0.001;
                     ui_max = 2.155;
                     ui_label = "Power";
                     > = 1.155;

/* TODO: Make this the main gamma correction formula here or elsewhere, then
 * edit SDR Direct Map to call this instead of doing it's own version */
float3 correctGamma(float4 pos : SV_POSITION,
                    float2 texcoord : TexCoord) : SV_Target
{
	float3 rgb = tex2Dfetch(ReShade::BackBuffer, pos.xy).rgb;

	#if BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
	rgb = BT709::toBT2020(rgb);
	#endif

	const float scaleY = dstDiffuse / srcDiffuse;
	rgb /= scaleY;

	const float Y = BT2100::deriveY(rgb);
	const float newY = scaleY * (sign(Y) * pow(abs(Y), gamma));
	const float scale = Y != 0.0 ? newY / Y : 0.0;
	rgb *= scale;

	#if BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
	rgb = BT2020::toBT709(rgb);
	#endif

	return rgb;
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
