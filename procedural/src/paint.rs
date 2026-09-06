//! Small reproducible painted underlayer. Original CPU implementation, no model.
use serde::{Deserialize, Serialize};
#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
#[serde(deny_unknown_fields)]
pub struct Paint {
    pub color: [f32; 3],
    pub strength: f32,
    pub seed: u32,
    #[serde(default = "default_size")]
    pub size: u32,
    #[serde(default)]
    pub strokes: Vec<BrushStroke>,
    /// Fine periodic pigment deposits; albedo only, never baked directional light.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub granulation: Option<Granulation>,
}
#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
#[serde(deny_unknown_fields)]
pub struct Granulation {
    pub cells: [u32; 2],
    pub strength: f32,
    pub color: [f32; 3],
    /// Shading-only cavity depth in texture pixels, not physical displacement.
    #[serde(default)]
    pub relief_texels: f32,
}
impl Granulation {
    fn coverage(&self, uv: [f64; 2], seed: u32) -> f64 {
        let p: [f64; 2] = std::array::from_fn(|i| uv[i] * self.cells[i] as f64);
        let cell = p.map(|v| v.floor() as i32);
        let mut coverage = 0_f64;
        for y in -1..=1 {
            for x in -1..=1 {
                let c = [cell[0] + x, cell[1] + y];
                let mut hash = seed
                    ^ (c[0].rem_euclid(self.cells[0] as i32) as u32).wrapping_mul(0x8da6b343)
                    ^ (c[1].rem_euclid(self.cells[1] as i32) as u32).wrapping_mul(0xd8163841);
                let mut next = || {
                    hash ^= hash >> 16;
                    hash = hash.wrapping_mul(0x7feb352d);
                    hash ^= hash >> 15;
                    hash = hash.wrapping_mul(0x846ca68b);
                    hash = hash.wrapping_add(0x9e3779b9);
                    hash as f64 / 4294967296.
                };
                let center = [c[0] as f64 + next(), c[1] as f64 + next()];
                let radius = [0.16 + 0.3 * next(), 0.12 + 0.25 * next()];
                let r2 = ((p[0] - center[0]) / radius[0]).powi(2)
                    + ((p[1] - center[1]) / radius[1]).powi(2);
                coverage = coverage.max((1. - r2).max(0.).powi(2));
            }
        }
        coverage
    }
}
fn default_size() -> u32 {
    64
}
/// Editable UV-space calligraphic marks, composited in authoring order.
#[derive(Clone, Debug, Deserialize, Serialize, PartialEq)]
#[serde(deny_unknown_fields)]
pub struct BrushStroke {
    pub points: [[f32; 2]; 4],
    pub widths: [f32; 4],
    pub color: [f32; 3],
    pub opacity: f32,
    pub repeat_u: u32,
}
#[derive(Clone, Debug, Serialize)]
pub struct Texture {
    pub width: u32,
    pub height: u32,
    pub rgba: Vec<u8>,
    /// Linear +Y tangent normals, alpha 255; full mip chain, largest to 1x1.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub normal_rgba: Option<Vec<u8>>,
}
impl Texture {
    pub fn mip_bytes(&self) -> u64 {
        let (mut w, mut h) = (self.width, self.height);
        let mut bytes = 0;
        loop {
            bytes += w as u64 * h as u64 * 4;
            if w == 1 && h == 1 {
                break;
            }
            w = (w / 2).max(1);
            h = (h / 2).max(1);
        }
        bytes * if self.normal_rgba.is_some() { 2 } else { 1 }
    }
}
pub fn build(base: [f32; 4], paint: &Paint) -> crate::Result<Texture> {
    if let Some(g) = &paint.granulation {
        if g.cells.iter().any(|c| !(4..=paint.size / 4).contains(c))
            || !g.relief_texels.is_finite()
            || !(0. ..=4.).contains(&g.relief_texels)
            || g.color
                .iter()
                .chain([g.strength].iter())
                .any(|v| !v.is_finite() || !(0. ..=1.).contains(v))
        {
            return Err(
                "Granulation requires 4..size/4 cells and finite unit palette/strength".into(),
            );
        }
    }
    if ![64, 128, 256, 512].contains(&paint.size) || paint.strokes.len() > 64 {
        return Err("Paint requires size 64/128/256/512 and at most 64 strokes".into());
    }
    for s in &paint.strokes {
        if s.points
            .iter()
            .flatten()
            .any(|x| !x.is_finite() || !(0. ..=1.).contains(x))
            || s.widths
                .iter()
                .any(|x| !x.is_finite() || !(0. ..=0.1).contains(x))
            || s.widths == [0.; 4]
            || !(1..=16).contains(&s.repeat_u)
            || s.color
                .iter()
                .chain([s.opacity].iter())
                .any(|x| !x.is_finite() || !(0. ..=1.).contains(x))
        {
            return Err(
                "Invalid brush stroke coordinates, widths, palette, opacity or repeat count".into(),
            );
        }
    }
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
    let size = paint.size;
    let mut rgba = Vec::with_capacity((size * size * 4) as usize);
    for y in 0..size {
        for x in 0..size {
            let mut weight = 0.;
            for &(cx, cy, rx, ry, angle) in &strokes {
                let mut dx = (x as f64 + 0.5) / size as f64 - cx;
                dx -= dx.round();
                let mut dy = (y as f64 + 0.5) / size as f64 - cy;
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
    let mut work_left = 16_000_000_usize;
    for stroke in &paint.strokes {
        draw_stroke(&mut rgba, size as usize, stroke, &mut work_left)?;
    }
    let mut normal_rgba = None;
    if let Some(g) = &paint.granulation {
        let mut heights = vec![0_f32; (size * size) as usize];
        for y in 0..size {
            for x in 0..size {
                let coverage = g.coverage(
                    [
                        (x as f64 + 0.5) / size as f64,
                        (y as f64 + 0.5) / size as f64,
                    ],
                    paint.seed,
                ) as f32;
                heights[(y * size + x) as usize] = -coverage * g.relief_texels;
                let mix = coverage * g.strength;
                for channel in 0..3 {
                    let i = ((y * size + x) * 4) as usize + channel;
                    let before = rgba[i] as f32 / 255.;
                    rgba[i] = ((before + (g.color[channel] - before) * mix) * 255.).round() as u8;
                }
            }
        }
        if g.relief_texels > 0. {
            normal_rgba = Some(normal_mip_chain(normals_from_height(&heights, size), size));
        }
    }
    Ok(Texture {
        width: size,
        height: size,
        rgba,
        normal_rgba,
    })
}
fn normals_from_height(heights: &[f32], size: u32) -> Vec<u8> {
    let size = size as usize;
    let mut normals = Vec::with_capacity(size * size * 4);
    for y in 0..size {
        for x in 0..size {
            let dx = (heights[y * size + (x + 1) % size]
                - heights[y * size + (x + size - 1) % size])
                * 0.5;
            let dy = (heights[((y + 1) % size) * size + x]
                - heights[((y + size - 1) % size) * size + x])
                * 0.5;
            let length = (dx * dx + dy * dy + 1.).sqrt();
            for v in [-dx / length, -dy / length, 1. / length] {
                normals.push(((v * 0.5 + 0.5) * 255.).round() as u8);
            }
            normals.push(255);
        }
    }
    normals
}
/// Box-filter decoded vectors, then normalize before each RGBA8 encoding.
/// Input dimensions are validated power-of-two square paint sizes.
fn normal_mip_chain(mut pixels: Vec<u8>, size: u32) -> Vec<u8> {
    let mut width = size as usize;
    let mut offset = 0;
    while width > 1 {
        let next_width = width / 2;
        let next_offset = pixels.len();
        for y in 0..next_width {
            for x in 0..next_width {
                let mut sum = [0_f64; 3];
                for dy in 0..2 {
                    for dx in 0..2 {
                        let i = offset + ((2 * y + dy) * width + 2 * x + dx) * 4;
                        for c in 0..3 {
                            sum[c] += pixels[i + c] as f64 / 255. * 2. - 1.;
                        }
                    }
                }
                let length = sum.iter().map(|v| v * v).sum::<f64>().sqrt();
                let unit = if length > 1e-12 {
                    sum.map(|v| v / length)
                } else {
                    [0., 0., 1.]
                };
                for v in unit {
                    pixels.push(((v * 0.5 + 0.5) * 255.).round() as u8);
                }
                pixels.push(255);
            }
        }
        offset = next_offset;
        width = next_width;
    }
    pixels
}
fn draw_stroke(
    pixels: &mut [u8],
    size: usize,
    s: &BrushStroke,
    work_left: &mut usize,
) -> crate::Result<()> {
    if s.opacity == 0. {
        return Ok(());
    }
    let mut coverage = vec![0_f32; size * size];
    let point = |t: f64, k: u32| {
        let a = 1. - t;
        let p: [f64; 2] = std::array::from_fn(|i| {
            a * a * a * s.points[0][i] as f64
                + 3. * a * a * t * s.points[1][i] as f64
                + 3. * a * t * t * s.points[2][i] as f64
                + t * t * t * s.points[3][i] as f64
        });
        [
            ((p[0] + k as f64) / s.repeat_u as f64) * size as f64,
            p[1] * size as f64,
        ]
    };
    // 128 bounded samples per mark; union coverage avoids dark seams between
    // line segments. UV repeat wraps horizontally, not onto vessel interiors.
    for k in 0..s.repeat_u {
        for step in 0..128 {
            let t0 = step as f64 / 128.;
            let t1 = (step + 1) as f64 / 128.;
            let a = point(t0, k);
            let b = point(t1, k);
            let d = [b[0] - a[0], b[1] - a[1]];
            let length = d[0] * d[0] + d[1] * d[1];
            let width = |t: f64| {
                let a = 1. - t;
                (a * a * a * s.widths[0] as f64
                    + 3. * a * a * t * s.widths[1] as f64
                    + 3. * a * t * t * s.widths[2] as f64
                    + t * t * t * s.widths[3] as f64)
                    * size as f64
                    * 0.5
            };
            let radius = width(t0).max(width(t1)) + 1.;
            for y in ((a[1].min(b[1]) - radius).floor() as i32).max(0)
                ..=((a[1].max(b[1]) + radius).ceil() as i32).min(size as i32 - 1)
            {
                for x in (a[0].min(b[0]) - radius).floor() as i32
                    ..=(a[0].max(b[0]) + radius).ceil() as i32
                {
                    if *work_left == 0 {
                        return Err("Paint raster work budget exceeded".into());
                    }
                    *work_left -= 1;
                    let v = [x as f64 + 0.5 - a[0], y as f64 + 0.5 - a[1]];
                    let f = if length > 0. {
                        ((v[0] * d[0] + v[1] * d[1]) / length).clamp(0., 1.)
                    } else {
                        0.
                    };
                    let dist = (v[0] - f * d[0]).hypot(v[1] - f * d[1]);
                    let alpha = (width(t0 + (t1 - t0) * f) + 0.5 - dist).clamp(0., 1.) as f32;
                    let idx = y as usize * size + x.rem_euclid(size as i32) as usize;
                    coverage[idx] = coverage[idx].max(alpha);
                }
            }
        }
    }
    for (i, c) in coverage.into_iter().enumerate() {
        let mix = c * s.opacity;
        for channel in 0..3 {
            let previous = pixels[i * 4 + channel] as f32 / 255.;
            pixels[i * 4 + channel] =
                ((previous + (s.color[channel] - previous) * mix) * 255.).round() as u8;
        }
    }
    Ok(())
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn normal_mips_preserve_base_and_average_vectors_not_colors() {
        // Opposite X slopes with positive Z must converge toward a flat normal.
        let base = vec![
            218, 128, 218, 255, 37, 128, 218, 255, 218, 128, 218, 255, 37, 128, 218, 255,
        ];
        let chain = normal_mip_chain(base.clone(), 2);
        assert_eq!(&chain[..16], &base);
        assert_eq!(&chain[16..], &[128, 128, 255, 255]);
        for size in [64, 128, 256, 512] {
            let base = [128, 128, 255, 255].repeat((size * size) as usize);
            let chain = normal_mip_chain(base.clone(), size);
            let expected = (0..=size.ilog2())
                .map(|level| ((size >> level).pow(2) * 4) as usize)
                .sum::<usize>();
            assert_eq!(chain.len(), expected);
            assert_eq!(&chain[..base.len()], &base);
            assert!(chain
                .as_chunks::<4>()
                .0
                .iter()
                .all(|p| *p == [128, 128, 255, 255]));
        }
    }
    #[test]
    fn relief_has_normalized_direction_and_explicit_cost() {
        let flat = normals_from_height(&[0.; 16], 4);
        assert!(flat
            .as_chunks::<4>()
            .0
            .iter()
            .all(|p| *p == [128, 128, 255, 255]));
        let mut ramp = vec![0.; 16];
        for y in 0..4 {
            for x in 0..4 {
                ramp[y * 4 + x] = x as f32;
            }
        }
        let slopes = normals_from_height(&ramp, 4);
        assert!(slopes[(4 + 1) * 4] < 128); // +U height slope tilts normal toward -U.
        assert!(slopes[4 * 4] > 128); // Wrapped derivative, not clamped border.
        let mut p: Paint = serde_json::from_str(r#"{"color":[0,0,0],"strength":0,"seed":19,"granulation":{"cells":[12,7],"strength":0.5,"color":[0.1,0.1,0.1],"relief_texels":2}}"#).unwrap();
        let textured = build([1.; 4], &p).unwrap();
        let data = textured.normal_rgba.as_ref().unwrap();
        assert_eq!(data.len(), 21844);
        for pixel in data.as_chunks::<4>().0 {
            let n: Vec<_> = pixel[..3]
                .iter()
                .map(|v| *v as f32 / 255. * 2. - 1.)
                .collect();
            assert!((n.iter().map(|v| v * v).sum::<f32>().sqrt() - 1.).abs() < 0.014);
            assert!(n[2] > 0.);
            assert_eq!(pixel[3], 255);
        }
        assert_eq!(*data, build([1.; 4], &p).unwrap().normal_rgba.unwrap());
        p.granulation.as_mut().unwrap().relief_texels = 0.;
        let plain = build([1.; 4], &p).unwrap();
        assert_eq!(textured.rgba, plain.rgba);
        assert_eq!(textured.mip_bytes(), plain.mip_bytes() * 2);
        assert!(plain.normal_rgba.is_none());
        for invalid in [-1., 4.1, f32::NAN, f32::INFINITY] {
            p.granulation.as_mut().unwrap().relief_texels = invalid;
            assert!(build([1.; 4], &p).is_err());
        }
    }
    #[test]
    fn granulation_is_periodic_bounded_and_optional() {
        let mut p: Paint =
            serde_json::from_str(r#"{"color":[0,0,0],"strength":0,"seed":19}"#).unwrap();
        let plain = build([0.8, 0.7, 0.5, 1.], &p).unwrap();
        let g = Granulation {
            cells: [12, 7],
            strength: 0.7,
            color: [0.2, 0.1, 0.05],
            relief_texels: 0.,
        };
        for uv in [[0., 0.], [0.23, 0.78], [-0.12, 1.34]] {
            let a = g.coverage(uv, 19);
            assert!((0. ..=1.).contains(&a));
            assert!((a - g.coverage([uv[0] + 1., uv[1] - 1.], 19)).abs() < 1e-12);
        }
        p.granulation = Some(g);
        let first = build([0.8, 0.7, 0.5, 1.], &p).unwrap();
        assert_ne!(first.rgba, plain.rgba);
        assert_eq!(first.rgba, build([0.8, 0.7, 0.5, 1.], &p).unwrap().rgba);
        assert_eq!(first.mip_bytes(), plain.mip_bytes());
        p.granulation.as_mut().unwrap().strength = 0.;
        assert_eq!(plain.rgba, build([0.8, 0.7, 0.5, 1.], &p).unwrap().rgba);
        for invalid in [0, 17, u32::MAX] {
            p.granulation.as_mut().unwrap().cells = [12, invalid];
            assert!(build([1.; 4], &p).is_err());
        }
    }
    #[test]
    fn editable_marks_repeat_taper_and_roundtrip() {
        let mut p: Paint =
            serde_json::from_str(r#"{"color":[0,0,0],"strength":0,"seed":1}"#).unwrap();
        assert_eq!(p.size, 64);
        p.strokes.push(BrushStroke {
            points: [[0., 0.5], [0.33, 0.5], [0.67, 0.5], [1., 0.5]],
            widths: [0.08, 0.06, 0.04, 0.02],
            color: [1., 0.7, 0.2],
            opacity: 1.,
            repeat_u: 2,
        });
        let painted = build([0., 0., 0., 1.], &p).unwrap();
        assert!(painted.rgba[(32 * 64 + 4) * 4] > 200);
        assert_eq!(
            painted.rgba[(32 * 64 + 4) * 4],
            painted.rgba[(32 * 64 + 36) * 4]
        );
        assert_eq!(painted.rgba[0], 0);
        let restored: Paint = serde_json::from_slice(&serde_json::to_vec(&p).unwrap()).unwrap();
        assert_eq!(p, restored);
        assert_eq!(
            painted.rgba,
            build([0., 0., 0., 1.], &restored).unwrap().rgba
        );
        assert_eq!(painted.mip_bytes(), 21844);
        let mut pixels = vec![0; 64 * 64 * 4];
        assert!(draw_stroke(&mut pixels, 64, &p.strokes[0], &mut 0).is_err());
        p.size = 63;
        assert!(build([0.; 4], &p).is_err());
        p.size = 64;
        p.strokes[0].repeat_u = 0;
        assert!(build([0.; 4], &p).is_err());
    }
    #[test]
    fn deterministic_bounded_and_seeded() {
        let p = Paint {
            color: [0.7, 0.6, 0.3],
            strength: 0.6,
            seed: 42,
            size: 64,
            strokes: vec![],
            granulation: None,
        };
        let first = build([0.2, 0.3, 0.1, 1.], &p).unwrap();
        assert_eq!(first.rgba.len(), 64 * 64 * 4);
        assert_eq!(first.rgba, build([0.2, 0.3, 0.1, 1.], &p).unwrap().rgba);
        assert_ne!(
            first.rgba,
            build(
                [0.2, 0.3, 0.1, 1.],
                &Paint {
                    seed: 43,
                    ..p.clone()
                }
            )
            .unwrap()
            .rgba
        );
        assert!(first
            .rgba
            .as_chunks::<4>()
            .0
            .iter()
            .all(|pixel| pixel[3] == 255));
        let solid = build(
            [0.2, 0.3, 0.1, 1.],
            &Paint {
                strength: 0.,
                ..p.clone()
            },
        )
        .unwrap();
        assert!(solid
            .rgba
            .as_chunks::<4>()
            .0
            .iter()
            .all(|pixel| *pixel == [51, 77, 26, 255]));
        assert!(build(
            [0.; 4],
            &Paint {
                strength: f32::NAN,
                ..p
            }
        )
        .is_err());
    }
}
