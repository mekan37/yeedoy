'use client';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useState, type ReactNode } from 'react';
import { GlobalToastContainer } from '@/src/ui/bilesenler/bildirim-toast';
import { OturumSuresiUyarisi } from '@/src/ui/bilesenler/oturum-suresi-uyarisi';

export function AppProviders({ children }: { children: ReactNode }) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 30_000,
            refetchOnWindowFocus: false,
          },
        },
      }),
  );
  return (
    <QueryClientProvider client={queryClient}>
      {children}
      <GlobalToastContainer />
      <OturumSuresiUyarisi />
    </QueryClientProvider>
  );
}
