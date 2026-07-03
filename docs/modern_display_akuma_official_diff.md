# Akuma Official Modern Display Diff

This report compares the Capcom official generated candidate with the current runtime mapping.

## Summary

- Official candidate action_id count: 104
- Current Akuma.json action_id count: 13
- Official-only action_id count: 95
- Current-only action_id count: 4
- modern_display mismatch count: 5
- classic_only action_id count: 32
- needs-review action_id count: 35

## Official Candidate Adds

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

## Current Mapping Not Found In Official Candidate

- `672`
- `952`
- `992`
- `1022`

## Modern Display Mismatches

| action_id | current | official candidate |
| --- | --- | --- |
| `606` | `> 中` | `中 > 中` |
| `903` | `AUTO + SP` | `AUTO + SP/236 + 攻撃二つ` |
| `986` | `> 6 + 攻撃` | `null` |
| `1027` | `空中 4 + AUTO + SP` | `空中 4 + AUTO + SP/空中 214 + 攻撃二つ` |
| `1226` | `2 + SP + 強` | `null` |

## Classic Only In Official Candidate

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
- `986`
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
- `1226`
- `1240`
- `1244`
- `1495`
- `1497`

## Needs Manual Review

- `601`
- `602`
- `623`
- `624`
- `627`
- `636`
- `637`
- `661`
- `903`
- `949`
- `973`
- `975`
- `977`
- `978`
- `979`
- `986`
- `988`
- `1001`
- `1002`
- `1003`
- `1027`
- `1158`
- `1159`
- `1160`
- `1162`
- `1163`
- `1165`
- `1166`
- `1214`
- `1221`
- `1226`
- `1240`
- `1244`
- `1495`
- `1497`

## Current Sample Supplements Not Covered By Official Modern Command

- `672`
- `952`
- `986`
- `992`
- `1022`
- `1226`

Notes:

- This report does not modify `data/TrainingComboTrials_data/modern_display/Akuma.json`.
- `攻撃` is preserved in official candidates and marked for review instead of being forced to `強`.
- Current-only IDs may be contextual, sample-derived, or absent from the public official table.
