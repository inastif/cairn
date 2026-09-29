// Récupère les taux de référence quotidiens de la BCE (base EUR) et les
// enregistre dans public.fx_rates. Appelée par l'app quand ses taux datent
// de plus de 4 jours ; ne refait pas l'appel si un import a eu lieu dans
// les 6 dernières heures.
//
// Déploiement : npx supabase functions deploy fx-ecb
// La vérification JWT reste active : seuls les utilisateurs connectés
// peuvent déclencher l'import.
import { createClient } from "jsr:@supabase/supabase-js@2";

const ECB_DAILY_URL = "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml";
const MIN_INTERVAL_MS = 6 * 60 * 60 * 1000;

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: latest } = await supabase
    .from("fx_rates")
    .select("fetched_at")
    .order("fetched_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (latest && Date.now() - new Date(latest.fetched_at).getTime() < MIN_INTERVAL_MS) {
    return json({ status: "fresh" });
  }

  const response = await fetch(ECB_DAILY_URL);
  if (!response.ok) {
    return json({ error: "ecb_unavailable", status: response.status }, 502);
  }
  const xml = await response.text();

  const date = xml.match(/time=['"](\d{4}-\d{2}-\d{2})['"]/)?.[1];
  const fetchedAt = new Date().toISOString();
  const rows = [...xml.matchAll(/currency=['"]([A-Z]{3})['"]\s+rate=['"]([0-9.]+)['"]/g)]
    .map((m) => ({
      base: "EUR",
      quote: m[1],
      rate: Number(m[2]),
      rate_date: date,
      source: "BCE",
      fetched_at: fetchedAt,
    }))
    .filter((row) => Number.isFinite(row.rate) && row.rate > 0);

  if (!date || rows.length === 0) {
    return json({ error: "ecb_parse_failed" }, 502);
  }

  const { error } = await supabase.from("fx_rates").upsert(rows, { onConflict: "base,quote,rate_date" });
  if (error) {
    return json({ error: "database_error" }, 500);
  }
  return json({ status: "updated", date, count: rows.length });
});
