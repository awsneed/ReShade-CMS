# ReShade CMS

Here be dragons

The shaders in this repo will be geared towards correcting the images from video
games, such as by converting between encodings such as sRGB and BT1886 or
tonemapping HDR content. I aim to follow standards where possible and by
default, such as those in ITU BT.2408.

Mostly I'm creating this for fun and for myself, and this is the first time I've
worked with shaders or HLSL, so once again: Here be dragons.

## To-do List

- [ ] BT.2408-based tonemapping from higher range to lower range
- [ ] SDR correction tools (sRGB <-> BT.1886 / Gamma 2.2)
- [ ] Take another look or two at my initial macro-based typedef shenanigans
- [ ] Try out some HLG stuff on the SDR -> HDR mapping. Might be a good fit for
  overbright bits on HDR-forced SDR games.
- [ ] Far in the future: Calibrating SDR output in HDR color spaces?
