[TOC]







# 第七单元-shell脚本概述



## 7.1 shell概念

Shell 是一个用 C 语言编写的程序，它是用户使用 Linux 的桥梁。Shell 既是一种命令语言，又是一种程序设计语言。



## 7.2 shell脚本结构

Shell 脚本（shell script），是一种为 shell 编写的脚本程序。

**1.开头：#!/bin/sh或#!/bin/bash**
符号#!用来告诉系统，这个脚本需要什么解释器来执行，即使用哪一种 Shell。

**2.注释:**
以#开头的行表示注释

**3.命令行的书写规则：**
一行一条命令
若一行多个命令，用分号（;）分割
长命令可以使用反斜线字符（\）



### 7.2.1 第一个shell脚本

打开文本编辑器(可以使用 vi/vim 命令来创建文件)，新建一个文件 test.sh，扩展名为 sh（sh代表shell），扩展名并不影响脚本执行，见名知意就好，如果你用 php 写 shell 脚本，扩展名就用 php 好了。

输入一些代码，第一行一般是这样：

```
#!/bin/bash
echo "Hello World !"
```

### 7.2.2 shell 脚本的方法

**1、作为可执行程序**

将上面的代码保存为 test.sh，并 cd 到相应目录：

```shell
chmod +x ./test.sh  #使脚本具有执行权限
./test.sh  #执行脚本
```

注意，一定要写成 **./test.sh**，而不是 **test.sh**，运行其它二进制的程序也一样，直接写 test.sh，linux 系统会去 PATH 里寻找有没有叫 test.sh 的，而只有 /bin, /sbin, /usr/bin，/usr/sbin 等在 PATH 里，你的当前目录通常不在 PATH 里，所以写成 test.sh 是会找不到命令的，要用 ./test.sh 告诉系统说，就在当前目录找。

**2、作为解释器参数**

这种运行方式是，直接运行解释器，其参数就是 shell 脚本的文件名，如：

```shell
/bin/sh test.sh
```





## 7.3 变量

### 7.3.1 了解系统变量

| 系统定义的变量                     | 意义               |
| ---------------------------------- | ------------------ |
| BASH=/bin/bash                     | Bash Shell 名称    |
| BASH_VERSION=4.1.2(1)              | Bash 版本          |
| HOME=/home/linuxtechi              | 用户家目录         |
| LOGNAME=LinuxTechi                 | 当前登录用户的名字 |
| OSTYPE=Linux                       | 操作系统类型       |
| PATH=/usr/bin:/sbin:/bin:/usr/sbin | 可执行文件搜索路径 |
| PWD=/home/linuxtechi               | 当前工作目录       |
| SHELL=/bin/bash                    | Shell 名称         |
| USERNAME=linuxtechi                | 当前登录的用户名   |

 

### 7.3.2 掌握用户自定义变量

1.在shell 脚本中，**所有的变量都由字符串组成**，且不需要对变量进行声明。

2.用户变量可以是任何不超过20个的**字母、数字或者下划线字符的文本字符串（变量只能以字母或下划线开头）**。用户变量是**大小写敏感的**，因此，变量Var1和变量var1是不同的变量。

命名变量：

变量名=变量值

```shell
[root@ mysql-master tmp]# name=wjj
[root@ mysql-master tmp]# echo $name
wjj
```



### 7.3.3 特殊变量

| 特殊变量 | 含义                                                         |
| -------- | ------------------------------------------------------------ |
| $$       | Shell本身的PID（ProcessID）                                  |
| $!       | Shell最后运行的后台Process的PID                              |
| $?       | 最后运行的命令的结束代码（返回值）                           |
| $-       | 使用Set命令设定的Flag一览                                    |
| $*       | 所有参数列表。如"$*"用「"」括起来的情况、以"$1 $2 … $n"的形式输出所有参数。 |
| $@       | 所有参数列表。如"$@"用「"」括起来的情况、以"$1" "$2" … "$n" 的形式输出所有参数。 |
| $#       | 添加到Shell的参数个数                                        |
| $0       | Shell本身的文件名                                            |
| $1～$n   | 添加到Shell的各参数值。$1是第1参数、$2是第2参数…。           |

 **实例**

