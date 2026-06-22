#include "ReShade.fxh"

#pragma once

namespace ReShadeCMS
{

// Autocreate function macro statements for overloading multi-component
// versions. Commonly needed with transfer functions.
#define _AUTO_FUNC(_FUNCTION, T1, T2) \
_FUNCTION(T1,    T2   ); \
_FUNCTION(T1##2, T2##2); \
_FUNCTION(T1##3, T2##3);

// ReShade preprocessor translations
#define  COLOUR_SPACE_UNKNOWN  0
#define  COLOUR_SPACE_SRGB     1
#define  COLOUR_SPACE_SCRGB    2
#define  COLOUR_SPACE_PQ       3
#define  COLOUR_SPACE_HLG      4

#if      BUFFER_COLOR_SPACE ==      COLOUR_SPACE_UNKNOWN
#define  BUFFER_COLOR_SPACE_STRING  "Unknown"

#elif    BUFFER_COLOR_SPACE ==      COLOUR_SPACE_SRGB
#define  BUFFER_COLOR_SPACE_STRING  "sRGB"

#elif    BUFFER_COLOR_SPACE ==      COLOUR_SPACE_SCRGB
#define  BUFFER_COLOR_SPACE_STRING  "scRGB"

#elif    BUFFER_COLOR_SPACE ==      COLOUR_SPACE_PQ
#define  BUFFER_COLOR_SPACE_STRING  "PQ"

#elif    BUFFER_COLOR_SPACE ==      COLOUR_SPACE_HLG
#define  BUFFER_COLOR_SPACE_STRING  "HLG"
#endif

// Macro types to help understand what is what at what time. Might redo this or
// get rid of it, but I was hoping it would help understanding and organization.
//
// All nonlinear values are normalized to [0:1] generally (though they can go
// negative, such as when representing out-of-gamut colours).
//
// Linear is essentially Nits, with LinearNorm being normalized to [0:1] like
// the nonlinear values, such as for representing signal values.
//
// The rest should hopefully be self-explanatory
#define  LinearColour            float
#define  LinearColour2           float2
#define  LinearColour3           float3
#define  LinearNormColour        LinearColour
#define  LinearNormColour2       LinearColour2
#define  LinearNormColour3       LinearColour3
#define  NonLinearColour         float
#define  NonLinearColour2        float2
#define  NonLinearColour3        float3
#define  PQColour                NonLinearColour
#define  PQColour2               NonLinearColour2
#define  PQColour3               NonLinearColour3
#define  HLGColour               NonLinearColour
#define  HLGColour2              NonLinearColour2
#define  HLGColour3              NonLinearColour3
#define  BT601Colour             NonLinearColour
#define  BT601Colour2            NonLinearColour2
#define  BT601Colour3            NonLinearColour3
#define  BT709Colour             NonLinearColour
#define  BT709Colour2            NonLinearColour2
#define  BT709Colour3            NonLinearColour3
#define  BT2020Colour            NonLinearColour
#define  BT2020Colour2           NonLinearColour2
#define  BT2020Colour3           NonLinearColour3
#define  ICtCpColour             float3
#define  LMSColour               float3
// CIEColour types:
// Rows = X|Y|Z|x|y, Columns = R|G|B|W
// Examples:
//
//     CIEColour XYZ primaries     CIEColour XYZ white    CIEColour xy primaries      CIEColour xy white
//     CIEXYZColour    x2 x3 x4    CIEXYZColour           CIExyColour     x2 x3 x4    CIExyColour
//     float3 XR XG XB XW    float3 XW        float2 xR xG xB xW    float2 xW
//     float3 YR YG YB YW    float3 YW        float2 yR yG yB yW    float2 yW
//     float3 ZR ZG ZB ZW    float3 ZW
//
// These layouts reflect layouts commonly seen in ITU documentation, and so
// abiding by them should help with correlating code.
#define  CIExyColour    float2
#define  CIExyColour2   float2x2
#define  CIExyColour3   float2x3
#define  CIExyColour4   float2x4
#define  CIExyYColour   float3
#define  CIExyYColour2  float3x2
#define  CIExyYColour3  float3x3
#define  CIExyYColour4  float3x4
#define  CIEXYZColour   float3
#define  CIEXYZColour2  float3x2
#define  CIEXYZColour3  float3x3
#define  CIEXYZColour4  float3x4

// This function, given a colour space's xy primaries + xy white point, returns
// the Normalized Primary Matrix (NPM) used to convert from the input colour
// space to the CIEColour XYZ space.  The inverse of the NPM is used to convert from
// CIEColour XYZ to the colour space, and will be calculated by a separate matrix
// inversion function.

// colourSpace format: Rows are x y. Columns are r g b w.
CIEXYZColour3 calculateNPM(CIExyColour4 colourSpace)
{
    // z = [zR, zG, zB, zW]
    float4 zCoords = 1.0 - (colourSpace[0] + colourSpace[1]);
    float xr = colourSpace[0].r;
    float xg = colourSpace[0].g;
    float xb = colourSpace[0].b;
    float xw = colourSpace[0].a;
    float yr = colourSpace[1].r;
    float yg = colourSpace[1].g;
    float yb = colourSpace[1].b;
    float yw = colourSpace[1].a;
    float zr = zCoords.r;
    float zg = zCoords.g;
    float zb = zCoords.b;
    float zw = zCoords.a;

    // This is ugly. Taken from BT.2408 1:1.
    // TODO: Can we clean this up? Performance doesn't matter too much, this
    // function is only going to be called once per compilation / start-up to
    // save the values to static const variables or something similar.
    return CIEXYZColour3(
        /* XR */
          (((yg*zb-yb*zg)*xw+(xb*zg-xg*zb)*yw+(xg*yb-xb*yg)*zw)*xr)
        / ((xr*(yg*zb-yb*zg)-xg*(yr*zb-yb*zr)+xb*(yr*zg-yg*zr))*yw),
        /* XG */
          (((yb*zr-yr*zb)*xw+(xr*zb-xb*zr)*yw+(xb*yr-xr*yb)*zw)*xg)
        / ((xr*(yg*zb-yb*zg)-xg*(yr*zb-yb*zr)+xb*(yr*zg-yg*zr))*yw),
        /* XB */
          (((yr*zg-yg*zr)*xw+(xg*zr-xr*zg)*yw+(xr*yg-xg*yr)*zw)*xb)
        / ((xr*(yg*zb-yb*zg)-xg*(yr*zb-yb*zr)+xb*(yr*zg-yg*zr))*yw),
        /* YR */
          (((yg*zb-yb*zg)*xw+(xb*zg-xg*zb)*yw+(xg*yb-xb*yg)*zw)*yr)
        / ((xr*(yg*zb-yb*zg)-xg*(yr*zb-yb*zr)+xb*(yr*zg-yg*zr))*yw),
        /* YG */
          (((yb*zr-yr*zb)*xw+(xr*zb-xb*zr)*yw+(xb*yr-xr*yb)*zw)*yg)
        / ((xr*(yg*zb-yb*zg)-xg*(yr*zb-yb*zr)+xb*(yr*zg-yg*zr))*yw),
        /* YB */
          (((yr*zg-yg*zr)*xw+(xg*zr-xr*zg)*yw+(xr*yg-xg*yr)*zw)*yb)
        / ((xr*(yg*zb-yb*zg)-xg*(yr*zb-yb*zr)+xb*(yr*zg-yg*zr))*yw),
        /* ZR */
          (((yg*zb-yb*zg)*xw+(xb*zg-xg*zb)*yw+(xg*yb-xb*yg)*zw)*zr)
        / ((xr*(yg*zb-yb*zg)-xg*(yr*zb-yb*zr)+xb*(yr*zg-yg*zr))*yw),
        /* ZG */
          (((yb*zr-yr*zb)*xw+(xr*zb-xb*zr)*yw+(xb*yr-xr*yb)*zw)*zg)
        / ((xr*(yg*zb-yb*zg)-xg*(yr*zb-yb*zr)+xb*(yr*zg-yg*zr))*yw),
        /* ZB */
          (((yr*zg-yg*zr)*xw+(xg*zr-xr*zg)*yw+(xr*yg-xg*yr)*zw)*zb)
        / ((xr*(yg*zb-yb*zg)-xg*(yr*zb-yb*zr)+xb*(yr*zg-yg*zr))*yw)
    );
};

CIEXYZColour3 calculateNPM(CIExyColour3 primaries, CIExyColour whitePoint)
{
    return calculateNPM(CIExyColour4(
        primaries[0].r, primaries[0].g, primaries[0].b, whitePoint.x,
        primaries[1].r, primaries[1].g, primaries[1].b, whitePoint.y
    ));
};

// Matrix inversion, mainly for finding inverse NPM's
float3x3 invert(float3x3 m)
{
    float mDet = determinant(m);

    float3x3 adjugate = transpose(
        float3x3(
            /* Find the matrix of minors of m */
            determinant(float2x2(m._m11, m._m12,
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
                                 m._m10, m._m11))
        ) * float3x3(
            /* Convert to a matrix of cofactors */
             1.0, -1.0,  1.0,
            -1.0,  1.0, -1.0,
             1.0, -1.0,  1.0
        )
        /* Finally, the transpose switches this to an adjugate matrix */
    );

    /* Divide the adjugate by the original determinant to find the inverse */
    return adjugate / mDet;
};

float2x2 invert(float2x2 m)
{
    float mDet = determinant(m);

    float2x2 adjugate = transpose(
        float2x2(
            /* Find the matrix of minors of m (easy mode on 2x2's)*/
            m._m11, m._m10,
            m._m01, m._m00
        ) * float2x2(
            /* Convert to a matrix of cofactors */
             1.0, -1.0,
            -1.0,  1.0
        )
        /* Finally, the transpose switches this to an adjugate matrix */
    );

    /* Divide the adjugate by the original determinant to find the inverse */
    return adjugate / mDet;
};

namespace Output
{
uniform LinearColour peakWhite <
    ui_type = "slider";
    ui_min = 80.0;
    ui_step = 1.0;
    ui_max = 10000.0;
    ui_label = "Peak White";
    ui_category = "Output Settings";
    ui_units = " nits";
#if defined(RESHADECMS_CUSTOM_DEFAULT_PEAKWHITE)
> = RESHADECMS_CUSTOM_DEFAULT_PEAKWHITE;
#else
> = 1000.0;
#endif

uniform LinearColour diffuseWhite <
    ui_type = "slider";
    ui_min = 1.0;
    ui_step = 1.0;
    ui_max = 405.0;
    ui_label = "Diffuse White";
    ui_category = "Output Settings";
    ui_units = " nits";
#if defined(RESHADECMS_CUSTOM_DEFAULT_DIFFUSEWHITE)
> = RESHADECMS_CUSTOM_DEFAULT_PEAKWHITE;
#else
> = 203.0;
#endif

uniform LinearColour blackLevel <
    ui_type = "slider";
    ui_min = 0.0;
    ui_step = 0.0001;
    ui_max = 1.0;
    ui_label = "Black Level";
    ui_category = "Output Settings";
    ui_units = " nits";
#if defined(RESHADECMS_CUSTOM_DEFAULT_BLACKLEVEL)
> = RESHADECMS_CUSTOM_DEFAULT_BLACKLEVEL;
#else
> = 0.0;
#endif
} // namespace Output

namespace Content
{
#define  ENCODING_LINEAR                0
#define  ENCODING_NONLINEAR_BT601       1
#define  ENCODING_NONLINEAR_BT709       2
#define  ENCODING_NONLINEAR_BT2020      3
#define  ENCODING_NONLINEAR_BT2100_PQ   4
#define  ENCODING_NONLINEAR_BT2100_HLG  5

uniform uint encoding <
    ui_type = "combo";
    ui_items = 
        "Linear \0"
        "Non-linear BT.601 \0"
        "Non-linear BT.709 \0"
        "Non-linear BT.2020 \0"
        "Non-linear BT.2100 PQ \0"
        "Non-linear BT.2100 HLG \0";
    ui_label = "Buffer Encoding";
    ui_category = "Content Settings";
    uiColourext = "Buffer NonLinearColour Space = " BUFFER_COLOR_SPACE_STRING;
> = ENCODING_LINEAR;

#define  EOTF_NONE    0
#define  EOTF_SRGB    1
#define  EOTF_G22     2
#define  EOTF_BT1886  3
#define  EOTF_PQ      4
#define  EOTF_HLG     5

uniform uint oldEOTF <
    ui_type = "combo";
    ui_items = 
        "None \0"
        "sRGB \0"
        "Gamma 2.2 \0"
        "BT.1886 \0"
        "PQ \0"
        "HLG \0";
    ui_label = "Original EOTF";
    ui_category = "Content Settings";
#if BUFFER_COLOR_SPACE == COLOUR_SPACE_PQ
> = EOTF_PQ;
#elif BUFFER_COLOR_SPACE == COLOUR_SPACE_HLG
> = EOTF_HLG;
#else
> = EOTF_SRGB;
#endif

uniform uint newEOTF <
    ui_type = "combo";
    ui_items = 
        "None \0"
        "sRGB \0"
        "Gamma 2.2 \0"
        "BT.1886 \0"
        "PQ \0"
        "HLG \0";
    ui_label = "Override EOTF";
    ui_category = "Content Settings";
#if BUFFER_COLOR_SPACE == COLOUR_SPACE_PQ
> = EOTF_PQ;
#elif BUFFER_COLOR_SPACE == COLOUR_SPACE_HLG
> = EOTF_HLG;
#else
> = EOTF_SRGB;
#endif

uniform LinearColour whiteLevel <
    ui_type = "slider";
    ui_min = 80.0;
    ui_step = 1.0;
    ui_max = 10000.0;
    ui_label = "Peak White";
    ui_category = "Content Settings";
    ui_units = " nits";
> = 4000.0;

uniform LinearColour blackLevel <
    ui_type = "slider";
    ui_min = 0.0;
    ui_step = 0.0001;
    ui_max = 1.0;
    ui_label = "Black Level";
    ui_category = "Content Settings";
    ui_units = " nits";
> = 0.0;

} // namespace Content

namespace WhitePoints
{
    static const CIExyColour D65 = float2(
        0.3127,
        0.3290
    );
}; // namespace WhitePoints

namespace BT601
{
    static const CIExyColour whitePoint = WhitePoints::D65;

    namespace NTSC
    {
        // 525-line
        static const CIExyColour3 primaries = CIExyColour3(
            0.630, 0.310, 0.155,
            0.340, 0.595, 0.070
        );
    } // namespace NTSC

    namespace PAL
    {
        // 625-line
        static const CIExyColour3 primaries = CIExyColour3(
            0.640, 0.290, 0.150,
            0.330, 0.600, 0.060
        );
    } // namespace PAL

} // namespace BT601

namespace BT709
{
    static const CIExyColour whitePoint = WhitePoints::D65;
    static const CIExyColour3 primaries = CIExyColour3(
        0.640, 0.300, 0.150,
        0.330, 0.600, 0.060
    );

    // Neither BT.601 nor BT.709 defined an EOTF, as all CRTs behaved pretty
    // much the same. See BT.1886 for an EOTF that can be used on modern
    // displays for BT.709 and BT.601 content.

} // namespace BT709

namespace BT1886
{
    static const LinearColour whiteLevel = 100.0;
    static const LinearColour blackLevel =   0.0;
    static const float gamma = 2.40;
    // TODO: Does this work? Still learning HLSL / ReShade.
    static float a; // gain / contrast
    static float b; // black level lift / brightness

    float calculateGain(LinearColour LW, LinearColour LB)
    {
        a = (pow(LW, rcp(gamma)) - pow(LB, rcp(gamma)), gamma);
    };

    float calculateBlackLevelLift(LinearColour LW, LinearColour LB)
    {
        b = pow(LB, rcp(gamma)) / (pow(LW, rcp(gamma)) - pow(LB, rcp(gamma)));
    };

    // TODO: Finish implementing the white and black levels compensation
    #define _BT1886_EOTF(T1, T2) \
    T1 EOTF(T2 value) \
    { \
        return sign(value) * pow(abs(value), 2.4); \
    };
    _AUTO_FUNC(_BT1886_EOTF, LinearNormColour, NonLinearColour);

    #define _BT1886_INVERSE_EOTF(T1, T2) \
    T1 iEOTF(T2 value) \
    { \
        return sign(value) * pow(abs(value), rcp(2.4)); \
    };
    _AUTO_FUNC(_BT1886_INVERSE_EOTF, NonLinearColour, LinearNormColour);

} // namespace BT1886

namespace BT2035
{
    static const LinearColour whiteLevel = BT1886::whiteLevel;
} // namespace BT2035

namespace sRGB
{
    static const CIExyColour whitePoint = BT709::whitePoint;
    static const CIExyColour3 primaries = BT709::primaries;
    static const LinearColour whiteLevel = 80.0;

    // Using scRGB's higher-precision functions.
    #define _sRGB_EOTF(T1, T2) \
    T1 EOTF(T2 E) \
    { \
        static const float breakPoint = 0.04045; \
        const T2 ESign = sign(E); \
        E = abs(E); \
        \
        return ESign * (E <= breakPoint \
            ? E / 12.92 \
            : pow((E + 0.055) / 1.055, 2.4)); \
    };
    _AUTO_FUNC(_sRGB_EOTF, LinearColour, BT709Colour);

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
        return ESign * (E <= breakPoint \
            ? 12.92 * E \
            : 1.055 * pow(E, 1.0 / 2.4) - 0.055); \
    };
    _AUTO_FUNC(_sRGB_INVERSE_EOTF, BT709Colour, LinearColour);

} // namespace sRGB

namespace scRGB
{
    static const CIExyColour whitePoint = BT709::whitePoint;
    static const CIExyColour3 primaries = BT709::primaries;
    static const LinearColour peakWhite = 10000.0;
    static const LinearColour diffuseWhite = sRGB::whiteLevel;
} // namespace scRGB

namespace G22
{
    static const LinearColour whiteLevel = BT2035::whiteLevel;

    #define _G22_EOTF(T1, T2) \
    T1 EOTF(T2 value) \
    { \
        return sign(value) * pow(abs(value), 2.2); \
    };
    _AUTO_FUNC(_G22_EOTF, LinearColour, NonLinearColour);

    #define _G22_INVERSE_EOTF(T1, T2) \
    T1 iEOTF(T2 value) \
    { \
        return sign(value) * pow(abs(value), rcp(2.2)); \
    };
    _AUTO_FUNC(_G22_INVERSE_EOTF, NonLinearColour, LinearColour);

} // namespace Gamma22

namespace BT2020
{
    static const CIExyColour whitePoint = WhitePoints::D65;
    static const CIExyColour3 primaries = CIExyColour3(
        0.708, 0.170, 0.131,
        0.292, 0.797, 0.046
    );

    BT709Colour3 toBT709(BT2020Colour3 value)
    {
        static const CIEXYZColour3 testBT2020NPM = CIEXYZColour3(
             0.6370,  0.1446,  0.1689,
             0.2627,  0.6780,  0.0593,
             0.0000,  0.0281,  1.0610
        );
        static const CIEXYZColour3 testBT709InverseNPM = CIEXYZColour3(
             3.240625, -1.537208, -0.498629,
            -0.968931,  1.875756,  0.041518,
             0.055710, -0.204021,  1.056996
        );
        static const CIEXYZColour3 testCoefficients = 
            mul(testBT709InverseNPM, testBT2020NPM);

        static const CIEXYZColour3 BT2020NPM = 
            calculateNPM(primaries, whitePoint);
        static const CIEXYZColour3 BT709InverseNPM = 
            invert(calculateNPM(BT709::primaries, BT709::whitePoint));
        static const CIEXYZColour3 coefficients = mul(BT709InverseNPM, BT2020NPM);

        /* Non-linear to linear conversion from normalized R'G'B' signals
         * E'rE'gE'b (BT.2020) to linear normalized ErEgEb (BT.2020),
         * display-referred */
        value = BT1886::EOTF(value);

        /* Matrix convert linear normalized BT.202 display light to BT.709 */
        value = mul(coefficients, value);

        /* Convert from linear display light back to nonlinear */
        return BT1886::iEOTF(value);
        //return value;
    };
} // namespace BT2020

namespace BT709
{
    BT2020Colour3 toBT2020(BT709Colour3 value)
    {
        static const CIEXYZColour3 testBT709NPM = CIEXYZColour3(
             0.4124,  0.3576,  0.1805,
             0.2126,  0.7152,  0.0722,
             0.0193,  0.1192,  0.9505
        );
        static const CIEXYZColour3 testBT2020InverseNPM = CIEXYZColour3(
             1.7167, -0.3557, -0.2534,
            -0.6667,  1.6165,  0.0158,
             0.0176, -0.0428,  0.9421
        );
        static const CIEXYZColour3 testCoefficients = 
            mul(testBT2020InverseNPM, testBT709NPM);

        static const CIEXYZColour3 BT709NPM = 
            calculateNPM(primaries, whitePoint);
        static const CIEXYZColour3 BT2020InverseNPM = 
            invert(calculateNPM(BT2020::primaries, BT2020::whitePoint));
        static const CIEXYZColour3 coefficients = mul(BT2020InverseNPM, BT709NPM);


        /* Non-linear to linear conversion from normalized R'G'B' signals
         * E'rE'gE'b (BT.709) to linear normalized ErEgEb (BT.709),
         * display-referred */
        value = BT1886::EOTF(value);

        /* Matrix convert linear normalized BT.709 display light to BT.2020 */
        value = max(0.0, mul(coefficients, value));

        /* Convert from linear display light back to nonlinear */
        return BT1886::iEOTF(value);
    };
} // namespace BT709

namespace BT2100
{
    static const CIExyColour whitePoint = BT2020::whitePoint;
    static const CIExyColour3 primaries = BT2020::primaries;
    static const LinearColour diffuseWhite = 203.0;

    namespace PQ
    {
        static const LinearColour peakWhite = 10000.0;
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
            return pow( \
                (max(pow(E, 1.0 / m2) - c1, 0.0)) / (c2 - c3 * pow(E, 1.0 / m2)), \
                1.0 / m1 \
            ); \
        };
        _AUTO_FUNC(_PQ_EOTF, LinearColour, PQColour);

        #define _PQ_INVERSE_EOTF(T1, T2) \
        T1 iEOTF(T2 Y) \
        { \
            return pow((c1 + c2 * pow(Y, m1)) / (1.0 + c3 * pow(Y, m1)), m2); \
        };
        _AUTO_FUNC(_PQ_INVERSE_EOTF, PQColour, LinearColour);



    } // namespace PQ

    namespace HLG
    {
        static const LinearColour peak = 1000.0;
        static const float a = 0.17883277;
        static const float b = 1.0 - 4.0 * a;
        // c requires log(), so will calculate in functions that need it
        static const float gamma = 1.2;

        LinearColour OOTF(LinearColour E)
        {
            
        };

        LinearColour EOTF(HLGColour x)
        {
            static const float c = 0.5 - a * log(4.0 * a);

            /* TODO: Add user gain and black lift adjustments */
            return x <= 0.5
                ? exp2(x)
                : exp(((x - c) / a) + b) / 12.0;
        };
    } // namespace HLG
} // namespace BT2100

namespace RGB
{
    static const float3x3 LMSCoefficients = float3x3(
        // LR LG LB
        // MR MG MB
        // SR SG SB
         1688.0,  2146.0,   262.0,
          683.0,  2951.0,   462.0,
           99.0,   309.0,  3688.0
    );

