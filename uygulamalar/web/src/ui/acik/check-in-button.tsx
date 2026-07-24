'use client';
import { useState, useTransition } from 'react';

interface Props {
  businessId: string;
  initialCheckedIn: boolean;
}

export function CheckInButton({ businessId, initialCheckedIn }: Props) {
  const [checkedIn, setCheckedIn] = useState(initialCheckedIn);
  const [isPending, startTransition] = useTransition();
  const [message, setMessage] = useState<string | null>(null);

  function handleCheckIn() {
    startTransition(async () => {
      try {
        const res = await fetch('/api/check-in', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ businessId }),
        });

        if (res.status === 401) {
          setMessage('Ziyaret kaydetmek için giriş yapmanız gerekiyor.');
          return;
        }
        if (res.status === 409) {
          setCheckedIn(true);
          setMessage('Bugün zaten ziyaret kaydettiniz.');
          return;
        }
        if (!res.ok) {
          setMessage('Bir hata oluştu. Lütfen tekrar deneyin.');
          return;
        }

        setCheckedIn(true);
        setMessage('Ziyaretiniz kaydedildi!');
      } catch {
        setMessage('Bağlantı hatası. Lütfen tekrar deneyin.');
      }
    });
  }

  if (checkedIn) {
    return (
      <div className="flex items-center gap-2 rounded-xl border border-green-200 bg-green-50 px-4 py-2.5 text-sm font-semibold text-green-700">
        <svg className="h-4 w-4" fill="currentColor" viewBox="0 0 20 20" aria-hidden="true">
          <path
            fillRule="evenodd"
            d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z"
            clipRule="evenodd"
          />
        </svg>
        Bugün ziyaret edildi
        {message && (
          <span className="ml-1 text-xs font-normal text-green-600">· {message}</span>
        )}
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-1.5">
      <button
        onClick={handleCheckIn}
        disabled={isPending}
        className="flex min-h-[44px] items-center justify-center gap-2 rounded-2xl px-5 text-sm font-extrabold text-white transition-opacity hover:opacity-90 disabled:opacity-60"
        style={{ background: '#7F1D1D' }}
      >
        {isPending ? (
          <svg
            className="h-4 w-4 animate-spin"
            fill="none"
            viewBox="0 0 24 24"
            aria-hidden="true"
          >
            <circle
              className="opacity-25"
              cx="12"
              cy="12"
              r="10"
              stroke="currentColor"
              strokeWidth="4"
            />
            <path
              className="opacity-75"
              fill="currentColor"
              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"
            />
          </svg>
        ) : (
          <svg
            className="h-4 w-4"
            fill="currentColor"
            viewBox="0 0 20 20"
            aria-hidden="true"
          >
            <path
              fillRule="evenodd"
              d="M9.69 18.933l.003.001C9.89 19.02 10 19 10 19s.11.02.308-.066l.002-.001.006-.003.018-.008a5.741 5.741 0 00.281-.14c.186-.096.446-.24.757-.433.62-.387 1.445-.96 2.274-1.765C15.302 14.988 17 12.493 17 9A7 7 0 103 9c0 3.492 1.698 5.988 3.355 7.584a13.731 13.731 0 002.273 1.765 11.842 11.842 0 00.976.544l.062.029.018.008.006.003zM10 11.25a2.25 2.25 0 100-4.5 2.25 2.25 0 000 4.5z"
              clipRule="evenodd"
            />
          </svg>
        )}
        Gerçekten Buradayım
      </button>
      {message && <p className="text-center text-xs text-muted">{message}</p>}
    </div>
  );
}
