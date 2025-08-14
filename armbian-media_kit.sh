#!/usr/bin/env bash
set -euo pipefail

# ./armbian-media_kit.sh - Armbian Config V2 module

media_kit() {
	case "${1:-}" in
		help|-h|--help)
			_about_html_server
			;;
		index)
			_html_page > index.html

			;;
		icon)
			_icon_set_from_svg
			;;
		server)
			_html_server_main "${2:-.}"
			;;
		all)
			_icon_set_from_svg

			_html_server_index_json
			_html_page > index.html
			_html_server_main "${2:-.}"
			;;
		*)
			_about_html_server
			;;
	esac
}

_html_page() {
	cat <<EOF
<!DOCTYPE html>
<html>
<head>
	<meta charset='UTF-8'>
	<title>Armbian Logos</title>
	<style>
		body { font-family: sans-serif; }
		img { margin: 0.5em; }
	</style>
</head>
<body>
	<h1>Armbian Logos and Icons</h1>
	<div id="logos"></div>
	<script>
		fetch('logos.json')
			.then(response => response.json())
			.then(data => {
				const container = document.getElementById('logos');
				data.forEach(logo => {
					const div = document.createElement('div');
					div.innerHTML = \`
						<hr>
						<img src="\${logo.svg}" alt="\${logo.name}" width="64" height="64">
						<p>Download PNG:</p>
						<ul>
							\${logo.pngs.map(p => \`<li><a href="\${p}">\${p.split('/').pop()}</a></li>\`).join('')}
						</ul>
					\`;
					container.appendChild(div);
				});
			});
	</script>
	<p>All logos are licensed under the <a href="https://creativecommons.org/licenses/by-sa/4.0/">CC BY-SA 4.0</a> license.</p>
	<p>For more information, please refer to the <a href="https://www.armbian.com/brand/">Armbian Brand Guidelines</a>.</p>
</body>
</html>
EOF
}

_html_server_index_json() {
	# Directory containing SVGs
	SVG_DIR="./images/scalable"
	# Output JSON file
	OUTPUT="logos.json"

	echo "[" > "$OUTPUT"
	first=1
	local SIZES=(16 32 64 128 256 512)
	for file in "$SVG_DIR"/*.svg; do
		[[ -e "$file" ]] || continue
		name=$(basename "$file" .svg)
		[[ $first -eq 0 ]] && echo "," >> "$OUTPUT"
		first=0
		echo "  {" >> "$OUTPUT"
		echo "    \"name\": \"$name\"," >> "$OUTPUT"
		echo "    \"svg\": \"$file\"," >> "$OUTPUT"
		echo "    \"pngs\": [" >> "$OUTPUT"
		for i in "${!SIZES[@]}"; do
			sz="${SIZES[$i]}"
			echo -n "      \"share/icons/hicolor/${sz}x${sz}/${name}.png\"" >> "$OUTPUT"
			[[ $i -lt $((${#SIZES[@]}-1)) ]] && echo "," >> "$OUTPUT"
		done
		echo "" >> "$OUTPUT"
		echo "    ]" >> "$OUTPUT"
		echo -n "  }" >> "$OUTPUT"
	done
	echo "" >> "$OUTPUT"
	echo "]" >> "$OUTPUT"
	echo "JSON file created: $OUTPUT"
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

_icon_set_from_svg() {
	SRC_DIR="./brand_src"
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
	FAVICON_SVG="./brand_src/armbian_discord_v2.1.svg"
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