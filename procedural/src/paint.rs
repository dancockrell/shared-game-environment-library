//! Small reproducible painted underlayer. Original CPU implementation, no model.
use serde::{Deserialize, Serialize};
#[derive(Clone, Copy, Debug, Deserialize, Serialize, PartialEq)]
#[serde(deny_unknown_fields)]
pub struct Paint {
    pub color: [f32; 3],
    pub strength: f32,
    pub seed: u32,
}
#[derive(Clone, Debug, Serialize)]
pub struct Texture {
    pub width: u32,
    pub height: u32,
    pub rgba: Vec<u8>,
}
pub fn build(base: [f32; 4], paint: Paint) -> crate::Result<Texture> {
    if paint
        .color
        .iter()
        .chain([paint.strength].iter())
        .any(|v| !v.is_finite() || !(0. ..=1.).contains(v))
    {
        return Err("Paint palette and strength must be finite values in 0..1".into());
    }
    let mut state = paint.seed ^ 0x9e3779b9;
    let mut next = || {
        state = state.wrapping_mul(1664525).wrapping_add(1013904223);
        (state >> 8) as f64 / 16777216.
    };
    let strokes: Vec<_> = (0..32)
        .map(|_| {
            (
                next(),
                next(),
                0.08 + next() * 0.12,
                0.025 + next() * 0.045,
                (next() - 0.5) * 1.2,
            )
        })
        .collect();
    let mut rgba = Vec::with_capacity(64 * 64 * 4);
    for y in 0..64 {
        for x in 0..64 {
            let mut weight = 0.;
            for &(cx, cy, rx, ry, angle) in &strokes {
                let mut dx = (x as f64 + 0.5) / 64. - cx;
                dx -= dx.round();
                let mut dy = (y as f64 + 0.5) / 64. - cy;
                dy -= dy.round();
                let (s, c) = angle.sin_cos();
                let radius = ((dx * c + dy * s) / rx).powi(2) + ((-dx * s + dy * c) / ry).powi(2);
                let stroke = (1. - radius).max(0.).powi(2);
                weight = 1. - (1. - weight) * (1. - stroke);
            }
            let mix = (weight * paint.strength as f64) as f32;
            for (a, b) in base[..3].iter().zip(paint.color) {
                rgba.push(((a + (b - a) * mix).clamp(0., 1.) * 255.).round() as u8);
            }
            rgba.push(255);
        }
    }
    Ok(Texture {
        width: 64,
        height: 64,
        rgba,
    })
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn deterministic_bounded_and_seeded() {
        let p = Paint {
            color: [0.7, 0.6, 0.3],
            strength: 0.6,
            seed: 42,
        };
        let first = build([0.2, 0.3, 0.1, 1.], p).unwrap();
        assert_eq!(first.rgba.len(), 64 * 64 * 4);
        assert_eq!(first.rgba, build([0.2, 0.3, 0.1, 1.], p).unwrap().rgba);
        assert_ne!(
            first.rgba,
            build([0.2, 0.3, 0.1, 1.], Paint { seed: 43, ..p })
                .unwrap()
                .rgba
        );
        assert!(first
            .rgba
            .as_chunks::<4>()
            .0
            .iter()
            .all(|pixel| pixel[3] == 255));
        let solid = build([0.2, 0.3, 0.1, 1.], Paint { strength: 0., ..p }).unwrap();
        assert!(solid
            .rgba
            .as_chunks::<4>()
            .0
            .iter()
            .all(|pixel| *pixel == [51, 77, 26, 255]));
        assert!(build(
            [0.; 4],
            Paint {
                strength: f32::NAN,
                ..p
            }
        )
        .is_err());
    }
}
