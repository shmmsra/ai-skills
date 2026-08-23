---
name: vocal-ai
description: Use this skill whenever the user needs speech generated from text — narration or voiceover for a demo recording/screencast, reading a script aloud, producing a WAV clip from a line of text, or any "text to speech", "TTS", "voiceover", "narrate this", or "generate audio from this text" request. Wraps the `vocalai` CLI (local, offline Chatterbox TTS over ONNX — no cloud call, no bundled Python/PyTorch). Also covers first-time setup (downloading the `vocalai` binary and its ONNX models) and keeping them up to date — trigger on "set up vocal-ai", "install vocalai", or "update the TTS models" too.
---

# vocal-ai

Generates speech audio (WAV) from text using the [`vocal-ai`](https://github.com/shmmsra/vocal-ai) CLI — a self-contained Rust binary running the Chatterbox TTS model locally via ONNX Runtime. No network call at generation time, no Python/PyTorch runtime required.

## Before first use — check it's installed

The skill needs the `vocalai` binary and its model files present locally. Default install location is `$VOCALAI_INSTALL_DIR` if set, otherwise `~/.vocal-ai`.

```bash
VOCALAI_INSTALL_DIR="${VOCALAI_INSTALL_DIR:-$HOME/.vocal-ai}"
test -x "$VOCALAI_INSTALL_DIR/vocalai" && echo present || echo missing
```

If `missing`, follow `reference/setup.md` to install before generating anything. Do this once per machine, not once per project.

## Generating speech

```bash
"$VOCALAI_INSTALL_DIR/vocalai" \
  --text "The text to speak" \
  --out out.wav \
  --models-dir "$VOCALAI_INSTALL_DIR/models"
```

### Common flags

| Flag | Purpose | Default |
|---|---|---|
| `--text <STRING>` | Text to synthesize (required) | — |
| `--out <PATH>` | Output WAV path | `out.wav` |
| `--models-dir <PATH>` | Where the ONNX models live | `models` |
| `--voice <PATH>` | Reference WAV for zero-shot voice cloning; omit for the built-in default voice | built-in voice |
| `--use-gpu` / `--use-cpu` | Execution provider (CoreML on macOS, CUDA on Linux) | CPU |
| `--show-progress` | Print progress while generating | off |

Less common tuning flags (leave at defaults unless the user asks): `--exaggeration`, `--cfg-weight`, `--temperature`, `--repetition-penalty`, `--min-p`, `--top-p`, `--max-new-tokens`.

### Text length

Quality degrades past ~600 characters per `--text` call. For longer scripts, split into multiple calls at sentence/paragraph boundaries, generate separate WAV files, and concatenate them.

### Examples

Narration for a demo recording, default voice:
```bash
"$VOCALAI_INSTALL_DIR/vocalai" --text "Let's walk through the dashboard." \
  --out narration-01.wav --models-dir "$VOCALAI_INSTALL_DIR/models"
```

Cloning a specific voice from a reference clip:
```bash
"$VOCALAI_INSTALL_DIR/vocalai" --text "Welcome back." --voice ref.wav \
  --out cloned.wav --models-dir "$VOCALAI_INSTALL_DIR/models"
```

## Notes

- Output is 24kHz mono WAV, watermarked (PerthNet) transparently — this is inherent to the model, not a flag.
- English only; there's no `--language` flag.
- No config file — every choice is a CLI flag; there's nothing to look up beyond `--models-dir` and `--voice`.
- If generation fails outright (missing model files, ONNX runtime errors) or the user asks for the latest voice/quality improvements, re-run the setup steps in `reference/setup.md` — it's safe to run any time and no-ops when already current.
