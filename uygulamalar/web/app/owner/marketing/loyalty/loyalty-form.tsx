'use client';

import { useActionState, useState } from 'react';
import { PanelActionButton } from '@/src/ui/components/panel-action-button';
import { upsertLoyaltyAction, type LoyaltyActionResult } from './loyalty-actions';
import type { LoyaltyProgram } from '@/src/lib/veri/owner/sadakat';

interface LoyaltyFormProps {
  businessId: string;
  program: LoyaltyProgram | null;
}

const initialState: LoyaltyActionResult | null = null;

export function LoyaltyForm({ businessId, program }: LoyaltyFormProps) {
  const [result, formAction, isPending] = useActionState<
    LoyaltyActionResult | null,
    FormData
  >(upsertLoyaltyAction, initialState);

  const defaults = program ?? {
    is_active: false,
    checkin_points: 10,
    review_points: 25,
    photo_points: 15,
    reward_threshold_pts: 500,
    reward_type: 'discount_pct' as const,
    reward_value: 10,
  };

  const [selectedRewardType, setSelectedRewardType] = useState<'discount_pct' | 'free_item'>(
    defaults.reward_type,
  );

  return (
    <form action={formAction} className="flex flex-col gap-6">
      <input type="hidden" name="business_id" value={businessId} />

      {/* Status feedback banner */}
      {result && (
        <div
          role="alert"
          className={
            result.ok
              ? 'rounded-xl border border-green-200 bg-green-50 px-4 py-3 text-sm font-[700] text-green-800'
              : 'rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm font-[700] text-red-800'
          }
        >
          {result.ok
            ? 'Sadakat programı başarıyla kaydedildi.'
            : result.error === 'forbidden'
              ? 'Bu işletme için yetkiniz bulunmuyor.'
              : result.error === 'unauthorized'
                ? 'Oturum açmanız gerekiyor.'
                : result.error === 'invalid_payload'
                  ? 'Lütfen tüm alanları doğru doldurun.'
                  : 'Bir hata oluştu. Lütfen tekrar deneyin.'}
        </div>
      )}

      {/* Active toggle */}
      <div className="flex items-center justify-between gap-4 rounded-xl border border-border bg-card px-5 py-4">
        <div>
          <p className="text-[15px] font-[800] text-textStrong">Program Durumu</p>
          <p className="mt-0.5 text-sm text-muted">
            Pasif durumdayken müşteriler puan kazanamaz.
          </p>
        </div>
        <label className="relative inline-flex cursor-pointer items-center gap-3">
          <input
            type="checkbox"
            name="is_active"
            value="true"
            defaultChecked={defaults.is_active}
            className="peer sr-only"
          />
          <div className="peer h-6 w-11 rounded-full bg-slate-200 transition-colors after:absolute after:left-[2px] after:top-[2px] after:h-5 after:w-5 after:rounded-full after:bg-white after:shadow-sm after:transition-all after:content-[''] peer-checked:bg-primary peer-checked:after:translate-x-full peer-focus-visible:ring-2 peer-focus-visible:ring-primary/30" />
          <span className="text-sm font-[700] text-textStrong">Aktif</span>
        </label>
      </div>

      {/* Points section */}
      <div className="rounded-xl border border-border bg-card">
        <div className="border-b border-border px-5 py-4">
          <h2 className="text-[15px] font-[900] text-textStrong">Puan Kuralları</h2>
          <p className="mt-0.5 text-xs text-muted">Müşterilerin hangi aksiyonlarda kaç puan kazanacağı</p>
        </div>
        <div className="grid gap-5 p-5 sm:grid-cols-3">
          <PointField
            label="Check-in Puanı"
            name="checkin_points"
            hint="1 – 100"
            min={1}
            max={100}
            defaultValue={defaults.checkin_points}
            icon={<CheckinIcon />}
          />
          <PointField
            label="Yorum Puanı"
            name="review_points"
            hint="1 – 200"
            min={1}
            max={200}
            defaultValue={defaults.review_points}
            icon={<ReviewIcon />}
          />
          <PointField
            label="Fotoğraf Puanı"
            name="photo_points"
            hint="1 – 100"
            min={1}
            max={100}
            defaultValue={defaults.photo_points}
            icon={<PhotoIcon />}
          />
        </div>
      </div>

      {/* Reward section */}
      <div className="rounded-xl border border-border bg-card">
        <div className="border-b border-border px-5 py-4">
          <h2 className="text-[15px] font-[900] text-textStrong">Ödül Ayarları</h2>
          <p className="mt-0.5 text-xs text-muted">Müşteri kaç puan biriktirince ve ne kazanır</p>
        </div>
        <div className="flex flex-col gap-5 p-5">
          <div className="grid gap-5 sm:grid-cols-2">
            <PointField
              label="Ödül Eşiği (Puan)"
              name="reward_threshold_pts"
              hint="50 – 5000"
              min={50}
              max={5000}
              defaultValue={defaults.reward_threshold_pts}
              icon={<ThresholdIcon />}
            />
            <div className="flex flex-col gap-1.5">
              <label className="flex items-center gap-2 text-sm font-[700] text-textStrong">
                <span className="flex h-5 w-5 shrink-0 items-center justify-center text-muted">
                  <GiftIcon />
                </span>
                Ödül Türü
              </label>
              <select
                name="reward_type"
                value={selectedRewardType}
                onChange={(e) => setSelectedRewardType(e.target.value as 'discount_pct' | 'free_item')}
                className="h-10 w-full rounded-lg border border-border bg-bg px-3 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
              >
                <option value="discount_pct">İndirim (%)</option>
                <option value="free_item">Bedava Ürün</option>
              </select>
              <p className="text-[11px] text-muted">
                İndirim: sepet tutarına uygulanır. Bedava ürün: kasiyerin belirlediği ürün.
              </p>
            </div>
          </div>

          {selectedRewardType !== 'free_item' ? (
            <PointField
              label="İndirim Oranı (%)"
              name="reward_value"
              hint="0 – 100"
              min={0}
              max={100}
              defaultValue={defaults.reward_value}
              icon={<PercentIcon />}
            />
          ) : (
            /* Hidden reward_value — still needs to be submitted */
            <input type="hidden" name="reward_value" value={defaults.reward_value} />
          )}
        </div>
      </div>

      <div className="flex justify-end">
        <PanelActionButton type="submit" variant="primary" loading={isPending}>
          Kaydet
        </PanelActionButton>
      </div>
    </form>
  );
}

