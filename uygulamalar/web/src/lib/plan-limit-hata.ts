// _check_plan_limit_v1, RAISE EXCEPTION ... USING ERRCODE ile iki farklı
// hata döndürebilir: P0002 (unauthorized — çağıran owner_claims'te
// approved değil) ve P0003 (plan_limit_exceeded — gerçek plan sınırı).
// Çağıran taraflar bu ikisini ayırt etmeden her ikisini de "plan
// limitine ulaştınız" olarak gösteriyordu — asıl sebep yetki eksikliği
// olsa bile kullanıcıyı yanlış yönlendiriyordu.
export function planLimitHataMesaji(
  error: { code?: string; message?: string } | null,
  featureLabel: string,
): string {
  if (error?.code === 'P0002') {
    return 'Bu işlem için yetkiniz yok.';
  }
  return `${featureLabel} limitine ulaştınız. Daha fazla eklemek için planınızı yükseltin.`;
}
