# Exercise catalog / كتالوج التمارين

The app downloads **`catalog/exercises.json`** from this repository when you press *Update exercises from GitHub*.
A copy is bundled inside the APK (`assets/catalog/exercises.json`) so the app also works offline.

## Editing
1. Edit `catalog/exercises.json` (add, change or fix exercises). Put new photos in `catalog/images/<id>/0.jpg`, `1.jpg`.
2. **Bump `version`** at the top (the app shows it and uses it to compare).
3. Run `python3 tool/validate_catalog.py --sync` — validates the file and copies it to `assets/catalog/`.
4. Commit and push. Phones pick the change up with the **Update** button (exercises the user did not edit locally are refreshed automatically).

## Exercise fields
| field | meaning |
|---|---|
| `id` | stable lowercase id (`db_bench`). Never rename an id that plans may use. |
| `nameEn`, `nameAr` | English / Arabic name. The app shows `Arabic (English)` in Arabic mode and the English name in English mode. |
| `emoji` | only if it really relates to the exercise; otherwise `""` and the app shows the illustration photo |
| `category` | `chest back shoulders arms legs abs cardio warmup stretch other` |
| `type` | `reps` or `time` (holds, timed cardio, stretches, warm-ups) |
| `equipment` | `bodyweight`, `weights` (needs a weight), `calisthenics` (bar/rings or advanced bodyweight) |
| `level` | `beginner` `intermediate` `advanced` |
| `muscles`, `secondary` | keys from the muscle vocabulary in `tool/validate_catalog.py` |
| `stepsEn`, `stepsAr` | numbered instructions (same length) |
| `tipsEn`, `tipsAr` | tips (same length) |
| `video` | a YouTube link — plays inside the app |
| `link` | optional article/page link |
| `images` | paths relative to `catalog/` (or full URLs) |
| `rev` | optional: bump when you change an exercise |

## AI plans
The app's AI prompt embeds the id list from this file. An AI that returns a plan using these ids produces a file the app can import directly — all details (video, steps, photos) come from the catalog.

## Credits
Illustration photos: [free-exercise-db](https://github.com/yuhonas/free-exercise-db) (Unlicense / public domain).
Video links were collected by web search and are not individually verified; please open a PR to fix wrong or dead links.
