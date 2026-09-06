//! Engine-neutral geometry and composition. No network, engine or GPU dependency.
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;
mod room;
pub use room::{Opening, Room, Wall};
pub type V3 = [f32; 3];
type Result<T> = std::result::Result<T, String>;
#[derive(Clone, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct Recipe {
    pub version: u32,
    pub definitions: BTreeMap<String, Definition>,
    pub root: Assembly,
    #[serde(default)]
    pub limits: Limits,
}
#[derive(Clone, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct Definition {
    pub shape: Shape,
    pub color: [f32; 4],
}
#[derive(Clone, Deserialize, Serialize)]
#[serde(tag = "kind", rename_all = "snake_case", deny_unknown_fields)]
pub enum Shape {
    Room {
        room: Room,
    },
    Box {
        size: V3,
    },
    Gable {
        width: f32,
        depth: f32,
        rise: f32,
    },
    Lathe {
        profile: Vec<[f32; 2]>,
        segments: u32,
    },
    Extrude {
        polygon: Vec<[f32; 2]>,
        height: f32,
    },
}
#[derive(Clone, Deserialize, Serialize)]
#[serde(tag = "kind", rename_all = "snake_case", deny_unknown_fields)]
pub enum Assembly {
    Part {
        mesh: String,
        #[serde(default)]
        position: V3,
        #[serde(default)]
        yaw: f32,
        #[serde(default = "one")]
        scale: f32,
    },
    Group {
        children: Vec<Assembly>,
    },
    Repeat {
        count: u32,
        step: V3,
        child: Box<Assembly>,
    },
}
fn one() -> f32 {
    1.0
}
#[derive(Clone, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct Limits {
    pub max_instances: usize,
    pub max_vertices: usize,
    pub gpu_geometry_bytes: u64,
}
impl Default for Limits {
    fn default() -> Self {
        Self {
            max_instances: 50_000,
            max_vertices: 1_000_000,
            gpu_geometry_bytes: 512 * 1024 * 1024,
        }
    }
}
#[derive(Clone, Debug, Serialize)]
pub struct Mesh {
    pub name: String,
    pub apertures: Vec<room::Aperture>,
    #[serde(serialize_with = "flat3")]
    pub positions: Vec<V3>,
    #[serde(serialize_with = "flat3")]
    pub normals: Vec<V3>,
    #[serde(serialize_with = "flat2")]
    pub uvs: Vec<[f32; 2]>,
    pub indices: Vec<u32>,
    pub color: [f32; 4],
}
fn flat3<S: serde::Serializer>(v: &[V3], s: S) -> std::result::Result<S::Ok, S::Error> {
    s.collect_seq(v.iter().flatten())
}
fn flat2<S: serde::Serializer>(v: &[[f32; 2]], s: S) -> std::result::Result<S::Ok, S::Error> {
    s.collect_seq(v.iter().flatten())
}
#[derive(Debug, Serialize)]
pub struct Instance {
    pub mesh: usize,
    pub position: V3,
    pub yaw: f32,
    pub scale: f32,
}
#[derive(Debug, Serialize)]
pub struct Scene {
    pub version: u32,
    pub coordinate_system: &'static str,
    pub meshes: Vec<Mesh>,
    pub instances: Vec<Instance>,
    pub estimated_geometry_bytes: u64,
}
fn finite(v: &[f32]) -> Result<()> {
    if v.iter().all(|x| x.is_finite() && x.abs() <= 1_000_000.0) {
        Ok(())
    } else {
        Err("Non-finite or excessive coordinate".into())
    }
}
fn triangle(m: &mut Mesh, a: V3, b: V3, c: V3) -> Result<()> {
    // Compute in f64: a world-unit area epsilon deletes valid thin faces,
    // while f32 squared cross products overflow for large legal dimensions.
    let u: [f64; 3] = std::array::from_fn(|i| b[i] as f64 - a[i] as f64);
    let v: [f64; 3] = std::array::from_fn(|i| c[i] as f64 - a[i] as f64);
    let n = [
        u[1] * v[2] - u[2] * v[1],
        u[2] * v[0] - u[0] * v[2],
        u[0] * v[1] - u[1] * v[0],
    ];
    let length = n.iter().map(|x| x * x).sum::<f64>().sqrt();
    // Exact degeneracies at lathe poles intentionally contribute no triangle.
    if length == 0. {
        return Ok(());
    }
    let normal = n.map(|x| (x / length) as f32);
    let start = u32::try_from(m.positions.len()).map_err(|_| "Index overflow")?;
    m.positions.extend([a, b, c]);
    m.normals.extend([normal; 3]);
    m.uvs.extend([[0., 0.], [1., 0.], [0., 1.]]);
    m.indices.extend([start, start + 1, start + 2]);
    Ok(())
}
fn quad(m: &mut Mesh, a: V3, b: V3, c: V3, d: V3) -> Result<()> {
    triangle(m, a, b, c)?;
    triangle(m, a, c, d)
}
fn mesh(name: &str, d: &Definition, max_vertices: usize) -> Result<Mesh> {
    finite(&d.color)?;
    if d.color.iter().any(|x| *x < 0. || *x > 1.) {
        return Err("Color outside 0..1".into());
    }
    let mut m = Mesh {
        name: name.into(),
        apertures: vec![],
        positions: vec![],
        normals: vec![],
        uvs: vec![],
        indices: vec![],
        color: d.color,
    };
    match &d.shape {
        Shape::Room { room } => {
            let boxes = room.boxes()?;
            m.apertures = room.apertures();
            if boxes.len() * 36 > max_vertices {
                return Err("Vertex budget exceeded before room allocation".into());
            }
            for (size, position) in boxes {
                let part = mesh(
                    name,
                    &Definition {
                        shape: Shape::Box { size },
                        color: d.color,
                    },
                    36,
                )?;
                let start = m.positions.len() as u32;
                m.positions.extend(
                    part.positions
                        .into_iter()
                        .map(|p| [p[0] + position[0], p[1] + position[1], p[2] + position[2]]),
                );
                m.normals.extend(part.normals);
                m.uvs.extend(part.uvs);
                m.indices
                    .extend(part.indices.into_iter().map(|i| i + start));
            }
        }
        Shape::Gable { width, depth, rise } => {
            finite(&[*width, *depth, *rise])?;
            if *width <= 0. || *depth <= 0. || *rise <= 0. || max_vertices < 24 {
                return Err("Invalid gable dimensions or vertex budget".into());
            }
            let x = *width / 2.;
            let z = *depth / 2.;
            let y = *rise;
            let a = [-x, 0., -z];
            let b = [x, 0., -z];
            let c = [0., y, -z];
            let d = [-x, 0., z];
            let e = [x, 0., z];
            let f = [0., y, z];
            triangle(&mut m, a, c, b)?;
            triangle(&mut m, d, e, f)?;
            quad(&mut m, a, d, f, c)?;
            quad(&mut m, b, c, f, e)?;
            quad(&mut m, a, b, e, d)?;
        }
        Shape::Box { size } => {
            finite(size)?;
            if size.iter().any(|v| *v <= 0.) {
                return Err("Box dimensions must be positive".into());
            }
            if max_vertices < 36 {
                return Err("Vertex budget exceeded".into());
            }
            let [x, y, z] = [size[0] / 2., size[1] / 2., size[2] / 2.];
            if [x, y, z].contains(&0.) {
                return Err("Box dimensions collapse at output precision".into());
            }
            let v = [
                [-x, -y, -z],
                [x, -y, -z],
                [x, y, -z],
                [-x, y, -z],
                [-x, -y, z],
                [x, -y, z],
                [x, y, z],
                [-x, y, z],
            ];
            for [a, b, c, e] in [
                [0, 3, 2, 1],
                [4, 5, 6, 7],
                [0, 4, 7, 3],
                [1, 2, 6, 5],
                [0, 1, 5, 4],
                [3, 7, 6, 2],
            ] {
                quad(&mut m, v[a], v[b], v[c], v[e])?;
            }
        }
        Shape::Lathe { profile, segments } => {
            if !(3..=512).contains(segments) || !(2..=512).contains(&profile.len()) {
                return Err("Lathe subdivisions out of bounds".into());
            }
            let estimate = (profile.len() - 1) * (*segments as usize) * 6;
            if estimate > max_vertices {
                return Err("Vertex budget exceeded before lathe allocation".into());
            }
            for p in profile {
                finite(p)?;
                if p[0] < 0. {
                    return Err("Negative radius".into());
                }
            }
            if profile.windows(2).any(|p| p[1][1] < p[0][1]) {
                return Err("Lathe profile must ascend in height".into());
            }
            for pair in profile.windows(2) {
                for i in 0..*segments {
                    let angle = |j: u32| std::f32::consts::TAU * (j as f32) / (*segments as f32);
                    let point = |p: [f32; 2], a: f32| [p[0] * a.cos(), p[1], p[0] * a.sin()];
                    let a = point(pair[0], angle(i));
                    let b = point(pair[1], angle(i));
                    let c = point(pair[1], angle(i + 1));
                    let e = point(pair[0], angle(i + 1));
                    quad(&mut m, a, b, c, e)?;
                }
            }
        }
        Shape::Extrude { polygon, height } => {
            finite(&[*height])?;
            if *height <= 0. || !(3..=512).contains(&polygon.len()) {
                return Err("Invalid extrusion dimensions".into());
            }
            if polygon.len() * 12 > max_vertices {
                return Err("Vertex budget exceeded before extrusion allocation".into());
            }
            for p in polygon {
                finite(p)?
            }
            // Initial extrusion contract is strictly convex, counterclockwise in X/Z.
            // Reject unsupported concavity rather than silently triangulating it wrong.
            for i in 0..polygon.len() {
                let a = polygon[i];
                let b = polygon[(i + 1) % polygon.len()];
                let c = polygon[(i + 2) % polygon.len()];
                if (b[0] - a[0]) * (c[1] - b[1]) - (b[1] - a[1]) * (c[0] - b[0]) <= 1e-6 {
                    return Err("Polygon must be strictly convex and counterclockwise".into());
                }
                // Local turns alone also accept self-crossing stars. Every
                // remaining vertex must lie strictly inside this edge half-plane.
                for (j, point) in polygon.iter().enumerate() {
                    if j == i || j == (i + 1) % polygon.len() {
                        continue;
                    }
                    let side =
                        (b[0] - a[0]) * (point[1] - a[1]) - (b[1] - a[1]) * (point[0] - a[0]);
                    if side <= 1e-6 {
                        return Err("Self-crossing or non-convex extrusion polygon".into());
                    }
                }
            }
            for i in 0..polygon.len() {
                let a = polygon[i];
                let b = polygon[(i + 1) % polygon.len()];
                quad(
                    &mut m,
                    [a[0], 0., a[1]],
                    [a[0], *height, a[1]],
                    [b[0], *height, b[1]],
                    [b[0], 0., b[1]],
                )?;
            }
            for i in 1..polygon.len() - 1 {
                let a = polygon[0];
                let b = polygon[i];
                let c = polygon[i + 1];
                triangle(&mut m, [a[0], 0., a[1]], [b[0], 0., b[1]], [c[0], 0., c[1]])?;
                triangle(
                    &mut m,
                    [a[0], *height, a[1]],
                    [c[0], *height, c[1]],
                    [b[0], *height, b[1]],
                )?;
            }
        }
    }
    if m.indices.is_empty() {
        return Err("Empty or degenerate mesh".into());
    }
    Ok(m)
}
fn instance_count(node: &Assembly, depth: usize, limit: usize) -> Result<usize> {
    if depth > 32 {
        return Err("Assembly nesting exceeds 32".into());
    }
    let n = match node {
        Assembly::Part { .. } => 1,
        Assembly::Group { children } => {
            let mut sum = 0usize;
            for child in children {
                sum = sum
                    .checked_add(instance_count(child, depth + 1, limit)?)
                    .ok_or("Instance count overflow")?;
            }
            sum
        }
        Assembly::Repeat { count, child, .. } => instance_count(child, depth + 1, limit)?
            .checked_mul(*count as usize)
            .ok_or("Instance count overflow")?,
    };
    if n > limit {
        Err("Instance budget exceeded before expansion".into())
    } else {
        Ok(n)
    }
}
pub fn compile(recipe: &Recipe) -> Result<Scene> {
    if recipe.version != 1 {
        return Err("Unsupported recipe version".into());
    }
    if recipe.definitions.len() > 2048
        || recipe.limits.max_vertices > 4_000_000
        || recipe.limits.max_instances > 100_000
        || recipe.limits.gpu_geometry_bytes > 6 * 1024 * 1024 * 1024
    {
        return Err("Requested limits exceed compiler safety ceilings".into());
    }
    instance_count(&recipe.root, 0, recipe.limits.max_instances)?;
    let mut scene = Scene {
        version: 1,
        coordinate_system: "right-handed-y-up-ccw-metres",
        meshes: vec![],
        instances: vec![],
        estimated_geometry_bytes: 0,
    };
    let mut names = BTreeMap::new();
    fn emit(
        node: &Assembly,
        offset: V3,
        r: &Recipe,
        s: &mut Scene,
        names: &mut BTreeMap<String, usize>,
    ) -> Result<()> {
        match node {
            Assembly::Part {
                mesh: name,
                position,
                yaw,
                scale,
            } => {
                finite(position)?;
                finite(&[*yaw, *scale])?;
                if *scale <= 0. {
                    return Err("Scale must be positive".into());
                }
                let index = if let Some(i) = names.get(name) {
                    *i
                } else {
                    let d = r
                        .definitions
                        .get(name)
                        .ok_or_else(|| format!("Unknown mesh {name}"))?;
                    let used = s.meshes.iter().map(|m| m.positions.len()).sum::<usize>();
                    let m = mesh(name, d, r.limits.max_vertices.saturating_sub(used))?;
                    s.estimated_geometry_bytes +=
                        (m.positions.len() * 32 + m.indices.len() * 4) as u64;
                    if s.estimated_geometry_bytes > r.limits.gpu_geometry_bytes {
                        return Err("Geometry residency budget exceeded".into());
                    }
                    let index = s.meshes.len();
                    s.meshes.push(m);
                    names.insert(name.clone(), index);
                    index
                };
                let p = [
                    position[0] + offset[0],
                    position[1] + offset[1],
                    position[2] + offset[2],
                ];
                finite(&p)?;
                s.estimated_geometry_bytes += 64;
                if s.estimated_geometry_bytes > r.limits.gpu_geometry_bytes {
                    return Err("Instance residency budget exceeded".into());
                }
                s.instances.push(Instance {
                    mesh: index,
                    position: p,
                    yaw: *yaw,
                    scale: *scale,
                });
            }
            Assembly::Group { children } => {
                for child in children {
                    emit(child, offset, r, s, names)?
                }
            }
            Assembly::Repeat { count, step, child } => {
                finite(step)?;
                // Empty subtrees have no instances to emit. Without pruning,
                // nested repeats can do billions of iterations despite passing
                // the instance budget with a count of zero.
                if instance_count(child, 0, r.limits.max_instances)? == 0 {
                    return Ok(());
                }
                for i in 0..*count {
                    let p = [
                        offset[0] + step[0] * i as f32,
                        offset[1] + step[1] * i as f32,
                        offset[2] + step[2] * i as f32,
                    ];
                    finite(&p)?;
                    emit(child, p, r, s, names)?
                }
            }
        };
        Ok(())
    }
    emit(&recipe.root, [0.; 3], recipe, &mut scene, &mut names)?;
    Ok(scene)
}
pub fn compile_json(text: &str) -> Result<String> {
    if text.len() > 16 * 1024 * 1024 {
        return Err("Recipe exceeds 16 MiB".into());
    }
    let recipe: Recipe = serde_json::from_str(text).map_err(|e| e.to_string())?;
    serde_json::to_string(&compile(&recipe)?).map_err(|e| e.to_string())
}

