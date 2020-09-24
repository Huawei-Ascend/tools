#!/bin/bash

cd /home/HwHiAiUser/aicpu_kernels_device/
chmod 750 *.sh
chmod 750 scripts/*.sh
scripts/install.sh --run

rm -rf /home/HwHiAiUser/aicpu_kernels_device

exit 0

