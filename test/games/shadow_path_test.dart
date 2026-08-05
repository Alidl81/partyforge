import 'package:flutter_test/flutter_test.dart';
import 'package:partyforge/games/shadow_path/domain/shadow_path.dart';

void main() {
  final board = ShadowPathBoard(
    width: 4,
    height: 3,
    cells: {
      const GridPosition(3, 1): GridCell.goal,
      const GridPosition(1, 2): GridCell.trap,
      const GridPosition(2, 0): GridCell.wall,
    },
  );

  test('same-cell collision eliminates both', () {
    final result = ShadowPathSimulator.step(
      board: board,
      positions: const {'a': GridPosition(0, 1), 'b': GridPosition(2, 1)},
      commands: const {'a': GridCommand.right, 'b': GridCommand.left},
    );
    expect(result.eliminated, {'a', 'b'});
  });

  test('swap collision eliminates both', () {
    final result = ShadowPathSimulator.step(
      board: board,
      positions: const {'a': GridPosition(0, 1), 'b': GridPosition(1, 1)},
      commands: const {'a': GridCommand.right, 'b': GridCommand.left},
    );
    expect(result.eliminated, {'a', 'b'});
  });

  test('wall blocks movement and goal completes', () {
    final blocked = ShadowPathSimulator.step(
      board: board,
      positions: const {'a': GridPosition(1, 0)},
      commands: const {'a': GridCommand.right},
    );
    expect(blocked.positions['a'], const GridPosition(1, 0));
    final goal = ShadowPathSimulator.step(
      board: board,
      positions: const {'a': GridPosition(2, 1)},
      commands: const {'a': GridCommand.right},
    );
    expect(goal.finished, {'a'});
  });
}
