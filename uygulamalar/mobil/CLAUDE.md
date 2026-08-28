## Design System Rules — Flutter

- Colors: `AppColors` (primary `#7F1D1D` deep red, slate tones)
- Tokens: `AppTokens.of(context)` → `space4/8/12/16/20/24`, `radius12/16/20/24`
- Breakpoints: `AppTokens.bp720/860/980/1180/1280` — never magic numbers
- No inline color, spacing, or hex. No raw `TextStyle(fontSize:16)` hardcodes — use `AppTypography`
- Min tap target: 44 px
- Font family: Sora
