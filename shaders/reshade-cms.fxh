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
#define  Linear      float
#define  Linear2     float2
#define  Linear3     float3
#define  Nonlinear   float
#define  Nonlinear2  float2
#define  Nonlinear3  float3
#define  Nits        float
#define  Nits2       float2
#define  Nits3       float3

#define _COLOUR_POW(T1, T2)                                                     \
T1 cpow(T2 value, float power)                                                 \
{                                                                              \
    return sign(value) * pow(abs(value), power);                               \
};
_AUTO_FUNC(_COLOUR_POW, float, float);

namespace Output {
#define  OUTPUT_EOTF_SRGB     0
#define  OUTPUT_EOTF_GAMMA22  1
#define  OUTPUT_EOTF_BT1886   2
#define  OUTPUT_EOTF_LINEAR   3
#define  OUTPUT_EOTF_PQ       4
#define  OUTPUT_EOTF_HLG      5

uniform uint EOTF <
    ui_type = "combo";
    ui_items = 
        "sRGB\0"
        "Gamma 2.2\0"
        "BT.1886\0"
        "Linear\0"
        "PQ\0"
        "HLG\0";
    ui_label = "EOTF";
    ui_category = "Output Settings";
> = OUTPUT_EOTF_SRGB;

uniform Nits peak <
    ui_type = "slider";
    ui_min = 80.0;
    ui_step = 1.0;
    ui_max = 10000.0;
    ui_label = "Peak White";
    ui_category = "Output Settings";
    ui_category_closed = true;
    ui_units = " nits";
> = 1000.0;

uniform Nits diffuse <
    ui_type = "slider";
    ui_min = 1.0;
    ui_step = 1.0;
    ui_max = 405.0;
    ui_label = "Diffuse White";
    ui_category = "Output Settings";
    ui_category_closed = true;
    ui_units = " nits";
> = 203.0;

uniform Nits black <
    ui_type = "slider";
    ui_min = 0.0;
    ui_step = 0.0001;
    ui_max = 1.0;
    ui_label = "Black Level";
    ui_category = "Output Settings";
    ui_category_closed = true;
    ui_units = " nits";
> = 0.0;
}

namespace Input {
#define  CONTENT_OETF_BT709   0
#define  CONTENT_OETF_LINEAR  1
#define  CONTENT_OETF_PQ      2
#define  CONTENT_OETF_HLG     3

uniform uint OETF <
    ui_type = "combo";
    ui_items = 
        "BT.709\0"
        "Linear\0"
        "PQ\0"
        "HLG\0";
    ui_label = "OETF";
    ui_category = "Input Settings";
    ui_text = "Buffer Colour Space = " BUFFER_COLOR_SPACE_STRING;
> = CONTENT_OETF_BT709;

uniform Nits peak <
    ui_type = "slider";
    ui_min = 80.0;
    ui_step = 1.0;
    ui_max = 10000.0;
    ui_label = "Peak White";
    ui_category = "Input Settings";
    ui_units = " nits";
> = 1000.0;

uniform Nits black <
    ui_type = "slider";
    ui_min = 0.0;
    ui_step = 0.0001;
    ui_max = 1.0;
    ui_label = "Black Level";
    ui_category = "Input Settings";
    ui_units = " nits";
> = 0.0000;
} // namespace Input


namespace Illuminant {
    static const float2 D65 = float2(
        0.3127, 0.3290
    );
}; // namespace Illuminant

namespace BT601 {
    static const float2 whitePoint = Illuminant::D65;

    namespace NTSC {
        // 525-line
        static const float3x2 primaries = float3x2(
            0.630, 0.340,
            0.310, 0.595,
            0.155, 0.070
        );
    } // namespace NTSC

    namespace PAL {
        // 625-line
        static const float3x2 primaries = float3x2(
            0.640, 0.330,
            0.290, 0.600,
            0.150, 0.060
        );
    } // namespace PAL

    // NOTE / TODO: Seems to be the same OETF as BT.709? Double-check this,
    // maybe the only difference is colour primaries
    // Low Priority as BT601 game content will probably be very rare
} // namespace BT601

namespace BT709 {
    static const float2 whitePoint = Illuminant::D65;
    static const float3x2 primaries = float3x2(
        0.640, 0.330,
        0.300, 0.600,
        0.150, 0.060
    );

    // BT.709 did not define an EOTF, as all CRTs behaved pretty much the same.
    // See BT.1886 for an EOTF that can be used on modern displays for BT.709
    // content.

