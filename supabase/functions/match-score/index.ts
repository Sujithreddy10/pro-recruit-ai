// supabase/functions/match-score/index.ts
//
// Scores candidate-to-job fit for the recruiter Talent Match screen.
// Holds GEMINI_API_KEY server-side; the client only sends job/candidate text.
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
    const { jobTitle, companyName, candidateName } = await req.json();

    if (!jobTitle || !companyName || !candidateName) {
      return new Response(
        JSON.stringify({
          error: "Missing jobTitle, companyName, or candidateName",
        }),
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

    const prompt = `You are scoring how well a candidate fits a job, based only on the information given.
Return ONLY valid JSON, no markdown fences, no extra text.

JOB TITLE: ${jobTitle}
COMPANY: ${companyName}
CANDIDATE: ${candidateName} (resume on file, not included in this prompt)

Since detailed resume text isn't available here, give a conservative estimate based
on role/title alignment only, and say so in the reasoning.

Return JSON exactly in this shape:
{"score": <integer 0-100>, "reasoning": "<one sentence>"}`;

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

    let parsed: { score: number; reasoning: string };
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

    await logUsage(req, "match-score");

    return new Response(
      JSON.stringify({
        score: Math.round(Number(parsed.score) || 0),
        reasoning: parsed.reasoning ?? "",
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
