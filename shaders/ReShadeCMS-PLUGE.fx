#include "ReShadeCMS.fxh"

namespace ReShadeCMS {
namespace PLUGE {
static const uint limited12BitBlack =  256;
static const uint limited12BitWhite = 3760;
static const uint limitedRange = 3760 - 256;

namespace SDR {
static const float higherNorm = (3760.0 - limited12BitBlack) / limitedRange;
static const float lighterNorm = (320.0 - limited12BitBlack) / limitedRange;
static const float blackNorm  = 0.0;
static const float darkerNorm = (192.0 - limited12BitBlack) / limitedRange;
} // namespace SDR

namespace HDR {
static const float higherNorm = (1596.0 - limited12BitBlack) / limitedRange;
static const float lighterNorm = (320.0 - limited12BitBlack) / limitedRange;
static const float blackNorm  = 0.0;
static const float darkerNorm = (192.0 - limited12BitBlack) / limitedRange;
} // namespace HDR

namespace UHD8K {
static const uint2 resolution = uint2(7680, 4320);

static const uint sampleA = 0;
static const uint sampleB = 1248;
static const uint sampleC = 2399;
static const uint sampleD = 3552;
static const uint sampleE = 4127;
static const uint sampleF = 5280;
static const uint sampleG = 6431;
static const uint sampleH = 7679;

static const uint lineA = 0;
static const uint lineB = 1296;
static const uint lineC = 1380;
static const uint lineD = 1871;
static const uint lineE = 1872;
static const uint lineF = 2447;
static const uint lineG = 2448;
static const uint lineH = 2939;
static const uint lineI = 3023;
static const uint lineJ = 4319;
}

namespace UHD4K {
static const uint2 resolution = uint2(3840, 2160);

static const uint sampleA = 0;
static const uint sampleB = 624;
static const uint sampleC = 1199;
static const uint sampleD = 1776;
static const uint sampleE = 2063;
static const uint sampleF = 2640;
static const uint sampleG = 3215;
static const uint sampleH = 3839;

static const uint lineA = 0;
static const uint lineB = 648;
static const uint lineC = 690;
static const uint lineD = 935;
static const uint lineE = 936;
static const uint lineF = 1223;
static const uint lineG = 1224;
static const uint lineH = 1469;
static const uint lineI = 1511;
static const uint lineJ = 2159;
}

namespace HDTV {
static const uint2 resolution = uint2(1920, 1080);

static const uint sampleA = 0;
static const uint sampleB = 312;
static const uint sampleC = 599;
static const uint sampleD = 888;
static const uint sampleE = 1031;
static const uint sampleF = 1320;
static const uint sampleG = 1607;
static const uint sampleH = 1919;

static const uint lineA = 42;
static const uint lineB = 366;
static const uint lineC = 387;
static const uint lineD = 509;
static const uint lineE = 510;
static const uint lineF = 653;
static const uint lineG = 654;
static const uint lineH = 776;
static const uint lineI = 797;
static const uint lineJ = 1121;
}

/*
uniform float diffuse <ui_type = "slider";
                       ui_min = 1.0;
                       ui_step = 1.0;
                       ui_max = 405.0;
                       ui_label = "Diffuse White";
                       ui_units = " nits";
                       > = 203.0;
*/

float3 displayPLUGE(float4 pos : SV_POSITION,
                    float2 texcoord : TexCoord) : SV_Target
{
	float3 rgb = tex2Dfetch(ReShade::BackBuffer, pos.xy).rgb;

	rgb = 0.0;

	if (pos.x >= UHD4K::sampleD && pos.x <= UHD4K::sampleE) {
		if (pos.y >= UHD4K::lineE && pos.y <= UHD4K::lineF) {
			rgb = Buffer::normalizeFrom(HDR::higherNorm,
			                            COLOUR_SPACE_PQ);
		}
	} else if (pos.x >= UHD4K::sampleF && pos.x <= UHD4K::sampleG) {
		if (pos.y >= UHD4K::lineB && pos.y <= UHD4K::lineD) {
			rgb = Buffer::normalizeFrom(HDR::lighterNorm,
			                            COLOUR_SPACE_PQ);
		} else if (pos.y >= UHD4K::lineG && pos.y <= UHD4K::lineI) {
			rgb = Buffer::normalizeFrom(HDR::darkerNorm,
			                            COLOUR_SPACE_PQ);
		}
	} else if (pos.x >= UHD4K::sampleB && pos.x <= UHD4K::sampleC) {
		if (pos.y >= UHD4K::lineC && pos.y <= UHD4K::lineH) {
			// TODO
		}
	}

	return rgb;
}

technique displayPLUGE <ui_label = "PLUGE"; >
{
	pass black
	{
		VertexShader = PostProcessVS;
		PixelShader = displayPLUGE;
	}

}

} // namespace ReShadeCMS::PLUGE
} // namespace ReShadeCMS

// vim: filetype=shaderslang
