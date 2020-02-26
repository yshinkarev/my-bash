#!/usr/bin/env bash

VERSION=$1
if [ -z "$VERSION" ]; then
	>&2 echo "Missing argument VERSION (example: 5.9)"
	exit 1
fi

COMMAND=$2
if [ -z "$COMMAND" ]; then
	>&2 echo "Missing argument COMMAND (--install, --clean, --getupdates)"
	exit 1
fi

########################################

install() {
	echo "************* git clone *************"
	git clone https://code.qt.io/qt/qt5.git
	cd qt5
	echo "************* checkout $VERSION *************"
	git checkout $VERSION
	echo "************* perl init-repository *************"
	perl init-repository
	echo "************* configure *************"
	./configure -developer-build -opensource -nomake examples -nomake tests
	echo "************* make *************"
	make -j4
	echo "************* checkinstall *************"
	sudo checkinstall --install=no make install prefix=/usr
}

########################################

clean() {
	git submodule foreach --recursive "git clean -dfx" && git clean -dfx
}

########################################

getUpdates() {
	git pull
	perl init-repository -f
}

########################################

case "$1" in
	--install)
		install
		;;
	--clean)
		clean
		;;
	--getUpdates)
		getupdates
		;;
	*)
		>&2 echo "Unknown COMMAND"
	   	;;
esac