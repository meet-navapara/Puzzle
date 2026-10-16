/// Deterministic mulberry32 PRNG for reproducible tests and seeded levels.
class SeededRng {
  SeededRng(int seed) : _state = seed & 0xFFFFFFFF;

  int _state;

  int nextInt(int max) {
    assert(max > 0);
    _state = (_state + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = _state;
    t = ((t ^ (t >> 15)) * (t | 1)) & 0xFFFFFFFF;
    t ^= (t + ((t ^ (t >> 7)) * (t | 61))) & 0xFFFFFFFF;
    final result = ((t ^ (t >> 14)) >> 0) & 0xFFFFFFFF;
    return result % max;
  }

  T pick<T>(List<T> items) {
    assert(items.isNotEmpty);
    return items[nextInt(items.length)];
  }
}
