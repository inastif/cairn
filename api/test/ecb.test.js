import { test } from 'node:test';
import assert from 'node:assert/strict';
import { parseEcbXml, fetchEcbRates } from '../src/ecb.js';

const SAMPLE_XML = `<?xml version="1.0" encoding="UTF-8"?>
<gesmes:Envelope xmlns:gesmes="http://www.gesmes.org/xml/2002-08-01" xmlns="http://www.ecb.int/vocabulary/2002-08-01/eurofxref">
  <Cube>
    <Cube time='2026-09-29'>
      <Cube currency='USD' rate='1.1725'/>
      <Cube currency='JPY' rate='172.30'/>
      <Cube currency='GBP' rate='0.8650'/>
    </Cube>
  </Cube>
</gesmes:Envelope>`;

test('parseEcbXml extrait la date et les taux', () => {
  const { date, rates } = parseEcbXml(SAMPLE_XML);
  assert.equal(date, '2026-09-29');
  assert.deepEqual(rates, { USD: 1.1725, JPY: 172.3, GBP: 0.865 });
});

test('parseEcbXml refuse un document sans taux', () => {
  assert.throws(() => parseEcbXml('<html>maintenance</html>'), /ecb_parse_failed/);
});

test('parseEcbXml ignore un taux nul ou invalide', () => {
  const xml = `<Cube time='2026-09-29'><Cube currency='USD' rate='0'/><Cube currency='GBP' rate='0.86'/></Cube>`;
  assert.deepEqual(parseEcbXml(xml).rates, { GBP: 0.86 });
});

test('fetchEcbRates signale une BCE indisponible', async () => {
  const fakeFetch = async () => ({ ok: false, status: 503 });
  await assert.rejects(() => fetchEcbRates(fakeFetch), /ecb_unavailable:503/);
});

test('fetchEcbRates lit la réponse de la BCE', async () => {
  const fakeFetch = async () => ({ ok: true, text: async () => SAMPLE_XML });
  const { date } = await fetchEcbRates(fakeFetch);
  assert.equal(date, '2026-09-29');
});
