import Fastify from 'fastify';
import { RatesService } from './rates-service.js';

const CODE = { type: 'string', pattern: '^[A-Za-z]{3}$' };

/**
 * Construit l'application Fastify. Le service de taux est injectable :
 * les tests n'appellent jamais la vraie BCE.
 */
export function buildApp({ ratesService = new RatesService(), logger = false } = {}) {
  const app = Fastify({ logger });

  // Contrôle de santé : utilisé plus tard par Docker (HEALTHCHECK) et le déploiement.
  app.get('/health', async () => ({ status: 'ok' }));

  app.get('/fx/latest', async (_request, reply) => {
    try {
      return await ratesService.getLatest();
    } catch {
      return reply.code(502).send({ error: 'ecb_unavailable' });
    }
  });

  app.get(
    '/fx/convert',
    {
      schema: {
        querystring: {
          type: 'object',
          required: ['from', 'to', 'amount'],
          properties: {
            from: CODE,
            to: CODE,
            amount: { type: 'number', minimum: 0, maximum: 1e13 },
          },
        },
      },
    },
    async (request, reply) => {
      const from = request.query.from.toUpperCase();
      const to = request.query.to.toUpperCase();
      const { amount } = request.query;

      let latest;
      try {
        latest = await ratesService.getLatest();
      } catch {
        return reply.code(502).send({ error: 'ecb_unavailable' });
      }

      const result = ratesService.convert(amount, from, to, latest.rates);
      if (result === null) {
        // Comme l'app : pas de taux inventé, on signale l'impossibilité.
        return reply.code(422).send({ error: 'unsupported_currency', from, to });
      }
      return {
        from,
        to,
        amount,
        result: Math.round(result * 100) / 100,
        date: latest.date,
        source: latest.source,
        stale: latest.stale,
      };
    },
  );

  return app;
}
