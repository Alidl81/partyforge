import 'package:flutter_test/flutter_test.dart';
import 'package:partyforge/games/word_forge/domain/word_forge.dart';

final class _Dictionary implements DictionaryProvider {
  @override Future<bool> contains(String normalizedWord) async => {'سلام', 'بازی'}.contains(normalizedWord);
}

void main() {
  test('persian normalization unifies characters and spacing', () {
    expect(PersianWordNormalizer.normalize('  سـلام\u200c  ي  '), 'سلام ی');
    expect(PersianWordNormalizer.normalize('كِتاب'), 'کتاب');
  });

  test('inventory rejects unavailable letters', () {
    final inventory = LetterInventory({'س': 1, 'ل': 1, 'ا': 1, 'م': 1});
    expect(inventory.canBuild('سلام'), isTrue);
    expect(inventory.canBuild('سس'), isFalse);
  });

  test('duplicate accepted word scores only once', () async {
    final session = WordForgeSession(
      inventory: LetterInventory({'س': 1, 'ل': 1, 'ا': 1, 'م': 1}),
      dictionary: _Dictionary(),
    );
    expect(await session.submit('سلام'), greaterThan(0));
    expect(await session.submit('سلام'), 0);
  });
}
