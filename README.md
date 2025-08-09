# Samsung Splash Screen Creator (macOS Fixed Version)

This is a modified version of the original `samsung-splash-creator` script, specifically patched to work on modern macOS systems.

## Key Modifications

The following changes were made to ensure compatibility and smooth operation on macOS:

1.  **Replaced `sha256sum` with `shasum`**: macOS uses `shasum -a 256` for SHA256 checksums. The script was updated accordingly.
2.  **Fixed File Permissions**: Added `chmod u+w *` after file extraction (`tar`) because the original firmware files are often read-only, which caused `mogrify` to fail with "Permission denied" errors.
3.  **Dependency Checks**: The script now checks for `shasum` instead of `sha256sum`.

## Original Author & Credit

This script was originally created by **programminghoch10**. All credit for the core logic and original work goes to them.

- **Original Gist Link**: [https://gist.github.com/programminghoch10/dead88ad0fe720187fdcba598520eabb](https://gist.github.com/programminghoch10/dead88ad0fe720187fdcba598520eabb)

## Usage on macOS

1.  **Install Dependencies via Homebrew**:
    ```bash
    brew install imagemagick
    brew install --cask heimdall-suite
    ```
2.  **Download the script** from this repository.
3.  **Make it executable**:
    ```bash
    chmod +x samsung_splash_fixed.sh
    ```
4.  Follow the original script's usage instructions (e.g., `./samsung_splash_fixed.sh processMeta up_param.bin`).
