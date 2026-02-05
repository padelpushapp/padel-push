import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

console.log("⚡ FUNCTION STARTED");

// ---------------------------------------------
//  Load secrets
// ---------------------------------------------
const serviceAccount = JSON.parse(Deno.env.get("GOOGLE_SERVICE_ACCOUNT")!);
const SUPABASE_URL = Deno.env.get("PROJECT_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SERVICE_ROLE_KEY")!;
const projectId = serviceAccount.project_id;

console.log("🔐 Secrets loaded OK");

// ---------------------------------------------
//  Generate Access Token
// ---------------------------------------------
async function getAccessToken() {
  console.log("🔑 Generating access token...");

  const privateKey = serviceAccount.private_key.replace(/\\n/g, "\n");
  const header = { alg: "RS256", typ: "JWT" };
  const now = Math.floor(Date.now() / 1000);

  const claimSet = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const base64url = (str: string) =>
    btoa(str).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

  const unsigned =
    `${base64url(JSON.stringify(header))}.` +
    `${base64url(JSON.stringify(claimSet))}`;

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    new TextEncoder().encode(privateKey),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(unsigned)
  );

  const signed =
    `${unsigned}.${base64url(
      String.fromCharCode(...new Uint8Array(signature))
    )}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: signed,
    }),
  });

  const data = await res.json();
  console.log("🔓 Access token OK");
  return data.access_token;
}

// ---------------------------------------------
//  Send Notification FCM v1
// ---------------------------------------------
async function sendFCM(token: string, title: string, body: string, data?: any) {
  const accessToken = await getAccessToken();

  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

  const message = {
    message: {
      token,
      notification: { title, body },
      data,
    },
  };

  console.log("📩 Sending push to:", token);

  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(message),
  });

  const txt = await res.text();
  console.log("🔥 FCM raw response:", txt);
  return txt;
}

// ---------------------------------------------
// MAIN
// ---------------------------------------------
serve(async () => {
  console.log("📌 Connecting to Supabase...");

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

  // 1) Queue
  const { data: queue } = await supabase
    .from("notifications_queue")
    .select("id, match_id")
    .order("created_at", { ascending: true })
    .limit(1);

  console.log("🟦 Queue result:", queue);

  if (!queue || queue.length === 0) {
    return new Response("Queue empty", { status: 200 });
  }

  const item = queue[0];

  console.log("📌 Processing queue item:", item);

  // 2) Match
  const { data: match } = await supabase
    .from("matches")
    .select("id, date, time")
    .eq("id", item.match_id)
    .single();

  console.log("🎾 Match result:", match);

  // 3) Minutes before match
  const matchDate = new Date(`${match.date}T${match.time}`);
  const diff = (matchDate.getTime() - Date.now()) / 60000;

  console.log("⏳ Minutes before match:", diff);

  if (diff < 30) {
    await supabase.from("notifications_queue").delete().eq("id", item.id);
    return new Response("Match <30min → ignored", { status: 200 });
  }

  // 4) Get first waiting list user
  const { data: wlist } = await supabase
    .from("waiting_list")
    .select("id, user_id")
    .eq("match_id", match.id)
    .order("created_at", { ascending: true })
    .limit(1);

  console.log("🟩 Waiting list result:", wlist);

  if (!wlist || wlist.length === 0)
    return new Response("Waiting list empty", { status: 200 });

  const w = wlist[0];

  console.log("👤 First user in waiting list:", w);

  // 5) Get user info
  const { data: user } = await supabase
    .from("users")
    .select("id, push_token, notifications_paused_until")
    .eq("id", w.user_id)
    .single();

  console.log("🟦 User result:", user);

  if (!user || !user.push_token)
    return new Response("User missing push token", { status: 200 });

  // 6) Send push
  await sendFCM(
    user.push_token,
    "¡Hay una plaza libre!",
    "Rápido, entra antes que otro jugador 🎾",
    { match_id: match.id }
  );

  // 7) Remove queue item
  console.log("🧹 Removing queue item:", item.id);
  await supabase.from("notifications_queue").delete().eq("id", item.id);

  return new Response(
    JSON.stringify({ msg: "Notification sent", user_notified: user.id }),
    { status: 200 }
  );
});
