import { test } from 'node:test';
import assert from 'node:assert/strict';
import { RatesService } from '../src/rates-service.js';

const PAYLOAD = { date: '2026-09-29', rates: { USD: 1.2, GBP: 0.8 } };

function makeService({ failAfterFirst = false } = {}) {
  let calls = 0;
  let clock = 1_000_000;
  const service = new RatesService({
    ttlMs: 1000,
    now: () => clock,
    load: async () => {
      calls += 1;
      if (failAfterFirst && calls > 1) {
        throw new Error('ecb_unavailable:503');
      }
      return PAYLOAD;
    },
  });
  return { service, calls: () => calls, advance: (ms) => (clock += ms) };
}

test('le cache évite de rappeler la BCE', async () => {
  const { service, calls } = makeService();
  await service.getLatest();
  await service.getLatest();
  assert.equal(calls(), 1);
});

test('le cache expire après le TTL', async () => {
  const { service, calls, advance } = makeService();
  await service.getLatest();
  advance(1001);
  await service.getLatest();
  assert.equal(calls(), 2);
});

test('des requêtes simultanées ne font qu’un appel à la BCE', async () => {
  const { service, calls } = makeService();
  await Promise.all([service.getLatest(), service.getLatest(), service.getLatest()]);
  assert.equal(calls(), 1);
});

test('si la BCE tombe, on sert les derniers taux marqués stale', async () => {
  const { service, advance } = makeService({ failAfterFirst: true });
  const first = await service.getLatest();
  assert.equal(first.stale, false);
  advance(5000);
  const second = await service.getLatest();
  assert.equal(second.stale, true);
  assert.equal(second.rates.USD, 1.2);
});

test('sans cache et BCE en panne, l’erreur remonte', async () => {
  const service = new RatesService({
    load: async () => {
      throw new Error('ecb_unavailable:503');
    },
  });
  await assert.rejects(() => service.getLatest(), /ecb_unavailable/);
});

test('convert passe par l’euro', () => {
  const service = new RatesService();
  const rates = { USD: 1.2, GBP: 0.8 };
  assert.equal(service.convert(120, 'USD', 'EUR', rates), 100);
  assert.equal(service.convert(100, 'EUR', 'GBP', rates), 80);
  assert.equal(service.convert(120, 'USD', 'GBP', rates), 80);
  assert.equal(service.convert(50, 'EUR', 'EUR', rates), 50);
});

test('convert renvoie null pour une devise inconnue', () => {
  const service = new RatesService();
  assert.equal(service.convert(10, 'EUR', 'XXX', { USD: 1.2 }), null);
});
