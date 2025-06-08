# Examples for extensions:
# - https://github.com/lanefu/armbian-userpatches-example-indiedroid-nova/tree/main/extensions
# - https://github.com/armbian/build/tree/main/extensions

function post_install_kernel_debs__900_klipper() {
	display_alert "Install Klipper dependencies" "${EXTENSION}" "info"

    # Klipper dependencies
    declare -a pkgs=("virtualenv" "python3-dev" "libffi-dev" "build-essential" "libusb-dev")
    # kconfig requirements
    pkgs+=("libncurses-dev")
    # hub-ctrl
    pkgs+=("libusb-dev")
    # AVR chip installation and building
    pkgs+=("avrdude" "gcc-avr" "binutils-avr" "avr-libc")
    # ARM chip installation and building
    pkgs+=("stm32flash" "libnewlib-arm-none-eabi")
    pkgs+=("gcc-arm-none-eabi" "binutils-arm-none-eabi" "libusb-1.0" "pkg-config")
    # add dfu-util for octopi-images
    pkgs+=("dfu-util")
    # add pkg-config for rp2040 build
    pkgs+=("pkg-config")

    # Moonraker dependencies
    pkgs+=("python3-virtualenv" "python3-dev" "libopenjp2-7" "libsodium-dev" "zlib1g-dev" "libjpeg-dev" "packagekit" "curl" "build-essential" "libiw30")

    # Fluidd dependencies
    pkgs+=("nginx")

    # KlipperScreen dependencies
    pkgs+=("xinit" "xinput" "x11-xserver-utils" "xserver-xorg-input-evdev" "xserver-xorg-input-libinput" "xserver-xorg-legacy" "xserver-xorg-video-fbdev")

    # KlipperScreen OPTIONAL dependencies
    pkgs+=("fonts-nanum" "fonts-ipafont" "libmpv-dev")

    # KlipperScreen PYGOBJECT dependencies
    pkgs+=("libgirepository1.0-dev" "gcc" "libcairo2-dev" "pkg-config" "python3-dev" "gir1.2-gtk-3.0")

    # KlipperScreen MISC dependencies
    pkgs+=("librsvg2-common" "libopenjp2-7" "libdbus-glib-1-dev" "autoconf" "python3-venv")

    # Crowsnest Dependencies
    pkgs+=("git" "crudini" "bsdutils" "findutils" "v4l-utils" "curl")
    
    # Crowsnest Ustreamer Dependencies
    pkgs+=("build-essential" "libevent-dev" "libjpeg-dev" "libbsd-dev" "pkg-config")

    # Measuring Resonances in klipper dependencies
    pkgs+=("python3-numpy" "python3-matplotlib" "libatlas-base-dev" "libopenblas-dev")

    # Katapult dependencies
    pkgs+=("python3-serial")

    do_with_retries 3 chroot_sdcard_apt_get_install "${pkgs[@]}"

    display_alert "Delete marker file  `/root/.not_logged_in_yet`" "${EXTENSION}" "info"
	run_host_command_logged rm "${SDCARD}/root/.not_logged_in_yet"

    display_alert "Disable serial terminal" "${EXTENSION}" "info"
	run_host_command_logged rm "-f" "${SDCARD}/etc/systemd/system/getty@.service.d/override.conf"
	run_host_command_logged rm "-f" "${SDCARD}/etc/systemd/system/serial-getty@.service.d/override.conf"
}

function post_customize_image__klipper() {
	display_alert "Clear SSH host keys" "${EXTENSION}" "info"
	run_host_command_logged rm "-f" "${SDCARD}/etc/ssh/ssh_host*"

	display_alert "Copy installed version file" "${EXTENSION}" "info"
    local version_src="${SDCARD}/home/mks/versions"
    local version_dst="${DEST}/versions"
	run_host_command_logged cp $version_src $version_dst

    display_alert "Copy Device tree files" "${EXTENSION}" "info"
	run_host_command_logged cp "${EXTENSION_DIR}/*.dtb" "${SDCARD}/boot/dtb/rockchip/"
	run_host_command_logged echo "fdtfile=rockchip/rk3328-cheetah22.dtb" ">>" "${SDCARD}/boot/armbianEnv.txt"
}