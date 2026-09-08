import {readFileSync,readdirSync,realpathSync,writeFileSync} from 'node:fs'
import {resolve,relative,dirname,isAbsolute} from 'node:path'
import {fileURLToPath} from 'node:url'
import {createHash} from 'node:crypto'
const sha=b=>createHash('sha256').update(b).digest('hex')
function inside(root,path) {
 const rel=relative(root,path).replaceAll('\\','/')
 if(rel==='..'||rel.startsWith('../')||isAbsolute(rel))throw Error('Component path escapes kit')
 return path
}
function manifests(root) {
 return readdirSync(root,{withFileTypes:true}).sort((a,b)=>a.name.localeCompare(b.name)).flatMap(e=>e.isDirectory()?manifests(resolve(root,e.name)):e.isFile()&&e.name==='kit.json'?[resolve(root,e.name)]:[])
}
export function buildSpriteKitIndex(root) {
 root=realpathSync(root)
 const components=[],omitted={unreviewed:0,rejected:0},ids=new Set();let kits=0
 for(const manifest of manifests(root)) {
  const bytes=readFileSync(manifest),kit=JSON.parse(bytes),dir=dirname(manifest)
  if(!Array.isArray(kit.components))continue
  kits++
  for(const c of kit.components) {
   if(/^reject/i.test(kit.status??'')||/^reject/i.test(c.status??'')){omitted.rejected++;continue}
   if(c.status!=='reviewed-candidate'){omitted.unreviewed++;continue}
   if(!kit.id||!c.id||typeof c.file!=='string'||!c.file.endsWith('.png'))throw Error(`Missing identity/file: ${manifest}`)
   const path=inside(dir,realpathSync(inside(dir,resolve(dir,c.file)))),png=readFileSync(path)
   if(png.length<33||png.subarray(0,8).toString('hex')!=='89504e470d0a1a0a'||png.toString('ascii',12,16)!=='IHDR')throw Error(`Invalid PNG: ${c.file}`)
   if(c.sha256!==undefined&&c.sha256!==sha(png))throw Error(`Reviewed hash drift: ${c.id}`)
   const size=[png.readUInt32BE(16),png.readUInt32BE(20)]
   if(!Array.isArray(c.size)||c.size.length!==2||size.some((n,i)=>n!==c.size[i]||n<1||n>4096))throw Error(`Size drift: ${c.id}`)
   if(!Array.isArray(c.anchor)||c.anchor.length!==2||c.anchor.some((n,i)=>!Number.isFinite(n)||n<0||n>size[i]))throw Error(`Invalid anchor: ${c.id}`)
   if(!['ground','wall','roof'].includes(c.mount)||!Array.isArray(c.semanticTags)||c.semanticTags.some(t=>typeof t!=='string'))throw Error(`Missing mounting/tags: ${c.id}`)
   const id=kit.id+'/'+c.id;if(ids.has(id))throw Error(`Duplicate component: ${id}`);ids.add(id)
   components.push({...c,id,kit:kit.id,manifest:relative(root,manifest).replaceAll('\\','/'),manifestSha256:sha(bytes),file:relative(root,path).replaceAll('\\','/'),size,sha256:sha(png),runtimeAdmission:false})
  }
 }
 components.sort((a,b)=>a.id.localeCompare(b.id))
 return {schemaVersion:1,status:'reviewed-component-candidates',runtimeAdmission:false,source:'Derived from kit.json; not an independent admission registry',kits,omitted,components}
}
export function searchSpriteComponents(index,query) {
 const words=query.toLowerCase().split(/\s+/).filter(Boolean)
 return index.components.filter(c=>{const text=[c.id,c.mount,...c.semanticTags].join(' ').toLowerCase();return words.every(w=>text.includes(w))})
}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url)) {
 const index=buildSpriteKitIndex('procedural/sprites/candidates'),args=process.argv.slice(2)
 if(args[0]==='--search'&&args.length>1)console.log(JSON.stringify(searchSpriteComponents(index,args.slice(1).join(' ')),null,2))
 else if(!args.length){writeFileSync('procedural/sprites/component-index.json',JSON.stringify(index,null,2)+'\n');console.log(`Indexed ${index.components.length} reviewed candidates; ${index.omitted.unreviewed} legacy/unreviewed and ${index.omitted.rejected} rejected omitted. No runtime admission.`)}
 else throw Error('Usage: node tools/sprite-kit-index.mjs [--search words]')
}
