# ReShade CMS

Here be dragons

The shaders in this repo will be geared towards correcting the images from video
games, such as by converting between encodings such as sRGB and BT1886 or
tonemapping HDR content. I aim to follow standards where possible and by
default, such as those in ITU BT.2408.

Mostly I'm creating this for fun and for myself, and this is the first time I've
worked with shaders or HLSL, so once again: Here be dragons.

## To-do List

- [ ] Fix tonemapping (not sure what I did wrong)
- [ ] Add proper ICtCp color conversion in tonemapping (it will be the default)
- [ ] SDR correction tools (sRGB <-> BT.1886 / Gamma 2.2)
- [ ] Technique for applying the same gamma adjustment that would've applied to
  a SDR -> HDR image, but on already-native HDR images. Should be pretty simple
  I think.
- [ ] Take another look or two at my initial macro-based typedef shenanigans
