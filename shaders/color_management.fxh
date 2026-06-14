#pragma once

// ReShade preprocessor translations
#define COLOR_SPACE_UNKNOWN        -1
#define COLOR_SPACE_SRGB_NONLINEAR  0
#define COLOR_SPACE_SRGB_LINEAR     1
#define COLOR_SPACE_PQ              2
#define COLOR_SPACE_HLG             3

#if   BUFFER_COLOR_SPACE == COLOR_SPACE_UNKNOWN
    #define BUFFER_COLOR_SPACE_STRING "Unknown"

#elif BUFFER_COLOR_SPACE == COLOR_SPACE_SRGB_NONLINEAR
    #define BUFFER_COLOR_SPACE_STRING "sRGB Nonlinear"

#elif BUFFER_COLOR_SPACE == COLOR_SPACE_SRGB_LINEAR
    #define BUFFER_COLOR_SPACE_STRING "Extended sRGB Linear"

#elif BUFFER_COLOR_SPACE == COLOR_SPACE_PQ
    #define BUFFER_COLOR_SPACE_STRING "HDR10 ST2084"

#elif BUFFER_COLOR_SPACE == COLOR_SPACE_HLG
    #define BUFFER_COLOR_SPACE_STRING "HDR10 HLG"

#endif

// Autocreate function macro statements for 1 and 3 component versions. Commonly
// needed with transfer functions.
#define TRI_FUNCTION(functionMacro, T1, T2) \
functionMacro(T1,    T2); \
functionMacro(T1##3, T2##3);

// Macro types to help understand what is what at what time. Might redo this or
// get rid of it, but I was hoping it would help understanding and organization.
//
// Generally normalized to [0.0, 1.0] but sRGB / scRGB can go beyond. In that
// case, 0.0 = 0.0 black, and 1.0 = 80 nits, with 2.0 = 160 nits and so on. The
// negatives are for expanded gamut colors.
#define SceneLinear    float
#define SceneLinear2   float2
#define SceneLinear3   float3
#define DisplayLinear  float
#define DisplayLinear2 float2
#define DisplayLinear3 float3
#define Nonlinear      float
#define Nonlinear2     float2
#define Nonlinear3     float3
#define Nits           float

namespace Output {
uniform Nits white <
    ui_type = "slider";
    ui_min = 80.0;
    ui_step = 1.0;
    ui_max = 10000.0;
    ui_label = "Peak White";
    ui_category = "Output Settings";
    ui_category_closed = true;
    ui_units = " nits";
> = 1000.0;

uniform Nits diffuseWhite <
    ui_type = "slider";
    ui_min = 1.0;
    ui_step = 1.0;
    ui_max = 406.0;
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
} // namespace Output

namespace Content {
#define CONTENT_ENCODING_SRGB    0
#define CONTENT_ENCODING_GAMMA22 1
#define CONTENT_ENCODING_BT1886  2
#define CONTENT_ENCODING_LINEAR  3
#define CONTENT_ENCODING_PQ      4
#define CONTENT_ENCODING_HLG     5

uniform uint encoding <
    ui_type = "combo";
    ui_items = 
        "sRGB\0"
        "Gamma 2.2\0"
        "BT.1886\0"
        "Linear\0"
        "PQ\0"
        "HLG\0";
    ui_label = "Encoding";
    ui_category = "Content Settings";
    ui_text = "Buffer Color Space = " BUFFER_COLOR_SPACE_STRING;
> = CONTENT_ENCODING_SRGB;

uniform Nits white <
    ui_type = "slider";
    ui_min = 80.0;
    ui_step = 1.0;
    ui_max = 10000.0;
    ui_label = "Peak White";
    ui_category = "Content Settings";
    ui_units = " nits";
> = 1000.0;

uniform Nits black <
    ui_type = "slider";
    ui_min = 0.0;
    ui_step = 0.0001;
    ui_max = 1.0;
    ui_label = "Black Level";
    ui_category = "Content Settings";
    ui_units = " nits";
> = 0.0000;
} // namespace Content

namespace Rec601 {
    // NOTE / TODO: Seems to be the same OETF as Rec.709? Double-check this,
    // maybe the only difference is color primaries
} // namespace Rec601

namespace Rec709 {
    // Rec.709 did not define an EOTF, as all CRTs behaved pretty much the same
    // See BT.1886 for an EOTF that can be used on modern displays for Rec.709
    // content.

    #define REC709_OETF(T1, T2) \
    T1 OETF(T2 value) \
    { \
        static const float breakpoint = 0.018; \
        return value >= breakpoint ? \
            1.099 * pow(value, 0.45) - 0.099 : \
            4.500 * value; \
    };
    TRI_FUNCTION(REC709_OETF, Nonlinear, SceneLinear);

    #define REC709_INVERSE_OETF(T1, T2) \
    T1 inverseOETF(T2 value) \
    { \
        static const float breakpoint = 0.081; \
        return value >= breakpoint ? \
            pow((value + 0.099) / 1.099, 1.0 / 0.45) : \
            value / 4.5; \
    };
    TRI_FUNCTION(REC709_INVERSE_OETF, SceneLinear, Nonlinear);

} // namespace Rec709

namespace sRGB {
    static const DisplayLinear white = 80.0;

    #define SRGB_EOTF(T1, T2) \
    T1 EOTF(T2 value) \
    { \
        static const float breakpoint = 0.04045; \
        value = value > breakpoint ? \
            pow((value + 0.055) / 1.055, 2.4) : \
            value / 12.92; \
        return value; \
    };
    TRI_FUNCTION(SRGB_EOTF, DisplayLinear, Nonlinear);

    // sRGB standard specifically uses an imprecise inverse EOTF breakpoint
    // It's not exactly the true inverse of the EOTF
    #define SRGB_INVERSE_EOTF(T1, T2) \
    T1 inverseEOTF(T2 value) \
    { \
        static const float breakpoint = 0.0031308; \
        return value > breakpoint ? \
            1.055 * pow(value, 1.0 / 2.4) - 0.055 : \
            12.92 * value; \
    };
    TRI_FUNCTION(SRGB_INVERSE_EOTF, Nonlinear, DisplayLinear);

    // sRGB's OETF is just Rec.709's

} // namespace sRGB

#define POWER_LAW_GAMMA(T1, T2) \
T1 powerLawGamma(T2 value, float power) \
{ \
    return pow(value, power); \
};
TRI_FUNCTION(POWER_LAW_GAMMA, DisplayLinear, Nonlinear);

#define INVERSE_POWER_LAW_GAMMA(T1, T2) \
T1 inversePowerLawGamma(T2 value, float power) \
{ \
    return pow(value, 1.0 / power); \
};
TRI_FUNCTION(INVERSE_POWER_LAW_GAMMA, Nonlinear, DisplayLinear);

namespace Gamma22 {
    static const DisplayLinear white = 100.0;

    #define Gamma22_EOTF(T1, T2) \
    T1 EOTF(T2 value) \
    { \
        return powerLawGamma(value, 2.2); \
    };
    TRI_FUNCTION(Gamma22_EOTF, DisplayLinear, Nonlinear);

    #define Gamma22_INVERSE_EOTF(T1, T2) \
    T1 inverseEOTF(T2 value) \
    { \
        return inversePowerLawGamma(value, 2.2); \
    };
    TRI_FUNCTION(Gamma22_INVERSE_EOTF, Nonlinear, DisplayLinear);

    // Gamma22's OETF is just Rec.709's

    #define Gamma22_OETF(T1, T2) \
    T1 OETF(T2 value) \
    { \
        return Rec709::OETF(value); \
    };
    TRI_FUNCTION(Gamma22_OETF, DisplayLinear, Nonlinear);

    #define Gamma22_INVERSE_OETF(T1, T2) \
    T1 inverseOETF(T2 value) \
    { \
        return Rec709::inverseOETF(value); \
    };
    TRI_FUNCTION(Gamma22_INVERSE_OETF, Nonlinear, DisplayLinear);
}

namespace BT1886 {
    // TODO: Consider configurable display white and display black levels for
    // BT1886's scaling properties.
    //
    // NOTE: For now, assumes white = 100.0 and black = 0.0, making it
    // effectively power law gamma 2.4.

    static const DisplayLinear white = 100.0;

    #define BT1886_EOTF(T1, T2) \
    T1 EOTF(T2 value) \
    { \
        return powerLawGamma(value, 2.4); \
    };
    TRI_FUNCTION(BT1886_EOTF, DisplayLinear, Nonlinear);

    #define BT1886_INVERSE_EOTF(T1, T2) \
    T1 inverseEOTF(T2 value) \
    { \
        return inversePowerLawGamma(value, 2.4); \
    };
    TRI_FUNCTION(BT1886_INVERSE_EOTF, Nonlinear, DisplayLinear);

    // BT.1886's OETF is just Rec.709's

    #define BT1886_OETF(T1, T2) \
    T1 OETF(T2 value) \
    { \
        return Rec709::OETF(value); \
    };
    TRI_FUNCTION(BT1886_OETF, DisplayLinear, Nonlinear);

    #define BT1886_INVERSE_OETF(T1, T2) \
    T1 inverseOETF(T2 value) \
    { \
        return Rec709::inverseOETF(value); \
    };
    TRI_FUNCTION(BT1886_INVERSE_OETF, Nonlinear, DisplayLinear);

} // namespace BT1886

namespace PQ {
    static const DisplayLinear white = 10000.0;
    static const DisplayLinear diffuseWhite = 203.0;

    static const float m1 = 2610.0 / 16384.0;
    static const float m2 = 2523.0 / 4096.0 * 128.0;
    static const float c1 = 3424.0 / 4096.0;
    static const float c2 = 2413.0 / 4096.0 * 32.0;
    static const float c3 = 2392.0 / 4096.0 * 32.0;

    // Input: Non-linear PQ encoded value
    // The EOTF maps the non-linear PQ signal into display light.
    #define PQ_EOTF(T1, T2) \
    T1 EOTF(T2 value) \
    { \
        return max(pow(value, 1 / m2) - c1, 0) / (c2 - c3 * pow(value, 1 / m2)); \
    };
    TRI_FUNCTION(PQ_EOTF, DisplayLinear, Nonlinear);

    // Input: Scene linear light
    // The OETF maps relative scene linear light into the non-linear PQ signal value
    #define PQ_OETF(T1, T2) \
    T1 OETF(T2 value) \
    { \
        return pow((c1 + c2 * pow(value, m1)) / (1.0 + c3 * pow(value, m1)), m2); \
    };
    TRI_FUNCTION(PQ_OETF, Nonlinear, SceneLinear);

    #define PQ_INVERSE_EOTF(T1, T2) \
    T1 inverseEOTF(T2 value) \
    { \
        return OETF(value); \
    };
    TRI_FUNCTION(PQ_INVERSE_EOTF, Nonlinear, DisplayLinear);

    #define PQ_INVERSE_OETF(T1, T2) \
    T1 inverseOETF(T2 value) \
    { \
        return EOTF(value); \
    };
    TRI_FUNCTION(PQ_INVERSE_OETF, SceneLinear, Nonlinear);

    // Input: Scene linear light
    // The OOTF maps relative scene linear light to display linear light
    #define PQ_OOTF(T1, T2) \
    T1 OOTF(T2 value) \
    { \
        return BT1886::EOTF(Rec709::OETF(value)); \
    };
    TRI_FUNCTION(PQ_OOTF, DisplayLinear, SceneLinear);

    #define PQ_INVERSE_OOTF(T1, T2) \
    T1 inverseOOTF(T2 value) \
    { \
        return Rec709::inverseOETF(BT1886::inverseEOTF(value)); \
    };
    TRI_FUNCTION(PQ_INVERSE_OOTF, SceneLinear, DisplayLinear);

} // namespace PQ

namespace HLG {
    static const DisplayLinear white = 1000.0;
    static const DisplayLinear diffuseWhite = 203.0;

    static const float a = 0.17883277;
    static const float b = 1.0 - 4.0 * a;
    // Can't use functions outside of functions, so pre-computer log(4.0 * a)
    static const float c = 0.5 - a * -0.3350097945111627;
    static const float systemGamma = 1.2;

    // Input: Scene linear light
    // The OETF maps relative scene linear light into the non-linear signal value.
    #define HLG_OETF(T1, T2) \
    T1 OETF(T2 value) \
    { \
        static const float breakpoint = 1.0 / 12.0; \
        return value > breakpoint ? \
            a * log(12.0 * value - b) + c : \
            sqrt(3.0 * value); \
    };
    TRI_FUNCTION(HLG_OETF, Nonlinear, SceneLinear);

    #define HLG_INVERSE_OETF(T1, T2) \
    T1 inverseOETF(T2 value) \
    { \
        static const float breakpoint = 1.0 / 2.0; \
        return value > breakpoint ? \
            (exp((value - c) / a) + b) / 12.0 : \
            exp2(value) / 3.0; \
    };
    TRI_FUNCTION(HLG_INVERSE_OETF, SceneLinear, Nonlinear);

    /* TODO: Finish this
    // Input: Scene linear light
    // The OOTF maps relative scene linear light to display linear light.
    #define HLG_OOTF(T1, T2) \
    T1 OOTF(T2 value) \
        return pow(?Ys?, systemGamma - 1) * value;
    { \

    };
    TRI_FUNCTION(HLG_OOTF, DisplayLinear, SceneLinear);

    // Input: Non-linear HLG encoded value.
    // The EOTF maps the non-linear HLG signal into display light.
    // NOTE: Assuming black level of 0 and peak of 1000, so no black level lift
    // TODO: Consider parameterizing it
    #define HLG_EOTF(T1, T2) \
    T1 EOTF(T2 value) \
    { \
        // This max() would be where the black level lift comes in \
        value = max(0.0, value); \
        return OOTF(inverseOETF(value));
    };
    TRI_FUNCTION(HLG_EOTF, DisplayLinear, Nonlinear);

    #define HLG_INVERSE_EOTF(T1, T2) \
    T1 inverseEOTF(T2 value) \
    { \
        // max() and min() are uninvertible, so we won't \
        // TODO: Check if black level ift should factor in here \
        return OETF(inverseOOTF(value)); \
    };
    TRI_FUNCTION(HLG_INVERSE_EOTF, Nonlinear, DisplayLinear);
    */

} // namespace HLG

namespace Tonemapping {
    DisplayLinear BT2408(DisplayLinear value)
    {
        static const Nonlinear minLum = 
            (PQ::inverseEOTF(Output::black) - PQ::inverseEOTF(Content::black)) /
            (PQ::inverseEOTF(Content::white) - PQ::inverseEOTF(Content::black));
        static const Nonlinear maxLum = 
            (PQ::inverseEOTF(Output::white) - PQ::inverseEOTF(Content::black)) /
            (PQ::inverseEOTF(Content::white) - PQ::inverseEOTF(Content::black));
        static const Nonlinear kneeStart = 1.5 * maxLum - 0.5;
    }
} // namespace Tonemapping

// vim: filetype=shaderslang ts=4 sts=4 sw=4
