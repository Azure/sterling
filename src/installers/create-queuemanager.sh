sudo su mqm
/opt/mqm/bin/crtmqm -ld /MQHA/logs -md /MQHA/qmgrs sterling
/opt/mqm/bin/strmqm -x sterling
exit