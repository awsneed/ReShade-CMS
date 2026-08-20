#include "ReShadeCMS.fxh"

namespace ReShadeCMS {
namespace LowResSim {

uniform float strength <ui_label = "Strength";
                        ui_type = "slider";
                        ui_min = 0.0;
                        ui_max = 1.0;
                        ui_step = 0.001;
                        ui_tooltip = "How dark the spacing between pixels is.\n"
                                     "Auto Brightness takes this into account.";
                        ui_units = " %";
                        > = 1.0;

uniform bool autoBrightEnabled <ui_label = "Auto Brightness";
                                ui_tooltip = "Auto boost lit pixel brightness to preserve overall luminance.";
                                > = true;

uniform bool yEnabled <ui_category = "Vertical";
                       ui_category_toggle = true;
                       ui_label = "Enable Vertical";
                       > = true;

#define LOWRES_DEFAULT_Y_RES 480
#define LOWRES_DEFAULT_X_RES 854

uniform uint yRes <ui_category = "Vertical";
                   ui_type = "slider";
                   ui_min = 1;
                   ui_step = 1;
                   ui_max = BUFFER_HEIGHT / 2;
                   ui_label = "Resolution";
                   ui_units = " px";
                   > = LOWRES_DEFAULT_Y_RES;

uniform uint yPx <ui_category = "Vertical";
                  ui_type = "slider";
                  ui_min = 1;
                  ui_step = 1;
                  ui_max = 10;
                  ui_label = "Pixel Size";
                  ui_units = " px";
                  > = 2;

uniform bool xEnabled <ui_category = "Horizontal";
                       ui_category_toggle = true;
                       ui_label = "Enable Horizontal";
                       > = true;

uniform uint xRes <ui_category = "Horizontal";
                   ui_type = "slider";
                   ui_min = 1;
                   ui_step = 1;
                   ui_max = BUFFER_WIDTH / 2;
                   ui_label = "Resolution";
                   ui_units = " px";
                   > = LOWRES_DEFAULT_X_RES;

uniform uint xPx <ui_category = "Horizontal";
                  ui_type = "slider";
                  ui_min = 1;
                  ui_step = 1;
                  ui_max = 10;
                  ui_label = "Pixel Size";
                  ui_units = " px";
                  > = 2;

float3 lowResSim(float4 pos : SV_POSITION,
                 float2 texcoord : TexCoord) : SV_Target
{
	float3 rgb = tex2Dfetch(ReShade::BackBuffer, pos.xy).rgb;

	const uint2 pitch = uint2(BUFFER_WIDTH, BUFFER_HEIGHT) / uint2(xRes, yRes);
	const uint wholeArea = pitch.x * pitch.y;
	const uint litArea = xPx * yPx;
	const uint unlitArea = wholeArea - litArea;
	const float boost = wholeArea / (wholeArea - unlitArea * strength);

	const uint2 relPos = pos.xy % pitch;

	rgb = Buffer::linearize(rgb);
	rgb *= (relPos.x < xPx && relPos.y < yPx) ? boost : 1.0 - strength;
	rgb = Buffer::unlinearize(rgb);

	return rgb;
}

technique lowResSim <ui_label = "Low Resolution Simulator"; >
{
	pass p0
	{
		VertexShader = PostProcessVS;
		PixelShader = lowResSim;
	}

}

} // namespace ReShadeCMS::LowResSim
} // namespace ReShadeCMS

// vim: filetype=shaderslang
