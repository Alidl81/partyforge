# ADR-001: Domain boundaries

## Decision

Game rules are pure Dart. Domain code cannot import Flutter widgets, `BuildContext`, Drift, sockets, platform channels, or wall-clock APIs. Each game accepts immutable state, a command, game context, seeded random input, and authoritative monotonic time; it returns a new state plus immutable events.

UI controllers translate gestures into commands. They never mutate scores directly. Persistence consumes domain events after a transition succeeds. In LAN mode, only the host executes authoritative transitions and score calculation.

## Consequences

- Replays can be rebuilt from seed plus ordered command log.
- Local and LAN modes share the same game implementation.
- Rendering can be changed without changing scoring.
- Database and network tests can use fake clocks and deterministic random generators.
