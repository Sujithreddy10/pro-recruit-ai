// supabase/functions/skill-gap/index.ts
//
// Generates skill-gap explanations for the candidate Skill-Gap Analytics
// screen. Holds GEMINI_API_KEY server-side so it never ships inside the app.
// Successful calls are logged to ai_usage_log for the Usage Credits screen.

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

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { jobTitle, missingSkills } = await req.json();

    if (!jobTitle || !Array.isArray(missingSkills) || missingSkills.length === 0) {
      return new Response(
        JSON.stringify({ error: "Missing jobTitle or missingSkills" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const apiKey = Deno.env.get("GEMINI_API_KEY");
    if (!apiKey) {
      return new Response(
        JSON.stringify({
          error: "Server misconfigured: missing GEMINI_API_KEY secret",
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const prompt = `For the job title "${jobTitle}", here are skills/keywords the candidate's resume does NOT currently show: ${missingSkills.join(", ")}.

For each one, write exactly one honest, concise sentence (max 20 words) explaining why it matters for this specific role. Do not exaggerate or invent unrelated claims.

Return ONLY valid JSON, no markdown fences, in this exact shape:
[{"skill": "...", "reason": "..."}]`;

    const geminiRes = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
        }),
      },
    );

    if (!geminiRes.ok) {
      const errText = await geminiRes.text();
      return new Response(
        JSON.stringify({ error: `Gemini API error: ${errText}` }),
        {
          status: geminiRes.status,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const data = await geminiRes.json();
    const rawText: string =
      data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
    const cleaned = rawText
      .replace(/^```json/, "")
      .replace(/```$/, "")
      .trim();

    let parsed: unknown;
    try {
      parsed = JSON.parse(cleaned);
    } catch {
      return new Response(
        JSON.stringify({ error: "Could not parse model response", raw: rawText }),
        {
          status: 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    if (!Array.isArray(parsed)) {
      return new Response(
        JSON.stringify({ error: "Model response was not a JSON array", raw: rawText }),
        {
          status: 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const gaps = parsed.map((e: Record<string, unknown>) => ({
      skill: String(e?.skill ?? ""),
      reason: String(e?.reason ?? ""),
    }));

    await logUsage(req, "skill-gap");

    return new Response(JSON.stringify({ gaps }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
