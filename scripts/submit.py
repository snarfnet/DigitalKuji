import hashlib
import os
import sys
import time

import jwt
import requests

KEY_ID = 'WDXGY9WX55'
ISSUER = '2be0734f-943a-4d61-9dc9-5d9045c46fec'
APP_ID = '6766037910'
BUILD_NUMBER = sys.argv[1]
APP_VERSION = os.environ.get('APP_VERSION', '1.1')
SCREENSHOT_DIR = 'MarketingAssets/Screenshots'

SCREENSHOT_GROUPS = [
    ('APP_IPHONE_67', ['iphone67_01.png', 'iphone67_02.png', 'iphone67_03.png', 'iphone67_04.png']),
    ('APP_IPHONE_65', ['iphone65_01.png', 'iphone65_02.png', 'iphone65_03.png', 'iphone65_04.png']),
    ('APP_IPAD_PRO_3GEN_129', ['ipad129_01.png', 'ipad129_02.png', 'ipad129_03.png', 'ipad129_04.png']),
]

META = {
    'ja': {
        'description': 'シェイクでくじを引ける、シンプルなデジタルくじ引きアプリです。\n\n数字・色・テキストの3つのモードに対応。順番決め、抽選、プレゼント交換、ちょっとしたゲームに使えます。\n\n主な機能:\n- 数字くじ\n- 色くじ\n- テキストくじ\n- シェイクで抽選\n- 抽選履歴の表示',
        'keywords': 'おみくじ,くじ引き,抽選,ランダム,シェイク,順番決め,ルーレット,パーティー,占い,ゲーム',
        'whatsNew': '画面デザインを刷新しました。',
    },
    'en-US': {
        'description': 'Draw a quick digital lottery by shaking your device.\n\nDigital Kuji supports three modes: numbers, colors, and custom text. Use it for turn order, raffles, gift exchanges, party games, and quick random picks.\n\nFeatures:\n- Number lottery\n- Color lottery\n- Custom text lottery\n- Shake to draw\n- Draw history',
        'keywords': 'omikuji,lottery,draw,random,shake,picker,party,game,raffle,fortune',
        'whatsNew': 'Refreshed the screen design.',
    },
}

p8 = open('/tmp/asc_key.p8').read()

def make_token():
    return jwt.encode(
        {'iss': ISSUER, 'iat': int(time.time()), 'exp': int(time.time()) + 1200, 'aud': 'appstoreconnect-v1'},
        p8, algorithm='ES256', headers={'kid': KEY_ID}
    )

def headers():
    return {'Authorization': f'Bearer {make_token()}', 'Content-Type': 'application/json'}

def api(method, path, **kwargs):
    r = requests.request(method, f'https://api.appstoreconnect.apple.com/v1{path}',
        headers=headers(), **kwargs)
    return r

def api_json(method, path, **kwargs):
    r = api(method, path, **kwargs)
    try:
        body = r.json()
    except Exception:
        body = {}
    return r, body

def list_all(path):
    rows = []
    next_path = path
    while next_path:
        r, body = api_json('GET', next_path)
        if r.status_code != 200:
            raise RuntimeError(f'List failed {r.status_code}: {r.text[:300]}')
        rows.extend(body.get('data', []))
        next_url = body.get('links', {}).get('next')
        next_path = next_url.split('/v1', 1)[1] if next_url else None
    return rows

def ensure_localizations(version_id):
    localizations = list_all(f'/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=200')
    existing = {item['attributes']['locale']: item for item in localizations}
    for locale, meta in META.items():
        if locale not in existing:
            payload = {
                'data': {
                    'type': 'appStoreVersionLocalizations',
                    'attributes': {'locale': locale},
                    'relationships': {'appStoreVersion': {'data': {'type': 'appStoreVersions', 'id': version_id}}},
                }
            }
            r, body = api_json('POST', '/appStoreVersionLocalizations', json=payload)
            if r.status_code in (200, 201):
                existing[locale] = body['data']
        if locale in existing:
            loc_id = existing[locale]['id']
            api('PATCH', f'/appStoreVersionLocalizations/{loc_id}', json={
                'data': {'type': 'appStoreVersionLocalizations', 'id': loc_id, 'attributes': meta}
            })
    return list(existing.values())

