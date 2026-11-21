#!/bin/bash

# animation models
#
#   command arg:  <version>, the orc animation version the app expects
#   prints:       the types the animation snippets use
#
#   Call it between heredocs, not in backticks, so a version mismatch stops
#   the app's script:
#       ${ORC_ANIMATION}/models.sh 0.1.0 || exit 1

. "$(dirname "${BASH_SOURCE[0]}")/version.sh" "${1}"

cat << EOF

    struct Animation {
        id: String,
        fps: f32,
        frames: u32,
        row: u32,
    }

    struct PaintFrame {
        x: f32,
        y: f32,
        w: f32,
        h: f32,
    }

    struct AnimatedSprite<'a> {
        w: f32,
        h: f32,
        frame: u32,
        frame_time: f32, // lib resets back to 0, but caller increments it
        animation: &'a Animation,
        last_animation_id: String,
        paint_frame: Option<PaintFrame>,
    }

EOF
