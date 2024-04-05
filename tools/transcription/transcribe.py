from faster_whisper import WhisperModel
import sys

# file path is first arg
file_path = sys.argv[1]
# assert ends with mp3
assert file_path.endswith(".mp3")
print("Transcribing file: ", file_path)

# model_size = "large-v3"
model_size = "distil-large-v3"


def info(*args):
    for arg in args:
        sys.stderr.write(f"{arg} ")
    sys.stderr.write("\n")


# Run on GPU with FP16
info("Loading model...")
model = WhisperModel(model_size, device="cuda", compute_type="float16")

info("Transcribing...")
segments, info_result = model.transcribe(file_path, beam_size=5, language="en", condition_on_previous_text=False)

from tqdm import tqdm
for segment in tqdm(segments):
    info("Segment!")
    print("[%.2fs -> %.2fs] %s" % (segment.start, segment.end, segment.text))