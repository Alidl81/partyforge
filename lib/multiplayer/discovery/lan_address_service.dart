import 'dart:io';

import '../security/private_address.dart';

abstract final class LanAddressService {
  static Future<List<InternetAddress>> privateIpv4Addresses() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
      includeLinkLocal: true,
    );
    final addresses = <InternetAddress>[];
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        if (PrivateAddressPolicy.isAllowed(address)) {
          addresses.add(address);
        }
      }
    }
    addresses.sort((a, b) => a.address.compareTo(b.address));
    return addresses;
  }
}