```
以下实例我们向脚本传递三个参数，并分别输出，其中 $0 为执行的文件名：

#!/bin/bash

echo "Shell 传递参数实例！"
echo "执行的文件名：$0"
echo "第一个参数为：$1"
echo "第二个参数为：$2"
echo "第三个参数为：$3"
为脚本设置可执行权限，并执行脚本，输出结果如下所示：

chmod +x test.sh 
./test.sh 1 2 3

Shell 传递参数实例！
执行的文件名：./test.sh
第一个参数为：1
第二个参数为：2
第三个参数为：3
```



### 7.3.4 变量的赋值

变量的赋值使用“=”

例子:

```
x=6
a="welcome to beijing"
```

单引号('')：所有转移符全部关闭，完整的反括号中的内容

双引号("")：部分转义符关闭，但某些则保留(如：$ )

反引号(``)：反引号内荣作为一个系统命令并执行

**单引号和双引号的区别：**

```shell
[root@ mysql-master ~]# name=bawei
[root@ mysql-master ~]# echo $name
bawei
[root@ mysql-master ~]# echo '$name'
$name
[root@ mysql-master ~]# echo "$name"
bawei
```



### 7.3.5 变量的调用

在变量名前面加一个$符号

```
name=linux
echo $name
```



### 7.3.6 read从键盘读入内容

用法:

read -p "提示信息"  变量名

例子:

read -p "请输入你的用户名: " username



练习：模拟用户登录并显示登录用户

```shell
[root@ mysql-master ~]# vim login.sh
#!/bin/bash

read -p "请输入用户名: " username
read -p "请输入密码: " userpasswd
echo -e "Login success,Welcome,$username"
```





## 7.4 cut、sort、uniq、wc命令详解

### 7.4.1 cut

Linux cut命令用于显示每行从开头算起 num1 到 num2 的文字。

**语法**

```
cut  [-bn] [file]
cut [-c] [file]
cut [-df] [file]
```

**使用说明:**

cut 命令从文件的每一行剪切字节、字符和字段并将这些字节、字符和字段写至标准输出。

如果不指定 File 参数，cut 命令将读取标准输入。必须指定 -b、-c 或 -f 标志之一。

**参数:**

```
-b ：以字节为单位进行分割。这些字节位置将忽略多字节字符边界，除非也指定了 -n 标志。
-c ：以字符为单位进行分割。
-d ：自定义分隔符，默认为制表符。
-f ：与-d一起使用，指定显示哪个区域。
-n ：取消分割多字节字符。仅和 -b 标志一起使用。如果字符的最后一个字节落在由 -b 标志的 List 参数指示的
范围之内，该字符将被写出；否则，该字符将被排除
```

**实例：**

1.显示/etc/grub.conf里第1个字符

```
cut -c1 /etc/grub.conf
```

2.显示/etc/grub.conf里第1个到第20个字符

```
cut   -c1-20   /etc/grub.conf
```

3.显示/etc/passwd里，以冒号分隔的第1列到第3列

```
cut  -d':'  -f1-3   /etc/passwd
```

4.显示/etc/passwd里，以冒号分隔的第1列和第3列

```
cut  -d':' -f1,3   /etc/passwd
```



### 7.4.2 sort

Linux sort命令用于将**文本文件内容加以排序**。

sort可针对文本文件的内容，**以行为单位来排序**。

**语法**

```
sort [-bcdfimMnr][-o<输出文件>][-t<分隔字符>][+<起始栏位>-<结束栏位>][--help][--verison][文件]
```

**参数说明：**

