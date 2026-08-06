import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared_ui/widgets/party_scaffold.dart';
import '../domain/word_forge.dart';

class WordForgeScreen extends StatefulWidget {
  const WordForgeScreen({super.key});

  @override
  State<WordForgeScreen> createState() => _WordForgeScreenState();
}

class _WordForgeScreenState extends State<WordForgeScreen> {
  static const _letters = 'سلامبازیزمانخانهدوستگروهبرندهمسیررنگصدا';

  final TextEditingController _controller = TextEditingController();
  final List<({String word, int score})> _accepted = [];
  WordForgeSession? _session;
  String _message = 'در حال آماده‌سازی واژه‌نامه…';
  int _totalScore = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/dictionaries/fa_words.txt');
    final dictionary = _AssetDictionary(
      raw
          .split(RegExp(r'\r?\n'))
          .map(PersianWordNormalizer.normalize)
          .where((word) => word.isNotEmpty)
          .toSet(),
    );
    final counts = <String, int>{};
    for (final rune in _letters.runes) {
      final letter = String.fromCharCode(rune);
      counts[letter] = (counts[letter] ?? 0) + 1;
    }
    if (!mounted) return;
    setState(() {
      _session = WordForgeSession(
        inventory: LetterInventory(counts),
        dictionary: dictionary,
      );
      _message = 'یک واژه با حروف موجود بساز.';
    });
  }

  Future<void> _submit() async {
    final session = _session;
    final raw = _controller.text;
    if (session == null || raw.trim().isEmpty) return;
    final normalized = PersianWordNormalizer.normalize(raw);
    final points = await session.submit(raw);
    if (!mounted) return;
    setState(() {
      if (points > 0) {
        _accepted.add((word: normalized, score: points));
        _totalScore += points;
        _message = 'واژه پذیرفته شد: +$points امتیاز';
        _controller.clear();
      } else {
        _message = 'واژه نامعتبر، تکراری یا خارج از حروف موجود است.';
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uniqueLetters = _letters.runes.map(String.fromCharCode).toSet();
    return PartyScaffold(
      title: 'واژه‌ساز',
      fallbackLocation: '/play',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'امتیاز: $_totalScore',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 18),
              Text('حروف موجود', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final letter in uniqueLetters)
                    CircleAvatar(
                      radius: 24,
                      child: Text(
                        letter,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                enabled: _session != null,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'واژهٔ فارسی',
                  hintText: 'مثلاً: بازی',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _session == null ? null : _submit,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('ثبت واژه'),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(_message, textAlign: TextAlign.center),
                ),
              ),
              if (_accepted.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text('واژه‌های پذیرفته‌شده',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                for (final entry in _accepted.reversed)
                  ListTile(
                    leading: const Icon(Icons.auto_awesome),
                    title: Text(entry.word),
                    trailing: Text('+${entry.score}'),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

final class _AssetDictionary implements DictionaryProvider {
  const _AssetDictionary(this.words);

  final Set<String> words;

  @override
  Future<bool> contains(String normalizedWord) async =>
      words.contains(normalizedWord);
}
