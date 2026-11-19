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
