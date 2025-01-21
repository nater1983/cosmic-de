#!/bin/bash

# Array of project names and corresponding GitHub repository names
declare -A repos=(
  ["cosmic-applets"]="cosmic-applets"
  ["cosmic-applibrary"]="cosmic-applibrary"
  ["cosmic-bg"]="cosmic-bg"
  ["cosmic-comp"]="cosmic-comp"
  ["cosmic-files"]="cosmic-files"
  ["cosmic-icons"]="cosmic-icons"
  ["cosmic-launcher"]="cosmic-launcher"
  ["cosmic-notifications"]="cosmic-notifications"
  ["cosmic-osd"]="cosmic-osd"
  ["cosmic-panel"]="cosmic-panel"
  ["cosmic-player"]="cosmic-player"
  ["cosmic-randr"]="cosmic-randr"
  ["cosmic-reader"]="cosmic-reader"
  ["cosmic-screenshot"]="cosmic-screenshot"
  ["cosmic-session"]="cosmic-session"
  ["cosmic-settings-daemon"]="cosmic-settings-daemon"
  ["cosmic-settings"]="cosmic-settings"
  ["cosmic-term"]="cosmic-term"
  ["cosmic-store"]="cosmic-store"
  ["cosmic-idle"]="cosmic-idle"
  ["cosmic-workspaces-epoch"]="cosmic-workspaces-epoch"
  ["launcher"]="launcher" 
  ["pop-gtk-theme"]="gtk-theme" 
  ["pop-icon-theme"]="icon-theme"  # Directory name differs from repository name
  ["system76-fonts"]="fonts"
  ["system76-power"]="system76-power"
  ["xdg-desktop-portal-cosmic"]="xdg-desktop-portal-cosmic"
)

# Exit script on any error
set -e

# Root source directory (where this script is located)
ROOT_DIR="$(pwd)"

# Base GitHub URL
GITHUB_BASE_URL="https://github.com/pop-os"

# Loop through each project name
for PRGNAM in "${!repos[@]}"; do
  REPO_NAME=${repos[$PRGNAM]}
  CLONE_URL="$GITHUB_BASE_URL/$REPO_NAME.git"

  # Create a temporary directory for the git repository
  GITDIR=$(mktemp -dt "$PRGNAM.git.XXXXXX")
  git clone --depth 1 "$CLONE_URL" "$GITDIR" || { echo "Failed to clone $CLONE_URL"; exit 1; }
    
  # Extract the version and commit information
  cd "$GITDIR"
  VERSION=$(git log --date=format:%Y%m%d --pretty=format:%cd.%h -n1)
  _commit=$(git rev-parse HEAD)

  # Create the tarball URL
  TARBALL_URL="$GITHUB_BASE_URL/$REPO_NAME/archive/$_commit/$REPO_NAME-$_commit.tar.gz"

  # Remove .git directory and .gitignore files
  rm -rf .git
  find . -name .gitignore -print0 | xargs -0 rm -f

  # Move back to the root directory
  cd "$ROOT_DIR"

  # Update the SlackBuild script in the project directory
  SLACKBUILD="$ROOT_DIR/$PRGNAM/$PRGNAM.SlackBuild"
  if [ -f "$SLACKBUILD" ]; then
    sed -i "s|^wget -c .*|wget -c $TARBALL_URL|" "$SLACKBUILD"
    sed -i "s/^VERSION=.*/VERSION=${VERSION}/" "$SLACKBUILD"
    sed -i "s/^_commit=.*/_commit=${_commit}/" "$SLACKBUILD"
    echo "Updated $SLACKBUILD with the latest version and commit."
  else
    echo "SlackBuild script not found in $ROOT_DIR/$PRGNAM. Skipping update for $PRGNAM."
  fi

  # Create a tarball
  mv "$GITDIR" "$PRGNAM-$VERSION"
  tar cvfJ "$PRGNAM-$VERSION.tar.xz" "$PRGNAM-$VERSION"
  rm -rf "$PRGNAM-$VERSION"

