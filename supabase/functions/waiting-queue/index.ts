import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

// ============================================================
// 🔐 ENV
// ============================================================

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY")!;
const RESERVATION_MINUTES = Number(Deno.env.get("RESERVATION_MINUTES") ?? "1");

const supabase = createClient(
  SUPABASE_URL,
  SUPABASE_SERVICE_ROLE_KEY,
  { global: { headers: { "x-from": "waiting-queue" } } },
);

// ============================================================
// 🔔 SEND FCM — DATA ONLY (CLAVE ABSOLUTA)
// ============================================================

async function sendFcm(
  toToken: string,
  payloadData: Record<string, string>,
) {
  const payload = {
    to: toToken,
    priority: "high",
    data: payloadData,
  };

  await fetch("https://fcm.googleapis.com/fcm/send", {
    method: "POST",
    headers: {
      Authorization: `key=${FCM_SERVER_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });
}

// ============================================================
// 🚀 MAIN FUNCTION
// ============================================================

serve(async () => {
  try {
    // 1️⃣ Buscar partidos con huecos
    const { data: matches, error } = await supabase
      .from("matches")
      .select("id, needed_players")
      .gt("needed_players", 0);

    if (error) throw error;

    for (const match of matches ?? []) {
      // 2️⃣ Siguiente usuario en waiting list
      const { data: candidate } = await supabase
        .from("waiting_list")
        .select("*")
        .eq("match_id", match.id)
        .in("status", ["waiting", "notified"])
        .order("created_at", { ascending: true })
        .limit(1)
        .maybeSingle();

      if (!candidate) continue;

      const now = new Date();

      // ⏳ Aún tiene reserva activa
      if (
        candidate.status === "notified" &&
        candidate.expires_at &&
        new Date(candidate.expires_at) > now
      ) {
        continue;
      }

      // ⌛ Reserva expirada
      if (
        candidate.status === "notified" &&
        candidate.expires_at &&
        new Date(candidate.expires_at) <= now
      ) {
        await supabase
          .from("waiting_list")
          .update({ status: "expired" })
          .eq("id", candidate.id);
        continue;
      }

      // 3️⃣ Usuario
      const { data: user } = await supabase
        .from("users")
        .select("id, full_name, push_token")
        .eq("id", candidate.user_id)
        .maybeSingle();

      if (!user?.push_token) {
        await supabase
          .from("waiting_list")
          .update({ status: "expired" })
          .eq("id", candidate.id);
        continue;
      }

      // 4️⃣ Datos del partido
      const { data: matchData } = await supabase
        .from("matches")
        .select("club, location, time, level_start")
        .eq("id", match.id)
        .maybeSingle();

      const title = `¡${user.full_name?.toUpperCase() ?? "JUGADOR"} TIENES UN HUECO DISPONIBLE!`;
      const body =
        `Se ha liberado una plaza en ` +
        `${matchData?.club ?? matchData?.location ?? "un partido"} ` +
        `a las ${matchData?.time} · Nivel ${matchData?.level_start}`;

      // 5️⃣ ENVIAR PUSH (DATA ONLY)
      await sendFcm(user.push_token, {
        action: "waiting_slot",
        title,
        body,
        match_id: match.id,
        waiting_id: candidate.id,
      });

      // 6️⃣ Marcar como notificado + expiración
      const expiresAt = new Date(
        now.getTime() + RESERVATION_MINUTES * 60 * 1000,
      );

      await supabase
        .from("waiting_list")
        .update({
          status: "notified",
          notified_at: now.toISOString(),
          expires_at: expiresAt.toISOString(),
        })
        .eq("id", candidate.id);
    }

    return new Response(JSON.stringify({ ok: true }), { status: 200 });
  } catch (err) {
    console.error("❌ waiting-queue error:", err);
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 });
  }
});
