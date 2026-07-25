#include "ReShadeCMS.fxh"

namespace ReShadeCMS {
namespace AdjustGamma {

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

float3 adjustGamma(float4 pos : SV_POSITION,
                   float2 texcoord : TexCoord) : SV_Target
{
	float3 rgb = tex2Dfetch(ReShade::BackBuffer, pos.xy).rgb;

	const float diffuseNorm = Buffer::fromNits(diffuse);

	rgb = Buffer::linearize(rgb);

	const float y = Buffer::deriveY(rgb) / diffuseNorm;
	rgb *= sPow(y, gamma) / y;

	rgb = Buffer::unlinearize(rgb);

	return rgb;
}

technique adjustGamma <ui_label = "Adjust Gamma"; >
{
	pass p0
	{
		VertexShader = PostProcessVS;
		PixelShader = adjustGamma;
	}
}

} // namespace ReShadeCMS::AdjustGamma
} // namespace ReShadeCMS

// vim: filetype=shaderslang
