PartyForge build stability patch

Changes:
1) Fixes prefer_initializing_formals in LanRoomBroadcaster.
2) Runs flutter analyze --no-fatal-infos on both Android and Windows.
   Errors and warnings still fail Analyze; informational lints no longer block release builds.

Apply this archive at the repository root, replacing the two matching files.
Then commit/push and start a NEW workflow run.
