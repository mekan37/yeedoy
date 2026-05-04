'use client';

export default function Template({ children }: { children: React.ReactNode }) {
  return (
    <div style={{ animation: 'slide-up 260ms cubic-bezier(0.22, 1, 0.36, 1) both' }}>
      {children}
    </div>
  );
}
