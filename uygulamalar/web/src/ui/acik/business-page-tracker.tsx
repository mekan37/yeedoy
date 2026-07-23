'use client';

import { useEffect } from 'react';

async function fireEvent(eventName: string, businessId: string, source: string) {
  try {
    await fetch('/sunucu/izleme', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ eventName, businessId, source }),
      keepalive: true,
    });
  } catch {
    // tracking failures are silent
  }
}

/** Fires business_page_view on mount. Renders nothing. */
export function BusinessPageTracker({ businessId }: { businessId: string }) {
  useEffect(() => {
    void fireEvent('business_page_view', businessId, 'business_page');
  }, [businessId]);

  return null;
}

/** Wraps a link and fires a click event before navigation. */
export function TrackedLink({
  eventName,
  businessId,
  source,
  href,
  children,
  className,
  target,
  rel,
}: {
  eventName: 'directions_click' | 'phone_click' | 'whatsapp_click';
  businessId: string;
  source: string;
  href: string;
  children: React.ReactNode;
  className?: string;
  target?: string;
  rel?: string;
}) {
  function handleClick() {
    void fireEvent(eventName, businessId, source);
  }

  return (
    <a href={href} target={target} rel={rel} className={className} onClick={handleClick}>
      {children}
    </a>
  );
}
