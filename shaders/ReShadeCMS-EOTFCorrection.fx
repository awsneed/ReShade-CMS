#include "ReShadeCMS.fxh"

namespace ReShadeCMS
{
namespace EOTFCorrection
{

#if defined(BUFFER_IS_HDR)
uniform Nits SDRWhite <
    ui_type = "slider";
    ui_min = 1.0;
    ui_step = 1.0;
    ui_max = 405.0;
    ui_label = "SDR White";
    ui_units = " nits";
    ui_tooltip = "White level for SDR EOTFs.";
> = 203.0;
#else
static const Nits diffuseWhite = 100.0;
#endif

uniform uint oldEOTF <
    ui_type = "combo";
    ui_items = 
        "None \0"
        "sRGB \0"
        "Gamma 2.2 \0"
        "BT.1886 \0"
        #if defined(BUFFER_IS_HDR)
        "PQ \0"
        "HLG \0"
        #endif
        ;
    ui_label = "Original EOTF";
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
        #if defined(BUFFER_IS_HDR)
        "PQ \0"
        "HLG \0"
        #endif
        ;
    ui_label = "Override EOTF";
#if BUFFER_COLOR_SPACE == COLOUR_SPACE_PQ
> = EOTF_PQ;
#elif BUFFER_COLOR_SPACE == COLOUR_SPACE_HLG
> = EOTF_HLG;
#else
> = EOTF_SRGB;
#endif

float3 correctEOTFPS(
    float4 pos : SV_POSITION,
    float2 texcoord : TexCoord) : SV_Target
{
    LinearColour3 colour = tex2Dfetch(ReShade::BackBuffer, pos.xy).rgb;
    
    /* Old EOTF Scenarios:
     * In scRGB, old EOTF is SDR: Scale    80 /   1.0 to diffuseWhite / 1.0
     * In scRGB, old EOTF is PQ:  Scale 10000 / 125.0 to        10000 / 1.0
     * In scRGB, old EOTF is HLG: Scale 10000 / 125.0 to         1000 / 1.0

     * In PQ,    old EOTF is SDR: Scale 10000 /   1.0 to diffuseWhite / 1.0
     * In PQ,    old EOTF is HLG: Scale 10000 /   1.0 to         1000 / 1.0

     * In HLG,   old EOTF is SDR: Scale 1000 /    1.0 to diffuseWhite / 1.0
     * In HLG,   old EOTF is PQ:  Scale 1000 /    1.0 to        10000 / 1.0

     * In SDR,   old EOTF is SDR: Nothing (This is always the case for SDR)
     * In PQ,    old EOTF is PQ:  Nothing
     * In HLG,   old EOTF is HLG: Nothing
     */

    // Scale normalized values to what the old EOTF is expecting
    #if defined(BUFFER_IS_HDR)
    switch (oldEOTF)
    {
        case EOTF_SRGB:
        case EOTF_G22:
        case EOTF_BT1886:
            #if   BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
            colour *= sRGB::whiteLevel / SDRWhite;
            #elif BUFFER_COLOR_SPACE == COLOUR_SPACE_PQ
            colour *= BT2100::PQ::peakWhite / SDRWhite;
            #elif BUFFER_COLOR_SPACE == COLOUR_SPACE_HLG
            colour *= BT2100::HLG::peakWhite / SDRWhite;
            #endif
            break;
        case EOTF_PQ:
            #if   BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
            colour *= BT2100::PQ::scaleToSRGB;
            #elif BUFFER_COLOR_SPACE == COLOUR_SPACE_HLG
            colour *= BT2100::PQ::scaleToHLG;
            #endif
            break;
        case EOTF_HLG:
            #if   BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
            colour *= BT2100::HLG::scaleToSRGB;
            #elif BUFFER_COLOR_SPACE == COLOUR_SPACE_PQ
            colour *= BT2100::HLG::scaleToPQ;
            #endif
            break;
        case EOTF_NONE:
            // Might need to add something here in the future?
        default:
            break;
    }
    #endif

    colour = useIEOTF(colour, oldEOTF);
    colour = useEOTF(colour, newEOTF);

    // TODO: Double-check that this reverse scaling is right
    #if defined(BUFFER_IS_HDR)
    switch (newEOTF)
    {
        case EOTF_SRGB:
        case EOTF_G22:
        case EOTF_BT1886:
            #if   BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
            colour /= sRGB::whiteLevel / SDRWhite;
            #elif BUFFER_COLOR_SPACE == COLOUR_SPACE_PQ
            colour /= BT2100::PQ::peakWhite / SDRWhite;
            #elif BUFFER_COLOR_SPACE == COLOUR_SPACE_HLG
            colour /= BT2100::HLG::peakWhite / SDRWhite;
            #endif
            break;
        case EOTF_PQ:
            #if   BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
            colour /= BT2100::PQ::scaleToSRGB;
            #elif BUFFER_COLOR_SPACE == COLOUR_SPACE_HLG
            colour /= BT2100::PQ::scaleToHLG;
            #endif
            break;
        case EOTF_HLG:
            #if   BUFFER_COLOR_SPACE == COLOUR_SPACE_SCRGB
            colour /= BT2100::HLG::scaleToSRGB;
            #elif BUFFER_COLOR_SPACE == COLOUR_SPACE_PQ
            colour /= BT2100::HLG::scaleToPQ;
            #endif
            break;
        case EOTF_NONE:
        default:
            break;
    }
    #endif
    
    #if   BUFFER_COLOR_SPACE == COLOUR_SPACE_SRGB
    colour = sRGB::iEOTF(colour);
    #elif BUFFER_COLOR_SPACE == COLOUR_SPACE_PQ
    colour = BT2100::PQ::iEOTF(colour);
    #elif BUFFER_COLOR_SPACE == COLOUR_SPACE_HLG
    colour = BT2100::HLG::iEOTF(colour);
    #endif

    return colour;
}

technique correctEOTF <
    ui_label = "EOTF Correction";
>
{
    pass p0
    {
        VertexShader = PostProcessVS;
        PixelShader = correctEOTFPS;
    }
}

} // namespace EOTFCorrection
} // namespace ReShadeCMS
// vim: filetype=shaderslang ts=4 sts=4 sw=4