def ensure_screenshot_sets(version_id):
    localizations = ensure_localizations(version_id)
    if not localizations:
        raise RuntimeError('No localizations found for screenshot upload.')
    for loc in localizations:
        locale = loc['attributes']['locale']
        print(f'Screenshots for {locale}')
        sets = list_all(f"/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets?limit=200")
        existing = {item['attributes']['screenshotDisplayType']: item['id'] for item in sets}
        for display_type, filenames in SCREENSHOT_GROUPS:
            set_id = existing.get(display_type)
            if not set_id:
                payload = {
                    'data': {
                        'type': 'appScreenshotSets',
                        'attributes': {'screenshotDisplayType': display_type},
                        'relationships': {
                            'appStoreVersionLocalization': {
                                'data': {'type': 'appStoreVersionLocalizations', 'id': loc['id']}
                            }
                        },
                    }
                }
                r, body = api_json('POST', '/appScreenshotSets', json=payload)
                if r.status_code not in (200, 201):
                    raise RuntimeError(f'Screenshot set create failed {r.status_code}: {r.text[:300]}')
                set_id = body['data']['id']
            for screenshot in list_all(f'/appScreenshotSets/{set_id}/appScreenshots?limit=200'):
                api('DELETE', f"/appScreenshots/{screenshot['id']}")
            for filename in filenames:
                upload_screenshot(set_id, filename)

def upload_screenshot(set_id, filename):
    path = os.path.join(SCREENSHOT_DIR, filename)
    if not os.path.exists(path):
        raise RuntimeError(f'Missing screenshot: {path}')
    data = open(path, 'rb').read()
    checksum = hashlib.md5(data).hexdigest()
    payload = {
        'data': {
            'type': 'appScreenshots',
            'attributes': {'fileName': filename, 'fileSize': len(data)},
            'relationships': {'appScreenshotSet': {'data': {'type': 'appScreenshotSets', 'id': set_id}}},
        }
    }
    r, body = api_json('POST', '/appScreenshots', json=payload)
    if r.status_code not in (200, 201):
        raise RuntimeError(f'Screenshot create failed {r.status_code}: {r.text[:300]}')
    screenshot_id = body['data']['id']
    for operation in body['data']['attributes']['uploadOperations']:
        request_headers = {item['name']: item['value'] for item in operation['requestHeaders']}
        start = operation['offset']
        end = start + operation['length']
        requests.put(operation['url'], headers=request_headers, data=data[start:end], timeout=120)
    r = api('PATCH', f'/appScreenshots/{screenshot_id}', json={
        'data': {
            'type': 'appScreenshots',
            'id': screenshot_id,
            'attributes': {'uploaded': True, 'sourceFileChecksum': checksum},
        }
    })
    print(f'  {filename}: {r.status_code}')

print(f'Waiting for build {BUILD_NUMBER} to be processed...')
build_id = None
for i in range(80):
    r = api('GET', f'/builds?filter[app]={APP_ID}&filter[version]={BUILD_NUMBER}&filter[processingState]=VALID&limit=1')
    data = r.json()
    if data.get('data'):
        build_id = data['data'][0]['id']
        print(f'Build ready: {build_id}')
        break
    print(f'  Waiting... ({i+1}/80)')
    time.sleep(30)

if not build_id:
    print('WARNING: Build not found after 40 minutes. Check ASC manually.')
    sys.exit(0)

# Set export compliance
r = api('PATCH', f'/builds/{build_id}',
    json={'data': {'type': 'builds', 'id': build_id, 'attributes': {'usesNonExemptEncryption': False}}})
print(f'Export compliance: {r.status_code}')

# Find version
version_id = None
version_state = None
for version in list_all(f'/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=200'):
    attrs = version['attributes']
    if attrs.get('versionString') == APP_VERSION:
        version_id = version['id']
        version_state = attrs['appStoreState']
        print(f'Found version: {version_id} state={version_state}')
        break

if version_state in ('WAITING_FOR_REVIEW', 'IN_REVIEW'):
    print(f'Already in review ({version_state}). Nothing to do.')
    sys.exit(0)

