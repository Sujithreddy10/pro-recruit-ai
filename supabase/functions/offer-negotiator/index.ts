// supabase/functions/offer-negotiator/index.ts
//
// Gives candidates an honest read on a job offer plus negotiation talking
// points and a draft email. One Gemini call per request.
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

async function logUsage(req: Request, feature: string) {
  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !anonKey || !serviceKey) return;
    const authHeader = req.headers.get("Authorization") ?? "";
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user } } = await userClient.auth.getUser();
    if (!user) return;
    const adminClient = createClient(supabaseUrl, serviceKey);
    await adminClient.from("ai_usage_log").insert({ user_id: user.id, feature });
  } catch (_e) {
    // Usage logging must never break the actual feature response.
  }
}

function cleanJson(rawText: string): string {
  return rawText.replace(/^```json/, "").replace(/^```/, "").replace(/```$/, "").trim();
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  try {
    const { companyName, roleTitle, offeredSalary, currentSalary, experienceYears } = await req.json();
    if (!companyName || !roleTitle || !offeredSalary) {
      return new Response(JSON.stringify({ error: "Missing companyName, roleTitle, or offeredSalary" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    const apiKey = Deno.env.get("GEMINI_API_KEY");
    if (!apiKey) {
      return new Response(
        JSON.stringify({ error: "Server misconfigured: missing GEMINI_API_KEY secret" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }
    const prompt = `A candidate received a job offer and wants honest negotiation help. Details:
Company: ${companyName}
Role: ${roleTitle}
Offered salary/CTC: ${offeredSalary}
${currentSalary ? `Current salary: ${currentSalary}` : ""}
${experienceYears ? `Years of experience: ${experienceYears}` : ""}

Give an honest, general assessment (note this is general guidance, not live market-data benchmarking), 3-4 concrete negotiation talking points, and a short, polite, professional draft email the candidate could send to negotiate.
Return ONLY valid JSON, no markdown fences, in this exact shape:
{"assessment": "...", "talkingPoints": ["...", "..."], "draftEmail": "..."}`;
    const geminiRes = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] }),
      },
    );
    if (!geminiRes.ok) {
      const errText = await geminiRes.text();
      return new Response(JSON.stringify({ error: `Gemini API error: ${errText}` }), {
        status: geminiRes.status,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    const data = await geminiRes.json();
    const rawText: string = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
    const cleaned = cleanJson(rawText);
    let result: unknown;
    try {
      result = JSON.parse(cleaned);
    } catch {
      return new Response(JSON.stringify({ error: "Could not parse model response", raw: rawText }), {
        status: 502,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    await logUsage(req, "offer-negotiator");
    return new Response(JSON.stringify({ result }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
