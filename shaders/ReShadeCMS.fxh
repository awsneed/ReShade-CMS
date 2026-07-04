#include "ReShade.fxh"

#pragma once

namespace ReShadeCMS {

// Autocreate function macro statements for overloading multi-component
// versions. Commonly needed with transfer functions.
#define _AUTO_FUNC(_FUNCTION, T1, T2) \
_FUNCTION(T1,    T2); \
_FUNCTION(T1##2, T2##2); \
_FUNCTION(T1##3, T2##3); \
_FUNCTION(T1##4, T2##4);

// ReShade preprocessor translations
#define COLOUR_SPACE_UNKNOWN 0
#define COLOUR_SPACE_SRGB    1
#define COLOUR_SPACE_SCRGB   2
#define COLOUR_SPACE_PQ      3
#define COLOUR_SPACE_HLG     4

#if   BUFFER_COLOR_SPACE == COLOUR_SPACE_UNKNOWN
	#define BUFFER_COLOR_SPACE_STRING "Unknown"

#elif BUFFER_COLOR_SPACE == COLOUR_SPACE_SRGB
	#define BUFFER_COLOR_SPACE_STRING "sRGB"

#elif BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
	#define BUFFER_COLOR_SPACE_STRING "scRGB"

#elif BUFFER_COLOR_SPACE == COLOUR_SPACE_PQ
	#define BUFFER_COLOR_SPACE_STRING "PQ"

#elif BUFFER_COLOR_SPACE == COLOUR_SPACE_HLG
	#define BUFFER_COLOR_SPACE_STRING "HLG"
#endif

#if BUFFER_COLOR_SPACE != COLOUR_SPACE_SRGB
	#define BUFFER_IS_HDR true
#endif

#define EOTF_NONE   0
#define EOTF_SRGB   1
#define EOTF_G22    2
#define EOTF_BT1886 3
#define EOTF_PQ     4
#define EOTF_HLG    5

#if   BUFFER_COLOR_SPACE == COLOUR_SPACE_PQ
	#define EOTF_DEFAULT EOTF_PQ

#elif BUFFER_COLOR_SPACE == COLOUR_SPACE_HLG
	#define EOTF_DEFAULT EOTF_HLG

#else
	#define EOTF_DEFAULT EOTF_SRGB
#endif

float2x2 minors(float2x2 m)
{
	return float2x2(m._m11, m._m10,
	                m._m01, m._m00);
};

float3x3 minors(float3x3 m)
{
	return float3x3(determinant(float2x2(m._m11, m._m12,
	                                     m._m21, m._m22)),
	                determinant(float2x2(m._m10, m._m12,
	                                     m._m20, m._m22)),
	                determinant(float2x2(m._m10, m._m11,
	                                     m._m20, m._m21)),
	
	                determinant(float2x2(m._m01, m._m02,
	                                     m._m21, m._m22)),
	                determinant(float2x2(m._m00, m._m02,
	                                     m._m20, m._m22)),
	                determinant(float2x2(m._m00, m._m01,
	                                     m._m20, m._m21)),
	
	                determinant(float2x2(m._m01, m._m02,
	                                     m._m11, m._m12)),
	                determinant(float2x2(m._m00, m._m02,
	                                     m._m10, m._m12)),
	                determinant(float2x2(m._m00, m._m01,
	                                     m._m10, m._m11)));
};

float2x2 cofactors(float2x2 m)
{
	return m * float2x2( 1.0, -1.0,
	                    -1.0,  1.0);
};

float3x3 cofactors(float3x3 m)
{
	return m * float3x3( 1.0, -1.0,  1.0,
	                    -1.0,  1.0, -1.0,
	                     1.0, -1.0,  1.0);
};

float2x2 adjugate(float2x2 m)
{
	return transpose(cofactors(minors(m)));
};

float3x3 adjugate(float3x3 m)
{
	return transpose(cofactors(minors(m)));
};

// Matrix inversion, mainly for finding inverse NPM's
// Divide the adjugate by the original determinant to find the inverse
float2x2 inverse(float2x2 m)
{
	return adjugate(m) / determinant(m);
};

float3x3 inverse(float3x3 m)
{
	return adjugate(m) / determinant(m);
};

// TODO: Think up _auto_func that handles matrix types?
#define _CALCULATE_Z(T1, T2) \
T1 calculateZ(T2 coords) \
{ \
	return 1.0 - (coords[0] + coords[1]); \
};
_CALCULATE_Z(float,  float2);
_CALCULATE_Z(float2, float2x2);
_CALCULATE_Z(float3, float2x3);
_CALCULATE_Z(float4, float2x4);

// This function, given a colour space's xy primaries + xy white point, returns
// the Normalized Primary Matrix (NPM) used to convert from the input colour
// space to the CIE XYZ space.  The inverse of the NPM is used to convert from
// CIE XYZ to the colour space, and will be calculated by a separate matrix
// inversion function.
// 
// colourSpace format: Rows are x y. Columns are r g b w.
float3x3 deriveNPM(float4x2 xySpecs)
{
	float3x2 primaries = float3x2(xySpecs[0],
	                              xySpecs[1],
	                              xySpecs[2]);

	float2 whitePoint = xySpecs[3];

	float3x3 P = float3x3(primaries._m00_m10_m20,
	                      primaries._m01_m11_m21,
	                      calculateZ(transpose(primaries)));

	float3 W = float3(whitePoint.x / whitePoint.y,
	                  1.0,
	                  calculateZ(whitePoint) / whitePoint.y);
	
	float3 Ci = mul(inverse(P), W);
	float3x3 C = float3x3(Ci.r,  0.0,  0.0,
	                       0.0, Ci.g,  0.0,
	                       0.0,  0.0, Ci.b);
	
	return mul(P, C);
};

float3x3 deriveTRA(float4x2 xySrcSpecs, float4x2 xyDstSpecs)
{
	return mul(inverse(deriveNPM(xyDstSpecs)), deriveNPM(xySrcSpecs));
};

namespace WhitePoints {
static const float2 A =   float2(0.44758, 0.40745);
static const float2 D50 = float2(0.34567, 0.35850);
static const float2 D55 = float2(0.33242, 0.64743);
static const float2 D65 = float2(0.31272, 0.32903);
static const float2 D75 = float2(0.29902, 0.31485);
static const float2 D93 = float2(0.28315, 0.29711);
static const float2 E =   float2(0.33333, 0.33333);
}; // namespace ReShadeCMS::WhitePoints

namespace NTSCU {
static const float3x2 primaries = float3x2(0.630, 0.340,
                                           0.310, 0.595,
                                           0.155, 0.070);
static const float2 whitePoint = WhitePoints::D65;
static const float4x2 specs = float4x2(primaries[0],
                                       primaries[1],
                                       primaries[2],
                                       whitePoint);
} // namespace ReShadeCMS::NTSCU

namespace PAL {
static const float3x2 primaries = float3x2(0.640, 0.330,
                                           0.290, 0.600,
                                           0.150, 0.060);
static const float2 whitePoint = WhitePoints::D65;
static const float4x2 specs = float4x2(primaries[0],
                                       primaries[1],
                                       primaries[2],
                                       whitePoint);
} // namespace ReShadeCMS::PAL

namespace NTSCJ {
static const float3x2 primaries = float3x2(0.670, 0.330,
                                           0.210, 0.710,
                                           0.140, 0.080);
static const float2 whitePoint = WhitePoints::D93;
static const float4x2 specs = float4x2(primaries[0],
                                       primaries[1],
                                       primaries[2],
                                       whitePoint);
} // namespace ReShadeCMS::NTSCJ

namespace BT709 {
static const float2 whitePoint = WhitePoints::D65;
static const float3x2 primaries = float3x2(0.640, 0.330,
                                           0.300, 0.600,
                                           0.150, 0.060);
static const float4x2 specs = float4x2(primaries[0],
                                       primaries[1],
                                       primaries[2],
                                       whitePoint);
} // namespace ReShadeCMS::BT709

namespace BT1886 {
static const float whiteLevel = 100.0;
static const float blackLevel =   0.0;
static const float gamma = 2.40;

// TODO: Finish implementing the white and black levels compensation
#define _BT1886_EOTF(T1, T2) \
T1 EOTF(T2 value) \
{ \
	return sign(value) * pow(abs(value), 2.4); \
};
_AUTO_FUNC(_BT1886_EOTF, float, float);

#define _BT1886_INVERSE_EOTF(T1, T2) \
T1 iEOTF(T2 value) \
{ \
	return sign(value) * pow(abs(value), rcp(2.4)); \
};
_AUTO_FUNC(_BT1886_INVERSE_EOTF, float, float);

} // namespace ReShadeCMS::BT1886

namespace BT2035 {
static const float whiteLevel = 100.0;
static const float blackLevel = 0.0;
} // namespace ReShadeCMS::BT2035

namespace sRGB {
static const float2 whitePoint = BT709::whitePoint;
static const float3x2 primaries = BT709::primaries;
static const float4x2 specs = float4x2(primaries[0],
                                       primaries[1],
                                       primaries[2],
                                       whitePoint);
static const float whiteLevel = 80.0;

// Using scRGB's higher-precision functions.
#define _sRGB_EOTF(T1, T2) \
T1 EOTF(T2 E) \
{ \
	static const float breakPoint = 0.04045; \
	const T2 ESign = sign(E); \
	E = abs(E); \
	\
	return ESign * (E <= breakPoint ? E / 12.92 \
	                                : pow((E + 0.055) / 1.055, 2.4)); \
};
_AUTO_FUNC(_sRGB_EOTF, float, float);

// sRGB standard specifically uses an imprecise inverse EOTF breakPoint.
// It's not exactly the true inverse of the EOTF.
// NOTE: Not sure if the same negative reflection is to be used on inverses
#define _sRGB_INVERSE_EOTF(T1, T2) \
T1 iEOTF(T2 E) \
{ \
	static const float breakPoint = 0.0031308; \
	const T2 ESign = sign(E); \
	E = abs(E); \
	\
	return ESign * (E <= breakPoint ? 12.92 * E \
	                                : 1.055 * pow(E, 1.0 / 2.4) - 0.055); \
};
_AUTO_FUNC(_sRGB_INVERSE_EOTF, float, float);

} // namespace ReShadeCMS::sRGB

namespace scRGB {
static const float2 whitePoint = BT709::whitePoint;
static const float3x2 primaries = BT709::primaries;
static const float4x2 specs = float4x2(primaries[0],
                                       primaries[1],
                                       primaries[2],
                                       whitePoint);
static const float peakWhite = 10000.0; // Technically no limit
static const float diffuseWhite = sRGB::whiteLevel;
} // namespace ReShadeCMS::scRGB

namespace G22 {
static const float whiteLevel = BT2035::whiteLevel;

#define _G22_EOTF(T1, T2) \
T1 EOTF(T2 value) \
{ \
	return sign(value) * pow(abs(value), 2.2); \
};
_AUTO_FUNC(_G22_EOTF, float, float);

#define _G22_INVERSE_EOTF(T1, T2) \
T1 iEOTF(T2 value) \
{ \
	return sign(value) * pow(abs(value), rcp(2.2)); \
};
_AUTO_FUNC(_G22_INVERSE_EOTF, float, float);

} // namespace ReShadeCMS::Gamma22

namespace BT2020 {
static const float2 whitePoint = WhitePoints::D65;
static const float3x2 primaries = float3x2(0.708, 0.292,
                                           0.170, 0.797,
                                           0.131, 0.046);
static const float4x2 specs = float4x2(primaries[0],
                                       primaries[1],
                                       primaries[2],
                                       whitePoint);

float3 toBT709(float3 colour)
{
	static const float3x3 tra = deriveTRA(specs, BT709::specs);
	static const float3x3 traTest = float3x3( 1.6605, -0.5876, -0.0728,
	                                         -0.1246,  1.1329, -0.0083,
	                                         -0.0182, -0.1006,  1.1187);

	return mul(tra, colour);
};
} // namespace ReShadeCMS::BT2020

namespace BT709 {
float3 toBT2020(float3 colour)
{
	static const float3x3 tra = deriveTRA(specs, BT2020::specs);
	static const float3x3 traTest = float3x3(0.6274, 0.3293, 0.0433,
	                                         0.0691, 0.9195, 0.0114,
	                                         0.0164, 0.0880, 0.8956);

	return mul(tra, colour);
};
} // namespace ReShadeCMS::BT709

namespace BT2100 {
static const float2 whitePoint = BT2020::whitePoint;
static const float3x2 primaries = BT2020::primaries;
static const float4x2 specs = float4x2(primaries[0],
                                       primaries[1],
                                       primaries[2],
                                       whitePoint);
static const float diffuseWhite = 203.0;

namespace PQ {
static const float peakWhite = 10000.0;
static const float m1 = 2610.0 / 16384.0;
static const float m2 = 2523.0 / 4096.0 * 128.0;
static const float c1 = 3424.0 / 4096.0;
static const float c2 = 2413.0 / 4096.0 * 32.0;
static const float c3 = 2392.0 / 4096.0 * 32.0;

// Content: Non-linear PQ encoded value
// The EOTF maps the non-linear PQ signal into display light.
#define _PQ_EOTF(T1, T2) \
T1 EOTF(T2 E) \
{ \
	return pow(  max(pow(E, rcp(m2)) - c1, 0.0) \
	           / (c2 - c3 * pow(E, rcp(m2))), \
	           rcp(m1)); \
};
_AUTO_FUNC(_PQ_EOTF, float, float);

#define _PQ_INVERSE_EOTF(T1, T2) \
T1 iEOTF(T2 Y) \
{ \
	return pow(  ( c1 + c2 * pow(Y, m1)) \
	           / (1.0 + c3 * pow(Y, m1)), \
	           m2); \
};
_AUTO_FUNC(_PQ_INVERSE_EOTF, float, float);



} // namespace ReShadeCMS::BT2100::PQ

namespace HLG {
static const float peakWhite = 1000.0;
static const float a = 0.17883277;
static const float b = 1.0 - 4.0 * a;
// c requires log(), so will calculate in functions that need it
static const float gamma = 1.2;

float OOTF(float E)
{
	
};

float EOTF(float x)
{
	static const float c = 0.5 - a * log(4.0 * a);

	/* TODO: Add user gain and black lift adjustments */
	return x <= 0.5 ? exp2(x)
	                : exp(((x - c) / a) + b) / 12.0;
};
} // namespace ReShadeCMS::BT2100::HLG
} // namespace ReShadeCMS::BT2100

namespace RGB {
	static const float3x3 lmsCoeffs = float3x3(
	        // LR LG LB
	        // MR MG MB
	        // SR SG SB
	         1688.0,  2146.0,   262.0,
	          683.0,  2951.0,   462.0,
	           99.0,   309.0,  3688.0) / 4096.0;

	float3 toLMS(float3 colour)
	{
		return mul(lmsCoeffs, colour);
	};
} // namespace ReShadeCMS::RGB

namespace LMS {
float3 toRGB(float3 colour)
{
	static const float3x3 rgbCoeffs = inverse(RGB::lmsCoeffs);
	return mul(rgbCoeffs, colour);
}

namespace PQ {
static const float3x3 iCtCpCoeffs = float3x3( 2048.0,   2048.0,     0.0,
                                              6610.0, -13613.0,  7003.0,
                                             17933.0, -17390.0,  -543.0)
                                             / 4096.0;

float3 toICtCp(float3 colour)
{
	return mul(iCtCpCoeffs, BT2100::PQ::iEOTF(colour));
};

} // namespace ReShadeCMS::LMS::PQ

namespace HLG {
static const float3x3 iCtCpCoeffs = float3x3(2048.0,  2048.0,     0.0,
                                             3625.0, -7465.0,  3840.0,
                                             9500.0, -9212.0,  -288.0)
                                             / 4096.0;

/*
float3 toICtCp(float3 colour)
{
	return mul(iCtCpCoeffs, BT2100::HLG::iEOTF(colour));
};
*/
} // namespace ReShadeCMS::LMS::HLG
} // namespace ReShadeCMS::LMS

namespace ICtCp {
// ICtCp deals with 16-bit linear RGB
// Display-referred: 1.0 = 1.0 nit
// Scene-referred: 1.0 = maximum diffuse white

namespace PQ {
float3 toLMS(float3 colour)
{
	static const float3x3 lmsCoeffs = inverse(LMS::PQ::iCtCpCoeffs);

	return BT2100::PQ::EOTF(mul(lmsCoeffs, colour));
};
} // namespace ReShadeCMS::ICtCp::PQ

namespace HLG {
float3 toLMS(float3 colour)
{
	static const float3x3 lmsCoeffs = inverse(LMS::HLG::iCtCpCoeffs);

	return HLG::EOTF(mul(lmsCoeffs, colour));
};
} // namespace ReShadeCMS::ICtCp::HLG

} // namespace ReShadeCMS::ICtCp

namespace ToneMapping {
#define _BT2408_T(T1, T2) \
T1 T(T2 A, float KS) \
{ \
	return (A - KS) / (1.0 - KS); \
};
_AUTO_FUNC(_BT2408_T, float, float);

#define _BT2408_P(T1, T2) \
T1 P(T2 B, float KS, float maxLum) \
{ \
	T2 TOfB        = T(B, KS); \
	T2 TOfBSquared = pow(TOfB, 2.0); \
	T2 TOfBCubed   = pow(TOfB, 3.0); \
	\
	/* Hermite spline */ \
	return    ( 2.0 * TOfBCubed - 3.0 * TOfBSquared + 1.0 ) * KS \
	        + (       TOfBCubed - 2.0 * TOfBSquared + TOfB) * (1.0 - KS) \
	        + (-2.0 * TOfBCubed + 3.0 * TOfBSquared       ) * maxLum; \
};
_AUTO_FUNC(_BT2408_P, float, float);

#define _BT2408_EETF(T1, T2) \
T1 EETF(T2 e1, const float displayWhite, const float displayBlack, \
               const float contentWhite, const float contentBlack) \
{ \
	/* Bunch of simplification setup */ \
	float displayBlackNorm = BT2100::PQ::iEOTF(displayBlack / BT2100::PQ::peakWhite); \
	float displayWhiteNorm = BT2100::PQ::iEOTF(displayWhite / BT2100::PQ::peakWhite); \
	float contentBlackNorm = BT2100::PQ::iEOTF(contentBlack / BT2100::PQ::peakWhite); \
	float contentWhiteNorm = BT2100::PQ::iEOTF(contentWhite / BT2100::PQ::peakWhite); \
	float contentRange = contentWhiteNorm - contentBlackNorm; \
	\
	/* Step 1: Normalize PQ values based on mastering display */ \
	e1 = (e1 - displayBlackNorm) / contentRange; \
	/* Let's clamp the input to our configured input peak */ \
	e1 = min(1.0, e1); \
	\
	/* Step 1.5: Calculate mastering display black and white in [0:1] PQ */ \
	float minLum = (displayBlackNorm - contentBlackNorm) / contentRange; \
	float maxLum = (displayWhiteNorm - contentBlackNorm) / contentRange; \
	\
	/* Step 2: Calculate 1:1 mapping and knee (?) */ \
	float KS = 1.5 * maxLum - 0.5; \
	\
	/* Step 3: Solve for EETF (e3) with given end points */ \
	T2 e2 = e1 < KS ? e1 : P(e1, KS, maxLum); \
	T2 e3 = e2 + minLum * pow(1.0 - e2, 4.0); \
	\
	/* Step 4: Hermite spline equations (see functions P(...) and T(...) */ \
	\
	/* Step 5: Invert normalization of PQ values */ \
	return e3 * contentRange + contentBlackNorm; \
};
_AUTO_FUNC(_BT2408_EETF, float, float);

float3 inICtCp(float3 ICtCp, float displayWhite, float displayBlack,
                             float contentWhite, float contentBlack)
{
	const float I2 = EETF(ICtCp.x, displayWhite, displayBlack,
	                               contentWhite, contentBlack);

	return float3(I2, min(ICtCp.x / I2, I2 / ICtCp.x) * ICtCp.yz);
};

float3 inYCbCr(float3 YCbCr, float displayWhite, float displayBlack,
                             float contentWhite, float contentBlack)
{
	const float Y2 = EETF(YCbCr.x, displayWhite, displayBlack,
	                               contentWhite, contentBlack);

	return float3(Y2, min(YCbCr.x / Y2, Y2 / YCbCr.x) * YCbCr.yz);
};

float3 inRGB(float3 colour, float displayWhite, float displayBlack,
                            float contentWhite, float contentBlack)
{
	return EETF(colour, displayWhite, displayBlack,
	                    contentWhite, contentBlack);
};

} // namespace ReShadeCMS::ToneMapping

#define _USE_EOTF(T1, T2) \
T1 applyEOTF(T2 colour, const uint targetEOTF) \
{ \
	switch (targetEOTF) { \
	case EOTF_SRGB: \
		colour = sRGB::EOTF(colour); \
		break; \
	case EOTF_G22: \
		colour = G22::EOTF(colour); \
		break; \
	case EOTF_BT1886: \
		colour = BT1886::EOTF(colour); \
		break; \
	case EOTF_PQ: \
		colour = BT2100::PQ::EOTF(colour); \
		break; \
	case EOTF_HLG: \
		/* TODO */ \
		/*colour = HLG::EOTF(colour); */ \
		/*break; */ \
	case EOTF_NONE: \
	default: \
		break; \
	} \
	\
	return colour; \
};
_AUTO_FUNC(_USE_EOTF, float, float);

#define _USE_INVERSE_EOTF(T1, T2) \
T1 applyInverseEOTF(T2 colour, const uint targetEOTF) \
{ \
	switch (targetEOTF) { \
	case EOTF_SRGB: \
		colour = sRGB::iEOTF(colour); \
		break; \
	case EOTF_G22: \
		colour = G22::iEOTF(colour); \
		break; \
	case EOTF_BT1886: \
		colour = BT1886::iEOTF(colour); \
		break; \
	case EOTF_PQ: \
		colour = BT2100::PQ::iEOTF(colour); \
		break; \
	case EOTF_HLG: \
		/* TODO */ \
		/*colour = HLG::iEOTF(colour); */ \
		/*break; */ \
	case EOTF_NONE: \
	default: \
		break; \
	} \
	\
	return colour; \
};
_AUTO_FUNC(_USE_INVERSE_EOTF, float, float);

// Conversion constants
namespace sRGB {
static const float scaleToBT1886 = BT1886::whiteLevel     / whiteLevel;
static const float scaleToHLG    = BT2100::HLG::peakWhite / whiteLevel;
static const float scaleToPQ     = BT2100::PQ::peakWhite  / whiteLevel;
} // namespace ReShadeCMS::sRGB

namespace BT1886 {
static const float scaleToSRGB = sRGB::whiteLevel       / whiteLevel;
static const float scaleToHLG  = BT2100::HLG::peakWhite / whiteLevel;
static const float scaleToPQ   = BT2100::PQ::peakWhite  / whiteLevel;
} // namespace ReShadeCMS::BT1886

namespace BT2100 {
namespace PQ {
static const float scaleToSRGB   = sRGB::whiteLevel       / peakWhite;
static const float scaleToBT1886 = BT1886::whiteLevel     / peakWhite;
static const float scaleToHLG    = BT2100::HLG::peakWhite / peakWhite;
} // namespace ReShadeCMS::BT2100::PQ

namespace HLG {
static const float scaleToSRGB   = sRGB::whiteLevel      / peakWhite;
static const float scaleToBT1886 = BT1886::whiteLevel    / peakWhite;
static const float scaleToPQ     = BT2100::PQ::peakWhite / peakWhite;
} // namespace ReShadeCMS::BT2100::HLG
} // namespace ReShadeCMS::BT2100

} // namespace ReShadeCMS

// vim: filetype=shaderslang
