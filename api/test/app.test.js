import { test } from 'node:test';
import assert from 'node:assert/strict';
import { buildApp } from '../src/app.js';
import { RatesService } from '../src/rates-service.js';

function appWith(load) {
  const ratesService = new RatesService({ load });
  return buildApp({ ratesService });
}

const okLoad = async () => ({ date: '2026-09-29', rates: { USD: 1.2, GBP: 0.8, JPY: 160 } });
const failLoad = async () => {
  throw new Error('ecb_unavailable:503');
};

test('GET /health répond ok', async () => {
  const app = appWith(okLoad);
  const res = await app.inject({ method: 'GET', url: '/health' });
  assert.equal(res.statusCode, 200);
  assert.deepEqual(res.json(), { status: 'ok' });
});

test('GET /fx/latest renvoie les taux au format BCE', async () => {
  const app = appWith(okLoad);
  const res = await app.inject({ method: 'GET', url: '/fx/latest' });
  assert.equal(res.statusCode, 200);
  const body = res.json();
  assert.equal(body.base, 'EUR');
  assert.equal(body.source, 'BCE');
  assert.equal(body.date, '2026-09-29');
  assert.equal(body.rates.USD, 1.2);
  assert.equal(body.stale, false);
});

test('GET /fx/latest renvoie 502 si la BCE est injoignable', async () => {
  const app = appWith(failLoad);
  const res = await app.inject({ method: 'GET', url: '/fx/latest' });
  assert.equal(res.statusCode, 502);
  assert.deepEqual(res.json(), { error: 'ecb_unavailable' });
});

test('GET /fx/convert convertit un montant', async () => {
  const app = appWith(okLoad);
  const res = await app.inject({ method: 'GET', url: '/fx/convert?from=usd&to=gbp&amount=120' });
  assert.equal(res.statusCode, 200);
  const body = res.json();
  assert.equal(body.from, 'USD');
  assert.equal(body.to, 'GBP');
  assert.equal(body.result, 80);
});

test('GET /fx/convert refuse une devise inconnue (422)', async () => {
  const app = appWith(okLoad);
  const res = await app.inject({ method: 'GET', url: '/fx/convert?from=EUR&to=XYZ&amount=10' });
  assert.equal(res.statusCode, 422);
  assert.equal(res.json().error, 'unsupported_currency');
});

test('GET /fx/convert valide les paramètres (400)', async () => {
  const app = appWith(okLoad);
  for (const url of [
    '/fx/convert?from=EUR&to=USD',
    '/fx/convert?from=EURO&to=USD&amount=10',
    '/fx/convert?from=EUR&to=USD&amount=abc',
    '/fx/convert?from=EUR&to=USD&amount=-5',
  ]) {
    const res = await app.inject({ method: 'GET', url });
    assert.equal(res.statusCode, 400, url);
  }
});

test('GET /fx/convert renvoie 502 si la BCE est injoignable', async () => {
  const app = appWith(failLoad);
  const res = await app.inject({ method: 'GET', url: '/fx/convert?from=EUR&to=USD&amount=10' });
  assert.equal(res.statusCode, 502);
});
