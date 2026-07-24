import { clsx } from 'clsx';
import { type ReactNode } from 'react';

interface PanelDataTableProps {
  children: ReactNode;
  className?: string;
}

export function PanelDataTable({ children, className }: PanelDataTableProps) {
  return (
    <div className={clsx('w-full overflow-x-auto', className)}>
      <table className="w-full min-w-[640px] text-sm">
        {children}
      </table>
    </div>
  );
}

interface PanelDataTableHeaderProps {
  children: ReactNode;
  className?: string;
}

export function PanelDataTableHeader({ children, className }: PanelDataTableHeaderProps) {
  return (
    <th
      className={clsx(
        'border-b border-border px-4 py-2.5 text-left text-xs font-extrabold uppercase tracking-wide text-muted',
        className,
      )}
    >
      {children}
    </th>
  );
}

interface PanelDataTableRowProps {
  children: ReactNode;
  className?: string;
}

export function PanelDataTableRow({ children, className }: PanelDataTableRowProps) {
  return (
    <tr
      className={clsx(
        'border-b border-border transition-colors duration-100 last:border-0',
        'hover:bg-black/2.5',
        className,
      )}
    >
      {children}
    </tr>
  );
}

interface PanelDataTableCellProps {
  children: ReactNode;
  className?: string;
}

export function PanelDataTableCell({ children, className }: PanelDataTableCellProps) {
  return (
    <td className={clsx('px-4 py-3 text-textStrong', className)}>
      {children}
    </td>
  );
}
