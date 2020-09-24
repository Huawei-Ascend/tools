#
#   =======================================================================
#
# Copyright (C) 2018, Hisilicon Technologies Co., Ltd. All Rights Reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#   1 Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#
#   2 Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#
#   3 Neither the names of the copyright holders nor the names of the
#   contributors may be used to endorse or promote products derived from this
#   software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#   =======================================================================
#
'''common installation'''
import os
import platform
import signal
import subprocess
import time
import getpass
import pexpect
import re
import datetime

# ssh expect prompt
PROMPT = ['# ', '>>> ', '> ', '\$ ']


def execute(cmd, timeout=3600, cwd=None):
    '''execute os command'''
    print(cmd)
    is_linux = platform.system() == 'Linux'

    if not cwd:
        cwd = os.getcwd()
    process = subprocess.Popen(cmd, cwd=cwd, bufsize=32768, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT, shell=True,
                               preexec_fn=os.setsid if is_linux else None)

    t_beginning = time.time()

    # cycle times
    time_gap = 0.01

    str_std_output = ""
    while True:

        str_out = str(process.stdout.read().decode())
        str_std_output = str_std_output + str_out

        if process.poll() is not None:
            break
        seconds_passed = time.time() - t_beginning

        if timeout and seconds_passed > timeout:

            if is_linux:
                os.kill(process.pid, signal.SIGTERM)
            else:
                process.terminate()
            return False, process.stdout.readlines()
        time.sleep(time_gap)
    str_std_output = str_std_output.strip()
    # print(str_std_output)
    std_output_lines_last = []
    std_output_lines = str_std_output.split("\n")
    for i in std_output_lines:
        std_output_lines_last.append(i)

    if process.returncode != 0 or "Traceback" in str_std_output:
        return False, std_output_lines_last

    return True, std_output_lines_last


def sftp_to_remote(user, ip, port, password, cmd_list):
    '''ssh to remote and execute command'''
    cmd = "sftp -P {port} {user}@{ip} ".format(ip=ip, port=port, user=user)
    print(cmd)
    try:
        process = pexpect.spawn(cmd, timeout=300)
        ret = process.expect(
            ["password", "Are you sure you want to continue connecting"])
        if ret == 1:
            process.sendline("yes")
            ret = process.expect("password")
        if ret != 0:
            return False

        process.sendline(password)
        process.expect(PROMPT)

        for cmd in cmd_list:
            if cmd.get("type") == "expect":
                process.expect(cmd.get("value"))
            else:
                if cmd.get("secure") is False:
                    print(cmd.get("value"))
                process.sendline(cmd.get("value"))
    except:
        return False
    finally:
        process.close(force=True)
    return True


def ssh_to_remote(user, ip, port, password, cmd_list):
    '''ssh to remote and execute command'''
    cmd = "ssh -p {port} {user}@{ip} ".format(ip=ip, port=port, user=user)
    print(cmd)
    try:
        process = pexpect.spawn(cmd, timeout=300)
        ret = process.expect(
            ["password", "Are you sure you want to continue connecting"])
        if ret == 1:
            process.sendline("yes")
            ret = process.expect("password")
        if ret != 0:
            return False

        process.sendline(password)
        process.expect(PROMPT)

        for cmd in cmd_list:
            if cmd.get("type") == "expect":
                process.expect(cmd.get("value"))
            else:
                if cmd.get("secure") is False:
                    print(cmd.get("value"))
                process.sendline(cmd.get("value"))
    except:
        return False
    finally:
        process.close(force=True)
    return True


