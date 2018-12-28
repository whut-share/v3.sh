# v6.sh
wget https://raw.githubusercontent.com/whut-share/v6/master/v6.sh

### bbr_plus

wget "https://github.com/cx9208/bbrplus/raw/master/ok_bbrplus_centos.sh" && chmod +x ok_bbrplus_centos.sh && ./ok_bbrplus_centos.sh

安装后，执行uname -r，显示4.14.89则切换内核成功
执行lsmod | grep bbr，显示有bbrplus则开启成功
