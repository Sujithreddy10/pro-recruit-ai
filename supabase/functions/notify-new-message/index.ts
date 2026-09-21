import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ONESIGNAL_APP_ID = "fc16b84a-85ff-4fce-b472-debcd8bb09e3";
const ONESIGNAL_REST_API_KEY = Deno.env.get("ONESIGNAL_REST_API_KEY");

serve(async (req) => {
  try {
    const payload = await req.json();
    const message = payload.record;
    if (!message) {
      console.log("No record in payload:", JSON.stringify(payload));
      return new Response(JSON.stringify({ error: "no record in payload" }), { status: 400 });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: conversation, error: convErr } = await supabase
      .from("conversations")
      .select("candidate_id, recruiter_id, job_title, company_name")
      .eq("id", message.conversation_id)
      .single();

    if (convErr || !conversation) {
      console.log("Conversation lookup failed:", convErr);
      return new Response(JSON.stringify({ error: "conversation not found" }), { status: 404 });
    }

    const recipientId =
      message.sender_id === conversation.candidate_id
        ? conversation.recruiter_id
        : conversation.candidate_id;

    const { data: sender } = await supabase
      .from("profiles")
      .select("full_name")
      .eq("id", message.sender_id)
      .maybeSingle();

    const senderName = sender?.full_name || "Someone";
    const preview = (message.body || "").toString().slice(0, 120);

    await supabase.from("notifications").insert({
      user_id: recipientId,
      title: senderName,
      body: preview,
      type: "message",
      reference_id: message.conversation_id,
    });

    const oneSignalRes = await fetch("https://api.onesignal.com/notifications", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Key ${ONESIGNAL_REST_API_KEY}`,
      },
      body: JSON.stringify({
        app_id: ONESIGNAL_APP_ID,
        include_aliases: { external_id: [recipientId] },
        target_channel: "push",
        headings: { en: senderName },
        contents: { en: preview },
        data: { conversation_id: message.conversation_id },
      }),
    });

    const oneSignalResult = await oneSignalRes.json();
    console.log("OneSignal status:", oneSignalRes.status);
    console.log("OneSignal result:", JSON.stringify(oneSignalResult));

    return new Response(JSON.stringify({ ok: true, oneSignalStatus: oneSignalRes.status, oneSignalResult }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    console.log("Function error:", String(e));
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});
