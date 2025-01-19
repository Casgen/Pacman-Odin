
echo "Compiling game library gfx..."
odin build ./src/game --build-mode:shared -out:build/game --debug

echo "Creating an executable..."
odin build ./src/ -out:build/grappler --debug
