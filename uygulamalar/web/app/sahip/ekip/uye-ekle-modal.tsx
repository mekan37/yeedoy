'use client';

import { useState, useTransition } from 'react';
import { addTeamMember, type AddTeamMemberOutcome } from './ekip-islemleri';

function XIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><path d="M18 6 6 18M6 6l12 12" /></svg>;
}
function EyeIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" /><circle cx="12" cy="12" r="3" /></svg>;
}
function EyeOffIcon() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17.94 17.94A10.94 10.94 0 0 1 12 20c-7 0-11-8-11-8a19.6 19.6 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a19.6 19.6 0 0 1-2.16 3.19M14.12 14.12a3 3 0 1 1-4.24-4.24" /><line x1="1" y1="1" x2="23" y2="23" /></svg>;
}

const SUCCESS_MESSAGES: Record<Extract<AddTeamMemberOutcome, { ok: true }>['mode'], string> = {
  created: 'Hesap oluşturuldu — üye artık e-posta ve şifresiyle giriş yapıp doğrudan Sahip Paneli\'ne yönlendirilebilir.',
  invited: 'Davet e-postası gönderildi. Üye bu e-posta ile kayıt olduğunda veya giriş yaptığında otomatik olarak ekibe bağlanır.',
  linked: 'Bu e-posta zaten kayıtlıydı — mevcut hesap ekibe eklendi, şifresi değiştirilmedi.',
};

