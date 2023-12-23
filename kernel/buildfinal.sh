#!/bin/bash

# Compile script for Gato+ Kernel.
# Based off QuicksilveR kernel compilation script.
# Credits to Adithya R., Suga (bheatleyyy), rk134.

# Global variable initilization
SECONDS=0
ZIPNAME="Gato+-$(date '+%Y%m%d-%H%M').zip"
TC_DIR="/home/rk134/working/aospa/msm-5.4-gatotc/clang-17.0.3"
AK3_DIR="AnyKernel3"
DEFCONFIG="vendor/lahaina-qgki_defconfig"
MAKE_PARAMS="O=out ARCH=arm64 CC='ccache clang' LLVM=1 LLVM_IAS=1"

# Export $TC_DIR to path
export PATH="$TC_DIR/bin:$PATH"

# Function definition

## Regenerate defconfig
if [[ $2 = "-r" || $1 = "--regen" ]]; then
	make $MAKE_PARAMS $DEFCONFIG savedefconfig
	cp out/.config arch/arm64/configs/$DEFCONFIG
	echo -e "\nSuccessfully regenerated defconfig at $DEFCONFIG"
	exit
fi

## Fully regenerate defconfig
if [[ $2 = "-fr" || $1 = "--fregen" ]]; then
        make $MAKE_PARAMS $DEFCONFIG
        cp out/.config arch/arm64/configs/$DEFCONFIG
        echo -e "\nSuccessfully regenerated defconfig at $DEFCONFIG"
        exit
fi

## Regenerate defconfig using safedefconfig
if [[ $2 = "-dfr" || $1 = "--defregen" ]]; then
        make $MAKE_PARAMS $DEFCONFIG savedefconfig
        cp out/defconfig arch/arm64/configs/$DEFCONFIG
        echo -e "\nSuccessfully regenerated defconfig at $DEFCONFIG"
        exit

fi

## Regenerate defconfig using menuconfig
if [[ $2 = "-mc" || $1 = "--mconf" ]]; then
        make $MAKE_PARAMS $DEFCONFIG menuconfig
        cp out/.config arch/arm64/configs/$DEFCONFIG
        echo -e "\nSuccessfully regenerated defconfig at $DEFCONFIG"
        exit
fi

## Clean output folder
if [[ $2 = "-c" || $1 = "--clean" ]]; then
	echo -e "\nCleaning output folder..."
	rm -rf out
fi

# Starting the build
mkdir -p out
make $MAKE_PARAMS $DEFCONFIG
ARCH=arm64 CC=clang LLVM=1 LLVM_IAS=1 scripts/kconfig/merge_config.sh -O out arch/arm64/configs/$DEFCONFIG arch/arm64/configs/vendor/oplus_yupik_QGKI.config

echo -e "\nStarting compilation...\n"
make -j$(nproc --all) $MAKE_PARAMS || exit $?

kernel="out/arch/arm64/boot/Image"

if [ -f "$kernel" ]; then
	echo -e "\nKernel compiled succesfully! Zipping up...\n"
	if [ -d "$AK3_DIR" ]; then
		cp -r $AK3_DIR AnyKernel3
	elif ! git clone -q https://github.com/rk134/AnyKernel3; then
		echo -e "\nAnyKernel3 repo not found locally and couldn't clone from GitHub! Aborting..."
		exit 1
	fi
        COMPILED_IMAGE=out/arch/arm64/boot/Image
        COMPILED_DTBO=out/arch/arm64/boot/dtbo.img
        mv -f ${COMPILED_IMAGE} ${COMPILED_DTBO} AnyKernel3
        find out/arch/arm64/boot/dts/vendor -name '*.dtb' -exec cat {} + > AnyKernel3/dtb
	cd AnyKernel3
	zip -r9 "../$ZIPNAME" * -x .git README.md *placeholder
	cd ..
	rm -rf AnyKernel3
	echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) :"
	echo "$(realpath $ZIPNAME)"
else
	echo -e "\nCompilation failed!"
	exit 1
fi
