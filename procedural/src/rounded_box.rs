//! Rounded stock with exact outer dimensions and analytic surface normals.
//! Project a boundary-aligned box grid onto a box dilated by a sphere.
use crate::{finite, triangle, Mesh, Result, V3};

pub(super) fn build(
    mesh: &mut Mesh,
    size: V3,
    radius: f32,
    segments: u32,
    max_vertices: usize,
) -> Result<()> {
    finite(&size)?;
    finite(&[radius])?;
    if !(1..=32).contains(&segments) || radius <= 0. || size.iter().any(|s| *s <= 2. * radius) {
        return Err(
            "Rounded box requires 1..32 segments and 0 < radius < half every dimension".into(),
        );
    }
    let cells = 2 * segments as usize + 1;
    let vertices = 36 * cells * cells;
    if vertices > max_vertices {
        return Err("Vertex budget exceeded before rounded box allocation".into());
    }
    let half = size.map(|s| s as f64 / 2.);
    let r = radius as f64;
    let core = half.map(|h| h - r);
    let axes: [Vec<f64>; 3] = std::array::from_fn(|axis| {
        let mut values = Vec::with_capacity(cells + 1);
        for i in 0..=segments {
            values.push(-half[axis] + r * i as f64 / segments as f64);
        }
        for i in 0..=segments {
            values.push(core[axis] + r * i as f64 / segments as f64);
        }
        values
    });
    for axis in 0..3 {
        let u = (axis + 1) % 3;
        let v = (axis + 2) % 3;
        for sign in [-1., 1.] {
            let sample = |i: usize, j: usize| -> (V3, V3, [f32; 2]) {
                let mut p = [0.; 3];
                p[axis] = sign * half[axis];
                p[u] = axes[u][i];
                p[v] = axes[v][j];
                let closest: [f64; 3] = std::array::from_fn(|k| p[k].clamp(-core[k], core[k]));
                let delta: [f64; 3] = std::array::from_fn(|k| p[k] - closest[k]);
                let length = delta.iter().map(|x| x * x).sum::<f64>().sqrt();
                let normal = delta.map(|x| x / length);
                (
                    std::array::from_fn(|k| (closest[k] + r * normal[k]) as f32),
                    normal.map(|x| x as f32),
                    [
                        (p[u] / size[u] as f64 + 0.5) as f32,
                        (p[v] / size[v] as f64 + 0.5) as f32,
                    ],
                )
            };
            for i in 0..cells {
                for j in 0..cells {
                    let corners = [
                        sample(i, j),
                        sample(i + 1, j),
                        sample(i + 1, j + 1),
                        sample(i, j + 1),
                    ];
                    let faces = if sign > 0. {
                        [[0, 1, 2], [0, 2, 3]]
                    } else {
                        [[0, 2, 1], [0, 3, 2]]
                    };
                    for face in faces {
                        let start = mesh.positions.len();
                        triangle(
                            mesh,
                            corners[face[0]].0,
                            corners[face[1]].0,
                            corners[face[2]].0,
                        )?;
                        if mesh.positions.len() != start + 3 {
                            return Err("Rounded box surface collapses at output precision".into());
                        }
                        for (offset, corner) in face.iter().enumerate() {
                            mesh.normals[start + offset] = corners[*corner].1;
                            mesh.uvs[start + offset] = corners[*corner].2;
                        }
                    }
                }
            }
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use crate::{mesh, Definition, Shape};
    use std::collections::BTreeMap;
    fn definition(size: [f32; 3], radius: f32, segments: u32) -> Definition {
        Definition {
            shape: Shape::RoundedBox {
                size,
                radius,
                segments,
            },
            color: [1.; 4],
        }
    }
    #[test]
    fn bounded_closed_and_smooth() {
        for segments in [1, 3, 8, 32] {
            let size = [4., 2., 3.];
            let m = mesh("rounded", &definition(size, 0.25, segments), 200_000).unwrap();
            assert_eq!(m.positions.len(), 36 * (2 * segments as usize + 1).pow(2));
            let mut edges = BTreeMap::new();
            let key = |p: [f32; 3]| p.map(|x| if x == 0. { 0 } else { x.to_bits() });
            for (p, n) in m.positions.iter().zip(&m.normals) {
                assert!((n.iter().map(|x| x * x).sum::<f32>() - 1.).abs() < 1e-5);
                assert!(p.iter().zip(n).map(|(x, y)| x * y).sum::<f32>() > 0.);
                for k in 0..3 {
                    assert!(p[k].abs() <= size[k] / 2.);
                }
                let distance = (0..3)
                    .map(|k| (p[k].abs() - (size[k] / 2. - 0.25)).max(0.).powi(2))
                    .sum::<f32>()
                    .sqrt();
                assert!((distance - 0.25).abs() < 1e-6);
            }
            for t in m.positions.as_chunks::<3>().0 {
                let a: [f64; 3] = std::array::from_fn(|k| t[1][k] as f64 - t[0][k] as f64);
                let b: [f64; 3] = std::array::from_fn(|k| t[2][k] as f64 - t[0][k] as f64);
                let n = [
                    a[1] * b[2] - a[2] * b[1],
                    a[2] * b[0] - a[0] * b[2],
                    a[0] * b[1] - a[1] * b[0],
                ];
                assert!((0..3).map(|k| n[k] * t[0][k] as f64).sum::<f64>() > 0.);
                for (a, b) in [(0, 1), (1, 2), (2, 0)] {
                    let mut pair = [key(t[a]), key(t[b])];
                    pair.sort();
                    *edges.entry(pair).or_insert(0) += 1;
                }
            }
            assert!(
                edges.values().all(|count| *count == 2),
                "Unmatched surface seam"
            );
            for k in 0..3 {
                assert_eq!(
                    m.positions
                        .iter()
                        .map(|p| p[k])
                        .fold(f32::NEG_INFINITY, f32::max),
                    size[k] / 2.
                );
                assert_eq!(
                    m.positions
                        .iter()
                        .map(|p| p[k])
                        .fold(f32::INFINITY, f32::min),
                    -size[k] / 2.
                );
            }
        }
    }
    #[test]
    fn fixture_reuses_geometry_and_serializes_deterministically() {
        let text = include_str!("../examples/rounded-stock.json");
        let recipe: crate::Recipe = serde_json::from_str(text).unwrap();
        let scene = crate::compile(&recipe).unwrap();
        assert_eq!(scene.meshes.len(), 6);
        assert_eq!(scene.instances.len(), 12);
        assert_eq!(
            crate::compile_json(text).unwrap(),
            crate::compile_json(text).unwrap()
        );
    }
    #[test]
    fn invalid_and_over_budget_are_rejected() {
        for (radius, segments) in [
            (0., 4),
            (-1., 4),
            (1., 4),
            (0.1, 0),
            (0.1, 33),
            (f32::NAN, 4),
        ] {
            assert!(mesh("bad", &definition([2.; 3], radius, segments), 200_000).is_err());
        }
        assert!(mesh("budget", &definition([2.; 3], 0.1, 8), 100)
            .unwrap_err()
            .contains("before rounded box allocation"));
    }
}
