import 'package:flutter/material.dart';

import '../../../core/random/seeded_random.dart';
import '../../../shared_ui/widgets/party_scaffold.dart';
import '../domain/color_clash.dart';

class ColorClashScreen extends StatefulWidget {
  const ColorClashScreen({super.key});

  @override
  State<ColorClashScreen> createState() => _ColorClashScreenState();
}

class _ColorClashScreenState extends State<ColorClashScreen> {
  final Stopwatch _clock = Stopwatch();
  var _roundIndex = 1;
  var _score = 0;
  var _streak = 0;
  late ColorClashRound _round;
  String _message = 'رنگ ظاهری کلمه را انتخاب کن.';

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    _round = ColorClashEngine.createRound(
      SplitMix64Random(51000 + _roundIndex * 47),
    );
    _clock
      ..reset()
      ..start();
  }

  void _answer(ClashColor answer) {
    final points = ColorClashEngine.scoreAnswer(
      round: _round,
      answer: answer,
      elapsedUs: _clock.elapsedMicroseconds,
    );
    setState(() {
      if (points > 0) {
        _streak++;
        _score += points + (_streak - 1) * 25;
        _message = 'درست! +${points + (_streak - 1) * 25} امتیاز';
      } else {
        _streak = 0;
        _message = 'اشتباه؛ پاسخ درست ${_round.ink.label} بود.';
      }
      _roundIndex++;
      _newRound();
    });
  }

  Color _color(BuildContext context, ClashColor color) => switch (color) {
        ClashColor.red => Colors.red.shade600,
        ClashColor.blue => Colors.blue.shade600,
        ClashColor.green => Colors.green.shade600,
        ClashColor.yellow => Colors.amber.shade600,
      };

  @override
  Widget build(BuildContext context) {
    return PartyScaffold(
      title: 'نبرد رنگ‌ها',
      fallbackLocation: '/play',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('دور $_roundIndex'),
                    Text('امتیاز $_score  •  زنجیره $_streak'),
                  ],
                ),
                const SizedBox(height: 38),
                Text(
                  _round.word.label,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: _color(context, _round.ink),
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 16),
                Text(_message, textAlign: TextAlign.center),
                const SizedBox(height: 36),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 2.2,
                  children: [
                    for (final color in ClashColor.values)
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _color(context, color),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _answer(color),
                        child: Text(color.label),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