    float3 toLMS(LinearColour3 colour)
    {
        return float3(
            dot(LMSCoefficients[0], colour),
            dot(LMSCoefficients[1], colour),
            dot(LMSCoefficients[2], colour)
        ) / 4096.0;
    };
}

namespace LMS
{
    namespace PQ
    {
        static const float3x3 ICtCpCoefficients = float3x3(
                  2048.0,   2048.0,     0.0,
                  6610.0, -13613.0,  7003.0,
                 17933.0, -17390.0,  -543.0
        );

        float3 toICtCp(LinearColour3 colour)
        {
            return float3(
                dot(ICtCpCoefficients[0], colour),
                dot(ICtCpCoefficients[1], colour),
                dot(ICtCpCoefficients[2], colour)
                ) / 4096.0;
        };
    }
    namespace HLG
    {
        static const float3x3 ICtCpCoefficients = float3x3(
                2048.0,  2048.0,     0.0,
                3625.0, -7465.0,  3840.0,
                9500.0, -9212.0,  -288.0
        );

        float3 toICtCp(LinearColour3 colour)
        {
            return float3(
                dot(ICtCpCoefficients[0], colour),
                dot(ICtCpCoefficients[1], colour),
                dot(ICtCpCoefficients[2], colour)
                ) / 4096.0;
        };
    }
} // namespace LMS

namespace ICtCp
{
    // ICtCp deals with 16-bit linear RGB
    // Display-referred: 1.0 = 1.0 nit
    // Scene-referred: 1.0 = maximum diffuse white
    
