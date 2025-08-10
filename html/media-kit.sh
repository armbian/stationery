#!/usr/bin/env bash
set -euo pipefail

# ./html_server.sh - Armbian Config V2 module

html_server() {
	case "${1:-}" in
		help|-h|--help)
			_about_html_server
			;;
		index)
			# Generate an HTML index of SVG files
			_html_server_index
			;;
		icon)
			# Generate a set of icons from SVG files
			_icon_set_from_svg
			;;
		server)
			# Start a simple HTTP server using Python
			_html_server_main "${2:-.}"
			;;
		"")
			_icon_set_from_svg
			_html_server_index
			;;
		*)
			_about_html_server
			;;
	esac
}

_html_server_main() {
	# Use a default directory
	local DIR="${1:-.}"
	# Run Python web server for HTTP (CGI dropped for now)
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
	# Directory containing SVGs
	SVG_DIR="./images/scalable"
	# Output HTML file
	OUTPUT="./index.html"

	# Arrays to hold categories
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

	# Flex row for left (arm), right (conf)
	echo "<div class=\"flex-row\">"
	# Left: arm*
	echo "<div class=\"flex-col media-group\" style=\"flex:1\"><h3 class=\"center\">Armbian Logos</h3>"
	for file in "${arm_images[@]}"; do
		name=$(basename "$file" .svg)
		echo "<a href=\"$file\">"
		echo "  <img src=\"$file\" alt=\"$name.svg\" width=\"64\" height=\"64\">"
		echo "</a>"
		echo "<p>Download PNG:</p><ul>"
		for sz in 16 32 64 128 256 512; do
			echo "<li><a href=\"images/${sz}x${sz}/${name}.png\">${sz}x${sz} ${name}.png</a></li>"
		done
		echo "</ul><hr>"
	done
	echo "</div>"

	# Right: conf*
	echo "<div class=\"flex-col media-group\" style=\"flex:1\"><h3 class=\"center\">Config Logos</h3>"
	for file in "${conf_images[@]}"; do
		name=$(basename "$file" .svg)
		echo "<a href=\"$file\">"
		echo "  <img src=\"$file\" alt=\"$name.svg\" width=\"64\" height=\"64\">"
		echo "</a>"
		echo "<p>Download PNG:</p><ul>"
		for sz in 16 32 64 128 256 512; do
			echo "<li><a href=\"images/${sz}x${sz}/${name}.png\">${sz}x${sz} ${name}.png</a></li>"
		done
		echo "</ul><hr>"
	done
	echo "</div>"
	echo "</div>"

	# Bottom: rest
	if (( ${#other_images[@]} )); then
		echo "<div class=\"media-group\"><h3 class=\"center\">Other Logos & Icons</h3><div class=\"flex-row\" style=\"flex-wrap:wrap;justify-content:center;gap:2em;\">"
		for file in "${other_images[@]}"; do
			name=$(basename "$file" .svg)
			echo "<div style=\"text-align:center\">"
			echo "<a href=\"$file\">"
			echo "  <img src=\"$file\" alt=\"$name.svg\" width=\"64\" height=\"64\">"
			echo "</a>"
			echo "<p>Download PNG:</p><ul>"
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

# Directory containing SVGs
SRC_DIR="SVG"
# List of desired sizes
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

# Check if source directory exists
if [ ! -d "$SRC_DIR" ]; then
	echo "Error: Source directory '$SRC_DIR' does not exist."
	exit 1
fi

# Check if SVGs exist in the source directory
shopt -s nullglob
svg_files=("$SRC_DIR"/*.svg)
if [ ${#svg_files[@]} -eq 0 ]; then
	echo "Error: No SVG files found in '$SRC_DIR'."
	exit 1
fi
shopt -u nullglob

# Loop over each SVG file in the scalable directory
for svg in "${svg_files[@]}"; do
	# Extract the base filename without extension
	base=$(basename "$svg" .svg)
	# For each size, generate the PNG in the corresponding directory
	for size in "${SIZES[@]}"; do
		OUT_DIR="images/${size}x${size}"
		mkdir -p "$OUT_DIR"
		OUT_FILE="${OUT_DIR}/${base}.png"
		# Only generate if missing or source SVG is newer
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

}


_about_html_server() {
	cat <<EOF
Usage: html_server <command> [options]

Commands:
    help    - Show this help message.
    icon    - Generate a PNG icon set from SVG files in ./images/scalable.
    index   - Generate an HTML media kit index of all SVGs and icons.
    server  - Serve the HTML and icon directory using a simple HTTP server.

Examples:
    # Show help
    html_server help

    # Generate icons from SVGs
    html_server icon

    # Generate the HTML media kit
    html_server index

    # Generate the HTML and start the server
    html_server index serve

    # Start the server (serves current directory by default)
    html_server server [directory]

Notes:
    - All commands accept '--help', '-h', or 'help' for details, if implemented.
    - This tool is intended for use with the Armbian Config V2 menu and for scripting.
    - Please keep this help message up to date if commands or behavior change.
    - SVGs should be placed in ./images/scalable for indexing and icon generation.

EOF
}

### START ./html_server.sh - Armbian Config V2 test entrypoint

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	# --- Capture and assert help output ---
	help_output="$(html_server help)"
	echo "$help_output" | grep -q "Usage: html_server" || {
		echo "fail: Help output does not contain expected usage string"
		echo "test complete"
		exit 1
	}
	# --- end assertion ---
	html_server "$@"
fi

### END ./html_server.sh - Armbian Config V2 test entrypoint