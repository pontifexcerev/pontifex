# PONTIFEX site: GitHub setup

## What is in this folder
| Path | What it is |
|---|---|
| `index.html` | The whole site (achievements, skill tree, trophy case, redesign) |
| `config.js` | Your Supabase keys, registration form, billing text. Fill it in, then commit |
| `content.json` | Lessons, resources and flashcards (edited with the content editor) |
| `content-editor.html` | Add content and upload PDFs from your browser |
| `Badges/` | Your 30 badge PNGs, unchanged |
| `files/` | Your PDFs go here (the editor uploads to this folder) |
| `logo-*.png`, `app-icon-*.png`, `apple-touch-icon.png` | Logos and icons |
| `.nojekyll` | Tells GitHub Pages to serve files as they are |

## Put it on GitHub Pages
1. Create a repository (for example `pontifex`).
2. Upload everything in this folder, keeping the folder names exactly as they are (`Badges` with a capital B).
3. Settings, then Pages, then Deploy from branch, `main`, root.
4. Open `https://YOUR-USERNAME.github.io/pontifex/`.

## Using the content editor
Open `/content-editor.html` on your site.
1. Create a fine-grained token at GitHub, Settings, Developer settings, Fine-grained tokens. Limit it to this repository with **Contents: Read and write**.
2. Enter your username, repository, branch and token, then press **Load content.json from GitHub**.
3. Add lessons, resources and flashcards. In **PDF uploader**, drop PDFs to upload them to `files/`, then pick them when adding a lesson or resource.
4. In **Publish**, press **Commit content.json to GitHub**. No token? Use **Download content.json** and upload it to the repository by hand.

## Showing badges to other players (optional)
Run this once in the Supabase SQL editor, then add `badges` to the columns returned by your `get_leaderboard` function:

    alter table profiles add column if not exists badges text default '';

## If a badge image looks broken
The folder must be named exactly `Badges`, because GitHub is case-sensitive. A badge file can be named either `Theory of Structure.png` or `The Unshaken Order - Theory of Structure.png`. Major badges can be `STRUCT.png` or `Vitruvius Badge - STRUCT.png`.


## What changed in this update

### Time limits and item counts
| Activity | Time | Items |
|---|---|---|
| Diagnostic (each of the 6) | 2 hours | 30 |
| PSAD mock | 6 hours | 75 |
| MSTHC mock | 5 hours | 75 |
| HGE mock | 4 hours | 50 |
| Topic drill | 3 hours | 10 |
| Quiz (topic or mixed) | 3 hours | 30 |

If a bank has fewer questions than the target, the activity uses what exists. To change any number, add this to `config.js` (inside `window.PX_CONFIG`, minutes):

    timing: { diagnostic: 120, mock: [360, 300, 240], drill: 180, quiz: 180 },
    questionCounts: { diag: 30, quiz: 30, drill: 10 },

`mock` is in the order PSAD, MSTHC, HGE. Mock question counts still come from `mockSizes`.

### Situational problems and figure codes (CSV and editor)
Two new optional columns: `situation` and `situation_text`.
* Give every item of one situation the same `situation` code, for example `SIT-PSAD-01`. Type the situation statement once in `situation_text` (first row is enough).
* The site shows the situation and its figure once, above its items ("Items 4 to 6"), and keeps those items together in quizzes and mocks.
* `image` accepts figure codes. Name the file after the code and upload it to `files/figures/` (for example `FIG-PSAD-01.png`). The extension is found automatically (png, jpg, jpeg, webp, svg, gif). Names starting with `FIG-` show the code under the figure.
* On a row with a `situation`, the `image` is shown once with the situation. On other rows it is shown with that question.

### Review flow
Students see it under Review > Review flow (free for everyone). To change it: content editor > Review flow tab > "Start from the recommended flow", edit, then Publish. Until you publish a flow, the built-in default (your list plus a few suggested additions) is shown.

### Library search
Library > Search. Students type a topic (short names like rcd, proba, strema, geo also work) and get the references, videos, tables, lessons and formulas linked to it. A reference appears under a topic when you pick that topic while adding the resource in the content editor.

### Cross-device sync (v2 fix)
Progress is now merged between devices instead of the newest device replacing everything. A new device downloads your progress first and only then uploads. A cloud icon in the top bar shows "✓" when synced and "⚠ Not synced" with the reason (tap it) if the database refuses the save. Run `supabase-sync-fix.sql` once in Supabase to make sure the table, permissions and 6-hourly backups exist.
