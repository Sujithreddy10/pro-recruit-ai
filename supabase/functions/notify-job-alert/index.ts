import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ONESIGNAL_APP_ID = "fc16b84a-85ff-4fce-b472-debcd8bb09e3";
const ONESIGNAL_REST_API_KEY = Deno.env.get("ONESIGNAL_REST_API_KEY");

serve(async (req) => {
  try {
    const payload = await req.json();
    const job = payload.record;
    if (!job) {
      console.log("No record in payload:", JSON.stringify(payload));
      return new Response(JSON.stringify({ error: "no record in payload" }), { status: 400 });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: prefs, error } = await supabase
      .from("job_alert_preferences")
      .select("user_id, locations, work_modes");

    if (error) {
      console.log("Prefs lookup failed:", error);
      return new Response(JSON.stringify({ error: "prefs lookup failed" }), { status: 500 });
    }

    const jobLocation = job.location || "";
    const jobMode = job.mode || "";

    const matched = (prefs || [])
      .filter((p: any) => {
        const locs: string[] = p.locations || [];
        const modes: string[] = p.work_modes || [];
        const locationOk = locs.length === 0 || locs.includes(jobLocation);
        const modeOk = modes.length === 0 || modes.includes(jobMode);
        return locationOk && modeOk;
      })
      .map((p: any) => p.user_id);

    if (matched.length === 0) {
      console.log("No matching alert preferences for this job");
      return new Response(JSON.stringify({ ok: true, matched: 0 }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const notifTitle = "New job matching your alert";
    const notifBody = `${job.title} at ${job.company}${jobLocation ? " - " + jobLocation : ""}`;

    await supabase.from("notifications").insert(
      matched.map((uid: string) => ({
        user_id: uid,
        title: notifTitle,
        body: notifBody,
        type: "job_alert",
        reference_id: String(job.id),
      })),
    );

    const oneSignalRes = await fetch("https://api.onesignal.com/notifications", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Key ${ONESIGNAL_REST_API_KEY}`,
      },
      body: JSON.stringify({
        app_id: ONESIGNAL_APP_ID,
        include_aliases: { external_id: matched },
        target_channel: "push",
        headings: { en: notifTitle },
        contents: { en: notifBody },
        data: { job_id: job.id },
      }),
    });

    const oneSignalResult = await oneSignalRes.json();
    console.log("OneSignal status:", oneSignalRes.status);
    console.log("OneSignal result:", JSON.stringify(oneSignalResult));

    return new Response(
      JSON.stringify({
        ok: true,
        matched: matched.length,
        oneSignalStatus: oneSignalRes.status,
        oneSignalResult,
      }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.log("Function error:", String(e));
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});
