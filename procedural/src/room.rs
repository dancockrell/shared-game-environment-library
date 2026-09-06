//! Rectangular room construction: dimensions are clear interior dimensions.
//! Openings are supplied constraints, never inferred world-graph connections.
use crate::{finite, quad, Mesh, Result, V3};
use serde::{Deserialize, Serialize};

#[derive(Clone, Copy, Debug, Deserialize, Serialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum Wall {
    North,
    East,
    South,
    West,
}

#[derive(Clone, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct Opening {
    pub wall: Wall,
    /// Centre along world X on north/south, world Z on east/west.
    pub offset: f32,
    pub width: f32,
    pub height: f32,
    /// Height above finished floor; zero for doors.
    #[serde(default)]
    pub sill: f32,
}

#[derive(Clone, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct Room {
    pub width: f32,
    pub depth: f32,
    pub height: f32,
    pub wall_thickness: f32,
    pub floor_thickness: f32,
    #[serde(default)]
    pub openings: Vec<Opening>,
}

/// Geometric aperture only. No game command or destination is inferred.
#[derive(Clone, Debug, Serialize)]
pub struct Aperture {
    pub opening_index: usize,
    pub wall: Wall,
    /// Bottom centre on the wall centre plane, not the interior wall face.
    pub position: V3,
    pub outward_normal: V3,
    pub width: f32,
    pub height: f32,
}

