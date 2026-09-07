# Asian fox people: five female heroes, production design pass

Date: 2026-09-05. Status: concrete design proposal for review; no gameplay implementation or automatic art approval.

This is the current detailed proposal source for the existing Shiori Kaga, Natsume Rei, Hotaru Jin, Aoi Ten, and Tomoe Kiri. It preserves their names, concepts, and the current faction authority in `pirate-island-faction-system-current-authority.md`. The master character guide links here so their detailed mechanics have one maintained source. These proposed details do not override accepted global rules. Existing and newly generated portraits are variants until selected.

## Current individual art candidates

The main artist pass inspected all five v1 images. These are visible character proposals, not user-approved character photographs or proof that an ability is implemented. Exact generation prompts are preserved beside the other project prompts. Existing variants remain available.

### Shiori Kaga, v1

![Shiori Kaga v1](C:/Users/Admin/Documents/Codex/2026-09-04/pirate-island-work/outputs/assets/characters/provisional/shiori-kaga-v1.png)

[Exact image prompt](C:/Users/Admin/Documents/Codex/2026-09-04/pirate-island-work/outputs/prompts/shiori-kaga-v1.md). The red thread is visible but partly slack; the image should not be cited as proving a mechanically correct loaded tether. The intended combat keyframe below specifies the necessary tension and anchoring for later animation.

### Natsume Rei, v1

![Natsume Rei v1](C:/Users/Admin/Documents/Codex/2026-09-04/pirate-island-work/outputs/assets/characters/provisional/natsume-rei-v1.png)

[Exact image prompt](C:/Users/Admin/Documents/Codex/2026-09-04/pirate-island-work/outputs/prompts/natsume-rei-v1.md). Her mask is attached at a large column rather than the proposed small post. This is compatible with a reachable surface anchor; runtime range, mask visibility and destructibility must remain consistent.

### Hotaru Jin, v1

![Hotaru Jin v1](C:/Users/Admin/Documents/Codex/2026-09-04/pirate-island-work/outputs/assets/characters/provisional/hotaru-jin-v1.png)

[Exact image prompt](C:/Users/Admin/Documents/Codex/2026-09-04/pirate-island-work/outputs/prompts/hotaru-jin-v1.md). Staff, chain and recovery sled support the physical retrieval contract. The blue lantern offers identity and guidance; it does not promise that the pictured casualty is resurrected or exempt from midnight.

### Aoi Ten, v1

![Aoi Ten v1](C:/Users/Admin/Documents/Codex/2026-09-04/pirate-island-work/outputs/assets/characters/provisional/aoi-ten-v1.png)

[Exact image prompt](C:/Users/Admin/Documents/Codex/2026-09-04/pirate-island-work/outputs/prompts/aoi-ten-v1.md). Aoi is grounded while planting a stake. This gives a usable resolved pose for route placement; a separate preparation/rebound keyframe is still required to demonstrate the full movement.

### Tomoe Kiri, v1

![Tomoe Kiri v1](C:/Users/Admin/Documents/Codex/2026-09-04/pirate-island-work/outputs/assets/characters/provisional/tomoe-kiri-v1.png)

[Exact image prompt](C:/Users/Admin/Documents/Codex/2026-09-04/pirate-island-work/outputs/prompts/tomoe-kiri-v1.md). The bear reads as a distinct physical companion. Its presence in an illustration does not bypass the deployment, traversal, injury or persistent-death rules below.

## Critical assessment before revision

The five original concepts form a good faction, but several powers made promises an engineer could not implement honestly. Shiori's relationships risked becoming a universal movement web. Natsume's decoys risked reading the real world state and lying directly to the player UI. Hotaru nearly supplied free teleportation, resurrection, cleansing, and recruitment in one kit. Aoi nearly changed the navigation graph by drawing on it. Tomoe's persistent bear had no survival, deployment, or separation contract. Those are major mechanical problems, not matters of wording.

The revised identities are deliberately narrow. Shiori creates and punishes close fighting commitments. Natsume places believable false targets. Hotaru retrieves particular people. Aoi prepares fast, traversable escape lines. Tomoe makes enough physical room for people to get out. None is a general-purpose fox magician. They have different targeting shapes, different rhythms, and different failure conditions.

| Hero | Repeated decision | Strongest situation | Bad situation | Main expensive feature |
|---|---|---|---|---|
| Shiori | Which opponent can I isolate and turn? | One dangerous living melee fighter | Heavy ranged fire or area attacks | Directional parry and tether collision |
| Natsume | What will this observer believe next? | Patrols and loose ranged formations | Revealed anchors and disciplined hold fire | Per-observer decoy knowledge |
| Hotaru | Who can I physically bring home? | Scattered casualties near an escape route | Healthy living attackers closing on her | Persistent body identity and transport |
| Aoi | Which real route should the party use? | Intersections and broken cover | Roots, dead ends, blocked landings | Bounded route preview and validation |
| Tomoe | Where must a safe pocket move? | Civilian withdrawal through ground-level pressure | Elevated crossfire and confined passages | One persistent beast companion |

## Shared playable contract

