import assert from 'node:assert/strict'
import {mkdtempSync,mkdirSync,writeFileSync,rmSync} from 'node:fs'
import {tmpdir} from 'node:os'
import {join} from 'node:path'
import {buildSpriteKitIndex,searchSpriteComponents} from './sprite-kit-index.mjs'
const root=mkdtempSync(join(tmpdir(),'sprite-index-test-'))
try {
 const dir=join(root,'kit');mkdirSync(dir)
 const png=Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==','base64');writeFileSync(join(dir,'piece.png'),png)
 const c={id:'crate',file:'piece.png',size:[1,1],anchor:[.5,1],mount:'ground',semanticTags:['wood','storage'],status:'reviewed-candidate'}
 const kit={id:'kit',components:[c,{id:'unknown'},{id:'bad',status:'rejected'}]},save=()=>writeFileSync(join(dir,'kit.json'),JSON.stringify(kit))
 save();const r=buildSpriteKitIndex(root)
 assert.equal(r.components.length,1);assert.deepEqual(r.omitted,{unreviewed:1,rejected:1});assert.equal(r.components[0].runtimeAdmission,false)
 assert.equal(searchSpriteComponents(r,'wood ground').length,1);assert.equal(searchSpriteComponents(r,'roof').length,0);assert.deepEqual(buildSpriteKitIndex(root),r)
 c.sha256='invalid';save();assert.throws(()=>buildSpriteKitIndex(root),/hash drift/);delete c.sha256
 c.size=[2,1];save();assert.throws(()=>buildSpriteKitIndex(root),/Size drift/)
 c.size=[1,1];c.anchor=[2,1];save();assert.throws(()=>buildSpriteKitIndex(root),/Invalid anchor/)
 c.anchor=[.5,1];c.file='../outside.png';writeFileSync(join(root,'outside.png'),png);save();assert.throws(()=>buildSpriteKitIndex(root),/escapes/)
 c.file='piece.png';kit.components.push({...c});save();assert.throws(()=>buildSpriteKitIndex(root),/Duplicate/)
 console.log('PASS deterministic search, review/rejection gates, dimensions, anchors and path containment')
}finally{rmSync(root,{recursive:true,force:true})}
