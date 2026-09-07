import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { validate, validateImage, hasSpriteAlpha } from './sprite-animation-review.mjs'
import { createHash } from 'node:crypto'
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

test('original RGBA source passes header and identity gate',()=>{
  const bytes=readFileSync(new URL('../procedural/sprites/candidates/rat-scurry-01/source-01.png',import.meta.url))
  assert.doesNotThrow(()=>validateImage(bytes,source))
})
for(const name of ['idle-02.png','idle-03.png'])test(`${name} painted checkerboard is rejected`,()=>{
  const bytes=readFileSync(new URL(`../procedural/sprites/candidates/rat-scurry-01/${name}`,import.meta.url))
  const m=structuredClone(source);m.image.sha256=createHash('sha256').update(bytes).digest('hex')
  assert.throws(()=>validateImage(bytes,m),/RGBA/)
})
test('decoded alpha needs visible subject and fully transparent background',()=>{
  assert.equal(hasSpriteAlpha([0,0,0,0,100,50,25,255]),true)
  assert.equal(hasSpriteAlpha([0,0,0,0,100,50,25,1]),true)
  assert.equal(hasSpriteAlpha([255,255,255,255,128,128,128,255]),false)
  assert.equal(hasSpriteAlpha([0,0,0,0]),false)
  assert.equal(hasSpriteAlpha([]),false)
  assert.equal(hasSpriteAlpha([0,0,0]),false)
})
