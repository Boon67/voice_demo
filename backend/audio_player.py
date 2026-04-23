import os
import subprocess
import tempfile
import logging
import json
from typing import List
import config

logger = logging.getLogger(__name__)


def get_audio_duration(path: str) -> float:
    result = subprocess.run(
        ["ffprobe", "-v", "quiet", "-print_format", "json", "-show_format", path],
        capture_output=True, text=True
    )
    info = json.loads(result.stdout)
    return float(info["format"]["duration"])


def split_audio_file(path: str, segment_seconds: int = None) -> List[str]:
    if segment_seconds is None:
        segment_seconds = config.SEGMENT_SECONDS
    duration = get_audio_duration(path)
    total_chunks = int(duration // segment_seconds) + (1 if duration % segment_seconds > 1 else 0)
    tmp_dir = tempfile.mkdtemp(prefix="call_center_chunks_")
    chunks = []

    for i in range(total_chunks):
        start = i * segment_seconds
        out_path = os.path.join(tmp_dir, f"chunk_{i+1:03d}.mp3")
        subprocess.run(
            [
                "ffmpeg", "-y", "-i", path,
                "-ss", str(start), "-t", str(segment_seconds),
                "-acodec", "libmp3lame", "-q:a", "4",
                out_path
            ],
            capture_output=True
        )
        if os.path.exists(out_path) and os.path.getsize(out_path) > 0:
            chunks.append(out_path)
        else:
            logger.warning(f"Chunk {i+1} empty, skipping")

    logger.info(f"Split {path} into {len(chunks)} chunks of {segment_seconds}s each")
    return chunks


def cleanup_chunks(chunks: List[str]):
    for path in chunks:
        try:
            os.remove(path)
        except Exception:
            pass
    if chunks:
        try:
            os.rmdir(os.path.dirname(chunks[0]))
        except Exception:
            pass
