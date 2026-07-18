# ReShade CMS

Here be dragons

The shaders in this repo will be geared towards correcting the images from video
games, such as by converting between encodings such as sRGB and BT1886 or
tonemapping HDR content. I aim to follow standards where possible and by
default, such as those in ITU BT.2408.

Mostly I'm creating this for fun and for myself, and this is the first time I've
worked with shaders or HLSL, so once again: Here be dragons.

## Special Thanks

[Lillium](https://github.com/EndlesslyFlowering) for their [ReShade HDR
Shaders](https://github.com/EndlesslyFlowering/ReShade_HDR_shaders) project,
which has been an inspiration for this project and a recurring source of insight
on my never-ending journey of learning about HDR and all things video / colour
science. I have made heavy use of the analysis overlay shader in particular
during the testing of this project. Go check it out!

[Crosire](https://github.com/crosire) and all those who develop
[ReShade](https://github.com/crosire/reshade) and the [ReShade-Shaders
repo](https://github.com/crosire/reshade-shaders), as this project obviously
depends on the former and the latter has served as a good reference and example
for my studies.

All those who work on [Special K](https://github.com/SpecialKO/SpecialK), for
like Lillium's shaders it has been a great boon for playing around with HDR in
games. I use it in practically every single game I play, the only exception
being certain multiplayer games and the very rare game that is not compatible
with it. It has been one of my favorite pieces of software for many years.

## To-do List

- [ ] Look into desaturation function for the YRGB mapping space on the
  tonemapping shader.
    - As I've come to understand things better, it seems like that may be the
      only difference between these two mapping spaces. The desaturation
      function is a part of the equations that modify Ct and Cp in the BT.2408
      EETF, so there's maybe a way to hybridize the BT.2408 YRGB mapping space
      to also include effectively the same function. This may be more accurate
      and more performant by comparison, since fewer-to-no PQ nonlinear
      conversions would be involved.
- [ ] Look into tonemapping output being slightly over the configured peak.
  - Maybe it's fine? Is it only scRGB due to the BT.2020 -> BT.709 at the end?
    Or from using ICtCp scaling?
- [ ] PLUGE shader for setting black level for non-reference environments, to be
  fed into the Static Tone Mapping shader for example to compensate for the
  ambient lighting.
  - ~~Need to first fix the above point about the display black setting on the
    tone mapping shader. Or maybe I'm misunderstanding something...~~
- [ ] Finish the PQ black level lift shader?
    - Now that the tonemapping shader black settings are fixed, it might be
      doing a better job. Need to think about if the PQ black level lift shader
      (created based on BT.814 PLUGE advice) would ever be preferable, either
      due to a different look or being more performant by skipping the rest of
      the tonemapping.
- [ ] Make a dumb, static BT.2020 -> DCI-P3 perceptual gamut map shader maybe?
  - This might just be a LUT. Probably not very useful, but could be interesting
    to do and learn about.
- [ ] Improve performance (probably a passive effort)
  - Probably saving this for later, and my priority is no visual issues so I'll
    take the performance impact if it means preventing oddities.
- [x] ~~PQ / HLG buffers are very broken. All the work so far has been on scRGB
  and that should be the buffer type used if you are able to choose (check out
  SpecialK).~~
    - HLG is straight up unimplemented most of the time. I don't think I've even
      seen it come up in any game before, but ReShade has it listed as a
      possible colour space for the buffer, so I will eventually complete the
      support for it, it just is low priority.
- [x] ~~Tonemapping display black setting seems to do weird things... Highlight
  compression is fine, but bumping up display black compresses the whole
  image.~~
    - Had a variable mixup. Looks good now
- [x] ~~Fix tonemapping (not sure what I did wrong)~~
- [x] ~~Add proper ICtCp color conversion in tonemapping (it will be the
  default)~~
- [x] ~~Technique for applying the same gamma adjustment that would've applied to
  a SDR -> HDR image, but on already-native HDR images. Should be pretty simple
  I think.~~
  - ~~The SDR Direct-Mapping shader has that gamma adjust code in one block, so
    yeah probably easy to conver that into something without the other
    conversions.~~
- [x] ~~SDR correction tools (sRGB <-> BT.1886 / Gamma 2.2)~~
  - ~~Since breaking out more functions, I think this should be easy to
    implement. The EOTF Correction shader may already do this? Need to
    double-check it with SDR, seems underwhelming currently.~~
- [x] ~~Add more tonemapping methods and a selector for them~~
    - ~~RGB at least is easy-enough and already kinda there. ICtCp seems like the
      best so this is low-priority.~~
    - ~~Selector has been added, but only ICtCp works at this time.~~
- [x] ~~Re-organize code / Take another look or two at my initial macro-based
  typedef shenanigans~~
    - [x] ~~Specifically, figure out splitting up some of the uniforms out of the
      main ReShadeCMS.fxh. Maybe multiple .fxh files?~~
    - Removed the macro-based typedefs. Will probably continue to refactor code
      in the future to make it easier to understand and work with.
