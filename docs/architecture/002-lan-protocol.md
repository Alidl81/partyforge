# ADR-002: LAN authority and protocol

The Windows or Android host binds an available TCP port using `HttpServer` and upgrades `/ws` to WebSocket. Every message uses a versioned envelope with `messageId`, `sessionId`, `playerId`, `sequence`, client monotonic timestamp, type, and payload.

Clients send inputs and commands only. The host validates identity, session, protocol version, duplication, ordering, and game legality before changing state. Sequence gaps cause a full snapshot request. Temporary disconnects use an expiring resume token and last acknowledged sequence.

Release logging must redact join tokens, resume tokens, private prompts, secret roles, and sensitive player data. Production connections are restricted to loopback, RFC1918 IPv4, link-local addresses, and private IPv6 ranges.
