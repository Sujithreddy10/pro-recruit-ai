// supabase/functions/identity-verify-init/index.ts
//
// Starts real Aadhaar identity verification via Sandbox's raw DigiLocker
// API (not the closed-source mobile SDK, which appears to only work with
// production credentials). This flow explicitly targets Sandbox's test
// host end-to-end, so it's safe to test without live credentials. Returns
// an authorization_url that the app opens in an external browser; the
// user completes DigiLocker's own OTP + consent flow there, then returns
// to the app, which polls identity-verify-finalize to confirm the result.
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

    const adminClient = createClient(supabaseUrl, serviceKey);

    const accessToken = await getSandboxAccessToken(sandboxApiKey, sandboxApiSecret);

    const redirectUrl = `${supabaseUrl}/functions/v1/identity-verify-finalize`;
    const sessionRes = await fetch(`${SANDBOX_BASE}/kyc/digilocker/sessions/init`, {
      method: "POST",
      headers: {
        Authorization: accessToken,
        "x-api-key": sandboxApiKey,
        "x-api-version": "1.0.0",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        "@entity": "in.co.sandbox.kyc.digilocker.session.request",
        flow: "signin",
        redirect_url: redirectUrl,
        doc_types: ["aadhaar"],
        options: {
          verification_method: ["aadhaar"],
          pinless: true,
          usernameless: true,
          verified_mobile: "9687205427",
        },
      }),
    });
    const sessionJson = await sessionRes.json();
    const sessionId = sessionJson?.data?.session_id;
    const authorizationUrl = sessionJson?.data?.authorization_url;
    if (!sessionRes.ok || !sessionId || !authorizationUrl) {
      return new Response(
        JSON.stringify({ error: sessionJson?.message ?? "Failed to create DigiLocker session" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const { error: insertError } = await adminClient.from("identity_verifications").insert({
      user_id: user.id,
      verification_type: "aadhaar_digilocker",
      status: "pending",
      provider_session_id: sessionId,
    });
    if (insertError) {
      return new Response(JSON.stringify({ error: insertError.message }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ session_id: sessionId, authorization_url: authorizationUrl }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
