#!/bin/bash

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
		stretch)
			# your code here
			;;
		buster)
			# your code here
			;;
		bullseye)
			# your code here
			;;
		bionic)
			# your code here
			;;
		focal)
			# your code here
			;;
		bookworm)
                        set -ex
#                        cp /tmp/overlay/rk3328-roc-cc.dtb /boot/dtb/rockchip/rk3328-mkspi.dtb
                        cp /tmp/overlay/rk3328-mkspi.dtb /boot/dtb/rockchip/rk3328-mkspi.dtb
#                        cp /tmp/overlay/wpa_supplicant-wlan0.conf /etc/wpa_supplicant/
                        rm /root/.not_logged_in_yet
                        rm -f /etc/systemd/system/getty@.service.d/override.conf
                        rm -f /etc/systemd/system/serial-getty@.service.d/override.conf
                        useradd -m -s $(which bash) mks
                        cat /etc/group
			for additionalgroup in sudo tty dialout; do
			    usermod -aG "${additionalgroup}" mks 2> /dev/null
			done
cat <<EOF >/etc/sudoers.d/mks
mks    ALL=NOPASSWD: ALL
EOF
                        echo mks:makerbase | chpasswd
			cd /home/mks
                        sudo -u mks git clone https://github.com/dw-0/kiauh.git
                        cd kiauh
                        apt-get update
                        apt-get install -y gpiod
                        sed -i 's/set -e/set -ex/' ./kiauh.sh
                        sed -i 's/clear -x//' ./kiauh.sh
			printf '2\n1\n1\n1\n1\n2\nY\n4\nn\nB\nQ\n' |sudo -u mks ./kiauh.sh
                        echo "OS: $(cat /etc/issue)" >> /home/mks/versions
                        echo "Kernel: $(strings /boot/Image |awk '/Linux version/ {print $3; exit}')" >>/home/mks/versions
                        echo "Kiauh: $(sudo -u mks git -C /home/mks/kiauh describe --tags)" >> /home/mks/versions
                        echo "Klipper: $(sudo -u mks git -C /home/mks/klipper describe --tags)" >> /home/mks/versions
                        echo "Moonraker: $(sudo -u mks git -C /home/mks/moonraker describe --tags)" >> /home/mks/versions
                        echo "Fluidd: $(cat /home/mks/fluidd/release_info.json |jq -r .version)" >> /home/mks/versions
                        sudo -u mks cp /tmp/overlay/printer_data/config/* /home/mks/printer_data/config
                        cp /tmp/overlay/printer_data/systemd/* /home/mks/printer_data/systemd

			mkdir /etc/systemd/system/klipper.service.d
                        mkdir /etc/systemd/system/moonraker.service.d

cat <<EOF >/etc/systemd/system/klipper.service.d/override.conf
[Service]
LogsDirectory=klipper
RuntimeDirectory=klipper
EOF

cat <<EOF >/etc/systemd/system/moonraker.service.d/override.conf
[Service]
LogsDirectory=moonraker
EOF
			ln -s /var/log/moonraker/moonraker.log /home/mks/printer_data/logs/moonraker.log
			ln -s /var/log/klipper/klippy.log /home/mks/printer_data/logs/klippy.log

			ln -s /var/log/nginx/fluidd-access.log /home/mks/printer_data/logs/fluidd-access.log
			ln -s /var/log/klipper/fluidd-error.log /home/mks/printer_data/logs/fluidd-error.log
			chage -d 0 root
cat <<EOF >/lib/systemd/system/mks-shutdown.service
[Unit]
Description=MKS-shutdown
After=network.target
Wants=udev.target

[Install]
WantedBy=multi-user.target

[Service]
Type=simple
ExecStart=/bin/bash -c '/usr/bin/gpiomon -s -n 1 -r 2 16 && /usr/sbin/poweroff'
EOF
                        systemctl enable mks-shutdown
			;;
	esac
} # Main

Main "$@"
