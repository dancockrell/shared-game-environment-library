//! Elliptical structural band; clear opening dimensions, no filled-in doorway.
use crate::{finite, quad, Mesh, Result, V3};

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
    for i in 0..segments {
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
        quad(m, inner[0], inner[1], outer[1], outer[0])?;
        quad(m, inner[3], outer[3], outer[2], inner[2])?;
        for (points, is_outer) in [
            (outer, true),
            ([inner[0], inner[3], inner[2], inner[1]], false),
        ] {
            let start = m.positions.len();
            quad(m, points[0], points[1], points[2], points[3])?;
            if m.positions.len() != start + 6 {
                return Err("Arch surface collapses at output precision".into());
            }
            for index in start..start + 6 {
                m.normals[index] = normal(m.positions[index], is_outer);
            }
        }
    }
    // Both feet terminate at y=0, with a downward-facing cap.
    quad(
        m,
        point(0, false, false),
        point(0, true, false),
        point(0, true, true),
        point(0, false, true),
    )?;
    quad(
        m,
        point(segments, false, false),
        point(segments, false, true),
        point(segments, true, true),
        point(segments, true, false),
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