done  # <-- This was missing, ending the loop

echo "All projects have been processed and archives created."

# Handling the 'just' repository separately
JUST_REPO="https://github.com/casey/just.git"
JUST_REPO_NAME="just"
JUST_DIR=$(mktemp -dt "$JUST_REPO_NAME.git.XXXXXX")
git clone --depth 1 "$JUST_REPO" "$JUST_DIR"

cd "$JUST_DIR"
git fetch --tags
VERSION=$(git describe --tags $(git rev-list --tags --max-count=1))  # Get the latest tag for version
TARBALL_URL="https://github.com/casey/just/archive/$VERSION/just-$VERSION.tar.gz"

# Remove .git directory and .gitignore files
rm -rf .git
find . -name .gitignore -print0 | xargs -0 rm -f

cd "$ROOT_DIR"

# Update the SlackBuild script in the project directory for 'just'
SLACKBUILD="$ROOT_DIR/$JUST_REPO_NAME/$JUST_REPO_NAME.SlackBuild"
if [ -f "$SLACKBUILD" ]; then
  # Update the wget line
  sed -i "s|^wget -c .*|wget -c $TARBALL_URL|" "$SLACKBUILD"

  # Update the VERSION line with no fallback
  sed -i "s|^VERSION=.*|VERSION=$VERSION|" "$SLACKBUILD"

  echo "Updated $SLACKBUILD with the latest version and commit."
else
  echo "SlackBuild script not found in $ROOT_DIR/$JUST_REPO_NAME. Skipping update for $JUST_REPO_NAME."
fi

# Create a tarball
mv "$JUST_DIR" "$JUST_REPO_NAME-$VERSION"
tar cvfJ "$JUST_REPO_NAME-$VERSION.tar.xz" "$JUST_REPO_NAME-$VERSION"
rm -rf "$JUST_REPO_NAME-$VERSION"

echo "The 'just' repository has been processed, archived as $JUST_REPO_NAME-$VERSION.tar.xz, and cleaned up."

# Set up variables
COSMIC_WALLPAPERS_REPO="https://github.com/pop-os/cosmic-wallpapers.git"
COSMIC_WALLPAPERS_NAME="cosmic-wallpapers"
COSMIC_WALLPAPERS_DIR=$(mktemp -dt "$COSMIC_WALLPAPERS_NAME.git.XXXXXX")

# Clone the repository
git clone --depth 1 "$COSMIC_WALLPAPERS_REPO" "$COSMIC_WALLPAPERS_DIR" || { echo "Failed to clone the repository"; exit 1; }

# Navigate into the cloned repository
cd "$COSMIC_WALLPAPERS_DIR" || { echo "Failed to enter the repository directory"; exit 1; }

# Set up git-lfs and fetch LFS objects
git lfs install
git remote add network-origin https://github.com/pop-os/cosmic-wallpapers
git lfs fetch --all  # Fetch all LFS objects
git lfs pull  # Ensure all files are pulled down and available
git lfs checkout  # Check out the actual binary files

# Optional: sleep to ensure files are checked out
sleep 5

# Ensure that all LFS files were properly checked out
git lfs ls-files
git lfs status || { echo "git-lfs encountered an error"; exit 1; }

# Extract the version and commit information
VERSION=$(git log --date=format:%Y%m%d --pretty=format:%cd.%h -n1)
_commit=$(git rev-parse HEAD)

# Remove .git directory and .gitignore files
rm -rf .git
find . -name .gitignore -print0 | xargs -0 rm -f

# Navigate back to the root directory
cd "$ROOT_DIR" || { echo "Failed to return to the root directory"; exit 1; }

