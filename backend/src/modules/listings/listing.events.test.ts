import assert from 'node:assert/strict';
import { EventEmitter } from 'node:events';
import test from 'node:test';
import type { NextFunction, Request, Response } from 'express';
import { notifyViewers, watchListing } from './services/listing.events.js';

/** Response giả: ghi lại các lần write, phát 'finish' / 'close' như Express */
const fakeResponse = (statusCode = 200) => {
  const res = Object.assign(new EventEmitter(), {
    statusCode,
    written: [] as string[],
    setHeader() {},
    flushHeaders() {},
    write(chunk: string) { res.written.push(chunk); return true; },
  });
  return res;
};
const request = (id: string) => ({ params: { id } }) as unknown as Request;
const changed = (res: ReturnType<typeof fakeResponse>) => res.written.filter((c) => c.startsWith('event: changed')).length;

test('a successful change notifies only viewers of that listing', () => {
  const viewerA = fakeResponse();
  const viewerB = fakeResponse();
  watchListing(request('a'), viewerA as unknown as Response);
  watchListing(request('b'), viewerB as unknown as Response);

  const ok = fakeResponse(200);
  notifyViewers(request('a'), ok as unknown as Response, (() => {}) as NextFunction);
  ok.emit('finish');
  const failed = fakeResponse(409);
  notifyViewers(request('a'), failed as unknown as Response, (() => {}) as NextFunction);
  failed.emit('finish');
  assert.equal(changed(viewerA), 1);
  assert.equal(changed(viewerB), 0);

  viewerA.emit('close');
  ok.emit('finish');
  assert.equal(changed(viewerA), 1);
  viewerB.emit('close');
});
