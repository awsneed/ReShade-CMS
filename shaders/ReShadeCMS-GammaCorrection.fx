#include "ReShadeCMS.fxh"

namespace ReShadeCMS {
namespace GammaCorrection {

#if defined(BUFFER_IS_HDR)
uniform float diffuse <ui_type = "slider";
                       ui_min = 1.0;
                       ui_step = 1.0;
                       ui_max = 405.0;
                       ui_label = "Diffuse White";
                       ui_units = " nits";
                       > = 203.0;
#else
static const float diffuse = 1.0;
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

	rgb = Buffer::linearize(rgb);

	const float y = Buffer::deriveY(rgb);

	float yNew;
	if (diffuse != 1.0) {
		const float diffuseNorm = Buffer::fromNits(diffuse);
		yNew = sPow(y / diffuseNorm, gamma) * diffuseNorm;
	} else {
		yNew = sPow(y, gamma);
	}

	rgb *= y != 0.0 ? yNew / y : y;

	rgb = Buffer::unlinearize(rgb);

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
