import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { pathToFileURL } from 'node:url'
import { inside, validate, build, alignSpriteEdge } from './sprite-room-review.mjs'

assert.deepEqual(alignSpriteEdge([[10,20],[30,40]], [[2,3],[12,13]], 0), {scale:2,offset:[6,14],error:0})
const fixed = [[0,0],[100,1]], moving = [[0,0],[50,0]]
assert.equal(alignSpriteEdge(fixed, moving, 1).error, 1)
assert.throws(() => alignSpriteEdge(fixed, moving, 0.9))
for (const bad of [ [[0,0],[0,0]], [[0,0],[-10,0]], [[0,0],[0,10]], [[0,0],[NaN,0]] ])
  assert.throws(() => alignSpriteEdge([[0,0],[10,0]], bad))
assert.throws(() => alignSpriteEdge([[0,0],[10,0]], [[0,0],[10,0]], -1))
assert.throws(() => alignSpriteEdge([[0,0],[10,0]], [[0,0],[10,0]], Infinity))
assert.deepEqual(alignSpriteEdge(fixed,moving), alignSpriteEdge(fixed,moving))
console.log('PASS deterministic edge alignment, explicit tolerance, no rotation/mirror and invalid-input rejection')

const path = 'procedural/sprites/candidates/barana-drydock-01/room.json'
const room = JSON.parse(readFileSync(path, 'utf8'))
validate(room)
assert(inside([0.5,0.6], room.floor))
assert(!inside([0.05,0.05], room.floor))
for (const mutation of [
  r => r.anchors[0].point = [NaN,0.5],
  r => r.anchors[0].point = [0,0],
  r => r.anchors[1].id = r.anchors[0].id,
  r => r.runtimeAdmission = true,
  r => r.image.path = '../source.png',
  r => r.image.width = 0,
  r => r.exits[0].anchor = [0.5,0.5]
]) {
  const bad = structuredClone(room); mutation(bad)
  assert.throws(() => validate(bad))
}
assert.deepEqual(room.exits, [{direction:'south', command:'south', to:'1-455', presentation:'off-camera', anchor:null}])
const output = build(path)
const first = readFileSync(output, 'utf8')
build(path)
assert.equal(readFileSync(output, 'utf8'), first)
assert(!first.includes('fetch('))
console.log('PASS manifest, placement bounds, seven rejection cases, graph exit, image hash/dimensions, deterministic offline generation')

// Optional existing Playwright installation; no package download or server.
if (process.argv[2]) {
  const { chromium } = await import(pathToFileURL(resolve(process.argv[2])).href)
  const browser = await chromium.launch({headless:true})
  try {
    const page = await browser.newPage({viewport:{width:1440,height:1050},deviceScaleFactor:1})
    const errors = []
    page.on('pageerror', error => errors.push(error.message))
    await page.goto(pathToFileURL(resolve(output)).href)
    await page.locator('#art').evaluate(async image => {
      const decoded = new Image(); decoded.src = image.getAttribute('href'); await decoded.decode()
    })
    assert.equal(await page.locator('#markers circle').count(), 4)
    const box = await page.locator('#board').boundingBox()
    await page.mouse.click(box.x+box.width*0.05,box.y+box.height*0.05)
    assert.match(await page.locator('#status').innerText(), /rejected/)
    await page.mouse.click(box.x+box.width*0.53,box.y+box.height*0.66)
    assert.match(await page.locator('#status').innerText(), /Local review only/)
    const downloadWait = page.waitForEvent('download')
    await page.locator('#save').click()
    const download = await downloadWait
    const exported = JSON.parse(readFileSync(await download.path(), 'utf8'))
    validate(exported)
    assert.equal(exported.runtimeAdmission, false)
    assert.deepEqual(exported.exits, room.exits)
    assert(Math.abs(exported.anchors[0].point[0]-0.53)<0.001)
    await page.locator('#reset').click()
    await page.screenshot({path:resolve('procedural/sprites/candidates/barana-drydock-01/review-desktop.png'),fullPage:true})
    await page.setViewportSize({width:390,height:844})
    assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth))
    await page.locator('#overlays').uncheck()
    assert.equal(await page.locator('#markers').isVisible(), false)
    assert.deepEqual(errors, [])
    console.log('PASS headless browser: image load, markers, rejection, placement, JSON export, reset, mobile width, overlays, no page errors')
  } finally { await browser.close() }
}
