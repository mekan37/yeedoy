import type { SadakatProgram } from './sadakat-kurulum-istemcisi';

export function ProgramOnizleme({ program }: { program: SadakatProgram }) {
  const dolu = 0; // Yeni bir müşterinin kartı her zaman boş başlar — gerçekçi önizleme.

  return (
    <div
      className="flex flex-col items-center gap-4 rounded-2xl border border-border p-6 text-center"
      style={{ background: 'linear-gradient(160deg, #fdf6ec, #fbeee0)' }}
    >
      <span className="flex h-14 w-14 items-center justify-center rounded-2xl bg-white text-2xl shadow-xs">
        {program.mode === 'stamp' ? '☕' : '⭐'}
      </span>
      <div>
        <p className="text-lg font-black text-textStrong">
          {program.mode === 'stamp'
            ? `${program.reward_threshold} damga topla,`
            : `${program.reward_threshold} puan topla,`}
        </p>
        <p className="text-lg font-black text-primary">{program.reward_desc}!</p>
      </div>

      {program.mode === 'stamp' ? (
        <div className="grid grid-cols-5 gap-2.5">
          {Array.from({ length: program.reward_threshold }, (_, i) => (
            <div
              key={i}
              className={
                i < dolu
                  ? 'flex h-10 w-10 items-center justify-center rounded-full border-2 border-primary bg-primary/10 text-primary'
                  : 'flex h-10 w-10 items-center justify-center rounded-full border-2 border-dashed border-border text-muted/40'
              }
            >
              ☕
            </div>
          ))}
        </div>
      ) : (
        <div className="w-full max-w-[220px] rounded-xl border border-border bg-white/70 px-4 py-3">
          <div className="h-2.5 w-full overflow-hidden rounded-full bg-black/5">
            <div className="h-full rounded-full bg-primary" style={{ width: '0%' }} />
          </div>
          <p className="mt-1.5 text-xs font-bold text-muted">0 / {program.reward_threshold} puan</p>
        </div>
      )}

      <p className="text-xs text-muted">Yeni bir müşterinin kartı bu şekilde başlar.</p>
    </div>
  );
}
