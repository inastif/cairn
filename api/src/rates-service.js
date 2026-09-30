import { fetchEcbRates } from './ecb.js';

const SIX_HOURS_MS = 6 * 60 * 60 * 1000;

/**
 * Garde les derniers taux en mémoire pour ne pas solliciter la BCE à chaque
 * requête (elle publie une fois par jour ouvré). Si la BCE est injoignable, on
 * continue de servir les derniers taux connus, marqués `stale: true`.
 */
export class RatesService {
  constructor({ load = fetchEcbRates, ttlMs = SIX_HOURS_MS, now = () => Date.now() } = {}) {
    this.load = load;
    this.ttlMs = ttlMs;
    this.now = now;
    this.cache = null;
    this.inflight = null;
  }

  async getLatest() {
    if (this.cache && this.now() - this.cache.fetchedAtMs < this.ttlMs) {
      return this.#view(false);
    }

    // Une seule requête vers la BCE, même si plusieurs clients arrivent en même temps.
    this.inflight ??= this.load().finally(() => {
      this.inflight = null;
    });

    try {
      const { date, rates } = await this.inflight;
      this.cache = { date, rates, fetchedAtMs: this.now() };
      return this.#view(false);
    } catch (error) {
      if (this.cache) {
        return this.#view(true);
      }
      throw error;
    }
  }

  /**
   * Convertit un montant en passant par l'euro, comme l'app Flutter (FxRates).
   * @returns {number | null} null si l'une des devises est inconnue
   */
  convert(amount, from, to, rates) {
    const fromRate = from === 'EUR' ? 1 : rates[from];
    const toRate = to === 'EUR' ? 1 : rates[to];
    if (fromRate === undefined || toRate === undefined) {
      return null;
    }
    return (amount / fromRate) * toRate;
  }

  #view(stale) {
    return {
      base: 'EUR',
      date: this.cache.date,
      source: 'BCE',
      fetchedAt: new Date(this.cache.fetchedAtMs).toISOString(),
      stale,
      rates: { ...this.cache.rates },
    };
  }
}
