#!/usr/bin/env python3
"""
review_video.py
Orchestrates video download, audio extraction, keyframe sampling, and transcription.
Outputs a structured review folder for the assistant to analyze.
"""
import argparse
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

def run_cmd(cmd, cwd=None, check=True):
    """Run a command and return stdout, stderr, and returncode."""
    try:
        result = subprocess.run(
            cmd, shell=True, capture_output=True, text=True, cwd=cwd
        )
        if check and result.returncode != 0:
            print(f"Command failed: {cmd}", file=sys.stderr)
            print(f"stderr: {result.stderr}", file=sys.stderr)
            raise subprocess.CalledProcessError(result.returncode, cmd, result.stdout, result.stderr)
        return result
    except subprocess.CalledProcessError as e:
        if check:
            raise
        return e

def slugify(text):
    """Convert text to a safe slug."""
    text = re.sub(r'[^a-zA-Z0-9]+', '-', text)
    return text.strip('-') or "video"

def main():
    parser = argparse.ArgumentParser(description="Review and summarize a video.")
    parser.add_argument("--url", required=True, help="Video URL or file path")
    parser.add_argument("--out-dir", default="./video-review", help="Output base directory")
    parser.add_argument("--sample-seconds", type=int, default=20, help="Interval between keyframes in seconds")
    args = parser.parse_args()

    input_path = args.url
    out_base = Path(args.out_dir)
    out_base.mkdir(parents=True, exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    # If it's a URL, try to extract a slug from the URL; otherwise use the filename or a generic slug.
    if input_path.startswith(("http://", "https://")):
        slug = slugify(input_path)
    else:
        slug = slugify(Path(input_path).stem)

    target_dir = out_base / f"{timestamp}-{slug}"
    target_dir.mkdir(parents=True, exist_ok=True)
    frames_dir = target_dir / "frames"
    frames_dir.mkdir(parents=True, exist_ok=True)

    # We'll determine the video file after download.
    video_path = None
    audio_path = target_dir / "audio.wav"
    transcript_path = target_dir / "transcript.txt"
    review_path = target_dir / "REVIEW.md"

    # Initialize error tracking
    download_error = None
    transcription_error = None

    # Step 1: Download video if it's a URL, otherwise copy the file.
    print(f"Processing input: {input_path}")
    try:
        if input_path.startswith(("http://", "https://")):
            print("Downloading video with yt-dlp...")
            # Use yt-dlp to download the best video+audio format, outputting to target_dir/video.<ext>
            video_base = target_dir / "video"
            run_cmd(f"yt-dlp -o '{video_base}.%(ext)s' -f 'bv*+ba/b' {input_path!s}")
            # Find the downloaded video file
            video_files = list(target_dir.glob("video.*"))
            if not video_files:
                raise FileNotFoundError("No video file downloaded by yt-dlp")
            video_path = video_files[0]
        else:
            if not os.path.isfile(input_path):
                print(f"Error: File not found: {input_path}", file=sys.stderr)
                sys.exit(1)
            print("Copying local file...")
            video_path = target_dir / "video.mp4"
            run_cmd(f"cp {input_path!s} {video_path!s}")
    except subprocess.CalledProcessError as e:
        download_error = str(e)
        print(f"Download failed: {e}", file=sys.stderr)
        # Create a placeholder video file so that subsequent steps don't crash, but we'll note the error.
        # We'll create a tiny black video using ffmpeg (1 second) to allow the pipeline to continue.
        video_path = target_dir / "video.mp4"
        run_cmd(f"ffmpeg -f lavfi -i color=c=black:s=640x480:d=1 -c:v libx264 -pix_fmt yuv420p {video_path!s} -y")
    except Exception as e:
        download_error = str(e)
        print(f"Download failed: {e}", file=sys.stderr)
        video_path = target_dir / "video.mp4"
        run_cmd(f"ffmpeg -f lavfi -i color=c=black:s=640x480:d=1 -c:v libx264 -pix_fmt yuv420p {video_path!s} -y")

    # Step 2: Extract audio (only if we have a video file, even if it's a placeholder)
    print("Extracting audio...")
    try:
        run_cmd(f"ffmpeg -y -i {video_path!s} -vn -ac 1 -ar 16000 {audio_path!s}")
    except subprocess.CalledProcessError as e:
        transcription_error = f"Audio extraction failed: {e}"
        print(f"Audio extraction failed: {e}", file=sys.stderr)
        # Create a silent audio file to allow transcription step to run (will fail silently)
        run_cmd(f"ffmpeg -f lavfi -i anullsrc=r=16000:cl=mono -t 1 -q:a 9 -acodec libmp3lame {audio_path!s} -y")

    # Step 3: Sample keyframes.
    print(f"Sampling keyframes every {args.sample_seconds} seconds...")
    try:
        run_cmd(f"ffmpeg -y -i {video_path!s} -vf fps=1/{args.sample_seconds} {frames_dir!s}/frame-%04d.jpg")
    except subprocess.CalledProcessError as e:
        print(f"Keyframe extraction failed: {e}", file=sys.stderr)
        # We'll continue without frames

    # Step 4: Transcribe with whisper if available.
    transcribed = False
    whisper_cmd = "whisper"
    # Check if whisper is available.
    try:
        subprocess.run(["which", whisper_cmd], check=True, capture_output=True)
    except subprocess.CalledProcessError:
        print("Whisper CLI not found, skipping transcription.")
        whisper_cmd = None

    if whisper_cmd and not transcription_error:
        print("Transcribing with whisper CLI...")
        try:
            # Run whisper on the audio file, output txt to target_dir.
            run_cmd(f"{whisper_cmd} {audio_path!s} --model small --output_format txt --output_dir {target_dir!s}")
            # Whisper outputs a file named audio.txt in the target_dir.
            expected_transcript = target_dir / "audio.txt"
            if expected_transcript.exists():
                expected_transcript.rename(transcript_path)
                transcribed = True
            else:
                # Sometimes whisper names the file after the audio file.
                for f in target_dir.glob("*.txt"):
                    if f.name != "REVIEW.md":
                        f.rename(transcript_path)
                        transcribed = True
                        break
        except subprocess.CalledProcessError as e:
            transcription_error = f"Whisper transcription failed: {e}"
            print(f"Whisper transcription failed: {e}")
    elif transcription_error:
        # Already have an error from audio extraction
        pass

    # Step 5: Generate REVIEW.md with instructions for the assistant.
    frame_count = len(list(frames_dir.glob("*.jpg")))
    notes = []
    notes.append("# Video Review Prep")
    notes.append("")
    notes.append(f"- URL/File: {input_path}")
    notes.append(f"- Folder: {target_dir}")
    if download_error:
        notes.append(f"- Video: {video_path} (download failed, using placeholder)")
    else:
        notes.append(f"- Video: {video_path}")
    notes.append(f"- Frames: {frame_count} sampled every {args.sample_seconds} sec")
    if download_error or transcription_error:
        notes.append("- Errors encountered:")
        if download_error:
            notes.append(f"  * Download: {download_error}")
        if transcription_error:
            notes.append(f"  * Transcription: {transcription_error}")
    else:
        notes.append(f"- Transcript: {'available' if transcribed else 'not available (install whisper CLI for auto transcript)'}")
    notes.append("")
    notes.append("## Assistant next-step")
    notes.append("Read this folder, inspect frames, read transcript (if present), and produce:")
    notes.append("1) short summary")
    notes.append("2) timestamped highlights")
    notes.append("3) opinion/reaction")
    notes.append("")
    notes.append("## Access Note")
    notes.append("The assistant must report exactly what it could access and what it could not.")
    notes.append("If the download failed, the analysis is based on a placeholder and cannot be considered genuine.")
    notes.append("If transcription failed, the assistant should state that and proceed with visual-only analysis.")
    review_path.write_text("\n".join(notes))

    print(f"Done: {review_path}")

if __name__ == "__main__":
    main()