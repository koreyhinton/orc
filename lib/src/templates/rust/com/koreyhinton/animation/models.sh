#!/bin/bash

# animation models
#
#   command arg:  <version>, the orc animation version the app expects
#   prints:       the types the animation snippets use
#   settings:     ANIMATION_ANIMATION_FULLY_QUALIFIED        default Animation
#                 ANIMATION_ANIMATED_SPRITE_FULLY_QUALIFIED  default AnimatedSprite
#                 ANIMATION_PAINT_FRAME_FULLY_QUALIFIED      default PaintFrame
#
#   Call it between heredocs, not in backticks, so a version mismatch stops
#   the app's script:
#       ${ORC_ANIMATION}/models.sh 0.1.0 || exit 1
#
#   Rename a type when the app already has one by that name. Set the same
#   settings for the snippets, which use the names too.

: "${ANIMATION_ANIMATION_FULLY_QUALIFIED:=Animation}"
: "${ANIMATION_ANIMATED_SPRITE_FULLY_QUALIFIED:=AnimatedSprite}"
: "${ANIMATION_PAINT_FRAME_FULLY_QUALIFIED:=PaintFrame}"
. "$(dirname "${BASH_SOURCE[0]}")/version.sh" "${1}"

cat << EOF

    struct ${ANIMATION_ANIMATION_FULLY_QUALIFIED} {
        id: String,
        fps: f32,
        frames: u32,
        row: u32,
    }

    struct ${ANIMATION_PAINT_FRAME_FULLY_QUALIFIED} {
        x: f32,
        y: f32,
        w: f32,
        h: f32,
    }

    struct ${ANIMATION_ANIMATED_SPRITE_FULLY_QUALIFIED}<'a> {
        w: f32,
        h: f32,
        frame: u32,
        frame_time: f32, // lib resets back to 0, but caller increments it
        animation: &'a ${ANIMATION_ANIMATION_FULLY_QUALIFIED},
        last_animation_id: String,
        paint_frame: Option<${ANIMATION_PAINT_FRAME_FULLY_QUALIFIED}>,
    }

EOF
