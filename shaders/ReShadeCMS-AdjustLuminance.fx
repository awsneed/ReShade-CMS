#include "ReShadeCMS.fxh"

namespace ReShadeCMS {
namespace AdjustLuminance {

uniform float oldDiffuse <ui_type = "slider";
                          ui_min = 80.0;
                          ui_step = 1.0;
                          ui_max = 405.0;
                          ui_label = "Old Diffuse White";
                          ui_units = " nits";
                          > = 80.0;
uniform float newDiffuse <ui_type = "slider";
                          ui_min = 80.0;
                          ui_step = 1.0;
                          ui_max = 405.0;
                          ui_label = "New Diffuse White";
                          ui_units = " nits";
                          > = 203.0;

float3 adjustLuminance(float4 pos : SV_POSITION,
                       float2 texcoord : TexCoord) : SV_Target
{
	float3 rgb = tex2Dfetch(ReShade::BackBuffer, pos.xy).rgb;

	rgb = Buffer::linearize(rgb);
	rgb *= newDiffuse / oldDiffuse;
	rgb = Buffer::unlinearize(rgb);

	return rgb;
}

technique adjustLuminance <ui_label = "Adjust Luminance"; >
{
	pass p0
	{
		VertexShader = PostProcessVS;
		PixelShader = adjustLuminance;
	}
}

} // namespace Testing
} // namespace ReShadeCMS

// vim: filetype=shaderslang
