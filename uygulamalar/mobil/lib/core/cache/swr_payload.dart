class SwrPayload<T> {
  const SwrPayload({required this.data, required this.isStale, this.refresh});

  final T data;
  final bool isStale;
  final Future<T>? refresh;
}