if not version_id or version_state in ('READY_FOR_DISTRIBUTION',):
    print('Creating new version...')
    r = api('POST', '/appStoreVersions', json={
        'data': {
            'type': 'appStoreVersions',
            'attributes': {'platform': 'IOS', 'versionString': APP_VERSION},
            'relationships': {'app': {'data': {'type': 'apps', 'id': APP_ID}}}
        }
    })
    if r.status_code not in (200, 201):
        print(f'Failed to create version: {r.text[:300]}')
        sys.exit(1)
    version_id = r.json()['data']['id']
    version_state = 'PREPARE_FOR_SUBMISSION'

print(f'Version ID: {version_id} state={version_state}')

# Assign build
r = api('PATCH', f'/appStoreVersions/{version_id}/relationships/build',
    json={'data': {'type': 'builds', 'id': build_id}})
print(f'Build assigned: {r.status_code}')

# Cancel any blocking reviewSubmissions
canceled_any = False
for state_filter in ['UNRESOLVED_ISSUES', 'READY_FOR_REVIEW']:
    r = api('GET', f'/apps/{APP_ID}/reviewSubmissions?filter[state]={state_filter}')
    if r.status_code == 200:
        for sub in r.json().get('data', []):
            sid = sub['id']
            st = sub['attributes']['state']
            cr = api('PATCH', f'/reviewSubmissions/{sid}', json={
                'data': {'type': 'reviewSubmissions', 'id': sid, 'attributes': {'canceled': True}}
            })
            print(f'Cancel {sid} state={st}: {cr.status_code}')
            canceled_any = True

if canceled_any:
    print('Waiting 30s for cancellations to propagate...')
    time.sleep(30)
    r = api('GET', f'/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=1')
    data = r.json()
    if data.get('data'):
        version_id = data['data'][0]['id']
        version_state = data['data'][0]['attributes']['appStoreState']
        print(f'Version after cancel: {version_id} state={version_state}')
    r = api('PATCH', f'/appStoreVersions/{version_id}/relationships/build',
        json={'data': {'type': 'builds', 'id': build_id}})
    print(f'Build re-assigned: {r.status_code}')

ensure_screenshot_sets(version_id)
print('Waiting 180s for screenshots to process...')
time.sleep(180)

# Submit via reviewSubmissions API
submission_id = None
for attempt in range(5):
    r = api('POST', '/reviewSubmissions', json={
        'data': {
            'type': 'reviewSubmissions',
            'relationships': {'app': {'data': {'type': 'apps', 'id': APP_ID}}}
        }
    })
    if r.status_code == 201:
        submission_id = r.json()['data']['id']
        print(f'ReviewSubmission created: {submission_id}')
        break
    print(f'Create reviewSubmission attempt {attempt+1}/5 failed: {r.status_code} {r.text[:200]}')
    if attempt < 4:
        time.sleep(15)

if not submission_id:
    print('Could not create reviewSubmission after 5 attempts.')
    sys.exit(0)

# Add item
item_added = False
for attempt in range(5):
    r = api('POST', '/reviewSubmissionItems', json={
        'data': {
            'type': 'reviewSubmissionItems',
            'relationships': {
                'reviewSubmission': {'data': {'type': 'reviewSubmissions', 'id': submission_id}},
                'appStoreVersion': {'data': {'type': 'appStoreVersions', 'id': version_id}}
            }
        }
    })
    print(f'Add item attempt {attempt+1}/5: {r.status_code}')
    if r.status_code == 201:
        item_added = True
        break
    if attempt < 4:
        time.sleep(15)

if not item_added:
    print(f'Failed to add item: {r.text[:300]}')
    sys.exit(0)

r = api('PATCH', f'/reviewSubmissions/{submission_id}', json={
    'data': {
        'type': 'reviewSubmissions',
        'id': submission_id,
        'attributes': {'submitted': True}
    }
})
if r.status_code == 200:
    state = r.json()['data']['attributes']['state']
    print(f'Submitted! State: {state}')
else:
    print(f'Submit failed: {r.status_code} {r.text[:300]}')
