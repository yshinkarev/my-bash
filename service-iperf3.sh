#!/bin/bash

SERVICE=iperf3.service
SERVICE_FILE=/etc/systemd/system/$SERVICE
LOGROTATE_FILE=/etc/logrotate.d/iperf3
LOG_FILE=/var/log/iperf3.log

########################################

showHelp() {
cat << EOF
Usage: echo $(basename $0) [COMMAND]
Run iperf3 as service

  --install     Install iperf3 service
  --uninstall   Remove iperf3 service
  --status      Show runtime status of iperf3 service
  --start       Start iperf3 service
  --stop        Stop iperf3 service
EOF
}

########################################

installService() {
which iperf3 >/dev/null
if [ $? -ne 0 ]; then
	echo "  iperf3 does not installed. Install"
	sudo apt install iperf3
	if [ $? -ne 0 ]; then
		echo "  Something wrong. Exit"
    		exit 1
    	fi
fi

SCRIPT=$(readlink -e $0)
echo "  Create file $SERVICE_FILE"
sudo bash -c 'cat << EOF > "'"$SERVICE_FILE"'"
[Unit]
Description=iperf3 service

[Service]
Type=simple
ExecStart='$SCRIPT'
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF'

echo "  Add logrotate rule $LOGROTATE_FILE"
sudo bash -c 'cat << EOF > "'"$LOGROTATE_FILE"'"
/var/log/iperf3*.log {
        daily
        missingok
        rotate 7
        compress
        delaycompress
        notifempty
        create 640 root adm
        endscript
}
EOF'

echo "  Set files permissions"
sudo chmod 644 $SERVICE_FILE
sudo chmod 644 $LOGROTATE_FILE

echo "  Run daemon-reload"
sudo systemctl daemon-reload

echo "  Enable service"
sudo systemctl enable $SERVICE
}

########################################

statusService() {
sudo systemctl status $SERVICE
}

########################################

uninstallService() {
echo "  Stop service"
sudo systemctl stop $SERVICE
echo "  Disable service"
sudo systemctl stop $SERVICE
echo "  Remove files"
sudo rm $SERVICE_FILE
sudo rm /var/log/iperf3*
echo "  Run daemon-reload"
sudo systemctl daemon-reload
echo "  Run reset-failed"
sudo systemctl reset-failed
}

########################################

startService() {
sudo systemctl start $SERVICE
}

########################################

stopService() {
sudo systemctl stop $SERVICE
}

########################################

for arg in "$@"; do
	case $arg in
	    --install)
	  	installService
	  	exit 0
	  	;;
	    --uninstall)
	  	uninstallService
	  	exit 0
	  	;;
	    --status)
	  	statusService
	  	exit 0
	  	;;
	    --start)
	  	startService
	  	exit 0
	  	;;
	    --stop)
	  	stopService
	  	exit 0
	  	;;
	    --help)
		showHelp
		exit 0
		;;
	    *)
	      echo "Unknown argument: $arg"
	      showHelp
	      exit 1
	  esac
	done
########################################

stdbuf -oL iperf3 --server --format M >> $LOG_FILE