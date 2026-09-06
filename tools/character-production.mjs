import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const hash = value => createHash('sha256').update(value).digest('hex');
const ordered = values => [...values].sort((a, b) => a < b ? -1 : a > b ? 1 : 0);
export const guilds = ['Barbarian', 'Bard', 'Cleric', 'Commoner', 'Empath', 'Moon Mage', 'Necromancer', 'Paladin', 'Ranger', 'Thief', 'Trader', 'Warrior Mage'];
export const policies = {
  dragonrealms: { eras: ['ancient', 'medieval', 'renaissance', 'early-modern'], forbidden: ['firearm', 'modern', 'steampunk'], },
  'pirate-island': { eras: ['ancient', 'medieval', 'renaissance', 'early-modern', 'industrial-1870s', 'fantasy-steampunk'], forbidden: ['modern'], },
};

// Fail closed. A date alone cannot legalize a gun in DragonRealms.
// This is an admission check, not a replacement for geometry/fit review.
export function admission(asset, consumer) {
  const policy = policies[consumer];
  if (!policy) return ['Unknown consumer'];
  if (!asset || typeof asset !== 'object') return ['Missing asset record'];
  const errors = [];
  if (asset.status !== 'approved') errors.push('Asset is not approved');
  if (!Array.isArray(asset.consumers) || !asset.consumers.includes(consumer)) errors.push('Consumer approval missing');
  if (!policy.eras.includes(asset.era)) errors.push('Era not admitted');
  if (!Array.isArray(asset.tags)) errors.push('Explicit content tags required');
  else for (const tag of policy.forbidden) if (asset.tags.includes(tag)) errors.push('Forbidden content: ' + tag);
  if (typeof asset.sourceSha256 !== 'string' || !/^[a-f0-9]{64}$/.test(asset.sourceSha256)) errors.push('Source fingerprint missing');
  if (typeof asset.license !== 'string' || !asset.license.trim()) errors.push('License missing');
  if (![asset.fitReview, asset.visualReview].every(v => typeof v === 'string' && v.trim())) errors.push('Fit and visual review required');
  return errors;
}

// Exact page titles are identity: numbered creatures must never merge by noun.
export function buildInventory(data, sources) {
  const entries = [];
  const add = (kind, title, records) => {
    const facts = records.filter(Boolean);
    const bodyTypes = ordered(new Set(facts.flatMap(r => [r.BodyType, r.BodyType2, r['Body type is']]).filter(Boolean)));
    entries.push({ id: 'dr.' + kind + '.' + hash(title).slice(0, 20), kind, title,
      url: 'https://elanthipedia.play.net/' + encodeURIComponent((facts[0]?.page || title).replaceAll(' ', '_')),
      sourceBodyTypes: bodyTypes, constructionStatus: 'unassessed', approvedAssetIds: [] });
  };
  for (const title of ordered(Object.keys(data.races))) add('race', title, [data.races[title]]);
  for (const title of ordered(new Set([...Object.keys(data.creatures), ...Object.keys(data.bestiary)]))) add('creature', title, [data.creatures[title], data.bestiary[title]]);
  for (const title of ordered(Object.keys(data.npcs))) add('npc', title, [data.npcs[title]]);
  return { schemaVersion: 1, consumer: 'dragonrealms', scope: 'Local Elanthipedia cache snapshot, not a claim of exhaustive live-world coverage',
    sources, guildSource: 'https://elanthipedia.play.net/Category:Guilds', guilds,
    humanoidPresentationVariants: ['female', 'male'],
    variationRule: 'Race, guild and presentation are separate appearance axes, not generated identities or anatomy claims. Creature sex remains unassessed unless sourced. Commoner is unguilded.',
    counts: { races: Object.keys(data.races).length, creatures: entries.filter(e => e.kind === 'creature').length, npcs: Object.keys(data.npcs).length }, entries };
}

export function importInventory(input) {
  const data = {}, sources = [];
  for (const name of ['races', 'creatures', 'bestiary', 'npcs']) {
    const bytes = readFileSync(resolve(input, name + '.json'));
    data[name] = JSON.parse(bytes);
    if (!data[name] || Array.isArray(data[name]) || typeof data[name] !== 'object') throw Error('Expected title map: ' + name);
    sources.push({ file: name + '.json', sha256: hash(bytes), records: Object.keys(data[name]).length });
  }
  return buildInventory(data, sources);
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  if (process.argv[2] === '--admit') {
    const [, , , manifest, consumer] = process.argv;
    if (!manifest || !consumer) throw Error('Usage: --admit <asset-record.json> <consumer>');
    const errors = admission(JSON.parse(readFileSync(manifest)), consumer);
    console.log(JSON.stringify({ consumer, eligible: errors.length === 0, errors }, null, 2));
    process.exit(errors.length ? 1 : 0);
  }
  const [input, output] = process.argv.slice(2);
  if (!input || !output) throw Error('Usage: node tools/character-production.mjs <elanthipedia-cache-directory> <output.json>');
  const inventory = importInventory(input);
  mkdirSync(dirname(resolve(output)), { recursive: true });
  writeFileSync(output, JSON.stringify(inventory, null, 2) + '\n');
  console.log(JSON.stringify(inventory.counts));
}
