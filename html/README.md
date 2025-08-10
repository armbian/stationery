# Armbian Media Kit Generator

This project provides a Bash tool for generating and serving a media kit of Armbian SVG logos and icons.

## Features

- **Generate PNG icons** from SVG files at multiple resolutions.
- **Create an HTML index** (media kit) of all logos and icons, grouped for convenient browsing/downloading.
- **Serve the kit** with a built-in Python HTTP server for easy sharing or review.

## Usage

All commands are run via:
```bash
./html_server.sh <command> [options]
```

### Commands

- `help`  
  Show usage and help message.

- `icon`  
  Generate PNG icon sets from SVGs in `./images/scalable/` at common sizes (16, 32, 64, 128, 256, 512).

- `index`  
  Generate an HTML media kit (`index.html`) listing all SVGs and downloadable PNGs, grouped by filename pattern.

- `index serve`  
  Generate the HTML media kit and immediately serve it at [http://localhost:8080/](http://localhost:8080/).

- `server [directory]`  
  Serve the specified directory (default: current directory) over HTTP.

### File Organization

- Place all SVGs in `./images/scalable/`.
- PNGs are generated in `./icons/<size>x<size>/`.
- The HTML media kit (`index.html`) is generated at the project root.

### Media Kit Grouping Logic

- Logos starting with `arm` are displayed on the left.
- Logos starting with `conf` are displayed on the right.
- All other images appear in a separate section at the bottom.

## Requirements

- [ImageMagick](https://imagemagick.org/) (`convert` command) for icon generation.
- Python 3 for the HTTP server.

You will be prompted to install missing dependencies if needed.

## Example

```bash
./html_server.sh icon
./html_server.sh index
./html_server.sh server
```

## License

Open source, see [LICENSE](LICENSE).