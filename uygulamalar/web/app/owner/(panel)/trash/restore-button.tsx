'use client';

import { useTransition } from 'react';
import { PanelActionButton } from '@/src/ui/components/panel-action-button';
import { restoreMenu, restoreItem, restorePhoto } from './actions';

type EntityType = 'menu' | 'item' | 'photo';

export function RestoreButton({ entityType, entityId }: { entityType: EntityType; entityId: string }) {
  const [isPending, startTransition] = useTransition();

  function handleRestore() {
    startTransition(async () => {
      if (entityType === 'menu') await restoreMenu(entityId);
      else if (entityType === 'item') await restoreItem(entityId);
      else await restorePhoto(entityId);
    });
  }

  return (
    <PanelActionButton variant="secondary" loading={isPending} onClick={handleRestore}>
      Geri Yükle
    </PanelActionButton>
  );
}
