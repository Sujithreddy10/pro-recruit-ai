import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ONESIGNAL_APP_ID = "fc16b84a-85ff-4fce-b472-debcd8bb09e3";
const ONESIGNAL_REST_API_KEY = Deno.env.get("ONESIGNAL_REST_API_KEY");

function messageForStatus(
  status: string,
  jobTitle: string,
  companyName: string,
): { title: string; body: string } | null {
  switch (status) {
    case "shortlisted":
      return {
        title: "You've been shortlisted!",
        body: `Your application for ${jobTitle} at ${companyName} was shortlisted.`,
      };
    case "offer_sent":
      return {
        title: "You have an offer!",
        body: `You received an offer for ${jobTitle} at ${companyName}.`,
      };
    case "hired":
      return {
        title: "Congratulations!",
        body: `You've been hired for ${jobTitle} at ${companyName}!`,
      };
    case "rejected":
      return {
        title: "Application update",
        body: `Your application for ${jobTitle} at ${companyName} was not selected this time.`,
      };
    default:
      return null;
  }
}

serve(async (req) => {
  try {
    const payload = await req.json();
    const application = payload.record;
    if (!application) {
      console.log("No record in payload:", JSON.stringify(payload));
      return new Response(JSON.stringify({ error: "no record in payload" }), { status: 400 });
    }

    const recipientId = application.user_id;
    const status = application.status;
    const jobTitle = application.job_title || "a role";
    const companyName = application.company_name || "the company";

    const msg = messageForStatus(status, jobTitle, companyName);
    if (!msg || !recipientId) {
      console.log("No notification needed for status:", status);
      return new Response(JSON.stringify({ ok: true, skipped: true }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    await supabase.from("notifications").insert({
      user_id: recipientId,
      title: msg.title,
      body: msg.body,
      type: "application_status",
      reference_id: String(application.id),
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
        headings: { en: msg.title },
        contents: { en: msg.body },
        data: { application_id: application.id, status },
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
