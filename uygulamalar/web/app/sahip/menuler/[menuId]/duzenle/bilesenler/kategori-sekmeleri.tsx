import { Section } from '../menu-duzenleyici-yardimcilari';

export function KategoriSekmeleri({
  sections,
  itemCounts,
  activeSectionId,
  onChange,
}: {
  sections: Section[];
  itemCounts: Record<string, number>;
  activeSectionId: string | null;
  onChange: (sectionId: string | null) => void;
}) {
  const toplam = Object.values(itemCounts).reduce((sum, n) => sum + n, 0);

  return (
    <div className="flex flex-wrap gap-1 border-b border-border">
      <SekmeButonu
        label="Tümü"
        count={toplam}
        active={activeSectionId === null}
        onClick={() => onChange(null)}
      />
      {sections.map((section) => (
        <SekmeButonu
          key={section.id}
          label={section.title}
          count={itemCounts[section.id] ?? 0}
          active={activeSectionId === section.id}
          onClick={() => onChange(section.id)}
        />
      ))}
    </div>
  );
}

function SekmeButonu({
  label,
  count,
  active,
  onClick,
}: {
  label: string;
  count: number;
  active: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`shrink-0 border-b-2 px-3 py-2 text-sm font-bold transition-colors cursor-pointer ${
        active
          ? 'border-primary text-primary'
          : 'border-transparent text-muted hover:text-textStrong'
      }`}
    >
      {label} <span className="text-xs font-semibold text-muted">({count})</span>
    </button>
  );
}