All five are adult women: proposed ages 19–20 and heights within the established 4 feet 10 inches to 5 feet 3 inches range. Their romantic appeal comes from attractive distinct faces, confidence, personality, garment shape, and action. None is a minor or child-coded. Authored relationship quests create opportunities; combat effects never count as consent or as automatic romance progression. The main player party contains Michael and at most four women; these five fox women are a candidate pool, not a five-woman player-party composition. Tomoe's attached bear consumes no additional human character slot and never increases the four-woman limit.

Each has one basic action, four encounter powers, an ultimate, one party passive, and one strategic passive. They retain their kit and identity through allegiance changes. A woman's suitability for Michael can depend on circumstances, trust, story and recovery effort, but no permanent recruitment-immunity category is added. Fox women's wooing of living men uses the ordinary individual relationship system. A male follower never transfers to Michael merely because his fox partner does. Death and midnight processing remain authoritative over every hero ability.

The party remains represented by cards until the relevant member is presented as an active fighter. Abilities use authoritative encounter positions and targets even when the presentation emphasizes one fighter. Card presentation must not freeze the simulation or grant absent bodies immunity. Where a power requires an adjacent body, anchor or bear, the targeting preview must show that actual object; it cannot invent an offscreen helper.

The numerical values below are **initial prototype values**, chosen to make these mechanics testable. They are not claims of final balance. Distances use meters; durations and cooldowns use seconds; damage uses a normal basic hit as 1.0 damage. A normal combat action is approximately one second for this first pass. If the established combat clock changes, timings must be converted as a group. Cooldowns advance only with encounter simulation time, so normal pause freezes them. Strategic effects advance only with the campaign simulation.

All long actions have a visible windup and can be interrupted by the game's normal hard-interrupt state. Area indicators distinguish friend-safe zones, ordinary hostile zones, and physical hazards. Color is reinforced with line patterns and anchor shapes. Abilities cannot route through an unexplored room transition, solid wall, closed locked door or missing navigation connection. Unknown ground stays unknown. No skill reads omniscient strategic intent.

Party passives apply only while their owner belongs to the deployed party and is conscious, with any local range stated below. Duplicate copies use the strongest value, never multiply. Strategic passives require their stated assignment, buildings and supplies. Recruitment moves the hero, not existing buildings, subordinates or infrastructure. An unavailable, dead or captured hero cannot remotely perform ongoing strategic work.

## Shiori Kaga — The Red-Thread Duelist

### Character and narrative

Shiori is an accomplished matchmaker who enjoys dangerous people because she likes discovering the precise thing that makes them hesitate. Her warmth is genuine. Her habit of assuming she can arrange everyone's happiness is also genuinely irritating. She remembers an offhand preference six months later, notices a bad marriage before its participants admit it, and can turn a polite conversation into a duel without raising her voice. Her battlefield pleasure is the instant a boastful opponent realizes that their own forward step has trapped them.

Her personal story concerns a promise she encouraged two people to make when she had mistaken attraction for compatibility. Helping them requires protecting their choices, including a choice that damages her reputation. Michael's romance route tests whether she can become a participant with something to lose instead of directing everyone else's relationship. The quest changes trust and political outcomes; it does not spawn a recruit reward regardless of those people's decisions.

Proposed visual identity: age 20, 4 feet 11 inches, a slim adult with a compact heart-shaped face, russet ears, two elegant tails, and asymmetrically tied dark hair. Red and ivory short wrap layers, a fitted dark underlayer, exposed waist, narrow skirt panels over leggings, and practical soft boots retain the established design. Her crescent blade and physical red silk are her two dominant props. Thread knots should read at combat distance; decorative cords must not make all her clothing look like active weapons.

### Exact kit

**Basic — Crescent Blade.** A 1.8-meter melee cut, 1.0 damage. If a conscious ally is within 3 meters when the hit lands, recovery is 15% shorter. It does not stack per ally and a summon/illusion is not an ally for this check. This is a small reward for coordinated proximity, not her main damage engine.

**Power 1 — Silkstep.** Select a reachable point within 4 meters. After a 0.2-second tell, Shiori makes a fast ground step along the validated path and leaves one physical silk tripline between its endpoints for 5 seconds. She can slip past a light unit if there is real clearance; she never phases through collision. The first hostile moving across the line is slowed by 50% for 1 second and loses its current light movement action. Heavy actors receive only 20% slow and are never thrown down. The line breaks after triggering, after one deliberate hit, or when its endpoint is destroyed. Only one Silkstep line can exist. Cooldown 10 seconds. A blocked destination cancels without spending the cooldown; a later obstruction stops her at the last safe point and spends it.

**Power 2 — Red Thread.** Throw a visible silk weight at one enemy within 5 meters and line of sight. On hit it connects that enemy to a selected nearby fixed anchor or to Shiori for 6 seconds. There is no ally-target tether variant in the first implementation. The cord has 3 meters of slack. Beyond that, movement directly away from its anchor is 40% slower; at 5 meters it snaps. It never drags a heavy unit or moves the anchor. An enemy may spend one attack cutting the visible knot. Only one tether exists per Shiori. Cooldown 12 seconds. This ability works on physical male, female, beast, undead or machine bodies; it has no recruitment meaning.

