import urllib.request
import urllib.error
import json
import time
import re

env_url = ""
env_key = ""
service_key = ""

try:
    with open("assets/.env", "r", encoding="utf-8") as f:
        content = f.read()
        url_match = re.search(r'SUPABASE_URL\s*=\s*["\']?([^"\'\s,\n]+)', content)
        key_match = re.search(r'SUPABASE_ANON_KEY\s*=\s*["\']?([^"\'\s,\n]+)', content)
        skey_match = re.search(r'SUPABASE_SERVICE_ROLE_KEY\s*=\s*["\']?([^"\'\s,\n]+)', content)
        
        if url_match: env_url = url_match.group(1)
        if key_match: env_key = key_match.group(1)
        if skey_match: service_key = skey_match.group(1)
except Exception as e:
    print(f"❌ Error reading assets/.env: {e}")
    exit(1)

# Prefer Service Role Key for automated script bypass, fall back to anon key
active_key = service_key if service_key else env_key

headers = {
    "apikey": active_key,
    "Authorization": f"Bearer {active_key}",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

print(f"🔑 Target URL: {env_url}")
print(f"🔑 Using Key Type: {'Service Role (Bypasses RLS)' if service_key else 'Anon Key'}")
print("🚀 Sending Realtime Test Payload to Supabase...")

insert_url = f"{env_url}/rest/v1/applications"
test_data = json.dumps({
    "user_id": "00000000-0000-0000-0000-000000000000",
    "job_title": "Realtime AI Specialist (TEST)",
    "company_name": "Hylo Realtime Hub",
    "status": "applied"
}).encode("utf-8")

req_insert = urllib.request.Request(insert_url, data=test_data, headers=headers, method="POST")

try:
    with urllib.request.urlopen(req_insert) as response:
        res = json.loads(response.read().decode("utf-8"))
        app_id = res[0]["id"]
        print(f"\n✅ Test row created in Supabase (ID: {app_id})!")
        print("👀 Look at your simulator: The application should appear live on the Recruiter view!")
        
        print("\n⏳ Waiting 5 seconds before updating status to 'shortlisted'...")
        time.sleep(5)
        
        update_url = f"{env_url}/rest/v1/applications?id=eq.{app_id}"
        update_data = json.dumps({"status": "shortlisted"}).encode("utf-8")
        update_req = urllib.request.Request(update_url, data=update_data, headers=headers, method="PATCH")
        
        with urllib.request.urlopen(update_req):
            print("\n⚡ Status updated to 'shortlisted'!")
            print("✨ Look at your simulator: The status badge should morph instantly!")

except urllib.error.HTTPError as e:
    error_body = e.read().decode("utf-8")
    print(f"❌ Insert Failed (HTTP {e.code}): {error_body}")
