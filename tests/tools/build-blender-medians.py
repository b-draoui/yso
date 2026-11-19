#!/usr/bin/env python3
"""Builds data/blender-medians.json from the public Blender Open Data snapshot (CC0).

For each device (its kind and its name, written the way YSO writes it), each Blender version
(major.minor) and each of the three scenes YSO runs: the median samples per minute and how many
results it comes from. The PC passport of YSO (40) compares its own Blender Benchmark run with
these medians. Run every week by .github/workflows/blender-medians.yml.

Usage: python3 tests/tools/build-blender-medians.py data/blender-medians.json [snapshot.zip]
"""
import datetime, io, json, re, statistics, sys, urllib.request, zipfile

URL = 'https://opendata.blender.org/snapshots/opendata-latest.zip'
SCENES = ('monster', 'junkshop', 'classroom')
MIN_COUNT = 5          # fewer public results than this: no median for that scene


def bench_key(kind, name):
    """The same rules as ConvertTo-BenchKey in YSO.ps1 (PowerShell's -replace ignores case)."""
    n = re.sub(r'\((R|TM|C)\)', '', name, flags=re.I)
    n = re.sub(r'\s+CPU$', '', n, flags=re.I)
    n = re.sub(r'\s+', ' ', n).strip().lower()
    return '%s|%s' % (kind.upper(), n)


def bench_version(v):
    m = re.match(r'^(\d+)\.(\d+)', str(v or ''))
    return '%s.%s' % (m.group(1), m.group(2)) if m else ''


def results(obj):
    """Every benchmark result in a piece of the snapshot, wherever it sits: an object with a scene,
    stats and device_info (the layout of "benchmark --json")."""
    stack = [obj]
    while stack:
        o = stack.pop()
        if isinstance(o, list):
            stack.extend(o)
        elif isinstance(o, dict):
            if isinstance(o.get('scene'), dict) and isinstance(o.get('stats'), dict) and isinstance(o.get('device_info'), dict):
                yield o
            else:
                stack.extend(v for v in o.values() if isinstance(v, (dict, list)))


def device_of(r):
    """(kind, name) of the device that rendered, or None: several graphics cards, or a graphics card
    helped by the processor, are left out because they are not comparable."""
    di = r['device_info']
    kind = str(di.get('device_type') or '').upper()
    devs = di.get('compute_devices') or []
    names = []
    for d in devs:
        if isinstance(d, dict):
            names.append((str(d.get('type') or kind).upper(), str(d.get('name') or '')))
        else:
            names.append((kind, str(d)))
    if not kind or not names:
        return None
    if kind == 'CPU':
        return ('CPU', names[0][1]) if names[0][1] else None
    gpus = [n for t, n in names if t != 'CPU']
    if len(gpus) != 1 or len(gpus) != len(names):
        return None
    return (kind, gpus[0])


def main():
    out_path = sys.argv[1] if len(sys.argv) > 1 else 'data/blender-medians.json'
    if len(sys.argv) > 2:
        data = open(sys.argv[2], 'rb').read()
    else:
        req = urllib.request.Request(URL, headers={'User-Agent': 'YSO medians builder (github.com/b-draoui/yso)'})
        data = urllib.request.urlopen(req, timeout=600).read()
    values = {}
    seen = 0
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        for member in z.namelist():
            if not member.lower().endswith(('.json', '.jsonl')):
                continue
            with z.open(member) as f:
                text = io.TextIOWrapper(f, encoding='utf-8', errors='replace')
                if member.lower().endswith('.jsonl'):
                    chunks = (line for line in text if line.strip())
                else:
                    chunks = [text.read()]
                for chunk in chunks:
                    try:
                        obj = json.loads(chunk)
                    except ValueError:
                        continue
                    for r in results(obj):
                        seen += 1
                        scene = str(r['scene'].get('label') or '').lower()
                        if scene not in SCENES:
                            continue
                        try:
                            spm = float(r['stats'].get('samples_per_minute'))
                        except (TypeError, ValueError):
                            continue
                        if not spm > 0:
                            continue
                        dev = device_of(r)
                        ver = bench_version((r.get('blender_version') or {}).get('version') if isinstance(r.get('blender_version'), dict) else r.get('blender_version'))
                        if not dev or not ver:
                            continue
                        values.setdefault(bench_key(*dev), {}).setdefault(ver, {}).setdefault(scene, []).append(spm)
    devices = {}
    for k, vers in values.items():
        for v, scenes in vers.items():
            keep = {s: [round(statistics.median(x), 2), len(x)] for s, x in scenes.items() if len(x) >= MIN_COUNT}
            if keep:
                devices.setdefault(k, {})[v] = keep
    if seen == 0 or not devices:
        sys.exit('no benchmark result found in the snapshot: its layout changed?')
    out = {
        'source': URL,
        'license': 'CC0 1.0 (Blender Open Data)',
        'built': datetime.date.today().isoformat(),
        'results_read': seen,
        'min_results': MIN_COUNT,
        'devices': devices,
    }
    with open(out_path, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(out, f, sort_keys=True, separators=(',', ':'), ensure_ascii=False)
        f.write('\n')
    print('%d results read, %d devices written to %s' % (seen, len(devices), out_path))


if __name__ == '__main__':
    main()
