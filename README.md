# Armbian Media Kit Generator

This project provides a Bash tool for generating, indexing, and serving a media kit of Armbian SVG logos and icons.

## Features

- **Generate PNG icons** from SVG files at multiple resolutions.
- **Create an HTML index** (media kit) of all logos and icons, grouped for convenient browsing and downloading.
- **Serve the kit** with a built-in Python HTTP server for easy sharing or review.
- **Generate a multi-resolution favicon.ico** from your main SVG logo.

## Usage

Run all commands via:
```bash
./armbian-media_kit.sh <command> [options]
```

### Commands

- `help`  
  Show usage and help message.

- `icon`  
  Generate PNG icon sets from SVGs in `./SVG/` at common sizes (16, 32, 64, 128, 256, 512), and copy SVGs to `./images/scalable/`. Also generates a multi-resolution `favicon.ico` from `images/scalable/armbian-tux_v1.5.svg`.

- `index`  
  Generate an HTML media kit (`index.html`) listing all SVGs and downloadable PNGs, grouped by filename pattern.

- `server [directory]`  
  Serve the specified directory (default: current directory) over HTTP at [http://localhost:8080/](http://localhost:8080/).

- `all`  
  Run icon generation, HTML index generation, and start the server in sequence.

### File Organization

- **Input SVGs:** Place all SVGs in `./SVG/`.
- **PNGs:** Generated in `./images/<size>x<size>/`.
- **SVGs (for HTML):** After running `icon`, SVGs are copied to `./images/scalable/`.
- **HTML index:** `index.html` is generated at the project root.
- **Favicon:** `favicon.ico` is generated at the project root from `images/scalable/armbian-tux_v1.5.svg`.

### Media Kit Grouping Logic

- Logos starting with `arm` are displayed on the left.
- Logos starting with `conf` are displayed on the right.
- All other images appear in a separate section at the bottom.

### Favicon Generation

- Automatically generates a multi-resolution `favicon.ico` from `images/scalable/armbian-tux_v1.5.svg` (with 16x16, 32x32, and 48x48 sizes) for full browser and OS compatibility.

## Requirements

- [ImageMagick](https://imagemagick.org/) (`convert` command) for icon and favicon generation.
- Python 3 for the HTTP server.

You will be prompted to install missing dependencies if needed.

## Example

```bash
./armbian-media_kit.sh icon
./armbian-media_kit.sh index
./armbian-media_kit.sh server
./armbian-media_kit.sh all
```

## License

Open source, see [LICENSE](LICENSE).