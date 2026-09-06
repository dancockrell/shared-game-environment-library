//! Rectangular room construction: dimensions are clear interior dimensions.
//! Openings are supplied constraints, never inferred world-graph connections.
use crate::{finite, Result, V3};
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

impl Room {
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
        let mut result = vec![([w + 2. * t, *f, d + 2. * t], [0., -f / 2., 0.])];
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
                let centre = (a + b) / 2.;
                let y = (bottom + top) / 2.;
                let sign = if matches!(wall, Wall::North | Wall::West) {
                    -1.
                } else {
                    1.
                };
                let (size, position) = if horizontal {
                    ([b - a, top - bottom, *t], [centre, y, sign * (d + t) / 2.])
                } else {
                    ([*t, top - bottom, b - a], [sign * (w + t) / 2., y, centre])
                };
                result.push((size, position));
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
            .any(|(s, c)| (0..3).all(|i| (p[i] - c[i]).abs() < s[i] / 2.))
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