    namespace PQ
    {
    } // namespace ICtCp::PQ
} // namespace ICtCp

namespace XYZ
{
} // namespace XYZ

namespace ToneMapping
{
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
        return ( 2.0 * TOfBCubed - 3.0 * TOfBSquared + 1.0 ) * KS \
             + (       TOfBCubed - 2.0 * TOfBSquared + TOfB) * (1.0 - KS) \
             + (-2.0 * TOfBCubed + 3.0 * TOfBSquared       ) * maxLum; \
    };
    _AUTO_FUNC(_BT2408_P, float, float);

    #define _BT2408_EETF(T1, T2) \
    T1 EETF(T2 e1) \
    { \
        /* Bunch of simplification setup */ \
        float displayBlack = BT2100::PQ::iEOTF(Output::blackLevel / BT2100::PQ::peakWhite); \
        float displayWhite = BT2100::PQ::iEOTF(Output::peakWhite  / BT2100::PQ::peakWhite); \
        float contentBlack = BT2100::PQ::iEOTF(Content::blackLevel / BT2100::PQ::peakWhite); \
        float contentWhite = BT2100::PQ::iEOTF(Content::whiteLevel / BT2100::PQ::peakWhite); \
        float contentRange = contentWhite - contentBlack; \
        \
        /* Step 1: Normalize PQ values based on mastering display */ \
        e1 = (e1 - displayBlack) / contentRange; \
        /* Let's clamp the input to our configured input peak */ \
        e1 = min(1.0, e1); \
        \
        /* Step 1.5: Calculate mastering display black and white in [0:1] PQ */ \
        float minLum = (displayBlack - contentBlack) / contentRange; \
        float maxLum = (displayWhite - contentBlack) / contentRange; \
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
        return e3 * contentRange + contentBlack; \
    };
    _AUTO_FUNC(_BT2408_EETF, PQColour, PQColour);

