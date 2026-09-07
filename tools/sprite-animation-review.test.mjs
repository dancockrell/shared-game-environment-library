import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { validate } from './sprite-animation-review.mjs'
const source = JSON.parse(readFileSync(new URL('../procedural/sprites/candidates/rat-scurry-01/animation.json',import.meta.url)))
test('candidate validates',()=>assert.equal(validate(structuredClone(source)).frames.length,4))
for (const [name,change] of [
  ['admitted source',m=>m.runtimeAdmission=true],
  ['path traversal',m=>m.image.path='../source.png'],
  ['out of bounds',m=>m.frames[0].rect[2]=9999],
  ['invalid anchor',m=>m.frames[0].anchor[0]=-1],
  ['zero speed',m=>m.fps=0],
  ['infinite scale',m=>m.scale=Infinity]
]) test(name,()=>{const m=structuredClone(source);change(m);assert.throws(()=>validate(m))})
