# LAN Quick Join

PartyForge now treats technical connection details as an implementation detail.

## Normal flow

1. One player selects **Create room**.
2. The host advertises the room once per second on the local network.
3. Other players select **Join** and see nearby rooms automatically.
4. Tapping a room opens the WebSocket session and waits for an authoritative `lobby.joined` response.

## Discovery fallback

The host prefers TCP port `45873`. Clients listen for UDP announcements on `45872`. If broadcasts are blocked, the client probes the local `/24` subnet on the known host port. A manual six-digit code or host IP remains available under the advanced section.

## Reliability changes

- A join attempt is successful only after the host acknowledges it.
- Rejected joins return a typed error instead of appearing connected.
- Join credentials remain valid for eight hours instead of expiring after two minutes.
- The host screen shows connected players and keeps IP/port/session information collapsed.

## Platform notes

- Android includes Wi-Fi state and multicast permissions in the generated manifest.
- Windows users may need to approve the private-network Firewall prompt on first host launch.