**Power 3 — Turnabout.** Hold a 0.7-second frontal parry covering a 100-degree arc. The first blockable melee attack is stopped, and Shiori may make one 1.5-meter side step to an unoccupied point beside the attacker. The attacker retains its facing and suffers 0.6 seconds of recovery; Shiori does not rotate an unwilling actor as a cutscene. A successful side step grants her next basic hit within 2 seconds 30% extra damage. Projectiles, blasts, attacks from behind and tagged unbreakable blows beat the parry. Cooldown 9 seconds; failure still spends it.

**Power 4 — Invitation.** Mark one visible sapient hostile within 6 meters for 4 seconds and visibly lower her guard. While marked, Shiori takes 15% more damage from that target. If it begins a melee attack on her and she evades or parries it, that target receives `Exposed` for 2 seconds: the next allied direct hit deals 25% additional damage, then consumes the state. It cannot trigger from intentional friendly attacks, periodic damage or decoys. The AI evaluates this as a target opportunity, not compelled obedience; a ranged or cautious opponent may ignore her. Mindless units are invalid targets. Cooldown 14 seconds.

**Ultimate — Hundred Red Threads.** Shiori throws three large anchor knots to valid ground points within 6 meters, forming one triangular web for 10 seconds after a 0.8-second cast. The name is theatrical; the engine uses three edges, not a hundred simulated strings. Living or undead physical enemies crossing an edge receive 0.5 seconds of root, at most once per enemy per 3 seconds. Machines and large beasts receive 30% slow for 1 second instead. Allies crossing an intact edge receive 20% movement speed for 1.5 seconds; the buff refreshes without stacking. Each knot takes two deliberate ordinary hits to break, removing its adjacent edges. The web does no passive damage. Cooldown 70 seconds. It rewards chosen geometry and can be dismantled from range.

**Party passive — Shared Rhythm.** A party member who successfully evades an enemy melee hit grants the nearest other conscious party member within 3 meters a 15% speed bonus for 1 second. A recipient has a 5-second internal cooldown. This cannot trigger itself or turn one dodge into a chain of free turns.

**Strategic passive — House of Promises.** While personally assigned to a staffed fox household, Shiori can maintain one additional active courtship contact beyond that household's normal contact capacity. It consumes the same visits, safety, goods and relationship work as any other contact. It grants no success bonus or loyalty override. Existing participants persist when she leaves; extra scheduling capacity stops until capacity is restored. In Michael's faction she may help maintain existing diplomatic contacts, but this passive cannot recruit men into his faction.

### Art action and production limit

The keyframe is a tight turning parry: her crescent blade catches a saber, a visible red tether turns the enemy's forward commitment into a bad angle, and her short planted step keeps her balanced. Her smile belongs to the moment of discovery. The thread is physical gameplay equipment, not an abstract aura of romance. Show one readable line first, not a cloud of red ribbons.

Implement the tether and parry before the ultimate. The first playable proof is one opponent, one obstacle and two exit routes: it must be possible to escape her by cutting, backing carefully out, shooting an anchor, or refusing the invitation.

## Natsume Rei — The Maskmaker

### Character and narrative

Natsume is a theatrical craftswoman with immaculate timing and an untidy workbench. She enjoys impersonating vanity more than impersonating faces. She can be hilariously accurate about the way a commander waits for applause, but becomes evasive when anyone notices her own insecurity. Her masks are made by hand; the carved object establishes a limited stage on which the illusion works. She feels most exposed when someone recognizes her before she has chosen which version of herself to present.

Her story begins with masks made to protect evacuees being reused to conceal an actual disappearance. Recovering the workshop and tracing who used which mask produces testimony, suspects and consequences. Her romance develops through moments where she can say something plain and be believed. An illusion can open a route to a conversation; it cannot produce informed romantic agreement or rewrite a persistent relationship record.

Proposed visual identity: age 20, 5 feet tall, pale-gold ears, one enormous expressive tail, a sharp attractive face, straight short ink-black hair, indigo and plum layered performance garments, lattice sleeves and narrow wrap panels over fitted shorts. Five large recognizable masks are better than a belt crowded with tiny ornaments. Each gameplay face must have a silhouette readable without color.

### Exact kit

**Basic — Fan Edge.** Throw one real metal-edged fan up to 7 meters, dealing 0.7 damage to its first hit. It returns along a visible curve but does not damage again. Solid cover stops the outbound hit and the return becomes a safe recovery animation. Natsume cannot fire a second fan while this one is returning; the second carried fan is reserved for close defense.

**Power 1 — Empty Face.** Place one blank mask on a reachable surface within 4 meters. It projects one nondamaging copy of a nearby visible ally for 8 seconds. The copy repeats a selected simple behavior: hold, walk to a visible point, or make an attack gesture. No arbitrary recording system is required. The decoy has no body collision, cannot capture, interact, scout, trigger physical traps or block projectiles. One damaging hit, contact, or a successful close inspection reveals and destroys it for that observer; destroying its mask removes it for everyone. Limit two ordinary placed masks in total across powers. Cooldown 10 seconds.

