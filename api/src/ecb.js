// Client des taux de référence quotidiens de la BCE (base EUR).
// Même source et même format de lecture que la fonction Supabase fx-ecb.

export const ECB_DAILY_URL =
  process.env.ECB_URL ?? 'https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml';

/**
 * Extrait la date et les taux du XML de la BCE.
 * @returns {{ date: string, rates: Record<string, number> }}
 * @throws {Error} si le document ne contient ni date ni taux valide
 */
export function parseEcbXml(xml) {
  const date = xml.match(/time=['"](\d{4}-\d{2}-\d{2})['"]/)?.[1];

  const rates = {};
  for (const match of xml.matchAll(/currency=['"]([A-Z]{3})['"]\s+rate=['"]([0-9.]+)['"]/g)) {
    const rate = Number(match[2]);
    if (Number.isFinite(rate) && rate > 0) {
      rates[match[1]] = rate;
    }
  }

  if (!date || Object.keys(rates).length === 0) {
    throw new Error('ecb_parse_failed');
  }
  return { date, rates };
}

/**
 * Télécharge puis analyse les taux du jour.
 * @param {typeof fetch} fetchImpl injectable pour les tests
 */
export async function fetchEcbRates(fetchImpl = fetch, url = ECB_DAILY_URL) {
  const response = await fetchImpl(url, { signal: AbortSignal.timeout(8000) });
  if (!response.ok) {
    throw new Error(`ecb_unavailable:${response.status}`);
  }
  return parseEcbXml(await response.text());
}
