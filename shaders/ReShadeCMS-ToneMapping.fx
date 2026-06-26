#include "ReShadeCMS.fxh"

namespace ReShadeCMS
{
namespace ToneMapping
{

uniform LinearColour displayWhite <
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

uniform LinearColour displayBlack <
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

uniform LinearColour contentWhite <
    ui_type = "slider";
    ui_min = 80.0;
    ui_step = 1.0;
    ui_max = 10000.0;
    ui_label = "Peak White";
    ui_category = "Content Settings";
    ui_units = " nits";
> = 4000.0;

uniform LinearColour contentBlack <
    ui_type = "slider";
    ui_min = 0.0;
    ui_step = 0.0001;
    ui_max = 1.0;
    ui_label = "Black Level";
    ui_category = "Content Settings";
    ui_units = " nits";
> = 0.0;

#define MAPPING_SPACE_ICTCP  0
#define MAPPING_SPACE_YCBCR  1
#define MAPPING_SPACE_YRGB   2
#define MAPPING_SPACE_RGB    3
#define MAPPING_SPACE_MAXRGB 4

uniform uint mappingSpace <
    ui_type = "combo";
    ui_items = 
        "ICtCp\0"
        "Y'Cb'Cr'\0"
        "YRGB\0"
        "R'G'B'\0"
        "maxRGB\0";
    ui_label = "Mapping Space";
> = MAPPING_SPACE_ICTCP;

float3 toneMappingPS(
    float4 pos : SV_POSITION,
    float2 texcoord : TexCoord
) : SV_Target
{
    float3 colour = tex2D(ReShade::BackBuffer, texcoord).rgb;

    #if BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
    colour = BT709::toBT2020(colour);
    colour /= BT2100::PQ::peakWhite / sRGB::whiteLevel;
    #endif

    switch (mappingSpace)
    {
        case MAPPING_SPACE_ICTCP:
            colour = RGB::toLMS(colour);

            #if BUFFER_COLOR_SPACE == COLOUR_SPACE_HLG
            colour = LMS::HLG::toICtCp(colour);
            #else
            colour = LMS::PQ::toICtCp(colour);
            #endif

            colour = inICtCp(colour,
                displayWhite, displayBlack, contentWhite, contentBlack);

            #if BUFFER_COLOR_SPACE == COLOUR_SPACE_HLG
            colour = ICtCp::HLG::toLMS(colour);
            #else
            colour = ICtCp::PQ::toLMS(colour);
            #endif

            colour = LMS::toRGB(colour);
            break;

        case MAPPING_SPACE_YCBCR:
            break;

        case MAPPING_SPACE_YRGB:
            break;

        case MAPPING_SPACE_RGB:
            colour = EETF(colour,
                displayWhite, displayBlack, contentWhite, contentBlack);
            break;

        case MAPPING_SPACE_MAXRGB:
            break;

        default:
            break;
    }

    #if BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
    colour = BT2020::toBT709(colour);
    colour *= BT2100::PQ::peakWhite / sRGB::whiteLevel;
    #endif

    return colour;
}

technique toneMap <
    ui_label = "Static Tone Mapping";
>
{
    pass p0
    {
        VertexShader = PostProcessVS;
        PixelShader = toneMappingPS;
    }
}

} // namespace ToneMapping
} // namespace ReShadeCMS

// vim: filetype=shaderslang ts=4 sts=4 sw=4