    #define _BT709_OETF(T1, T2)                                                \
    T1 OETF(T2 L)                                                              \
    {                                                                          \
        static const float breakPoint = 0.018;                                 \
        const T2 LSign = sign(L);                                              \
        L = abs(L);                                                            \
                                                                               \
        return LSign * (L < breakPoint                                         \
            ? 4.500 * L                                                        \
            : 1.099 * pow(L, 0.45) - 0.099);                                   \
    };
    _AUTO_FUNC(_BT709_OETF, Nonlinear, Linear);

    #define _BT709_INVERSE_OETF(T1, T2)                                        \
    T1 inverseOETF(T2 V)                                                       \
    {                                                                          \
        static const float breakPoint = 0.081;                                 \
        const T2 VSign = sign(V);                                              \
        V = abs(V);                                                            \
                                                                               \
        return VSign * (V < breakPoint                                         \
            ? V / 4.5                                                          \
            : pow((V + 0.099) / 1.099, rcp(0.45)));                           \
    };
    _AUTO_FUNC(_BT709_INVERSE_OETF, Linear, Nonlinear);

    // Display-referred: input after BT1886 EOTF, then invert it after the
    // conversion.
    // Scene-referred: input after BT709 inverse OETF, then inver that (as in,
    // apply the normal OETF) after the conversion.
    float3 toBT2020(Nonlinear3 value) {
        static const float3x3 coefficients = mul(
            float3x3(
                rcp(0.6370), rcp(0.1446), rcp(0.1689),
                rcp(0.2627), rcp(0.6780), rcp(0.0593),
                rcp(0.0000), rcp(0.0281), rcp(1.0610)
            ),
            float3x3(
                0.4124, 0.3576, 0.1805,
                0.2126, 0.7152, 0.0722,
                0.0193, 0.1192, 0.9505
            ));

        // Explicitly using mul() here to ensure it's a matrix * column-vector
        // matrix multiply and not anything else
        return mul(coefficients, value);
    }
} // namespace BT709

namespace sRGB {
    static const float2 whitePoint = BT709::whitePoint;
    static const float3x2 primaries = BT709::primaries;
    static const Nits peak = 80.0;

    #define _SRGB_EOTF(T1, T2)                                                 \
    T1 EOTF(T2 E)                                                              \
    {                                                                          \
        static const float breakPoint = 0.04045;                               \
        const T2 ESign = sign(E);                                              \
        E = abs(E);                                                            \
                                                                               \
        return ESign * (E > breakPoint                                         \
            ? pow((E + 0.055) / 1.055, 2.4)                                    \
            : E / 12.92);                                                      \
    };
    _AUTO_FUNC(_SRGB_EOTF, Linear, Nonlinear);

    // sRGB standard specifically uses an imprecise inverse EOTF breakPoint.
    // It's not exactly the true inverse of the EOTF.
    // NOTE: Not sure if the same negative reflection is to be used on inverses
    #define _SRGB_INVERSE_EOTF(T1, T2)                                         \
    T1 inverseEOTF(T2 E)                                                       \
    {                                                                          \
        static const float breakPoint = 0.0031308;                             \
        const T2 ESign = sign(E);                                              \
        E = abs(E);                                                            \
                                                                               \
        return ESign * (E > breakPoint                                         \
            ? 1.055 * pow(E, rcp(2.4)) - 0.055                                \
            : 12.92 * E);                                                      \
    };
    _AUTO_FUNC(_SRGB_INVERSE_EOTF, Nonlinear, Linear);

    // sRGB is just an EOTF for BT.709, so the OETF would be BT.709's

} // namespace sRGB

namespace scRGB {
    static const float2 whitePoint = BT709::whitePoint;
    static const float3x2 primaries = BT709::primaries;
    static const Nits peak = 10000.0;
    static const Nits diffuse = 80.0;
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
    return pow(value, rcp(power));                                            \
};
_AUTO_FUNC(_INVERSE_POWER_LAW_GAMMA, Nonlinear, Linear);

namespace Gamma22 {
    static const float2 whitePoint = BT709::whitePoint;
    static const float3x2 primaries = BT709::primaries;
    static const Nits peak = 100.0;

    #define _GAMMA22_EOTF(T1, T2)                                              \
    T1 EOTF(T2 value)                                                          \
    {                                                                          \
        return sign(value) * powerLawGamma(abs(value), 2.2);                   \
    };
    _AUTO_FUNC(_GAMMA22_EOTF, Linear, Nonlinear);

