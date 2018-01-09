#!/bin/bash

SERVICE=send-to-telegram-on-poweron.service

########################################

installService() {
FILE=/etc/systemd/system/$SERVICE
SCRIPT=$0
echo "  Create file $FILE"
sudo bash -c 'cat << EOF > "'"$FILE"'"
[Unit]
Description=Send to telegram on power on

[Service]
Type=oneshot
ExecStart='$SCRIPT'

[Install]
WantedBy=multi-user.target
EOF'

echo "  Set file permissions"
sudo chmod 644 $FILE

echo "  Run daemon-reload"
sudo systemctl daemon-reload

echo "  Enable service"
sudo systemctl enable $SERVICE
}

statusService() {
sudo systemctl status $SERVICE
}

########################################

uninstallService() {
echo "  Stop service"
sudo systemctl stop $SERVICE
echo "  Disable service"
sudo systemctl stop $SERVICE
echo "  Remove service file"
sudo rm /etc/systemd/system/$SERVICE
echo "  Run daemon-reload"
sudo systemctl daemon-reload
echo "  Run reset-failed"
sudo systemctl reset-failed
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
	  esac	 
	done
########################################

/home/schumi/bin/send-to-telegram.sh --wait-connect=15 --message="System power on" -q