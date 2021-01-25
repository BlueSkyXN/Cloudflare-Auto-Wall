email="77@live.com"
globalapi="77a7727b"
rulesid1="114772905"
rulesid2="7707777ce"
zoneid="77777718"
keeptime=1200  #可访问后持续多少秒，进行尝试关盾
curlnum=5      #测试多少次网站状态码，不建议高于10，数值越高网站压力越大
minsuc=4    #网站至少正常访问多少次，否则就开验证码
cfile="/home/cf_curl_code/"
lasttime=$( cat $cfile"xtime.txt" 2>/dev/null )
webhost="cangshui.com"  #你的网站域名
curlnum="5"
#==================================================#
#http状态返回404即正常,因为curl的地址是一个网站+随机字符+.html，状态返回403即为开盾状态，返回500-600为错误代码
mkdir "$cfile" 2>/dev/null
rm -rf $cfile$webhost".log"
i="1"
while [ $i -le $curlnum ]
do
i=$(($i+1))
randtxt=$( cat /dev/urandom | head -n 30 | md5sum | head -c 30 2>/dev/null )
echo "开始测试访问https://"$webhost"/"$randtxt".html"
code=$( curl -I -m 10 -o /dev/null -s -w %{http_code} "https://"$webhost"/"$randtxt".html" )
echo $code >> $cfile$webhost".log"
sleep 2s
done


num404=$( grep -c "404" $cfile$webhost".log" )
if [[ $num404 -ge $minsuc ]]
then
  echo -e "网站访问正常"  && exit
else 
  sed -i 's/404//g'  $cfile$webhost".log"
  sed -i '/^$/d' $cfile$webhost".log"
  httpcode=$( sed -n 1p $cfile$webhost".log" )
fi

nowtime=$(date +%s)
if [[ $lasttime -eq "" ]]&&[[ $httpcode -eq "403" ]]
then
  echo -e "验证码已开启，但未有开启时间记录"
  lasttime=$(date +%s)
  echo $lasttime >> $cfile"xtime.txt"
  gaptime=0
else  
  echo -e "数据正常"
  gaptime=`expr $nowtime - $lasttime`
  echo -e "距离上次开盾已经：$gaptime S ，上次时间为：$lasttime"
fi

if [[ $httpcode > "499" ]]&&[[ $httpcode < "600" ]]
then
     echo "\n状态码大于500，开验证码"
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
     sleep 15s
	 randtxt=$( cat /dev/urandom | head -n 30 | md5sum | head -c 30 2>/dev/null )
     httpcode2=$( curl -I -m 10 -o /dev/null -s -w %{http_code} "https://"$webhost"/"$randtxt".html" )
        if [ $httpcode2 = "403" ]
        then
          lasttime=$(date +%s)
          rm -rf $cfile"xtime.txt"
          echo $lasttime >> $cfile"xtime.txt"
          echo -e "\n开验证码成功"
        else
          echo -e "\n开验证码失败，可能是暂未生效"
        fi
else
        if [[ $httpcode -eq "403" ]]&&[[ $gaptime -ge $keeptime ]]
        then
          echo -e "\n开盾时间已有$gaptime，超过$keeptime，尝试关盾"
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
           echo -e "\n开盾时间有$gaptime，未超过$keeptime或未开盾" 
        fi
fi
