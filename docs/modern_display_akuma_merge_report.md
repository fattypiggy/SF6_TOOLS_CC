# Akuma Official Modern Display Merge Report

This report documents the manual-safe merge from the Capcom official candidate into the formal Akuma modern display mapping. Existing verified sample mappings were not blindly overwritten.

## Summary

- Formal action_id count before merge: 13
- Official candidate action_id count: 104
- Formal action_id count after merge: 108
- Added capcom_official action_id count: 95
- Preserved community_sample/manual_verified action_id count: 13
- classic_only action_id count after merge: 30

## Official Additions

- `17`
- `18`
- `480`
- `600`
- `601`
- `602`
- `608`
- `611`
- `614`
- `615`
- `622`
- `623`
- `624`
- `627`
- `630`
- `635`
- `636`
- `637`
- `640`
- `643`
- `650`
- `651`
- `652`
- `653`
- `654`
- `655`
- `657`
- `661`
- `664`
- `667`
- `668`
- `669`
- `671`
- `715`
- `717`
- `739`
- `740`
- `850`
- `854`
- `900`
- `901`
- `902`
- `943`
- `944`
- `945`
- `947`
- `949`
- `962`
- `963`
- `964`
- `973`
- `974`
- `975`
- `976`
- `977`
- `979`
- `980`
- `987`
- `988`
- `989`
- `995`
- `996`
- `997`
- `998`
- `1001`
- `1002`
- `1003`
- `1013`
- `1015`
- `1018`
- `1023`
- `1026`
- `1029`
- `1075`
- `1081`
- `1087`
- `1158`
- `1159`
- `1160`
- `1162`
- `1163`
- `1165`
- `1166`
- `1200`
- `1208`
- `1213`
- `1214`
- `1220`
- `1221`
- `1225`
- `1231`
- `1240`
- `1244`
- `1495`
- `1497`

## Preserved Verified Sample IDs

- `605`
- `606`
- `617`
- `672`
- `903`
- `952`
- `961`
- `978`
- `986`
- `992`
- `1022`
- `1027`
- `1226`

## Official Candidate Missing But Sample Kept

- `672`
- `952`
- `992`
- `1022`

These IDs are kept because verified modern samples require them. They may be internal follow-ups, aerial/contextual actions, OD routes, or sample-derived actions not exposed directly in the public candidate table.

## Official Conflict Kept As Verified Display

- `606`
- `903`
- `986`
- `1027`
- `1226`

For these IDs, the current formal `modern_display` remains preferred because it was verified in-game against modern control samples. Official candidate values were recorded in `note` only.

## Classic Only IDs

- `601`
- `602`
- `623`
- `624`
- `627`
- `636`
- `637`
- `661`
- `949`
- `973`
- `975`
- `977`
- `979`
- `988`
- `1001`
- `1002`
- `1003`
- `1158`
- `1159`
- `1160`
- `1162`
- `1163`
- `1165`
- `1166`
- `1214`
- `1221`
- `1240`
- `1244`
- `1495`
- `1497`

## Runtime Scope

- Lua display logic was not changed.
- Validator, ActionMatcher, PendingAbsorb, timeline, recorder flow, and auto demo were not changed.
- The formal mapping was merged from structured JSON; the candidate file was not copied over the formal file.
