> 由于promethues.service等脚本使用的 start-stop-daemon启动的,start-stop-daemon在debian的dpkg包,CentOS默认是没有的.

**centos安装:**

```
sudo yum install ncurses-devel -y
sudo wget http://ftp.de.debian.org/debian/pool/main/d/dpkg/dpkg_1.16.18.tar.xz -O dpkg_1.16.18.tar.xz
sudo tar -xf dpkg_1.16.18.tar.xz && cd dpkg-1.16.18
sudo ./configure 
sudo make
sudo make install
cd utils
sudo cp start-stop-daemon /usr/bin/start-stop-daemon
```

**Ubuntu或Debian**:

```
sudo apt-cache search ncurses
sudo apt-get install libncurses5-dev -y
sudo wget http://ftp.de.debian.org/debian/pool/main/d/dpkg/dpkg_1.16.18.tar.xz -O dpkg_1.16.18.tar.xz
sudo tar -xf dpkg_1.16.18.tar.xz && cd dpkg-1.16.18
sudo ./configure 
sudo make
sudo make install
sudo cp utils/start-stop-daemon /usr/local/bin/start-stop-daemon
```

