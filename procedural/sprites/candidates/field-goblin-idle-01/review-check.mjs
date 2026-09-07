import {launch} from '../../../../../dr-companion/tools/browser.mjs'
import {fileURLToPath} from 'node:url'
import assert from 'node:assert/strict'
const browser=await launch({width:1100,height:900})
try {
  await browser.goto(new URL('./extracted-01/animation-review.html',import.meta.url).href,{waitFor:'body[data-ready]'})
  await browser.click('#play')
  const frames=await browser.eval(`(async()=>{const frames=new Set();for(let i=0;i<70;i++){frames.add(document.querySelector('#state').textContent);await new Promise(r=>setTimeout(r,50))}return [...frames].sort()})()`)
  assert.deepEqual(frames,['Frame 1 / 4','Frame 2 / 4','Frame 3 / 4','Frame 4 / 4'])
  assert.equal(await browser.eval("document.querySelector('#error').textContent"),'')
  await browser.screenshot(fileURLToPath(new URL('./extracted-01/review-moss.png',import.meta.url)))
  await browser.eval("(()=>{const bg=document.querySelector('#bg');bg.value='#eee8d9';bg.dispatchEvent(new Event('change'))})()")
  await browser.screenshot(fileURLToPath(new URL('./extracted-01/review-light.png',import.meta.url)))
  console.log('PASS field goblin: transparent frames decoded, all four poses observed with real timing; moss and light captures')
} finally {await browser.close()}
