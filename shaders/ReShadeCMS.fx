#include "ReShadeCMS.fxh"

namespace ReShadeCMS
{
namespace Misc
{

float3 TestPS(
    float4 pos : SV_POSITION,
    float2 texcoord : TexCoord
) : SV_Target
{
    float3 colour = tex2D(ReShade::BackBuffer, texcoord).rgb;

    // Testing round-trip BT709 -> BT2020 -> BT709;
    return colour;
}

technique Test
{
    pass p0
    {
        VertexShader = PostProcessVS;
        PixelShader = TestPS;
    }
}

} // namespace Misc
} // namespace ReShadeCMS

// vim: filetype=shaderslang ts=4 sts=4 sw=4
