# Cloudflare Worker Ownership

`bmo-stack` deploys the `cloudflare/prismtek-api` Worker as `prismtek-api`.

The old duplicate `prismtek-ai` Worker was removed from Cloudflare on 2026-04-11 after Cloudflare generated alternating bot PRs that flipped `wrangler.jsonc` between `prismtek-ai` and `prismtek-api`. Keep one Worker/build integration for this repo so the Worker name, source path, GitHub checks, and dashboard integration do not drift again.
