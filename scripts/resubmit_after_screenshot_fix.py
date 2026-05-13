import hashlib
import os
import time

import jwt
import requests

KEY_ID = os.environ.get("ASC_KEY_ID", "WDXGY9WX55")
ISSUER = os.environ.get("ASC_ISSUER_ID", "2be0734f-943a-4d61-9dc9-5d9045c46fec")
P8_PATH = os.environ.get("ASC_P8_PATH", "/tmp/asc_key.p8")
APP_ID = os.environ.get("APP_ID", "6766037910")
VERSION = os.environ.get("APP_VERSION", "1.1")
SCREENSHOT_DIR = "MarketingAssets/Screenshots"

SCREENSHOT_GROUPS = [
    ("APP_IPHONE_67", ["iphone67_01.png", "iphone67_02.png", "iphone67_03.png", "iphone67_04.png"]),
    ("APP_IPHONE_65", ["iphone65_01.png", "iphone65_02.png", "iphone65_03.png", "iphone65_04.png"]),
    ("APP_IPAD_PRO_3GEN_129", ["ipad129_01.png", "ipad129_02.png", "ipad129_03.png", "ipad129_04.png"]),
]

p8 = open(P8_PATH, encoding="utf-8").read()


def token():
    now = int(time.time())
    payload = {"iss": ISSUER, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"}
    return jwt.encode(payload, p8, algorithm="ES256", headers={"kid": KEY_ID})


def headers():
    return {"Authorization": f"Bearer {token()}", "Content-Type": "application/json"}


def api(method, path, **kwargs):
    last = None
    for _ in range(6):
        last = requests.request(
            method,
            f"https://api.appstoreconnect.apple.com/v1{path}",
            headers=headers(),
            timeout=120,
            **kwargs,
        )
        if last.status_code not in (401, 429, 500, 502, 503, 504):
            return last
        time.sleep(15)
    return last


def api_json(method, path, **kwargs):
    response = api(method, path, **kwargs)
    try:
        body = response.json()
    except Exception:
        body = {}
    return response, body


def list_all(path):
    rows = []
    next_path = path
    while next_path:
        response, body = api_json("GET", next_path)
        if response.status_code != 200:
            raise RuntimeError(f"List failed {response.status_code}: {response.text[:400]}")
        rows.extend(body.get("data", []))
        next_url = body.get("links", {}).get("next")
        next_path = next_url.split("/v1", 1)[1] if next_url else None
    return rows


def find_version():
    versions = list_all(f"/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=200")
    for version in versions:
        attrs = version.get("attributes", {})
        if attrs.get("versionString") == VERSION:
            return version["id"], attrs.get("appStoreState")
    raise RuntimeError(f"Version {VERSION} not found")


def latest_valid_build():
    builds = list_all(f"/builds?filter[app]={APP_ID}&filter[processingState]=VALID&sort=-uploadedDate&limit=20")
    if not builds:
        raise RuntimeError("No valid build found")
    return builds[0]["id"], builds[0]["attributes"]["version"]


def upload_screenshot(set_id, filename):
    path = os.path.join(SCREENSHOT_DIR, filename)
    data = open(path, "rb").read()
    checksum = hashlib.md5(data).hexdigest()
    payload = {
        "data": {
            "type": "appScreenshots",
            "attributes": {"fileName": filename, "fileSize": len(data)},
            "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}},
        }
    }
    response, body = api_json("POST", "/appScreenshots", json=payload)
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Screenshot create failed {response.status_code}: {response.text[:400]}")
    screenshot_id = body["data"]["id"]
    for operation in body["data"]["attributes"]["uploadOperations"]:
        request_headers = {item["name"]: item["value"] for item in operation["requestHeaders"]}
        start = operation["offset"]
        end = start + operation["length"]
        put = requests.put(operation["url"], headers=request_headers, data=data[start:end], timeout=120)
        if put.status_code not in (200, 201):
            raise RuntimeError(f"Screenshot binary upload failed {put.status_code}: {put.text[:200]}")
    response = api(
        "PATCH",
        f"/appScreenshots/{screenshot_id}",
        json={
            "data": {
                "type": "appScreenshots",
                "id": screenshot_id,
                "attributes": {"uploaded": True, "sourceFileChecksum": checksum},
            }
        },
    )
    if response.status_code != 200:
        raise RuntimeError(f"Screenshot finalize failed {response.status_code}: {response.text[:400]}")
    print(f"Uploaded {filename}")


def upload_screenshots(version_id):
    localizations = list_all(f"/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=200")
    for loc in localizations:
        locale = loc["attributes"]["locale"]
        sets = list_all(f"/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets?limit=200")
        existing = {item["attributes"]["screenshotDisplayType"]: item["id"] for item in sets}
        print(f"Updating screenshots: {locale}")
        for display_type, filenames in SCREENSHOT_GROUPS:
            set_id = existing.get(display_type)
            if not set_id:
                payload = {
                    "data": {
                        "type": "appScreenshotSets",
                        "attributes": {"screenshotDisplayType": display_type},
                        "relationships": {
                            "appStoreVersionLocalization": {
                                "data": {"type": "appStoreVersionLocalizations", "id": loc["id"]}
                            }
                        },
                    }
                }
                response, body = api_json("POST", "/appScreenshotSets", json=payload)
                if response.status_code not in (200, 201):
                    raise RuntimeError(f"Screenshot set create failed {response.status_code}: {response.text[:400]}")
                set_id = body["data"]["id"]
            for screenshot in list_all(f"/appScreenshotSets/{set_id}/appScreenshots?limit=200"):
                delete = api("DELETE", f"/appScreenshots/{screenshot['id']}")
                if delete.status_code not in (200, 204):
                    print(f"Delete old screenshot warning {delete.status_code}: {delete.text[:160]}")
            for filename in filenames:
                upload_screenshot(set_id, filename)


def assign_build(version_id, build_id):
    api("PATCH", f"/builds/{build_id}", json={
        "data": {"type": "builds", "id": build_id, "attributes": {"usesNonExemptEncryption": False}}
    })
    response = api(
        "PATCH",
        f"/appStoreVersions/{version_id}/relationships/build",
        json={"data": {"type": "builds", "id": build_id}},
    )
    print(f"Build assigned: {response.status_code}")


def cancel_blocking_submissions():
    for state in ("UNRESOLVED_ISSUES", "READY_FOR_REVIEW"):
        response, body = api_json("GET", f"/apps/{APP_ID}/reviewSubmissions?filter[state]={state}&limit=200")
        if response.status_code != 200:
            continue
        for submission in body.get("data", []):
            sid = submission["id"]
            response = api("PATCH", f"/reviewSubmissions/{sid}", json={
                "data": {"type": "reviewSubmissions", "id": sid, "attributes": {"canceled": True}}
            })
            print(f"Canceled {sid}: {response.status_code}")


def submit(version_id):
    response, body = api_json("POST", "/reviewSubmissions", json={
        "data": {
            "type": "reviewSubmissions",
            "attributes": {"platform": "IOS"},
            "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
        }
    })
    if response.status_code != 201:
        raise RuntimeError(f"Review submission create failed {response.status_code}: {response.text[:400]}")
    submission_id = body["data"]["id"]
    for attempt in range(10):
        response = api("POST", "/reviewSubmissionItems", json={
            "data": {
                "type": "reviewSubmissionItems",
                "relationships": {
                    "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": submission_id}},
                    "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}},
                },
            }
        })
        print(f"Add review item {attempt + 1}: {response.status_code}")
        if response.status_code == 201:
            break
        time.sleep(15)
    else:
        raise RuntimeError(f"Review item create failed: {response.text[:400]}")
    response, body = api_json("PATCH", f"/reviewSubmissions/{submission_id}", json={
        "data": {"type": "reviewSubmissions", "id": submission_id, "attributes": {"submitted": True}}
    })
    if response.status_code != 200:
        raise RuntimeError(f"Review submit failed {response.status_code}: {response.text[:400]}")
    print(f"Submitted {submission_id}: {body['data']['attributes']['state']}")


def main():
    version_id, state = find_version()
    print(f"Version {version_id}: {state}")
    build_id, build_number = latest_valid_build()
    print(f"Latest valid build: {build_number} ({build_id})")
    upload_screenshots(version_id)
    print("Waiting for App Store Connect to process screenshots...")
    time.sleep(180)
    cancel_blocking_submissions()
    time.sleep(30)
    assign_build(version_id, build_id)
    submit(version_id)


if __name__ == "__main__":
    main()
