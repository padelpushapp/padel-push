// supabase/functions/accept-slot/index.ts

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

// ============================================================
// ✅ Helper: respuesta JSON
// ============================================================

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

// ============================================================
// ✅ MAIN
// ============================================================

serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return jsonResponse({ error: "Method not allowed" }, 405);
    }

    let body: any = {};
    try {
      body = await req.json();
    } catch (_e) {
      return jsonResponse({ error: "Invalid JSON body" }, 400);
    }

    const match_id = body.match_id as string | undefined;
    const user_id = body.user_id as string | undefined;
    const waiting_id = body.waiting_id as string | undefined;

    // 🔍 Log para debug
    console.log("📩 accept-slot body:", body);

    // 🔐 Solo obligatorios match_id y user_id
    if (!match_id || !user_id) {
      return jsonResponse(
        { error: "Missing params", received: body },
        400,
      );
    }

    // ========================================================
    // 1️⃣ Buscar fila en waiting_list
    // ========================================================

    let waitingRow: any = null;

    if (waiting_id) {
      const { data, error } = await supabase
        .from("waiting_list")
        .select("*")
        .eq("id", waiting_id)
        .maybeSingle();

      if (error) {
        console.error("❌ waiting_list by id error:", error);
        return jsonResponse({ error: "DB error waiting_list id" }, 500);
      }

      waitingRow = data;
    } else {
      // fallback por match + user
      const { data, error } = await supabase
        .from("waiting_list")
        .select("*")
        .eq("match_id", match_id)
        .eq("user_id", user_id)
        .in("status", ["waiting", "notified"])
        .order("created_at", { ascending: true })
        .limit(1)
        .maybeSingle();

      if (error) {
        console.error("❌ waiting_list by match+user error:", error);
        return jsonResponse({ error: "DB error waiting_list" }, 500);
      }

      waitingRow = data;
    }

    if (!waitingRow) {
      return jsonResponse(
        { error: "Waiting row not found", received: body },
        404,
      );
    }

    // ========================================================
    // 2️⃣ Verificar que aún hay hueco
    // ========================================================

    const { data: match, error: matchError } = await supabase
      .from("matches")
      .select("id, needed_players")
      .eq("id", match_id)
      .maybeSingle();

    if (matchError) {
      console.error("❌ error leyendo match:", matchError);
      return jsonResponse({ error: "DB error match" }, 500);
    }

    if (!match) {
      return jsonResponse({ error: "Match not found" }, 404);
    }

    if (!match.needed_players || match.needed_players <= 0) {
      // Otro usuario ha ocupado ya el hueco
      return jsonResponse(
        { error: "No slots available", needed_players: match.needed_players },
        409,
      );
    }

    // ========================================================
    // 3️⃣ Decrementar needed_players
    // ========================================================

    const newNeeded = Math.max(0, (match.needed_players as number) - 1);

    const { error: updateNeededError } = await supabase
      .from("matches")
      .update({ needed_players: newNeeded })
      .eq("id", match_id);

    if (updateNeededError) {
      console.error("❌ error actualizando needed_players:", updateNeededError);
      return jsonResponse({ error: "Update needed_players failed" }, 500);
    }

    // ========================================================
    // 4️⃣ Crear / asegurar match_requests = approved
    // ========================================================

    const { data: existingReq, error: existingErr } = await supabase
      .from("match_requests")
      .select("id, status")
      .eq("match_id", match_id)
      .eq("requester_id", user_id)
      .maybeSingle();

    if (existingErr) {
      console.error("❌ error leyendo match_requests:", existingErr);
      return jsonResponse({ error: "DB error match_requests" }, 500);
    }

    if (!existingReq) {
      const { error: insertReqErr } = await supabase
        .from("match_requests")
        .insert({
          match_id,
          requester_id: user_id,
          status: "approved",
        });

      if (insertReqErr) {
        console.error("❌ error insert match_requests:", insertReqErr);
        return jsonResponse({ error: "Insert match_request failed" }, 500);
      }
    } else if (existingReq.status !== "approved") {
      const { error: updateReqErr } = await supabase
        .from("match_requests")
        .update({ status: "approved" })
        .eq("id", existingReq.id);

      if (updateReqErr) {
        console.error("❌ error update match_requests:", updateReqErr);
        return jsonResponse({ error: "Update match_request failed" }, 500);
      }
    }

    // ========================================================
    // 5️⃣ Marcar waiting_list como accepted
    // ========================================================

    const { error: updateWaitingErr } = await supabase
      .from("waiting_list")
      .update({ status: "accepted" })
      .eq("id", waitingRow.id);

    if (updateWaitingErr) {
      console.error("❌ error update waiting_list:", updateWaitingErr);
      // no rompemos del todo, pero lo dejamos logueado
    }

    // ========================================================
    // ✅ OK
    // ========================================================

    return jsonResponse({
      ok: true,
      match_id,
      user_id,
      waiting_id: waitingRow.id,
      new_needed_players: newNeeded,
    });
  } catch (err) {
    console.error("❌ accept-slot error:", err);
    return jsonResponse({ error: String(err) }, 500);
  }
});
