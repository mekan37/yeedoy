import type { BusinessBadge } from '@/src/lib/businessBadges';

interface Props {
  badges: BusinessBadge[];
}

const tierColors: Record<string, string> = {
  gold: '#FFD700',
  silver: '#9E9E9E',
  special: '#9C27B0',
  bronze: '#CD7F32',
};

export function BusinessBadges({ badges }: Props) {
  if (badges.length === 0) return null;

  return (
    <div className="flex flex-wrap gap-2 my-3">
      {badges.map((badge) => {
        const color = tierColors[badge.tier] ?? tierColors.bronze;
        return (
          <span
            key={badge.id}
            className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold border"
            style={{
              color,
              borderColor: `${color}66`,
              backgroundColor: `${color}1A`,
            }}
          >
            {badge.title}
          </span>
        );
      })}
    </div>
  );
}
