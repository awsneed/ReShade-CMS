# ReShade CMS

Here be dragons

The shaders in this repo will be geared towards correcting the images from video
games, such as by converting between encodings such as sRGB and BT1886 or
tonemapping HDR content. I aim to follow standards where possible and by
default, such as those in ITU BT.2408.

Mostly I'm creating this for fun and for myself, and this is the first time I've
worked with shaders or HLSL, so once again: Here be dragons.

## To-do List

- [x] ~~Fix tonemapping (not sure what I did wrong)~~
- [x] ~~Add proper ICtCp color conversion in tonemapping (it will be the
  default)~~
- [ ] Technique for applying the same gamma adjustment that would've applied to
  a SDR -> HDR image, but on already-native HDR images. Should be pretty simple
  I think.
- [ ] SDR correction tools (sRGB <-> BT.1886 / Gamma 2.2)
- [ ] Add more tonemapping methods and a selector for them
- [ ] Re-organize code / Take another look or two at my initial macro-based
  typedef shenanigans

## Special Thanks

[Lillium](https://github.com/EndlesslyFlowering) for their [ReShade HDR
Shaders](https://github.com/EndlesslyFlowering/ReShade_HDR_shaders) project,
which has been an inspiration for this project and a recurring source of insight
on my never-ending journey of learning about HDR and all things video / colour
science. I have made heavy use of the analysis overlay shader in particular
during the testing of this project. Go check it out!
