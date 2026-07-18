#include "ReShade.fxh"

#pragma once

namespace ReShadeCMS {

// Autocreate function macro statements for overloading multi-component
// versions. Commonly needed with transfer functions.
#define _AUTO_FUNC(_FUNCTION, T1) \
_FUNCTION(T1); \
_FUNCTION(T1##2); \
_FUNCTION(T1##3); \
_FUNCTION(T1##4);

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

// Safe pow() that reflects over negative
#define _S_POW(T1) \
T1 sPow(const T1 e, const float power) \
{ \
	return sign(e) * pow(abs(e), power); \
};
_AUTO_FUNC(_S_POW, float);

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
//static const float2 A =   float2(0.44758, 0.40745);
//static const float2 D50 = float2(0.34567, 0.35850);
//static const float2 D55 = float2(0.33242, 0.64743);
static const float2 D65 = float2(0.31272, 0.32903);
//static const float2 D75 = float2(0.29902, 0.31485);
static const float2 D93 = float2(0.28315, 0.29711);
//static const float2 E =   float2(0.33333, 0.33333);
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

float deriveY(float3 rgb)
{
	static const float3x3 npm = deriveNPM(specs);
	return dot(npm[1], rgb);
};
} // namespace ReShadeCMS::BT709

namespace BT2035 {
static const float diffuse = 100.0;
static const float black   = 0.0;
} // namespace ReShadeCMS::BT2035

namespace BT1886 {
static const float diffuse = BT2035::diffuse;
static const float black   = BT2035::black;
static const float gamma   = 2.4;

// TODO: Finish implementing the white and black levels compensation
#define _BT1886_EOTF(T1) \
T1 EOTF(const T1 e) \
{ \
	return sPow(e, gamma); \
};
_AUTO_FUNC(_BT1886_EOTF, float);

#define _BT1886_INVERSE_EOTF(T1) \
T1 iEOTF(const T1 e) \
{ \
	return sPow(e, rcp(gamma)); \
};
_AUTO_FUNC(_BT1886_INVERSE_EOTF, float);

} // namespace ReShadeCMS::BT1886

namespace sRGB {
static const float diffuse = 80.0;

// Using scRGB's higher-precision functions, and reflected around negatives
#define _sRGB_EOTF(T1) \
T1 EOTF(const T1 e) \
{ \
	static const float breakPoint = 0.04045; \
	const T1 signE = sign(e); \
	const T1 absE  = abs(e); \
	\
	return signE * (absE <= breakPoint ? absE / 12.92 \
	                                   : pow((absE + 0.055) / 1.055, 2.4)); \
};
_AUTO_FUNC(_sRGB_EOTF, float);

// sRGB standard specifically uses an imprecise inverse EOTF breakPoint.
// It's not exactly the true inverse of the EOTF.
// NOTE: Not sure if the same negative reflection is to be used on inverses
#define _sRGB_INVERSE_EOTF(T1) \
T1 iEOTF(const T1 e) \
{ \
	static const float breakPoint = 0.0031308; \
	const T1 signE = sign(e); \
	const T1 absE  = abs(e); \
	\
	return signE * (absE <= breakPoint ? 12.92 * absE \
	                                   : 1.055 * pow(absE, rcp(2.4)) - 0.055); \
};
_AUTO_FUNC(_sRGB_INVERSE_EOTF, float);

} // namespace ReShadeCMS::sRGB

namespace scRGB {
static const float2 whitePoint = BT709::whitePoint;
static const float3x2 primaries = BT709::primaries;
static const float4x2 specs = float4x2(primaries[0],
                                       primaries[1],
                                       primaries[2],
                                       whitePoint);
static const float peak = 10000.0; // Technically no limit
static const float diffuse = sRGB::diffuse;
} // namespace ReShadeCMS::scRGB

namespace G22 {
static const float diffuse = BT2035::diffuse;
static const float black = BT2035::black;
static const float gamma = 2.2;

#define _G22_EOTF(T1) \
T1 EOTF(T1 e) \
{ \
	return sPow(e, gamma); \
};
_AUTO_FUNC(_G22_EOTF, float);

#define _G22_INVERSE_EOTF(T1) \
T1 iEOTF(T1 e) \
{ \
	return sPow(e, rcp(gamma)); \
};
_AUTO_FUNC(_G22_INVERSE_EOTF, float);

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

float3 toBT709(float3 rgb)
{
	static const float3x3 tra = deriveTRA(specs, BT709::specs);
	static const float3x3 traTest = float3x3( 1.6605, -0.5876, -0.0728,
	                                         -0.1246,  1.1329, -0.0083,
	                                         -0.0182, -0.1006,  1.1187);

	return mul(tra, rgb);
};
} // namespace ReShadeCMS::BT2020

namespace BT709 {
float3 toBT2020(float3 rgb)
{
	static const float3x3 tra = deriveTRA(specs, BT2020::specs);
	static const float3x3 traTest = float3x3(0.6274, 0.3293, 0.0433,
	                                         0.0691, 0.9195, 0.0114,
	                                         0.0164, 0.0880, 0.8956);

	return mul(tra, rgb);
};
} // namespace ReShadeCMS::BT709

namespace BT2100 {
static const float2 whitePoint = BT2020::whitePoint;
static const float3x2 primaries = BT2020::primaries;
static const float4x2 specs = float4x2(primaries[0],
                                       primaries[1],
                                       primaries[2],
                                       whitePoint);
static const float diffuse = 203.0;

float deriveY(float3 rgb)
{
	static const float3x3 npm = deriveNPM(specs);
	return dot(npm[1], rgb);
};

namespace PQ {
static const float peak = 10000.0;
static const float m1 = 2610.0 / 16384.0;
static const float m2 = 2523.0 / 4096.0 * 128.0;
static const float c1 = 3424.0 / 4096.0;
static const float c2 = 2413.0 / 4096.0 * 32.0;
static const float c3 = 2392.0 / 4096.0 * 32.0;

// Content: Non-linear PQ encoded value
// The EOTF maps the non-linear PQ signal into display light.
#define _PQ_EOTF(T1) \
T1 EOTF(T1 E) \
{ \
	return pow(  max(pow(E, rcp(m2)) - c1, 0.0) \
	           / (c2 - c3 * pow(E, rcp(m2))), \
	           rcp(m1)); \
};
_AUTO_FUNC(_PQ_EOTF, float);

#define _PQ_INVERSE_EOTF(T1) \
T1 iEOTF(T1 Y) \
{ \
	return pow(  ( c1 + c2 * pow(Y, m1)) \
	           / (1.0 + c3 * pow(Y, m1)), \
	           m2); \
};
_AUTO_FUNC(_PQ_INVERSE_EOTF, float);



} // namespace ReShadeCMS::BT2100::PQ

namespace HLG {
static const float peak = 1000.0;
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
	return x <= 0.5 ? exp2(x) : exp(((x - c) / a) + b) / 12.0;
};

float iEOTF(float x)
{
	return x;
}
} // namespace ReShadeCMS::BT2100::HLG
} // namespace ReShadeCMS::BT2100

namespace RGB {
static const float3x3 lmsCoeffs = float3x3(1688.0,  2146.0,   262.0,
	                                    683.0,  2951.0,   462.0,
	                                     99.0,   309.0,  3688.0) / 4096.0;

float3 toLMS(float3 rgb)
{
	return mul(lmsCoeffs, rgb);
};
} // namespace ReShadeCMS::RGB

namespace LMS {
float3 toRGB(float3 lms)
{
	static const float3x3 rgbCoeffs = inverse(RGB::lmsCoeffs);
	return mul(rgbCoeffs, lms);
}

namespace PQ {
static const float3x3 iCtCpCoeffs = float3x3( 2048.0,   2048.0,     0.0,
                                              6610.0, -13613.0,  7003.0,
                                             17933.0, -17390.0,  -543.0)
                                             / 4096.0;

float3 toICtCp(float3 lms)
{
	return mul(iCtCpCoeffs, BT2100::PQ::iEOTF(lms));
};

} // namespace ReShadeCMS::LMS::PQ

namespace HLG {
static const float3x3 iCtCpCoeffs = float3x3(2048.0,  2048.0,     0.0,
                                             3625.0, -7465.0,  3840.0,
                                             9500.0, -9212.0,  -288.0)
                                             / 4096.0;

/*
float3 toICtCp(float3 lms)
{
	return mul(iCtCpCoeffs, BT2100::HLG::iEOTF(lms));
};
*/
float3 toICtCp(float3 lms)
{
	return lms;
}
} // namespace ReShadeCMS::LMS::HLG
} // namespace ReShadeCMS::LMS

namespace ICtCp {
// ICtCp deals with 16-bit linear RGB
// Display-referred: 1.0 = 1.0 nit
// Scene-referred: 1.0 = maximum diffuse white

namespace PQ {
float3 toLMS(float3 iCtCp)
{
	static const float3x3 lmsCoeffs = inverse(LMS::PQ::iCtCpCoeffs);

	return BT2100::PQ::EOTF(mul(lmsCoeffs, iCtCp));
};
} // namespace ReShadeCMS::ICtCp::PQ

namespace HLG {
float3 toLMS(float3 iCtCp)
{
	static const float3x3 lmsCoeffs = inverse(LMS::HLG::iCtCpCoeffs);

	return HLG::EOTF(mul(lmsCoeffs, iCtCp));
};
} // namespace ReShadeCMS::ICtCp::HLG

} // namespace ReShadeCMS::ICtCp

namespace ToneMapping {
#define _BT2408_T(T1) \
T1 t(const T1 a, const float ks) \
{ \
	return (a - ks) / (1.0 - ks); \
};
_AUTO_FUNC(_BT2408_T, float);

#define _BT2408_P(T1) \
T1 p(const T1 b, const float ks, const float maxLum) \
{ \
	const T1 tOfB        = t(b, ks); \
	const T1 tOfBSquared = pow(tOfB, 2.0); \
	const T1 tOfBCubed   = pow(tOfB, 3.0); \
	\
	/* Hermite spline */ \
	return    ( 2.0 * tOfBCubed - 3.0 * tOfBSquared + 1.0 ) * ks \
	        + (       tOfBCubed - 2.0 * tOfBSquared + tOfB) * (1.0 - ks) \
	        + (-2.0 * tOfBCubed + 3.0 * tOfBSquared       ) * maxLum; \
};
_AUTO_FUNC(_BT2408_P, float);

#define _BT2408_EETF(T1) \
T1 EETF(T1 e1, const float dstPeak, const float dstBlack, \
               const float srcPeak, const float srcBlack) \
{ \
	/* Bunch of simplification setup */ \
	float dstBlackNl = BT2100::PQ::iEOTF(dstBlack / BT2100::PQ::peak); \
	float dstPeakNl  = BT2100::PQ::iEOTF(dstPeak  / BT2100::PQ::peak); \
	float srcBlackNl = BT2100::PQ::iEOTF(srcBlack / BT2100::PQ::peak); \
	float srcPeakNl  = BT2100::PQ::iEOTF(srcPeak  / BT2100::PQ::peak); \
	float srcRangeNl = srcPeakNl - srcBlackNl; \
	\
	/* Step 1: Normalize PQ values based on mastering display */ \
	e1 = (e1 - srcBlackNl) / srcRangeNl; \
	\
	/* Step 1.5: Calculate mastering display black and white in [0:1] PQ */ \
	float minLum = (dstBlackNl - srcBlackNl) / srcRangeNl; \
	float maxLum = (dstPeakNl  - srcBlackNl) / srcRangeNl; \
	\
	/* Step 2: Calculate 1:1 mapping and knee (?) */ \
	float ks = 1.5 * maxLum - 0.5; \
	\
	/* Step 3: Solve for EETF (e3) with given end points */ \
	T1 e2 = e1 < ks ? e1 : p(e1, ks, maxLum); \
	T1 e3 = e2 + minLum * pow(1.0 - e2, 4.0); \
	\
	/* Step 4: Hermite spline equations (functions p(...) and t(...)) */ \
	\
	/* Step 5: Invert normalization of PQ values */ \
	return e3 * srcRangeNl + srcBlackNl; \
};
_AUTO_FUNC(_BT2408_EETF, float);

// Preserves hue well and is a perceputal colour difference space
// Includes a desaturation function.
float3 inICtCp(float3 iCtCp, float dstPeak, float dstBlack,
                             float srcPeak, float srcBlack)
{
	const float i2 = EETF(iCtCp.x, dstPeak, dstBlack, srcPeak, srcBlack);

	return float3(i2, min(iCtCp.x / i2, i2 / iCtCp.x) * iCtCp.yz);
};

// Preserves chroma / hue. Does not involve any desaturation
float3 inYRGB(float3 rgb, float dstPeak, float dstBlack,
                          float srcPeak, float srcBlack)
{
	static const float3x3 npm = deriveNPM(BT2100::specs);
	float y1 = BT2100::deriveY(rgb);
	float y2 = BT2100::PQ::EOTF(EETF(BT2100::PQ::iEOTF(y1),
	                                 dstPeak, dstBlack,
	                                 srcPeak, srcBlack));
	
	return (y2 / y1) * rgb;
};

// R'G'B'. Highly desaturates and can cause noticeable hue change.
float3 inNlRGB(float3 rgb, float dstPeak, float dstBlack,
                           float srcPeak, float srcBlack)
{
	return EETF(rgb, dstPeak, dstBlack, srcPeak, srcBlack);
};

// Preserves chroma but at the expense of lightness. Can look very un-natural
float3 inMaxRGB(float3 rgb, float dstPeak, float dstBlack,
                            float srcPeak, float srcBlack)
{
	float m1 = max(max(rgb.r, rgb.g), rgb.b);
	float m2 = BT2100::PQ::EOTF(EETF(BT2100::PQ::iEOTF(m1),
	                                 dstPeak, dstBlack,
	                                 srcPeak, srcBlack));

	return (m2 / m1) * rgb;
};

} // namespace ReShadeCMS::ToneMapping

// Does nothing in SDR (no point), but in HDR will switch the normalization of
// values between different colour space formats. For example: convertNorm(rgb,
// scRGB, PQ) would divide rgb by 125, so that 125.0 = 10k in scRGB would be 1.0
// = 10k in PQ.
// In Performance Mode, this should inline to the appropriate scaleTo
// multiplication with no performance hit.
#define _CONVERT_NORMALIZATION(T1) \
T1 convertNorm(const T1 rgb, const uint srcSpace, const uint dstSpace) \
{ \
	switch(srcSpace) { \
	case COLOUR_SPACE_SCRGB: \
		switch(dstSpace) { \
		case COLOUR_SPACE_PQ: \
			return rgb * (scRGB::diffuse / BT2100::PQ::peak); \
		case COLOUR_SPACE_HLG: \
			return rgb * (scRGB::diffuse / BT2100::HLG::peak); \
		default: \
			return rgb; \
		} \
		break; \
	case COLOUR_SPACE_PQ: \
		switch(dstSpace) { \
		case COLOUR_SPACE_SCRGB: \
			return rgb * (BT2100::PQ::peak / scRGB::diffuse); \
		case COLOUR_SPACE_HLG: \
			return rgb * (BT2100::PQ::peak / BT2100::HLG::peak); \
		default: \
			return rgb; \
		} \
		break; \
	case COLOUR_SPACE_HLG: \
		switch(dstSpace) { \
		case COLOUR_SPACE_SCRGB: \
			return rgb * (BT2100::HLG::peak / scRGB::diffuse); \
		case COLOUR_SPACE_PQ: \
			return rgb * (BT2100::HLG::peak / BT2100::PQ::peak); \
		default: \
			return rgb; \
		} \
		break; \
	default: \
		return rgb; \
	} \
};
_AUTO_FUNC(_CONVERT_NORMALIZATION, float);

#define _APPLY_EOTF(T1) \
T1 applyEOTF(const T1 e, const uint eotf) \
{ \
	switch (eotf) { \
	case EOTF_SRGB: \
		return sRGB::EOTF(e); \
	case EOTF_G22: \
		return G22::EOTF(e); \
	case EOTF_BT1886: \
		return BT1886::EOTF(e); \
	case EOTF_PQ: \
		return BT2100::PQ::EOTF(e); \
	case EOTF_HLG: \
		/*return BT2100::HLG::EOTF(e);*/ \
	default: \
		return e; \
	} \
};
_AUTO_FUNC(_APPLY_EOTF, float);

#define _APPLY_INVERSE_EOTF(T1) \
T1 applyInverseEOTF(const T1 e, const uint eotf) \
{ \
	switch (eotf) { \
	case EOTF_SRGB: \
		return sRGB::iEOTF(e); \
	case EOTF_G22: \
		return G22::iEOTF(e); \
	case EOTF_BT1886: \
		return BT1886::iEOTF(e); \
	case EOTF_PQ: \
		return BT2100::PQ::iEOTF(e); \
	case EOTF_HLG: \
		/*return BT2100::HLG::iEOTF(e);*/ \
	default: \
		return e; \
	} \
};
_AUTO_FUNC(_APPLY_INVERSE_EOTF, float);

namespace Buffer {
#define _BUFFER_LINEARIZE(T1) \
T1 linearize(const T1 e) \
{ \
	switch (BUFFER_COLOR_SPACE) { \
	case COLOUR_SPACE_SRGB: \
		return applyEOTF(e, EOTF_SRGB); \
	case COLOUR_SPACE_PQ: \
		return applyEOTF(e, EOTF_PQ); \
	case COLOUR_SPACE_HLG: \
		/*return applyEOTF(e, EOTF_HLG);*/ \
	default: \
		return e; \
	} \
};
_AUTO_FUNC(_BUFFER_LINEARIZE, float);

#define _BUFFER_UNLINEARIZE(T1) \
T1 unlinearize(const T1 e) \
{ \
	switch (BUFFER_COLOR_SPACE) { \
	case COLOUR_SPACE_SRGB: \
		return applyInverseEOTF(e, EOTF_SRGB); \
	case COLOUR_SPACE_PQ: \
		return applyInverseEOTF(e, EOTF_PQ); \
	case COLOUR_SPACE_HLG: \
		/*return applyInverseEOTF(e, EOTF_HLG);*/ \
	default: \
		return e; \
	} \
};
_AUTO_FUNC(_BUFFER_UNLINEARIZE, float);

#define _BUFFER_NORMALIZE_TO(T1) \
T1 normalizeTo(const T1 e, const uint dstSpace) \
{ \
	return convertNorm(e, BUFFER_COLOR_SPACE, dstSpace); \
};
_AUTO_FUNC(_BUFFER_NORMALIZE_TO, float);

#define _BUFFER_NORMALIZE_FROM(T1) \
T1 normalizeFrom(const T1 e, const uint srcSpace) \
{ \
	return convertNorm(e, srcSpace, BUFFER_COLOR_SPACE); \
};
_AUTO_FUNC(_BUFFER_NORMALIZE_FROM, float);

#define _BUFFER_TO_NITS(T1) \
T1 toNits(const T1 e) \
{ \
	switch (BUFFER_COLOR_SPACE) { \
	case COLOUR_SPACE_SCRGB: \
		return e * sRGB::diffuse; \
	case COLOUR_SPACE_PQ: \
		return e * BT2100::PQ::peak; \
	case COLOUR_SPACE_HLG: \
		return e * BT2100::HLG::peak; \
	default: \
		return e; \
	} \
};
_AUTO_FUNC(_BUFFER_TO_NITS, float);

#define _BUFFER_FROM_NITS(T1) \
T1 fromNits(const T1 e) \
{ \
	switch (BUFFER_COLOR_SPACE) { \
	case COLOUR_SPACE_SCRGB: \
		return e / sRGB::diffuse; \
	case COLOUR_SPACE_PQ: \
		return e / BT2100::PQ::peak; \
	case COLOUR_SPACE_HLG: \
		return e / BT2100::HLG::peak; \
	default: \
		return e; \
	} \
};
_AUTO_FUNC(_BUFFER_FROM_NITS, float);

float deriveY(const float3 rgb)
{
	switch (BUFFER_COLOR_SPACE) {
	case COLOUR_SPACE_SRGB:
	case COLOUR_SPACE_SCRGB:
		return BT709::deriveY(rgb);
	case COLOUR_SPACE_PQ:
	case COLOUR_SPACE_HLG:
		return BT2100::deriveY(rgb);
	default:
		return rgb;
	}
};

} // namespace ReShadeCMS::Buffer

namespace PLUGE {
// TODO: Well, this is partly some BT2100-specific info. So probably need to
// rethink which namespace they go in.
static const int narrowBlack =  256.0;
static const int narrowPeak  = 3760.0;
static const int narrowRange = narrowPeak - narrowBlack;

#if defined(BUFFER_IS_HDR)
static const float higherLevel          = (1596.0 - narrowBlack) / narrowRange;
static const float slightlyDarkerLevel  = ( 192.0 - narrowBlack) / narrowRange;
static const float slightlyLighterLevel = ( 320.0 - narrowBlack) / narrowRange;
#else
static const float higherLevel          = (3760.0 - narrowBlack) / narrowRange;
static const float slightlyDarkerLevel  = ( 192.0 - narrowBlack) / narrowRange;
static const float slightlyLighterLevel = ( 320.0 - narrowBlack) / narrowRange;
#endif
} // namespace ReShadeCMS::PLUGE

} // namespace ReShadeCMS

// vim: filetype=shaderslang
