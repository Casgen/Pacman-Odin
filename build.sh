
echo "Building gfx..."
odin build ./src/gfx --build-mode:shared -out:build/gfx --debug

echo "Building entities..."
odin build ./src/level --build-mode:shared -out:build/level --debug

echo "Building level..."
odin build ./src/entities --build-mode:shared -out:build/entities --debug

echo "Creating an executable..."
odin build ./src/ -out:build/pacman -collection:shared=build/ --debug
