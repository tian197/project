[TOC]







# 第九单元-shell脚本循环语句

​	循环语句常用于**重复执行一条命令或一组命令等**，直到达到结束条件后，则终止执行。在Shell中常见的循环命令有while、until、for和select等。



## 9.1 for循环语句

​	for循环语句与while循环语句类似，但for循环语句主要用于**有限次的循环场景**，while主要**无限次循环的场景**，如守护进程。



### 9.1.1 for循环语句语法分析

1.第一种格式

```shell
for  变量  in  列表
do
	操作
done
```

2,.第二种格式

```shell
for  ((初始化表达式； 条件表达式； 更新循环变量表达式))
do
	循环语句
done
```

这种格式是类C的风格，大家也见得较多



### 9.1.2 for循环实例应用

**1.输出指定序列**

例子一: 循环输出1到10

```shell
for i  in  $(seq  1   10)
do
	echo $i
done
```

例子二：循环输出1到10

```
for (( i=1; i<=10; i++ ))
do
    echo $i
done
```



**2.批量用户处理**

```shell
批量创建user01、user02 ...user10共10个用户

#!/bin/bash
for ((i=1;i<=10;i=i+1))
do
    echo "正在创建第$i个用户"
    useradd user$i
done
```



**拓展一：shell批量创建用户并设置密码**

**1.指定密码创建用户**

```shell
示例一：for循环创建
#!/bin/bash
for i in  $(seq  1   10)
do
    useradd www$i   # www$i 此处为字符串拼接
    echo "123456" | passwd --stdin www$i
done

示例二：while循环创建
#!/bin/bash
PREFIX="stu"
i=1
while [ $i -le 20 ]
do
    useradd ${PREFIX}$i
    echo "123456" | passwd --stdin ${PREFIX}$i &> /dev/null
    let i++
done
```

**2.随机密码，并保存，创建用户**

```shell
示例一：
#!/bin/bash
for u in la{01..10}
do
	useradd $u &>/dev/null
	if [ $? -eq 0 ]
    then
       echo "add user is ok"
       p=$(uuidgen)
       echo $p|passwd --stdin $u &>/dev/null
       echo "$u:$p" >>/tmp/user.list
     else
       echo "add user is error"
    fi
done
```



**拓展二：for循环嵌套if判断**

使用bash打印出1,2,3,4,5 ，判断等于4时打印hello。

```shell
#!/bin/sh
for i in 1 2 3 4 5;do
 if [ $i == 4 ];then
  echo "hello"
 else
  echo "$i"
 fi
done
```



### 9.1.3 补充：获取随机字符串或数字

#### （1）获取随机8位字符串：

方法一：

```shell
uuidgen|cut -c 1-8
```

方法二：

```shell
echo $RANDOM |md5sum|cut -c 1-8
```

方法三：

```shell
cat /proc/sys/kernel/random/uuid |cut -c 1-8
```

方法四：

```shell
openssl rand -base64 4
```

 

#### （2）获取随机8位数字：

方法一：

```
echo $RANDOM|cksum |cut -c 1-8
```

方法二：

```
openssl rand -base64 4|cksum|cut -c 1-8
```

方法三：

```
date +%N|cut -c 1-8
```

**提示**：cksum：打印CRC效验和统计字节



## 9.2 while循环语句

### 9.2.1 while循环语句语法分析

```shell
语法格式一：
while [条件]
do
	操作
done

语法格式二：
while read line
do
	操作
done  <  file

#通过read命令每次读取一行文件，文件内容有多少行，while循环多少次
```



注意：只有表达式为真，do和done之间的语句才会执行，表达式为假时，结束循环（即条件成立就一直执行循环）

无限循环：

```shell
while true ;do
	echo 'I love you'
done
```



### 9.2.2 使用while循环产生序列

例子：循环输出1到10的数字

```shell
#!/bin/bash

num=1

while [ $num -le 10 ]
do
	echo $num
	num=$(( $num + 1 ))
done
```



**拓展：while读文件并打印文件内容**

```shell
用法一：

while read line
do
	echo $line
done <./a.txt

用法二：
cat ./a.txt|
while read line
do
	echo $line 
done
```



## 9.3 until语句

### 9.3.1 until语句语法分析

```shell
语法格式
until [条件]
do
	操作
done

#注意：重复do和done之间的操作，直到表达式成立为止（即只要条件成立就停止执行循环）
```



### 9.3.2 使用until产生序列实例

```
#!/bin/bash
myvar=1
until [ $myvar -gt 10 ]
do
	echo $myvar
	myvar=$(( $myvar + 1 ))
done
```



## 9.4 循环的控制

```shell
continue 跳过当次循环
break    跳过整个循环
exit     退出脚本
return   退出函数
```

对比break，continue，exit对脚本的影响

```shell
1.break跳过整个循环

#!/bin/bash
for n in 1 2 3 4 5
do
    if [ $n -eq 3  ]
    then
        break
    fi
    echo $n
done
echo ok

输出：
1
2
ok

2.continue跳过当次循环

#!/bin/bash
for n in 1 2 3 4 5
do
    if [ $n -eq 3  ]
    then
        continue
    fi
    echo $n
  ne
echo ok

输出：
1
2
4
5
ok

3.exit退出脚本

#!/bin/bash
for n in 1 2 3 4 5
do
    if [ $n -eq 3  ]
    then
        exit
    fi
    echo $n
done
echo ok

输出:
1
2
```



