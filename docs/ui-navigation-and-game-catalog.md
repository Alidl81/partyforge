# UI Navigation and Game Catalog

## Navigation rules

- `/` is the root home screen and does not expose individual game cards.
- The primary **بازی** action opens `/play`.
- Every non-root screen contains a visible back button.
- Navigation from the app uses `context.push` so the normal route stack is preserved.
- `PartyBackButton` falls back to a safe route when a page is opened directly without history.
- `PartyScaffold` also handles the system back action when no route can be popped.

## Game discovery flow

1. Home
2. Play
3. Game selection
4. Either:
   - Game information
   - Start game
   - LAN setup for LAN-only games

Every catalog entry has:

- unique artwork;
- short and detailed descriptions;
- player-count metadata;
- local or LAN mode metadata;
- difficulty and tags;
- step-by-step instructions;
- an information action;
- a functional play or LAN action.

## Catalog

The catalog contains 12 games:

1. Chrono Lock
2. Hidden Fuse
3. Ghost Trace
4. Word Forge
5. Memory Grid (new)
6. Color Clash (new)
7. Number Rush (new)
8. Tap Storm (new)
9. Signal Snap
10. Shadow Path
11. Sketch Imposter
12. Split Control

The first eight have local play routes in this delivery. LAN-specific entries route to the multiplayer setup screen rather than presenting a fake or non-functional game screen.
