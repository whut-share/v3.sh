#!/bin/bash

###############  授权信息（需修改成你自己的） ################ 
# cf email
auth_email="456@vip.cn"
# CloudFlare API Key
auth_key="2b96ba25d235ac329c6148bd8edade0c03321"
# cf domain
zone_name="cccc.com"
record_name="aaa.cccc.com"

######################  修改配置信息 ####################### 
# 域名类型，IPv4 为 A，IPv6 则是 AAAA
record_type="A"
# IPv6 检测服务
#ip=$(curl -s https://ipv6.vircloud.net)
# IPv4 检测服务
ip=$(curl -s https://ipv4.vircloud.net)
# 变动前的公网 IP 保存位置
ip_file="/root/ddns/ip.txt"
# 域名识别信息保存位置
id_file="/root/ddns/cloudflare.ids"
# 监测日志保存位置
log_file="/root/ddns/cloudflare.log"

######################  监测日志格式 ######################## 
log() {
    if [ "$1" ]; then
        echo -e "[$(date)] - $1" >> $log_file
    fi
}
log "Check Initiated"

######################  判断 IP 是否变化 #################### 
if [ -f $ip_file ]; then
    old_ip=$(cat $ip_file)
    if [ "$ip" == "$old_ip" ]; then
        echo "IP has not changed."
        exit 0
    fi
fi



######################  获取域名及授权 ###################### 
if [ -f $id_file ] && [ $(wc -l $id_file | cut -d " " -f 1) == 2 ]; then
    zone_identifier=$(head -1 $id_file)
else
    zone_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone_name" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1 )
fi

###################### check if exist ###################3
record_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$record_name&type=$record_type" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*')

if [ -z $record_identifier ]; then
    create=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" --data "{\"type\":\"$record_type\",\"name\":\"$record_name\",\"content\":\"$ip\"}")
    if [[ $create == *"\"success\":false"* ]]; then
        message= "ERROR: Failed to create DNS '$record_type' record '$record_name'. DUMPING RESULTS:\n$create"
        echo -e "$message"
        exit 1 
    else
        message="SUCCESS: create DNS $record_type record $record_name => $ip."
        echo "$ip" > $ip_file
        log "$message"
        echo "$message"
        exit 0
    fi
fi

######################  获取域名及授权 ###################### 
if [ -f $id_file ] && [ $(wc -l $id_file | cut -d " " -f 1) == 2 ]; then
    record_identifier=$(tail -1 $id_file)
else
    zone_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone_name" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1 )
    record_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$record_name&type=$record_type" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*')
    echo "$zone_identifier" > $id_file
    echo "$record_identifier" >> $id_file
fi



######################  更新 DNS 记录 ###################### 
update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" --data "{\"id\":\"$zone_identifier\",\"type\":\"$record_type\",\"name\":\"$record_name\",\"content\":\"$ip\"}")

#########################  更新反馈 ######################### 
if [[ $update == *"\"success\":false"* ]]; then
    message= "ERROR: Failed to update DNS '$record_type' record '$record_name'. DUMPING RESULTS:\n$update"
    log "$message"
    echo -e "$message"
    exit 1 
else
    message="SUCCESS: update DNS '$record_type' record '$record_name' from $old_ip to $ip ."
    echo "$ip" > $ip_file
    log "$message"
    echo "$message"
fi