**Power 2 — Laughing Face.** Send a carved laughing mask skittering along a validated ground path up to 6 meters. It emits one hostile-sounding call. An unengaged sapient observer within 5 meters turns to investigate for up to 1 second; an engaged enemy merely adds an uncertain sound observation and may refuse to turn. Each observer can be distracted by this power once per 12 seconds. Mindless, deaf or already-revealed observers ignore the call. It does no damage, charm, fear or forced targeting. Mask duration 4 seconds; cooldown 12 seconds.

**Power 3 — Weeping Face.** Hang a tear-marked mask within 4 meters. Its visible glass teardrops watch a narrow 60-degree, 5-meter cone for 10 seconds. A hostile crossing that cone creates a sharp reflected ripple: local concealment is suppressed for 2 seconds and its current outline remains visible to allies with line of sight to the ripple. It does not identify a disguised person's true allegiance or see through walls. No slow is included; that unrelated control effect diluted the kit. It occupies one ordinary mask slot and is destroyed by one deliberate hit. Cooldown 14 seconds.

**Power 4 — Beast Face.** Wear the physical beast mask for 5 seconds. Fan throws are replaced by 1.5-meter fan-claw cuts dealing 0.85 damage, and the first movement command may be a single 3-meter ground pounce. The pounce obeys collision and produces a 0.5-second stagger on its first light target. No actual transformation or summoned beast occurs. She is now making a dangerous real attack after encouraging the enemy to expect false ones. Cooldown 15 seconds.

**Ultimate — Festival of Faces.** After 1 second, project exactly three nondamaging actors from a single physical festival mask for 9 seconds. Natsume and those three actors follow separately chosen validated short routes; she remains fully physical and targetable. Actors cannot share her tracking marks, footprints or interactions. Each observer carries independent confidence about which actors are false. A damaged actor dissolves; a destroyed festival mask removes all three. The ultimate mask is a separate single slot, not three extra ordinary masks. It cannot manufacture reinforcements or strategic garrison counts. Cooldown 75 seconds.

**Party passive — Rehearsed Entrance.** The first direct attack against a party member within 2 seconds of that member leaving actual concealment deals 15% less damage. A member must remain unobserved for 6 seconds to reset it. Walking behind one thin post for a frame is insufficient. This reuses observed/unobserved state rather than adding random dodge immunity.

**Strategic passive — False Attendance.** While assigned to one veil shrine, Natsume can prepare one linked settlement's decoy muster. A distant visual-only scout receives a low-confidence garrison observation with up to one extra ordinary squad signature. The true population and the owner's UI never change. Entering the settlement, observing supply use over time, interviewing a resident or exposing a mask replaces the mistaken report with stronger evidence. Preparation needs her presence, staffed craft work and one decoy kit; it cannot be cast on arbitrary nodes from the strategic screen.

### Art action and production limit

She is low beside a waist-high stage post, sliding a carved mask onto its peg while an enemy thrusts a spear through the false woman beyond it. Her real fan and hands remain tangible; the false silhouette has no blood or impact. Her face says she saw this exact mistake coming. One false actor is enough for the image.

Decoy behavior is a perception system, not permission for arbitrary AI stupidity. Give agents observation confidence and a tested inspection action. A disciplined commander should improve against repeated use without becoming omniscient. Debug views must expose real bodies, mask anchors, observer beliefs and the evidence that changed them.

## Hotaru Jin — The Lantern Keeper

### Character and narrative

Hotaru is a determined recovery worker with a gentle face and a stubbornly practical manner. She knows how to tie a splint, move an adult body with a sled, recognize a forged name slip, and keep speaking calmly to someone who thinks they are already dead. She collects small ordinary details because those details help frightened people recognize themselves. Her quiet humor appears at the worst possible hours; she can complain about someone's boots while refusing to leave them behind.

She once brought the right body home with the wrong family's token attached. Correcting that record forces her to revisit a failed evacuation and confront the temptation to turn uncertainty into a comforting answer. A romance quest with Michael is built around returning for a person when the efficient decision is to leave. Success depends on actual rescue and honest choices, not a mandatory sacrificial death.

Proposed visual identity: age 20, 4 feet 10 inches, soft silver-brown ears and tail, large but adult-proportioned dark eyes, a long black braid with a few legible name slips, fitted charcoal-and-teal travel layers and narrow trousers. One distinctive blue lantern and its hooked chain dominate. She is warm and alive, neither a child medium nor a ghost bride.

### Exact kit

**Basic — Lantern Staff.** A 2-meter hooked-staff strike, 0.75 damage. A landed strike leaves a visible ember for 2 seconds, suppressing concealment on that target only. It does not reveal secret identity or cure madness.

