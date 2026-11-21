#!/bin/bash

# animation animate-sprite
#
#   Adapted from macroquad's src/experimental/animation.rs
#   (AnimatedSprite::update and AnimatedSprite::frame),
#   Copyright (c) 2019-2021 Fedor Logachev, MIT License. See LICENSE-MIT.

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

    let ${v}${priv}PaintFrame = ${!animated_sprite}.paint_frame.get_or_insert(
        PaintFrame { x: 0.0, y: 0.0, w: 0.0, h: 0.0 }
    );

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

    ${v}${priv}PaintFrame.x = ${!animated_sprite}.w * ${!animated_sprite}.frame as f32;
    ${v}${priv}PaintFrame.y = ${!animated_sprite}.h * ${!animated_sprite}.animation.row as f32;
    ${v}${priv}PaintFrame.w = ${!animated_sprite}.w;
    ${v}${priv}PaintFrame.h = ${!animated_sprite}.h;

    /**********************************************************************
     *                                                                    *
     * :END: animation animate-sprite                                     *
     *                                                                    *
     **********************************************************************/

EOF
