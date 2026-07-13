'use client';

import { useActionState, useState } from 'react';
import { Eye, EyeOff, KeyRound, ShieldCheck } from 'lucide-react';
import { PanelActionButton } from '@/src/ui/components/panel-action-button';
import { PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { updatePassword } from '../actions';

const INPUT_CLASS =
  'min-h-11 w-full rounded-xl border border-border bg-bg px-3 pr-12 text-sm text-textStrong outline-none transition-colors placeholder:text-muted/70 focus:border-primary focus:ring-2 focus:ring-primary/20';

export function GizlilikGuvenlikTab() {
  const [state, action, isPending] = useActionState(updatePassword, null);
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmation, setShowConfirmation] = useState(false);
  const [formChanged, setFormChanged] = useState(false);
  const showFeedback = Boolean(state) && !formChanged && !isPending;

  return (
    <PanelSectionCard
      title="Şifre Güvenliği"
      description="Hesabınız için en az 8 karakterli, benzersiz bir şifre kullanın."
    >
      <div className="mb-5 flex gap-3 border-b border-border pb-5">
        <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-cardAlt text-primary">
          <ShieldCheck aria-hidden="true" className="h-5 w-5" />
        </span>
        <div>
          <p className="text-sm font-[700] text-textStrong">Hesap erişiminizi koruyun</p>
          <p className="mt-0.5 text-xs text-muted">
            Başka hizmetlerde kullandığınız bir şifreyi tekrar kullanmayın.
          </p>
        </div>
      </div>

      <form
        action={action}
        className="max-w-lg space-y-4"
        onChangeCapture={() => setFormChanged(true)}
        onReset={() => setFormChanged(true)}
        onSubmit={() => setFormChanged(false)}
      >
        <PasswordField
          id="new-password"
          name="password"
          label="Yeni şifre"
          visible={showPassword}
          onToggle={() => setShowPassword((value) => !value)}
          autoComplete="new-password"
        />
        <PasswordField
          id="confirm-password"
          name="confirm_password"
          label="Yeni şifreyi doğrulayın"
          visible={showConfirmation}
          onToggle={() => setShowConfirmation((value) => !value)}
          autoComplete="new-password"
        />

        <div aria-live="polite" className="min-h-5">
          {state && showFeedback && 'error' in state ? (
            <p role="alert" className="text-sm font-[700] text-danger">
              {state.error}
            </p>
          ) : null}
          {state && showFeedback && 'success' in state ? (
            <p role="status" className="text-sm font-[700] text-success">
              Şifreniz güncellendi.
            </p>
          ) : null}
        </div>

        <div className="flex justify-end">
          <PanelActionButton
            type="submit"
            variant="primary"
            loading={isPending}
            icon={<KeyRound aria-hidden="true" className="h-4 w-4" />}
            className="min-h-11"
          >
            {isPending ? 'Güncelleniyor' : 'Şifreyi Güncelle'}
          </PanelActionButton>
        </div>
      </form>
    </PanelSectionCard>
  );
}

function PasswordField({
  id,
  name,
  label,
  visible,
  onToggle,
  autoComplete,
}: {
  id: string;
  name: string;
  label: string;
  visible: boolean;
  onToggle: () => void;
  autoComplete: string;
}) {
  return (
    <div>
      <label htmlFor={id} className="mb-1.5 block text-xs font-[700] text-muted">
        {label}
      </label>
      <div className="relative">
        <input
          id={id}
          name={name}
          type={visible ? 'text' : 'password'}
          minLength={8}
          maxLength={72}
          required
          autoComplete={autoComplete}
          className={INPUT_CLASS}
        />
        <button
          type="button"
          onClick={onToggle}
          aria-label={visible ? `${label} alanını gizle` : `${label} alanını göster`}
          aria-pressed={visible}
          className="absolute inset-y-0 right-0 flex min-h-11 w-11 items-center justify-center rounded-r-xl text-muted transition-colors hover:text-textStrong focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-primary/30"
        >
          {visible ? (
            <EyeOff aria-hidden="true" className="h-5 w-5" />
          ) : (
            <Eye aria-hidden="true" className="h-5 w-5" />
          )}
        </button>
      </div>
    </div>
  );
}
