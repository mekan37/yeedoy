'use client';

import { useEffect, useRef, useState, type ReactNode } from 'react';
import { clsx } from 'clsx';
import { useToastDeposu } from '@/src/lib/toast-deposu';

type ToastVariant = 'default' | 'success' | 'danger' | 'warning' | 'info';

interface ToastProps {
  message: string;
  variant?: ToastVariant;
  duration?: number;
  onClose?: () => void;
  icon?: ReactNode;
}

const variantStyles: Record<ToastVariant, string> = {
  default: 'bg-textStrong text-card border-textStrong/20',
  success: 'bg-success/12 text-success border-success/20',
  danger:  'bg-danger/12 text-danger border-danger/20',
  warning: 'bg-warning/12 text-warning border-warning/20',
  info:    'bg-info/12 text-info border-info/20',
};

const defaultIcons: Record<ToastVariant, ReactNode> = {
  default: null,
  success: <CheckIcon />,
  danger:  <XIcon />,
  warning: <WarnIcon />,
  info:    <InfoIcon />,
};

export function Toast({ message, variant = 'default', duration = 3500, onClose, icon }: ToastProps) {
  const [leaving, setLeaving] = useState(false);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  function dismiss() {
    setLeaving(true);
    timerRef.current = setTimeout(() => onClose?.(), 220);
  }

  useEffect(() => {
    timerRef.current = setTimeout(dismiss, duration);
    return () => { if (timerRef.current) clearTimeout(timerRef.current); };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const displayIcon = icon ?? defaultIcons[variant];

  return (
    <div
      role="status"
      aria-live="polite"
      className={clsx(
        'flex items-center gap-3 rounded-2xl border px-4 py-3 shadow-yd3 text-sm font-bold max-w-[360px] w-full',
        variantStyles[variant],
        leaving ? 'toast-leave' : 'toast-enter',
      )}
    >
      {displayIcon && (
        <span className="flex h-5 w-5 shrink-0 items-center justify-center">
          {displayIcon}
        </span>
      )}
      <span className="flex-1">{message}</span>
      <button
        type="button"
        onClick={dismiss}
        aria-label="Bildirimi kapat"
        className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full opacity-60 transition-opacity hover:opacity-100 focus-visible:outline-hidden focus-visible:ring-2 focus-visible:ring-current"
      >
        <XIcon size={14} />
      </button>
    </div>
  );
}

/** ToastContainer — fixed bottom-right, renders stacked toasts. */
export function ToastContainer({ children }: { children: ReactNode }) {
  return (
    <div
      aria-label="Bildirimler"
      className="fixed bottom-6 right-6 z-200 flex flex-col-reverse gap-2 pointer-events-none"
    >
      <div className="pointer-events-auto flex flex-col gap-2">
        {children}
      </div>
    </div>
  );
}

/** useToast — minimal hook for imperative toast management. */
export function useToast() {
  const [toasts, setToasts] = useState<Array<{ id: number } & ToastProps>>([]);
  const idRef = useRef(0);

  function show(props: Omit<ToastProps, 'onClose'>) {
    const id = ++idRef.current;
    setToasts((prev) => [...prev, { ...props, id, onClose: () => remove(id) }]);
  }

  function remove(id: number) {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  }

  const container = (
    <ToastContainer>
      {toasts.map((t) => (
        <Toast key={t.id} {...t} />
      ))}
    </ToastContainer>
  );

  return { show, container };
}

/** GlobalToastContainer — mounts in AppProviders, reads from global Zustand store. */
export function GlobalToastContainer() {
  const { toasts, remove } = useToastDeposu();
  return (
    <ToastContainer>
      {toasts.map((t) => (
        <Toast key={t.id} {...t} onClose={() => remove(t.id)} />
      ))}
    </ToastContainer>
  );
}

// ─── İkonlar ─────────────────────────────────────────────────────────────────

function CheckIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <polyline points="20 6 9 17 4 12" />
    </svg>
  );
}

function XIcon({ size = 16 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <line x1="18" y1="6" x2="6" y2="18" />
      <line x1="6" y1="6" x2="18" y2="18" />
    </svg>
  );
}

function WarnIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" />
      <line x1="12" y1="9" x2="12" y2="13" />
      <line x1="12" y1="17" x2="12.01" y2="17" />
    </svg>
  );
}

function InfoIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <circle cx="12" cy="12" r="10" />
      <line x1="12" y1="16" x2="12" y2="12" />
      <line x1="12" y1="8" x2="12.01" y2="8" />
    </svg>
  );
}
