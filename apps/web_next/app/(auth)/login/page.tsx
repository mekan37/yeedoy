'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { zodResolver } from '@hookform/resolvers/zod';
import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { createSupabaseBrowserClient } from '@/src/lib/supabaseClient';
import { loginSchema } from '@/src/lib/validators';
import { Card } from '@/src/ui/components/card';
import { Input } from '@/src/ui/components/input';
import { Button } from '@/src/ui/components/button';

type Values = z.infer<typeof loginSchema>;

export default function LoginPage() {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const form = useForm<Values>({
    resolver: zodResolver(loginSchema),
    defaultValues: { email: '', password: '' },
  });

  return (
    <main className="relative mx-auto flex min-h-screen max-w-md items-center px-4">
      <div className="absolute inset-0 -z-10 bg-[radial-gradient(circle_at_10%_20%,rgba(15,23,42,0.08),transparent_40%),radial-gradient(circle_at_80%_0%,rgba(15,23,42,0.06),transparent_36%)]" />
      <Card className="w-full rounded-3xl border-slate-200/80 p-6 shadow-md">
        <div>
          <h1 className="text-3xl font-extrabold tracking-tight text-slate-900">Yeedoy Isletme Girisi</h1>
          <p className="mt-2 text-sm text-slate-500">Panelden menu, fiyat ve QR varliklarini yonet.</p>
        </div>
        <form
          className="mt-5 space-y-3"
          onSubmit={form.handleSubmit(async (v) => {
            try {
              setError(null);
              setLoading(true);
              const supabase = createSupabaseBrowserClient();
              const { error } = await supabase.auth.signInWithPassword({
                email: v.email,
                password: v.password,
              });
              if (error) {
                setError('Giris basarisiz: e-posta veya sifreyi kontrol et.');
                return;
              }
              router.push('/dashboard');
              router.refresh();
            } catch (err) {
              setError(err instanceof Error ? err.message : 'Giris sirasinda beklenmeyen bir hata olustu.');
            } finally {
              setLoading(false);
            }
          })}
        >
          <Input placeholder="E-posta" {...form.register('email')} />
          <Input type="password" placeholder="Sifre" {...form.register('password')} />
          {error && <p className="text-sm text-red-600">{error}</p>}
          <Button type="submit" className="h-11 w-full rounded-xl" disabled={loading}>
            {loading ? 'Giris yapiliyor...' : 'Giris Yap'}
          </Button>
        </form>
      </Card>
    </main>
  );
}