| 参数                   | 含义                                                     |
| ---------------------- | -------------------------------------------------------- |
| -b                     | 忽略每行前面开始出的空格字符。                           |
| -c                     | 检查文件是否已经按照顺序排序。                           |
| -d                     | 排序时，处理英文字母、数字及空格字符外，忽略其他的字符。 |
| -f                     | 排序时，将小写字母视为大写字母。                         |
| -i                     | 排序时，除了040至176之间的ASCII字符外，忽略其他的字符。  |
| -m                     | 将几个排序好的文件进行合并。                             |
| -M                     | 将前面3个字母依照月份的缩写进行排序。                    |
| **-n**                 | **依照数值的大小排序。**                                 |
| -o<输出文件>           | 将排序后的结果存入指定的文件。                           |
| **-r**                 | **以相反的顺序来排序。**                                 |
| **-u**                 | **去除重复行**                                           |
| -t<分隔字符>           | 指定排序时所用的栏位分隔字符。                           |
| +<起始栏位>-<结束栏位> | 以指定的栏位来排序，范围由起始栏位到结束栏位的前一栏位。 |

**实例**

1.查看/etc/passwd里的内容并且**正向排序**

```
sort /etc/passwd
```

2.在输出行中**去除重复行**

sort的-u选项

```shell
[root@ mysql-master ~]# cat fruit.txt
banana
apple
pear
orange
pear

[root@ mysql-master ~]# sort fruit.txt
apple
banana
orange
pear
pear

[root@ mysql-master ~]# sort -u fruit.txt
apple
banana
orange
pear
```

3.反向排序

sort默认的排序方式是升序，如果想改成降序，就加个-r就搞定了。

```shell
[root@ mysql-master ~]# cat number.txt
1
3
5
2
4

[root@ mysql-master ~]# sort number.txt
1
2
3
4
5

[root@ mysql-master ~]# sort -r number.txt
5
4
3
2
1
```



4.将排序后内容输出到文件

sort的-o选项

由于sort默认是把结果输出到标准输出，所以需要用重定向才能将结果写入文件，形如sort filename > newfile。

但是，如果你想把排序结果输出到原文件中，用重定向可就不行了。

```shell
[root@ mysql-master ~]# sort -r number.txt >number.txt
[root@ mysql-master ~]# cat number.txt
[root@ mysql-master ~]#
```


你瞅瞅，竟然将number清空了。

就在这个时候，-o选项出现了，它成功的解决了这个问题，让你放心的将结果写入原文件。这或许也是-o比重定向的唯一优势所在。

```shell
[root@ mysql-master ~]# cat number.txt
1
3
5
2
4
[root@ mysql-master ~]# sort -r number.txt -o number.txt
[root@ mysql-master ~]# cat number.txt
5
4
3
2
1
```



5.依照数值的大小排序

sort的-n选项

有没有遇到过10比2小的情况。出现这种情况是由于排序程序将这些数字按字符来排序了，排序程序会先比较1和2，显然1小，所以就将10放在2前面喽。这也是sort的一贯作风。

我们如果想改变这种现状，就要使用-n选项，来告诉sort，“要以数值来排序”！

```shell
[root@ mysql-master ~]# cat number.txt
1
10
19
11
2
5

[root@ mysql-master ~]# sort number.txt
1
10
11
19
2
5

[root@ mysql-master ~]# sort -n number.txt
1
2
5
10
11
19
```



6.sort的-t选项和-k选项

如果有一个文件的内容是这样：

```
[root@ mysql-master ~]# cat facebook.txt
banana:30:5.5
apple:10:2.5
pear:90:2.3
orange:20:3.4
```

这个文件有三列，列与列之间用冒号隔开了，第一列表示水果类型，第二列表示水果数量，第三列表示水果价格。

那么我想以水果数量来排序，也就是以第二列来排序，如何利用sort实现？

幸好，**sort提供了-t选项，后面可以设定间隔符**。（是不是想起了cut和paste的-d选项，共鸣～～）

指定了间隔符之后，就可以用-k来指定列数了。

```
[root@ mysql-master ~]# sort -n -k 2 -t : facebook.txt
apple:10:2.5
orange:20:3.4
banana:30:5.5
pear:90:2.3
```

我们使用冒号作为间隔符，并针对第二列来进行数值升序排序，结果很令人满意。



### 7.4.3 uniq

uniq命令可以**删除排序过的文件中的重复行**，因此uniq经常和sort合用。也就是说，为了使uniq起作用，所有的重复行必须是相邻的。