**Power 1 — Name Flame.** Touch a conscious ally, downed ally, or identified allied body within 2 meters during a 0.6-second action. Attach one named ward for 20 seconds, maximum three live wards. It blocks one hostile `Possession` or `IdentityObscured` application and then breaks. If those states are absent from the implementation, the ward's shipped benefit is the tangible tracking tag, not invented immunity to all magic. It does not block death, madness accumulation, faction conversion already resolved, or midnight resurrection. Cooldown 8 seconds.

**Power 2 — Lantern Gate.** Place an entrance and exit marker up to 5 meters apart in the same room, each visible and joined by an already traversable path of at most 7 meters. After a 0.8-second preparation, one conscious willing ally can make a fast guided transit along that path; both markers extinguish. Transit is ground movement with normal collision, not teleportation. It cannot carry a body, cross a locked door, skip traps or enter unknown terrain. An exit that becomes blocked cancels before use; blocking it during transit stops the traveler at the last safe point. Markers last 8 seconds and can be destroyed with one hit. Cooldown 15 seconds. This narrow recovery lane preserves the lantern-gate motif without replacing hidden-gate buildings or Aoi's group route role.

**Power 3 — Ancestor Chain.** Hook one visible undead or spirit-bound physical target within 5 meters. For up to 4 seconds while Hotaru channels, tagged phase/blink abilities are disabled and movement away from her is slowed 35%. Ordinary attacks, projectiles and movement toward her remain available. The target can cut the chain with one deliberate attack; a wall breaking the line or a hard interrupt ends it. An incorporeal target must have a targetable manifested anchor; the skill cannot reach a hidden soul record. Cooldown 13 seconds. It does not change allegiance.

**Power 4 — Homeward Pull.** Connect the hook to one allied downed body or identified corpse within 5 meters, then reel it along a clear ground path at 1.5 meters per second for up to 4 seconds. Hotaru remains planted and can cancel to move. A living downed ally must be transportable; an awake ally uses normal movement. Heavy bodies require the ordinary sled or another helper and visibly reduce speed. Enemies, walls, closed doors and cliffs can block the path. No living enemy pull is included. Cooldown 10 seconds; a failed initial path spends nothing, a mid-pull interruption spends it. The exact persistent character and its body move together.

**Ultimate — All Names Answer.** Open the lantern for a 1-second cast, then a 6-second channel in a 6-meter radius. Known allied casualties in that radius display their names and last verified life state. Downed living allies pause their bleed-out timer only while the channel remains active. Corpses receive no restored health and their midnight deadline continues. False decoys inside the radius flicker visibly, permitting ordinary inspection, without remote mask destruction. One identified former ally now raised as undead may receive a 2-second recognition hesitation if it lacks an active command override; this stops its next attack once but neither transfers nor cleanses it. Recognition is a proposed optional extension, disabled until an explicit raised-person identity query exists. Cooldown 80 seconds.

**Party passive — Names Remembered.** Known party casualties in the current room retain a last-seen marker and can be highlighted through foliage or smoke within 10 meters of conscious Hotaru. The highlight tracks a body only while the existing name ward is intact or an allied observer currently sees it. Otherwise it is explicitly a last-known position. It cannot report an unseen corpse being carried elsewhere as live intelligence.

**Strategic passive — Kept Register.** While Hotaru is assigned to an operating ancestor lantern house, she can verify one additional casualty record per normal identification cycle, using the existing staff and materials. Verified records carry the same stable person ID through transports and reduce rejected or mismatched recovery jobs. She adds no resurrection capacity, grants no new body access and suspends no deadline. Missing or corrupted records must be investigated rather than silently repaired from omniscient state.

### Art action and production limit

Show Hotaru braced on a wet shrine path, blue lantern low and chain taut, drawing a wounded adult on a small practical recovery sled toward shelter. Her beautiful face shows reassuring determination. The casualty's weight and the chain direction are essential. Do not illustrate levitation, a soul flying into her lantern, or someone restored from death; none is her ordinary action.

This is the highest continuity risk in the set. Every power must be tested across death, faction transfer, save/load and midnight. A body beside an operating lantern still rises for Cthulhu if the authoritative restoration job has not completed in time. A player must never read a blue tag as proof that the person is safe from midnight.

## Aoi Ten — The Foxfire Courier

### Character and narrative

Aoi is a competitive route runner who remembers a settlement by its awkward landings and the food waiting at the far end. She likes arriving with a grin while everyone else is still arguing about whether the road is usable. That delight is undercut by impatience: she can mistake a route she can survive for one a frightened family can follow. Her best development is learning that a courier's achievement is measured by what arrives, not by how spectacularly she ran.

Her story asks her to reopen a route carrying three different needs: a warning, a medicine delivery and displaced civilians. They cannot all use the same shortcut. Michael can help by testing the route, carrying a slower traveler or resisting a tempting chase. The romance emerges from sharing a rhythm and making room for another person's pace.

Proposed visual identity: age 19, 5 feet 1 inch, slim runner's build, copper ears, three streaming tails, cropped dark hair and a lively angular face. Saffron and blue sleeveless wrapped courier layers, narrow running trousers, wrapped calves, a secure sealed dispatch cylinder, one light spear and small foxfire stakes. Her silhouette is forward and compact, not an acrobat stretched across the whole picture.

