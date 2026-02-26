'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { businessSchema } from '@/src/shared/schemas/businessSchema';
import { Input } from '@/src/ui/components/input';
import { Button } from '@/src/ui/components/button';

type Values = z.infer<typeof businessSchema>;

export function BusinessCreateForm() {
  const router = useRouter();
  const [info, setInfo] = useState<string | null>(null);
  const form = useForm<Values>({
    resolver: zodResolver(businessSchema),
    defaultValues: {
      name: '',
      city: '',
      district: '',
      category: 'Restoran',
      address: '',
      phone: '',
      website: '',
    },
  });

  return (
    <form
      className="grid gap-3"
      onSubmit={form.handleSubmit(async (v) => {
        try {
          setInfo(null);
          const fd = new FormData();
          fd.set('name', v.name);
          fd.set('city', v.city);
          fd.set('district', v.district);
          fd.set('category', v.category || 'Restoran');
          fd.set('address', v.address);
          fd.set('phone', v.phone || '');
          fd.set('website', v.website || '');

          const res = await fetch('/api/businesses', { method: 'POST', body: fd });
          const body = await res.json().catch(() => ({}));
          if (!res.ok) {
            alert(body.error ?? 'Basvuru gonderilemedi');
            return;
          }
          form.reset();
          setInfo('Basvuru alindi. Admin onayindan sonra listene eklenecek.');
          router.refresh();
        } catch (err) {
          alert(err instanceof Error ? err.message : 'Basvuru gonderilirken beklenmeyen bir hata olustu.');
        }
      })}
    >
      <Input placeholder="Isletme adi" {...form.register('name')} />
      <div className="grid grid-cols-2 gap-2">
        <Input placeholder="Sehir" {...form.register('city')} />
        <Input placeholder="Ilce" {...form.register('district')} />
      </div>
      <Input placeholder="Kategori (or. Restoran)" {...form.register('category')} />
      <Input placeholder="Adres" {...form.register('address')} />
      <div className="grid grid-cols-2 gap-2">
        <Input placeholder="Telefon (opsiyonel)" {...form.register('phone')} />
        <Input placeholder="Website (opsiyonel)" {...form.register('website')} />
      </div>
      {info && <p className="text-sm text-emerald-700">{info}</p>}
      <Button type="submit" className="h-11 rounded-xl">
        Basvuru Gonder
      </Button>
    </form>
  );
}
