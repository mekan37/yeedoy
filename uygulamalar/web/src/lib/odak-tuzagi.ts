import { useEffect, useRef, type RefObject } from 'react';

// Basit bir modal focus-trap: modal açıkken Tab/Shift+Tab yalnızca modal
// içindeki odaklanabilir öğeler arasında döner (arkadaki sayfa içeriği
// görsel olarak gizli ama hâlâ DOM'da ve tab-erişilebilir olduğu için
// gerekli). Kapanışta odağı tetikleyen elemana geri verir.
export function useModalFocusTrap(
  active: boolean,
  dialogRef: RefObject<HTMLElement | null>,
  triggerRef?: RefObject<HTMLElement | null>,
  onEscape?: () => void,
) {
  const onEscapeRef = useRef(onEscape);
  useEffect(() => {
    onEscapeRef.current = onEscape;
  });

  useEffect(() => {
    if (!active) return;

    function getFocusable(): HTMLElement[] {
      const root = dialogRef.current;
      if (!root) return [];
      return Array.from(
        root.querySelectorAll<HTMLElement>(
          'a[href], button:not([disabled]), textarea, input, select, [tabindex]:not([tabindex="-1"])',
        ),
      );
    }

    function onKey(e: KeyboardEvent) {
      if (e.key === 'Escape' && onEscapeRef.current) { onEscapeRef.current(); return; }
      if (e.key !== 'Tab') return;

      const focusable = getFocusable();
      if (focusable.length === 0) return;
      const first = focusable[0];
      const last = focusable[focusable.length - 1];
      const activeEl = document.activeElement;
      const inDialog = !!activeEl && !!dialogRef.current?.contains(activeEl);

      if (e.shiftKey && activeEl === first) {
        e.preventDefault();
        last.focus();
      } else if (!e.shiftKey && activeEl === last) {
        e.preventDefault();
        first.focus();
      } else if (!inDialog) {
        e.preventDefault();
        first.focus();
      }
    }

    window.addEventListener('keydown', onKey);
    const focusable = getFocusable();
    (focusable[0] ?? dialogRef.current)?.focus();
    const triggerEl = triggerRef?.current;

    return () => {
      window.removeEventListener('keydown', onKey);
      triggerEl?.focus();
    };
  }, [active, dialogRef, triggerRef]);
}
