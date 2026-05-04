'use client';

import { clsx } from 'clsx';

interface PanelSearchFieldProps {
  value?: string;
  onChange?: (v: string) => void;
  placeholder?: string;
  name?: string;
  defaultValue?: string;
  className?: string;
}

export function PanelSearchField({
  value,
  onChange,
  placeholder = 'Ara...',
  name,
  defaultValue,
  className,
}: PanelSearchFieldProps) {
  return (
    <div className={clsx('relative flex items-center', className)}>
      <span className="pointer-events-none absolute left-3 flex h-4 w-4 items-center justify-center text-muted">
        <SearchIcon />
      </span>
      <input
        type="text"
        name={name}
        value={value}
        defaultValue={defaultValue}
        placeholder={placeholder}
        onChange={onChange ? (e) => onChange(e.target.value) : undefined}
        className={clsx(
          'h-9 w-full rounded-xl border border-border bg-bg py-2 pl-9 pr-3',
          'text-sm text-textStrong placeholder:text-muted',
          'transition-colors duration-150',
          'focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary/40',
        )}
      />
    </div>
  );
}

function SearchIcon() {
  return (
    <svg
      viewBox="0 0 20 20"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.75"
      strokeLinecap="round"
      strokeLinejoin="round"
      className="h-4 w-4"
      aria-hidden="true"
    >
      <circle cx="8.5" cy="8.5" r="5.25" />
      <line x1="12.75" y1="12.75" x2="17" y2="17" />
    </svg>
  );
}
