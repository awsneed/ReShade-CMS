#include "ReShade.fxh"

#pragma once

// Autocreate function macro statements for overloading multi-component
// versions. Commonly needed with transfer functions.
#define _AUTO_FUNC(_FUNCTION, T1, T2)                                          \
_FUNCTION(T1,    T2   );                                                       \
_FUNCTION(T1##2, T2##2);                                                       \
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
// Generally normalized to [0:1] but sRGB / scRGB can go beyond. In that case,
// 0.0 = 0.0 black, and 1.0 = 80 nits, with 2.0 = 160 nits and so on. The
// negatives are for expanded gamut colours.
#define  Linear             float
#define  Linear2            float2
#define  Linear3            float3
#define  Nonlinear          float
#define  Nonlinear2         float2
#define  Nonlinear3         float3
#define  PQNonlinear        Nonlinear
#define  PQNonlinear2       Nonlinear2
#define  PQNonlinear3       Nonlinear3
#define  HLGNonlinear       Nonlinear
#define  HLGNonlinear2      Nonlinear2
#define  HLGNonlinear3      Nonlinear3
#define  BT601Nonlinear     Nonlinear
#define  BT601Nonlinear2    Nonlinear2
#define  BT601Nonlinear3    Nonlinear3
#define  BT709Nonlinear     Nonlinear
#define  BT709Nonlinear2    Nonlinear2
#define  BT709Nonlinear3    Nonlinear3
#define  BT2020Nonlinear    Nonlinear
#define  BT2020Nonlinear2   Nonlinear2
#define  BT2020Nonlinear3   Nonlinear3
#define  Nits               Linear
#define  Nits2              Linear2
#define  Nits3              Linear3
// Rows = X|Y|Z|x|y, Columns = R|G|B|W
// Examples:
//
//     CIEXYZ primaries      CIEXYZ white    CIExy primaries       CIExy white
//               x2 x3 x4                              x2 x3 x4   
//     float3 XR XG XB XW    float3 XW       float2 xR xG xB xW    float2 xW
//     float3 YR YG YB YW    float3 YW       float2 yR yG yB yW    float2 yW
//     float3 ZR ZG ZB ZW    float3 ZW
//
// These layouts reflect layouts commonly seen in ITU documentation, and so
// abiding by them should help with correlating to code.
#define  CIExy       float2
#define  CIExy2      float2x2
#define  CIExy3      float2x3
#define  CIExy4      float2x4
#define  CIExyz      float3
#define  CIExyz2     float3x2
#define  CIExyz3     float3x3
#define  CIExyz4     float3x4
#define  CIExyY      float3
#define  CIExyY2     float3x2
#define  CIExyY3     float3x3
#define  CIExyY4     float3x4
#define  CIEXYZ      float3
#define  CIEXYZ2     float3x2
#define  CIEXYZ3     float3x3
#define  CIEXYZ4     float3x4

// This function, given a colour space's xy primaries + xy white point, returns
// the Normalized Primary Matrix (NPM) used to convert from the input colour
// space to the CIE XYZ space.  The inverse of the NPM is used to convert from
// CIE XYZ to the colour space, and will be calculated by a separate matrix
// inversion function.
CIEXYZ3 calculateNPM(CIExy4 colourSpaceSpecs) {
    // z = [zR, zG, zB, zW]
    float4 zCoords = 1.0 - (colourSpaceSpecs[0] + colourSpaceSpecs[1]);
    float xr = colourSpaceSpecs[0].r;
    float xg = colourSpaceSpecs[0].g;
    float xb = colourSpaceSpecs[0].b;
    float xw = colourSpaceSpecs[0].a;
    float yr = colourSpaceSpecs[1].r;
    float yg = colourSpaceSpecs[1].g;
    float yb = colourSpaceSpecs[1].b;
    float yw = colourSpaceSpecs[1].a;
    float zr = zCoords.r;
    float zg = zCoords.g;
    float zb = zCoords.b;
    float zw = zCoords.a;

    // This is ugly. Taken from BT.2408 1:1.
    // TODO: Can we clean this up? Performance doesn't matter too much, this
    // function is only going to be called once per compilation / start-up to
    // save the values to static const variables or something similar.
    return CIEXYZ3(
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

CIEXYZ3 calculateNPM(CIExy3 primaries, CIExy whitePoint) {
    return calculateNPM(CIExy4(
        primaries[0].r, primaries[0].g, primaries[0].b, whitePoint.x,
        primaries[1].r, primaries[1].g, primaries[1].b, whitePoint.y
    ));
};

// Matrix inversion, mainly for finding inverse NPM's
float3x3 invert(float3x3 m) {
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

float2x2 invert(float2x2 m) {
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

namespace Display {
uniform Nits peakWhite <
    ui_type = "slider";
    ui_min = 80.0;
    ui_step = 1.0;
    ui_max = 10000.0;
    ui_label = "Peak White";
    ui_category = "Display Settings";
    ui_units = " nits";
> = 1000.0;

uniform Nits diffuseWhite <
    ui_type = "slider";
    ui_min = 1.0;
    ui_step = 1.0;
    ui_max = 405.0;
    ui_label = "Diffuse White";
    ui_category = "Display Settings";
    ui_units = " nits";
> = 203.0;

uniform Nits blackLevel <
    ui_type = "slider";
    ui_min = 0.0;
    ui_step = 0.0001;
    ui_max = 1.0;
    ui_label = "Black Level";
    ui_category = "Display Settings";
    ui_units = " nits";
> = 0.0;
}

namespace Content {
#define  ENCODING_LINEAR            0
#define  ENCODING_NONLINEAR_BT709   1
#define  ENCODING_NONLINEAR_BT2020  2
#define  ENCODING_NONLINEAR_PQ      3
#define  ENCODING_NONLINEAR_HLG     4
#define  ENCODING_NONLINEAR_BT601   5

uniform uint encoding <
    ui_type = "combo";
    ui_items = 
        "Linear\0"
        "Non-linear BT.709\0"
        "Non-linear BT.2020\0"
        "Non-linear PQ\0"
        "Non-linear HLG\0";
    ui_label = "Encoding";
    ui_category = "Content Settings";
    ui_text = "Buffer Colour Space = " BUFFER_COLOR_SPACE_STRING;
> = ENCODING_LINEAR;

#define  EOTF_NONE    0
#define  EOTF_SRGB    1
#define  EOTF_G22     2
#define  EOTF_BT1886  3
#define  EOTF_PQ      4
#define  EOTF_HLG     5

uniform uint overrideEOTF <
    ui_type = "combo";
    ui_items = 
        "None\0"
        "sRGB\0"
        "Gamma 2.2\0"
        "BT.1886\0"
        "PQ\0"
        "HLG\0";
    ui_label = "EOTF Override";
    ui_category = "Content Settings";
> = EOTF_SRGB;

uniform Nits whiteLevel <
    ui_type = "slider";
    ui_min = 80.0;
    ui_step = 1.0;
    ui_max = 10000.0;
    ui_label = "Peak White";
    ui_category = "Content Settings";
    ui_units = " nits";
> = 4000.0;

uniform Nits blackLevel <
    ui_type = "slider";
    ui_min = 0.0;
    ui_step = 0.0001;
    ui_max = 1.0;
    ui_label = "Black Level";
    ui_category = "Content Settings";
    ui_units = " nits";
> = 0.0000;

} // namespace Content


namespace Illuminant {
    static const CIExy D65 = float2(
        0.3127,
        0.3290
    );
}; // namespace Illuminant

namespace BT601 {
    static const CIExy whitePoint = Illuminant::D65;

    namespace NTSC {
        // 525-line
        static const CIExy3 primaries = CIExy3(
            0.630, 0.310, 0.155,
            0.340, 0.595, 0.070
        );
    } // namespace NTSC

    namespace PAL {
        // 625-line
        static const CIExy3 primaries = CIExy3(
            0.640, 0.290, 0.150,
            0.330, 0.600, 0.060
        );
    } // namespace PAL

} // namespace BT601

namespace BT709 {
    static const CIExy whitePoint = Illuminant::D65;
    static const CIExy3 primaries = CIExy3(
        0.640, 0.300, 0.150,
        0.330, 0.600, 0.060
    );

    // Neither BT.601 nor BT.709 defined an EOTF, as all CRTs behaved pretty
    // much the same.  See BT.1886 for an EOTF that can be used on modern
    // displays for BT.709 and BT.601 content.

} // namespace BT709

namespace BT2035 {
    static const Nits whiteLevel = 100.0;
} // namespace BT2035

namespace sRGB {
    static const CIExy whitePoint = BT709::whitePoint;
    static const CIExy3 primaries = BT709::primaries;
    static const Nits whiteLevel = 80.0;

    // Using scRGB's higher-precision functions.
    #define _SRGB_EOTF(T1, T2)                                                 \
    T1 EOTF(T2 E)                                                              \
    {                                                                          \
        static const float breakPoint = 0.04045;                               \
        const T2 ESign = sign(E);                                              \
        E = abs(E);                                                            \
                                                                               \
        return ESign * (E <= breakPoint                                        \
            ? E / 12.92                                                        \
            : pow((E + 0.055) / 1.055, 2.4));                                  \
    };
    _AUTO_FUNC(_SRGB_EOTF, Linear, BT709Nonlinear);

    // sRGB standard specifically uses an imprecise inverse EOTF breakPoint.
    // It's not exactly the true inverse of the EOTF.
    // NOTE: Not sure if the same negative reflection is to be used on inverses
    #define _SRGB_INVERSE_EOTF(T1, T2)                                         \
    T1 iEOTF(T2 E)                                                             \
    {                                                                          \
        static const float breakPoint = 0.0031308;                             \
        const T2 ESign = sign(E);                                              \
        E = abs(E);                                                            \
                                                                               \
        return ESign * (E <= breakPoint                                        \
            ? 12.92 * E                                                        \
            : 1.055 * pow(E, 1.0 / 2.4) - 0.055);                              \
    };
    _AUTO_FUNC(_SRGB_INVERSE_EOTF, BT709Nonlinear, Linear);

} // namespace sRGB

namespace scRGB {
    static const CIExy whitePoint = BT709::whitePoint;
    static const CIExy3 primaries = BT709::primaries;
    static const Nits peakWhite = 10000.0;
    static const Nits diffuseWhite = sRGB::whiteLevel;
} // namespace scRGB

#define _POWER_LAW_GAMMA(T1, T2)                                               \
T1 powerLawGamma(T2 value, float power)                                        \
{                                                                              \
    return pow(value, power);                                                  \
};
_AUTO_FUNC(_POWER_LAW_GAMMA, Linear, Nonlinear);

#define _INVERSE_POWER_LAW_GAMMA(T1, T2)                                       \
T1 inversePowerLawGamma(T2 value, float power)                                 \
{                                                                              \
    return pow(value, 1.0 / power);                                            \
};
_AUTO_FUNC(_INVERSE_POWER_LAW_GAMMA, Nonlinear, Linear);

namespace G22 {
    static const Nits whiteLevel = BT2035::whiteLevel;

    #define _G22_EOTF(T1, T2)                                                  \
    T1 EOTF(T2 value)                                                          \
    {                                                                          \
        return sign(value) * powerLawGamma(abs(value), 2.2);                   \
    };
    _AUTO_FUNC(_G22_EOTF, Linear, Nonlinear);

    #define _G22_INVERSE_EOTF(T1, T2)                                          \
    T1 iEOTF(T2 value)                                                         \
    {                                                                          \
        return sign(value) * inversePowerLawGamma(abs(value), 2.2);            \
    };
    _AUTO_FUNC(_G22_INVERSE_EOTF, Nonlinear, Linear);

} // namespace Gamma22

namespace BT1886 {
    // TODO: Consider configurable display peak and display black levels for
    // BT1886's scaling properties.
    //
    // NOTE: For now, assumes peak = 100.0 and black = 0.0, making it
    // effectively power law gamma 2.4.
    static const Nits whiteLevel = BT2035::whiteLevel;
    static const Nits blackLevel = 0.0;

    #define _BT1886_EOTF(T1, T2)                                               \
    T1 EOTF(T2 value)                                                          \
    {                                                                          \
        return sign(value) * powerLawGamma(abs(value), 2.4);                   \
    };
    _AUTO_FUNC(_BT1886_EOTF, Linear, Nonlinear);

    #define _BT1886_INVERSE_EOTF(T1, T2)                                       \
    T1 iEOTF(T2 value)                                                         \
    {                                                                          \
        return sign(value) * inversePowerLawGamma(abs(value), 2.4);            \
    };
    _AUTO_FUNC(_BT1886_INVERSE_EOTF, Nonlinear, Linear);

} // namespace BT1886

namespace BT2020 {
    static const CIExy whitePoint = Illuminant::D65;
    static const CIExy3 primaries = CIExy3(
        0.708, 0.170, 0.131,
        0.292, 0.797, 0.046
    );

    BT709Nonlinear3 toBT709(BT2020Nonlinear3 value)
    {
        static const CIEXYZ3 testBT2020NPM = CIEXYZ3(
             0.6370,  0.1446,  0.1689,
             0.2627,  0.6780,  0.0593,
             0.0000,  0.0281,  1.0610
        );
        static const CIEXYZ3 testBT709InverseNPM = CIEXYZ3(
             3.240625, -1.537208, -0.498629,
            -0.968931,  1.875756,  0.041518,
             0.055710, -0.204021,  1.056996
        );
        static const CIEXYZ3 testCoefficients = 
            mul(testBT709InverseNPM, testBT2020NPM);

        static const CIEXYZ3 BT2020NPM = 
            calculateNPM(primaries, whitePoint);
        static const CIEXYZ3 BT709InverseNPM = 
            invert(calculateNPM(BT709::primaries, BT709::whitePoint));
        static const CIEXYZ3 coefficients = mul(BT709InverseNPM, BT2020NPM);

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

namespace BT709 {
    BT2020Nonlinear3 toBT2020(BT709Nonlinear3 value)
    {
        static const CIEXYZ3 testBT709NPM = CIEXYZ3(
             0.4124,  0.3576,  0.1805,
             0.2126,  0.7152,  0.0722,
             0.0193,  0.1192,  0.9505
        );
        static const CIEXYZ3 testBT2020InverseNPM = CIEXYZ3(
             1.7167, -0.3557, -0.2534,
            -0.6667,  1.6165,  0.0158,
             0.0176, -0.0428,  0.9421
        );
        static const CIEXYZ3 testCoefficients = 
            mul(testBT2020InverseNPM, testBT709NPM);

        static const CIEXYZ3 BT709NPM = 
            calculateNPM(primaries, whitePoint);
        static const CIEXYZ3 BT2020InverseNPM = 
            invert(calculateNPM(BT2020::primaries, BT2020::whitePoint));
        static const CIEXYZ3 coefficients = mul(BT2020InverseNPM, BT709NPM);


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

namespace BT2100 {
    static const Nits diffuseWhite = 203.0;
} // namespace BT2100

namespace PQ {
    static const CIExy whitePoint = BT2020::whitePoint;
    static const CIExy3 primaries = BT2020::primaries;

    static const Nits peakWhite = 10000.0;
    static const Nits diffuseWhite = BT2100::diffuseWhite;

    static const float m1 = 2610.0 / 16384.0;
    static const float m2 = 2523.0 / 4096.0 * 128.0;
    static const float c1 = 3424.0 / 4096.0;
    static const float c2 = 2413.0 / 4096.0 * 32.0;
    static const float c3 = 2392.0 / 4096.0 * 32.0;

    // Content: Non-linear PQ encoded value
    // The EOTF maps the non-linear PQ signal into display light.
    #define _PQ_EOTF(T1, T2)                                                   \
    T1 EOTF(T2 E)                                                              \
    {                                                                          \
        return pow(                                                            \
            (max(pow(E, 1.0 / m2) - c1, 0.0)) / (c2 - c3 * pow(E, 1.0 / m2)),  \
            1.0 / m1                                                           \
        );                                                                     \
    };
    _AUTO_FUNC(_PQ_EOTF, Linear, PQNonlinear);

    #define _PQ_INVERSE_EOTF(T1, T2)                                           \
    T1 iEOTF(T2 Y)                                                             \
    {                                                                          \
        return pow((c1 + c2 * pow(Y, m1)) / (1.0 + c3 * pow(Y, m1)), m2);      \
    };
    _AUTO_FUNC(_PQ_INVERSE_EOTF, PQNonlinear, Linear);

} // namespace PQ

namespace HLG {
    static const CIExy whitePoint = BT2020::whitePoint;
    static const CIExy3 primaries = BT2020::primaries;

    static const Nits peak = 1000.0;
    static const Nits diffuse = BT2100::diffuseWhite;

    static const float a = 0.17883277;
    static const float b = 1.0 - 4.0 * a;
    // Can't use functions outside of functions, so pre-computed log(4.0 * a)
    static const float c = 0.5 - a * -0.3350097945111627;
    static const float gamma = 1.2;

} // namespace HLG

namespace ICtCp {
    // ICtCp deals with 16-bit linear RGB
    // Display-referred: 1.0 = 1.0 nit
    // Scene-referred: 1.0 = maximum diffuse white
    
    static const float3x3 LMSCoefficients = float3x3(
        // LR LG LB
        // MR MG MB
        // SR SG SB
         1688.0, 2146.0, 262.0,
         683.0, 2951.0, 462.0,
         99.0, 309.0, 3688.0
    );

    namespace PQ {
        static const float3x3 ICtCpCoefficients = float3x3(
              2048.0,   2048.0,     0.0,
              6610.0, -13613.0,  7003.0,
             17933.0, -17390.0,  -543.0
        );

        float3 encode(Nits3 RGBColour) {
            float3 LMSNonlinear = PQ::iEOTF(
                mul(LMSCoefficients, RGBColour) / 4096.0
            );

            return mul(ICtCpCoefficients, LMSNonlinear) / 4096;
        };

        float3 decode(float3 ICtCpColour) {
            static const float3x3 iICtCpCoefficients = invert(ICtCpCoefficients);
            static const float3x3 iLMSCoefficients   = invert(LMSCoefficients);

            float3 LMSNonlinear = mul(iICtCpCoefficients, ICtCpColour * 4096.0);

            return mul(iLMSCoefficients,
                PQ::EOTF(LMSNonlinear) * 4096.0
            );
        }
    } // namespace ICtCp::PQ
} // namespace ICtCp

namespace XYZ {
} // namespace XYZ

namespace Tonemapping {
    #define _BT2408_T(T1, T2)                                                  \
    T1 T(T2 A, float KS)                                                       \
    {                                                                          \
        return (A - KS) / (1.0 - KS);                                          \
    };
    _AUTO_FUNC(_BT2408_T, float, float);

    #define _BT2408_P(T1, T2)                                                  \
    T1 P(T2 B, float KS, float maxLum)                                         \
    {                                                                          \
        T2 TOfB        = T(B, KS);                                             \
        T2 TOfBSquared = pow(TOfB, 2.0);                                       \
        T2 TOfBCubed   = pow(TOfB, 3.0);                                       \
                                                                               \
        /* Hermite spline */                                                   \
        return ( 2.0 * TOfBCubed - 3.0 * TOfBSquared + 1.0 ) * KS              \
             + (       TOfBCubed - 2.0 * TOfBSquared + TOfB) * (1.0 - KS)      \
             + (-2.0 * TOfBCubed + 3.0 * TOfBSquared       ) * maxLum;         \
    };
    _AUTO_FUNC(_BT2408_P, float, float);

    #define _BT2408_EETF(T1, T2)                                               \
    T1 EETF(T2 e1)                                                             \
    {                                                                          \
        /* Bunch of simplification setup */                                    \
        float displayBlack = PQ::iEOTF(Display::blackLevel / PQ::peakWhite);   \
        float displayWhite = PQ::iEOTF(Display::peakWhite  / PQ::peakWhite);   \
        float contentBlack = PQ::iEOTF(Content::blackLevel / PQ::peakWhite);   \
        float contentWhite = PQ::iEOTF(Content::whiteLevel / PQ::peakWhite);   \
        float contentRange = contentWhite - contentBlack;                      \
                                                                               \
        /* Step 1: Normalize PQ values based on mastering display */           \
        e1 = (e1 - displayBlack) / contentRange;                               \
        /* Let's clamp the input to our configured input peak */               \
        e1 = min(1.0, e1);                                                     \
                                                                               \
        /* Step 1.5: Calculate mastering display black and white in [0:1] PQ */\
        float minLum = (displayBlack - contentBlack) / contentRange;           \
        float maxLum = (displayWhite - contentBlack) / contentRange;           \
                                                                               \
        /* Step 2: Calculate 1:1 mapping and knee (?) */                       \
        float KS = 1.5 * maxLum - 0.5;                                         \
                                                                               \
        /* Step 3: Solve for EETF (e3) with given end points */                \
        T2 e2 = e1 < KS ? e1 : P(e1, KS, maxLum);                              \
        T2 e3 = e2 + minLum * pow(1.0 - e2, 4.0);                              \
                                                                               \
        /* Step 4: Hermite spline equations (see functions P(...) and T(...) */\
                                                                               \
        /* Step 5: Invert normalization of PQ values */                        \
        return e3 * contentRange + contentBlack;                               \
    };
    _AUTO_FUNC(_BT2408_EETF, PQNonlinear, PQNonlinear);

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

    PQNonlinear3 inRGB(PQNonlinear3 colour)
    {
        return EETF(colour);
    };

} // namespace Tonemapping

namespace Content {
    #define _CONTENT_TO_LINEAR(T1, T2)                                         \
    T1 toLinear(T2 colour) {                                                   \
        /* TODO: Account for pre-existing EOTF */                              \
        switch (overrideEOTF) {                                                \
        case EOTF_SRGB:                                                        \
            colour = sRGB::EOTF(colour);                                       \
            break;                                                             \
        case EOTF_G22:                                                         \
            colour = G22::EOTF(colour);                                        \
            break;                                                             \
        case EOTF_BT1886:                                                      \
            colour = BT1886::EOTF(colour);                                     \
            break;                                                             \
        case EOTF_PQ:                                                          \
            colour = PQ::EOTF(colour);                                         \
            break;                                                             \
        case EOTF_HLG:                                                         \
            /* TODO */                                                         \
            /*colour = HLG::EOTF(colour); */                                   \
            /*break; */                                                        \
        case EOTF_NONE:                                                        \
        default:                                                               \
            break;                                                             \
        }                                                                      \
                                                                               \
        return colour;                                                         \
    };
    _AUTO_FUNC(_CONTENT_TO_LINEAR, Linear, Nonlinear);

    #define _CONTENT_TO_NONLINEAR(T1, T2)                                      \
    T1 toNonlinear(T2 colour) {                                                \
        /* TODO: Account for pre-existing EOTF */                              \
        switch (overrideEOTF) {                                                \
        case EOTF_SRGB:                                                        \
            colour = sRGB::iEOTF(colour);                                      \
            break;                                                             \
        case EOTF_G22:                                                         \
            colour = G22::iEOTF(colour);                                       \
            break;                                                             \
        case EOTF_BT1886:                                                      \
            colour = BT1886::iEOTF(colour);                                    \
            break;                                                             \
        case EOTF_PQ:                                                          \
            colour = PQ::iEOTF(colour);                                        \
            break;                                                             \
        case EOTF_HLG:                                                         \
            /* TODO */                                                         \
            /*colour = HLG::iEOTF(colour); */                                  \
            /*break; */                                                        \
        case EOTF_NONE:                                                        \
        default:                                                               \
            break;                                                             \
        }                                                                      \
                                                                               \
        return colour;                                                         \
    };
    _AUTO_FUNC(_CONTENT_TO_NONLINEAR, Nonlinear, Linear);
} // namespace Content

// vim: filetype=shaderslang ts=4 sts=4 sw=4
