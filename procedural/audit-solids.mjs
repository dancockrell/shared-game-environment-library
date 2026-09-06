// Read-only diagnostics on exact-position connectivity, not topology repair or
// proof of a valid solid. UV/normal splits are ignored ONLY in this audit graph.
import { readFileSync, statSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

export function auditMesh(mesh) {
  const ids = new Map(), remap = [], edges = new Map(), links = [];
  for (let i = 0; i < mesh.positions.length; i += 3) {
    const p = mesh.positions.slice(i, i + 3);
    if (p.length !== 3 || p.some(x => !Number.isFinite(x))) throw new Error('Invalid position buffer');
    const key = p.map(x => x === 0 ? 0 : x).join(',');
    if (!ids.has(key)) { ids.set(key, ids.size); links.push([]); }
    remap.push(ids.get(key));
  }
  if (mesh.indices.length % 3) throw new Error('Incomplete triangle');
  let collapsedFaces = 0, volume6 = 0;
  for (let i = 0; i < mesh.indices.length; i += 3) {
    const raw = mesh.indices.slice(i, i + 3);
    if (raw.some(x => !Number.isInteger(x) || x < 0 || x >= remap.length)) throw new Error('Invalid triangle index');
    const [a,b,c] = raw.map(x => remap[x]);
    if (a === b || a === c || b === c) { collapsedFaces++; continue; }
    const points = raw.map(x => mesh.positions.slice(x * 3, x * 3 + 3));
    const [p,q,r] = points;
    const cross = [(q[1]-p[1])*(r[2]-p[2])-(q[2]-p[2])*(r[1]-p[1]),
      (q[2]-p[2])*(r[0]-p[0])-(q[0]-p[0])*(r[2]-p[2]),
      (q[0]-p[0])*(r[1]-p[1])-(q[1]-p[1])*(r[0]-p[0])];
    if (cross.every(x => x === 0)) collapsedFaces++;
    volume6 += p[0]*(q[1]*r[2]-q[2]*r[1]) + p[1]*(q[2]*r[0]-q[0]*r[2]) + p[2]*(q[0]*r[1]-q[1]*r[0]);
    for (const [u,v] of [[a,b],[b,c],[c,a]]) {
      const key = u < v ? `${u}:${v}` : `${v}:${u}`;
      const edge = edges.get(key) ?? {count:0, balance:0};
      edge.count++; edge.balance += u < v ? 1 : -1; edges.set(key, edge);
    }
    links[a].push([b,c]); links[b].push([c,a]); links[c].push([a,b]);
  }
  let boundaryEdges=0, excessIncidenceEdges=0, windingConflicts=0, failedClosedVertexFans=0;
  for (const edge of edges.values()) {
    if (edge.count === 1) boundaryEdges++;
    if (edge.count > 2) excessIncidenceEdges++;
    if (edge.count === 2 && edge.balance !== 0) windingConflicts++;
  }
  for (const link of links) {
    const graph = new Map();
    for (const [a,b] of link) {
      if (!graph.has(a)) graph.set(a, []);
      if (!graph.has(b)) graph.set(b, []);
      graph.get(a).push(b); graph.get(b).push(a);
    }
    const visited = new Set(), pending = graph.size ? [graph.keys().next().value] : [];
    while (pending.length) {
      const next = pending.pop();
      if (visited.has(next)) continue;
      visited.add(next);
      for (const neighbor of graph.get(next)) if (!visited.has(neighbor)) pending.push(neighbor);
    }
    if (!graph.size || visited.size !== graph.size || [...graph.values()].some(x => x.length !== 2)) failedClosedVertexFans++;
  }
  let connectedComponents = 0;
  const reached = new Set();
  for (let vertex = 0; vertex < links.length; vertex++) {
    if (reached.has(vertex)) continue;
    connectedComponents++;
    const pending = [vertex];
    while (pending.length) {
      const next = pending.pop();
      if (reached.has(next)) continue;
      reached.add(next);
      for (const pair of links[next]) for (const neighbor of pair) if (!reached.has(neighbor)) pending.push(neighbor);
    }
  }
  const closed = mesh.indices.length > 0 && collapsedFaces + boundaryEdges + excessIncidenceEdges + windingConflicts + failedClosedVertexFans === 0;
  return {name:mesh.name, stored_vertices:remap.length, exact_position_vertices:ids.size,
    triangles:mesh.indices.length/3, connected_components:connectedComponents, collapsed_faces:collapsedFaces, boundary_edges:boundaryEdges,
    excess_incidence_edges:excessIncidenceEdges, winding_conflicts:windingConflicts,
    failed_closed_vertex_fans:failedClosedVertexFans, closed_oriented_position_graph:closed,
    signed_volume_estimate:closed ? volume6/6 : null,
    solid_validity:'not_certified', self_intersections:'not_checked',
    connectivity_basis:'exact numeric positions; signed zero unified; no tolerance or mesh edits'};
}

export function auditScene(scene) {
  if (![1,2].includes(scene.version) || !Array.isArray(scene.meshes)) throw new Error('Unsupported compiled scene');
  const meshes=scene.meshes.map(auditMesh);
  const recipe=scene.recipe_json ? JSON.parse(scene.recipe_json) : null;
  const failed=meshes.filter(m=>recipe?.definitions?.[m.name]?.shape?.kind==='room' && !m.closed_oriented_position_graph).map(m=>m.name);
  return {scope:'read-only exact-position connectivity audit; not solid admission', required_closed_shapes:['room'], failed_required_meshes:failed, meshes};
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const input = process.argv[2];
  if (!input || statSync(input).size > 128*1024*1024) throw new Error('Expected compiled scene no larger than 128 MiB');
  const scene = JSON.parse(readFileSync(input, 'utf8'));
  const report=auditScene(scene);
  process.stdout.write(JSON.stringify(report,null,2)+'\n');
  if (report.failed_required_meshes.length) process.exitCode=1;
}
