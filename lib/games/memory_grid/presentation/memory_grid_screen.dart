import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/random/seeded_random.dart';
import '../../../shared_ui/widgets/party_scaffold.dart';
import '../domain/memory_grid.dart';

class MemoryGridScreen extends StatefulWidget {
  const MemoryGridScreen({super.key});

  @override
  State<MemoryGridScreen> createState() => _MemoryGridScreenState();
}

class _MemoryGridScreenState extends State<MemoryGridScreen> {
  var _level = 1;
  var _score = 0;
  late MemoryGridRound _round;
  final Set<int> _selected = {};
  bool _preview = true;
  MemoryGridResult? _result;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  void _startRound() {
    _round = MemoryGridEngine.createRound(
      SplitMix64Random(99000 + _level * 31),
      _level,
    );
    _selected.clear();
    _result = null;
    _preview = true;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _preview = false);
    });
  }

  void _submit() {
    if (_preview || _result != null) return;
    final result = MemoryGridEngine.evaluate(_round, _selected);
    setState(() {
      _result = result;
      _score += result.points;
      if (result.correct) _level++;
    });
  }

  void _next() => setState(_startRound);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PartyScaffold(
      title: 'شبکهٔ حافظه',
      fallbackLocation: '/play',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('مرحله $_level',
                      style: Theme.of(context).textTheme.titleLarge),
                  Text('امتیاز $_score',
                      style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _preview
                    ? 'الگو را به خاطر بسپار…'
                    : _result == null
                        ? 'خانه‌های درست را انتخاب کن.'
                        : _result!.correct
                            ? 'کاملاً درست!'
                            : 'نزدیک بود؛ دوباره تلاش کن.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 22),
              AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _round.size,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: _round.size * _round.size,
                  itemBuilder: (context, index) {
                    final active = _preview
                        ? _round.activeCells.contains(index)
                        : _selected.contains(index);
                    final revealCorrect = _result != null &&
                        _round.activeCells.contains(index) &&
                        !_selected.contains(index);
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _preview || _result != null
                          ? null
                          : () => setState(() {
                                if (!_selected.add(index)) {
                                  _selected.remove(index);
                                }
                              }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: revealCorrect
                              ? Theme.of(context).colorScheme.errorContainer
                              : active
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: active
                            ? Icon(
                                Icons.auto_awesome,
                                color: Theme.of(context).colorScheme.onPrimary,
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              if (_result == null)
                FilledButton.icon(
                  onPressed: _preview ? null : _submit,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('ثبت پاسخ'),
                )
              else
                FilledButton.icon(
                  onPressed: _next,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(_result!.correct ? 'مرحلهٔ بعد' : 'تلاش دوباره'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
