enum SequenceStatus { accepted, duplicateOrOld, gap }

final class SequenceTracker {
  int _last = 0;
  int get last => _last;

  SequenceStatus accept(int sequence) {
    if (sequence <= _last) return SequenceStatus.duplicateOrOld;
    if (sequence > _last + 1) return SequenceStatus.gap;
    _last = sequence;
    return SequenceStatus.accepted;
  }

  void resetFromSnapshot(int sequence) => _last = sequence;
}
