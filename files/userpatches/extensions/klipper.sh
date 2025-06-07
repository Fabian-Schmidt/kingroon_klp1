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
    pkgs+=("python3-virtualenv" "python3-dev" "libopenjp2-7" "libsodium-dev" "zlib1g-dev" "libjpeg-dev" "packagekit" "curl" "build-essential")

    # Measuring Resonances in klipper dependencies
    pkgs+=("python3-numpy" "python3-matplotlib" "libatlas-base-dev" "libopenblas-dev")

    # Katapult dependencies
    pkgs+=("python3-serial")

    do_with_retries 3 chroot_sdcard_apt_get_install "${pkgs[@]}"
}