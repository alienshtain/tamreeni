#!/usr/bin/env python3
"""Validates catalog/exercises.json and keeps assets/catalog/exercises.json (bundled copy) in sync.
Usage: python3 tool/validate_catalog.py [--sync]   (--sync copies catalog -> assets)"""
import json, os, re, shutil, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SRC = os.path.join(ROOT, "catalog", "exercises.json")
BUNDLED = os.path.join(ROOT, "assets", "catalog", "exercises.json")

CATS = {"chest", "back", "shoulders", "arms", "legs", "abs", "cardio", "warmup", "stretch", "other"}
EQUIP = {"bodyweight", "weights", "calisthenics"}
LEVELS = {"", "beginner", "intermediate", "advanced"}
MUSCLES = set("chest lats upper_back lower_back traps front_delts side_delts rear_delts biceps triceps forearms abs obliques quads hamstrings glutes calves hip_flexors adductors abductors neck full_body".split())
YT = re.compile(r"^https://(www\.)?(youtube\.com/watch\?v=|youtu\.be/)[A-Za-z0-9_-]{11}([&?].*)?$")

def main():
    errors = []
    with open(SRC, encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data.get("version"), int):
        errors.append("top-level 'version' must be an integer (bump it whenever you change the catalog)")
    ids = set()
    for i, e in enumerate(data.get("exercises", [])):
        w = f"#{i} ({e.get('id','?')})"
        eid = e.get("id", "")
        if not re.match(r"^[a-z0-9_]+$", eid):
            errors.append(f"{w}: id must be lowercase letters/digits/underscore")
        if eid in ids:
            errors.append(f"{w}: duplicate id")
        ids.add(eid)
        if not e.get("nameEn") and not e.get("nameAr"):
            errors.append(f"{w}: needs nameEn or nameAr")
        if e.get("category") not in CATS: errors.append(f"{w}: bad category")
        if e.get("type") not in ("reps", "time"): errors.append(f"{w}: type must be reps|time")
        if e.get("equipment") not in EQUIP: errors.append(f"{w}: equipment must be one of {sorted(EQUIP)}")
        if e.get("level", "") not in LEVELS: errors.append(f"{w}: bad level")
        for m in e.get("muscles", []) + e.get("secondary", []):
            if m not in MUSCLES: errors.append(f"{w}: unknown muscle '{m}'")
        if len(e.get("stepsEn", [])) != len(e.get("stepsAr", [])):
            errors.append(f"{w}: stepsEn / stepsAr must have the same length")
        if len(e.get("tipsEn", [])) != len(e.get("tipsAr", [])):
            errors.append(f"{w}: tipsEn / tipsAr must have the same length")
        v = e.get("video", "")
        if v and not YT.match(v): errors.append(f"{w}: video must be a YouTube watch/youtu.be link")
        for img in e.get("images", []):
            if not img.startswith("http") and not os.path.exists(os.path.join(ROOT, "catalog", img)):
                errors.append(f"{w}: image not found: catalog/{img}")
    if errors:
        print("\n".join("ERROR " + x for x in errors))
        sys.exit(1)
    print(f"OK: {len(ids)} exercises, catalog version {data['version']}")
    if "--sync" in sys.argv:
        shutil.copyfile(SRC, BUNDLED)
        print("synced -> assets/catalog/exercises.json")
    elif open(BUNDLED, encoding="utf-8").read() != open(SRC, encoding="utf-8").read():
        print("WARNING: assets/catalog/exercises.json differs from catalog/exercises.json (run with --sync before a release)")

if __name__ == "__main__":
    main()