选项与参数：

```shell
-i   ：忽略大小写字符的不同；
-c  ：进行计数
-u  ：只显示唯一的行
```

实例：

1.排序之后删除了重复行，同时在行首位置输出该行重复的次数

```shell
[root@ mysql-master ~]# sort test.txt | uniq -c
      1 friend
      3 hello
      2 world
```

2.仅显示存在重复的行，并在行首显示该行重复的次数

```shell
[root@ mysql-master ~]# sort test.txt | uniq -dc
      3 hello
      2 world
```

3.仅显示不重复的行

```shell
[root@ mysql-master ~]# sort test.txt | uniq -u
friend
```



### 7.4.4 wc

wc命令的功能为统计指定文件中的字节数、字数、行数，并将统计结果显示输出。

**语法：**wc [选项] 文件...

**说明：**该命令统计指定文件中的字节数、字数、行数。如果没有给出文件名，则从标准输入读取。wc同时也给出所指定文件的总统计数。下面让我们来简单的看一下其支持的参数及其代表的含义。

**参数及含义**

| 参数 | 含义                                                         |
| ---- | ------------------------------------------------------------ |
| -c   | 显示文件的Bytes数(字节数)及文件名输出到屏幕上                |
| -l   | 将每个文件的行数及文件名输出到屏幕上                         |
| -m   | 将每个文件的字符数及文件名输出到屏幕上，如果当前系统不支持多字节字符其将显示与-c参数相同的结果 |
| -w   | 将每个文件含有多少个词及文件名输出到屏幕上                   |
| -L   | 显示最长一行字符数                                           |

**实例：**

```
[root@ mysql-master ~]# wc -l /etc/passwd
25 /etc/passwd

[root@ mysql-master ~]# cat /etc/passwd|wc -l
25

[root@ mysql-master ~]# echo '123456'|wc -L
6
```



## 7.5 find文件查找工具

### 7.5.1 find工具详解

 【命令作用】 查找（文件f或目录d）  file   directory

| **参数**  | **说明**                                                  |
| --------- | --------------------------------------------------------- |
| -type     | 类型                                                      |
| -exec     |                                                           |
| -name     | 以什么*命名的                                             |
| -iname    | 此参数的效果和指定“-name”参数类似，但忽略字符大小写的差别 |
| -mtime    | 修改时间                                                  |
| -ctime    | 创建时间                                                  |
| -maxdepth | find命令查找的最大深度（tree -L 1 -d）                    |
| -size     | 文件大小（大于1M   是+1M）                                |
| -perm     | 按照文件权限来查找文件                                    |
| -user     | 按照文件属主来查找文件                                    |
| -group    | 按照文件所属的组来查找文件                                |
| -inum     | 根据inode号查找文件                                       |



### 7.5.2 find案例实战

find+mv(cp)经典例题

```
mv  $(find /data/ -type f -size +1M -mtime +7 -name "*log")  /tmp/
find /data/ -type f -size +1M -mtime +7 -name "*log" -exec mv {} /tmp/ \;
find /data/ -type f -size +1M -mtime +7 -name "*.log" |xargs mv -t  /tmp/
find /data/ -type f -size +1M -mtime +7 -name "*.log" |xargs -i mv {} /tmp/
```

查找文件

```
find ./ -type f
```

查找目录

```
find ./ -type d
```

查找名字为test的文件或目录

```
find ./ -name test
```

查找文件名匹配*.c的文件

```
find ./ -name '*.log'
```

打印test文件名后，打印test文件的内容

```
find ./ -name test -print -exec cat {} \;
```

不打印test文件名，只打印test文件的内容

```
find ./ -name test -exec cat {} \;
```

查找文件更新日时在距现在时刻二天以上的文件

```
find ./ -mtime +2
```

查找空文件并删除

```
find ./ -empty -type f -print -delete
```

查找权限为644的文件或目录(需完全符合)

```
find ./ -perm 664
```

查找有执行权限但没有可读权限的文件

```
find ./ -executable \! -readable
```

查找文件size小于10M的文件或目录

```
find ./ -size -10M
```

