#!/bin/sh
set -e

repository_root=$(dirname "$(realpath "$0")")
content_service="$repository_root/src/modules/content-management-service"
ui_project="$repository_root/src/modules/ui"
build_directory="$repository_root/build/desktop"
pyinstaller_binary="$repository_root/.venv/bin/pyinstaller"
prompt_files="features/study_units_generation/prompts/prompt_files"
frozen_backend="$build_directory/dist/leffic-backend"
sdk_bundled_claude="$frozen_backend/_internal/claude_agent_sdk/_bundled"
app_bundle="$ui_project/build/macos/Build/Products/Release/leffic.app"
bundled_backend="$app_bundle/Contents/Resources/backend"
bundled_tools="$app_bundle/Contents/Resources/tools"
text_recognizer_source="$ui_project/macos/TextRecognizer/main.swift"

if [ ! -x "$pyinstaller_binary" ]; then
    echo "build: pyinstaller is missing - run ./install.sh" >&2
    exit 1
fi

if [ "$(uname -m)" != "arm64" ]; then
    echo "build: Leffic is built for Apple silicon only" >&2
    exit 1
fi

rm -rf "$build_directory"

env -C "$content_service" "$pyinstaller_binary" run_desktop.py \
    --noconfirm \
    --onedir \
    --name leffic-backend \
    --distpath "$build_directory/dist" \
    --workpath "$build_directory/work" \
    --specpath "$build_directory" \
    --paths "$content_service" \
    --add-data "$content_service/migrations:migrations" \
    --add-data "$content_service/$prompt_files:$prompt_files" \
    --collect-submodules celery \
    --collect-submodules kombu \
    --collect-submodules uvicorn \
    --collect-all claude_agent_sdk

rm -rf "$sdk_bundled_claude"

ssl_module=$("$repository_root/.venv/bin/python" -c \
    "import _ssl; print(_ssl.__file__)")
linked_libssl=$(otool -L "$ssl_module" | awk '/libssl/ {print $1}')
openssl_directory=$(dirname "$linked_libssl")
cp "$openssl_directory/libssl.3.dylib" "$openssl_directory/libcrypto.3.dylib" \
    "$frozen_backend/_internal/"

rm -rf "$app_bundle"
env -C "$ui_project" flutter build macos --release

mkdir -p "$bundled_backend"
cp -R "$frozen_backend" "$bundled_backend/"

mkdir -p "$bundled_tools"
swiftc -O -o "$bundled_tools/leffic-text-recognizer" \
    "$text_recognizer_source"

codesign --force --deep --sign - "$app_bundle"

echo "build: ready - $app_bundle"
