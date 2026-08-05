import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:partyforge/multiplayer/security/private_address.dart';

void main() {
  test('allows private and loopback addresses', () {
    expect(PrivateAddressPolicy.isAllowed(InternetAddress('127.0.0.1')), isTrue);
    expect(PrivateAddressPolicy.isAllowed(InternetAddress('192.168.1.10')), isTrue);
    expect(PrivateAddressPolicy.isAllowed(InternetAddress('10.2.3.4')), isTrue);
  });

  test('rejects public address', () {
    expect(PrivateAddressPolicy.isAllowed(InternetAddress('8.8.8.8')), isFalse);
  });
}
