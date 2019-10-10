#!/bin/bash

. release
name=json
targetname="$MOD_NAME-$MOD_VERSION"
moddir=./target/exploded/$MOD_NAME
#moddir=./target/exploded
extension=""
case "$OSTYPE" in
	linux*)	system="lin"
		;;
	darwin*)
		system="mac"
		;;
	*)	system="win"
		extension=".exe"
		;;
esac
if [[ "$PROCESSOR_ARCHITECTURE" == "AMD64" && -f "./main/bin/weidu-$system-amd64$extnesion" ]]; then
	system="$system-amd64"
else
	system="$system-x86"
fi	


case "$#" in
	0)
		eval "$0 package"
		exit $?
		;;
	*)
		case "$1" in
			package)
				echo "Copying files..."
				rm -rf ./target
				mkdir -p ./target/exploded
				cp -a ./main/src/ "$moddir"
				tar -czf ./target/$targetname.tgz -C ./target/exploded .
				;;

			test)
				$0 package
				for GAMEDIR in "test/Baldur's Gate" "test/Baldur's Gate EE" "test/Siege of Dragonspear" "test/Baldur's Gate 2" "test/Baldur's Gate 2 EE" "test/Icewind Dale" "test/Icewind Dale EE"; do
					if [[ -d "$GAMEDIR" ]]; then
						if [[ -f "$GAMEDIR/setup-$name-test.tp2" ]]; then
							cd "$GAMEDIR"
							"./setup-$name-test$extension" --uninstall
							cd -
						fi
						if [[ ! -d "$GAMEDIR/$name-test" ]]; then
							mkdir "$GAMEDIR/$name-test"
						fi

						cp -a ./test/src/* "$GAMEDIR/$name-test"
						cp $moddir/* "$GAMEDIR/$name-test"
						cp ./bin/weidu-$system$extension "$GAMEDIR/setup-$name-test$extension"
						cd "$GAMEDIR"
						"./setup-$name-test$extension" --yes
						if [[ "$?" != 0 ]]; then 
							cd -
							exit $?
						fi
						"./setup-$name-test$extension" --uninstall
						cd -
						break
					fi
				done
				;;
			clean)
				rm -rf ./target
				;;
			
			*)
				echo "Usage: $0 [-h|clean|package|test]"
		esac
		;;
esac





