# Forward colonial fort placement candidate

**Status: development placement approved by root after visual review, 2026-09-08.** The full and detail images are static composites, not engine renders. Approval concerns placement at [22,10], not completed runtime construction or final art.

Proposed entrance [22,10] at pixel[720,336]. Reuses actual runtime watch_fort.png unchanged:1125x928 RGBA, SHA25634c8f250350f73f4cb6ae78c82a7bf9aca4266040a221d60e40e9f2527494c56. Display150px, scale0.1333333333, pivot[775,825]. Same offsets[[-2,-1],[-1,-1],[0,-1],[-2,0],[-1,0]]. No new artwork or actual new runtime holding.

Source viewed first. Full placement-review.png and3x placement-detail.png inspected: foundation lies in open inland grass beside paths, south of the northern tree line and north of the central jungle obstacle. No palms or water beneath the foundation. Roof clears neighboring canopy silhouettes; actual150px fort remains legible. No overlap with existing holdings or Michael's reviewed19,17workshop/start20,18. Optional workshop shown illustratively, not assumed already built.

The static navigation audit reuses heart-grove-01/placement_review.py in memory with this entrance, pivot, source, crop and current holding inputs; no duplicate renderer was installed. Script SHA256:9c9e245b60434d05682b4ee9b7cf0f76af0c17de13a7fd5cb6c6ea7381d3b94a. All five footprint cells lie on existing land, without existing building overlap. The entrance is reachable in 20 cardinal steps from the contested clearing [20,18]. The first fort is 22 steps from that clearing under the same final mask, so this expansion is modestly closer. Straight Manhattan separations from the new entrance: first fort10; fox market12; shrine11; workshop10; Michael start10; grove21; quay24. Those separations are not path lengths.

Currentfirstfort correction:12,11 is the nativepreferred position, not a valid landcell in currentmask. Native installation chooses nearest connected cell because that archetype has no exactplacement override. Static audit reproduces12,10 as nearestvalid; finalcomposite andcollision audit use12,10, not12,11. Verify actualsnapshot duringroot integration. Other holdings use their authoredexactentrances. This correction does not relocate anything in runtime.

Exactsource/terrain/navigation hashes andlegalcellresults inplacement.json. Terrain untouched. These images are staticcompositions, not enginecaptures. Root must validate actualnative expansionplacement/route and costs beforeadmission. This task did not implement construction or claim ownershipofthenewholding.
