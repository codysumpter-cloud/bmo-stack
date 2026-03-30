---
name: video-review
description: Review and summarize online videos (especially YouTube) by extracting transcript + keyframes with local tools. Use when the user asks you to "watch" a video link, react to a video, summarize a video, or extract highlights/timestamps.
---

# Video Review

Use this skill when the user wants a real video breakdown instead of metadata-only comments.

## Workflow

1. Run `skills/video-review/scripts/review_video.py` with the target URL or file path.
2. Read the generated `REVIEW.md` in the output directory.
3. Reply with:
   - 3-6 bullet summary
   - best moments with timestamps
   - your opinion/take
   - any missing capability note (if transcription failed)

## Command

```bash
python3 skills/video-review/scripts/review_video.py --url "<video-url-or-file>" [--out-dir "./video-review"] [--sample-seconds 20]
```

## Output Location

- `<out-dir>/<timestamp>-<slug>/REVIEW.md`
- `<out-dir>/<timestamp>-<slug>/transcript.txt` (if available)
- `<out-dir>/<timestamp>-<slug>/frames/`

## Notes

- Requires `yt-dlp` + `ffmpeg` in PATH.
- Uses `whisper` CLI if available for local transcription.
- If transcript is unavailable, still provide visual/keyframe-based observations and clearly say transcription was unavailable.

## Smoke Test
Verify end-to-end function:
```bash
python3 skills/video-review/scripts/review_video.py \
  --url "https://www.youtube.com/watch?v=jNQXAC9IVRw" \
  --out-dir "./test-output" \
  --sample-seconds 5
# Expect: test-output/*/REVIEW.md with content summary, transcript.txt, frames/
```
Dependencies: yt-dlp, ffmpeg, whisper CLI

