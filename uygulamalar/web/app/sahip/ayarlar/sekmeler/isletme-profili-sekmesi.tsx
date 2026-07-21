'use client';

import { useActionState, useState, type ReactNode } from 'react';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { BrandingEditor } from './isletme-gorselleri-editoru';
import { updateBusinessProfile, updateContactInfo } from '../ayarlar-islemleri';
import type { ActionState } from '../ayarlar-islemleri';
import { HoursForm, type WeeklyHourRow } from '../saatler/saatler-formu';
import type { BusinessData } from '../ayarlar-istemcisi';

interface IsletmeProfilTabProps {
  business: BusinessData;
  hours: WeeklyHourRow[];
}

const INPUT_CLASS =
  'min-h-11 w-full rounded-xl border border-border bg-bg px-3 text-sm text-textStrong outline-none transition-colors placeholder:text-muted focus:border-primary focus:ring-2 focus:ring-primary/20';
const LABEL_CLASS = 'text-xs font-[700] text-muted';

const SOCIAL_FIELDS = [
  {
    name: 'instagram_url',
    label: 'Instagram',
    placeholder: 'https://instagram.com/...',
  },
  {
    name: 'facebook_url',
    label: 'Facebook',
    placeholder: 'https://facebook.com/...',
  },
  {
    name: 'twitter_url',
    label: 'Twitter / X',
    placeholder: 'https://x.com/...',
  },
] as const;