export function UyeEkleModal({ businesses }: { businesses: { id: string; name: string }[] }) {
  const [open, setOpen] = useState(false);
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [showPassword, setShowPassword] = useState(false);

  function close() {
    setOpen(false);
    setError(null);
    setSuccess(null);
    setShowPassword(false);
  }

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const form = e.currentTarget;
    const fd = new FormData(form);
    const password = String(fd.get('password') ?? '');

    if (password && password.length < 8) {
      setError('Şifre en az 8 karakter olmalı');
      return;
    }

    const input = {
      businessId: String(fd.get('businessId') ?? ''),
      email: String(fd.get('email') ?? ''),
      fullName: String(fd.get('fullName') ?? ''),
      password,
      role: String(fd.get('role') ?? 'staff'),
    };

    setError(null);
    startTransition(async () => {
      const result = await addTeamMember(input);
      if ('error' in result) {
        setError(result.error);
        return;
      }
      setSuccess(SUCCESS_MESSAGES[result.mode]);
      form.reset();
    });
  }

  return (
    <>
      <button
        onClick={() => setOpen(true)}
        className="btn-primary inline-flex min-h-[40px] cursor-pointer items-center justify-center rounded-xl px-4 text-sm font-[800] text-white"
      >
        + Üye Ekle
      </button>

      {open && (
        <>
          <div className="fixed inset-0 z-40 bg-black/50 backdrop-blur-[2px]" onClick={close} />
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            <div className="flex max-h-[90vh] w-full max-w-md flex-col rounded-2xl bg-card shadow-lg">
              <div className="flex shrink-0 items-center justify-between rounded-t-2xl border-b border-border px-6 py-4">
                <h2 className="text-base font-[900] text-textStrong">Üye Ekle</h2>
                <button
                  type="button"
                  onClick={close}
                  className="flex h-8 w-8 cursor-pointer items-center justify-center rounded-xl border border-border text-muted hover:bg-bg"
                >
                  <XIcon />
                </button>
              </div>

              {success ? (
                <div className="flex flex-1 flex-col gap-4 px-6 py-8 text-center">
                  <p className="text-sm font-[700] text-textStrong">{success}</p>
                  <div className="flex justify-center gap-2">
                    <button
                      onClick={() => setSuccess(null)}
                      className="cursor-pointer rounded-xl border border-border px-4 py-2 text-sm font-[700] text-textStrong hover:bg-bg"
                    >
                      Başka Üye Ekle
                    </button>
                    <button onClick={close} className="btn-primary cursor-pointer rounded-xl px-4 py-2 text-sm font-[700] text-white">
                      Kapat
                    </button>
                  </div>
                </div>
              ) : (
                <form className="flex flex-1 flex-col overflow-hidden" onSubmit={handleSubmit}>
                  <div className="flex flex-1 flex-col gap-3 overflow-y-auto px-6 py-5">
                    {businesses.length > 1 ? (
                      <label className="flex flex-col gap-1">
                        <span className="text-xs font-[700] text-muted">İşletme</span>
                        <select
                          name="businessId"
                          required
                          className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
                        >
                          {businesses.map((b) => (
                            <option key={b.id} value={b.id}>{b.name}</option>
                          ))}
                        </select>
                      </label>
                    ) : (
                      <input type="hidden" name="businessId" value={businesses[0]?.id ?? ''} />
                    )}

                    <label className="flex flex-col gap-1">
                      <span className="text-xs font-[700] text-muted">Ad Soyad (opsiyonel)</span>
                      <input
                        name="fullName"
                        placeholder="Ör: Ayşe Yılmaz"
                        className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
                      />
                    </label>

                    <label className="flex flex-col gap-1">
                      <span className="text-xs font-[700] text-muted">E-posta</span>
                      <input
                        name="email"
                        type="email"
                        required
                        placeholder="personel@ornek.com"
                        className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
                      />
                    </label>

                    <label className="flex flex-col gap-1">
                      <span className="text-xs font-[700] text-muted">Şifre (opsiyonel)</span>
                      <div className="relative">
                        <input
                          name="password"
                          type={showPassword ? 'text' : 'password'}
                          minLength={8}
                          placeholder="Boş bırakırsanız e-posta daveti gönderilir"
                          className="w-full rounded-xl border border-border bg-bg px-3 py-2 pr-10 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
                        />
                        <button
                          type="button"
                          onClick={() => setShowPassword((v) => !v)}
                          className="absolute right-2 top-1/2 -translate-y-1/2 cursor-pointer text-muted"
                          aria-label={showPassword ? 'Şifreyi gizle' : 'Şifreyi göster'}
                        >
                          {showPassword ? <EyeOffIcon /> : <EyeIcon />}
                        </button>
                      </div>
                      <span className="text-[11px] text-muted">
                        Şifre belirlerseniz üye hemen giriş yapıp Sahip Paneli&apos;ne yönlendirilir. Boş bırakırsanız e-posta ile davet gönderilir.
                      </span>
                    </label>

                    <label className="flex flex-col gap-1">
                      <span className="text-xs font-[700] text-muted">Rol</span>
                      <select
                        name="role"
                        defaultValue="staff"
                        className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
                      >
                        <option value="manager">Yönetici</option>
                        <option value="editor">Editör</option>
                        <option value="staff">Personel</option>
                        <option value="viewer">İzleyici</option>
                      </select>
                    </label>
                  </div>

                  <div className="shrink-0 rounded-b-2xl border-t border-border bg-card px-6 py-4">
                    {error && <p className="mb-3 rounded-xl bg-red-50 px-3 py-2 text-xs font-[700] text-red-700">{error}</p>}
                    <div className="flex items-center justify-end gap-3">
                      <button
                        type="button"
                        onClick={close}
                        className="cursor-pointer rounded-xl border border-border px-4 py-2 text-sm font-[700] text-textStrong hover:bg-bg"
                      >
                        İptal
                      </button>
                      <button
                        type="submit"
                        disabled={isPending}
                        className="btn-primary cursor-pointer rounded-xl px-5 py-2 text-sm font-[700] text-white shadow-sm transition hover:opacity-90 disabled:opacity-60"
                      >
                        {isPending ? 'Ekleniyor…' : 'Üye Ekle'}
                      </button>
                    </div>
                  </div>
                </form>
              )}
            </div>
          </div>
        </>
      )}
    </>
  );
}
