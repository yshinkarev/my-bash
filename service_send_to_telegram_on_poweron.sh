#!/bin/bash

SERVICE=send-to-telegram-on-poweron.service
SERVICE_FILE=/etc/systemd/system/$SERVICE

########################################

showHelp() {
cat << EOF
Usage: echo $(basename $0) [COMMAND]
Send message to telegram on power on

  --install     Install service
  --uninstall   Remove service
  --status      Show runtime status of service
  --start       Start service
  --stop        Stop service
EOF
}

########################################

installService() {
SCRIPT=$(readlink -e $0)
echo "  Create file $SERVICE_FILE"
sudo bash -c 'cat << EOF > "'"$SERVICE_FILE"'"
[Unit]
Description=Send to telegram on power on

[Service]
Type=oneshot
ExecStart='$SCRIPT'

[Install]
WantedBy=multi-user.target
EOF'

echo "  Set file permissions"
sudo chmod 644 $SERVICE_FILE

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

send_to_telegram.sh --wait-connect=15 --message="System power on" -q