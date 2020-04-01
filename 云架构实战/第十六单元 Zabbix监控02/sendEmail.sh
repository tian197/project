#!/bin/bash
LOGFILE="/tmp/Email.log"
:>"$LOGFILE"
exec 1>"$LOGFILE"
exec 2>&1
SMTP_server='smtp.163.com'
#改为自己163邮箱地址
username='XXX@163.com'
#改为自己163邮箱的授权码
password='XXX'
from_email_address='XXX@163.com'
to_email_address="$1"
message_subject_utf8="$2"
message_body_utf8="$3"
# 转换邮件标题为GB2312，解决邮件标题含有中文，收到邮件显示乱码的问题。
message_subject_gb2312=`iconv -t GB2312 -f UTF-8 << EOF
$message_subject_utf8
EOF`
[ $? -eq 0 ] && message_subject="$message_subject_gb2312" || message_subject="$message_subject_utf8"
# 转换邮件内容为GB2312，解决收到邮件内容乱码
message_body_gb2312=`iconv -t GB2312 -f UTF-8 << EOF
$message_body_utf8
EOF`
[ $? -eq 0 ] && message_body="$message_body_gb2312" || message_body="$message_body_utf8"
# 发送邮件
sendEmail='/usr/local/bin/sendEmail'
set -x
$sendEmail -s "$SMTP_server" -xu "$username" -xp "$password" -f "$from_email_address" -t "$to_email_address" -u "$message_subject" -m "$message_body" -o message-content-type=text -o message-charset=gb2312
