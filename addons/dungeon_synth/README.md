# Dungeon Synth

Godot 4.7 editor plugin for creating deterministic environment music with Clef and an SF2 SoundFont.

## Workflow

1. Open the **Dungeon Synth** main-screen tab.
2. Select an environment and adjust tempo, length, layer density, and instruments.
3. Choose **Generate Take**, then **Play** to audition through Clef.
4. Choose **Save Song + MIDI** to create `.tres`, `.json`, and `.mid` files.
5. Choose **Export WAV** to render the saved MIDI through FluidSynth at 48 kHz/16-bit stereo.

The `.tres` recipe stores the seed and the exact generated MIDI document, so saved takes remain reproducible even if generator behavior changes later.

## Setup

- Enable both Clef and Dungeon Synth in Project Settings → Plugins.
- Set `clef/default_soundfont` or use the SoundFont field in the panel.
- FluidSynth must resolve from `PATH`, or `dungeon_synth/fluidsynth_path` must point to `fluidsynth.exe`.
- The default generated soundtrack folder is `res://assets/audio/music/generated`.
