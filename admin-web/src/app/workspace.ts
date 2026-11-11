import { createContext, useContext } from 'react';

export const WorkspaceContext = createContext({
  canOpen: (_section: string): boolean => false,
  openSection: (_section: string, _filter?: string) => {},
  filter: '',
});
export const useWorkspace = () => useContext(WorkspaceContext);
