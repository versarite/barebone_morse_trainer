# MorseTest

**MorseTest** is a bare-bones Morse code trainer for practicing reception at a selected speed in words per minute (WPM). It generates groups of characters, plays them as Morse audio, and prints the generated characters to the console for feedback.

## Features

- Configure the sending speed in WPM.
- Select the training character set:
  - Letters (`A–Z`)
  - Numbers (`0–9`)
  - Mixed letters and numbers
  - Mixed characters with punctuation
  - Mixed characters with punctuation and German umlauts (`Ä`, `Ö`, `Ü`), depending on the selected source version
- Choose a fixed-length session or continuous practice, where supported by the version you build.
- Load console text from an external `locale.txt` file.
- Keep English strings hard-coded as fallbacks if the locale file or an individual key is missing.
- UTF-8 source and locale text for characters such as German umlauts.

## Design and portability

MorseTest is written in Object Pascal for Free Pascal and Lazarus. The source uses conditional compilation so it can be built for both Linux and Windows from the same codebase. On Linux, the program includes the `cthreads` unit and uses the system OpenAL library. On Windows, the program calls OpenAL through the `openal` Pascal unit and expects the OpenAL DLL name `openal32.dll`.

OpenAL Soft distributions may provide the Windows library as `soft_oal.dll`. If so, copy the matching architecture build and rename the copy to **`openal32.dll`** in the same directory as `morsetest.exe` (or in a directory searched by Windows). The 32-bit DLL must be used with a 32-bit executable; the 64-bit DLL must be used with a 64-bit executable. Do not mix architectures. Keep the original `soft_oal.dll` if other applications need it.

## Requirements

### Windows

- Free Pascal / Lazarus to compile from source.
- OpenAL runtime DLL compatible with the target architecture.
- `locale.txt` beside the executable if you want translated console text; otherwise the built-in English text is used.

### Linux

- Free Pascal Compiler (FPC).
- The FPC multimedia units, which provide the `openal` Pascal unit.
- The OpenAL development/runtime library.
- Lazarus is optional if you prefer to build from the IDE rather than the command line.

On Debian or Ubuntu, install the packages with:

```bash
sudo apt update
sudo apt install fpc fp-units-multimedia libopenal-dev
```

To use the Lazarus IDE as well, install it with:

```bash
sudo apt install lazarus
```

Package names can vary by distribution and repository. On Debian/Ubuntu, `fp-units-multimedia` contains Free Pascal's OpenAL unit, while `libopenal-dev` supplies the OpenAL development library; its runtime dependency is installed with it. If the compiler reports `Can't find unit openal`, check that the multimedia units matching your installed FPC version are installed. The FPC and unit package versions should match.

### Build on Linux

From the project directory, build with FPC:

```bash
fpc morsetest.lpr
```

Or open the project in Lazarus and compile it for Linux. If your project has a Lazarus project file (`.lpi`), open that file in the IDE.

If compilation succeeds but the program reports that it cannot open an audio device, verify that OpenAL is installed and that your system has a working audio output device and audio session.

## Getting started

1. Build the program for your operating system and CPU architecture.
2. On Windows, make sure the matching `openal32.dll` is available to the executable.
3. Optionally place `locale.txt` beside the executable.
4. Run `morsetest` from a terminal/console.
5. Follow the prompts to choose the WPM speed, character set, and session length (as provided by your build).

## Localization

MorseTest can read console strings from `locale.txt`. The file is UTF-8 text with one `key=value` entry per line.

Example:

```ini
prompt_wpm=Enter Speed in WPM (e.g. 45, 55):
menu_mode_title=Select Training Target Type:
prompt_mode=Enter Selection (1-5):
```

Keep the keys on the left side of `=` unchanged when translating. Translate only the values on the right. Preserve format placeholders such as `%d` in any formatted status messages.

The program's English strings remain hard-coded as fallbacks. If `locale.txt` is missing or a key is not found, the fallback text is used. Save the file as UTF-8. On Windows, the console output code page and font also need to support UTF-8 for umlauts to display correctly.

## License

The MorseTest barebone Morse trainer is distributed under the **GNU General Public License, version 3, or (at your option) any later version**.

See [`LICENSE`](https://github.com/versarite/TotalCopy/blob/main/LICENSE) for the complete license text.

## Copyright

Copyright (C) 2026 [DL1BWA/KD1AEV]

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but **WITHOUT ANY WARRANTY**; without even the implied warranty of **MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE**. See the GNU General Public License for more details.

For more information, see the [GNU GPL version 3](https://www.gnu.org/licenses/gpl-3.0.html).