### Exact kit

**Basic — Running Spear.** A 2.5-meter thrust, 0.85 damage. Moving at normal run speed for at least 1 second before impact adds 30% stagger, not damage. There is no freely thrown replacement spear; Spearpost owns that decision.

**Power 1 — Blue Streak.** Preview and sprint a straight traversable ground segment up to 7 meters at 140% normal speed. Leave three physical route sparks lasting 7 seconds. Allies passing within 0.8 meters receive the party passive; enemies touching the trail lose concealment for 1.5 seconds. Sparks do no damage. Water deeper than the local wading threshold and a closed passage invalidate the segment; ordinary rain changes the visuals but does not randomly extinguish it. Limit three ordinary sparks. Cooldown 10 seconds.

**Power 2 — Spearpost.** Plant or throw her real spear into a valid point within 5 meters. It becomes one sturdy route beacon for 8 seconds, revealing only its already visible local ground. Aoi switches to a weak 1-meter knife basic, 0.4 damage. Reactivation recalls the spear along an unobstructed line, dealing 0.8 damage to the first enemy hit and returning her normal basic. A blocked return causes the spear to remain physically present; she must retrieve it or clear the line. An enemy may dislodge the beacon, ending its route effect without deleting her equipment. Cooldown 12 seconds starts when the spear is recovered. No duplicated spear objects.

**Power 3 — Wallskip.** Choose an authored vault/rebound edge within 3 meters and a validated landing within 3 meters beyond it. Aoi makes one low vault or angled rebound, preserving her movement momentum. Both endpoints and the landing arc are previewed before activation. It cannot use arbitrary walls, actors, room exits, unclimbable cliffs or a distant unseen landing. A blocked landing disables the target before spending the action. Cooldown 8 seconds. This reuses a finite set of traversal links instead of solving arbitrary parkour geometry.

**Power 4 — False Trail.** At one of her active ordinary sparks, place a false fork up to 4 meters along reachable ground for 5 seconds. It produces misleading foxfire footprints and a receding sound, not an ally actor. Enemies that have lost sight of Aoi may add it as a low-confidence pursuit route. Enemies currently seeing her cannot be made to forget that observation. A tracker can inspect the fork; physical footprints or a route ending against cover expose it. It never changes the navigation graph or the player's waypoint. Cooldown 14 seconds.

**Ultimate — Nine-Turn Circuit.** Select a start and up to three visible waypoints within the room, with total traversable length at most 18 meters. After a 0.5-second windup Aoi runs that course at 170% speed. The title describes her practiced technique, not a requirement to click nine points. Each completed waypoint deposits one bright junction for 10 seconds; together they grant allies 25% movement speed and ignore ordinary shallow-mud/brush slowing while following the validated segments. The strongest route bonus applies, never both. Aoi can be hit and stopped; completed junctions persist, unvisited ones never appear. Each junction takes one enemy interaction or hit to extinguish. No invulnerability, teleportation or collision bypass. Cooldown 70 seconds.

**Party passive — Follow the Spark.** A conscious party member passing through one of Aoi's active ordinary sparks gains 15% movement speed and ignores light brush/shallow-mud slow for 2 seconds. Repeated sparks refresh duration; they do not stack. Roots, deep water, cliffs and damaged legs remain effective. Junctions from her ultimate use their stated stronger effect.

**Strategic passive — Impossible Dispatch.** Once Aoi physically completes an existing risky graph edge, her assigned pathfinder lodge may publish that edge as a timed courier route for compatible light runners. Proposed lifetime is one in-game day or until a reported obstruction. This improves route knowledge, not topology. The route retains its actual hazards, capacity and unit tags; wagons, bears, armies and civilians cannot inherit her vault access. Aoi or another qualified scout must recheck it after collapse, capture or weather state invalidates it.

### Art action and production limit

Show a low wall rebound finishing in a compact landing, her hand driving a blue-flame route stake into the earth while the spear stays readable in the other hand. A visible trail shows where she came from and where the route turns next. The sealed message stays attached. Her grin is earned by the maneuver. Avoid a airborne downward dive or a decorative ribbon of fire that crosses solid stone.

Marisol solves long transport and communication with a persistent horse and frontier riding skill. Aoi prepares short local paths with foxfire and known traversal edges. She does not gain horse endurance, mounted shooting, animal transport or universal road creation. Her encounter role is route preparation first and damage second.

## Tomoe Kiri — The Moon-Bear Keeper

### Character and narrative

Tomoe is patient in the way that comes from handling something stronger than herself every day. She does not confuse gentleness with indulgence. She knows exactly when to stand still, when to yield a step and when to put the glaive across a doorway. The bear is affectionate, inconvenient, territorial, occasionally frightened and capable of refusing a bad command. Their comfort together is attractive because it reveals a life beyond fighting: harness adjustments, brush strokes, stolen rations, quiet shared rest.

Her personal story concerns the settlement that once wanted the bear dead now wanting to use it as an expendable weapon. She must defend both the people and the animal without pretending their needs always agree. Michael earns intimacy by becoming someone the pair can rest around, not by defeating the animal or proving dominance. No new proper name is assigned to the bear in this pass.

