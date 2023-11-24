#!/bin/bash
# Compile script for MoeKernel
# Copyright (C) 2020-2021 Adithya R.

SECONDS=0
ZIPNAME="Moe-$(date '+%Y%m%d').zip"
TC_DIR="$HOME/tc/clang-18.0.0"
GCC_64_DIR="$HOME/tc/aarch64-linux-android-4.9"
GCC_32_DIR="$HOME/tc/arm-linux-androideabi-4.9"
AK3_DIR="$HOME/android/AnyKernel3"
DEFCONFIG="vendor/moe_defconfig"

if test -z "$(git rev-parse --show-cdup 2>/dev/null)" && head=$(git rev-parse --verify HEAD 2>/dev/null); then
    ZIPNAME="${ZIPNAME::-4}-$(echo $head | cut -c1-8).zip"
fi

export PATH="$TC_DIR/bin:$PATH"

export KBUILD_BUILD_USER=Moe
export KBUILD_BUILD_HOST=Nyan

if ! [ -d "${TC_DIR}" ]; then
    echo "Clang not found! Cloning to ${TC_DIR}..."
    if ! git clone --depth=1 https://gitlab.com/moehacker/clang-r498229b ${TC_DIR}; then
        echo "Cloning failed! Aborting..."
        exit 1
    fi
fi

if ! [ -d "${GCC_64_DIR}" ]; then
    echo "gcc not found! Cloning to ${GCC_64_DIR}..."
    if ! git clone --depth=1 -b lineage-19.1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git ${GCC_64_DIR}; then
        echo "Cloning failed! Aborting..."
        exit 1
    fi
fi

if ! [ -d "${GCC_32_DIR}" ]; then
    echo "gcc_32 not found! Cloning to ${GCC_32_DIR}..."
    if ! git clone --depth=1 -b lineage-19.1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git ${GCC_32_DIR}; then
        echo "Cloning failed! Aborting..."
        exit 1
    fi
fi

if [[ $1 = "-r" || $1 = "--regen" ]]; then
    make O=out ARCH=arm64 $DEFCONFIG savedefconfig
    cp out/defconfig arch/arm64/configs/$DEFCONFIG
    exit
fi

if [[ $1 = "-c" || $1 = "--clean" ]]; then
    rm -rf out
fi

if [[ $1 = "-m" || $1 = "--menu" ]]; then
    mkdir -p out
    make O=out ARCH=arm64 $DEFCONFIG menuconfig
elif [[ $1 = "menu" ]]; then
    mkdir -p out
    make O=out ARCH=arm64 $DEFCONFIG menuconfig
else
    mkdir -p out
    make O=out ARCH=arm64 $DEFCONFIG
fi

echo -e "\nStarting compilation... wait\n"
make -j$(nproc --all) \
    O=out \
    ARCH=arm64 \
    CC=clang \
    LD=ld.lld \
    AR=llvm-ar \
    AS=llvm-as \
    NM=llvm-nm \
    OBJCOPY=llvm-objcopy \
    OBJDUMP=llvm-objdump \
    STRIP=llvm-strip \
    CROSS_COMPILE=$GCC_64_DIR/bin/aarch64-linux-android- \
    CROSS_COMPILE_ARM32=$GCC_32_DIR/bin/arm-linux-androideabi- \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    Image.gz-dtb dtbo.img

if [ -f "out/arch/arm64/boot/Image.gz-dtb" ] && \
   [ -f "out/arch/arm64/boot/dtbo.img" ]; then
    echo -e "\nKernel compiled successfully! Zipping up...\n"
    if [ -d "$AK3_DIR" ]; then
        cp -r $AK3_DIR AnyKernel3
    elif ! git clone -q https://github.com/MoeKernel/AnyKernel3; then
        echo -e "\nAnyKernel3 repo not found locally and cloning failed! Aborting..."
        exit 1
    fi
    cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
    cp out/arch/arm64/boot/dtbo.img AnyKernel3
    rm -f *zip
    cd AnyKernel3
    git checkout master &> /dev/null
    zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
    cd ..
    rm -rf AnyKernel3
    rm -rf out/arch/arm64/boot
    echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
    echo "Zip: $ZIPNAME"
else
    echo -e "\nCompilation failed!"
    exit 1
fi
