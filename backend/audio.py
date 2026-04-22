import os
import io
import time
import uuid
import threading
import logging
from typing import Callable, Optional

logger = logging.getLogger(__name__)

AUDIO_AVAILABLE = False
try:
    import pyaudio
    from pydub import AudioSegment
    AUDIO_AVAILABLE = True
except ImportError:
    logger.warning("PyAudio/pydub not available — audio recording disabled, use simulator")


RATE = 44100
CHANNELS = 1
FORMAT = None
CHUNK_FRAMES = 1024
SEGMENT_SECONDS = 10
OVERLAP_OFFSET = 7

if AUDIO_AVAILABLE:
    FORMAT = pyaudio.paInt16


class AudioRecorder:
    def __init__(self, case_id: int, call_id: str, output_dir: str, on_segment: Optional[Callable] = None):
        self.case_id = case_id
        self.call_id = call_id
        self.output_dir = output_dir
        self.on_segment = on_segment
        self._recording = False
        self._chunk_counter = 0
        self._primary_buffer = []
        self._secondary_buffer = []
        self._archive_frames = []
        self._primary_frame_count = 0
        self._secondary_frame_count = 0
        self._stream = None
        self._pa = None
        self._thread = None
        os.makedirs(output_dir, exist_ok=True)

    @property
    def is_recording(self):
        return self._recording

    @property
    def chunk_count(self):
        return self._chunk_counter

    def start(self):
        if not AUDIO_AVAILABLE:
            logger.error("Audio not available")
            return False
        self._recording = True
        self._pa = pyaudio.PyAudio()
        self._stream = self._pa.open(
            format=FORMAT,
            channels=CHANNELS,
            rate=RATE,
            input=True,
            frames_per_buffer=CHUNK_FRAMES,
        )
        self._thread = threading.Thread(target=self._record_loop, daemon=True)
        self._thread.start()
        return True

    def stop(self) -> Optional[str]:
        self._recording = False
        if self._thread:
            self._thread.join(timeout=5)
        if self._stream:
            self._stream.stop_stream()
            self._stream.close()
        if self._pa:
            self._pa.terminate()
        archive_path = None
        if self._archive_frames:
            archive_path = self._save_mp3(self._archive_frames, "archive")
        return archive_path

    def _record_loop(self):
        segment_frames = RATE * SEGMENT_SECONDS
        overlap_frames = RATE * OVERLAP_OFFSET
        while self._recording:
            try:
                data = self._stream.read(CHUNK_FRAMES, exception_on_overflow=False)
            except Exception:
                break
            self._primary_buffer.append(data)
            self._primary_frame_count += CHUNK_FRAMES
            self._secondary_buffer.append(data)
            self._secondary_frame_count += CHUNK_FRAMES
            self._archive_frames.append(data)

            if self._primary_frame_count >= segment_frames:
                self._flush_segment(self._primary_buffer, "primary")
                self._primary_buffer = []
                self._primary_frame_count = 0

            if self._secondary_frame_count >= segment_frames + overlap_frames:
                self._flush_segment(self._secondary_buffer, "secondary")
                self._secondary_buffer = []
                self._secondary_frame_count = 0

    def _flush_segment(self, frames, stream_type):
        self._chunk_counter += 1
        path = self._save_mp3(frames, stream_type)
        if path and self.on_segment:
            self.on_segment(path, self._chunk_counter, stream_type)

    def _save_mp3(self, frames, label) -> Optional[str]:
        try:
            raw = b"".join(frames)
            audio = AudioSegment(data=raw, sample_width=2, frame_rate=RATE, channels=CHANNELS)
            ts = int(time.time())
            filename = f"{self.case_id}_{self.call_id}_{self._chunk_counter}_{ts}_{label}.mp3"
            filepath = os.path.join(self.output_dir, filename)
            audio.export(filepath, format="mp3")
            return filepath
        except Exception as e:
            logger.error(f"Failed to save MP3: {e}")
            return None