    #define _GAMMA22_INVERSE_EOTF(T1, T2)                                      \
    T1 inverseEOTF(T2 value)                                                   \
    {                                                                          \
        return sign(value) * inversePowerLawGamma(abs(value), 2.2);            \
    };
    _AUTO_FUNC(_GAMMA22_INVERSE_EOTF, Nonlinear, Linear);

    // Gamma22's OETF is just BT.709's
} // namespace Gamma22

namespace BT1886 {
    // TODO: Consider configurable display peak and display black levels for
    // BT1886's scaling properties.
    //
    // NOTE: For now, assumes peak = 100.0 and black = 0.0, making it
    // effectively power law gamma 2.4.
    static const float2 whitePoint = BT709::whitePoint;
    static const float3x2 primaries = BT709::primaries;
    static const Nits peak = 100.0;
    static const Nits black =  0.0;

    #define _BT1886_EOTF(T1, T2)                                               \
    T1 EOTF(T2 value)                                                          \
    {                                                                          \
        return sign(value) * powerLawGamma(abs(value), 2.4);                   \
    };
    _AUTO_FUNC(_BT1886_EOTF, Linear, Nonlinear);

    #define _BT1886_INVERSE_EOTF(T1, T2)                                       \
    T1 inverseEOTF(T2 value)                                                   \
    {                                                                          \
        return sign(value) * inversePowerLawGamma(abs(value), 2.4);            \
    };
    _AUTO_FUNC(_BT1886_INVERSE_EOTF, Nonlinear, Linear);

    // BT.1886's OETF is just BT.709's

} // namespace BT1886

namespace BT2020 {
    static const float2 whitePoint = Illuminant::D65;
    static const float3x2 primaries = float3x2(
        0.708, 0.292,
        0.170, 0.797,
        0.131, 0.046
    );
    // Let's assume 12 bits, as 10 bits is the same as on BT.709; can just use
    // that.
    static const float a = 1.0993;

    #define _BT2020_OETF(T1, T2)                                               \
    T1 OETF(T2 E)                                                              \
    {                                                                          \
        static const float breakPoint = 0.0181;                                \
                                                                               \
        return E < breakPoint                                                  \
            ? 4.5 * E                                                          \
            : a * pow(E, 0.45) - (a - 1.0);                                    \
    };
    _AUTO_FUNC(_BT2020_OETF, Nonlinear, Linear);

    #define _BT2020_INVERSE_OETF(T1, T2)                                       \
    T1 inverseOETF(T2 E)                                                       \
    {                                                                          \
        static const float breakPoint = 0.08145;                               \
                                                                               \
        return E < breakPoint                                                  \
            ? E / 4.5                                                          \
            : pow((E + (a - 1)) / a, rcp(0.45));                              \
    };
    _AUTO_FUNC(_BT2020_INVERSE_OETF, Linear, Nonlinear);

    // EOTF would just be either PQ/HLG for HDR or BT.1886 for SDR

} // namespace BT2020

namespace PQ {
    static const float2 whitePoint = BT2020::whitePoint;
    static const float3x2 primaries = BT2020::primaries;

    static const Nits peak =  10000.0;
    static const Nits diffuse = 203.0;

    static const float m1 = 2610.0 / 16384.0;
    static const float m2 = 2523.0 / 4096.0 * 128.0;
    static const float c1 = 3424.0 / 4096.0;
    static const float c2 = 2413.0 / 4096.0 * 32.0;
    static const float c3 = 2392.0 / 4096.0 * 32.0;

    // Input: Non-linear PQ encoded value
    // The EOTF maps the non-linear PQ signal into display light.
    #define _PQ_EOTF(T1, T2)                                                   \
    T1 EOTF(T2 E)                                                              \
    {                                                                          \
        return pow( max(pow(E, rcp(m2)) - c1, 0.0)                            \
                    / (c2 - c3 * pow(E, rcp(m2))), rcp(m1));                 \
    };
    _AUTO_FUNC(_PQ_EOTF, Linear, Nonlinear);

    // Input: Scene linear light
    // The OETF maps relative scene linear light into the non-linear PQ signal
    // value
    #define _PQ_OETF(T1, T2)                                                   \
    T1 OETF(T2 Y)                                                              \
    {                                                                          \
        return pow((c1 + c2 * pow(Y, m1))                                      \
                / (1.0 + c3 * pow(Y, m1)), m2);                                \
    };
    _AUTO_FUNC(_PQ_OETF, Nonlinear, Linear);

