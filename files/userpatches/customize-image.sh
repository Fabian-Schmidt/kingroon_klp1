#!/bin/bash

# NOTE this script is here as a placeholder for LEGACY compatability, and shouldn't be used.  Please use hooks and extensions instead

# arguments: $RELEASE $LINUXFAMILY $BOARD $BUILD_DESKTOP
#
# This is the image customization script

# NOTE: It is copied to /tmp directory inside the image
# and executed there inside chroot environment
# so don't reference any files that are not already installed

# NOTE: If you want to transfer files between chroot and host
# userpatches/overlay directory on host is bind-mounted to /tmp/overlay in chroot
# The sd card's root path is accessible via $SDCARD variable.

RELEASE=$1
LINUXFAMILY=$2
BOARD=$3
BUILD_DESKTOP=$4

Main() {
	case $RELEASE in
	bookworm)
		InstallKlipper
		;;
	trixie)
		InstallKlipper
		;;
	jammy)
		InstallKlipper
		;;
	esac
} # Main

InstallKlipper() {
		set -ex

		# Create user `mks`
		useradd -m -s $(which bash) mks
		# cat /etc/group
		for additionalgroup in sudo tty dialout; do
			usermod -aG "${additionalgroup}" mks 2>/dev/null
		done
		cat <<EOF >/etc/sudoers.d/mks
mks    ALL=NOPASSWD: ALL
EOF
		echo mks:makerbase | chpasswd

		# Install Klipper via `kiauh`
		apt update
		cd /home/mks
		sudo -u mks git clone https://github.com/dw-0/kiauh.git
		cd kiauh
		sudo -u mks sed -i 's/set -e/set -ex/' ./kiauh.sh
		sudo -u mks sed -i 's/clear -x//' ./kiauh.sh
		# Start kiauh and press menu buttons
		# 4-Select KIAUH v5
		# 1-Install
		# 1-Klipper
		# 1-Python 3.x
		# 1-Number of Klipper instances
		# 2-Moonraker
		# Yes-Start install
		# 4-Fluidd
		# No-Do not install recommended macros
		# 5-KlipperScreen
  		# Yes-Default
    	# X-graphical backend is Xserver
      	# Yes-Install NetworkManager
		# 14-Crowsnest
  		# Y-Add to update manager
    	# N-Reboot now
		# B-Back
		# Q-Quit
		printf '4\n1\n1\n1\n1\n2\nYes\n4\nNo\n5\nYes\nX\nYes\n14\nY\nN\n\nB\nQ\n' | sudo -u mks ./kiauh.sh
  		sudo -u mks git checkout kiauh.sh
		cd ..

		# Download files for Measuring Resonances in klipper
  		sudo -u mks ./klippy-env/bin/pip install -v "numpy<1.26"

		# Download & prep Katapult
		sudo -u mks git clone https://github.com/Arksine/katapult

		# Extract installed versions
		echo "OS: $(cat /etc/issue)" >>/home/mks/versions
		echo "Kernel: $(strings /boot/Image | awk '/Linux version/ {print $3; exit}')" >>/home/mks/versions
		echo "Kiauh: $(sudo -u mks git -C /home/mks/kiauh describe --tags)" >>/home/mks/versions
		echo "Klipper: $(sudo -u mks git -C /home/mks/klipper describe --tags)" >>/home/mks/versions
		echo "Moonraker: $(sudo -u mks git -C /home/mks/moonraker describe --tags)" >>/home/mks/versions
		echo "Fluidd: $(cat /home/mks/fluidd/release_info.json | jq -r .version)" >>/home/mks/versions
		echo "KlipperScreen: $(sudo -u mks git -C /home/mks/KlipperScreen describe --tags)" >> /home/mks/versions
		echo "Crowsnest: $(sudo -u mks git -C /home/mks/crowsnest describe --tags)" >> /home/mks/versions
		echo "Katapult: $(sudo -u mks git -C /home/mks/katapult describe)" >>/home/mks/versions
		cat /home/mks/versions

		# Take config files from repo
		sudo -u mks cp /tmp/overlay/printer_data/config/* /home/mks/printer_data/config
		cp /tmp/overlay/printer_data/systemd/* /home/mks/printer_data/systemd

		# Configure systemd
		mkdir /etc/systemd/system/klipper.service.d
		cat <<EOF >/etc/systemd/system/klipper.service.d/override.conf
[Service]
LogsDirectory=klipper
RuntimeDirectory=klipper
EOF

		mkdir /etc/systemd/system/moonraker.service.d
		cat <<EOF >/etc/systemd/system/moonraker.service.d/override.conf
[Service]
LogsDirectory=moonraker
EOF
		# Configure log redirects
		ln -s /var/log/moonraker/moonraker.log /home/mks/printer_data/logs/moonraker.log
		ln -s /var/log/klipper/klippy.log /home/mks/printer_data/logs/klippy.log
		ln -s /var/log/nginx/fluidd-access.log /home/mks/printer_data/logs/fluidd-access.log
		ln -s /var/log/klipper/fluidd-error.log /home/mks/printer_data/logs/fluidd-error.log

		# apt install -y gpiod

		# Cleanup image
		apt clean
		rm -rf /var/lib/apt/lists/*

		# Force password expired for root user
		chage -d 0 root
} # InstallKlipper

Main "$@"
