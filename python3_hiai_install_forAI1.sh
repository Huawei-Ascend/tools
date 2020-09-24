#!/bin/bash


install_python3_dependency() {
    sudo apt-get update
    sudo apt-get install python3-setuptools python3-pip python-funcsigs python3-dev build-essential

    pip3 install numpy enum34 future funcsigs unique protobuf -i http://mirrors.aliyun.com/pypi/simple/  --trusted-host mirrors.aliyun.com --user
    pip3 install six -i http://mirrors.aliyun.com/pypi/simple/  --trusted-host mirrors.aliyun.com --user -U 
    pip3 install jupyter ipython==7.9 -i http://mirrors.aliyun.com/pypi/simple/  --trusted-host mirrors.aliyun.com --user
    pip3 install opencv-python -i http://mirrors.aliyun.com/pypi/simple/  --trusted-host mirrors.aliyun.com --user
}

subdir_create() {
    path=$1
    if [ ! -d $path ];then
        mkdir -p $path
    fi

    chmod 750 $path
    return 0
}

install_python3_egg(){
    targetdir=$1

    if [ ! -d $targetdir ];then
        echo "$targetdir no exist"
        exit 1
    fi

    # clean environment
    rm -rf ~/.local/bin/easy_install*

    PYTHON3_VERSION=`python3 --version 2>&1 | awk 'NR==1{ print $2 }'`
    PYTHON3_VERSION_TAG=`echo ${PYTHON3_VERSION} | awk -F'.' '{ print $1"."$2 }'`
    PYTHON3=python${PYTHON3_VERSION_TAG}
    EASY_INSTALL3_ITEMS="easy_install3
                         easy_install-3.1
                         easy_install-3.2
                         easy_install-3.3
                         easy_install-3.4
                         easy_install-3.5
                         easy_install-3.6"
    PIP3=pip3

    for item in $(echo $EASY_INSTALL3_ITEMS);
    do
        which ${item} > /dev/null 2>&1
           if [ $? = 0 ];then
              EASY_INSTALL3=$item
              break
           fi
    done

    flag3=true
    which ${EASY_INSTALL3} > /dev/null 2>&1
    if [ $? != 0 ]; then
        echo "lack python install tool"
        exit 1
    fi
    which ${PIP3} > /dev/null 2>&1
    if [ $? != 0 ]; then
        echo "lack python pip"
        exit 1
    fi

    config_file='/usr/local/python-hiai/install_path.config'
    touch $config_file

    # deal with easy_install and setuptools
    if [ "$flag3" = true ];then
        easy_install_version=$($EASY_INSTALL3 --version | awk '{print $2}')
        setuptools_version=$($PIP3 show setuptools | grep -w "Version" | awk '{print $2}')
        if [ -n "${easy_install_version}" ] && [ -n "${setuptools_version}" ];then
            if [ "${easy_install_version}" != "${setuptools_version}" ];then
                ${PIP3} uninstall -q -y setuptools
            fi
        fi

        mkdir -p ${targetdir}/${PYTHON3}/site-packages

        # set PYTHONPATH
        export PYTHONPATH=${targetdir}/${PYTHON3}/site-packages

        # install hiaiengine-python3
        ${EASY_INSTALL3} -q --allow-hosts=None --no-find-links -d ${targetdir}/${PYTHON3}/site-packages ${targetdir}/../HiAI/runtime/lib64/hiaiengine-py3.5.egg

        # copy common
        which python3 > /dev/null
        if [ $? -eq 0 ];then
            if [ -f ${targetdir}/${PYTHON3}/site-packages/hiaiengine-py3.5.egg/common/get_install_path.py ];then
                ret=$(python3 ${targetdir}/${PYTHON3}/site-packages/hiaiengine-py3.5.egg/common/get_install_path.py)
                if [ ! -n $ret ];then
                    echo "get python install path failed"
                else
                    echo "python3="$ret >> $config_file
                    if [ -d $ret/hiai ];then
                        rm -rf $ret/hiai
                        if [ $? != 0 ];then
                            echo "remove hiai failed"
                        fi
                    fi
                    mkdir -p $ret/hiai
                    cp -r ${targetdir}/${PYTHON3}/site-packages/hiaiengine-py3.5.egg/common/* $ret/hiai/
                    if [ $? != 0 ];then
                        echo "copy hiai failed"
                    fi
                fi
            fi
        fi

    fi
}

install_python_opencv() {
    pip3 install opencv-python
}


main () {
    pip3 install --upgrade pip
    install_python3_dependency
	
    python3_hiai_path=/usr/local/python-hiai
    subdir_create $python3_hiai_path
    install_python3_egg $python3_hiai_path    

    install_python_opencv
}

main


