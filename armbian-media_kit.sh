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
			_html_server "${2:-.}"
			;;
		all)
			_icon_set_from_svg

			_html_server_index_json
			_html_page > index.html
			_html_server "${2:-.}"
			;;
		*)
			_about_html_server
			;;
	esac
}
_html_page() {
	cat <<'EOF'
<!DOCTYPE html>
<html>
<head>
	<meta charset='UTF-8'>
	<title>Armbian Logos</title>
	<style>
		body {
			font-family: sans-serif;
			margin: 0;
			padding: 0;
			background: #f8f8f8;
		}
		header, footer {
			background: #333;
			color: #fff;
			padding: 1em;
			text-align: center;
		}
		main {
			padding: 1em;
			display: grid;
			grid-template-columns: 1fr 1fr;
			grid-template-rows: auto auto;
			gap: 1em;
		}
		@media (max-width: 768px) {
			main {
				grid-template-columns: 1fr;
				grid-template-rows: auto;
			}
		}
		.section {
			padding: 1em;
			background: #f0f0f0;
			border-radius: 6px;
		}
		.section h2 {
			margin-top: 0;
		}
		img {
			margin: 0.5em;
			vertical-align: middle;
		}
		.legacy {
			opacity: 0.85; /* Slightly dim legacy sections */
		}
		ul {
			list-style-type: none;
			padding-left: 0;
		}
		ul li {
			margin: 0.2em 0;
		}
	</style>
</head>
<body>
	<header>
		<h1>Armbian Logos and Icons</h1>
	</header>

	<main>
		<div id="armbian-section" class="section">
			<h2>Armbian</h2>
			<div id="armbian-logos"></div>
		</div>
		<div id="configng-section" class="section">
			<h2>ConfigNG</h2>
			<div id="configng-logos"></div>
		</div>
		<div id="armbian-legacy-section" class="section legacy">
			<h2>Armbian Legacy</h2>
			<div id="armbian-legacy-logos"></div>
		</div>
		<div id="configng-legacy-section" class="section legacy">
			<h2>ConfigNG Legacy</h2>
			<div id="configng-legacy-logos"></div>
		</div>
	</main>

	<footer>
		<p>For more information, see 
			<a href="https://www.armbian.com/brand/" style="color: #fff;">Armbian Brand Guidelines</a>.
		</p>
	</footer>

	<script>
		fetch('logos.json')
			.then(response => response.json())
			.then(data => {
				data.forEach(logo => {
					let sectionId;
					switch (logo.category) {
						case 'armbian': sectionId = 'armbian-logos'; break;
						case 'armbian-legacy': sectionId = 'armbian-legacy-logos'; break;
						case 'configng': sectionId = 'configng-logos'; break;
						case 'configng-legacy': sectionId = 'configng-legacy-logos'; break;
						default: return;
					}
					const container = document.getElementById(sectionId);
					if (!container) return;

					// Adapt for PNG object format
					const pngList = logo.pngs.map(p => {
						if (typeof p === 'string') {
							return `<li><a href="${p}">${p.split('/').pop()}</a></li>`;
						} else {
							return `<li><a href="${p.path}">${p.size}</a> – ${p.kb} KB</li>`;
						}
					}).join('');

					const div = document.createElement('div');
					div.innerHTML = `
						<hr>
						<img src="${logo.svg}" alt="${logo.name}" width="64" height="64">
						<p>Download PNG:</p>
						<ul>${pngList}</ul>
					`;
					container.appendChild(div);
				});
			});
	</script>
</body>
</html>
EOF
}

_html_page_v0.1() {
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
	
	<p>For more information, please refer to the <a href="https://www.armbian.com/brand/">Armbian Brand Guidelines</a>.</p>
</body>
</html>
EOF
}

