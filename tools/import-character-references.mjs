import { readFile, writeFile, copyFile, mkdir, stat, access } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { resolve, dirname, relative, basename, isAbsolute } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const input = process.argv[2];
if (!input) throw new Error('Usage: node tools/import-character-references.mjs /absolute/path/to/character-art-manifest.json [--check]');
const check = process.argv.includes('--check');
const manifestPath = resolve(input);
const sourceRoot = resolve(dirname(manifestPath), '../../..');
const packDir = resolve(root, 'resource_packs/character-support/illustrated-adult-adventurers');
const raw = await readFile(manifestPath);
const manifest = JSON.parse(raw);
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const exists = async path => { try { await access(path); return true; } catch { return false; } };
const sourcePath = path => {
  const result = resolve(sourceRoot, path);
  const rel = relative(sourceRoot, result);
  if (isAbsolute(rel) || rel === '..' || rel.startsWith('../') || rel.startsWith('..\\')) throw new Error('Source path escapes input workspace: ' + path);
  return result;
};
const candidates = (manifest.candidate_collections ?? []).flatMap(collection => collection.assets.map(asset => ({ collection, asset })));
if (!candidates.length) throw new Error('No explicitly catalogued candidate assets; refusing an empty import.');
const planned = new Map();
const outputs = [];
const ids = new Set();
const inputAssets = new Map();
async function planFile(source, destination, expectedHash) {
  const bytes = await readFile(source);
  const sha256 = hash(bytes);
  if (expectedHash && sha256 !== expectedHash.toLowerCase()) throw new Error('Source hash mismatch: ' + source);
  if (planned.has(destination) && hash(planned.get(destination).bytes) !== sha256) throw new Error('Conflicting destination: ' + destination);
  planned.set(destination, { source, bytes });
  return { sha256, bytes: bytes.length };
}
function pngDimensions(bytes) {
  if (bytes.length < 24 || bytes.subarray(0,8).toString('hex') !== '89504e470d0a1a0a') throw new Error('Invalid PNG input');
  return { width: bytes.readUInt32BE(16), height: bytes.readUInt32BE(20) };
}
for (const {collection, asset} of candidates) {
  if (!/^[a-z0-9][a-z0-9-]+$/.test(asset.id) || ids.has(asset.id)) throw new Error('Invalid/duplicate asset ID: ' + asset.id);
  ids.add(asset.id);
  if (collection.reference_usage !== 'style-only; not identity transfer') throw new Error('Unsupported lineage: record all parent relationships before extending this importer.');
  const path = 'artifacts/references/' + asset.id + '.png';
  const info = await planFile(sourcePath(asset.path), path, asset.sha256);
  const dimensions = pngDimensions(planned.get(path).bytes);
  if (dimensions.width !== asset.width || dimensions.height !== asset.height || info.bytes !== asset.bytes) throw new Error('Dimensions/bytes mismatch: ' + asset.id);
  const promptPath = 'prompts/' + asset.id + '.md';
  const prompt = await planFile(sourcePath(asset.prompt_record_path), promptPath);
  const refHash = asset.style_reference_sha256.toLowerCase();
  const refId = 'reference.' + refHash;
  const refPath = 'inputs/' + refHash + '.png';
  if (!inputAssets.has(refId)) {
    const ref = await planFile(sourcePath(asset.style_reference_path), refPath, refHash);
    const referenceRecord = manifest.assets.find(x => x.sha256?.toLowerCase() === refHash);
    if (!referenceRecord) throw new Error('Style input missing source provenance');
    inputAssets.set(refId, {
      assetId: refId, path: refPath, format: 'PNG', ...ref,
      ...pngDimensions(planned.get(refPath).bytes),
      role: 'style_reference_only',
      generation: { tool: manifest.generator, modelVersion: null, creationId: referenceRecord.source_file, sourceThreadId: manifest.source_thread_id, exactPrompt: null },
      userApprovalScope: 'Project identity approval does not grant shared runtime admission.',
      licenseSpdx: 'NOASSERTION', engineEligibility: 'reference_only'
    });
  }
  outputs.push({
    assetId: 'character-reference.' + asset.id, path, format: 'PNG', ...info, ...dimensions,
    role: 'generated_character_concept', tags: ['adult', 'illustrated', 'period-derived-clothing', 'character-reference', asset.id.replace(/-v[0-9]+$/, '')],
    generation: { tool: collection.generator, modelVersion: collection.model_version ?? null, creationId: asset.source_file, sourceThreadId: collection.source_thread_id, recordedDate: collection.recorded_date, promptPath, promptSha256: prompt.sha256 },
    lineage: { operation: 'image_generation_with_style_reference', parents: [{ assetId: refId, sha256: refHash, relationship: 'style_only' }], transformations: ['byte_identical_export_to_shared_library'] },
    review: { sourceStatus: asset.status, visualReview: asset.visual_review, userApproved: asset.production_admission.user_approved, runtimeReady: false },
    licenseSpdx: 'NOASSERTION', termsEvidence: collection.license_terms_snapshot ?? null, engineEligibility: 'reference_only'
  });
}
outputs.push(...inputAssets.values());
outputs.sort((a,b)=>a.assetId.localeCompare(b.assetId));
const pack = {
  packId: 'character-support.illustrated-adult-adventurers.v1',
  displayName: 'Illustrated Adult Adventurer References',
  packType: 'character-support', authoringStatus: 'reference_only', engineEligibility: 'reference_only',
  style: { renderLanguage: ['illustrated_color', 'detailed_character_concept'], physicalSubject: ['adult_human_adventurer', 'adult_fox_woman', 'period_equipment'], sceneRoles: ['character_visual_reference', 'costume_reference', 'illustration_reference'] },
  sourceLineage: { kind: 'generated_reference_export', sourceProject: manifest.project, sourceManifest: basename(manifestPath), sourceManifestSha256: hash(raw), sourceThreadId: manifest.source_thread_id, upstreamLicenseSpdx: 'NOASSERTION', sourceMembers: outputs.map(x=>x.generation.creationId), updatePolicy: 'Regenerate from project manifest. Project remains owner of identity and approval; shared pack is a derived reference export.' },
  reusePolicy: { purpose: 'Shared inspiration and modeling references; no inferred training permission or ready-made rig/mesh.', combinations: 'New combinations and alterations must keep every exact input asset ID/hash and its relationship, operation, prompt and changed properties. Preserve originals.', publication: 'Owner directs testing, integration and push to the existing repository; verify remote Git and LFS availability. No separate publication approval gate. Reference status remains independent of game approval.', rights: 'Generated outputs are not CC0 merely because library metadata is CC0; terms evidence remains unverified.' },
  outputs,
  searchTags: ['character-support','adult','illustration','period-clothing','pirate','fox','generated-reference','not-runtime'],
  review: { literalSemantics: 'project_agent_inspected_concept_candidates', technical: 'png_dimensions_and_hashes_verified_not_engine_reviewed', visual: 'user_selection_pending_for_ten_concepts', rights: 'terms_evidence_pending', runtime: 'not_admitted' }
};
const packPath = resolve(packDir, 'pack.json');
if (await exists(packPath)) {
  const old = JSON.parse(await readFile(packPath));
  for (const entry of old.outputs) if (!outputs.some(x=>x.assetId === entry.assetId && x.sha256 === entry.sha256)) throw new Error('Refusing to remove or replace an existing variant: ' + entry.assetId);
}
for (const [path, file] of planned) {
  const dest = resolve(packDir, path);
  if (await exists(dest)) {
    if (hash(await readFile(dest)) !== hash(file.bytes)) throw new Error('Existing shared file differs: ' + path);
  } else if (check) throw new Error('Missing shared file: ' + path);
}
const serialized = JSON.stringify(pack,null,2) + '\n';
if (check) {
  if (!await exists(packPath) || (await readFile(packPath,'utf8')) !== serialized) throw new Error('Pack metadata is not the current deterministic export.');
} else {
  for (const [path, file] of planned) {
    const dest = resolve(packDir,path);
    await mkdir(dirname(dest),{recursive:true});
    if (!await exists(dest)) await copyFile(file.source,dest);
  }
  await writeFile(packPath,serialized);
}
console.log((check ? 'Verified' : 'Imported') + ' ' + candidates.length + ' concepts, ' + inputAssets.size + ' style inputs, and ' + candidates.length + ' exact prompts; originals preserved.');
