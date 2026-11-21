#!/bin/bash

# animation animate-sprite
#
#   Adapted from macroquad's src/experimental/animation.rs
#   (AnimatedSprite::update and AnimatedSprite::frame),
#   Copyright (c) 2019-2021 Fedor Logachev, MIT License. See LICENSE-MIT.
#
#   settings:     ANIMATION_PAINT_FRAME_FULLY_QUALIFIED  default PaintFrame
#                 (the same as for models.sh)

: "${ANIMATION_PAINT_FRAME_FULLY_QUALIFIED:=PaintFrame}"
v=$1
priv=${RANDOM}_
# maps
. ${NSMAP}/bind $v AnimatedSprite

cat << EOF

    /**********************************************************************
     *                                                                    *
     *    animation animate-sprite                                        *
     *                                                                    *
     *        command arg:                                                *
     *            |ns_|                                                   *
     *                                                                    *
     *        input/output:                                               *
     *            |ns_|AnimatedSprite: AnimatedSprite                     *
     *                declared by the caller                              *
     *                frame_time: the caller adds the frame's elapsed     *
     *                    time before this runs; reset here on each step  *
     *                frame, last_animation_id, paint_frame: set here     *
     *                                                                    *
     *        required model types (models.sh):                           *
     *            Animation, AnimatedSprite, PaintFrame                   *
     *            (renamed by the ANIMATION_*_FULLY_QUALIFIED settings)   *
     *                                                                    *
     *        Steps the frame at animation.fps, restarts at frame 0 when  *
     *        animation.id changes, and sets paint_frame to the source    *
     *        rect of the current frame. The caller decides when it runs  *
     *        (such as only while playing).                               *
     *                                                                    *
     *        Adapted from macroquad src/experimental/animation.rs        *
     *        (AnimatedSprite::update and AnimatedSprite::frame)          *
     *        Copyright (c) 2019-2021 Fedor Logachev <not.fl3@gmail.com>  *
     *        MIT License (see snippets/macroquad/LICENSE-MIT in orc)     *
     *                                                                    *
     **********************************************************************/

    let ${v}${priv}FirstPaint = ${!animated_sprite}.paint_frame.is_none();

    let ${v}${priv}AnimationSwapped = ${v}${priv}FirstPaint ||
        ${!animated_sprite}.animation.id != ${!animated_sprite}.last_animation_id;

    let ${v}${priv}IncrementFrame = !${v}${priv}AnimationSwapped &&
        ${!animated_sprite}.frame_time > 1. / ${!animated_sprite}.animation.fps;

    if ${v}${priv}AnimationSwapped {
        ${!animated_sprite}.frame = 0;
        ${!animated_sprite}.frame_time = 0.0;
        ${!animated_sprite}.last_animation_id =
            ${!animated_sprite}.animation.id.clone();
    }

    if ${v}${priv}IncrementFrame && ${!animated_sprite}.animation.frames > 0 {
        ${!animated_sprite}.frame = (${!animated_sprite}.frame + 1)
            % ${!animated_sprite}.animation.frames;
        ${!animated_sprite}.frame_time = 0.0;
    }

    // Set in one statement, so no borrow of paint_frame is held while other
    // fields are written. That keeps it compiling when the sprite is an
    // indexed element, such as sprites[i].
    ${!animated_sprite}.paint_frame = Some(${ANIMATION_PAINT_FRAME_FULLY_QUALIFIED} {
        x: ${!animated_sprite}.w * ${!animated_sprite}.frame as f32,
        y: ${!animated_sprite}.h * ${!animated_sprite}.animation.row as f32,
        w: ${!animated_sprite}.w,
        h: ${!animated_sprite}.h,
    });

    /**********************************************************************
     *                                                                    *
     * :END: animation animate-sprite                                     *
     *                                                                    *
     **********************************************************************/

EOF
