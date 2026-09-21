import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ONESIGNAL_APP_ID = "fc16b84a-85ff-4fce-b472-debcd8bb09e3";
const ONESIGNAL_REST_API_KEY = Deno.env.get("ONESIGNAL_REST_API_KEY");

serve(async (req) => {
  try {
    const payload = await req.json();
    const interview = payload.record;
    if (!interview) {
      console.log("No record in payload:", JSON.stringify(payload));
      return new Response(JSON.stringify({ error: "no record in payload" }), { status: 400 });
    }

    const recipientId = interview.candidate_id;
    const jobTitle = interview.job_title || "your role";
    const companyName = interview.company_name || "the company";
    const date = interview.scheduled_date || "";
    const time = interview.scheduled_time || "";
    const mode = interview.mode || "";

    if (!recipientId) {
      console.log("No candidate_id on interview record");
      return new Response(JSON.stringify({ ok: true, skipped: true }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const title = "Interview scheduled";
    const body = `${jobTitle} at ${companyName} - ${date} at ${time}${mode ? " (" + mode + ")" : ""}`;

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    await supabase.from("notifications").insert({
      user_id: recipientId,
      title,
      body,
      type: "interview_scheduled",
      reference_id: String(interview.id),
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
        headings: { en: title },
        contents: { en: body },
        data: { interview_id: interview.id },
      }),
    });

    const oneSignalResult = await oneSignalRes.json();
    console.log("OneSignal status:", oneSignalRes.status);
    console.log("OneSignal result:", JSON.stringify(oneSignalResult));

    return new Response(
      JSON.stringify({ ok: true, oneSignalStatus: oneSignalRes.status, oneSignalResult }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.log("Function error:", String(e));
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});
