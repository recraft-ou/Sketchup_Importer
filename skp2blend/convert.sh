#!/usr/bin/env bash
# Convert a .skp file to .blend using the skp2blend Docker image.
#
# Usage: ./convert.sh <input.skp> [output.blend]
#
# If output is omitted, the .blend file is written next to the input
# with the same base name.

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <input.skp> [output.blend] [--also-obj] [--obj-only]" >&2
    exit 1
fi

INPUT="$(realpath "$1")"
INPUT_DIR="$(dirname "$INPUT")"
INPUT_NAME="$(basename "$INPUT")"

if [ ! -f "$INPUT" ]; then
    echo "Error: file not found: $INPUT" >&2
    exit 1
fi

# Parse positional and flag arguments
OUTPUT=""
EXTRA_FLAGS=()
shift
while [ $# -gt 0 ]; do
    case "$1" in
        --also-obj|--obj-only)
            EXTRA_FLAGS+=("$1")
            ;;
        *)
            OUTPUT="$1"
            ;;
    esac
    shift
done

if [ -z "$OUTPUT" ]; then
    OUTPUT="${INPUT_DIR}/${INPUT_NAME%.skp}.blend"
else
    OUTPUT="$(realpath -m "$OUTPUT")"
fi
OUTPUT_DIR="$(dirname "$OUTPUT")"
OUTPUT_NAME="$(basename "$OUTPUT")"

# If input and output are in the same directory we only need one mount
if [ "$INPUT_DIR" = "$OUTPUT_DIR" ]; then
    docker run --rm \
        -v "${INPUT_DIR}:/data" \
        skp2blend \
        "/data/${INPUT_NAME}" "/data/${OUTPUT_NAME}" "${EXTRA_FLAGS[@]+${EXTRA_FLAGS[@]}}"
else
    docker run --rm \
        -v "${INPUT_DIR}:/input:ro" \
        -v "${OUTPUT_DIR}:/output" \
        skp2blend \
        "/input/${INPUT_NAME}" "/output/${OUTPUT_NAME}" "${EXTRA_FLAGS[@]+${EXTRA_FLAGS[@]}}"
fi

echo "Output: ${OUTPUT}"
