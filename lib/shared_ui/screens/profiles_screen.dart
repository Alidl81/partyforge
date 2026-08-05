import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/domain/player/player_profile.dart';
import '../../data/repositories/repository_providers.dart';

final profilesProvider = StreamProvider.autoDispose<List<PlayerProfile>>(
  (ref) => ref.watch(playerRepositoryProvider).watchAll(),
);

class ProfilesScreen extends ConsumerWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profilesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('پروفایل‌ها')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.person_add),
        label: const Text('بازیکن جدید'),
      ),
      body: profiles.when(
        data: (items) => items.isEmpty
            ? const Center(child: Text('هنوز بازیکنی ساخته نشده است.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final item = items[index];
                  return ListTile(
                    tileColor: Theme.of(context).colorScheme.surfaceContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    leading: CircleAvatar(backgroundColor: Color(item.colorValue), child: const Icon(Icons.person)),
                    title: Text(item.name),
                    subtitle: Text('برد ${item.totalWins} • باخت ${item.totalLosses}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        unawaited(
                          ref.read(playerRepositoryProvider).delete(item.id),
                        );
                      },
                    ),
                  );
                },
              ),
        error: (error, _) => Center(child: Text('خطا در خواندن پروفایل‌ها: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('نام بازیکن'),
        content: TextField(controller: controller, autofocus: true, maxLength: 24),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('ذخیره')),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    final now = DateTime.now().toUtc();
    await ref.read(playerRepositoryProvider).save(PlayerProfile(
      id: const Uuid().v4(),
      name: name,
      colorValue: 0xFF6D4AFF,
      avatarId: 'default',
      championshipPoints: 0,
      totalWins: 0,
      totalLosses: 0,
      createdAt: now,
      updatedAt: now,
    ));
  }
}
