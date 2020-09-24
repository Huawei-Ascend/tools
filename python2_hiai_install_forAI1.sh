#!/bin/bash

install_python2_dependency() {
    sudo apt-get update
    sudo apt-get install python-setuptools python-dev build-essential python-pip
    pip install numpy enum34 future funcsigs unique protobuf -i http://mirrors.aliyun.com/pypi/simple/  --trusted-host mirrors.aliyun.com --user
    pip install opencv-python -i http://mirrors.aliyun.com/pypi/simple/  --trusted-host mirrors.aliyun.com --user
}

main() {
    install_python2_dependency 
    pip install opencv-python
}

main



