// supabase/functions/parse-resume/index.ts
//
// Extracts real text out of an uploaded resume PDF and writes it to
// profiles.resume_text. Nothing else in the app ever populated this
// column, which meant Resume Score and Skill Gap silently failed for
// every real user. Called right after every resume upload (single-resume
// flow in candidate_root.dart, Resume Vault, and Onboarding Pro).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { extractText, getDocumentProxy } from "https://esm.sh/unpdf@0.11.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !anonKey || !serviceKey) {
      return new Response(JSON.stringify({ error: "Server misconfigured" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const authHeader = req.headers.get("Authorization") ?? "";
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user } } = await userClient.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: "Not authenticated" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = await req.json();
    const storagePath = body?.storagePath;
    if (!storagePath || typeof storagePath !== "string") {
      return new Response(JSON.stringify({ error: "Missing 'storagePath' field" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Only allow extracting text from a file inside the caller's own
    // storage folder (resumes are stored at `${userId}/...`).
    if (!storagePath.startsWith(`${user.id}/`)) {
      return new Response(JSON.stringify({ error: "Forbidden" }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const adminClient = createClient(supabaseUrl, serviceKey);

    const { data: fileBlob, error: downloadError } = await adminClient.storage
      .from("resumes")
      .download(storagePath);

    if (downloadError || !fileBlob) {
      return new Response(
        JSON.stringify({ error: `Couldn't download resume: ${downloadError?.message}` }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const arrayBuffer = await fileBlob.arrayBuffer();
    const pdf = await getDocumentProxy(new Uint8Array(arrayBuffer));
    const { text } = await extractText(pdf, { mergePages: true });

    if (!text || text.trim().length < 20) {
      return new Response(
        JSON.stringify({ error: "Could not extract readable text from this PDF" }),
        { status: 422, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    await adminClient
      .from("profiles")
      .update({ resume_text: text })
      .eq("id", user.id);

    return new Response(JSON.stringify({ success: true, textLength: text.length }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
