# AlePdf product website
Original responsive Turkish/English site. No build dependencies, application analytics, forms, remote fonts, or document uploads. Deploy `dist`, `api/locale.js`, and `vercel.json`. The GitHub Follow and Star links are separate and exact.

## Preview
Run `python3 -m http.server 4173 --bind 127.0.0.1 --directory dist`. Open http://127.0.0.1:4173.

## Vercel portability
Import this directory as a separate project, select Other framework, no install/build command, output directory `dist`. `vercel.json` records the output directory. The owner authorized the public site at https://alepdf-website.vercel.app/. No Vercel account or credentials were changed.

The earlier Sites preview remains private and is not the public host. `.openai/hosting.json` refers only to that preserved preview; omit `.openai` from Vercel deployments.

## Before public launch
1. Clear app icon provenance and the asset audit; retain original legal notices and complete distribution license review.
2. Sign/notarize with the owner's authorized Apple developer credentials, and require Gatekeeper acceptance before enabling the Mac download. Do not bypass macOS security.
3. Publish an explicitly approved verified app release, checksum, and release notes. Replace the pending download section with its actual URL; test it.
4. Confirm platform/minimum OS support with device tests. This preview only claims Apple Silicon macOS.
5. Set approved public canonical/social metadata and remove `noindex` only when public launch is authorized.

## Evidence and artwork
Fresh unaltered screenshots captured from installed AlePdf 0.15.0 local.20261031.a3784c39 on 2026-10-31. Document is fictional and created for this preview; source PDF is in `tools`. Screenshots show the editor and Fill & Sign, avoiding the disputed Home icon. They contain no private documents. PDF uses standard font names, no embedded proprietary fonts; screenshots reflect actual runtime rendering, not a font-licensing clearance. Website uses system font stacks without distributing font files.

The pages mark SVG and website layout/copy are original for this task. No ArtCraft website assets were copied. App credits preserve PdfCraft / ArtCraft Team attribution; source licensing does not establish clearance of every asset. The local review ZIP is deliberately outside `dist` and is not hosted.

## Localization
`dist/index.html` is English; `scripts/translate.py` generates `dist/tr/index.html` and rejects untranslated copy nodes. Run it after English copy changes and update the translation mapping. `dist/locale.js` resolves persisted manual TR/EN choice first, then Vercel country (TR → tr; other known country → en), then browser-language fallback. `/api/locale` reads only `x-vercel-ip-country` and returns it with `private, no-store`; application code does not read or persist IP, city, coordinates or country. The browser stores only the manual language choice. Vercel's ordinary hosting request handling remains subject to its platform policies.

## Current distribution hold
Mac ad-hoc preview triggered an Apple verification warning. Website download is disabled pending Developer ID signing and Apple notarization. Do not treat checksum/signature integrity as Gatekeeper trust, and do not offer bypass instructions. Windows preview 0.15.0 windows-preview.1 is published. Collision tests, portable extraction/CLI, asset audit, per-user EXE install, GUI window startup and uninstall passed on the Windows runner. Interactive PDF editing was not tested. Installer is unsigned. Public EXE anonymously downloaded and SHA-256 verified: f0ce5abc1297f9cd28f3541ea677a56b047fd8423fd08f7e74663dfd940e6a9f.

## Cat artwork
`dist/assets/cat-icon.png` derives from original OpenAI-generated artwork created for the owner on 31 October 2026, with no third-party reference art. Provenance and full resolution original are retained outside this site in the separate release workspace. No installed application is modified by this site.