_html_server_index_json() {
    SVG_DIR="./brand_src"
    OUTPUT="logos.json"
    SIZES=(16 32 512)

    mapfile -t svg_files < <(find "$SVG_DIR" -type f -name "*.svg" | sort -u)

    echo "[" > "$OUTPUT"
    first=1

    for file in "${svg_files[@]}"; do
        [[ -e "$file" ]] || continue
        name=$(basename "$file" .svg)

        # Determine category
        case "$file" in
            *"/legacy/"*)
                if [[ "$name" == armbian_* ]]; then category="armbian-legacy"
                elif [[ "$name" == configng_* ]]; then category="configng-legacy"
                else category="other-legacy"; fi
                ;;
            *)
                if [[ "$name" == armbian_* ]]; then category="armbian"
                elif [[ "$name" == configng_* ]]; then category="configng"
                else category="other"; fi
                ;;
        esac

        # Safely extract SVG metadata
        svg_width=$(grep -oP 'width="[^"]+"' "$file" | head -n1 | cut -d'"' -f2 || echo "")
        svg_height=$(grep -oP 'height="[^"]+"' "$file" | head -n1 | cut -d'"' -f2 || echo "")
        svg_viewbox=$(grep -oP 'viewBox="[^"]+"' "$file" | head -n1 | cut -d'"' -f2 || echo "")
        svg_title=$(grep -oP '<title>(.*?)</title>' "$file" | head -n1 || echo "")
        svg_desc=$(grep -oP '<desc>(.*?)</desc>' "$file" | head -n1 || echo "")

        [[ $first -eq 0 ]] && echo "," >> "$OUTPUT"
        first=0
        echo "  {" >> "$OUTPUT"
        echo "    \"name\": \"$name\"," >> "$OUTPUT"
        echo "    \"category\": \"$category\"," >> "$OUTPUT"
        echo "    \"svg\": \"$file\"," >> "$OUTPUT"
        echo "    \"svg_meta\": {" >> "$OUTPUT"
        echo "      \"width\": \"$svg_width\"," >> "$OUTPUT"
        echo "      \"height\": \"$svg_height\"," >> "$OUTPUT"
        echo "      \"viewBox\": \"$svg_viewbox\"," >> "$OUTPUT"
        echo "      \"title\": \"$svg_title\"," >> "$OUTPUT"
        echo "      \"desc\": \"$svg_desc\"" >> "$OUTPUT"
        echo "    }," >> "$OUTPUT"
        echo "    \"pngs\": [" >> "$OUTPUT"

        for i in "${!SIZES[@]}"; do
            sz="${SIZES[$i]}"
            png_path="images/${sz}x${sz}/${name}.png"
            if [[ -f "$png_path" ]]; then
                kb=$(du -k "$png_path" 2>/dev/null | cut -f1 || echo 0)
            else
                kb=0
            fi
            kb_decimal=$(printf "%.2f" "$kb")
            echo -n "      { \"path\": \"$png_path\", \"size\": \"${sz}x${sz}\", \"kb\": ${kb_decimal} }" >> "$OUTPUT"
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


_html_server() {
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
    SIZES=(16 48 512)

    # Name of the base SVG (without extension) to use for favicon
    FAVICON_BASE="configng-mascot_v2.0"  # change this to whatever your main icon is

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

    cp -r "$SRC_DIR" "images/scalable"

    # Generate multi-resolution favicon.ico from chosen SVG
    FAVICON_SVG="$SRC_DIR/${FAVICON_BASE}.svg"
    if [[ -f "$FAVICON_SVG" ]]; then
        echo "Creating favicon.ico from $FAVICON_SVG"
        convert -background none "$FAVICON_SVG" -resize 16x16 favicon-16.png
        convert -background none "$FAVICON_SVG" -resize 32x32 favicon-32.png
        convert -background none "$FAVICON_SVG" -resize 48x48 favicon-48.png
        convert favicon-16.png favicon-32.png favicon-48.png favicon.ico
        rm favicon-16.png favicon-32.png favicon-48.png
        echo "Multi-resolution favicon.ico created."
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