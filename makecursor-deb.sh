#!/bin/bash

# make a tmp dir
WORK_DIR=`mktemp -d`

# check if tmp dir was created
if [[ ! -d "$WORK_DIR" ]]; then
  echo 'Failed to make a temporary directory!'
  exit 1
fi

# deletes the temp directory
function cleanup {      
  rm -rf "$WORK_DIR"
  echo "Deleted temp working directory $WORK_DIR"
}

# register the cleanup function to be called on the EXIT signal
trap cleanup EXIT

# Download ARM64 binary from their downloader server where normally on the main site ARM64 is not listed as a available architecture for Linux users
cd "$WORK_DIR"
curl -O -J https://downloader.cursor.sh/linux/appImage/arm64 || echo 'Failed to download ARM64 Cursor AppImage binary!'

# Loop through matching files in the directory
for file in "$WORK_DIR"/cursor-*arm64.AppImage; do
  # Check if the file exists
  if [[ -f "$file" ]]; then
    echo "Processing file: $file"

    # Make the file executable
    chmod +x "$file"
    echo "Made executable: $file"

    # Extract the version from the file name
    if [[ "$file" =~ cursor-([0-9]+\.[0-9]+\.[0-9]+)arm64.AppImage ]]; then
      version="${BASH_REMATCH[1]}"
      echo "Extracted version from file name: $version"
      echo "This version will be used during the Debian package."
    else
      echo "Could not extract version from $file"
      exit 1
    fi
  else
    echo "No matching files found."
    exit 1
  fi
done

echo "Preparing resources to make a Debian package"
git clone https://github.com/matu6968/cursor-ai-pi-apps || echo 'failed to clone github repository'
cd cursor-ai-pi-apps
mkdir cursor-deb
cp -r DEBIAN cursor-deb
cp -r usr cursor-deb 
$file --appimage-extract || echo 'failed to extract files from AppImage'
mkdir cursor-deb/usr/share/cursor 
cd cursor-deb
sed 's/Version: 0.43.5/Version: '$version'' DEBIAN/control
chmod 0755 -R usr/share/cursor/
chmod 0755 -R DEBIAN/
cd ..
cp -r squashfs-root/* cursor-deb/usr/share/cursor
cd cursor-deb
dpkg-deb --build . ../cursor_"$version"_arm64.deb || echo "failed to build package"
cp ../cursor_"$version"_arm64.deb /tmp
echo "package build complete, install package from cursor_"$version"_arm64.deb or copy it to your specifed directory'
