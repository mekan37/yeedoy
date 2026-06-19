import { SkeletonText } from '@yeedoy/web-ui';

export function SingleLine() {
  return (
    <div style={{ padding: 24, width: 320, background: '#fff' }}>
      <SkeletonText />
    </div>
  );
}

export function ThreeLines() {
  return (
    <div style={{ padding: 24, width: 320, background: '#fff' }}>
      <SkeletonText lines={3} />
    </div>
  );
}

export function FiveLines() {
  return (
    <div style={{ padding: 24, width: 320, background: '#fff' }}>
      <SkeletonText lines={5} />
    </div>
  );
}