    #define _PQ_INVERSE_EOTF(T1, T2)                                           \
    T1 inverseEOTF(T2 value)                                                   \
    {                                                                          \
        return OETF(value);                                                    \
    };
    _AUTO_FUNC(_PQ_INVERSE_EOTF, Nonlinear, Linear);

    #define _PQ_INVERSE_OETF(T1, T2)                                           \
    T1 inverseOETF(T2 value)                                                   \
    {                                                                          \
        return EOTF(value);                                                    \
    };
    _AUTO_FUNC(_PQ_INVERSE_OETF, Linear, Nonlinear);

    // Input: Scene linear light
    // The OOTF maps relative scene linear light to display linear light
    // TODO: Change to the HDR-scaled versions of these functions
    #define _PQ_OOTF(T1, T2)                                                   \
    T1 OOTF(T2 value)                                                          \
    {                                                                          \
        return BT1886::EOTF(BT709::OETF(value));                               \
    };
    _AUTO_FUNC(_PQ_OOTF, Linear, Linear);

    // TODO: Change to the HDR-scaled versions of these functions
    #define _PQ_INVERSE_OOTF(T1, T2)                                           \
    T1 inverseOOTF(T2 value)                                                   \
    {                                                                          \
        return BT709::inverseOETF(BT1886::inverseEOTF(value));                 \
    };
    _AUTO_FUNC(_PQ_INVERSE_OOTF, Linear, Linear);

} // namespace PQ

namespace HLG {
    static const float2 whitePoint = BT2020::whitePoint;
    static const float3x2 primaries = BT2020::primaries;

    static const Nits peak = 1000.0;
    static const Nits diffuse = 203.0;

    static const float a = 0.17883277;
    static const float b = 1.0 - 4.0 * a;
    // Can't use functions outside of functions, so pre-computed log(4.0 * a)
    static const float c = 0.5 - a * -0.3350097945111627;
    static const float gamma = 1.2;

    // Input: Scene linear light
    // The OETF maps relative scene linear light into the non-linear signal
    // value.
    #define _HLG_OETF(T1, T2)                                                  \
    T1 OETF(T2 value)                                                          \
    {                                                                          \
        static const float breakPoint = rcp(12.0);                            \
        return value > breakPoint ?                                            \
            a * log(12.0 * value - b) + c :                                    \
            sqrt(3.0 * value);                                                 \
    };
    _AUTO_FUNC(_HLG_OETF, Nonlinear, Linear);

    #define _HLG_INVERSE_OETF(T1, T2)                                          \
    T1 inverseOETF(T2 value)                                                   \
    {                                                                          \
        static const float breakPoint = rcp(2.0);                             \
        return value > breakPoint ?                                            \
            (exp((value - c) / a) + b) / 12.0 :                                \
            exp2(value) / 3.0;                                                 \
    };
    _AUTO_FUNC(_HLG_INVERSE_OETF, Linear, Nonlinear);

    /* TODO: Finish this
    // Input: Scene linear light
    // The OOTF maps relative scene linear light to display linear light.
    #define _HLG_OOTF(T1, T2)                                                  \
    T1 OOTF(T2 value)                                                          \
        return pow(?Ys?, gamma - 1) * value;                                   \
    {                                                                          \
    };
    _AUTO_FUNC(_HLG_OOTF, Linear, Linear);

    // Input: Non-linear HLG encoded value.
    // The EOTF maps the non-linear HLG signal into display light.
    // NOTE: Assuming black level of 0 and peak of 1000, so no black level lift
    // TODO: Consider parameterizing it
    #define _HLG_EOTF(T1, T2)                                                  \
    T1 EOTF(T2 value)                                                          \
    {                                                                          \
        // This max() would be where the black level lift comes in             \
        value = max(0.0, value);                                               \
        return OOTF(inverseOETF(value));                                       \
    };
    _AUTO_FUNC(_HLG_EOTF, Linear, Nonlinear);

    #define _HLG_INVERSE_EOTF(T1, T2)                                          \
    T1 inverseEOTF(T2 value)                                                   \
    {                                                                          \
        // max() and min() are uninvertible, so we won't                       \
        // TODO: Check if black level ift should factor in here                \
        return OETF(inverseOOTF(value));                                       \
    };
    _AUTO_FUNC(_HLG_INVERSE_EOTF, Nonlinear, Linear);
    */

} // namespace HLG

namespace ICtCp {
    static const float3x3 LMSCoefficients = float3x3(
        1688.0, 2146.0, 262.0,
        683.0, 2951.0, 462.0,
        99.0, 309.0, 3688.0
    );

