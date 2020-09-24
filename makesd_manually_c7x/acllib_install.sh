#!/bin/bash
ACLLIB_PACKAGE=$(basename $(ls /home/HwHiAiUser/Ascend-acllib-*.run))


chown HwHiAiUser:HwHiAiUser /home/HwHiAiUser/${ACLLIB_PACKAGE}
echo "y
y
" | su HwHiAiUser -c "/home/HwHiAiUser/${ACLLIB_PACKAGE} --run"

rm -f /home/HwHiAiUser/${ACLLIB_PACKAGE}
exit 0
