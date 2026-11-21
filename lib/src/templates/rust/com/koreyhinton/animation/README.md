# Animation

Sprite-sheet animation for Rust, generated from bash with orc. The
`animate-sprite` snippet steps a sprite through the frames of its current
animation at the animation's fps, restarts at frame 0 when the animation
changes, and works out the rectangle of the current frame in the sprite
sheet (the paint frame).

It doesn't draw anything, so it works with any game library or engine: pass
the paint frame to whatever draws a sub-rectangle of a texture. With
macroquad, for example, that's the `source` of `draw_texture_ex`. The example
below doesn't use a game library at all: it's a command line app that prints
each step.

The sprite sheet is laid out with one animation per row, and that
animation's frames left to right, each `w` by `h`. Frame `n` of an animation
on row `r` is at `(w * n, h * r)`.

## Credits

`animate-sprite` is adapted from macroquad's `src/experimental/animation.rs`
(`AnimatedSprite::update` and `AnimatedSprite::frame`), Copyright (c)
2019-2021 Fedor Logachev, under the MIT license. Its license is next to the
snippet, in `snippets/macroquad/LICENSE-MIT`, and the snippet prints the
credit into the generated code. Include that license along with orc's
https://github.com/koreyhinton/orc/blob/main/LICENSE (AGPL-3.0) for your app.

## Snippets

| Snippet | What it does |
| --- | --- |
| `snippets/macroquad/animate-sprite.sh` | steps an `AnimatedSprite` for one update, and sets its `paint_frame` |

Call it once per update (per frame of your game loop), after adding the
update's elapsed time to the sprite's `frame_time`:

```sh
sprite.frame_time += dt;
` ${ORC_ANIMATION}/snippets/macroquad/animate-sprite.sh ${v}anim_ `
```

| Binding | Type | |
| --- | --- | --- |
| `\|ns_\|AnimatedSprite` | `AnimatedSprite` | input/output, declared by the caller |

It reads `frame_time`, `animation`, `w`, `h`, `last_animation_id` and
whether `paint_frame` is set yet, and sets `frame`, `frame_time`,
`last_animation_id` and `paint_frame`. Your app decides when it
runs: to pause an animation, don't call it (and don't add frame time).

## Types and models.sh