// ---- sub-components ----

interface PointFieldProps {
  label: string;
  name: string;
  hint: string;
  min: number;
  max: number;
  defaultValue: number;
  icon: React.ReactNode;
}

function PointField({ label, name, hint, min, max, defaultValue, icon }: PointFieldProps) {
  return (
    <div className="flex flex-col gap-1.5">
      <label className="flex items-center gap-2 text-sm font-[700] text-textStrong">
        <span className="flex h-5 w-5 shrink-0 items-center justify-center text-muted">{icon}</span>
        {label}
      </label>
      <input
        type="number"
        name={name}
        min={min}
        max={max}
        defaultValue={defaultValue}
        required
        className="h-10 w-full rounded-lg border border-border bg-bg px-3 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
      />
      <p className="text-[11px] text-muted">{hint}</p>
    </div>
  );
}

// ---- icons ----
function CheckinIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" />
      <circle cx="12" cy="10" r="3" />
    </svg>
  );
}

function ReviewIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
    </svg>
  );
}

function PhotoIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z" />
      <circle cx="12" cy="13" r="4" />
    </svg>
  );
}

function ThresholdIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <polyline points="22 12 18 12 15 21 9 3 6 12 2 12" />
    </svg>
  );
}

function GiftIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <polyline points="20 12 20 22 4 22 4 12" />
      <rect x="2" y="7" width="20" height="5" />
      <line x1="12" y1="22" x2="12" y2="7" />
      <path d="M12 7H7.5a2.5 2.5 0 0 1 0-5C11 2 12 7 12 7z" />
      <path d="M12 7h4.5a2.5 2.5 0 0 0 0-5C13 2 12 7 12 7z" />
    </svg>
  );
}

function PercentIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <line x1="19" y1="5" x2="5" y2="19" />
      <circle cx="6.5" cy="6.5" r="2.5" />
      <circle cx="17.5" cy="17.5" r="2.5" />
    </svg>
  );
}
