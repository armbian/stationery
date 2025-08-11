#!/usr/bin/env bash
set -euo pipefail

# ./html_server.sh - Armbian Config V2 module

media_kit() {
	case "${1:-}" in
		help|-h|--help)
			_about_html_server
			;;
		index)
			_html_server_index
			;;
		icon)
			_icon_set_from_svg
			;;
		server)
			_html_server_main "${2:-.}"
			;;
		all)
			_icon_set_from_svg
			_html_server_index
			_html_server_main "${2:-.}"
			;;
		*)
			_about_html_server
			;;
	esac
}

_html_server_main() {
	local DIR="${1:-.}"
	if ! command -v python3 &> /dev/null; then
		echo "Python 3 is required to run the server. Please install it."
		exit 1
	fi
	echo "Starting Python web server"
	python3 -m http.server 8080 &

	PYTHON_PID=$!

	echo "Python web server started with PID $PYTHON_PID"
	echo "You can access the server at http://localhost:8080/$DIR"
	echo "Press any key to stop the server..."
	read -r -n 1 -s
	echo "Stopping the server..."
	if ! kill -0 "$PYTHON_PID" 2>/dev/null; then
		echo "Server is not running or already stopped."
		exit 0
	fi
	kill "$PYTHON_PID" && wait "$PYTHON_PID" 2>/dev/null
	if [[ $? -eq 0 ]]; then
		echo "Server stopped successfully."
	else
		echo "Failed to stop the server."
		exit 1
	fi
	echo "Test complete"
}