# Update the SlackBuild script in the project directory for 'cosmic-wallpapers'
SLACKBUILD="$ROOT_DIR/$COSMIC_WALLPAPERS_NAME/$COSMIC_WALLPAPERS_NAME.SlackBuild"
if [ -f "$SLACKBUILD" ]; then
  # Update the wget line
  sed -i "s|^wget -c .*|wget -c https://reddoglinux.ddns.net/distfile/$COSMIC_WALLPAPERS_NAME-$_commit.tar.xz|" "$SLACKBUILD"

  # Update the VERSION and _commit lines
  sed -i "s/^VERSION=.*/VERSION=${VERSION}/" "$SLACKBUILD"
  sed -i "s/^_commit=.*/_commit=${_commit}/" "$SLACKBUILD"

  echo "Updated $SLACKBUILD with the latest version and commit."
else
  echo "SlackBuild script not found in $ROOT_DIR/$COSMIC_WALLPAPERS_NAME. Skipping update for $COSMIC_WALLPAPERS_NAME."
fi

# Create a tarball and move it to /opt/htdocs/distfile
mv "$COSMIC_WALLPAPERS_DIR" "$COSMIC_WALLPAPERS_NAME-$_commit"
tar cvfJ "$COSMIC_WALLPAPERS_NAME-$_commit.tar.xz" "$COSMIC_WALLPAPERS_NAME-$_commit"
rm -fr "$COSMIC_WALLPAPERS_NAME-$_commit"
mv "$COSMIC_WALLPAPERS_NAME-$_commit.tar.xz" /opt/htdocs/distfile/

echo "The 'cosmic-wallpapers' repository has been processed, archived, and moved to /opt/htdocs/distfile."

# Set up variables
COSMIC_EDIT_REPO="https://github.com/pop-os/cosmic-edit.git"
COSMIC_EDIT_NAME="cosmic-edit"
COSMIC_EDIT_DIR=$(mktemp -dt "$COSMIC_EDIT_NAME.git.XXXXXX")

# Clone the repository
git clone --depth 1 "$COSMIC_EDIT_REPO" "$COSMIC_EDIT_DIR" || { echo "Failed to clone the repository"; exit 1; }

# Navigate into the cloned repository
cd "$COSMIC_EDIT_DIR" || { echo "Failed to enter the repository directory"; exit 1; }

# Set up git-lfs and fetch LFS objects
git lfs install
git remote add network-origin https://github.com/pop-os/cosmic-edit
git lfs fetch --all  # Fetch all LFS objects
git lfs pull  # Ensure all files are pulled down and available
git lfs checkout  # Check out the actual binary files

# Optional: sleep to ensure files are checked out
sleep 5

# Ensure that all LFS files were properly checked out
git lfs ls-files
git lfs status || { echo "git-lfs encountered an error"; exit 1; }

# Extract the version and commit information
VERSION=$(git log --date=format:%Y%m%d --pretty=format:%cd.%h -n1)
_commit=$(git rev-parse HEAD)

# Remove .git directory and .gitignore files
rm -rf .git
find . -name .gitignore -print0 | xargs -0 rm -f

# Navigate back to the root directory
cd "$ROOT_DIR" || { echo "Failed to return to the root directory"; exit 1; }

# Update the SlackBuild script in the project directory for 'cosmic-wallpapers'
SLACKBUILD="$ROOT_DIR/$COSMIC_EDIT_NAME/$COSMIC_EDIT_NAME.SlackBuild"
if [ -f "$SLACKBUILD" ]; then
  # Update the wget line
  sed -i "s|^wget -c .*|wget -c https://reddoglinux.ddns.net/distfile/$COSMIC_EDIT_NAME-$_commit.tar.xz|" "$SLACKBUILD"

  # Update the VERSION and _commit lines
  sed -i "s/^VERSION=.*/VERSION=${VERSION}/" "$SLACKBUILD"
  sed -i "s/^_commit=.*/_commit=${_commit}/" "$SLACKBUILD"

  echo "Updated $SLACKBUILD with the latest version and commit."