Proposed visual identity: age 20, 5 feet 3 inches, compact and slim with credible planted strength, dark umber ears, one thick tail, a broad-soft beautiful adult face and a heavy black braid. Moss and rust fitted handler layers over a wrapped top, reinforced narrow trousers, practical gloves and a broad-bladed glaive. The natural moon bear is large and powerful, not a hulking monster or substitute for her silhouette. Its harness has real pressure points and room for movement.

### Persistent bear contract

The bear has a stable animal ID, health, wounds, morale, location and equipment. It is not conjured, duplicated on load or replaced when a cooldown finishes. Tomoe occupies one party character slot; the bear is her attached controlled companion and appears only where it can physically reach. On deployment the interface shows whether it is accompanying her, waiting, injured, captured or dead. It is not a sixth human party member or a romance participant.

There is one direct command channel: follow, hold, move, guard or the current hero power. New commands replace queued ones. The bear retains self-preservation and can panic under the existing morale rules; it does not independently query the whole strategic map. A narrow doorway may make Tomoe continue without it or require another route. If separated, bear-dependent powers are disabled with its real location/status. Her glaive and ordinary movement remain usable.

Animal death is unresolved in the current global wording. Conservative proposal: if the game includes beasts in the midnight eligible-personnel rule, the bear must enter the same death pipeline; if beasts are excluded globally, that exclusion applies to all comparable beasts. This document grants no special immunity or automatic respawn. Until that island-wide choice is resolved, the prototype must preserve a dead bear record and offer no replacement button. The user should not be forced to discover this rule by losing it.

### Exact kit

**Basic — Keeper's Glaive.** A 2.5-meter sweep across a 75-degree frontal arc, 0.7 damage to at most two targets. A hit on a light enemy approaching the bear adds a small 0.3-second movement interruption, at most once per enemy per 4 seconds. It cannot stunlock a doorway indefinitely.

**Power 1 — Shoulder Together.** Select Tomoe's position or the bear's reachable position within 6 meters as a rally point. Both take normal ground paths toward a paired formation for up to 3 seconds. The bear's last meter gently displaces light units only if those units have a free adjacent landing; otherwise it stops. It never shoves bodies through walls, bridges a chasm or teleports to her. Once both arrive, each gains 15% damage reduction for 3 seconds. Cooldown 12 seconds. The power can be interrupted by attacking or issuing a different move.

**Power 2 — No Closer.** Tomoe sets her glaive and the adjacent bear braces behind her in a 90-degree frontal zone extending 3 meters for 3 seconds. The first light hostile entering takes 0.6 damage and is pushed 1.5 meters toward a valid landing. Heavy actors receive a 0.5-second stagger instead. One successful interception ends the stance. It has no rear protection and does not stop bullets. Requires bear within 2 meters and a clear stance footprint. Cooldown 10 seconds.

**Power 3 — Scent the False.** Order the bear to inspect one visible actor, object or last-known track point within 6 meters. It approaches and sniffs for 1.5 seconds. A scentless image is revealed locally as a decoy. An ordinary disguised person remains a person; the bear may match a previously learned individual scent but cannot infer allegiance, guilt, romance or secret intentions. Heavy rain, strong conflicting odors and lack of a scent record produce `Inconclusive`, not an invented answer. The investigation can be interrupted and gives away the bear's position. Cooldown 8 seconds.

**Power 4 — Honey and Blood.** Spend one carried beast-care ration and channel for 3 seconds within 1.5 meters of the bear or a willing allied animal. It restores 15% maximum health and 20 morale over the channel, ending early if Tomoe moves or is hard-interrupted. Damage does not magically vanish: critical wounds still require ordinary treatment and cannot be removed by this skill. Initial carried capacity three rations, replenished from actual supplies at a suitable camp. Cooldown 18 seconds. No effect on dead animals or machines.

**Ultimate — The Den Walks.** Choose a traversable straight advance up to 8 meters with enough width for the bear. For up to 6 seconds it advances at 65% run speed while Tomoe accompanies its flank. The bear receives 35% frontal damage reduction and can shove light blockers by up to 1 meter if safe space exists. Allies in its actual rear cover region gain ordinary line-of-fire protection from its body, not an abstract all-angle shield. Rear and elevated attacks remain dangerous; strong fire or morale collapse can end the advance. Tomoe moving more than 3 meters away ends coordinated protection. It neither enlarges the bear nor grants temporary health. Cooldown 85 seconds.

**Party passive — Gentle Hands.** Conscious party members and attached living animals within 5 meters recover morale 20% faster during ordinary recovery opportunities and suffer 10% less morale loss from taking damage. This does not prevent panic, madness, recruitment or death. The bear's own presence is not required for this passive; it comes from Tomoe's calming behavior.

**Strategic passive — Shared Dens.** While assigned to a staffed beast garden, Tomoe can oversee one additional animal recovery/relocation job alongside the garden's normal work. The animal still requires a real shelter berth, feed, handler and traversable route appropriate to its size. The passive adds scheduling attention, not hidden storage or free beasts. When deployed elsewhere, already dispatched jobs continue using their real staff, while the extra scheduling slot closes.

