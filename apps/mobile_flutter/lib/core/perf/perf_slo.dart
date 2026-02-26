enum StartupType { cold, warm }

enum SearchCacheType { hit, miss }

class PerfSlo {
  static const int coldStartP95Ms = 2000;
  static const int warmStartP95Ms = 800;
  static const int homeTtiP95Ms = 1200;
  static const int searchCacheHitP95Ms = 300;
  static const int searchCacheMissP95Ms = 800;
  static const double frameBudgetMs = 16.0;
  static const double maxJankRate = 0.01;
}

int startupBudgetMs(StartupType type) {
  return type == StartupType.warm
      ? PerfSlo.warmStartP95Ms
      : PerfSlo.coldStartP95Ms;
}

int searchBudgetMs(SearchCacheType type) {
  return type == SearchCacheType.hit
      ? PerfSlo.searchCacheHitP95Ms
      : PerfSlo.searchCacheMissP95Ms;
}
