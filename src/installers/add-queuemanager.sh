sudo su mqm
/opt/mqm/bin/addmqinf -s QueueManager -v Name=sterling -v Directory=sterling -v Prefix=/var/mqm -v DataPath=/MQHA/qmgrs/sterling
/opt/mqm/bin/strmqm -x sterling
exit