_html_server_index() {
	SVG_DIR="./images/scalable"
	OUTPUT="./index.html"
	arm_images=()
	conf_images=()
	other_images=()

	shopt -s nullglob
	for file in "$SVG_DIR"/*.svg; do
		[[ -e "$file" ]] || continue
		name=$(basename "$file" .svg)
		if [[ $name == arm* ]]; then
			arm_images+=("$file")
		elif [[ $name == conf* ]]; then
			conf_images+=("$file")
		else
			other_images+=("$file")
		fi
	done
	shopt -u nullglob

	{
	echo "<!DOCTYPE html>"
	echo "<html><head>"
	echo "<meta charset='UTF-8'><title>Armbian Media Kit</title>"
	echo "<link rel=\"icon\" type=\"image/x-icon\" href=\"favicon.ico\">"
	echo "<style>
	body { background: #fff; color: #000; font-family: sans-serif; margin: 0; }
	header { background: #23262f; color: #fff; padding: 0.3rem 1rem; display: flex; align-items: center; min-height: 56px; }
	header .header-logo { display: flex; gap: 1em; padding: 0.1rem }
	header a { display: inline-block; }
	header img { vertical-align: middle; height: 64px; width: auto; }
	footer { background: #23262f; color: #fff; padding: 1rem 2rem; text-align: center; font-size: 0.9em; }
	footer a { color: #3ea6ff; }
	main { padding: 2rem; }
	hr { border: 0; border-bottom: 1px solid #353535; margin: 2em 0; }
	a { color: #3ea6ff; }
	ul { padding-left: 1.2em; }
	.flex-row { display: flex; justify-content: space-between; gap: 3em; }
	.flex-col { display: flex; flex-direction: column; gap: 1.5em; }
	.center { text-align: center; }
	.media-group { margin-bottom: 2em; }
	</style>"
	echo "</head><body>"
	echo "<header>"
	echo "  <span class=\"header-logo\">"
	echo "    <a href=\"https://www.armbian.com/\" target=\"_blank\" rel=\"noopener\">"
	echo "      <img src=\"images/scalable/armbian-tux_v1.5.svg\" alt=\"armbian-tux_v1.5.svg\">"
	echo "    </a>"
	echo "    <a href=\"https://www.armbian.com/\" target=\"_blank\" rel=\"noopener\">"
	echo "      <img src=\"images/scalable/armbian_logo_v2.svg\" alt=\"armbian_logo_v2.svg\">"
	echo "    </a>"
	echo "  </span>"
	echo "</header>"
	echo "<main>"
	echo "<p>We've put together some logos and icons for you to use in your articles and projects.</p>"

	echo "<div class=\"flex-row\">"
	echo "<div class=\"flex-col media-group\" style=\"flex:1\"><h3 class=\"center\">Armbian Logos</h3>"
	for file in "${arm_images[@]}"; do
		name=$(basename "$file" .svg)
		echo "<a href=\"$file\">"
		echo "  <img src=\"$file\" alt=\"$name.svg\" width=\"64\" height=\"64\">"
		echo "</a>"
		echo "<ul>"
		for sz in 16 32 64 128 256 512; do
			echo "<li><a href=\"images/${sz}x${sz}/${name}.png\">${sz}x${sz}</a></li>"
		done
		echo "</ul><hr>"
	done
	echo "</div>"

	echo "<div class=\"flex-col media-group\" style=\"flex:1\"><h3 class=\"center\">Config Logos</h3>"
	for file in "${conf_images[@]}"; do
		name=$(basename "$file" .svg)
		echo "<a href=\"$file\">"
		echo "  <img src=\"$file\" alt=\"$name.svg\" width=\"64\" height=\"64\">"
		echo "</a>"
		echo "<ul>"
		for sz in 16 32 64 128 256 512; do
			echo "<li><a href=\"images/${sz}x${sz}/${name}.png\">${sz}x${sz}</a></li>"
		done
		echo "</ul><hr>"
	done
	echo "</div>"
	echo "</div>"

	if (( ${#other_images[@]} )); then
		echo "<div class=\"media-group\"><h3 class=\"center\">Other Logos & Icons</h3><div class=\"flex-row\" style=\"flex-wrap:wrap;justify-content:center;gap:2em;\">"
		for file in "${other_images[@]}"; do
			name=$(basename "$file" .svg)
			echo "<div style=\"text-align:center\">"
			echo "<a href=\"$file\">"
			echo "  <img src=\"$file\" alt=\"$name.svg\" width=\"64\" height=\"64\">"
			echo "</a>"
			echo "<ul>"
			for sz in 16 32 64 128 256 512; do
				echo "<li><a href=\"images/${sz}x${sz}/${name}.png\">${sz}x${sz} ${name}.png</a></li>"
			done
			echo "</ul>"
			echo "</div>"
		done
		echo "</div></div>"
	fi

	echo "</main>"
	cat <<EOF
	<footer>
		Armbian Config V2 &copy; $(date +%Y) | Powered by open source<br>
	</footer>
EOF
	echo "</body></html>"
	} > "$OUTPUT"

	echo "HTML file created: $OUTPUT"
}

_icon_set_from_svg() {
	SRC_DIR="./SVG"
	SIZES=(16 32 64 128 256 512)
	# Check for ImageMagick's convert command
	if ! command -v convert &> /dev/null; then
		echo "Error: ImageMagick 'convert' command not found."
		read -p "Would you like to install ImageMagick using 'sudo apt install imagemagick'? [Y/n] " yn
		case "$yn" in
			[Yy]* | "" )
			echo "Installing ImageMagick..."
			sudo apt update && sudo apt install imagemagick
			if ! command -v convert &> /dev/null; then
				echo "Installation failed or 'convert' still not found. Exiting."
				exit 1
			fi
			;;
			* )
			echo "Cannot proceed without ImageMagick. Exiting."
			exit 1
			;;
		esac
	fi

	if [ ! -d "$SRC_DIR" ]; then
		echo "Error: Source directory '$SRC_DIR' does not exist."
		exit 1
	fi

	shopt -s nullglob
	svg_files=("$SRC_DIR"/*.svg)
	if [ ${#svg_files[@]} -eq 0 ]; then
		echo "Error: No SVG files found in '$SRC_DIR'."
		exit 1
	fi
	shopt -u nullglob

	for svg in "${svg_files[@]}"; do
		base=$(basename "$svg" .svg)
		for size in "${SIZES[@]}"; do
			OUT_DIR="images/${size}x${size}"
			mkdir -p "$OUT_DIR"
			OUT_FILE="${OUT_DIR}/${base}.png"
			if [[ ! -f "$OUT_FILE" || "$svg" -nt "$OUT_FILE" ]]; then
				convert -background none -resize ${size}x${size} "$svg" "$OUT_FILE"
				if [ $? -eq 0 ]; then
					echo "Generated $OUT_FILE"
				else
					echo "Failed to convert $svg to $OUT_FILE"
				fi
			fi
		done
	done

	cp -r $SRC_DIR "images/scalable"

	# Generate proper multi-resolution favicon.ico from SVG (always overwrites old one)
	FAVICON_SVG="images/scalable/armbian-tux_v1.5.svg"
	if [[ -f "$FAVICON_SVG" ]]; then
		convert "$FAVICON_SVG" -background none -resize 16x16 favicon-16.png
		convert "$FAVICON_SVG" -background none -resize 32x32 favicon-32.png
		convert "$FAVICON_SVG" -background none -resize 48x48 favicon-48.png
		convert favicon-16.png favicon-32.png favicon-48.png favicon.ico
		rm favicon-16.png favicon-32.png favicon-48.png
		echo "Multi-resolution favicon.ico created from $FAVICON_SVG"
	else
		echo "Could not create favicon.ico (SVG not found: $FAVICON_SVG)"
	fi
}

_about_html_server() {
	cat <<EOF
Usage: media_kit <command> [options]

Commands:
    help    - Show this help message.
    icon    - Generate a PNG icon set from SVG files in ./images/scalable.
    index   - Generate an HTML media kit index of all SVGs and icons.
    server  - Serve the HTML and icon directory using a simple HTTP server.
    all     - Run icon generation, HTML index generation and start the server.

Examples:
    # Show help
    media_kit help

    # Generate icons from SVGs
    media_kit icon

    # Generate the HTML media kit
    media_kit index

    # Generate the HTML and start the server
    media_kit index serve

    # Start the server (serves current directory by default)
    media_kit server [directory]

Notes:
    - All commands accept '--help', '-h', or 'help' for details, if implemented.
    - This tool is intended for use with the Armbian Config V2 menu and for scripting.
    - Please keep this help message up to date if commands or behavior change.
    - SVGs should be placed in ./images/scalable for indexing and icon generation.

EOF
}

### START ./html_server.sh - Armbian Config V2 test entrypoint

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	help_output="$(media_kit help)"
	echo "$help_output" | grep -q "Usage: media_kit" || {
		echo "fail: Help output does not contain expected usage string"
		echo "test complete"
		exit 1
	}
	media_kit "$@"
fi
### END ./html_server.sh - Armbian Config V2 test entrypoint