# ADR-003: Determinism and time

All gameplay randomness is produced by `SplitMix64Random` from a match seed. No game rule may create `Random()` internally. Match duration uses a monotonic clock; `DateTime.now()` is reserved for persistence timestamps and token expiry.

Clock synchronization collects at least seven ping/pong samples, sorts by round-trip time, keeps the best subset, estimates a weighted offset, and records uncertainty. Signal Snap compares host-normalized input times and declares a tie when separation is inside uncertainty.

Frame rate never advances authoritative simulation. Tick-driven games apply commands at explicit ticks, and replay uses the same seed and command order.
