# North weaponsmith frontage: reuse binding, not new art

Read actual North room 1-14 description and map edge `go weaponsmith's -> 191`. The connected map room is Milgrym's Weapons, Showroom; however the local delivered 1-191 room text incorrectly names Berolt's Dry Goods. Reported this mismatch to parent and did not treat it as weaponsmith evidence.

Verified [Milgrym's Weapons](https://elanthipedia.play.net/Milgrym%27s_Weapons) on 2026-09-08: showroom described as plain and businesslike; weapon stock is displayed on pine surfaces. That establishes a restrained commercial character, not an exterior material or roof design. Page room ID 19801 and local graph room 191 are different identifier namespaces, not interchangeable IDs.

Inspected existing whole plain timber workshop sprite. It already supplies an intact modest exterior, no text signs, and a front-left threshold aligned to the North path's lower-left approach. Reuse it byte-identically through kit.json rather than generating another arbitrary building or duplicating the PNG. Its original actual Cattle Trail references, generation prompts, source hash, extraction and visual review remain in crossing-building-fronts-01/GENERATION.md.

No new image generation. Timber, roof, window and closed-door appearance remain explicit artistic interpretations. No exterior weapons display added: pine merchandise surfaces are interior evidence, not authority for exterior racks. Source-scale image inspected; source identity is unchanged.

Estimated door anchor [136,420] binds to current cobblestone far endpoint [678.75,464.25] at uniform scale .8, giving source origin [569.95,128.25] and ordinary pivot [721.95,469.85]. Parent must handle the hedge opening deliberately; the current continuous hedge run overlaps the doorway approach. Do not claim the composition solves that occlusion or that the path direction is an authoritative compass direction. No collision geometry or runtime admission.
