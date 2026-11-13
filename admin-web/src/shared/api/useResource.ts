import { useEffect, useState } from 'react';
import { Session, errorText } from './session';
export type Page<T> = { items: T[]; total: number };
export function useResource<T>(session: Session, path: string) {
  const [revision, setRevision] = useState(0);
  const [state, set] = useState<{ path: string; data?: T; error?: string }>({ path });
  useEffect(() => {
    let current = true;
    set({ path });
    session
      .call<T>(path)
      .then((data) => {
        if (current) set({ path, data });
      })
      .catch((err) => {
        if (current) set({ path, error: errorText(err) });
      });
    return () => {
      current = false;
    };
  }, [session, path, revision]);
  return { ...(state.path === path ? state : {}), reload: () => setRevision((n) => n + 1) };
}
