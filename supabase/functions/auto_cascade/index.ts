// auto_cascade — pemicu HTTP untuk kaskade B2C -> B2B.
//
// Fungsi ini sengaja tipis. Seluruh logika kaskade ada di satu fungsi SQL,
// public.run_auto_cascade(), yang juga dipanggil pg_cron tiap 5 menit.
// Jadi pemicu cron dan pemicu manual menjalankan kode yang benar-benar sama —
// bukan dua salinan yang bisa menyimpang diam-diam menjelang demo.
//
// Cara memanggil dari Flutter (sesi pengguna sudah login, JWT ikut otomatis):
//
//   final res = await supabase.functions.invoke('auto_cascade', body: {
//     'force': true,                 // lewati jam cutoff (tombol demo)
//     'merchant_id': merchantId,     // batasi ke satu merchant
//   });
//
// Balasan: {"cascaded": 3, "waste_batches_created": 3, "total_kg": 25.4}

import { createClient } from "jsr:@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  // Body opsional: cron memanggil tanpa body sama sekali.
  let force = false;
  let merchantId: string | null = null;

  try {
    const raw = await req.text();
    if (raw.trim().length > 0) {
      const body = JSON.parse(raw);
      force = body.force === true;
      merchantId = typeof body.merchant_id === "string" ? body.merchant_id : null;
    }
  } catch (_e) {
    return json({ error: "body bukan JSON yang sah" }, 400);
  }

  // run_auto_cascade menulis lintas merchant, jadi harus dipanggil dengan
  // service role. Kuncinya diambil dari environment Edge Function
  // (disuntikkan Supabase), tidak pernah dari berkas yang ter-commit.
  const url = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceKey) {
    return json({ error: "environment Supabase tidak lengkap" }, 500);
  }

  const supabase = createClient(url, serviceKey);

  const { data, error } = await supabase.rpc("run_auto_cascade", {
    p_force: force,
    p_merchant_id: merchantId,
  });

  if (error) {
    console.error("[auto_cascade] gagal:", error.message);
    return json({ error: error.message }, 500);
  }

  console.log("[auto_cascade] hasil:", JSON.stringify(data));
  return json(data);
});