### Art action and production limit

Tomoe makes a short planted glaive sweep protecting the bear's exposed flank while it shoulders loose timber aside to open a passage for villagers. The motion reads as practiced cooperation. Her body is slim and short but her feet, grip and leverage are convincing. Do not have her casually lift the bear, summon it from smoke or control it with glowing domination strings.

Prototype one bear, one broad path and one deliberately impassable narrow route. The pair must separate honestly. Add the ultimate only after collision, command replacement, panic and persistent injury work. This is more expensive than a summoned unit but remains bounded if the game commits to one persistent attached animal instead of a general animal society simulation.

## Shared production and QA contracts

### Minimal authored and runtime data

Every ability definition needs an immutable ID, owner ID, target category, range, line-of-sight rule, windup, duration, cooldown, resource cost, allowed movement tags, state applications, stacking policy, interruption rules, AI scoring inputs and presentation cues. Actor and ability names are presentation strings, never identity keys.

Runtime anchors carry owner/faction ID, room and position, lifespan, health or interaction count, link endpoints and visibility. Perception records carry observer ID, observed object, observation kind, confidence, location, timestamp and evidence that exposed it. Knowledge may be wrong; population records never are. Body references use the same stable character ID before and after recovery, raising and recruitment. Bear state is saved as one persistent animal, not serialized inside each ability.

Save/load preserves cooldown remaining, timed states, existing masks/threads/sparks, ownership, body transport, bear location and per-observer exposed-decoy knowledge. If saving during a move/channel is not supported by the encounter engine, save at its next stable tick with the visible action outcome; never silently duplicate a body or reset consumed supplies. A faction change clears old hostile targeting and reevaluates anchor hostility on the next simulation tick. Ownership of already placed equipment is explicit; it does not automatically turn into a remote attack against former allies without a normal hostile-action decision.

### Individuality at card and action scale

Each card crop must preserve a face, distinctive hair/ear shape and one identifying prop: Shiori's red knot; Natsume's carved mask; Hotaru's blue lantern; Aoi's stake/message cylinder; Tomoe's glaive and a readable portion of the bear. Do not require a full action plate to recognize the character. Tails vary in count as established art identity, not as an unstated power-tier system.

Action keyframes need preparation, contact and resolved poses. Shiori has a planted pivot and released tension. Natsume has placement, mistaken enemy impact and an exposed mask. Hotaru has hook attachment, weighted pull and casualty in shelter. Aoi has route choice, low rebound and stable landing. Tomoe has paired stance, physical pressure and space opening behind them. Each sequence should still make sense without visual effects.

### Demonstrable slice order

1. Shiori against one melee enemy: validate facing, cuttable tether, obstacles and refusal of bait.
2. Natsume against two observers: one sees a mask exposed while the other remains uncertain; neither sees through walls or damages a real body through its decoy.
3. Hotaru with one living casualty and one corpse: move exact bodies, preserve records, cross midnight, and prove a lantern ward does not prevent Cthulhu's legitimate acquisition.
4. Aoi with one valid and one invalid route: clear preview, normal collision, no route creation, limited actor traversal tags and interrupted-circuit behavior.
5. Tomoe with one bear: passage width, separation, panic, rations, death persistence and no duplicate summon.

Only after these pass should the player-party combinations be tested: Michael plus at most four chosen fox women. Test all five choices of omitted fox hero to expose the cost of each missing specialty. Evaluate chained control against a heavy enemy, repeated reveal effects against Natsume, combined route bonuses, recovery throughput and the opportunity cost of filling all four companion slots with utility-heavy heroes. These compositions should struggle against sustained ranged damage and siege rather than secretly covering every weakness through their ultimates. A separate five-hero fox faction squad may be tested under the ordinary RTS squad rules; it is never presented as the player's main party. Tomoe's attached bear follows its companion contract rather than consuming or creating a sixth character slot.

### Review ledger

Preserved: the five existing names and titles; distinct physical masks, red thread, lantern recovery, foxfire routes and one living bear; adult petite cast direction; four powers plus ultimate and two passive layers; allegiance and relationship boundaries; authoritative midnight consequences.

Proposed improvements: concrete timers and targets, finite anchors, physical route limits, observer-based deception, no generic sorrow slow, no enemy corpse-retrieval substitution, no unlimited soul recall, no arbitrary parkour, explicit bear persistence. These need gameplay testing and user review rather than being treated as final balance.

Open global decisions: exact shared action clock and damage model; which spirit/possession states will actually ship; whether ordinary beasts are eligible for midnight raising; encounter save granularity; precise common cooldown/resource economy. None should be hidden inside a portrait prompt or resolved by generating an attractive image.

New images based on these briefs are visual candidates. They demonstrate silhouette, personality, period-derived clothing and a readable action. They cannot prove targeting, AI, resurrection, recruiting behavior or completed animation. Keep all earlier approved and candidate images available as requested; do not overwrite them when recording a newer variant.