/// C ABI: compile a UTF-8 recipe into an owned response buffer.
///
/// # Safety
/// Caller must supply readable input bytes and writable out_len.
/// Returned buffer belongs to this library and must be released exactly once
/// with scene_forge_free and the returned length. Do not use another allocator.
#[no_mangle]
pub unsafe extern "C" fn scene_forge_compile(
    input: *const u8,
    len: usize,
    out_len: *mut usize,
) -> *mut u8 {
    if out_len.is_null() {
        return std::ptr::null_mut();
    }
    *out_len = 0;
    if input.is_null() || len > 16 * 1024 * 1024 {
        return std::ptr::null_mut();
    }
    let result = std::panic::catch_unwind(|| {
        let bytes = std::slice::from_raw_parts(input, len);
        let text = std::str::from_utf8(bytes).map_err(|e| e.to_string())?;
        compile_json(text)
    });
    let response = match result {
        Ok(Ok(scene)) => format!("{{\"ok\":true,\"scene\":{scene}}}"),
        Ok(Err(error)) => serde_json::json!({"ok":false,"error":error}).to_string(),
        Err(_) => serde_json::json!({"ok":false,"error":"Compiler panicked"}).to_string(),
    };
    let mut bytes = response.into_bytes().into_boxed_slice();
    *out_len = bytes.len();
    let ptr = bytes.as_mut_ptr();
    std::mem::forget(bytes);
    ptr
}
/// Release the owned response buffer.
///
/// # Safety
/// ptr and len must be an outstanding allocation returned by scene_forge_compile.
#[no_mangle]
pub unsafe extern "C" fn scene_forge_free(ptr: *mut u8, len: usize) {
    if !ptr.is_null() {
        drop(Box::from_raw(std::ptr::slice_from_raw_parts_mut(ptr, len)))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    fn recipe() -> Recipe {
        serde_json::from_str(r#"{"version":1,"definitions":{"block":{"shape":{"kind":"box","size":[2,2,2]},"color":[0.6,0.5,0.4,1]}},"root":{"kind":"repeat","count":1000,"step":[3,0,0],"child":{"kind":"part","mesh":"block"}}}"#).unwrap()
    }
    #[test]
    fn instances_share_geometry() {
        let s = compile(&recipe()).unwrap();
        assert_eq!(s.instances.len(), 1000);
        assert_eq!(s.meshes.len(), 1);
        assert_eq!(s.meshes[0].positions.len(), 36);
        assert!(s.estimated_geometry_bytes < 70_000);
    }
    #[test]
    fn deterministic() {
        let r = recipe();
        assert_eq!(
            serde_json::to_string(&compile(&r).unwrap()).unwrap(),
            serde_json::to_string(&compile(&r).unwrap()).unwrap()
        );
    }
    #[test]
    fn outward_box_normals() {
        let s = compile(&recipe()).unwrap();
        let m = &s.meshes[0];
        for (p, n) in m.positions.iter().zip(&m.normals) {
            assert!(p.iter().zip(n).map(|(a, b)| a * b).sum::<f32>() > 0.);
        }
    }
    #[test]
    fn budgets_fail_before_expansion() {
        let mut r = recipe();
        r.limits.max_instances = 10;
        assert!(compile(&r).unwrap_err().contains("Instance budget"));
        r.limits.max_instances = 1000;
        r.limits.max_vertices = 10;
        assert!(compile(&r).unwrap_err().contains("Vertex budget"));
        r.limits.max_vertices = 100;
        r.limits.gpu_geometry_bytes = 100;
        assert!(compile(&r).unwrap_err().contains("residency"));
    }
    #[test]
    fn box_faces_survive_scale_extremes() {
        for size in [[1e-20, 1., 1.], [1e6; 3], [1e-20; 3]] {
            let m = mesh(
                "scale-regression",
                &Definition {
                    shape: Shape::Box { size },
                    color: [1.; 4],
                },
                36,
            )
            .unwrap();
            assert_eq!(m.positions.len(), 36, "Missing faces for {size:?}");
            for n in &m.normals {
                assert!(n.iter().all(|v| v.is_finite()));
                assert!((n.iter().map(|v| v * v).sum::<f32>() - 1.).abs() < 1e-6);
            }
        }
    }
    #[test]
    fn invalid_geometry() {
        let mut r = recipe();
        r.definitions.get_mut("block").unwrap().shape = Shape::Box {
            size: [f32::from_bits(1), 1., 1.],
        };
        assert!(compile(&r).unwrap_err().contains("output precision"));
        r.definitions.get_mut("block").unwrap().shape = Shape::Box {
            size: [f32::NAN, 1., 1.],
        };
        assert!(compile(&r).is_err());
        r.definitions.get_mut("block").unwrap().shape = Shape::Extrude {
            polygon: vec![[0., 0.], [0., 1.], [1., 0.]],
            height: 1.,
        };
        assert!(compile(&r).is_err());
    }
    #[test]
    fn supported_lathe_and_extrusion() {
        for shape in [
            Shape::Lathe {
                profile: vec![[0., 0.], [1., 0.], [1., 2.], [0., 2.]],
                segments: 32,
            },
            Shape::Extrude {
                polygon: vec![[0., 0.], [2., 0.], [1., 1.]],
                height: 2.,
            },
        ] {
            let mut r = recipe();
            r.definitions.get_mut("block").unwrap().shape = shape;
            let s = compile(&r).unwrap();
            let m = &s.meshes[0];
            assert!(!m.indices.is_empty());
            assert!(m.indices.iter().all(|i| (*i as usize) < m.positions.len()));
            assert!(m
                .normals
                .iter()
                .all(|n| (n.iter().map(|v| v * v).sum::<f32>() - 1.).abs() < 1e-4));
        }
    }
    #[test]
    fn native_abi_roundtrip() {
        let text = serde_json::to_vec(&recipe()).unwrap();
        unsafe {
            let mut n = 0;
            let p = scene_forge_compile(text.as_ptr(), text.len(), &mut n);
            assert!(!p.is_null());
            let v: serde_json::Value =
                serde_json::from_slice(std::slice::from_raw_parts(p, n)).unwrap();
            assert_eq!(v["ok"], true);
            scene_forge_free(p, n);
        }
    }
    #[test]
    fn huge_empty_repeats_are_pruned() {
        let mut r = recipe();
        r.root = Assembly::Repeat {
            count: u32::MAX,
            step: [0.; 3],
            child: Box::new(Assembly::Repeat {
                count: u32::MAX,
                step: [0.; 3],
                child: Box::new(Assembly::Group { children: vec![] }),
            }),
        };
        let s = compile(&r).unwrap();
        assert!(s.instances.is_empty());
        assert!(s.meshes.is_empty());
        assert_eq!(s.estimated_geometry_bytes, 0);
    }
    #[test]
    fn room_batch_reuses_mesh_and_enforces_vertex_budget() {
        let text = include_str!("../examples/rooms.json");
        let mut r: Recipe = serde_json::from_str(text).unwrap();
        if let Assembly::Repeat { count, .. } = &mut r.root {
            *count = 17_000;
        }
        let s = compile(&r).unwrap();
        assert_eq!(s.instances.len(), 17_000);
        assert_eq!(s.meshes.len(), 1);
        assert!(s.estimated_geometry_bytes < 2_000_000);
        assert_eq!(s.instances[1].position, [10., 0., 0.]);
        let m = &s.meshes[0];
        assert_eq!(m.positions.len(), m.normals.len());
        assert_eq!(m.apertures.len(), 3);
        assert_eq!(m.apertures[0].opening_index, 0);
        assert_eq!(m.apertures[0].position, [1.5, 0., 3.65]);
        assert_eq!(m.apertures[0].outward_normal, [0., 0., 1.]);
        assert_eq!(m.apertures[1].position, [4.15, 1., -1.]);
        assert!(m.indices.iter().all(|i| (*i as usize) < m.positions.len()));
        assert_eq!(compile_json(text).unwrap(), compile_json(text).unwrap());
        r.limits.max_vertices = m.positions.len() - 1;
        assert!(compile(&r).unwrap_err().contains("before room allocation"));
    }
}
