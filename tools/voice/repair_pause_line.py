"""Replace the clipped opening narration line without changing other speech."""

import argparse
import os
import wave

import numpy as np
from piper import PiperVoice, SynthesisConfig


DEFAULT_VOICE_DIR = os.environ.get(
    "EMBRACE_VOICE_DIR", r"D:/VideoProjects/voice"
)
START_SECONDS = 12.5
REPLACE_END_SECONDS = 19.1
DISPLAY_TEXT = "Thank you for taking a few minutes to pause."
# "Paws" is the same phoneme sequence and prevents this Piper model from
# dropping the final consonant when the word ends an utterance.
SPOKEN_TEXT = "Thank you for taking a few minutes to paws."
LENGTH_SCALE = 1.28
TAIL_SILENCE_MS = 240
FADE_IN_MS = 20
FADE_OUT_MS = 6


def read_mono_pcm16(path):
    with wave.open(path, "rb") as source:
        if source.getnchannels() != 1 or source.getsampwidth() != 2:
            raise SystemExit("Narration source must be mono 16-bit PCM WAV")
        rate = source.getframerate()
        audio = np.frombuffer(source.readframes(source.getnframes()), dtype="<i2")
    return rate, audio.astype(np.float32) / 32768.0


def synthesize_line(model_path, rate):
    voice = PiperVoice.load(model_path)
    if voice.config.sample_rate != rate:
        raise SystemExit("Voice model and narration sample rates do not match")

    config = SynthesisConfig(
        length_scale=LENGTH_SCALE,
        noise_scale=0.667,
        noise_w_scale=0.8,
    )
    chunks = [
        chunk.audio_float_array
        for chunk in voice.synthesize(SPOKEN_TEXT, syn_config=config)
    ]
    if not chunks:
        raise SystemExit("Piper returned no audio for the repaired line")

    speech = np.concatenate(chunks).astype(np.float32)
    fade_in = min(len(speech), int(rate * FADE_IN_MS / 1000))
    fade_out = min(len(speech), int(rate * FADE_OUT_MS / 1000))
    speech[:fade_in] *= np.linspace(0.0, 1.0, fade_in, dtype=np.float32)
    speech[-fade_out:] *= np.linspace(1.0, 0.0, fade_out, dtype=np.float32)
    tail = np.zeros(int(rate * TAIL_SILENCE_MS / 1000), dtype=np.float32)
    return np.concatenate([speech, tail])


def write_mono_pcm16(path, rate, audio):
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    with wave.open(path, "wb") as target:
        target.setnchannels(1)
        target.setsampwidth(2)
        target.setframerate(rate)
        target.writeframes(
            (np.clip(audio, -1.0, 1.0) * 32767).astype("<i2").tobytes()
        )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--input", default=os.path.join(DEFAULT_VOICE_DIR, "narration.wav")
    )
    parser.add_argument("--output", required=True)
    parser.add_argument(
        "--model",
        default=os.path.join(
            DEFAULT_VOICE_DIR,
            "piper_models",
            "en_GB-jenny_dioco-medium.onnx",
        ),
    )
    args = parser.parse_args()

    rate, narration = read_mono_pcm16(args.input)
    replacement = synthesize_line(args.model, rate)
    start = round(START_SECONDS * rate)
    replace_end = round(REPLACE_END_SECONDS * rate)
    available = replace_end - start
    if len(replacement) > available:
        raise SystemExit(
            f"Repaired line is {len(replacement) / rate:.2f}s but only "
            f"{available / rate:.2f}s is available"
        )

    repaired = narration.copy()
    repaired[start:replace_end] = 0.0
    original_peak = float(np.max(np.abs(narration)))
    replacement_peak = float(np.max(np.abs(replacement)))
    if replacement_peak > 0:
        replacement *= original_peak / replacement_peak
    repaired[start:start + len(replacement)] = replacement
    write_mono_pcm16(args.output, rate, repaired)

    speech_seconds = (len(replacement) / rate) - (TAIL_SILENCE_MS / 1000)
    print(f"caption : {DISPLAY_TEXT}")
    print(f"spoken  : {SPOKEN_TEXT}")
    print(f"start   : {START_SECONDS:.2f}s")
    print(f"speech  : {speech_seconds:.2f}s")
    print(f"release : {TAIL_SILENCE_MS}ms")
    print(f"output  : {args.output}")


if __name__ == "__main__":
    main()
