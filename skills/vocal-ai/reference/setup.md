# vocal-ai — setup & update

`vocal-ai`'s own installer (`scripts/install.sh` / `install.ps1` in the [vocal-ai](https://github.com/shmmsra/vocal-ai) repo) already handles both first-time install and updates idempotently — it writes `.vocalai_version` next to the binary and `MODELS_VERSION` next to the models, and skips re-downloading anything that's already current. This skill just calls that script directly rather than reimplementing it.

## Install location

Set `VOCALAI_INSTALL_DIR` before running the installer so the binary + models land somewhere stable and shared across projects, instead of a per-project `./vocalai` directory:

```bash
export VOCALAI_INSTALL_DIR="$HOME/.vocal-ai"
```

If the user already has `VOCALAI_INSTALL_DIR` set in their environment, respect it instead of overriding it.

## Install / update — macOS / Linux

```bash
export VOCALAI_INSTALL_DIR="${VOCALAI_INSTALL_DIR:-$HOME/.vocal-ai}"
curl -fsSL https://raw.githubusercontent.com/shmmsra/vocal-ai/main/scripts/install.sh | bash
```

Downloads the prebuilt release binary (`vocalai-macos` with CoreML, or `vocalai-linux-cpu`) into `$VOCALAI_INSTALL_DIR`, and the Chatterbox ONNX model files from the `shmmsra/vocal-ai-models` Hugging Face repo into `$VOCALAI_INSTALL_DIR/models/` (no HF token required — it's a public repo).

## Install / update — Windows (PowerShell)

```powershell
$env:VOCALAI_INSTALL_DIR = "$HOME\.vocal-ai"
irm https://raw.githubusercontent.com/shmmsra/vocal-ai/main/scripts/install.ps1 | iex
```

## Updating later

Re-run the exact same command. The script compares the installed `.vocalai_version` against the latest GitHub release tag, and the installed `MODELS_VERSION` against the one published on Hugging Face — if both already match, it skips the download entirely. There's no separate `--update` flag; rerunning *is* the update.

## Verifying the install

```bash
"$VOCALAI_INSTALL_DIR/vocalai" --text "test" --out /tmp/vocalai-check.wav \
  --models-dir "$VOCALAI_INSTALL_DIR/models"
test -s /tmp/vocalai-check.wav && echo ok
```

A non-empty WAV file confirms both the binary and models are working end to end.

## Troubleshooting

- **GPU acceleration**: opt-in via `--use-gpu` at generation time (CoreML on macOS, CUDA on Linux). Default is CPU — no extra setup needed for the common case.
- **No ffmpeg or Python needed at runtime** — the release binary is fully self-contained. Python is only used upstream (in the vocal-ai repo itself) to export the model to ONNX; end users never need it.
- **Windows CUDA / Linux GPU release assets** are not yet published (deferred upstream); CPU execution works everywhere the installer supports.
