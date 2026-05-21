import { create } from 'zustand';

interface WebKabukStore {
  isDrawerOpen: boolean;
  openDrawer: () => void;
  closeDrawer: () => void;
  toggleDrawer: () => void;
}

export const useWebKabukStore = create<WebKabukStore>()((set) => ({
  isDrawerOpen: false,
  openDrawer:  () => set({ isDrawerOpen: true }),
  closeDrawer: () => set({ isDrawerOpen: false }),
  toggleDrawer: () => set((s) => ({ isDrawerOpen: !s.isDrawerOpen })),
}));