    float3 inICtCp(float3 ICtCp)
    {
        const float I2 = EETF(ICtCp.x);

        return float3(I2, min(ICtCp.x / I2, I2 / ICtCp.x) * ICtCp.yz);
    };

    float3 inYCbCr(float3 YCbCr)
    {
        const float Y2 = EETF(YCbCr.x);

        return float3(Y2, min(YCbCr.x / Y2, Y2 / YCbCr.x) * YCbCr.yz);
    };

    PQColour3 inRGB(PQColour3 colour)
    {
        return EETF(colour);
    };

} // namespace ToneMapping

namespace Content
{
    #define _CONTENT_EOTF(T1, T2) \
    T1 EOTF(T2 colour) { \
        /* TODO: Account for pre-existing EOTF */ \
        switch (newEOTF) { \
        case EOTF_NONE: \
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
        default: \
            break; \
        } \
        \
        return colour; \
    };
    _AUTO_FUNC(_CONTENT_EOTF, LinearColour, NonLinearColour);

    #define _CONTENT_INVERSE_EOTF(T1, T2) \
    T1 iEOTF(T2 colour) { \
        /* TODO: Account for pre-existing EOTF */ \
        switch (newEOTF) { \
        case EOTF_NONE: \
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
        default: \
            break; \
        } \
        \
        return colour; \
    };
    _AUTO_FUNC(_CONTENT_INVERSE_EOTF, NonLinearColour, LinearColour);
} // namespace Content

} // namespace ReShadeCMS

// vim: filetype=shaderslang ts=4 sts=4 sw=4
