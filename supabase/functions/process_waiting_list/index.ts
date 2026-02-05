import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async () => {
  console.log("⚡️ FUNCTION STARTED");

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  console.log("📌 Connected to Supabase");

  // 1) Leer cola
  const { data: queue, error: qErr } = await supabase
    .from("notifications_queue")
    .select("id, match_id")
    .order("created_at", { ascending: true })
    .limit(1);

  console.log("🟦 Queue result:", queue);

  if (qErr) {
    console.log("❌ Queue error:", qErr);
    return new Response(JSON.stringify(qErr), { status: 400 });
  }

  if (!queue || queue.length === 0) {
    console.log("⚠️ Queue empty → exit");
    return new Response(JSON.stringify({ msg: "Queue empty" }), { status: 200 });
  }

  const item = queue[0];
  console.log("📌 Processing queue item:", item);

  // 2) Leer partido
  const { data: match } = await supabase
    .from("matches")
    .select("id, date, time")
    .eq("id", item.match_id)
    .single();

  console.log("🎾 Match result:", match);

  if (!match) {
    console.log("❌ Match not found");
    return new Response(JSON.stringify({ msg: "Match not found" }), { status: 404 });
  }

  const dateTime = new Date(`${match.date}T${match.time}`);
  const diff = (dateTime.getTime() - Date.now()) / 60000;

  console.log("⏳ Minutes before match:", diff);

  if (diff < 30) {
    console.log("⚠️ Match <30min → removed from queue");
    await supabase.from("notifications_queue").delete().eq("id", item.id);
    return new Response(JSON.stringify({ msg: "Match begins <30min → removed" }), { status: 200 });
  }

  // 3) Leer waiting_list
  const { data: waiting } = await supabase
    .from("waiting_list")
    .select("id, user_id")
    .eq("match_id", match.id)
    .order("created_at", { ascending: true })
    .limit(1);

  console.log("🟩 Waiting list result:", waiting);

  if (!waiting || waiting.length === 0) {
    console.log("⚠️ Waiting list empty");
    return new Response(JSON.stringify({ msg: "Waiting list empty" }), { status: 200 });
  }

  const target = waiting[0];
  console.log("👤 First user in waiting list:", target);

  // 4) Leer usuario
  const { data: user } = await supabase
    .from("users")
    .select("id, push_token, notifications_paused_until")
    .eq("id", target.user_id)
    .single();

  console.log("🟦 User result:", user);

  if (!user) {
    console.log("❌ User not found");
    return new Response(JSON.stringify({ msg: "User not found" }), { status: 404 });
  }

  // Pausa "Hoy no"
  if (user.notifications_paused_until) {
    const paused = new Date(user.notifications_paused_until);
    console.log("⏸ notifications_paused_until:", paused);

    if (new Date() < paused) {
      console.log("🚫 User paused notifications");
      return new Response(JSON.stringify({ msg: "User paused notifications" }), { status: 200 });
    }
  }

  // 5) Enviar push notification
  if (user.push_token) {
    console.log("📩 Sending push to:", user.push_token);

    const res = await fetch("https://fcm.googleapis.com/fcm/send", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `key=${Deno.env.get("FCM_SERVER_KEY")}`,
      },
      body: JSON.stringify({
        to: user.push_token,
        notification: {
          title: "¡Plaza libre en un partido!",
          body: "Corre, puedes entrar al partido que esperabas 🎾",
        },
        data: { match_id: match.id, type: "waiting_list_open" },
      }),
    });

    console.log("🔥 FCM raw response:", await res.text());
  } else {
    console.log("⚠️ No push_token → skipping FCM");
  }

  // 6) Eliminar item de cola
  console.log("🧹 Removing queue item:", item.id);
  await supabase.from("notifications_queue").delete().eq("id", item.id);

  console.log("✅ PROCESS COMPLETE");
  return new Response(JSON.stringify({ msg: "Notification sent", user_notified: user.id }), { status: 200 });
});
