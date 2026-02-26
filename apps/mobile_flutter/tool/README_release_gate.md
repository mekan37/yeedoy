# Release Gate

Bu kontrol release oncesi kalite + guvenlik + rollout kapisi icin kullanilir.

## Beklenen metrik JSON formati

```json
{
  "crash_free_rate": 0.998,
  "jank_rate": 0.006,
  "startup_p95_ms": 1800,
  "home_tti_p95_ms": 1000,
  "search_hit_p95_ms": 220,
  "search_miss_p95_ms": 700,
  "security": {
    "zero_trust_write": true,
    "waf_ip_reputation": true,
    "device_fingerprint_soft": true,
    "pii_minimized": true,
    "security_review_checklist_done": true
  },
  "release_ops": {
    "backend_feature_flags": true,
    "kill_switch_ready": true,
    "api_versioning_enforced": true,
    "current_rollout_percent": 5,
    "stages": [1, 5, 20, 100],
    "crash_free_rate": 0.999,
    "jank_rate": 0.005,
    "home_tti_p95_ms": 980,
    "edge_429_rate": 0.01
  }
}
```

## Calistirma

```bash
dart run tool/release_gate_check.dart <metrics.json>
```

- `PASS` -> release devam eder
- `BLOCK` -> release durur
- `ACTION: ROLLOUT_NEXT_STAGE_X` -> bir sonraki asamaya gec
- `ACTION: AUTO_ROLLBACK_TRIGGER` -> otomatik rollback tetikle
- `ACTION: ROLLBACK_RECOMMENDED` -> SLO bazli rollback onerisi
