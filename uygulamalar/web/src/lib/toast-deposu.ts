import { create } from 'zustand';

type ToastVariant = 'default' | 'success' | 'danger' | 'warning' | 'info';

export interface ToastItem {
  id: number;
  message: string;
  variant?: ToastVariant;
  duration?: number;
}

interface ToastState {
  toasts: ToastItem[];
  show: (props: Omit<ToastItem, 'id'>) => void;
  remove: (id: number) => void;
}

let _nextId = 0;

export const useToastDeposu = create<ToastState>((set) => ({
  toasts: [],
  show: (props) => {
    const id = ++_nextId;
    set((state) => ({ toasts: [...state.toasts, { ...props, id }] }));
  },
  remove: (id) => set((state) => ({ toasts: state.toasts.filter((t) => t.id !== id) })),
}));

export function toast(message: string, variant: ToastVariant = 'default', duration?: number) {
  useToastDeposu.getState().show({ message, variant, duration });
}
