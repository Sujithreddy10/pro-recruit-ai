// supabase/functions/portfolio-architect/index.ts
//
// Builds a portfolio outline and polished per-project pitches from the
// candidate's real skills/projects/certificates. One Gemini call per
// request.
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
    const { skills, projects, certificates, targetRole } = await req.json();
    if (!Array.isArray(skills) || !Array.isArray(projects) || !Array.isArray(certificates)) {
      return new Response(JSON.stringify({ error: "Missing skills, projects, or certificates arrays" }), {
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
    const prompt = `Help a candidate build a professional portfolio${targetRole ? ` targeting the role "${targetRole}"` : ""}.
Their real skills: ${JSON.stringify(skills)}
Their real projects: ${JSON.stringify(projects)}
Their real certificates: ${JSON.stringify(certificates)}

Suggest a portfolio section structure (list of section names in order), and for each project provided, write one polished 2-3 sentence pitch highlighting impact and skills used. If there are no projects, return an empty projectPitches array. Write a 2-3 sentence overall summary of how to present this candidate's portfolio.
Return ONLY valid JSON, no markdown fences, in this exact shape:
{"structure": ["...", "..."], "projectPitches": [{"title": "...", "pitch": "..."}], "summary": "..."}`;
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
    await logUsage(req, "portfolio-architect");
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
