import { type ReactNode } from 'react';

interface PanelEmptyStateProps {
  icon?: ReactNode;
  title: string;
  description?: string;
  action?: ReactNode;
}

export function PanelEmptyState({ icon, title, description, action }: PanelEmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center gap-4 py-16 text-center">
      {icon && (
        <div
          className="flex h-16 w-16 items-center justify-center rounded-full text-2xl text-(--yd-color-primary)"
          style={{
            background:
              'radial-gradient(circle at center, rgba(127,29,29,0.10), rgba(127,29,29,0.04))',
          }}
        >
          {icon}
        </div>
      )}
      <div>
        <p className="text-[17px] font-black text-textStrong">{title}</p>
        {description && (
          <p className="mt-1 text-sm leading-relaxed text-muted">{description}</p>
        )}
      </div>
      {action && <div className="mt-2">{action}</div>}
    </div>
  );
}
