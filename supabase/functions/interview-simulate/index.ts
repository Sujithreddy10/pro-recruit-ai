// supabase/functions/interview-simulate/index.ts
//
// Powers the candidate AI Interview Simulation feature. Two modes in one
// function:
//  - generate_questions: given a role, returns 6 interview questions in
//    one Gemini call.
//  - evaluate_session: given the full question/answer transcript, returns
//    one overall feedback report + score in a single Gemini call, and
//    persists the session to interview_simulations. Batching to 2 calls
//    total per session (instead of one call per answer) keeps this usable
//    on the free Gemini quota.
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

async function callGemini(apiKey: string, prompt: string) {
  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=${apiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] }),
    },
  );
  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`Gemini API error: ${errText}`);
  }
  const data = await res.json();
  return data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  try {
    const body = await req.json();
    const mode = body?.mode;
    const apiKey = Deno.env.get("GEMINI_API_KEY");
    if (!apiKey) {
      return new Response(
        JSON.stringify({ error: "Server misconfigured: missing GEMINI_API_KEY secret" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    if (mode === "generate_questions") {
      const roleTitle = body?.roleTitle;
      if (!roleTitle || typeof roleTitle !== "string") {
        return new Response(JSON.stringify({ error: "Missing 'roleTitle' field" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      const prompt = `You are an experienced interview panelist. Generate exactly 6 realistic interview questions for the role "${roleTitle}". Mix in 2 behavioral questions, 2 role-specific/technical questions, and 2 situational questions. Keep each question under 30 words.
Return ONLY valid JSON, no markdown fences, in this exact shape:
["question 1", "question 2", "question 3", "question 4", "question 5", "question 6"]`;
      const rawText = await callGemini(apiKey, prompt);
      const cleaned = cleanJson(rawText);
      let questions: unknown;
      try {
        questions = JSON.parse(cleaned);
      } catch {
        return new Response(
          JSON.stringify({ error: "Could not parse model response", raw: rawText }),
          { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }
      if (!Array.isArray(questions)) {
        return new Response(
          JSON.stringify({ error: "Model response was not a JSON array", raw: rawText }),
          { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }
      await logUsage(req, "interview-simulate");
      return new Response(JSON.stringify({ questions: questions.map((q) => String(q)) }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (mode === "evaluate_session") {
      const roleTitle = body?.roleTitle;
      const qaPairs = body?.qaPairs;
      if (!roleTitle || !Array.isArray(qaPairs) || qaPairs.length === 0) {
        return new Response(JSON.stringify({ error: "Missing 'roleTitle' or 'qaPairs'" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      const transcript = qaPairs
        .map((qa: Record<string, unknown>, i: number) => `Q${i + 1}: ${qa.question}\nA${i + 1}: ${qa.answer}`)
        .join("\n\n");
      const prompt = `You are an honest, constructive interview coach reviewing a mock interview transcript for the role "${roleTitle}".
${transcript}

Give an overall assessment. Return ONLY valid JSON, no markdown fences, in this exact shape:
{"score": <integer 0-100>, "strengths": ["...", "..."], "improvements": ["...", "..."], "summary": "2-3 sentence overall summary in a supportive but honest tone"}`;
      const rawText = await callGemini(apiKey, prompt);
      const cleaned = cleanJson(rawText);
      let evaluation: Record<string, unknown>;
      try {
        evaluation = JSON.parse(cleaned);
      } catch {
        return new Response(
          JSON.stringify({ error: "Could not parse model response", raw: rawText }),
          { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }

      const supabaseUrl = Deno.env.get("SUPABASE_URL");
      const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
      const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
      if (supabaseUrl && anonKey && serviceKey) {
        const authHeader = req.headers.get("Authorization") ?? "";
        const userClient = createClient(supabaseUrl, anonKey, {
          global: { headers: { Authorization: authHeader } },
        });
        const { data: { user } } = await userClient.auth.getUser();
        if (user) {
          const adminClient = createClient(supabaseUrl, serviceKey);
          await adminClient.from("interview_simulations").insert({
            user_id: user.id,
            role_title: roleTitle,
            questions: qaPairs.map((qa: Record<string, unknown>) => qa.question),
            answers: qaPairs.map((qa: Record<string, unknown>) => qa.answer),
            feedback: JSON.stringify(evaluation),
            score: Number(evaluation?.score) || null,
          });
        }
      }

      await logUsage(req, "interview-simulate");
      return new Response(JSON.stringify({ evaluation }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ error: "Invalid or missing 'mode'" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
