#!/bin/bash

install_python_egg(){
    targetdir=$1

    if [ ! -d $targetdir ];then
        echo "$targetdir no exist"
        exit 1
    fi

    # clean environment
    rm -rf ~/.local/bin/easy_install*

    # check setuptools has installed
    PYTHON2_VERSION=`python2 --version 2>&1 | awk 'NR==1{ print $2 }'`
    PYTHON2_VERSION_TAG=`echo ${PYTHON2_VERSION} | awk -F'.' '{ print $1"."$2 }'`
    PYTHON2=python${PYTHON2_VERSION_TAG}
    EASY_INSTALL2_ITEMS="easy_install
                         easy_install-2.1
                         easy_install-2.2
                         easy_install-2.3
                         easy_install-2.4
                         easy_install-2.5
                         easy_install-2.6
                         easy_install-2.7"
    PIP2=pip2

    for item in $(echo $EASY_INSTALL2_ITEMS);
    do
        which ${item} > /dev/null 2>&1
        if [ $? = 0 ];then
           EASY_INSTALL2=$item
           break
        fi
    done

    flag2=true
    which ${EASY_INSTALL2} > /dev/null 2>&1
    if [ $? != 0 ]; then
      flag2=false
    fi
    which ${PIP2} > /dev/null 2>&1
    if [ $? != 0 ]; then
      flag2=false
    fi

    config_file='/usr/local/python-hiai/install_path.config'
    touch $config_file
    # deal with easy_install and setuptools
    if [ "$flag2" = true ];then
        easy_install_version=$($EASY_INSTALL2 --version | awk '{print $2}')
        setuptools_version=$($PIP2 show setuptools | grep -w "Version" | awk '{print $2}')
        if [ -n "${easy_install_version}" ] && [ -n "${setuptools_version}" ];then
            if [ "${easy_install_version}" != "${setuptools_version}" ];then
                ${PIP2} uninstall -q -y setuptools
            fi
        fi

        mkdir -p ${targetdir}/site-packages

        # set PYTHONPATH
        export PYTHONPATH=${targetdir}/site-packages

        # install hiaiengine-python2
        ${EASY_INSTALL2} -q --allow-hosts=None --no-find-links -d ${targetdir}/site-packages ${targetdir}/../../lib64/hiaiengine-py2.7.egg

        # copy common
        which python2 > /dev/null
        if [ $? -eq 0 ];then
            if [ -f ${targetdir}/site-packages/hiaiengine-py2.7.egg/common/get_install_path.py ];then
                ret=$(python2 ${targetdir}/site-packages/hiaiengine-py2.7.egg/common/get_install_path.py)
                if [ ! -n $ret ];then
                    echo "get python install path failed"
                else
                    echo "python2="$ret >$config_file
                    if [ -d $ret/hiai ];then
                        rm -rf $ret/hiai
                        if [ $? != 0 ];then
                            echo "remove hiai failed"
                        fi
                    fi
                    mkdir -p $ret/hiai
                    cp -r ${targetdir}/site-packages/hiaiengine-py2.7.egg/common/* $ret/hiai/
                    if [ $? != 0 ];then
                        echo "copy hiai failed"
                    fi
               fi
            fi
        fi
    fi
    
    touch /etc/hiai_python.config
    echo "/usr" > /etc/hiai_python.config
    echo "DEVICE" >> /etc/hiai_python.config

}

python_hiai_path=/usr/local/python-hiai
install_python_egg $python_hiai_path
