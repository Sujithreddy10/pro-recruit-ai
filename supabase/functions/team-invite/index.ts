// supabase/functions/team-invite/index.ts
//
// Admin-only team management actions: invite a new recruiter by email,
// or remove an existing recruiter. Uses the service role key server-side
// since these are privileged Supabase Auth Admin operations that must
// never run with a client-exposed key. Only recruiters with
// is_team_admin = true may perform these actions.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
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

    // Verify the caller is authenticated and is an admin recruiter before
    // allowing any team-management action.
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

    const { data: callerProfile } = await adminClient
      .from("profiles")
      .select("user_role, is_team_admin")
      .eq("id", user.id)
      .maybeSingle();

    if (callerProfile?.user_role !== "recruiter" || callerProfile?.is_team_admin !== true) {
      return new Response(
        JSON.stringify({ error: "Only team admins can manage the team" }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const body = await req.json();
    const action = body?.action;

    if (action === "invite") {
      const email = body.email;
      if (!email || typeof email !== "string") {
        return new Response(JSON.stringify({ error: "Missing 'email' field" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const { data: inviteData, error: inviteError } =
        await adminClient.auth.admin.inviteUserByEmail(email, {
          data: { user_role: "recruiter" },
        });

      if (inviteError) {
        return new Response(JSON.stringify({ error: inviteError.message }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const invitedId = inviteData.user?.id;
      if (invitedId) {
        // New invitees are recruiters but NOT admins by default -
        // an existing admin has to promote them explicitly.
        await adminClient.from("profiles").upsert({
          id: invitedId,
          user_role: "recruiter",
          is_team_admin: false,
        });
      }

      return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (action === "remove") {
      const targetUserId = body.userId;
      if (!targetUserId || typeof targetUserId !== "string") {
        return new Response(JSON.stringify({ error: "Missing 'userId' field" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      if (targetUserId === user.id) {
        return new Response(JSON.stringify({ error: "You cannot remove yourself" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const { error: deleteError } = await adminClient.auth.admin.deleteUser(targetUserId);
      if (deleteError) {
        return new Response(JSON.stringify({ error: deleteError.message }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (action === "set_admin") {
      const targetUserId = body.userId;
      const makeAdmin = body.isAdmin === true;
      if (!targetUserId || typeof targetUserId !== "string") {
        return new Response(JSON.stringify({ error: "Missing 'userId' field" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const { error: updateError } = await adminClient
        .from("profiles")
        .update({ is_team_admin: makeAdmin })
        .eq("id", targetUserId);

      if (updateError) {
        return new Response(JSON.stringify({ error: updateError.message }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ error: "Unknown action" }), {
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
