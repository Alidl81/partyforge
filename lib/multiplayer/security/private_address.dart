import 'dart:io';

abstract final class PrivateAddressPolicy {
  static bool isAllowed(
    InternetAddress address, {
    bool developmentOverride = false,
  }) {
    if (developmentOverride || address.isLoopback) return true;
    final raw = address.rawAddress;
    if (address.type == InternetAddressType.IPv4 && raw.length == 4) {
      return _isPrivateV4(raw);
    }
    if (address.type == InternetAddressType.IPv6 && raw.length == 16) {
      final mappedV4 = raw.take(10).every((byte) => byte == 0) &&
          raw[10] == 0xFF &&
          raw[11] == 0xFF;
      if (mappedV4) return _isPrivateV4(raw.sublist(12));
      return (raw[0] & 0xFE) == 0xFC ||
          (raw[0] == 0xFE && (raw[1] & 0xC0) == 0x80);
    }
    return false;
  }

  static bool _isPrivateV4(List<int> raw) =>
      raw[0] == 10 ||
      (raw[0] == 172 && raw[1] >= 16 && raw[1] <= 31) ||
      (raw[0] == 192 && raw[1] == 168) ||
      (raw[0] == 169 && raw[1] == 254);
}
