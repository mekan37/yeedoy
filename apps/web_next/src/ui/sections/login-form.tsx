'use client';

import { zodResolver } from '@hookform/resolvers/zod';
import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { Button } from '@/src/ui/components/button';
import { Input } from '@/src/ui/components/input';
import { loginSchema } from '@/src/lib/validators';

type Props = {
  onSubmit: (fd: FormData) => Promise<void>;
};

export function LoginForm({ onSubmit }: Props) {
  const form = useForm<z.infer<typeof loginSchema>>({
    resolver: zodResolver(loginSchema),
    defaultValues: { email: '', password: '' },
  });

  return (
    <form
      className="space-y-3"
      onSubmit={form.handleSubmit(async (v) => {
        const fd = new FormData();
        fd.set('email', v.email);
        fd.set('password', v.password);
        await onSubmit(fd);
      })}
    >
      <div>
        <Input placeholder="Email" {...form.register('email')} />
        {form.formState.errors.email && (
          <p className="mt-1 text-xs text-red-600">{form.formState.errors.email.message}</p>
        )}
      </div>
      <div>
        <Input type="password" placeholder="Password" {...form.register('password')} />
        {form.formState.errors.password && (
          <p className="mt-1 text-xs text-red-600">{form.formState.errors.password.message}</p>
        )}
      </div>
      <Button type="submit" className="w-full">
        Sign In
      </Button>
    </form>
  );
}
