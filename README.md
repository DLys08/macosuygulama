# AlePdf product website
Original responsive English static site. No build dependencies, tracking, forms, remote fonts, or document uploads. `dist` is the complete deployable site. The GitHub Follow and Star links are separate and exact.

## Preview
Run `python3 -m http.server 4173 --bind 127.0.0.1 --directory dist`. Open http://127.0.0.1:4173.

## Vercel portability
Import this directory as a separate project, select Other framework, no install/build command, output directory `dist`. `vercel.json` records the output directory. Do not publish publicly until the owner approves the audience. No Vercel account or credentials were changed.

The current Sites destination is owner-private; `.openai/hosting.json` identifies it. Keep that configuration for Sites, omit `.openai` when distributing a portable website source copy.

## Before public launch
1. Clear app icon provenance and the asset audit; retain original legal notices and complete distribution license review.
2. Sign/notarize with the owner's authorized Apple developer credentials, or accurately disclose any preview limitations. Do not bypass macOS security.
3. Publish an explicitly approved verified app release, checksum, and release notes. Replace the pending download section with its actual URL; test it.
4. Confirm platform/minimum OS support with device tests. This preview only claims Apple Silicon macOS.
5. Set approved public canonical/social metadata and remove `noindex` only when public launch is authorized.

## Evidence and artwork
Fresh unaltered screenshots captured from installed AlePdf 0.15.0 local.20261031.a3784c39 on 2026-10-31. Document is fictional and created for this preview; source PDF is in `tools`. Screenshots show the editor and Fill & Sign, avoiding the disputed Home icon. They contain no private documents. PDF uses standard font names, no embedded proprietary fonts; screenshots reflect actual runtime rendering, not a font-licensing clearance. Website uses system font stacks without distributing font files.

The pages mark SVG and website layout/copy are original for this task. No ArtCraft website assets were copied. App credits preserve PdfCraft / ArtCraft Team attribution; source licensing does not establish clearance of every asset. The local review ZIP is deliberately outside `dist` and is not hosted.