## 9.5 shell数组

### 9.5.1 数组的定义

数组中可以存放多个值。Bash Shell 只支持一维数组（不支持多维数组），初始化时不需要定义数组大小（与 PHP 类似）。与大部分编程语言类似，数组元素的下标由0开始。

在 Shell 中，用括号**( )**来表示数组，数组元素之间用**空格**来分隔。由此，定义数组的一般形式为：
array=(value01 value02 ... valuen)

> 注意，赋值号=两边不能有空格，必须紧挨着数组名和数组元素。



下面是一个定义数组的实例：

```
nums=(29 100 13 8 91 44)
```

Shell 是弱类型的，它并不要求所有数组元素的类型必须相同，例如：

```
arr=(20 56 "http://www.baidu.com")
```

第三个元素就是一个“异类”，前面两个元素都是整数，而第三个元素是字符串。

Shell 数组的长度**不是固定的**，定义之后还可以增加元素。

例如，对于上面的 nums 数组，它的长度是 6，使用下面的代码会在最后增加一个元素，使其长度扩展到 7：

```
nums[6]=88
```

此外，你也无需逐个元素地给数组赋值，下面的代码就是只给特定元素赋值：

```
ages=([3]=24 [5]=19 [10]=12)
```

以上代码就只给第 3、5、10 个元素赋值，所以数组长度是 3。



### 9.5.2 数组的引用

获取数组元素的值，一般使用下面的格式：

```
${array_name[index]}

array_name为数组的名称
index为属组元素下标
```

其中，array_name 是数组名，index 是下标。例如：

```
n=${nums[2]}
```

表示获取 nums 数组的第二个元素，然后赋值给变量 n。再如：

```
echo ${nums[3]}
```

表示输出 nums 数组的第 3 个元素。

使用

```
@
```

或

```
*
```

可以获取数组中的所有元素，例如：

```
${nums[*]}
或
${nums[@]}
```

两者都可以得到 nums 数组的所有元素。



示例一：

```shell
#!/bin/bash
nums=(29 100 13 8 91 44)
echo ${nums[@]}  #输出所有数组元素
nums[10]=66  #给第10个元素赋值（此时会增加数组长度）
echo ${nums[*]}  #输出所有数组元素
echo ${nums[4]}  #输出第4个元素

运行结果：

29 100 13 8 91 44
29 100 13 8 91 44 66
91
```



示例二：

a) 找出一组数据中的最大数，这组数据用数组保存。

```shell
#!/bin/bash

array=(1 2 3 4 5 6 7 8 9 0 11 10 19 18)

max=${array[0]} 
index=${#array[*]}

for i in `seq 1 $index`
do
	if [  $max -lt  $[array[$i]] ];then
		max=${array[$i]}
	fi
done
echo $max
```



### 9.5.3 数组切片与替换（了解）

**数组切片**

```
array=(1 2 3 4 5)

echo ${array[@]:0:3}	#从第一个元素开始，截取3个

echo ${array[@]:1:4}	#从第二个元素开始，截取4个

echo ${array[@]:0-3:2}	#从倒数第三个元素开始，截取两个

```

**数组替换**

```shell
[root@ mysql-master ~]# array=(1 2 3 4 5)
[root@ mysql-master ~]# echo ${array[@]/3/100}
1 2 100 4 5

[root@ mysql-master ~]# array=(${array[@]/4/200})
[root@ mysql-master ~]# echo ${array[@]}
1 2 3 200 5
```



## 9.6 Shell函数

Shell 函数的本质是一段可以重复使用的脚本代码，这段代码被提前编写好了，放在了指定的位置，使用时直接调取即可。

Shell 中的函数和C++、Java、Python、C# 等其它编程语言中的函数类似，只是在语法细节有所差别。



### 9.6.1 Shell函数的定义

shell中的函数的语法有以下三种：

```shell
方法一：
function 函数名 () {  
        指令...  
}  

方法二：
function 函数名 {  
        指令...  
}  

方法三：简化写法
函数名 () {  
    指令...   
}
```

**Shell函数实例如下**

```shell
function fj () {  
    echo "我是风姐！"  
}  
  
zs () {  
    echo "我是张三！"  
}  
  
fj  
zs
```



### 9.6.2 Shell函数的调用	

调用 Shell 函数时可以给它传递参数，也可以不传递。如果不传递参数，直接给出函数名字即可：

```
name
```

如果传递参数，那么多个参数之间以空格分隔：

```shell
name param1 param2 param3
```

不管是哪种形式，函数名字后面都不需要带括号。

和其它编程语言不同的是，Shell 函数在定义时不能指明参数，但是在调用时却可以传递参数，并且给它传递什么参数它就接收什么参数。

Shell 也不限制定义和调用的顺序，你可以将定义放在调用的前面，也可以反过来，将定义放在调用的后面。

示例：

```shell
#!/bin/bash
input(){
    echo "这是第一个参数：$1"
    echo "这是第二个参数：$2"
    echo "这是第三个参数：$3"
    echo "这是当前脚本名称：$0"
    echo "这是参数总和：$#"
    echo "这是当前脚本的进程号pid：$$"
}
input I love Linux
```

