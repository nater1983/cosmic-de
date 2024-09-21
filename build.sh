#!/bin/bash

echo "Building the Cosmic Desktop Environment on Slackware:"

# Array of directories
directories=(
  "cosmic-applets"
  "cosmic-applibrary"
  "cosmic-bg"
  "cosmic-comp"
  "cosmic-edit"
  "cosmic-files"
  "cosmic-greeter"
  "cosmic-icons"
  "cosmic-launcher"
  "cosmic-notifications"
  "cosmic-osd"
  "cosmic-panel"
  "cosmic-randr"
  "cosmic-screenshot"
  "cosmic-session"
  "cosmic-settings-daemon"
  "cosmic-settings"
  "cosmic-term"
  "cosmic-wallpapers"
  "cosmic-workspaces-epoch"
  "fira-fonts"
  "just"
  "pop-icon-theme"
  "sddm-sugar-candy"
  "seatd"
  "switcheroo-control"
  "system76-fonts"
  "system76-power"
  "xdg-desktop-portal-cosmic"
)

# Iterate through each directory, build, and install the packages
for dir in "${directories[@]}"; do
  echo "Building in $dir ..."
  cd "$dir" || { echo "Failed to change to directory $dir"; exit 1; }
  
  # Run the specific .SlackBuild script for the directory
  sh "${dir}.SlackBuild"
  if [ $? -ne 0 ]; then
    echo "Build failed in $dir"
    exit 1
  fi

  # Print contents of the cache directory for debugging
  echo "Contents of /var/cache/cosmic/:"
  ls -l /var/cache/cosmic/

  # Install the package corresponding to the directory
  package_file=$(ls /var/cache/cosmic/${dir}-*.t?z 2>/dev/null | grep -E "^/var/cache/cosmic/${dir}-[^-]+.t?z$")
  if [ -n "$package_file" ]; then
    upgradepkg --reinstall --install-new "$package_file"
    if [ $? -ne 0 ]; then
      echo "Package installation failed for $package_file"
      exit 1
    fi
  else
    echo "No package file found for $dir"
    exit 1
  fi
  
  cd ..
done

echo "Cosmic Desktop Environment build and installation completed successfully."