`models.sh <version>` prints the types the snippet uses. Unlike orc's other
languages, for Rust it prints just the type definitions, with no module line
or imports: your app inlines them in its own generated file. Call it between
heredocs, not in backticks, so a version mismatch stops your build (see the
example's `main.sh`). With the default names, and comments added here:

```rust
struct Animation {
    id: String,     // the snippet restarts at frame 0 when this changes
    fps: f32,
    frames: u32,    // frames in the animation's row
    row: u32,       // the animation's row in the sprite sheet
}

struct PaintFrame {
    x: f32,         // the current frame's rectangle in the sprite sheet
    y: f32,
    w: f32,
    h: f32,
}

struct AnimatedSprite<'a> {
    w: f32,         // the size of one frame
    h: f32,
    frame: u32,
    frame_time: f32, // the caller adds elapsed time, the snippet resets it
    animation: &'a Animation,
    last_animation_id: String,
    paint_frame: Option<PaintFrame>,
}
```

Start a sprite with `frame: 0`, `frame_time: 0.0`,
`last_animation_id: String::new()` and `paint_frame: None`. The snippet sets
`paint_frame` on its first update, so it's `None` until then: check for that
before drawing. To change animations, point `animation` at another one; the
snippet notices by its `id`.

## Settings

| Setting | Default | Used by |
| --- | --- | --- |
| `ANIMATION_ANIMATION_FULLY_QUALIFIED` | `Animation` | `models.sh` |
| `ANIMATION_ANIMATED_SPRITE_FULLY_QUALIFIED` | `AnimatedSprite` | `models.sh` |
| `ANIMATION_PAINT_FRAME_FULLY_QUALIFIED` | `PaintFrame` | `models.sh`, `animate-sprite.sh` |

Rename a type when your app already has one by that name, such as
macroquad's `experimental::animation::Animation`. Export the settings before
calling `models.sh` and the snippet:

```sh
export ANIMATION_ANIMATION_FULLY_QUALIFIED=OrcAnimation
```

## Imports

None. The snippet only uses Rust's core types, and orc libraries don't wrap
third-party ones: your app imports what it uses itself, such as your game
library's draw call.

## Version

The library's version is in `version.sh` (`0.1.0`). `models.sh` takes the
version your app asks for, and fails your build if it doesn't match:

```
Error: invalid orc animation version specified. Requested: 0.0.1, provided: 0.1.0
```

Keep the version your app asks for in one place, such as `build.sh`
(`ORC_ANIMATION_VERSION` in the example), and check out the orc version that
matches it.

## What it doesn't handle yet

- It steps at most one frame per update, and resets `frame_time` to 0 when it
  steps, so the time past the frame interval is dropped. A long update (a
  hitch) doesn't catch up, and the animation plays a little slower than its
  fps: at 0.03s per update and 10 fps, it steps every 4 updates (0.12s), not
  every 0.1s.
- It steps when `frame_time` is more than `1 / fps`, not equal to it.
- Every animation loops. There's no play-once, ping-pong or reverse.
- An animation's frames must fit in one row of the sprite sheet.
- An animation with 0 frames stays on frame 0, and one with an fps of 0
  never steps.

## Example

A command line app, `sprite-steps`, that takes animations as text options
and prints each update of the snippet, one after another: the animation,
the frame, the paint frame, and what happened (the first update, a step to
the next frame, or a swap to a new animation). There's no game loop or game
library: it just runs the updates in a `for` loop, adding a fixed time to
each.

You must change this path variable inside `./build.sh`:

* orc

Source files:

- ./Cargo.toml
- ./build.sh
- ./src/main.sh

Generated files:

- ./src/main.rs

### ./ (app root folder)

./Cargo.toml

```toml
[package]
name = "sprite-steps"
version = "0.1.0"
edition = "2021"

[dependencies]
```

./build.sh

```sh
#!/bin/bash

orc=/path/to/orc  # path to root of this repo
export NSMAP=${orc}/lib/src/main/bash/com/koreyhinton/nsmap
export ORC_ANIMATION=${orc}/lib/src/templates/rust/com/koreyhinton/animation
export ORC_ANIMATION_VERSION=0.1.0

set -o pipefail

cd "$(dirname "$0")/src" || exit 1
# write to a temp file, so a failed generate keeps the last good main.rs
./main.sh > ./main.rs.tmp && mv ./main.rs.tmp ./main.rs || exit 1
```

command line run

```sh
chmod +x build.sh
chmod +x src/main.sh
./build.sh && cargo run -- size=32x48 dt=0.03 updates=12 anim=walk,10,6,1 anim=idle,10,2,0@8
```

The options:

| Option | Default | |
| --- | --- | --- |
| `size=WxH` | `32x48` | the size of one frame in the sprite sheet |
| `dt=SECONDS` | `0.03` | the time each update adds |
| `updates=N` | `12` | how many updates to run |
| `anim=ID,FPS,FRAMES,ROW[@START]` | (at least one) | an animation, and the update it starts on (default 0) |

It plays the walk animation (row 1, 6 frames at 10 fps), then swaps to idle
(row 0, 2 frames) on update 8:

```
update   time  animation  frame  paint (x, y, w, h)    event
     0  0.03s  walk           0  (0, 48, 32, 48)       first update
     1  0.06s  walk           0  (0, 48, 32, 48)
     2  0.09s  walk           0  (0, 48, 32, 48)
     3  0.12s  walk           0  (0, 48, 32, 48)
     4  0.15s  walk           1  (32, 48, 32, 48)      step
     5  0.18s  walk           1  (32, 48, 32, 48)
     6  0.21s  walk           1  (32, 48, 32, 48)
     7  0.24s  walk           1  (32, 48, 32, 48)
     8  0.27s  idle           0  (0, 0, 32, 48)        swap
     9  0.30s  idle           0  (0, 0, 32, 48)
    10  0.33s  idle           0  (0, 0, 32, 48)
    11  0.36s  idle           0  (0, 0, 32, 48)
```

The first update restarts at frame 0 and resets `frame_time`, so the walk
steps once `frame_time` passes 0.1s, on the 4th update after it (0.12s). The
swap to idle restarts at frame 0 on idle's row (y = 0).

With an update time over the frame interval, it steps every update, and
wraps back to frame 0 after the last frame:

```sh
cargo run -- size=16x16 dt=0.11 updates=8 anim=blink,10,3,2
```

```
update   time  animation  frame  paint (x, y, w, h)    event
     0  0.11s  blink          0  (0, 32, 16, 16)       first update
     1  0.22s  blink          1  (16, 32, 16, 16)      step
     2  0.33s  blink          2  (32, 32, 16, 16)      step
     3  0.44s  blink          0  (0, 32, 16, 16)       step
     4  0.55s  blink          1  (16, 32, 16, 16)      step
     5  0.66s  blink          2  (32, 32, 16, 16)      step
     6  0.77s  blink          0  (0, 32, 16, 16)       step
     7  0.88s  blink          1  (16, 32, 16, 16)      step
```

### ./src (subfolder)

./src/main.sh

```sh
#!/bin/bash

v=${1:-mn_}
# maps
export ${v}anim_AnimatedSprite=sprite

cat << EOF
#![allow(non_snake_case)]

use std::env;
use std::process;
use std::str::FromStr;

EOF

# between heredocs, so a version mismatch stops the build
${ORC_ANIMATION}/models.sh "${ORC_ANIMATION_VERSION}" || exit 1

cat << EOF

// an animation from the command line, and the update it starts on
struct Track {
    animation: Animation,
    start: u32,
}

fn usage() -> ! {
    eprintln!("usage: sprite-steps [size=WxH] [dt=SECONDS] [updates=N] [anim=ID,FPS,FRAMES,ROW[@START]]...");
    eprintln!("example: sprite-steps size=32x48 dt=0.03 updates=12 anim=walk,10,6,1 anim=idle,10,2,0@8");
    process::exit(2);
}

fn parse<T: FromStr>(text: &str) -> T {
    text.parse().unwrap_or_else(|_| usage())
}

fn main() {
    // defaults, changed by key=value arguments
    let mut w: f32 = 32.0;
    let mut h: f32 = 48.0;
    let mut dt: f32 = 0.03; // seconds per update
    let mut updates: u32 = 12;
    let mut tracks: Vec<Track> = vec![];

    for arg in env::args().skip(1) {
        let (key, value) = arg.split_once('=').unwrap_or_else(|| usage());
        match key {
            "size" => {
                let (sw, sh) = value.split_once('x').unwrap_or_else(|| usage());
                w = parse(sw);
                h = parse(sh);
            }
            "dt" => dt = parse(value),
            "updates" => updates = parse(value),
            "anim" => {
                let (spec, start) = value.split_once('@').unwrap_or((value, "0"));
                let parts: Vec<&str> = spec.split(',').collect();
                if parts.len() != 4 {
                    usage();
                }
                tracks.push(Track {
                    animation: Animation {
                        id: parts[0].to_string(),
                        fps: parse(parts[1]),
                        frames: parse(parts[2]),
                        row: parse(parts[3]),
                    },
                    start: parse(start),
                });
            }
            _ => usage(),
        }
    }
    if tracks.is_empty() {
        usage();
    }
    tracks.sort_by_key(|track| track.start);

    let mut sprite = AnimatedSprite {
        w,
        h,
        frame: 0,
        frame_time: 0.0,
        animation: &tracks[0].animation,
        last_animation_id: String::new(),
        paint_frame: None,
    };

    println!("update   time  animation  frame  paint (x, y, w, h)    event");
    let mut time: f32 = 0.0;
    for update in 0..updates {
        // play the latest animation that has started by this update
        for track in &tracks {
            if track.start <= update {
                sprite.animation = &track.animation;
            }
        }

        let first = sprite.paint_frame.is_none();
        let last_id = sprite.last_animation_id.clone();
        let last_frame = sprite.frame;

        // the caller adds the elapsed time, then the snippet steps the frame
        time += dt;
        sprite.frame_time += dt;
        ` ${ORC_ANIMATION}/snippets/macroquad/animate-sprite.sh ${v}anim_ `

        let event = if first {
            "first update"
        } else if sprite.last_animation_id != last_id {
            "swap"
        } else if sprite.frame != last_frame {
            "step"
        } else {
            ""
        };
        if let Some(paint) = sprite.paint_frame.as_ref() {
            let rect = format!("({}, {}, {}, {})", paint.x, paint.y, paint.w, paint.h);
            let line = format!(
                "{:>6}  {:>4.2}s  {:<9}  {:>5}  {:<20}  {}",
                update, time, sprite.animation.id, sprite.frame, rect, event
            );
            println!("{}", line.trim_end());
        }
    }
}

EOF
```

## Tests

The library's tests are in `lib/src/test/rust/com/koreyhinton/animation/`
(see its `README.md`). Run them all with:

```sh
lib/src/test/rust/com/koreyhinton/animation/run.sh
```
