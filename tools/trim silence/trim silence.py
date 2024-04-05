from pydub import AudioSegment
from pydub.silence import split_on_silence
import sys

# Assume the file path is provided as the first argument
input_file_path = sys.argv[1]
assert input_file_path.endswith(".mp3"), "Input file must be an MP3"
output_file_path = sys.argv[2]
assert output_file_path.endswith(".mp3"), "Output file must be an MP3"

# Load the audio file
print("Loading audio from:", input_file_path)
audio = AudioSegment.from_mp3(input_file_path)

# Split the audio file into non-silent chunks
# You may need to adjust the silence_thresh and min_silence_len parameters based on your audio
print("Splitting audio into non-silent chunks...")
chunks = split_on_silence(
    audio,
    min_silence_len=500,  # Minimum length of silence to consider in milliseconds
    silence_thresh=-40,  # Silence threshold in dB
    keep_silence=200,  # Keep 200 milliseconds of silence at the start and end of each chunk
)

# Combine the chunks back into an AudioSegment
print("Combining non-silent chunks...")
processed_audio = AudioSegment.empty()
from tqdm import tqdm
for chunk in tqdm(chunks):
    print("chunk!")
    processed_audio += chunk

# Export the processed audio to a new file
print("Exporting processed audio to:", output_file_path)
processed_audio.export(output_file_path, format="mp3")

print("Processed file saved as:", output_file_path)