else
  echo "SlackBuild script not found in $ROOT_DIR/$COSMIC_EDIT_NAME. Skipping update for $COSMIC_EDIT_NAME."
fi

# Create a tarball and move it to /opt/htdocs/distfile
mv "$COSMIC_EDIT_DIR" "$COSMIC_EDIT_NAME-$_commit"
tar cvfJ "$COSMIC_EDIT_NAME-$_commit.tar.xz" "$COSMIC_EDIT_NAME-$_commit"
rm -fr "$COSMIC_EDIT_NAME-$_commit"
mv "$COSMIC_EDIT_NAME-$_commit.tar.xz" /opt/htdocs/distfile/

echo "The 'cosmic-edit' repository has been processed, archived, and moved to /opt/htdocs/distfile."

# Set up variables
COSMIC_GREETER_REPO="https://github.com/pop-os/cosmic-greeter.git"
COSMIC_GREETER_NAME="cosmic-greeter"
COSMIC_GREETER_DIR=$(mktemp -dt "$COSMIC_GREETER_NAME.git.XXXXXX")

# Clone the repository
git clone --depth 1 "$COSMIC_GREETER_REPO" "$COSMIC_GREETER_DIR" || { echo "Failed to clone the repository"; exit 1; }

# Navigate into the cloned repository
cd "$COSMIC_GREETER_DIR" || { echo "Failed to enter the repository directory"; exit 1; }

# Set up git-lfs and fetch LFS objects
git lfs install
git remote add network-origin https://github.com/pop-os/cosmic-greeter
git lfs fetch --all  # Fetch all LFS objects
git lfs pull  # Ensure all files are pulled down and available
git lfs checkout  # Check out the actual binary files

# Optional: sleep to ensure files are checked out
sleep 5

# Ensure that all LFS files were properly checked out
git lfs ls-files
git lfs status || { echo "git-lfs encountered an error"; exit 1; }

# Extract the version and commit information
VERSION=$(git log --date=format:%Y%m%d --pretty=format:%cd.%h -n1)
_commit=$(git rev-parse HEAD)

# Remove .git directory and .gitignore files
rm -rf .git
find . -name .gitignore -print0 | xargs -0 rm -f

# Navigate back to the root directory
cd "$ROOT_DIR" || { echo "Failed to return to the root directory"; exit 1; }

# Update the SlackBuild script in the project directory for 'cosmic-wallpapers'
SLACKBUILD="$ROOT_DIR/$COSMIC_GREETER_NAME/$COSMIC_GREETER_NAME.SlackBuild"
if [ -f "$SLACKBUILD" ]; then
  # Update the wget line
  sed -i "s|^wget -c .*|wget -c https://reddoglinux.ddns.net/distfile/$COSMIC_GREETER_NAME-$_commit.tar.xz|" "$SLACKBUILD"

  # Update the VERSION and _commit lines
  sed -i "s/^VERSION=.*/VERSION=${VERSION}/" "$SLACKBUILD"
  sed -i "s/^_commit=.*/_commit=${_commit}/" "$SLACKBUILD"

  echo "Updated $SLACKBUILD with the latest version and commit."
else
  echo "SlackBuild script not found in $ROOT_DIR/$COSMIC_GREETER_NAME. Skipping update for $COSMIC_GREETER_NAME."
fi

# Create a tarball and move it to /opt/htdocs/distfile
mv "$COSMIC_GREETER_DIR" "$COSMIC_GREETER_NAME-$_commit"
tar cvfJ "$COSMIC_GREETER_NAME-$_commit.tar.xz" "$COSMIC_GREETER_NAME-$_commit"
rm -fr "$COSMIC_GREETER_NAME-$_commit"
mv "$COSMIC_GREETER_NAME-$_commit.tar.xz" /opt/htdocs/distfile/

echo "The 'cosmic-greeter' repository has been processed, archived, and moved to /opt/htdocs/distfile."

echo "All projects have been processed and archives created."

