import test from 'node:test';
import assert from 'node:assert/strict';
import {auditMesh} from './audit-solids.mjs';

const tetra = () => ({name:'tetra', positions:[0,0,0, 1,0,0, 0,1,0, 0,0,1], indices:[0,2,1, 0,1,3, 0,3,2, 1,2,3]});
test('closed tetrahedron, volume and split rendering vertices', () => {
  const source=tetra(), report=auditMesh(source);
  assert.equal(report.closed_oriented_position_graph,true);
  assert.equal(report.signed_volume_estimate,1/6);
  const split={name:'split',positions:source.indices.flatMap(i=>source.positions.slice(i*3,i*3+3)),indices:Array.from({length:12},(_,i)=>i)};
  const before=JSON.stringify(split), result=auditMesh(split);
  assert.equal(result.closed_oriented_position_graph,true);
  assert.equal(result.exact_position_vertices,4);
  assert.equal(JSON.stringify(split),before);
});
test('missing and flipped faces are not admitted as closed oriented graphs', () => {
  const missing=tetra(); missing.indices.splice(0,3);
  assert.equal(auditMesh(missing).boundary_edges,3);
  const flipped=tetra(); [flipped.indices[0],flipped.indices[1]]=[flipped.indices[1],flipped.indices[0]];
  assert.equal(auditMesh(flipped).winding_conflicts,3);
});
test('point-contact shells fail the closed vertex fan check despite paired edges', () => {
  const a=tetra(); a.positions.push(-1,0,0, 0,-1,0, 0,0,-1);
  a.indices.push(...tetra().indices.map(i=>i===0?0:i+3).reverse());
  const result=auditMesh(a);
  assert.equal(result.boundary_edges,0);
  assert.equal(result.excess_incidence_edges,0);
  assert.equal(result.failed_closed_vertex_fans,1);
  assert.equal(result.closed_oriented_position_graph,false);
});
test('degenerate and malformed inputs fail visibly', () => {
  assert.equal(auditMesh({name:'empty',positions:[],indices:[]}).closed_oriented_position_graph,false);
  const d=tetra(); d.indices.push(0,0,1);
  assert.equal(auditMesh(d).collapsed_faces,1);
  d.indices.push(999,0,1);
  assert.throws(()=>auditMesh(d),/Invalid triangle index/);
});
test('separate shells are counted without declaring them one solid', () => {
  const d=tetra();
  d.positions.push(...tetra().positions.map((x,i)=>i%3===0?x+3:x));
  d.indices.push(...tetra().indices.map(i=>i+4));
  const r=auditMesh(d);
  assert.equal(r.connected_components,2);
  assert.equal(r.closed_oriented_position_graph,true);
  assert.equal(r.solid_validity,'not_certified');
});
