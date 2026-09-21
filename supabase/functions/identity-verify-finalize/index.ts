// supabase/functions/identity-verify-finalize/index.ts
//
// Two jobs in one function:
//  - GET: DigiLocker redirects the user's browser here after consent. We
//    don't parse any query params -- the app independently polls status
//    via POST once the user manually returns. This just shows a friendly
//    page telling them to go back to the app.
//  - POST: called by the Flutter app once the user is back. Re-checks the
//    session status directly with Sandbox (never trusts the client alone),
//    then fetches the actual Aadhaar document to confirm consent was
//    really granted, before marking the verification 'verified' in the
//    database (service role write only, candidates cannot self-certify).
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const SANDBOX_BASE = "https://api.sandbox.co.in";

async function getSandboxAccessToken(apiKey: string, apiSecret: string) {
  const res = await fetch(`${SANDBOX_BASE}/authenticate`, {
    method: "POST",
    headers: {
      "x-api-key": apiKey,
      "x-api-secret": apiSecret,
      "x-api-version": "1.0.0",
      "Content-Type": "application/json",
    },
  });
  const json = await res.json();
  if (!res.ok || !json?.data?.access_token) {
    throw new Error(json?.message ?? "Sandbox authentication failed");
  }
  return json.data.access_token as string;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method === "GET") {
    return new Response(
      `<!DOCTYPE html><html><body style="font-family: -apple-system, sans-serif; text-align: center; padding: 60px 20px;">
        <h2>Verification submitted</h2>
        <p>You can close this window and return to the Hylo app to see your status.</p>
      </body></html>`,
      { headers: { "Content-Type": "text/html" } },
    );
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const sandboxApiKey = Deno.env.get("SANDBOX_API_KEY");
    const sandboxApiSecret = Deno.env.get("SANDBOX_API_SECRET");
    if (!supabaseUrl || !anonKey || !serviceKey || !sandboxApiKey || !sandboxApiSecret) {
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
    const sessionId = body?.session_id;
    if (!sessionId || typeof sessionId !== "string") {
      return new Response(JSON.stringify({ error: "Missing 'session_id' field" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const adminClient = createClient(supabaseUrl, serviceKey);

    const { data: pendingRow } = await adminClient
      .from("identity_verifications")
      .select("id, user_id")
      .eq("provider_session_id", sessionId)
      .eq("user_id", user.id)
      .maybeSingle();
    if (!pendingRow) {
      return new Response(JSON.stringify({ error: "Session not found for this user" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const accessToken = await getSandboxAccessToken(sandboxApiKey, sandboxApiSecret);

    const statusRes = await fetch(
      `${SANDBOX_BASE}/kyc/digilocker/sessions/${sessionId}/status`,
      {
        headers: {
          Authorization: accessToken,
          "x-api-key": sandboxApiKey,
          "x-api-version": "1.0.0",
        },
      },
    );
    const statusJson = await statusRes.json();
    const status = statusJson?.data?.status;

    if (status !== "succeeded") {
      await adminClient
        .from("identity_verifications")
        .update({ status: status === "failed" || status === "expired" ? "failed" : "pending" })
        .eq("id", pendingRow.id);
      return new Response(JSON.stringify({ verified: false, status: status ?? "unknown" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const docRes = await fetch(
      `${SANDBOX_BASE}/kyc/digilocker/sessions/${sessionId}/documents/aadhaar`,
      {
        headers: {
          Authorization: accessToken,
          "x-api-key": sandboxApiKey,
          "x-api-version": "1.0.0",
        },
      },
    );
    const docJson = await docRes.json();
    const file = docJson?.data?.files?.[0];
    if (!docRes.ok || !file) {
      return new Response(
        JSON.stringify({ verified: false, error: docJson?.message ?? "Document not available yet" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    await adminClient
      .from("identity_verifications")
      .update({
        status: "verified",
        verified_at: new Date().toISOString(),
        provider_reference_id: sessionId,
        masked_id: file?.metadata?.description ?? "Aadhaar Card",
      })
      .eq("id", pendingRow.id);

    return new Response(JSON.stringify({ verified: true }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
