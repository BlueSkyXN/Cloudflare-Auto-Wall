#https://github.com/CangShui/clouflarea-auto-firewall
email="6666666@live.com"
globalapi="876666627b"
rulesid1="1146666665"
rulesid2="c8666666ce"
zoneid="f266666c18"
maxload="5" #范围0~10.设置10即为满载时开盾，5即一半负载时开盾
keeptime=1200  #可访问后持续多少秒，进行尝试关盾
cfile="/home/cf_uptime/"
lasttime=$( cat $cfile"xtime.txt" 2>/dev/null )
#==================================================#
mkdir "$cfile" 2>/dev/null
cpu_num=$( grep -c 'model name' /proc/cpuinfo ) #cpu总核数 
cpu_load=$( uptime | awk '{print $10}' | awk '{sub(/.$/,"")}1' ) #系统1分钟的平均负载 
cpu_load=$(echo "$cpu_load * 100" | bc | awk '{print int($0)}' )
cpu_maxload=`expr $cpu_num \* $maxload \* 10`
nowtime=$(date +%s)
echo -e "cpu_load数值为：$cpu_load ，cpu_maxload数值为：$cpu_maxload"
if [[ $lasttime -eq "" ]]
then
  echo -e "未开验证码"
else  
  echo -e "数据正常"
  gaptime=`expr $nowtime - $lasttime`
  echo -e "距离上次开盾已经：$gaptime S ，上次时间为：$lasttime"
fi
if [[ $cpu_load -gt $cpu_maxload ]]&&[[ $lasttime -eq "" ]]
then
     echo "一分钟平均负载已超过阈值，开验证码"
	 curl -X PUT \
     -H "X-Auth-Email: $email" \
     -H "X-Auth-Key: $globalapi" \
     -H "Content-Type: application/json" \
     -d '{
	  "id": "$rulesid1",
      "paused": false,
      "description": "全部都验证码",
      "action": "challenge",
      "priority": 1000,
	  "filter": {
        "id": "'$rulesid2'"
      }
     }' "https://api.cloudflare.com/client/v4/zones/$zoneid/firewall/rules/$rulesid1"
        rm -rf $cfile"xtime.txt"
		lasttime=$(date +%s)
        echo $lasttime >> $cfile"xtime.txt"
        echo -e "\n开验证码成功"
else
        if [[ $cpu_load -lt $cpu_maxload ]]&&[[ $gaptime -ge $keeptime ]]
        then
          echo -e "\n开盾时间已有$gaptime，超过$keeptime，且一分钟平均负载已低于阈值，尝试关盾"
          	curl -X PUT \
           -H "X-Auth-Email: $email" \
           -H "X-Auth-Key: $globalapi" \
     	   -H "Content-Type: application/json" \
           -d '{
     	   "id": "$rulesid1",
           "paused": true,
           "description": "全部都验证码",
           "action": "challenge",
           "priority": 1000,
       	    "filter": {
            "id": "'$rulesid2'"
             }
            }' "https://api.cloudflare.com/client/v4/zones/$zoneid/firewall/rules/$rulesid1"
            rm -rf $cfile"xtime.txt"
        else
           if [[ $cpu_load -ge $cpu_maxload ]]&&[[ $gaptime -ge $keeptime ]]
           then
           echo -e "\n开盾时间已有$gaptime，超过$keeptime，但是负载仍然较高暂不关验证码，请自行排查原因"
           else         		      
			  if [[ $lasttime -eq "" ]]
              then
			  echo -e ""
              else  
              echo -e "\n开盾时间有$gaptime，未超过$keeptime，不关验证码或无需开验证码" 
              fi			  
           fi
        fi
fi
