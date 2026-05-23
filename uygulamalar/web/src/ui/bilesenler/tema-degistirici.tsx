'use client';

import { useEffect, useState } from 'react';

type Theme = 'light' | 'dark' | 'system';

function getApplied(): 'light' | 'dark' {
  if (typeof window === 'undefined') return 'light';
  const html = document.documentElement;
  if (html.classList.contains('dark')) return 'dark';
  if (html.classList.contains('light')) return 'light';
  const stored = localStorage.getItem('yd-theme') as Theme | null;
  if (stored === 'dark') return 'dark';
  if (stored === 'light') return 'light';
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
}

function apply(theme: Theme) {
  const html = document.documentElement;
  html.classList.remove('dark', 'light');
  if (theme === 'dark') {
    html.classList.add('dark');
    html.style.colorScheme = 'dark';
  } else if (theme === 'light') {
    html.classList.add('light');
    html.style.colorScheme = 'light';
  } else {
    html.style.colorScheme = '';
  }
  localStorage.setItem('yd-theme', theme);
  window.dispatchEvent(new CustomEvent('yd-theme-change', { detail: { theme } }));
}

export function ThemeToggle({ className = '' }: { className?: string }) {
  const [applied, setApplied] = useState<'light' | 'dark'>('light');

  useEffect(() => {
    setApplied(getApplied());
    function handleThemeChange() {
      setApplied(getApplied());
    }
    window.addEventListener('storage', handleThemeChange);
    window.addEventListener('yd-theme-change', handleThemeChange);
    return () => {
      window.removeEventListener('storage', handleThemeChange);
      window.removeEventListener('yd-theme-change', handleThemeChange);
    };
  }, []);

  function toggle() {
    const current = getApplied();
    const next: Theme = current === 'dark' ? 'light' : 'dark';
    apply(next);
    setApplied(next);
  }

  const isDark = applied === 'dark';

  return (
    <button
      type="button"
      onClick={toggle}
      aria-label={isDark ? 'Açık moda geç' : 'Karanlık moda geç'}
      className={`inline-flex min-h-[40px] min-w-[40px] items-center justify-center rounded-full border border-border bg-cardAlt text-muted transition-all duration-200 hover:border-primary/30 hover:text-textStrong focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30 ${className}`}
    >
      {isDark ? <SunIcon /> : <MoonIcon />}
    </button>
  );
}

function SunIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <circle cx="12" cy="12" r="5"/>
      <line x1="12" y1="1" x2="12" y2="3"/>
      <line x1="12" y1="21" x2="12" y2="23"/>
      <line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/>
      <line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/>
      <line x1="1" y1="12" x2="3" y2="12"/>
      <line x1="21" y1="12" x2="23" y2="12"/>
      <line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/>
      <line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/>
    </svg>
  );
}

function MoonIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>
    </svg>
  );
}