impl Room {
    pub(crate) fn apertures(&self) -> Vec<Aperture> {
        self.openings
            .iter()
            .enumerate()
            .map(|(opening_index, o)| {
                let x = (self.width + self.wall_thickness) / 2.;
                let z = (self.depth + self.wall_thickness) / 2.;
                let (position, outward_normal) = match o.wall {
                    Wall::North => ([o.offset, o.sill, -z], [0., 0., -1.]),
                    Wall::South => ([o.offset, o.sill, z], [0., 0., 1.]),
                    Wall::East => ([x, o.sill, o.offset], [1., 0., 0.]),
                    Wall::West => ([-x, o.sill, o.offset], [-1., 0., 0.]),
                };
                Aperture {
                    opening_index,
                    wall: o.wall,
                    position,
                    outward_normal,
                    width: o.width,
                    height: o.height,
                }
            })
            .collect()
    }
    /// Exact shared min/max construction coordinates, never centre/size reconstruction.
    pub(crate) fn boxes(&self) -> Result<Vec<(V3, V3)>> {
        let Self {
            width: w,
            depth: d,
            height: h,
            wall_thickness: t,
            floor_thickness: f,
            openings,
        } = self;
        finite(&[*w, *d, *h, *t, *f])?;
        if [*w, *d, *h, *t, *f].iter().any(|v| *v < 0.001)
            || *t >= w.min(*d) / 2.
            || openings.len() > 64
        {
            return Err("Invalid room dimensions or more than 64 openings".into());
        }
        for o in openings {
            finite(&[o.offset, o.width, o.height, o.sill])?;
            let length = match o.wall {
                Wall::North | Wall::South => *w,
                _ => *d,
            };
            if o.width < 0.001
                || o.height < 0.001
                || o.sill < 0.
                || o.sill + o.height > *h
                || o.offset - o.width / 2. < -length / 2.
                || o.offset + o.width / 2. > length / 2.
            {
                return Err("Opening lies outside clear wall bounds".into());
            }
        }
        let x0 = -w / 2. - t;
        let x1 = w / 2. + t;
        let z0 = -d / 2. - t;
        let z1 = d / 2. + t;
        let mut result = vec![([x0, -*f, z0], [x1, 0., z1])];
        for wall in [Wall::North, Wall::East, Wall::South, Wall::West] {
            let horizontal = matches!(wall, Wall::North | Wall::South);
            let length = if horizontal { *w } else { *d };
            let mut cuts: Vec<_> = openings.iter().filter(|o| o.wall == wall).collect();
            cuts.sort_by(|a, b| a.offset.total_cmp(&b.offset));
            let mut cursor = -length / 2.;
            // East/west own the corner columns; no overlapping solid volumes.
            let extent = if horizontal { 0. } else { *t };
            let mut segment = |a: f32, b: f32, bottom: f32, top: f32| {
                if b <= a || top <= bottom {
                    return;
                }
                let bounds = match wall {
                    Wall::North => ([a, bottom, z0], [b, top, -d / 2.]),
                    Wall::South => ([a, bottom, d / 2.], [b, top, z1]),
                    Wall::West => ([x0, bottom, a], [-w / 2., top, b]),
                    Wall::East => ([w / 2., bottom, a], [x1, top, b]),
                };
                result.push(bounds);
            };
            segment(cursor - extent, cursor, 0., *h);
            for o in cuts {
                let a = o.offset - o.width / 2.;
                let b = o.offset + o.width / 2.;
                if a < cursor {
                    return Err("Overlapping opening spans on a wall".into());
                }
                segment(cursor, a, 0., *h);
                segment(a, b, 0., o.sill);
                segment(a, b, o.sill + o.height, *h);
                cursor = b;
            }
            segment(cursor, length / 2. + extent, 0., *h);
        }
        Ok(result)
    }
    pub(crate) fn build(&self, mesh: &mut Mesh, budget: usize) -> Result<()> {
        let boxes = self.boxes()?;
        for (lo, hi) in &boxes {
            finite(lo)?;
            finite(hi)?;
            if (0..3).any(|axis| lo[axis] >= hi[axis]) {
                return Err("Room construction cell collapses at output precision".into());
            }
        }
        let mut cuts: [Vec<f32>; 3] = std::array::from_fn(|axis| {
            boxes
                .iter()
                .flat_map(|(lo, hi)| [lo[axis], hi[axis]])
                .collect()
        });
        for values in &mut cuts {
            values.sort_by(f32::total_cmp);
            values.dedup();
            finite(values)?;
        }
        let dims = cuts.each_ref().map(|c| c.len() - 1);
        let cells = dims
            .iter()
            .try_fold(1_usize, |a, b| a.checked_mul(*b))
            .ok_or("Room grid overflow")?;
        if cells > 262_144 {
            return Err("Room construction grid exceeds 262144 cells".into());
        }
        let index = |p: [usize; 3]| (p[0] * dims[1] + p[1]) * dims[2] + p[2];
        let mut occupied = vec![false; cells];
        for (lo, hi) in boxes {
            let a: [usize; 3] =
                std::array::from_fn(|i| cuts[i].iter().position(|x| *x == lo[i]).unwrap());
            let b: [usize; 3] =
                std::array::from_fn(|i| cuts[i].iter().position(|x| *x == hi[i]).unwrap());
            for x in a[0]..b[0] {
                for y in a[1]..b[1] {
                    for z in a[2]..b[2] {
                        occupied[index([x, y, z])] = true;
                    }
                }
            }
        }
        let exposed = |p: [usize; 3], axis: usize, high: bool| {
            if (high && p[axis] + 1 == dims[axis]) || (!high && p[axis] == 0) {
                return true;
            }
            let mut other = p;
            if high {
                other[axis] += 1;
            } else {
                other[axis] -= 1;
            }
            !occupied[index(other)]
        };
        // First count, then allocate triangles: subdivision cannot evade the budget.
        let mut faces = 0_usize;
        for x in 0..dims[0] {
            for y in 0..dims[1] {
                for z in 0..dims[2] {
                    let p = [x, y, z];
                    if occupied[index(p)] {
                        for axis in 0..3 {
                            for high in [false, true] {
                                if exposed(p, axis, high) {
                                    faces += 1;
                                }
                            }
                        }
                    }
                }
            }
        }
        if faces * 6 > budget {
            return Err("Vertex budget exceeded before room boundary allocation".into());
        }
        for x in 0..dims[0] {
            for y in 0..dims[1] {
                for z in 0..dims[2] {
                    let cell = [x, y, z];
                    if !occupied[index(cell)] {
                        continue;
                    }
                    for axis in 0..3 {
                        for high in [false, true] {
                            if !exposed(cell, axis, high) {
                                continue;
                            }
                            let u = (axis + 1) % 3;
                            let v = (axis + 2) % 3;
                            let mut points = [[0_f32; 3]; 4];
                            for (i, (du, dv)) in
                                [(0, 0), (1, 0), (1, 1), (0, 1)].into_iter().enumerate()
                            {
                                points[i][axis] = cuts[axis][cell[axis] + usize::from(high)];
                                points[i][u] = cuts[u][cell[u] + du];
                                points[i][v] = cuts[v][cell[v] + dv];
                            }
                            if !high {
                                points.reverse();
                            }
                            let before = mesh.positions.len();
                            quad(mesh, points[0], points[1], points[2], points[3])?;
                            if mesh.positions.len() != before + 6 {
                                return Err("Room boundary collapses at output precision".into());
                            }
                        }
                    }
                }
            }
        }
        mesh.apertures = self.apertures();
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    fn room() -> Room {
        Room {
            width: 10.,
            depth: 8.,
            height: 3.,
            wall_thickness: 0.3,
            floor_thickness: 0.2,
            openings: vec![
                Opening {
                    wall: Wall::South,
                    offset: 2.,
                    width: 2.,
                    height: 2.4,
                    sill: 0.,
                },
                Opening {
                    wall: Wall::East,
                    offset: -1.,
                    width: 1.5,
                    height: 1.,
                    sill: 1.,
                },
            ],
        }
    }
    fn occupied(boxes: &[(V3, V3)], p: V3) -> bool {
        boxes
            .iter()
            .any(|(lo, hi)| (0..3).all(|i| p[i] > lo[i] && p[i] < hi[i]))
    }
    #[test]
    fn actual_holes_and_correct_sides() {
        let b = room().boxes().unwrap();
        assert!(!occupied(&b, [2., 1., 4.15]));
        assert!(occupied(&b, [-2., 1., 4.15]));
        assert!(occupied(&b, [2., 2.8, 4.15]));
        assert!(occupied(&b, [2., 1., -4.15]));
        assert!(!occupied(&b, [5.15, 1.5, -1.]));
        assert!(occupied(&b, [5.15, 0.5, -1.]));
        assert!(occupied(&b, [5.15, 2.5, -1.]));
        assert!(!occupied(&b, [0., 1., 0.]));
        assert!(occupied(&b, [0., -0.1, 0.]));
    }
    #[test]
    fn invalid_openings_rejected() {
        let mut r = room();
        r.openings.push(r.openings[0].clone());
        assert!(r.boxes().unwrap_err().contains("Overlapping"));
        r = room();
        r.openings[0].offset = 5.;
        assert!(r.boxes().is_err());
        r = room();
        r.openings[0].height = 4.;
        assert!(r.boxes().is_err());
        r = room();
        r.openings[0].sill = -1.;
        assert!(r.boxes().is_err());
        r = room();
        r.width = f32::NAN;
        assert!(r.boxes().is_err());
    }
    #[test]
    fn boundary_preserves_material_volume_and_grid_is_bounded() {
        let build = |r: Room| {
            crate::mesh(
                "room",
                &crate::Definition {
                    shape: crate::Shape::Room { room: r },
                    color: [1.; 4],
                    material: crate::MaterialSettings::default(),
                },
                1_000_000,
            )
        };
        let r = room();
        let expected: f64 = r
            .boxes()
            .unwrap()
            .iter()
            .map(|(lo, hi)| (0..3).map(|i| hi[i] as f64 - lo[i] as f64).product::<f64>())
            .sum();
        let mesh = build(r).unwrap();
        let mut volume = 0.;
        for triangle in mesh.positions.as_chunks::<3>().0 {
            let [a, b, c] = [triangle[0], triangle[1], triangle[2]].map(|p| p.map(f64::from));
            volume += (a[0] * (b[1] * c[2] - b[2] * c[1])
                + a[1] * (b[2] * c[0] - b[0] * c[2])
                + a[2] * (b[0] * c[1] - b[1] * c[0]))
                / 6.;
        }
        assert!((volume - expected).abs() < 1e-8 * expected);
        let mut dense = room();
        dense.width = 20.;
        dense.depth = 20.;
        dense.openings = (0..64)
            .map(|i| Opening {
                wall: if i % 2 == 0 { Wall::South } else { Wall::East },
                offset: -7. + (i / 2) as f32 * 0.4,
                width: 0.15,
                height: 0.005,
                sill: 0.1 + i as f32 * 0.01,
            })
            .collect();
        assert!(build(dense).unwrap_err().contains("grid exceeds"));
        let mut thin = room();
        thin.width = 1_000_000.;
        thin.wall_thickness = 0.001;
        assert!(build(thin).unwrap_err().contains("output precision"));
    }
    #[test]
    fn all_four_sides_support_full_height_openings() {
        for wall in [Wall::North, Wall::East, Wall::South, Wall::West] {
            let mut r = room();
            r.openings = vec![Opening {
                wall,
                offset: 0.,
                width: 2.,
                height: 3.,
                sill: 0.,
            }];
            let p = match wall {
                Wall::North => [0., 1., -4.15],
                Wall::South => [0., 1., 4.15],
                Wall::East => [5.15, 1., 0.],
                Wall::West => [-5.15, 1., 0.],
            };
            assert!(!occupied(&r.boxes().unwrap(), p));
        }
    }
}
