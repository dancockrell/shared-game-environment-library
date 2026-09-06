//! Cubic section sweeps, using Wang et al.'s double-reflection frame transport.
//! Author report: https://www.cs.hku.hk/data/techreps/document/TR-2007-07.pdf
//! Original implementation; no third-party code. Open bores have annular ends.
use crate::{finite, triangle, Mesh, Result, V3};
use serde::{Deserialize, Serialize};
type D3 = [f64; 3];

/// Each cubic control point is [x,y,z,radius], in metres. Consecutive spans
/// share an endpoint and tangent direction. Tolerance bounds control-hull
/// deviation in position/radius, NOT the complete tessellated surface error.
#[derive(Clone, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct Sweep {
    pub spans: Vec<[[f32; 4]; 4]>,
    pub tolerance: f32,
    pub sides: u32,
    #[serde(default)]
    pub wall_thickness: f32,
}
fn sub(a: D3, b: D3) -> D3 {
    std::array::from_fn(|i| a[i] - b[i])
}
fn add(a: D3, b: D3) -> D3 {
    std::array::from_fn(|i| a[i] + b[i])
}
fn mul(a: D3, s: f64) -> D3 {
    a.map(|x| x * s)
}
fn dot(a: D3, b: D3) -> f64 {
    (0..3).map(|i| a[i] * b[i]).sum()
}
fn cross(a: D3, b: D3) -> D3 {
    [
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
    ]
}
fn unit(a: D3) -> Result<D3> {
    let l = dot(a, a).sqrt();
    if !l.is_finite() || l <= 1e-15 {
        return Err("Sweep has a zero tangent or collapsed frame".into());
    }
    Ok(mul(a, 1. / l))
}
fn reflect(a: D3, v: D3) -> Result<D3> {
    let q = dot(v, v);
    if q <= 1e-24 {
        return Err("Sweep frame reflection degenerates; refine or revise the curve".into());
    }
    Ok(sub(a, mul(v, 2. * dot(a, v) / q)))
}
fn transport(p: D3, next: D3, tangent: D3, next_tangent: D3, normal: D3) -> Result<D3> {
    let chord = sub(next, p);
    let reflected_tangent = reflect(tangent, chord)?;
    let reflected_normal = reflect(normal, chord)?;
    let n = reflect(reflected_normal, sub(next_tangent, reflected_tangent))?;
    // Remove roundoff drift; this is not a fallback for a degenerate reflection.
    unit(sub(n, mul(next_tangent, dot(n, next_tangent))))
}
#[derive(Clone)]
struct Sample {
    p: D3,
    t: D3,
    r: f64,
    dr_ds: f64,
}
fn evaluate(c: &[[f64; 4]; 4], u: f64) -> Result<Sample> {
    let v = 1. - u;
    let point: [f64; 4] = std::array::from_fn(|i| {
        v * v * v * c[0][i]
            + 3. * v * v * u * c[1][i]
            + 3. * v * u * u * c[2][i]
            + u * u * u * c[3][i]
    });
    let d: [f64; 4] = std::array::from_fn(|i| {
        3. * (v * v * (c[1][i] - c[0][i])
            + 2. * v * u * (c[2][i] - c[1][i])
            + u * u * (c[3][i] - c[2][i]))
    });
    let dp = [d[0], d[1], d[2]];
    Ok(Sample {
        p: [point[0], point[1], point[2]],
        t: unit(dp)?,
        r: point[3],
        dr_ds: d[3] / dot(dp, dp).sqrt(),
    })
}
fn split(c: [[f64; 4]; 4]) -> ([[f64; 4]; 4], [[f64; 4]; 4]) {
    let mid = |a: [f64; 4], b: [f64; 4]| std::array::from_fn(|i| (a[i] + b[i]) * 0.5);
    let a = mid(c[0], c[1]);
    let b = mid(c[1], c[2]);
    let d = mid(c[2], c[3]);
    let e = mid(a, b);
    let f = mid(b, d);
    let g = mid(e, f);
    ([c[0], a, e, g], [g, f, d, c[3]])
}
fn sample_span(
    c: [[f64; 4]; 4],
    tolerance: f64,
    depth: u32,
    result: &mut Vec<Sample>,
    cap: usize,
) -> Result<()> {
    let start = evaluate(&c, 0.)?;
    let end = evaluate(&c, 1.)?;
    let chord: [f64; 4] = std::array::from_fn(|i| c[3][i] - c[0][i]);
    let length2: f64 = chord.iter().map(|x| x * x).sum();
    let mut deviation: f64 = 0.;
    for point in &c[1..3] {
        let fraction = if length2 > 0. {
            ((0..4).map(|i| (point[i] - c[0][i]) * chord[i]).sum::<f64>() / length2).clamp(0., 1.)
        } else {
            0.
        };
        deviation = deviation.max(
            (0..4)
                .map(|i| (point[i] - c[0][i] - fraction * chord[i]).powi(2))
                .sum::<f64>()
                .sqrt(),
        );
    }
    // Also keep normal interpolation within a small angle, including a
    // perfectly straight spine whose radius changes rapidly.
    let angular = dot(start.t, end.t) < 5_f64.to_radians().cos()
        || (start.dr_ds.atan() - end.dr_ds.atan()).abs() > 5_f64.to_radians();
    // Positive derivative projection on the chord throughout the control
    // hull proves the accepted segment has no stationary point/reversal.
    // Endpoint tangents alone can miss an interior cusp on a straight cubic.
    let direction = sub(end.p, start.p);
    let regular = c.windows(2).all(|p| {
        dot(
            [p[1][0] - p[0][0], p[1][1] - p[0][1], p[1][2] - p[0][2]],
            direction,
        ) > 0.
    });
    if deviation > tolerance || angular || !regular {
        if depth == 12 {
            return Err("Sweep sampling depth exceeded before meeting tolerance".into());
        }
        let (a, b) = split(c);
        sample_span(a, tolerance, depth + 1, result, cap)?;
        sample_span(b, tolerance, depth + 1, result, cap)?;
    } else {
        if result.len() >= cap {
            return Err("Vertex budget exceeded before sweep allocation".into());
        }
        result.push(end);
    }
    Ok(())
}
/// Share the cubic sampler with surfaces of revolution. The radius of a sweep
/// is unused here: x is the meridian radius and y the meridian height.
pub(super) fn sample_profile(profile: &[[[f32; 2]; 4]], tolerance: f32) -> Result<Vec<[f32; 2]>> {
    finite(&[tolerance])?;
    if tolerance <= 0. || profile.is_empty() || profile.len() > 64 {
        return Err("Lathe spline requires positive tolerance and 1..64 spans".into());
    }
    let mut samples: Vec<Sample> = Vec::new();
    for span in profile {
        for point in span {
            finite(point)?;
            if point[0] < 0. {
                return Err("Negative spline radius".into());
            }
        }
        let c = span.map(|p| [p[0] as f64, p[1] as f64, 0., 0.]);
        let first = evaluate(&c, 0.)?;
        if let Some(previous) = samples.last() {
            if previous.p != first.p {
                return Err("Lathe spline spans must share endpoints".into());
            }
        } else {
            samples.push(first);
        }
        sample_span(c, tolerance as f64, 0, &mut samples, 512)?;
    }
    Ok(samples
        .into_iter()
        .map(|s| [s.p[0] as f32, s.p[1] as f32])
        .collect())
}
pub(super) fn validate_meridian(profile: &[[f32; 2]]) -> Result<()> {
    let orient = |a: [f32; 2], b: [f32; 2], c: [f32; 2]| {
        (b[0] as f64 - a[0] as f64) * (c[1] as f64 - a[1] as f64)
            - (b[1] as f64 - a[1] as f64) * (c[0] as f64 - a[0] as f64)
    };
    for (i, a) in profile.windows(2).enumerate() {
        if a[0] == a[1] {
            continue;
        }
        for (j, b) in profile.windows(2).enumerate().skip(i + 2) {
            if b[0] == b[1] {
                continue;
            }
            if orient(a[0], a[1], b[0]) * orient(a[0], a[1], b[1]) < 0.
                && orient(b[0], b[1], a[0]) * orient(b[0], b[1], a[1]) < 0.
            {
                return Err("Lathe meridian crosses itself".into());
            }
            // Nonadjacent tangencies/overlaps are also non-manifold. Permit
            // only the explicit closing endpoint of a closed meridian.
            for (point, edge) in [(a[0], b), (a[1], b), (b[0], a), (b[1], a)] {
                let closure = i == 0
                    && j == profile.len() - 2
                    && point == profile[0]
                    && profile.first() == profile.last();
                if !closure
                    && orient(edge[0], edge[1], point) == 0.
                    && (0..2).all(|k| {
                        point[k] >= edge[0][k].min(edge[1][k])
                            && point[k] <= edge[0][k].max(edge[1][k])
                    })
                {
                    return Err("Lathe meridian touches or overlaps itself".into());
                }
            }
        }
    }
    Ok(())
}
impl Sweep {
    fn samples(&self, cap: usize) -> Result<Vec<Sample>> {
        finite(&[self.tolerance, self.wall_thickness])?;
        if self.spans.is_empty()
            || self.spans.len() > 64
            || !(8..=256).contains(&self.sides)
            || self.tolerance <= 0.
            || self.wall_thickness < 0.
        {
            return Err("Sweep requires 1..64 spans, 8..256 sides, positive tolerance and nonnegative wall thickness".into());
        }
        let mut result: Vec<Sample> = Vec::new();
        for span in &self.spans {
            for p in span {
                finite(p)?;
                if p[3] <= self.wall_thickness {
                    return Err("Sweep radii must exceed wall thickness and zero".into());
                }
            }
            let c = span.map(|p| p.map(|x| x as f64));
            let first = evaluate(&c, 0.)?;
            if let Some(previous) = result.last() {
                if previous.p != first.p
                    || previous.r != first.r
                    || dot(previous.t, first.t) < 1. - 1e-8
                    || (previous.dr_ds - first.dr_ds).abs() > 1e-6
                {
                    return Err(
                        "Sweep spans must meet with equal position, radius and tangent/slope"
                            .into(),
                    );
                }
            } else {
                result.push(first);
            }
            sample_span(c, self.tolerance as f64, 0, &mut result, cap)?;
        }
        Ok(result)
    }
    pub(super) fn build(&self, m: &mut Mesh, budget: usize) -> Result<()> {
        let hollow = self.wall_thickness > 0.;
        let sides = self.sides as usize;
        if sides == 0 {
            return Err("Sweep requires sides".into());
        }
        let per_ring = sides * 6 * if hollow { 2 } else { 1 };
        let ends = sides * if hollow { 12 } else { 6 };
        if budget < ends + per_ring {
            return Err("Vertex budget exceeded before sweep allocation".into());
        }
        let samples = self.samples(((budget - ends) / per_ring + 1).min(8192))?;
        let mut frames = Vec::with_capacity(samples.len());
        let t = samples[0].t;
        let axis = if t[0].abs() < 0.8 {
            [1., 0., 0.]
        } else {
            [0., 1., 0.]
        };
        let mut n = unit(sub(axis, mul(t, dot(axis, t))))?;
        frames.push(n);
        for pair in samples.windows(2) {
            n = transport(pair[0].p, pair[1].p, pair[0].t, pair[1].t, n)?;
            frames.push(n);
        }
        // First-order regularity guard: reject locally folded thick sweeps.
        // This is not a certificate against remote/global self-intersection.
        let mut distance = vec![0.];
        for pair in samples.windows(2) {
            let ds = dot(sub(pair[1].p, pair[0].p), sub(pair[1].p, pair[0].p)).sqrt();
            if ds <= 1e-12 {
                return Err("Sweep contains coincident sampled positions".into());
            }
            let curvature = dot(sub(pair[1].t, pair[0].t), sub(pair[1].t, pair[0].t)).sqrt() / ds;
            if curvature * pair[0].r.max(pair[1].r) >= 0.95 {
                return Err("Sweep radius exceeds local curvature clearance".into());
            }
            distance.push(distance.last().unwrap() + ds);
        }
        let total = *distance.last().unwrap();
        let mut rings = Vec::new();
        let mut normals = Vec::new();
        for (i, s) in samples.iter().enumerate() {
            let binormal = cross(s.t, frames[i]);
            let curvature = if i == 0 {
                mul(sub(samples[1].t, s.t), 1. / distance[1])
            } else if i + 1 == samples.len() {
                mul(
                    sub(s.t, samples[i - 1].t),
                    1. / (distance[i] - distance[i - 1]),
                )
            } else {
                mul(
                    sub(samples[i + 1].t, samples[i - 1].t),
                    1. / (distance[i + 1] - distance[i - 1]),
                )
            };
            for inner in 0..if hollow { 2 } else { 1 } {
                let radius = s.r - self.wall_thickness as f64 * inner as f64;
                let mut ring = Vec::new();
                let mut ns = Vec::new();
                for j in 0..sides {
                    let angle = std::f64::consts::TAU * j as f64 / sides as f64;
                    let radial = add(mul(frames[i], angle.cos()), mul(binormal, angle.sin()));
                    let p = add(s.p, mul(radial, radius)).map(|x| x as f32);
                    finite(&p)?;
                    ring.push(p);
                    // Surface-of-variable-radius correction; a radial-only
                    // normal is wrong on tapered spouts and icing tips.
                    let surface_normal = unit(sub(
                        mul(radial, 1. - radius * dot(curvature, radial)),
                        mul(s.t, s.dr_ds),
                    ))?;
                    ns.push(
                        mul(surface_normal, if inner == 0 { 1. } else { -1. }).map(|x| x as f32),
                    );
                }
                rings.push(ring);
                normals.push(ns);
            }
        }
        let stride = if hollow { 2 } else { 1 };
        for i in 0..samples.len() - 1 {
            for inner in 0..stride {
                for j in 0..sides {
                    let k = (j + 1) % sides;
                    let a = i * stride + inner;
                    let b = (i + 1) * stride + inner;
                    let mut points = [rings[a][j], rings[a][k], rings[b][k], rings[b][j]];
                    let mut ns = [normals[a][j], normals[a][k], normals[b][k], normals[b][j]];
                    let v0 = (distance[i] / total) as f32;
                    let v1 = (distance[i + 1] / total) as f32;
                    let mut uv = [
                        [j as f32 / sides as f32, v0],
                        [(j + 1) as f32 / sides as f32, v0],
                        [(j + 1) as f32 / sides as f32, v1],
                        [j as f32 / sides as f32, v1],
                    ];
                    if inner == 1 {
                        points.reverse();
                        ns.reverse();
                        uv.reverse();
                    }
                    for face in [[0, 1, 2], [0, 2, 3]] {
                        emit(
                            m,
                            face.map(|v| points[v]),
                            face.map(|v| ns[v]),
                            face.map(|v| uv[v]),
                        )?;
                    }
                }
            }
        }
        for end in [0, samples.len() - 1] {
            let outward = mul(samples[end].t, if end == 0 { -1. } else { 1. }).map(|x| x as f32);
            for j in 0..sides {
                let k = (j + 1) % sides;
                let a = end * stride;
                let mut points = if hollow {
                    [rings[a][j], rings[a][k], rings[a + 1][k], rings[a + 1][j]]
                } else {
                    [
                        samples[end].p.map(|x| x as f32),
                        rings[a][j],
                        rings[a][k],
                        samples[end].p.map(|x| x as f32),
                    ]
                };
                if end == 0 {
                    points.reverse();
                }
                if hollow {
                    for face in [[0, 1, 2], [0, 2, 3]] {
                        emit(
                            m,
                            face.map(|v| points[v]),
                            [outward; 3],
                            [[0., 0.], [1., 0.], [1., 1.]],
                        )?;
                    }
                } else {
                    let face = [0, 1, 2];
                    emit(
                        m,
                        face.map(|v| points[v]),
                        [outward; 3],
                        [[0.5, 0.5], [0., 0.], [1., 0.]],
                    )?;
                }
            }
        }
        Ok(())
    }
}
fn emit(m: &mut Mesh, p: [V3; 3], n: [V3; 3], uv: [[f32; 2]; 3]) -> Result<()> {
    let start = m.positions.len();
    triangle(m, p[0], p[1], p[2])?;
    if m.positions.len() != start + 3 {
        return Err("Sweep triangle collapses at output precision".into());
    }
    m.normals[start..start + 3].copy_from_slice(&n);
    m.uvs[start..start + 3].copy_from_slice(&uv);
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{mesh, Definition, MaterialSettings, Shape};
    fn fixture(hollow: bool) -> Definition {
        Definition {
            color: [0.3, 0.5, 0.6, 1.],
            material: MaterialSettings::default(),
            shape: Shape::Sweep {
                sweep: Sweep {
                    spans: vec![[
                        [0., 0., 0., 0.2],
                        [0., 1., 0., 0.2],
                        [0., 2., 0., 0.2],
                        [0., 3., 0., 0.2],
                    ]],
                    tolerance: 0.001,
                    sides: 32,
                    wall_thickness: if hollow { 0.04 } else { 0. },
                },
            },
        }
    }
    #[test]
    fn straight_solid_and_hollow_are_closed_and_outward() {
        for hollow in [false, true] {
            let m = mesh("tube", &fixture(hollow), 100000).unwrap();
            let mut edges = std::collections::BTreeMap::new();
            for (p, ns) in m
                .positions
                .as_chunks::<3>()
                .0
                .iter()
                .zip(m.normals.as_chunks::<3>().0)
            {
                let face = cross(
                    sub(p[1].map(f64::from), p[0].map(f64::from)),
                    sub(p[2].map(f64::from), p[0].map(f64::from)),
                );
                for n in ns {
                    assert!(dot(face, n.map(f64::from)) > 0.);
                    assert!((dot(n.map(f64::from), n.map(f64::from)) - 1.).abs() < 1e-6);
                }
                for (a, b) in [(0, 1), (1, 2), (2, 0)] {
                    let key = |v: V3| v.map(|x| if x == 0. { 0 } else { x.to_bits() });
                    let mut edge = [key(p[a]), key(p[b])];
                    edge.sort();
                    *edges.entry(edge).or_insert(0) += 1;
                }
            }
            assert!(edges.values().all(|n| *n == 2));
            if hollow {
                assert!(m.positions.iter().all(|p| p[0].hypot(p[2]) > 0.159));
            }
        }
    }
    #[test]
    fn double_reflection_is_reversible_and_orthogonal() {
        let p = [0., 0., 0.];
        let q = [1., 2., 0.4];
        let t = unit([1., 1., 0.]).unwrap();
        let u = unit([0.5, 1., 0.2]).unwrap();
        let n = [0., 0., 1.];
        let next = transport(p, q, t, u, n).unwrap();
        assert!(dot(next, u).abs() < 1e-12);
        let back = transport(q, p, u, t, next).unwrap();
        assert!(dot(sub(back, n), sub(back, n)) < 1e-24);
        assert!(transport(p, p, t, t, n).is_err());
    }
    #[test]
    fn budget_and_invalid_radius_rejected() {
        assert!(mesh("budget", &fixture(true), 10).is_err());
        let mut d = fixture(true);
        let Shape::Sweep { sweep } = &mut d.shape else {
            unreachable!()
        };
        sweep.wall_thickness = 0.3;
        assert!(mesh("wall", &d, 100000).is_err());
    }
    #[test]
    fn cusp_and_disconnected_spans_fail_without_unbounded_work() {
        let mut d = fixture(false);
        let Shape::Sweep { sweep } = &mut d.shape else {
            unreachable!()
        };
        sweep.spans[0] = [
            [0., 0., 0., 0.02],
            [1., 0., 0., 0.02],
            [-1., 0., 0., 0.02],
            [0.1, 0., 0., 0.02],
        ];
        assert!(mesh("interior-reversal", &d, 100000).is_err());
        let mut d = fixture(false);
        let Shape::Sweep { sweep } = &mut d.shape else {
            unreachable!()
        };
        sweep.spans.push(sweep.spans[0]);
        assert!(mesh("disconnected", &d, 100000)
            .unwrap_err()
            .contains("must meet"));
    }
    #[test]
    fn curved_hero_parts_have_consistent_faces_and_deterministic_output() {
        let recipe: crate::Recipe =
            serde_json::from_str(include_str!("../examples/teapot.json")).unwrap();
        for name in ["teapot.handle", "teapot.spout"] {
            let d = &recipe.definitions[name];
            let m = mesh(name, d, 100000).unwrap();
            assert_eq!(
                serde_json::to_vec(&m).unwrap(),
                serde_json::to_vec(&mesh(name, d, 100000).unwrap()).unwrap()
            );
            for (p, ns) in m
                .positions
                .as_chunks::<3>()
                .0
                .iter()
                .zip(m.normals.as_chunks::<3>().0)
            {
                let face = cross(
                    sub(p[1].map(f64::from), p[0].map(f64::from)),
                    sub(p[2].map(f64::from), p[0].map(f64::from)),
                );
                assert!(ns.iter().all(|n| dot(face, n.map(f64::from)) > 0.));
            }
        }
    }
    #[test]
    fn hollow_meridian_and_invalid_crossings() {
        assert!(
            validate_meridian(&[[0., 0.], [2., 0.], [2., 3.], [1., 3.], [1., 1.], [0., 1.]])
                .is_ok()
        );
        assert!(validate_meridian(&[[0., 0.], [2., 2.], [2., 0.], [0., 2.]]).is_err());
        assert!(validate_meridian(&[[0., 0.], [2., 0.], [2., 1.], [1., 0.]]).is_err());
        let d = Definition {
            color: [1.; 4],
            material: MaterialSettings::default(),
            shape: Shape::Lathe {
                profile: vec![[0., 0.], [2., 0.], [2., 3.], [1., 3.], [1., 1.], [0., 1.]],
                segments: 32,
                smooth: true,
                crease_angle: 45.,
            },
        };
        let m = mesh("hollow", &d, 10000).unwrap();
        assert!(m
            .positions
            .iter()
            .zip(&m.normals)
            .any(
                |(p, n)| (p[0].hypot(p[2]) - 1.).abs() < 1e-5 && p[0] * n[0] + p[2] * n[2] < -0.99
            ));
    }
}
