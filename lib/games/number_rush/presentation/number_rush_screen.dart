import 'package:flutter/material.dart';

import '../../../core/random/seeded_random.dart';
import '../../../shared_ui/widgets/party_scaffold.dart';
import '../domain/number_rush.dart';

class NumberRushScreen extends StatefulWidget {
  const NumberRushScreen({super.key});

  @override
  State<NumberRushScreen> createState() => _NumberRushScreenState();
}

class _NumberRushScreenState extends State<NumberRushScreen> {
  var _roundIndex = 1;
  var _score = 0;
  var _streak = 0;
  late NumberRushRound _round;
  final List<int> _selected = [];
  String _message = 'دو عدد را انتخاب کن.';

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    _round = NumberRushEngine.createRound(
      SplitMix64Random(83000 + _roundIndex * 53),
    );
    _selected.clear();
  }

  void _select(int index) {
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
        return;
      }
      if (_selected.length < 2) _selected.add(index);
    });
  }

  void _submit() {
    if (_selected.length != 2) return;
    final correct = NumberRushEngine.isCorrect(
      _round,
      _selected[0],
      _selected[1],
    );
    setState(() {
      if (correct) {
        _streak++;
        final earned = NumberRushEngine.score(correct: true, streak: _streak);
        _score += earned;
        _message = 'درست! +$earned امتیاز';
      } else {
        _streak = 0;
        _message = 'این دو عدد به هدف نمی‌رسند.';
      }
      _roundIndex++;
      _newRound();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PartyScaffold(
      title: 'یورش عددی',
      fallbackLocation: '/play',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            shrinkWrap: true,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('دور $_roundIndex'),
                  Text('امتیاز $_score  •  زنجیره $_streak'),
                ],
              ),
              const SizedBox(height: 26),
              Text(
                'هدف: ${_round.target}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 10),
              Text(_message, textAlign: TextAlign.center),
              const SizedBox(height: 28),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                ),
                itemCount: _round.numbers.length,
                itemBuilder: (context, index) {
                  final selected = _selected.contains(index);
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _select(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Text(
                        '${_round.numbers[index]}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: selected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : null,
                            ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _selected.length == 2 ? _submit : null,
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('بررسی پاسخ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
