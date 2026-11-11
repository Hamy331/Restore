import { useState } from 'react';
import { Session } from './session';
import { useResource, type Page } from './useResource';
export function usePage<T>(session: Session, path: string) {
  const [page, setPage] = useState(1);
  const { data, error, reload } = useResource<Page<T>>(session, path + (path.includes('?') ? '&page=' : '?page=') + page);
  const pagination = {
    current: page,
    total: data?.total,
    pageSize: 25,
    showSizeChanger: false,
    onChange: setPage,
  };
  function refresh() {
    if (data?.items.length === 1 && page > 1) setPage(page - 1);
    else reload();
  }
  return { data, error, reload, pagination, refresh };
}
