from faster_whisper import WhisperModel
import sys

# file path is first arg
file_path = sys.argv[1]
# assert ends with mp3
assert file_path.endswith(".mp3")
print("Transcribing file: ", file_path)

model_size = "large-v3"

# Run on GPU with FP16
model = WhisperModel(model_size, device="cuda", compute_type="float16")

segments, info = model.transcribe("audio.mp3", beam_size=5)

print("Detected language '%s' with probability %f" % (info.language, info.language_probability))

for segment in segments:
    print("[%.2fs -> %.2fs] %s" % (segment.start, segment.end, segment.text))