    float deriveI(float2 LM)
    {
        return dot(float2(0.5, 0.5), LM);
    };

    namespace PQ {
        static const float2x3 CtCpCoefficients = float2x3(
            6610.0, -13613.0, 7003.0,
            17933.0, -17390.0, -543.0
        );

        float3 derive(Nits3 colour)
        {
            float3 LMSColour = PQ::inverseEOTF(float3(
                dot(LMSCoefficients[0], colour),
                dot(LMSCoefficients[1], colour),
                dot(LMSCoefficients[2], colour)
            ) / 4096.0) / PQ::peak;

            return float3(deriveI(LMSColour.xy), float2(
                dot(CtCpCoefficients[0], LMSColour),
                dot(CtCpCoefficients[1], LMSColour)) / 4096.0);
        };
    } // namespace ICtCp::PQ

    namespace HLG {
        static const float2x3 CtCpCoefficients = float2x3(
            3625.0, -7465.0, 3840.0,
            9500.0, -9212.0, -288.0
        );

        float3 derive(Nits3 colour)
        {
            float3 LMSColour = HLG::OETF(float3(
                dot(LMSCoefficients[0], colour),
                dot(LMSCoefficients[1], colour),
                dot(LMSCoefficients[2], colour)
            ) / 4096.0) / HLG::peak;

            return float3(deriveI(LMSColour.xy), float2(
                dot(CtCpCoefficients[0], LMSColour),
                dot(CtCpCoefficients[1], LMSColour)) / 4096.0);
        };
    } // namespace ICtCp::HLG
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
        /* Skip if we don't need to tonemap. Why did you turn this on? */      \
        if (Output::black <= Input::black && Output::peak >= Input::peak)      \
        {                                                                      \
            return e1;                                                         \
        };                                                                     \
                                                                               \
        /* Bunch of simplification setup */                                    \
        float outputBlack     = min(Output::black, Output::diffuse);           \
        float outputPeak      = max(Output::peak, Output::diffuse);            \
        float outputBlackNorm = PQ::inverseEOTF(outputBlack  / PQ::peak);      \
        float outputPeakNorm  = PQ::inverseEOTF(outputPeak   / PQ::peak);      \
        float inputBlackNorm  = PQ::inverseEOTF(Input::black / PQ::peak);      \
        float inputPeakNorm   = PQ::inverseEOTF(Input::peak  / PQ::peak);      \
        float inputRangeNorm  = inputPeakNorm - inputBlackNorm;                \
                                                                               \
        /* Step 1: Normalize PQ values based on mastering display */           \
        e1 = (e1 - inputBlackNorm) / (inputPeakNorm - inputBlackNorm);         \
        /* Let's clamp the input to our configured input peak */               \
        e1 = saturate(e1);                                                     \
                                                                               \
        /* Step 1.5: Calculate mastering display black and white in [0:1] PQ */\
        float minLum = (outputBlackNorm - inputBlackNorm) / inputRangeNorm;    \
        float maxLum = (outputPeakNorm - inputBlackNorm)  / inputRangeNorm;    \
                                                                               \
        /* Step 2: Calculate 1:1 mapping and knee (?) */                       \
        float KS = 1.5 * maxLum - 0.5;                                         \
                                                                               \
        /* Step 3: Saolve for EETF (e3) with given end points */               \
        T2 e2 = e1 < KS ? e1 : P(e1, KS, maxLum);                              \
        T2 e3 = e2 + minLum * pow(1.0 - e2, 4.0);                              \
                                                                               \
        /* Step 4: Hermite spline equations (see functions P(...) and T(...) */\
                                                                               \
        /* Step 5: Invert normalization of PQ values */                        \
        return e3 * inputRangeNorm + inputBlackNorm;                           \
    };
    _AUTO_FUNC(_BT2408_EETF, Nonlinear, Nonlinear);

    float3 ICtCp(float3 ICtCp)
    {
        const float I2 = EETF(ICtCp.x);

        return float3(I2, min(ICtCp.x / I2, I2 / ICtCp.x) * ICtCp.yz);
    };

    float3 YCbCr(float3 YCbCr)
    {
        const float Y2 = EETF(YCbCr.x);

        return float3(Y2, min(YCbCr.x / Y2, Y2 / YCbCr.x) * YCbCr.yz);
    };

    float3 RGB(float3 colour)
    {
        return EETF(colour);
    };

} // namespace Tonemapping

namespace BT2020 {
} // namespace BT2020

// vim: filetype=shaderslang ts=4 sts=4 sw=4
