import urllib.request
import urllib.error
import json
import time

URL = "https://zdcaranlkgscrvikoxsc.supabase.co"
KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpkY2FyYW5sa2dzY3J2aWtveHNjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MTUwMjg1OSwiZXhwIjoyMDk3MDc4ODU5fQ.W3VA4O0hHUVGmrhQX14ZWscIoM7kfakxSiTy3TYte2E"

headers = {
    "apikey": KEY,
    "Authorization": "Bearer " + KEY,
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

user_id = "00ea64de-c531-45b8-841d-c9079be3df35"

timestamp = time.strftime("%I:%M:%S %p")

print("\n------------------------------------------------------------")
print(f"🎬 STEP 1: Inserting new card at {timestamp}...")
print("------------------------------------------------------------")

payload = {
    "user_id": user_id,
    "job_title": f"Realtime Flutter Test ({timestamp})",
    "company_name": "Jobscout HQ",
    "status": "applied"
}

insert_url = URL + "/rest/v1/applications"
test_data = json.dumps(payload).encode("utf-8")
req_insert = urllib.request.Request(insert_url, data=test_data, headers=headers, method="POST")

try:
    with urllib.request.urlopen(req_insert) as response:
        res = json.loads(response.read().decode("utf-8"))
        app_id = res[0]["id"]
        
        print(f"✅ Created Application ID: {app_id}")
        print(f"👉 Title: 'Realtime Flutter Test ({timestamp})'")
        print("\n📲 LOOK AT YOUR FLUTTER SIMULATOR NOW!")

        for i in range(8, 0, -1):
            print(f"⏳ Updating status in {i} seconds...", end="\r")
            time.sleep(1)

        print("\n\n------------------------------------------------------------")
        print("⚡ STEP 2: Patching status to 'shortlisted'...")
        print("------------------------------------------------------------")

        update_url = URL + f"/rest/v1/applications?id=eq.{app_id}"
        update_data = json.dumps({"status": "shortlisted"}).encode("utf-8")
        update_req = urllib.request.Request(update_url, data=update_data, headers=headers, method="PATCH")

        with urllib.request.urlopen(update_req):
            print("✅ Status updated in DB!")
            print("✨ Look at the simulator: Badge should change to Shortlisted!")
            print("------------------------------------------------------------\n")

except urllib.error.HTTPError as e:
    error_body = e.read().decode("utf-8")
    print(f"\n❌ Request failed (HTTP {e.code}): {error_body}")
except Exception as e:
    print(f"\n❌ Unexpected error: {e}")
