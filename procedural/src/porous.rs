//! Bounded porous solid coupon. Original field/extraction code; no neural model.
//! Seeded cell-local cavities follow the researched spatial-particle principle.
use crate::{finite, triangle, Mesh, Result, V3};
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;

#[derive(Clone, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct PorousBox {
    pub size: V3,
    pub spacing: f32,
    pub radii: [f32; 2],
    pub step: f32,
    pub seed: u32,
    /// Explicit level-set offset in metres, bounded to one tenth of a grid step.
    #[serde(default)]
    pub surface_offset: f32,
}
fn random(state: &mut u32) -> f64 {
    *state ^= *state >> 16;
    *state = state.wrapping_mul(0x7feb352d);
    *state ^= *state >> 15;
    *state = state.wrapping_mul(0x846ca68b);
    *state ^= *state >> 16;
    *state = state.wrapping_add(0x9e3779b9);
    *state as f64 / 4294967296.
}
impl PorousBox {
    fn validate(&self) -> Result<()> {
        finite(&self.size)?;
        finite(&[self.spacing, self.step, self.radii[0], self.radii[1]])?;
        finite(&[self.surface_offset])?;
        if self.size.iter().any(|x| *x < 0.001)
            || self.step < 0.00001
            || self.spacing < 0.0001
            || self.surface_offset.abs() > self.step * 0.1
            || self.radii[0] < self.step * 2.
            || self.radii[1] < self.radii[0]
            || self.radii[1] > self.spacing * 0.45
            || self.size.iter().any(|x| *x / self.spacing > 10000.)
        {
            return Err(
                "Invalid porous dimensions: radius needs >=2 steps and <=0.45 spacing".into(),
            );
        }
        Ok(())
    }
    fn particle(&self, cell: [i32; 3]) -> ([f64; 3], f64) {
        let mut state = self.seed
            ^ (cell[0] as u32).wrapping_mul(0x8da6b343)
            ^ (cell[1] as u32).wrapping_mul(0xd8163841)
            ^ (cell[2] as u32).wrapping_mul(0xcb1ab31f);
        let center = std::array::from_fn(|i| {
            (cell[i] as f64 + 0.1 + 0.8 * random(&mut state)) * self.spacing as f64
        });
        let radius =
            self.radii[0] as f64 + (self.radii[1] - self.radii[0]) as f64 * random(&mut state);
        (center, radius)
    }
    fn pores(&self, p: [f64; 3], reach: i32) -> f64 {
        let q = p.map(|x| (x / self.spacing as f64).floor() as i32);
        // Beyond the 27 cells, distance is >= spacing - max_radius > spacing/2.
        // Truncation makes this a local signed field, not an unlimited true SDF.
        let mut distance = self.spacing as f64 * 0.5;
        for z in -reach..=reach {
            for y in -reach..=reach {
                for x in -reach..=reach {
                    let (c, r) = self.particle([q[0] + x, q[1] + y, q[2] + z]);
                    distance =
                        distance.min((0..3).map(|i| (p[i] - c[i]).powi(2)).sum::<f64>().sqrt() - r);
                }
            }
        }
        distance
    }
    fn field(&self, p: [f64; 3]) -> f64 {
        let q: [f64; 3] = std::array::from_fn(|i| p[i].abs() - self.size[i] as f64 * 0.5);
        let host = q.map(|x| x.max(0.).powi(2)).iter().sum::<f64>().sqrt()
            + q[0].max(q[1]).max(q[2]).min(0.);
        host.max(-self.pores(p, 1)) - self.surface_offset as f64
    }
    fn normal(&self, p: [f64; 3]) -> V3 {
        let h = self.step as f64 * 0.02;
        let g: [f64; 3] = std::array::from_fn(|i| {
            let mut a = p;
            let mut b = p;
            a[i] += h;
            b[i] -= h;
            self.field(a) - self.field(b)
        });
        let length = g.iter().map(|x| x * x).sum::<f64>().sqrt();
        if length <= 1e-20 {
            return [0.; 3];
        }
        g.map(|x| (x / length) as f32)
    }
    pub(crate) fn build(&self, mesh: &mut Mesh, budget: usize) -> Result<()> {
        self.validate()?;
        let cells: [usize; 3] = self
            .size
            .map(|s| (s as f64 / self.step as f64).ceil() as usize + 2);
        let dims = cells.map(|n| n + 1);
        let samples = dims
            .iter()
            .try_fold(1usize, |a, b| a.checked_mul(*b))
            .ok_or("Porous grid overflow")?;
        if samples > 262144 {
            return Err("Porous grid exceeds 262144 samples".into());
        }
        let id = |x: usize, y: usize, z: usize| (z * dims[1] + y) * dims[0] + x;
        let mut points = Vec::with_capacity(samples);
        let mut values = Vec::with_capacity(samples);
        for z in 0..dims[2] {
            for y in 0..dims[1] {
                for x in 0..dims[0] {
                    let ijk = [x, y, z];
                    let p = std::array::from_fn(|i| {
                        let half = self.size[i] as f64 * 0.5;
                        if ijk[i] == 0 {
                            -half - self.step as f64
                        } else if ijk[i] == cells[i] {
                            half + self.step as f64
                        } else if ijk[i] == cells[i] - 1 {
                            half
                        } else {
                            -half
                                + (ijk[i] - 1) as f64 * self.size[i] as f64 / (cells[i] - 2) as f64
                        }
                    });
                    points.push(p);
                    values.push(self.field(p));
                }
            }
        }
        // Six tetrahedra around the shared 0->7 cube diagonal. Opposite cube
        // faces use matching diagonals, including between neighboring cells.
        let tets = [
            [0, 1, 3, 7],
            [0, 3, 2, 7],
            [0, 2, 6, 7],
            [0, 6, 4, 7],
            [0, 4, 5, 7],
            [0, 5, 1, 7],
        ];
        let mut intersections = BTreeMap::<(usize, usize), (V3, V3)>::new();
        for z in 0..cells[2] {
            for y in 0..cells[1] {
                for x in 0..cells[0] {
                    let cube: [usize; 8] = std::array::from_fn(|i| {
                        id(x + (i & 1), y + ((i >> 1) & 1), z + ((i >> 2) & 1))
                    });
                    for tet in tets {
                        let mut inside = Vec::with_capacity(4);
                        let mut outside = Vec::with_capacity(4);
                        for local in tet {
                            let v = cube[local];
                            if values[v] < 0. {
                                inside.push(v);
                            } else {
                                outside.push(v);
                            }
                        }
                        if inside.is_empty() || outside.is_empty() {
                            continue;
                        }
                        let mut crossing = |a: usize, b: usize| -> (V3, V3) {
                            let (a, b) = if a < b { (a, b) } else { (b, a) };
                            *intersections.entry((a, b)).or_insert_with(|| {
                                let t = values[a] / (values[a] - values[b]);
                                let p = if values[a] == 0. {
                                    points[a]
                                } else if values[b] == 0. {
                                    points[b]
                                } else {
                                    std::array::from_fn(|i| {
                                        points[a][i] + t * (points[b][i] - points[a][i])
                                    })
                                };
                                (p.map(|x| x as f32), self.normal(p))
                            })
                        };
                        let tris = if inside.len() == 1 {
                            vec![[
                                crossing(inside[0], outside[0]),
                                crossing(inside[0], outside[1]),
                                crossing(inside[0], outside[2]),
                            ]]
                        } else if outside.len() == 1 {
                            vec![[
                                crossing(outside[0], inside[0]),
                                crossing(outside[0], inside[1]),
                                crossing(outside[0], inside[2]),
                            ]]
                        } else {
                            let a = crossing(inside[0], outside[0]);
                            let b = crossing(inside[0], outside[1]);
                            let c = crossing(inside[1], outside[1]);
                            let d = crossing(inside[1], outside[0]);
                            vec![[a, b, c], [a, c, d]]
                        };
                        for mut tri in tris {
                            if mesh.positions.len() + 3 > budget {
                                return Err("Porous vertex budget exceeded".into());
                            }
                            let a: V3 = std::array::from_fn(|i| tri[1].0[i] - tri[0].0[i]);
                            let b: V3 = std::array::from_fn(|i| tri[2].0[i] - tri[0].0[i]);
                            let cross = [
                                a[1] * b[2] - a[2] * b[1],
                                a[2] * b[0] - a[0] * b[2],
                                a[0] * b[1] - a[1] * b[0],
                            ];
                            let direction: V3 = std::array::from_fn(|i| {
                                (points[outside[0]][i] - points[inside[0]][i]) as f32
                            });
                            if (0..3).map(|i| cross[i] * direction[i]).sum::<f32>() < 0. {
                                tri.swap(1, 2);
                            }
                            let start = mesh.positions.len();
                            triangle(mesh, tri[0].0, tri[1].0, tri[2].0)?;
                            if mesh.positions.len() == start {
                                continue;
                            }
                            for (i, (p, n)) in tri.iter().enumerate() {
                                if *n != [0.; 3] {
                                    mesh.normals[start + i] = *n;
                                }
                                mesh.uvs[start + i] =
                                    [p[0] / self.size[0] + 0.5, p[1] / self.size[1] + 0.5];
                            }
                        }
                    }
                }
            }
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    fn sample() -> PorousBox {
        PorousBox {
            size: [0.05, 0.03, 0.02],
            spacing: 0.01,
            radii: [0.0025, 0.004],
            step: 0.001,
            seed: 19,
            surface_offset: 0.000001,
        }
    }
    #[test]
    fn grid_and_output_budgets_refuse_excess_work() {
        let build = |porous, budget| {
            crate::mesh(
                "budget",
                &crate::Definition {
                    shape: crate::Shape::PorousBox { porous },
                    color: [1.; 4],
                    material: crate::MaterialSettings::default(),
                },
                budget,
            )
        };
        let mut too_large = sample();
        too_large.size = [1.; 3];
        assert!(build(too_large, 1000000)
            .unwrap_err()
            .contains("grid exceeds"));
        assert!(build(sample(), 3).unwrap_err().contains("vertex budget"));
        let mut offset = sample();
        offset.surface_offset = offset.step;
        assert!(offset.validate().is_err());
    }
    #[test]
    fn local_cavities_match_bruteforce_and_have_stable_physical_scale() {
        let a = sample();
        a.validate().unwrap();
        let mut state = 15;
        for _ in 0..64 {
            let p = std::array::from_fn(|_| (random(&mut state) - 0.5) * 0.1);
            assert_eq!(a.pores(p, 1), a.pores(p, 3));
        }
        let (center, radius) = a.particle([-2, 1, 0]);
        assert!((a.pores(center, 1) + radius).abs() < 1e-12);
        assert_eq!(a.particle([-2, 1, 0]), a.particle([-2, 1, 0]));
        let mut b = a.clone();
        b.seed += 1;
        assert_ne!(a.particle([0; 3]), b.particle([0; 3]));
        assert!(a.field([1.; 3]) > 0.);
        let mut invalid = a;
        invalid.step = 0.002;
        assert!(invalid.validate().is_err());
    }
}
