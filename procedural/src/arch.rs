//! Elliptical structural band; clear opening dimensions, no filled-in doorway.
use crate::{finite, quad, Mesh, Result, V3};

fn textured_quad(m: &mut Mesh, p: [V3; 4], uv: [[f32; 2]; 4]) -> Result<()> {
    let start = m.positions.len();
    quad(m, p[0], p[1], p[2], p[3])?;
    if m.positions.len() != start + 6 {
        return Err("Arch surface collapses at output precision".into());
    }
    for (offset, corner) in [0, 1, 2, 0, 2, 3].into_iter().enumerate() {
        m.uvs[start + offset] = uv[corner];
    }
    Ok(())
}

pub(super) fn build(
    m: &mut Mesh,
    width: f32,
    rise: f32,
    thickness: f32,
    depth: f32,
    segments: u32,
    budget: usize,
) -> Result<()> {
    finite(&[width, rise, thickness, depth])?;
    if [width, rise, thickness, depth].iter().any(|x| *x <= 0.)
        || !(4..=512).contains(&segments)
        || !segments.is_multiple_of(2)
    {
        return Err("Arch requires positive dimensions and an even segment count in 4..512".into());
    }
    if segments as usize * 24 + 12 > budget {
        return Err("Vertex budget exceeded before arch allocation".into());
    }
    let a = width as f64 / 2.;
    let b = rise as f64;
    let t = thickness as f64;
    finite(&[(a + t) as f32, (b + t) as f32])?;
    let point = |i: u32, outer: bool, back: bool| -> V3 {
        let angle = std::f64::consts::PI * i as f64 / segments as f64;
        let (sin, cos) = if i == 0 {
            (0., 1.)
        } else if i == segments {
            (0., -1.)
        } else {
            angle.sin_cos()
        };
        let extra = if outer { t } else { 0. };
        [
            ((a + extra) * cos) as f32,
            ((b + extra) * sin) as f32,
            if back { depth / 2. } else { -depth / 2. },
        ]
    };
    let normal = |p: V3, outer: bool| {
        let extra = if outer { t } else { 0. };
        let x = p[0] as f64 / (a + extra).powi(2);
        let y = p[1] as f64 / (b + extra).powi(2);
        let length = x.hypot(y);
        let sign = if outer { 1. } else { -1. };
        [(sign * x / length) as f32, (sign * y / length) as f32, 0.]
    };
    // Normalized sampled arc length on the band's centerline. Shared ring
    // coordinates avoid per-triangle texture resets and angular stretching.
    let mut arc = vec![0_f64];
    for i in 0..segments {
        let center = |j| {
            let inner = point(j, false, false);
            let outer = point(j, true, false);
            [
                (inner[0] as f64 + outer[0] as f64) / 2.,
                (inner[1] as f64 + outer[1] as f64) / 2.,
            ]
        };
        let p = center(i);
        let q = center(i + 1);
        arc.push(arc.last().unwrap() + (q[0] - p[0]).hypot(q[1] - p[1]));
    }
    let total = *arc.last().unwrap();
    for i in 0..segments {
        let u0 = (arc[i as usize] / total) as f32;
        let u1 = (arc[i as usize + 1] / total) as f32;
        let inner = [
            point(i, false, false),
            point(i + 1, false, false),
            point(i + 1, false, true),
            point(i, false, true),
        ];
        let outer = [
            point(i, true, false),
            point(i + 1, true, false),
            point(i + 1, true, true),
            point(i, true, true),
        ];
        textured_quad(
            m,
            [inner[0], inner[1], outer[1], outer[0]],
            [[u0, 0.], [u1, 0.], [u1, 1.], [u0, 1.]],
        )?;
        textured_quad(
            m,
            [inner[3], outer[3], outer[2], inner[2]],
            [[u0, 0.], [u0, 1.], [u1, 1.], [u1, 0.]],
        )?;
        for (points, is_outer) in [
            (outer, true),
            ([inner[0], inner[3], inner[2], inner[1]], false),
        ] {
            let start = m.positions.len();
            let uv = if is_outer {
                [[u0, 0.], [u1, 0.], [u1, 1.], [u0, 1.]]
            } else {
                [[u0, 0.], [u0, 1.], [u1, 1.], [u1, 0.]]
            };
            textured_quad(m, points, uv)?;
            if m.positions.len() != start + 6 {
                return Err("Arch surface collapses at output precision".into());
            }
            for index in start..start + 6 {
                m.normals[index] = normal(m.positions[index], is_outer);
            }
        }
    }
    // Both feet terminate at y=0, with a downward-facing cap.
    textured_quad(
        m,
        [
            point(0, false, false),
            point(0, true, false),
            point(0, true, true),
            point(0, false, true),
        ],
        [[0., 0.], [1., 0.], [1., 1.], [0., 1.]],
    )?;
    textured_quad(
        m,
        [
            point(segments, false, false),
            point(segments, false, true),
            point(segments, true, true),
            point(segments, true, false),
        ],
        [[0., 0.], [1., 0.], [1., 1.], [0., 1.]],
    )?;
    if m.positions.len() != segments as usize * 24 + 12 {
        return Err("Arch band collapses at output precision".into());
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use crate::*;
    fn definition() -> Definition {
        Definition {
            shape: Shape::Arch {
                width: 4.,
                rise: 1.5,
                thickness: 0.3,
                depth: 0.6,
                segments: 24,
            },
            color: [1.; 4],
            material: MaterialSettings::default(),
        }
    }
    #[test]
    fn band_uvs_are_continuous_and_follow_arc_length() {
        let m = mesh("uv", &definition(), 1000).unwrap();
        assert!(m
            .uvs
            .iter()
            .flatten()
            .all(|v| v.is_finite() && (0. ..=1.).contains(v)));
        assert_eq!(m.uvs[0][0], 0.);
        assert_eq!(m.uvs[23 * 24 + 1][0], 1.);
        for i in 0..23 {
            // Every surface band reuses the adjacent segment's U coordinate.
            for face in 0..4 {
                let current = &m.uvs[i * 24 + face * 6..i * 24 + face * 6 + 6];
                let next = &m.uvs[(i + 1) * 24 + face * 6..(i + 1) * 24 + face * 6 + 6];
                let end = current.iter().map(|uv| uv[0]).fold(0., f32::max);
                let start = next.iter().map(|uv| uv[0]).fold(1., f32::min);
                assert_eq!(end, start);
            }
        }
        // Elliptical arc length is deliberately not uniform angular spacing.
        assert!((m.uvs[1][0] - 1. / 24.).abs() > 0.001);
    }
    #[test]
    fn invalid_arches_are_rejected() {
        for (width, rise, thickness, depth, segments) in [
            (0., 1., 0.2, 0.5, 24),
            (4., -1., 0.2, 0.5, 24),
            (4., 1., 0., 0.5, 24),
            (4., 1., 0.2, f32::NAN, 24),
            (4., 1., 0.2, 0.5, 3),
            (4., 1., 0.2, 0.5, 25),
            (4., 1., 0.2, 0.5, 514),
        ] {
            let mut d = definition();
            d.shape = Shape::Arch {
                width,
                rise,
                thickness,
                depth,
                segments,
            };
            assert!(mesh("invalid", &d, 100_000).is_err());
        }
    }
    #[test]
    fn arch_has_open_center_closed_surface_and_smooth_curve() {
        let m = mesh("arch", &definition(), 1000).unwrap();
        assert_eq!(m.positions.len(), 588);
        assert_eq!(m.bounds.min, [-2.3, 0., -0.3]);
        assert_eq!(m.bounds.max, [2.3, 1.8, 0.3]);
        let key = |p: V3| p.map(|v| if v == 0. { 0 } else { v.to_bits() });
        let mut edges = std::collections::BTreeMap::new();
        for (triangle, normals) in m
            .positions
            .as_chunks::<3>()
            .0
            .iter()
            .zip(m.normals.as_chunks::<3>().0)
        {
            let u: [f64; 3] =
                std::array::from_fn(|i| triangle[1][i] as f64 - triangle[0][i] as f64);
            let v: [f64; 3] =
                std::array::from_fn(|i| triangle[2][i] as f64 - triangle[0][i] as f64);
            let face = [
                u[1] * v[2] - u[2] * v[1],
                u[2] * v[0] - u[0] * v[2],
                u[0] * v[1] - u[1] * v[0],
            ];
            for n in normals {
                assert!((n.iter().map(|x| x * x).sum::<f32>() - 1.).abs() < 1e-5);
                assert!((0..3).map(|i| face[i] * n[i] as f64).sum::<f64>() > 0.);
            }
            for (a, b) in [(0, 1), (1, 2), (2, 0)] {
                let mut edge = [key(triangle[a]), key(triangle[b])];
                edge.sort();
                *edges.entry(edge).or_insert(0) += 1;
            }
        }
        assert!(edges.values().all(|count| *count == 2));
        // No vertex occupies the central clear opening (the arch is a band).
        assert!(m
            .positions
            .iter()
            .all(|p| (p[0] / 2.).powi(2) + (p[1] / 1.5).powi(2) >= 0.99999));
        assert!(mesh("budget", &definition(), 587)
            .unwrap_err()
            .contains("before arch allocation"));
    }
}
