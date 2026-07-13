'use client';

import { useActionState, useState } from 'react';
import { PanelActionButton } from '@/src/ui/components/panel-action-button';
import { PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { updateReservationSettings } from '../actions';
import type { BusinessData } from '../settings-client';

const INPUT_CLASS =
  'min-h-11 w-full rounded-lg border border-border bg-bg px-3 py-2 text-sm text-textStrong outline-none transition-colors placeholder:text-muted focus-visible:border-primary focus-visible:ring-2 focus-visible:ring-primary/20 disabled:cursor-not-allowed disabled:opacity-60';

function getPartyDefaults(business: BusinessData) {
  const storedMinimum = business.reservation_min_party;
  const storedMaximum = business.reservation_max_party;
  const minimum =
    storedMinimum !== null && storedMinimum >= 1 && storedMinimum <= 99
      ? storedMinimum
      : 1;
  const maximumCandidate =
    storedMaximum !== null && storedMaximum >= 1 && storedMaximum <= 99
      ? storedMaximum
      : 20;

  return { minimum, maximum: Math.max(minimum, maximumCandidate) };
}

export function RezervasyonAyarlariTab({ business }: { business: BusinessData }) {
  const [state, formAction, isPending] = useActionState(
    updateReservationSettings.bind(null, business.id),
    null,
  );
  const [formChanged, setFormChanged] = useState(false);
  const { minimum, maximum } = getPartyDefaults(business);
  const feedbackId = 'reservation-settings-feedback';
  const showFeedback = Boolean(state) && !formChanged && !isPending;

  return (
    <PanelSectionCard
      title="Rezervasyon Ayarları"
      description="Rezervasyon kabul durumunu ve müşterilere gösterilecek bilgileri yönetin."
    >
      <form
        action={formAction}
        aria-describedby={showFeedback ? feedbackId : undefined}
        className="flex flex-col gap-6"
        onChangeCapture={() => setFormChanged(true)}
        onReset={() => setFormChanged(true)}
        onSubmit={() => setFormChanged(false)}
      >
        <label className="flex min-h-11 cursor-pointer items-center justify-between gap-4 border-b border-border pb-5">
          <span className="min-w-0">
            <span className="block text-sm font-[700] text-textStrong">
              Rezervasyonları kabul et
            </span>
            <span id="accepts-reservations-description" className="mt-1 block text-xs text-muted">
              Müşteriler işletme sayfanız üzerinden rezervasyon talebi gönderebilir.
            </span>
          </span>
          <span className="relative flex min-h-11 min-w-11 shrink-0 items-center justify-center">
            <input
              type="checkbox"
              role="switch"
              name="accepts_reservations"
              defaultChecked={business.accepts_reservations}
              aria-describedby="accepts-reservations-description"
              className="peer sr-only"
            />
            <span
              aria-hidden="true"
              className="relative h-6 w-11 rounded-full bg-borderStrong transition-colors after:absolute after:left-0.5 after:top-0.5 after:h-5 after:w-5 after:rounded-full after:bg-card after:shadow-sm after:transition-transform after:content-[''] peer-checked:bg-primary peer-checked:after:translate-x-5 peer-focus-visible:ring-2 peer-focus-visible:ring-primary/30 peer-focus-visible:ring-offset-2 peer-focus-visible:ring-offset-card"
            />
          </span>
        </label>

        <div className="grid gap-5 sm:grid-cols-2">
          <div className="sm:col-span-2">
            <label htmlFor="reservation-phone" className="text-xs font-[700] text-muted">
              Rezervasyon telefonu
            </label>
            <p id="reservation-phone-help" className="mb-2 mt-1 text-xs text-muted">
              Müşterilerin rezervasyon için ulaşacağı telefon numarası.
            </p>
            <input
              id="reservation-phone"
              name="reservation_phone"
              type="tel"
              inputMode="tel"
              autoComplete="tel"
              defaultValue={business.reservation_phone ?? ''}
              placeholder={business.phone ?? '+90 555 000 00 00'}
              maxLength={30}
              aria-describedby="reservation-phone-help"
              className={INPUT_CLASS}
            />
          </div>

          <div>
            <label htmlFor="reservation-min-party" className="text-xs font-[700] text-muted">
              Minimum kişi sayısı
            </label>
            <input
              id="reservation-min-party"
              name="reservation_min_party"
              type="number"
              inputMode="numeric"
              min={1}
              max={99}
              defaultValue={minimum}
              required
              className={`${INPUT_CLASS} mt-2`}
            />
          </div>

          <div>
            <label htmlFor="reservation-max-party" className="text-xs font-[700] text-muted">
              Maksimum kişi sayısı
            </label>
            <input
              id="reservation-max-party"
              name="reservation_max_party"
              type="number"
              inputMode="numeric"
              min={1}
              max={99}
              defaultValue={maximum}
              required
              className={`${INPUT_CLASS} mt-2`}
            />
          </div>
        </div>

        <div>
          <label htmlFor="reservation-note" className="text-xs font-[700] text-muted">
            Rezervasyon notu
          </label>
          <p id="reservation-note-help" className="mb-2 mt-1 text-xs text-muted">
            Koşullar, uygun saatler veya müşterilerin bilmesi gereken diğer ayrıntılar.
          </p>
          <textarea
            id="reservation-note"
            name="reservation_note"
            defaultValue={business.reservation_note ?? ''}
            maxLength={500}
            rows={4}
            aria-describedby="reservation-note-help"
            className={`${INPUT_CLASS} resize-y`}
          />
        </div>

        {state && showFeedback && (
          <p
            id={feedbackId}
            role={'error' in state ? 'alert' : 'status'}
            aria-live="polite"
            className={`rounded-lg border px-3 py-2 text-sm ${
              'error' in state
                ? 'border-danger/20 bg-danger/5 text-danger'
                : 'border-success/20 bg-success/5 text-success'
            }`}
          >
            {'error' in state ? state.error : 'Rezervasyon ayarları kaydedildi.'}
          </p>
        )}

        <div className="flex justify-stretch border-t border-border pt-5 sm:justify-end">
          <PanelActionButton
            type="submit"
            variant="primary"
            loading={isPending}
            className="min-h-11 w-full justify-center sm:w-auto"
          >
            {isPending ? 'Kaydediliyor...' : 'Değişiklikleri Kaydet'}
          </PanelActionButton>
        </div>
      </form>
    </PanelSectionCard>
  );
}
