enum GridCommand { up, down, left, right, wait }

enum GridCell { empty, wall, trap, goal }

final class GridPosition {
  const GridPosition(this.x, this.y);
  final int x;
  final int y;

  GridPosition moved(GridCommand command) => switch (command) {
    GridCommand.up => GridPosition(x, y - 1),
    GridCommand.down => GridPosition(x, y + 1),
    GridCommand.left => GridPosition(x - 1, y),
    GridCommand.right => GridPosition(x + 1, y),
    GridCommand.wait => this,
  };

  @override bool operator ==(Object other) => other is GridPosition && other.x == x && other.y == y;
  @override int get hashCode => Object.hash(x, y);
}

final class ShadowPathTickResult {
  const ShadowPathTickResult({required this.positions, required this.eliminated, required this.finished});
  final Map<String, GridPosition> positions;
  final Set<String> eliminated;
  final Set<String> finished;
}

final class ShadowPathBoard {
  const ShadowPathBoard({required this.width, required this.height, required this.cells});
  final int width;
  final int height;
  final Map<GridPosition, GridCell> cells;

  GridCell cellAt(GridPosition position) {
    if (position.x < 0 || position.y < 0 || position.x >= width || position.y >= height) return GridCell.wall;
    return cells[position] ?? GridCell.empty;
  }
}

abstract final class ShadowPathSimulator {
  static ShadowPathTickResult step({
    required ShadowPathBoard board,
    required Map<String, GridPosition> positions,
    required Map<String, GridCommand> commands,
  }) {
    final proposed = <String, GridPosition>{};
    for (final entry in positions.entries) {
      final target = entry.value.moved(commands[entry.key] ?? GridCommand.wait);
      proposed[entry.key] = board.cellAt(target) == GridCell.wall ? entry.value : target;
    }

    final eliminated = <String>{};
    final groups = <GridPosition, List<String>>{};
    for (final entry in proposed.entries) {
      groups.putIfAbsent(entry.value, () => []).add(entry.key);
    }
    for (final players in groups.values) {
      if (players.length > 1) eliminated.addAll(players);
    }

    final ids = positions.keys.toList(growable: false);
    for (var i = 0; i < ids.length; i++) {
      for (var j = i + 1; j < ids.length; j++) {
        final a = ids[i];
        final b = ids[j];
        if (proposed[a] == positions[b] && proposed[b] == positions[a] && positions[a] != positions[b]) {
          eliminated.add(a);
          eliminated.add(b);
        }
      }
    }

    final finished = <String>{};
    for (final entry in proposed.entries) {
      if (board.cellAt(entry.value) == GridCell.trap) eliminated.add(entry.key);
      if (board.cellAt(entry.value) == GridCell.goal && !eliminated.contains(entry.key)) finished.add(entry.key);
    }
    return ShadowPathTickResult(
      positions: Map.unmodifiable(proposed),
      eliminated: Set.unmodifiable(eliminated),
      finished: Set.unmodifiable(finished),
    );
  }
}