export function IsletmeProfilTab({ business, hours }: IsletmeProfilTabProps) {
  const [profileState, profileAction, profilePending] = useActionState(
    updateBusinessProfile.bind(null, business.id),
    null,
  );
  const [contactState, contactAction, contactPending] = useActionState(
    updateContactInfo.bind(null, business.id),
    null,
  );
  const [profileChanged, setProfileChanged] = useState(false);
  const [contactChanged, setContactChanged] = useState(false);

  const socialValues: Record<(typeof SOCIAL_FIELDS)[number]['name'], string | null> = {
    instagram_url: business.instagram_url,
    facebook_url: business.facebook_url,
    twitter_url: business.twitter_url,
  };

  return (
    <div className="space-y-6">
      <div className="grid items-start gap-6 lg:grid-cols-[minmax(0,1.7fr)_minmax(18rem,0.9fr)]">
        <PanelBolumKarti
          title="İşletme Bilgileri"
          description="İşletmenizin temel bilgilerini düzenleyin."
        >
          <form
            action={profileAction}
            className="space-y-5"
            onChangeCapture={() => setProfileChanged(true)}
            onReset={() => setProfileChanged(true)}
            onSubmit={() => setProfileChanged(false)}
          >
            <div className="grid gap-4 sm:grid-cols-2">
              <FormField id="business-name" label="İşletme Adı">
                <input
                  id="business-name"
                  name="name"
                  defaultValue={business.name}
                  required
                  maxLength={120}
                  autoComplete="organization"
                  className={INPUT_CLASS}
                />
              </FormField>
              <FormField id="business-category" label="Kategori">
                <input
                  id="business-category"
                  name="category"
                  defaultValue={business.category}
                  required
                  maxLength={80}
                  className={INPUT_CLASS}
                />
              </FormField>
              <FormField id="business-phone" label="Telefon">
                <input
                  id="business-phone"
                  name="phone"
                  type="tel"
                  defaultValue={business.phone ?? ''}
                  maxLength={30}
                  autoComplete="tel"
                  className={INPUT_CLASS}
                />
              </FormField>
              <FormField id="business-email" label="E-posta">
                <input
                  id="business-email"
                  name="email"
                  type="email"
                  defaultValue={business.email ?? ''}
                  maxLength={255}
                  autoComplete="email"
                  className={INPUT_CLASS}
                />
              </FormField>
            </div>

            <FormField id="business-address" label="Adres">
              <input
                id="business-address"
                name="address"
                defaultValue={business.address ?? ''}
                maxLength={300}
                autoComplete="street-address"
                className={INPUT_CLASS}
              />
            </FormField>

            <div className="grid gap-4 sm:grid-cols-2">
              <FormField id="business-city" label="Şehir">
                <input
                  id="business-city"
                  name="city"
                  defaultValue={business.city ?? ''}
                  maxLength={80}
                  autoComplete="address-level1"
                  className={INPUT_CLASS}
                />
              </FormField>
              <FormField id="business-district" label="İlçe">
                <input
                  id="business-district"
                  name="district"
                  defaultValue={business.district ?? ''}
                  maxLength={80}
                  autoComplete="address-level2"
                  className={INPUT_CLASS}
                />
              </FormField>
            </div>

            <FormField id="business-description" label="Açıklama">
              <textarea
                id="business-description"
                name="description"
                defaultValue={business.description ?? ''}
                maxLength={1000}
                rows={4}
                className={`${INPUT_CLASS} resize-y py-3`}
              />
            </FormField>

            <ActionMessage
              state={profileState}
              successMessage="İşletme bilgileri kaydedildi."
              hidden={profileChanged || profilePending}
            />

            <div className="flex flex-wrap justify-end gap-3 border-t border-border pt-5">
              <PanelActionButton type="reset" variant="secondary" className="min-h-11">
                İptal
              </PanelActionButton>
              <PanelActionButton
                type="submit"
                variant="primary"
                loading={profilePending}
                className="min-h-11"
              >
                Değişiklikleri Kaydet
              </PanelActionButton>
            </div>
          </form>
        </PanelBolumKarti>

        <section aria-labelledby="business-branding-heading" className="min-w-0">
          <div className="mb-3 px-1">
            <h2 id="business-branding-heading" className="text-[15px] font-[900] text-textStrong">
              İşletme Görselleri
            </h2>
            <p className="mt-0.5 text-xs text-muted">
              Logonuzu ve profil kapağınızı yönetin.
            </p>
          </div>
          <BrandingEditor
            businessId={business.id}
            initialLogoUrl={business.logo_url}
            initialCoverUrl={business.cover_url}
            businessName={business.name}
          />
        </section>
      </div>

      <div className="grid items-start gap-6 lg:grid-cols-2">
        <PanelBolumKarti
          title="Çalışma Saatleri"
          description="Haftalık açılış ve kapanış saatlerinizi düzenleyin."
        >
          <HoursForm businessId={business.id} hours={hours.length > 0 ? hours : null} />
        </PanelBolumKarti>

        <PanelBolumKarti
          title="İletişim Bilgileri"
          description="Müşterilerin size ulaşabileceği bağlantıları yönetin."
        >
          <form
            action={contactAction}
            className="space-y-5"
            onChangeCapture={() => setContactChanged(true)}
            onReset={() => setContactChanged(true)}
            onSubmit={() => setContactChanged(false)}
          >
            <FormField id="business-website" label="Web Sitesi">
              <input
                id="business-website"
                name="website_url"
                type="url"
                inputMode="url"
                defaultValue={business.website_url ?? ''}
                maxLength={500}
                placeholder="https://ornek.com"
                autoComplete="url"
                className={INPUT_CLASS}
              />
            </FormField>

            <fieldset className="space-y-3">
              <legend className={LABEL_CLASS}>Sosyal Medya</legend>
              {SOCIAL_FIELDS.map((field) => {
                const id = `business-${field.name}`;
                return (
                  <div key={field.name} className="grid gap-1.5 sm:grid-cols-[6rem_minmax(0,1fr)] sm:items-center sm:gap-3">
                    <label htmlFor={id} className={LABEL_CLASS}>
                      {field.label}
                    </label>
                    <input
                      id={id}
                      name={field.name}
                      type="url"
                      inputMode="url"
                      defaultValue={socialValues[field.name] ?? ''}
                      maxLength={500}
                      placeholder={field.placeholder}
                      className={INPUT_CLASS}
                    />
                  </div>
                );
              })}
            </fieldset>

            <ActionMessage
              state={contactState}
              successMessage="İletişim bilgileri kaydedildi."
              hidden={contactChanged || contactPending}
            />

            <div className="flex justify-end border-t border-border pt-5">
              <PanelActionButton
                type="submit"
                variant="primary"
                loading={contactPending}
                className="min-h-11"
              >
                İletişim Bilgilerini Kaydet
              </PanelActionButton>
            </div>
          </form>
        </PanelBolumKarti>
      </div>
    </div>
  );
}

function FormField({
  id,
  label,
  children,
}: {
  id: string;
  label: string;
  children: ReactNode;
}) {
  return (
    <div className="flex min-w-0 flex-col gap-1.5">
      <label htmlFor={id} className={LABEL_CLASS}>
        {label}
      </label>
      {children}
    </div>
  );
}

function ActionMessage({
  state,
  successMessage,
  hidden = false,
}: {
  state: ActionState;
  successMessage: string;
  hidden?: boolean;
}) {
  if (!state || hidden) return null;

  if ('error' in state) {
    return (
      <p role="alert" className="rounded-xl bg-danger/10 px-3 py-2.5 text-sm font-[700] text-danger">
        {state.error}
      </p>
    );
  }

  return (
    <p role="status" aria-live="polite" className="rounded-xl bg-success/10 px-3 py-2.5 text-sm font-[700] text-success">
      {successMessage}
    </p>
  );
}
