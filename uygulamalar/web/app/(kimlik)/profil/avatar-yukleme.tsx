'use client';

import { useRef, useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';

const BUCKET = 'menu-media';

type Props = {
  userId: string;
  avatarUrl: string | null;
  displayName: string;
  initials: string;
  size?: 'sm' | 'lg';
};

export function AvatarYukleme({ userId, avatarUrl, displayName, initials, size = 'lg' }: Props) {
  const router = useRouter();
  const inputRef = useRef<HTMLInputElement>(null);
  const [preview, setPreview] = useState<string | null>(avatarUrl);
  const [hata, setHata] = useState('');
  const [isPending, start] = useTransition();

  const dim = size === 'lg' ? 'h-20 w-20' : 'h-16 w-16';
  const textSize = size === 'lg' ? 'text-2xl' : 'text-xl';

  async function handleFile(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    if (file.size > 3 * 1024 * 1024) { setHata('Görsel en fazla 3 MB olabilir.'); return; }

    const localUrl = URL.createObjectURL(file);
    setPreview(localUrl);
    setHata('');

    start(async () => {
      try {
        const sb = createSupabaseBrowserClient();
        const ext = file.name.split('.').pop()?.toLowerCase() ?? 'jpg';
        const path = `user-avatars/${userId}.${ext}`;

        const { error: upErr } = await sb.storage
          .from(BUCKET)
          .upload(path, file, { upsert: true, contentType: file.type });
        if (upErr) throw upErr;

        const publicUrl = sb.storage.from(BUCKET).getPublicUrl(path).data.publicUrl;

        await (sb as any)
          .from('user_profiles')
          .update({ avatar_url: publicUrl })
          .eq('user_id', userId);

        setPreview(publicUrl);
        router.refresh();
      } catch {
        setHata('Yükleme başarısız.');
        setPreview(avatarUrl);
      } finally {
        if (inputRef.current) inputRef.current.value = '';
      }
    });
  }

  return (
    <div className="relative shrink-0">
      <label
        htmlFor={`avatar-upload-${size}`}
        className={`block cursor-pointer ${isPending ? 'opacity-70' : ''}`}
        title="Profil fotoğrafını değiştir"
      >
        <div className={`${dim} overflow-hidden rounded-full border-[3px] border-white shadow-yd2 bg-primary/10`}>
          {preview ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={preview} alt={displayName} className="h-full w-full object-cover" />
          ) : (
            <div className={`flex h-full w-full items-center justify-center ${textSize} font-[900] text-primary`}>
              {initials}
            </div>
          )}
        </div>

        {/* Kamera rozeti */}
        <div className={`absolute bottom-0 right-0 flex h-6 w-6 items-center justify-center rounded-full shadow-sm transition ${isPending ? 'bg-muted' : 'bg-primary hover:brightness-110'}`}>
          {isPending ? (
            <svg className="h-3 w-3 animate-spin text-white" viewBox="0 0 24 24" fill="none" aria-hidden="true">
              <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="3" strokeOpacity="0.3" />
              <path d="M12 2a10 10 0 0 1 10 10" stroke="currentColor" strokeWidth="3" />
            </svg>
          ) : (
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
              <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z" />
              <circle cx="12" cy="13" r="4" />
            </svg>
          )}
        </div>
      </label>

      <input
        id={`avatar-upload-${size}`}
        ref={inputRef}
        type="file"
        accept="image/jpeg,image/png,image/webp"
        className="sr-only"
        onChange={handleFile}
        disabled={isPending}
      />

      {hata && (
        <p className="absolute left-1/2 top-full mt-1.5 -translate-x-1/2 whitespace-nowrap rounded-lg bg-danger/10 px-2 py-0.5 text-[10px] font-[700] text-danger">
          {hata}
        </p>
      )}
    </div>
  );
}