def main():
    while(True):
        atlasdk_ip = input("Please input Atlas DK Development Board IP:")

        if re.match(r"^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", atlasdk_ip):
            break
        else:
            print("Input IP: %s is invalid!" % atlasdk_ip)

    atlasdk_ssh_user = input(
        "Please input Atlas DK Development Board SSH user(default: HwHiAiUser):")
    if atlasdk_ssh_user == "":
        atlasdk_ssh_user = "HwHiAiUser"

    atlasdk_ssh_pwd = getpass.getpass(
        "Please input Atlas DK Development Board SSH user password:")

    atlasdk_ssh_port = input(
        "Please input Atlas DK Development Board SSH port(default: 22):")
    if atlasdk_ssh_port == "":
        atlasdk_ssh_port = "22"
        
    print("[Step] Install system dependency packages...")
    ret = execute("apt-get install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu")
    if not ret[0]:
        print("ERROR: Install system dependency packages failed, please check your network.")
        tips = "If you make sure you have installed gcc-aarch64-linux-gnu g++-aarch64-linux-gnu,\nplease input Y to confirm, others to exit:"
        confirm = input(tips)
        
        if confirm != "Y" and confirm != "y":
            exit(-1)
    
    print("[Step] Pack sysroot...")
    now_time = datetime.datetime.now().strftime('ui_cross_%Y%m%d%H%M%S')
    command_list = [{"type": "cmd",
                     "value": "mkdir -p ./{path}/sysroot".format(path=now_time),
                     "secure": False},
                    {"type": "expect",
                     "value": PROMPT},
                    {"type": "cmd",
                     "value": "cp -rdp --parents /usr/include ./{path}/sysroot".format(path=now_time),
                     "secure": False},
                    {"type": "expect",
                     "value": PROMPT},
                    {"type": "cmd",
                     "value": "cp -rdp --parents /usr/lib ./{path}/sysroot".format(path=now_time),
                     "secure": False},
                    {"type": "expect",
                     "value": PROMPT},
                    {"type": "cmd",
                     "value": "cp -rdp --parents /lib ./{path}/sysroot".format(path=now_time),
                     "secure": False},
                    {"type": "expect",
                     "value": PROMPT},
                    {"type": "cmd",
                     "value": "cd ./{path}".format(path=now_time),
                     "secure": False},
                    {"type": "expect",
                     "value": PROMPT},
                    {"type": "cmd",
                     "value": "tar -zcvf ~/sysroot.tar.gz ./sysroot",
                     "secure": False},
                    {"type": "expect",
                     "value": PROMPT},
                    {"type": "cmd",
                     "value": "rm -rf ~/{path}".format(path=now_time),
                     "secure": False},
                    {"type": "expect",
                     "value": PROMPT}]

    ret = ssh_to_remote(atlasdk_ssh_user, atlasdk_ip, atlasdk_ssh_port,
                        atlasdk_ssh_pwd, command_list)
    if not ret:
        print("Pack sysroot.tar.gz failed.")
        exit(-1)
    
    print("[Step] Download sysroot package...")
    ret = sftp_to_remote(atlasdk_ssh_user, atlasdk_ip, atlasdk_ssh_port, atlasdk_ssh_pwd, [{"type": "cmd",
                                                                                            "value": "get sysroot.tar.gz",
                                                                                            "secure": False},
                                                                                           {"type": "expect",
                                                                                            "value": PROMPT},
                                                                                           {"type": "cmd",
                                                                                            "value": "rm sysroot.tar.gz",
                                                                                            "secure": False},
                                                                                           {"type": "expect",
                                                                                            "value": PROMPT}])
    if not ret:
        print("Download sysroot.tar.gz failed.")
        exit(-1)
    print("[Step] Configure UI Cross Compilation environment...")
    execute("tar -zxvf sysroot.tar.gz")
    execute("mkdir -p /usr/lib/aarch64-linux-gnu")
    execute("cp -rdp ./sysroot/usr/include /usr/aarch64-linux-gnu/")
    execute("cp -rdp ./sysroot/usr/lib/aarch64-linux-gnu/* /usr/lib/aarch64-linux-gnu")
    execute("cp -rdp ./sysroot/lib/aarch64-linux-gnu /lib/")
    execute("ln -s /lib/aarch64-linux-gnu/libz.so.1 /usr/lib/aarch64-linux-gnu/libz.so")
    execute("ln -s /usr/aarch64-linux-gnu/include/sys /usr/include/sys") 
    execute("ln -s /usr/aarch64-linux-gnu/include/bits /usr/include/bits")
    execute("ln -s /usr/aarch64-linux-gnu/include/gnu /usr/include/gnu")
    execute("rm -rf sysroot*")
    print("Configure cross compilation environment successfully.")
    exit(0)

if __name__ == "__main__":
    main()
