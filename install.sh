#!/bin/bash
VER=9.10
#DEBUGINSTALL=1
PACKAGES_NEEDED="dnsutils git tcl8.6-dev tcllib autoconf bc curl diffutils ftp libflac-dev libssl-dev lm-sensors lynx make mariadb-server mkvtoolnix ncftp passwd rsync smartmontools tcl tcl-dev tcl-tls tcpd wget zip"
BINARY_NEEDED="lynx wget tar tcpd gcc openssl dig nslookup cc"
clear
if [ ! "$(whoami)" = "root" ] 
then echo "The installer should be run as root"; exit 0; fi
# verification
for pkg in $PACKAGES_NEEDED; do
	if apt-get -qq install $pkg; then
		echo "Successfully installed $pkg"
	else
		echo "Error installing $pkg"
		exit
	fi
done

for cmd in $BINARY_NEEDED; do
	if ! command -v "$cmd" &> /dev/null
	then
		echo "$cmd need be installed"
		exit
	fi
done

function FCT_CreateDir {
	if [ -d "$1" ]
	then
		rm -rf "$1"
	fi
	mkdir -p "$1"
}

FCT_CreateDir ".tmp"

until [ -n "$glroot" ]; do
	echo -n "Please enter the private directory to install glftpd [/glftpd]: "
	read -r glroot
	case $glroot in
		/)
			echo "You can't have / as your private dir!  Try again."
			echo ""
			unset glroot
			continue
		;;
		/*|"")
		[ -z "$glroot" ] && glroot="/glftpd"
			[ -d "$glroot" ] && {
				echo -n "Path already exists. [D]elete it, [A]bort, [T]ry again, [I]gnore? "
				read -r reply
				case $reply in
					[dD]*) rm -rf "$glroot" ;;
					[tT]*) unset glroot; continue ;;
					[iI]*) ;;
					*) echo "Aborting."; exit 1 ;;
				esac
			}
			FCT_CreateDir "$glroot"
			continue
		;;
		*)
			echo "The private directory must start with a \"/\".  Try again."
			echo ""
			unset glroot
			continue
		;;
	esac
done 
# Export for install.sh glftpd
export glroot

clear

echo "Welcome to the glFTPD installer v$VER"
echo
echo "Disclaimer:" 
echo "This software is used at your own risk!"
echo "The author of this installer takes no responsibility for any damage done to your system."
echo
echo -n "Have you read and installed the Requirements in README.MD ? [Y]es [N]o, default N : " ; read -r requirement
echo
case $requirement in
	[Yy]) ;;
	[Nn]) rm -r .tmp ; exit 1 ;;
	*)  rm -r .tmp ; exit 1 ;;
esac

if [ "$(echo "$PATH" | grep -c /usr/sbin)" = 0 ]
then 
	echo "/usr/sbin not found in environmental PATH" 
	echo "Default PATH should be : /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
	echo "Current PATH is : $PATH"
	echo "Correcting PATH"
	export PATH=$PATH:/usr/sbin
	echo "Done"
	echo
fi

rootdir=$(pwd)
cache="$rootdir/install.cache"

# clean up comments and trailing spaces in install.cache to avoid problems with unattended installation
if [ -f "$cache" ]
then
	sed -i -e 's/" #.*/"/g' -e 's/^#.*//g' -e '/^\s*$/d' -e 's/[ \t]*$//' "$cache"
fi


function start
{
		echo "--------[ Server configuration ]--------------------------------------"
	echo
	if [[ -f "$cache" && "$(grep -c -w sitename "$cache")" = 1 ]]
	then
		sitename=$(grep -w sitename "$cache" | cut -d "=" -f2 | tr -d "\"")
	return
	fi
	
	echo
	while [[ -z $sitename ]]
	do
		echo -n "Please enter the name of the site, without space : " ; read -r sitename
	done
	# replace space by _
	sitename=${sitename// /_}
	
	if [ ! -f "$cache" ]
	then
		echo sitename=\""$sitename"\" > "$cache"
	fi
}

function port
{
	if [[ -f "$cache" && "$(grep -c -w port "$cache")" = 1 ]]
	then
		port=$(grep -w port "$cache" | cut -d "=" -f2 | tr -d "\"")
	else
		echo -n "Please enter the port number for your site, default 2010 : " ; read -r port
		
		if [ "$port" = "" ] 
		then
			port="2010"
		fi
		
		if [ "$(grep -c -w port= "$cache")" = 0 ]
		then
			echo port=\"$port\" >> "$cache"
		fi
	fi
}

function version
{
	if [[ -f "$cache" && "$(grep -c -w versionbranch "$cache")" = 1 ]]
	then
		versionbranch=$(grep -w versionbranch "$cache" | cut -d "=" -f2 | tr -d "\"")
	else
		echo -n "Install stable or beta version of glFTPD ? [stable] [beta], default stable : " ; read -r versionbranch
	fi
	if [ "$versionbranch" = "" ] ||  [ "$versionbranch" = "stable" ] 
	then
		versionbranch="latest stable version"
	else
		versionbranch="The latest version"
	fi

	
	if [[ -f "$cache" && "$(grep -c -w version "$cache")" = 1 ]]
	then
		version=$(grep -w version "$cache" | cut -d "=" -f2 | tr -d "\"")
	else
		echo -n "Install 32 or 64 bit version of glFTPD ? [32] [64], default 64 : " ; read -r version
	fi
	case $version in
		32)
			
		;;
		64)
			
		;;
		*)
			version="64"
		;;
	esac
	latest=$(lynx --dump https://glftpd.io | grep "$versionbranch" | cut -d ":" -f2 | sed -e 's/20[1-9][0-9].*//' -e 's/^  //' -e 's/^v//' | tr "[:space:]" "_" | sed 's/_$//')
	PK1="$(wget -q -O - https://glftpd.io/files/ | grep "LNX-$latest.*x$version.*" | grep -o -P '(?=glftpd).*(?=.tgz">)').tgz"
	if [ -f packages/"$PK1" ] ; then
		rm packages/"$PK1"
	fi
	
	echo -n "Downloading relevant packages, please wait...                   "
	wget -q https://glftpd.io/files/"$PK1" -O packages/"$PK1"
	echo -e "[\e[32mDone\e[0m]"
	PK1DIR="${PK1//.tgz/}"
	PK2DIR="pzs-ng"
	PK3DIR="eggdrop"
	UP="tar xf"
	BOTU="sitebot"
	
	CHKGR=$(grep -w "glftpd" /etc/group | cut -d ":" -f1)
	CHKUS=$(grep -w "sitebot" /etc/passwd | cut -d ":" -f1)
	
	if [ "$CHKGR" != "glftpd" ] 
	then
		groupadd glftpd -g 199
		#echo "Group glftpd added"
	fi
	
	if [ "$CHKUS" != "sitebot" ] 
	then
		useradd -d $glroot/sitebot -m -g glftpd -s /bin/bash $BOTU
		chfn -f 0 -r 0 -w 0 -h 0 $BOTU
		#echo "User $BOTU added"
	fi 
	
	cd packages || exit
	echo -n "Extracting the Source files, please wait...                     "
	$UP "$PK1" && rm "$PK1"
	git clone https://github.com/pzs-ng/pzs-ng >/dev/null 2>&1
	git clone https://github.com/eggheads/eggdrop >/dev/null 2>&1
	echo -e "[\e[32mDone\e[0m]"
	echo
	FCT_CreateDir source
	cp -R scripts source
	cd ..
	
	if [ "$(grep -c -w version= "$cache")" = 0 ]
	then
		echo version=\"$version\" >> "$cache"
	fi
	cp -f "$rootdir/packages/data/cleanup.sh" "$rootdir"
}

function device_name
{
	if [[ -f "$cache" && "$(grep -c -w device "$cache")" = 1 ]]
	then
		device=$(grep -w device "$cache" | cut -d "=" -f2 | tr -d "\"")
		echo "Sitename           = $sitename"
		echo "Port               = $port"
		echo "glFTPD version     = $version" 
		echo "Device             = $device"
	else
		echo "Please enter which device you will use for the $glroot/site folder"
		echo "eg /dev/sda1"
		echo "eg /dev/mapper/lvm-lvm"
		echo "eg /dev/md0"
		echo "Default: /dev/sda1"
		echo -n "Device : " ; read -r device
		echo
	
		if [ "$device" = "" ] 
		then
			device="/dev/sda1"
		fi
	
	fi
	cp packages/scripts/tur-space/tur-space.conf packages/scripts/tur-space/tur-space.conf.new
		printf '%s\n' \
				'[TRIGGER]'                     \
				"TRIGGER=$device:25000:50000"   \
				''                              \
				'[INCOMING]'                    \
		>> packages/scripts/tur-space/tur-space.conf.new

	
	if [ "$(grep -c -w device= "$cache")" = 0 ]
	then
		echo device=\"$device\" >> "$cache"
	fi
}

function channel
{
	FCT_CreateDir ".tmp"
		if [[ -f "$cache" && "$(grep -c -w ircserver "$cache")" = 1 ]]
		then
				ircserver=$(grep -w ircserver "$cache" | cut -d "=" -f2 | tr -d "\"")
				echo -n "Irc server         = $ircserver"
		fi
	
	if [[ -f "$cache" && "$(grep -c -w channelnr "$cache")" = 1 ]]
	then
		echo
		channelnr=$(grep -w channelnr "$cache" | cut -d "=" -f2 | tr -d "\"")
	else
		while [[ -z $channelnr || $channelnr -gt 15 ]]
		do
			echo -n "How many channels do you require the bot to be in (max 15)? : " ; read -r channelnr
		done
	fi
	
	counta=0
	
	
	if [ "$(grep -c -w channelnr= "$cache")" = 0 ]
	then
		echo channelnr=\""$channelnr"\" >> "$cache"
	fi
	
	while [ $counta -lt "$channelnr" ] 
	do
		if [[ -f "$cache" && "$(grep -c -w "channame$((counta+1))" "$cache")" = 1 ]]
		then
			channame=$(grep -w "channame$((counta+1))" "$cache" | cut -d "=" -f2 | tr -d "\"" | cut -d " " -f1)
			echo "Channel $((counta+1))          = $channame"
		else	
			echo "Include # in name of channel ie #main"
			while [[ -z $channame ]] 
			do
				echo -n "Channel $((counta+1)) is : " ; read -r channame
			done
		fi
		
		if [[ -f "$cache" && "$(grep -c -w "channame$((counta+1))" "$cache")" = 1 ]]
		then
			chanpasswd=$(grep -w "channame$((counta+1))" "$cache" | cut -d "=" -f2 | tr -d "\"" | cut -d " " -f2)
			echo "Requires password  = $chanpasswd"
		else
			echo -n "Channel password ? [Y]es [N]o, default N : " ; read -r chanpasswd
		fi
		
		case $chanpasswd in
		[Yy])
				if [[ -f "$cache" && "$(grep -c -w "announcechannels" "$cache")" = 1 ]]
				then
						echo "Channel mode       = password protected"
				fi
		
		if [[ -f "$cache" && "$(grep -c -w "channame$((counta+1))" "$cache")" = 1 ]]
		then
			chanpassword=$(grep -w "channame$((counta+1))" "$cache" | cut -d "=" -f2 | tr -d "\"" | cut -d " " -f3)
			echo "Channel password   = $chanpassword"
		else
			while [[ -z $chanpassword ]]
			do
				echo -n "Enter the channel password : " ; read -r chanpassword
			done
		fi
			echo "channel set $channame chanmode {+ntpsk $chanpassword}" >> "$rootdir/.tmp/bot.chan.tmp"
			echo "channel add $channame {" >> "$rootdir/.tmp/eggchan"
			echo "idle-kick 0" >> "$rootdir/.tmp/eggchan"
			echo "stopnethack-mode 0" >> "$rootdir/.tmp/eggchan"
			echo "flood-chan 0:0" >> "$rootdir/.tmp/eggchan"
			echo "flood-join 0:0" >> "$rootdir/.tmp/eggchan"
			echo "flood-ctcp 0:0" >> "$rootdir/.tmp/eggchan"
			echo "flood-kick 0:0" >> "$rootdir/.tmp/eggchan"
			echo "flood-deop 0:0" >> "$rootdir/.tmp/eggchan"
			echo "flood-nick 0:0" >> "$rootdir/.tmp/eggchan"
			echo "aop-delay 0:0" >> "$rootdir/.tmp/eggchan"
			echo "chanmode \"+ntsk $chanpassword\"" >> "$rootdir/.tmp/eggchan"
			echo "}" >> "$rootdir/.tmp/eggchan"
			echo "" >> "$rootdir/.tmp/eggchan"
			echo "$channame" >> "$rootdir/.tmp/channels"
		
			if [ "$(grep -c -w channame$((counta+1))= "$cache")" = 0 ]
			then
				echo "channame$((counta+1))=\"$channame $chanpasswd $chanpassword\"" >> "$cache"
			fi
			
			;;
			[Nn])
			if [[ -f "$cache" && "$(grep -c -w "announcechannels" "$cache")" = 1 ]]
			then
				echo "Channel mode       = invite only"
			fi

			echo "channel set $channame chanmode {+ntpsi}" >> "$rootdir/.tmp/bot.chan.tmp"
			echo "channel add $channame {" >> "$rootdir/.tmp/eggchan"
			echo "idle-kick 0" >> "$rootdir/.tmp/eggchan"
			echo "stopnethack-mode 0" >> "$rootdir/.tmp/eggchan"
			echo "flood-chan 0:0" >> "$rootdir/.tmp/eggchan"
			echo "aop-delay 0:0" >> "$rootdir/.tmp/eggchan"
			echo "chanmode +ntsi" >> "$rootdir/.tmp/eggchan"
			echo "}" >> "$rootdir/.tmp/eggchan"
			echo "" >> "$rootdir/.tmp/eggchan"
			echo "$channame" >> "$rootdir/.tmp/channels"
			
			if [ "$(grep -c -w channame$((counta+1))= "$cache")" = 0 ]
			then
				echo "channame$((counta+1))=\"$channame n nopass\"" "$cache"
			fi
		
			;;
			*)
						if [[ -f "$cache" && "$(grep -c -w "announcechannels" "$cache")" = 1 ]]
						then
								echo "Channel mode       = invite only"
						fi
			echo "channel set $channame chanmode {+ntpsi}" >> "$rootdir/.tmp/bot.chan.tmp"
			echo "channel add $channame {" >> "$rootdir/.tmp/eggchan"
			echo "idle-kick 0" >> "$rootdir/.tmp/eggchan"
			echo "stopnethack-mode 0" >> "$rootdir/.tmp/eggchan"
			echo "flood-chan 0:0" >> "$rootdir/.tmp/eggchan"
			echo "aop-delay 0:0" >> "$rootdir/.tmp/eggchan"
			echo "chanmode +ntsi" >> "$rootdir/.tmp/eggchan"
			echo "}" >> "$rootdir/.tmp/eggchan"
			echo "" >> "$rootdir/.tmp/eggchan"
			echo "$channame" >> "$rootdir/.tmp/channels"
			
			if [ "$(grep -c -w channame$((counta+1))= "$cache")" = 0 ]
			then
				echo "channame$((counta+1))=\"$channame n nopass\"" >> "$cache"
			fi
			
			;;
		esac
		channame=""
		chanpasswd=""
		((counta++))
	done

}

function announce
{
	sed -i -e :a -e N -e 's/\n/ /' -e ta "$rootdir/.tmp/channels"
	if [[ -f "$cache" && "$(grep -c -w announcechannels "$cache")" = 1 ]]
	then
		announcechannels=$(grep -w announcechannels "$cache" | cut -d "=" -f2 | tr -d "\"")
		echo "Announce channels  = $announcechannels"
	else
		echo -n "Which should be announce channels,  default: $(cat "$rootdir/.tmp/channels") : " ; read -r announcechannels
	fi
	
	if [ "$announcechannels" = "" ] 
	then
		announcechannels=$(cat "$rootdir/.tmp/channels")
		cat "$rootdir/.tmp/channels" > "$rootdir/.tmp/dzchan"
	
		if [ "$(grep -c -w announcechannels= "$cache")" = 0 ]
		then
			echo "announcechannels=\"$(cat "$rootdir/.tmp/channels")\"" >> "$cache"
		fi
		
	else 
		echo "$announcechannels" > "$rootdir/.tmp/dzchan"
	
		if [ "$(grep -c -w announcechannels= "$cache")" = 0 ]
		then
			echo "announcechannels=\"$announcechannels\"" >> "$cache"
		fi
	
	fi
}

function opschan
{
	if [[ -f "$cache" && "$(grep -c -w channelops "$cache")" = 1 ]]
	then
		channelops=$(grep -w channelops "$cache" | cut -d "=" -f2 | tr -d "\"")
		echo "Ops channel        = $channelops"
	else
		echo "Channels: $(cat "$rootdir/.tmp/channels")"
		while [[ -z $channelops ]]
		do
			echo -n "Which of these channels as ops channel ? : " ; read -r channelops
		done
	fi
	
	echo "$channelops" > "$rootdir/.tmp/dzochan"
	
	if [ "$(grep -c -w channelops= "$cache")" = 0 ]
	then
		echo "channelops=\"$channelops\"" >> "$cache"
	fi
	
	rm "$rootdir/.tmp/channels"
}

function ircnickname
{
	if [[ -f "$cache" && "$(grep -c -w ircnickname "$cache")" = 1 ]]
	then
		ircnickname=$(grep -w ircnickname "$cache" | cut -d "=" -f2 | tr -d "\"")
		echo "Nickname           = $ircnickname"
	else	
		while [[ -z $ircnickname ]] 
		do
			echo -n "What is your nickname on irc ? ie l337 : " ; read -r ircnickname
		done
	fi
	
	if [ "$(grep -c -w ircnickname= "$cache")" = 0 ]
	then
		echo "ircnickname=\"$ircnickname\"" >> "$cache"
	fi
}

## how many sections
function section_names
{
	FCT_CreateDir ".tmp"
	if [[ -f "$cache" && "$(grep -c -w sections "$cache")" = 1 ]]
	then
		sections=$(grep -w sections "$cache" | cut -d "=" -f2 | tr -d "\"")
	else
		echo
		echo "Valid Sections are : "
		echo "0DAY ANIME APPS DVDR EBOOKS FLAC GAMES MP3 MBLURAY MVDVDR NSW PDA PS4 TV-HD TV-NL TV-SD X264 X265-2160 XVID XXX XXX-PAYSITE"
		echo
		while [[ -z $sections || $sections -gt 20 ]]
		do
			echo -n "How many sections do you require for your site (max 20)? : " ; read -r sections
		done
		echo
	fi
	
	cp packages/scripts/tur-rules/tur-rules.sh.org packages/scripts/tur-rules/tur-rules.sh
	packages/scripts/tur-rules/rulesgen.sh GENERAL
	cp packages/scripts/tur-autonuke/tur-autonuke.conf.org packages/scripts/tur-autonuke/tur-autonuke.conf
	cp packages/data/dated.sh.org "$rootdir/.tmp/dated.sh"
	counta=0
	
	if [ "$(grep -c -w sections= "$cache")" = 0 ]
	then
		echo sections=\""$sections"\" >> "$cache"
	fi
	
	while [ $counta -lt "$sections" ] 
	do
		section_generate
		((counta++))
	done
}

## which Sections
function section_generate
{
	if [[ -f "$cache" && "$(grep -c -w "section$((counta+1))" "$cache")" = 1 ]]
	then
		section=$(grep -w "section$((counta+1))" "$cache" | cut -d "=" -f2 | tr -d "\"")
	else
		echo -n "Section $((counta+1)) is : " ; read -r section
	fi
	case ${section^^} in
		0DAY|ANIME|APPS|DVDR|EBOOKS|FLAC|GAMES|MP3|MBLURAY|MVDVDR|NSW|PDA|PS4|TV-HD|TV-NL|TV-SD|X264|X265-2160|XVID|XXX|XXX-PAYSITE)
		writ
		;;
		*)
		while [[ ${section^^} != @(0DAY|ANIME|APPS|DVDR|EBOOKS|FLAC|GAMES|MP3|MBLURAY|MVDVDR|NSW|PDA|PS4|TV-HD|TV-NL|TV-SD|X264|X265-2160|XVID|XXX|XXX-PAYSITE) ]]
		do
			echo "Section [$section] is not in the above list of available sections, please try again."
			echo -n "Section $((counta+1)) is : " ; read -r section
		done
		;;
	esac
}

## TMP_dZSbot.tcl_Config
function writ
{
	section=${section^^}
	if [[ ${section^^} = 0DAY || ${section^^} = FLAC || ${section^^} = MP3 || ${section^^} = EBOOKS ]] 
	then
	
		FCT_CreateDir "$rootdir/.tmp/site/${section^^}"
		chmod 777 "$rootdir/.tmp/site/${section^^}"
		echo "${section^^} " > "$rootdir/.tmp/.section" && cat "$rootdir/.tmp/.section" >> "$rootdir/.tmp/.sections"
		awk -F '[" "]+' '{printf $0}' "$rootdir/.tmp/.sections" > "$rootdir/.tmp/.validsections"
		#echo "set statsection($counta) \"${section^^}\"" >> $rootdir/.tmp/dzsstats
		echo "set paths(${section^^})				\"/site/${section^^}/*/*\"" >> "$rootdir/.tmp/dzsrace"
		echo "set chanlist(${section^^}) 			\"$announcechannels\"" >> "$rootdir/.tmp/dzschan"
		#echo "#stat_section 	${section^^}	/site/${section^^}/* no" >> $rootdir/.tmp/glstat
				printf '%s\n' \
						"section.${section^^}.name=${section^^}"                \
						"section.${section^^}.dir=/site/${section^^}/MMDD"      \
						"section.${section^^}.gl_credit_section=0"              \
						"section.${section^^}.gl_stat_section=0"                \
				>> "$rootdir/.tmp/footools"

		sed -i "s/\bDIRS=\"/DIRS=\"\n\/site\/${section^^}\/\$today/" packages/scripts/tur-autonuke/tur-autonuke.conf
		sed -i "s/\bDIRS=\"/DIRS=\"\n\/site\/${section^^}\/\$yesterday/" packages/scripts/tur-autonuke/tur-autonuke.conf
		echo "INC${section^^}=$device:$glroot/site/${section^^}:DATED" >> packages/scripts/tur-space/tur-space.conf.new
		echo "$glroot/site/${section^^}" >> "$rootdir/.tmp/.fullpath"
	
		if [[ ${section^^} = FLAC || ${section^^} = MP3 ]] 
		then
			echo "/site/${section^^}/ " > "$rootdir/.tmp/.section" && cat "$rootdir/.tmp/.section" >> "$rootdir/.tmp/.temp"
			awk -F '[" "]+' '{printf $0}' "$rootdir/.tmp/.temp" > "$rootdir/.tmp/.path"
		fi
		
		if [ "$(grep -c -w section$((counta+1))= "$cache")" = 0 ]
		then
			echo "section$((counta+1))=\"$section\"" >> "$cache"
		fi
	
	else
	
		FCT_CreateDir "$rootdir/.tmp/site/${section^^}"
		chmod 777 "$rootdir/.tmp/site/${section^^}"
		echo "${section^^} " > "$rootdir/.tmp/.section" && cat "$rootdir/.tmp/.section" >> "$rootdir/.tmp/.sections"
		awk -F '[" "]+' '{printf $0}' "$rootdir/.tmp/.sections" > "$rootdir/.tmp/.validsections"
		#echo "set statsection($counta) \"${section^^}\"" >> $rootdir/.tmp/dzsstats
		echo "set paths(${section^^}) 			\"/site/${section^^}/*\"" >> "$rootdir/.tmp/dzsrace"
		echo "set chanlist(${section^^}) 			\"$announcechannels\"" >> "$rootdir/.tmp/dzschan"
		echo "/site/${section^^}/ " > "$rootdir/.tmp/.section" && cat "$rootdir/.tmp/.section" >> "$rootdir/.tmp/.temp"
		awk -F '[" "]+' '{printf $0}' "$rootdir/.tmp/.temp" > "$rootdir/.tmp/.path"
		#echo "#stat_section 	${section^^} /site/${section^^}/* no" >> $rootdir/.tmp/glstat
				printf '%s\n' \
						"section.${section^^}.name=${section^^}"                \
						"section.${section^^}.dir=/site/${section^^}"           \
						"section.${section^^}.gl_credit_section=0"              \
						"section.${section^^}.gl_stat_section=0"                \
				>> "$rootdir/.tmp/footools"

		sed -i "s/\bDIRS=\"/DIRS=\"\n\/site\/${section^^}/" packages/scripts/tur-autonuke/tur-autonuke.conf
		echo "INC${section^^}=$device:$glroot/site/${section^^}:" >> packages/scripts/tur-space/tur-space.conf.new
		echo "$glroot/site/${section^^}" >> "$rootdir/.tmp/.fullpath"
		
		if [ "$(grep -c -w section$((counta+1))= "$cache")" = 0 ]
		then
			echo "section$((counta+1))=\"$section\"" >> "$cache"
		fi
	
	fi
	incom
}

function incom
{
	packages/scripts/tur-rules/rulesgen.sh "${section^^}"
	echo "/site/_REQUESTS/" >> "$rootdir/.tmp/.path"
}


## GLFTPD
function glftpd
{
	if [[ -f "$cache" && "$(grep -c -w eur0presystem "$cache")" = 1 ]]
	then
		echo "Sections           = $(cat "$rootdir/.tmp/.validsections")"
	fi
	if [[ -f "$cache" && "$(grep -c -w router "$cache")" = 1 ]]
		then
				echo "Router             = $(grep -w router "$cache" | cut -d "=" -f2 | tr -d "\"")"
		fi
		if [[ -f "$cache" && "$(grep -c -w pasv_addr "$cache")" = 1 ]]
		then
				echo "Passive address    = $(grep -w pasv_addr "$cache" | cut -d "=" -f2 | tr -d "\"")"
		fi
		if [[ -f "$cache" && "$(grep -c -w pasv_ports "$cache")" = 1 ]]
		then
				echo "Port range         = $(grep -w pasv_ports "$cache" | cut -d "=" -f2 | tr -d "\"")"
		fi
		if [[ -f "$cache" && "$(grep -c -w psxcimdbchan "$cache")" = 1 ]]
		then
				echo "IMDB trigger chan  = $(grep -w psxcimdbchan "$cache" | cut -d "=" -f2 | tr -d "\"")"
		fi

	echo
	echo "--------[ Installation of software and scripts ]----------------------"
	packages/scripts/tur-rules/rulesgen.sh MISC
	cd packages || exit
	echo
	echo -n "Installing glftpd, please wait...                               "
	echo "####### Here starts glFTPD scripts #######" >> /var/spool/cron/crontabs/root
	#cd $PK1DIR ; mv -f ../data/installgl.sh ./ ; ./installgl.sh >/dev/null 2>&1
	cd "$PK1DIR"
	sed "s/changeme/$port/" ../data/installgl.sh.org > installgl.sh 
	chmod +x installgl.sh 
	./installgl.sh 
	#>/dev/null 2>&1
	FCT_CreateDir "$glroot/ftp-data/misc/"
	echo "By malagam.artispretis@gmail.com" >> $glroot/ftp-data/misc/welcome.msg
	echo -e "[\e[32mDone\e[0m]"
	cd ../data || exit
		printf '%s\n' \
				'##########################################################################'            \
				'# Server shutdown: 0=server open, 1=deny all but siteops, !*=deny all, etc'            \
				'shutdown 1'                                                                            \
				'#'                                                                                     \
				"sitename_long          ${sitename}"                                                      \
				"sitename_short         ${sitename}"                                                      \
				'email                  malagam.artispretis@gmail.com'                          \
				"login_prompt           ${sitename}[:space:]Ready"                                        \
				'mmap_amount            100'                                                            \
				'dl_sendfile            4096'                                                           \
				'# SECTION              KEYWORD         DIRECTORY               SEPARATE CREDITS'       \
				'stat_section   DEFAULT         *                               no'                     \
		> glftpd.conf

	if [[ -f "$cache" && "$(grep -c -w router "$cache")" = 1 ]]
	then
		router=$(grep -w router "$cache" | cut -d "=" -f2 | tr -d "\"")
	else
		echo -n "Do you use a router ? [Y]es [N]o, default N : " ; read -r router
	fi
	case $router in
		[Yy])
		wgetbinary=$(which wget)
		ipcheck="$($wgetbinary -qO- http://ipecho.net/plain ; echo)"
	
			if [[ -f "$cache" && "$(grep -c -w pasv_addr "$cache")" = 1 ]]
			then
				pasv_addr=$(grep -w pasv_addr "$cache" | cut -d "=" -f2 | tr -d "\"")
			else	
				echo -n "Please enter the DNS or IP for the site, default $ipcheck : " ; read -r pasv_addr
			fi
			
			if [ "$pasv_addr" = "" ] 
			then
				pasv_addr="$ipcheck"
			fi
		
			if [[ -f "$cache" && "$(grep -c -w pasv_ports "$cache")" = 1 ]]
			then
				pasv_ports=$(grep -w pasv_ports "$cache" | cut -d "=" -f2 | tr -d "\"")
			else
				echo -n "Please enter the port range for passive mode, default 6000-7000 : " ; read -r pasv_ports
			fi
		
		echo "pasv_addr		$pasv_addr	1" >> glftpd.conf
		
			if [ "$pasv_ports" = "" ] 
			then
				echo "pasv_ports		6000-7000" >> glftpd.conf
				pasv_ports="6000-7000"
			else
				echo "pasv_ports		$pasv_ports" >> glftpd.conf
			fi
		;;
		[Nn])
		router=n
		;;
		*)
		router=n
		;;
	esac
	
	if [ "$(grep -c -w router= "$cache")" = 0 ]
	then
		echo "router=\"$router\"" >> "$cache"
	fi
	
	if [[ "$(grep -c -w pasv_addr= "$cache")" = 0 && "$pasv_addr" != "" ]]
	then
		echo "pasv_addr=\"$pasv_addr\"" >> "$cache"
	fi
	
	if [[ "$(grep -c -w pasv_ports= "$cache")" = 0 && "$pasv_addr" != "" ]]
	then
		echo "pasv_ports=\"$pasv_ports\"" >> "$cache"
	fi
	
	#cat glstat >> glftpd.conf && rm glstat
	cat glfoot >> glftpd.conf && mv glftpd.conf $glroot/etc
	cp -f default.user $glroot/ftp-data/users
		printf '%s\n' \
			"59 23 * * * 		$(which chroot) $glroot /bin/cleanup >/dev/null 2>&1"		\
			"29 4 * * * 		$(which chroot) $glroot /bin/datacleaner >/dev/null 2>&1"	\
			"*/10 * * * *		$glroot/bin/incomplete-list-nuker.sh >/dev/null 2>&1"		\
			"0 1 * * *			$glroot/bin/olddirclean2 -PD >/dev/null 2>&1"				\
		>> /var/spool/cron/crontabs/root
	touch $glroot/ftp-data/logs/incomplete-list-nuker.log
	mv ../scripts/tur-space/tur-space.conf.new $glroot/bin/tur-space.conf
	cp ../scripts/tur-space/tur-space.sh $glroot/bin
	cp ../scripts/tur-precheck/tur-precheck.sh $glroot/bin
	cp ../scripts/tur-predircheck/tur-predircheck.sh $glroot/bin
	cp ../scripts/tur-predircheck_manager/tur-predircheck_manager.sh $glroot/bin
	cp ../scripts/tur-free/tur-free.sh $glroot/bin
	sed -i '/^SECTIONS/a '"TOTAL:$device" $glroot/bin/tur-free.sh
	sed -i "s/changeme/$sitename/" $glroot/bin/tur-free.sh
	gcc ../scripts/tur-predircheck/glftpd2/dirloglist_gl.c -o $glroot/bin/dirloglist_gl
	gcc -O2 ../scripts/tur-ftpwho/tur-ftpwho.c -o $glroot/bin/tur-ftpwho
	gcc ../scripts/tuls/tuls.c -o $glroot/bin/tuls
	rm -f $glroot/README
	rm -f $glroot/README.ALPHA
	rm -f $glroot/UPGRADING
	rm -f $glroot/changelog
	rm -f $glroot/LICENSE
	rm -f $glroot/LICENCE
	rm -f $glroot/glftpd.conf
	rm -f $glroot/installgl.debug
	rm -f $glroot/installgl.sh
	rm -f $glroot/glftpd.conf.dist
	rm -f $glroot/convert_to_2.0.pl
	rm -f /etc/glftpd.conf
	mv -f $glroot/create_server_key.sh $glroot/etc
	mv -f ../../site.rules $glroot/ftp-data/misc
	cp incomplete-list.sh $glroot/bin
	cp incomplete-list-nuker.sh $glroot/bin
	chmod 755 $glroot/site
	ln -s $glroot/etc/glftpd.conf /etc/glftpd.conf
	chmod 777 $glroot/ftp-data/msgs
	cp ../scripts/extra/update_perms.sh $glroot/bin
	cp ../scripts/extra/mkv_check.sh $glroot/bin 
	cp "$(which mkvinfo)" $glroot/bin
	cp ../scripts/extra/glftpd-version_check.sh $glroot/bin
	echo "0 18 * * *              $glroot/bin/glftpd-version_check.sh >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
	cp ../scripts/section_manager/section_manager.sh $glroot
	cp ../scripts/imdbrating/imdbrating.sh $glroot
	sed -i "s|changeme|$device|" $glroot/section_manager.sh
	chown -R root:root $glroot/bin
	chmod u+s $glroot/bin/undupe
	chmod u+s $glroot/bin/sed
	chmod u+s $glroot/bin/nuker
	if [ -f /etc/systemd/system/glftpd.socket ]
	then
	    sed -i 's/#MaxConnections=64/MaxConnections=300/' /etc/systemd/system/glftpd.socket
	fi
	systemctl daemon-reload 
	systemctl restart glftpd.socket
}

## EGGDROP
function eggdrop
{
	if [[ -f "$cache" && "$(grep -c -w eur0presystem "$cache")" = 0 ]]
	then
		echo
	fi
	echo -n "Installing eggdrop, please wait...                              "
	cd ../$PK3DIR || exit ; ./configure --prefix="$glroot/sitebot" >/dev/null 2>&1 && make config >/dev/null 2>&1  && make >/dev/null 2>&1 && make install >/dev/null 2>&1 && make sslcert >/dev/null 2>&1
	cd ../data || exit
	
	FCT_CreateDir "$glroot/sitebot/data"
	chmod 777 $glroot/sitebot/data
	cat egghead > "$sitename".conf
	cat "$rootdir/.tmp/eggchan" >> "$sitename".conf
	sed -e "s/changeme/$sitename/" bot.chan > $glroot/sitebot/data/"$sitename".chan
	cat "$rootdir/.tmp/bot.chan.tmp" >> $glroot/sitebot/data/"$sitename".chan
		printf '%s\n' \
				"set username              \"$sitename\""       \
				"set nick          \"$sitename\""               \
				"set altnick               \"_$sitename\""      \
		> "$sitename".conf
	sed -i "s/changeme/$ircnickname/" "$sitename".conf
	mv "$sitename".conf $glroot/sitebot
	cp botchkhead .botchkhead
		printf '%s\n' \
				"botdir=$glroot/sitebot"                \
				"botscript=$PK3DIR"                     \
				"botname=$sitename"                     \
				"userfile=./data/$sitename.user"        \
				"pidfile=pid.$sitename"                 \
		> .botchkhead

	chmod 755 .botchkhead
	mv .botchkhead $glroot/sitebot/botchk
	cat botchkfoot >> $glroot/sitebot/botchk
	touch /var/spool/cron/crontabs/$BOTU
	echo "*/10 * * * *	$glroot/sitebot/botchk >/dev/null 2>&1" >> /var/spool/cron/crontabs/$BOTU
	chmod 777 $glroot/sitebot/logs
	chown -R sitebot:glftpd $glroot/sitebot/
	rm -f $glroot/sitebot/BOT.INSTALL
	rm -f $glroot/sitebot/README
	rm -f $glroot/sitebot/eggdrop1.8
	rm -f $glroot/sitebot$glroot-tcl.old-TIMER
	rm -f $glroot/sitebot$glroot.tcl-TIMER
	rm -f $glroot/sitebot/eggdrop
	rm -f $glroot/sitebot/eggdrop-basic.conf
	rm -f $glroot/sitebot/scripts/CONTENTS
	rm -f $glroot/sitebot/scripts/autobotchk
	rm -f $glroot/sitebot/scripts/botchk
	rm -f $glroot/sitebot/scripts/weed
	ln -s "$glroot/sitebot/$(ls $glroot/sitebot/*eggdrop-*)" $glroot/sitebot/sitebot
	chmod 666 $glroot/etc/glroot.conf
	FCT_CreateDir $glroot/site/_PRE/SiteOP $glroot/site/_REQUESTS $glroot/site/_SPEEDTEST
	chmod 777 $glroot/site/_PRE $glroot/site/_PRE/SiteOP $glroot/site/_REQUESTS $glroot/site/_SPEEDTEST
	dd if=/dev/urandom of=$glroot/site/_SPEEDTEST/150MB bs=1M count=150 >/dev/null 2>&1
	dd if=/dev/urandom of=$glroot/site/_SPEEDTEST/250MB bs=1M count=250 >/dev/null 2>&1
	dd if=/dev/urandom of=$glroot/site/_SPEEDTEST/500MB bs=1M count=500 >/dev/null 2>&1
	dd if=/dev/urandom of=$glroot/site/_SPEEDTEST/1GB bs=1M count=1000 >/dev/null 2>&1
	dd if=/dev/urandom of=$glroot/site/_SPEEDTEST/5GB bs=1M count=5000 >/dev/null 2>&1
	dd if=/dev/urandom of=$glroot/site/_SPEEDTEST/10GB bs=1M count=10000 >/dev/null 2>&1
	rm -f $glroot/sitebot/scripts/*.tcl
	cp ../scripts/extra/*.tcl $glroot/sitebot/scripts
	sed -i "s/#changeme/$announcechannels/" $glroot/sitebot/scripts/rud-news.tcl
	sed -i "s/#personal/$channelops/" $glroot/sitebot/scripts/rud-news.tcl
	mv -f ../scripts/tur-rules/tur-rules.sh $glroot/bin
	cp ../scripts/tur-rules/*.tcl $glroot/sitebot/scripts
	cp ../scripts/tur-free/*.tcl $glroot/sitebot/scripts
	cp ../scripts/tur-predircheck_manager/tur-predircheck_manager.tcl $glroot/sitebot/scripts
	sed -i "s/changeme/$channelops/g" $glroot/sitebot/scripts/tur-predircheck_manager.tcl
	cp "$rootdir/packages/data/kill.sh" $glroot/sitebot
	sed -i "s/changeme/$sitename/g" $glroot/sitebot/kill.sh
	echo "source scripts/tur-free.tcl" >> $glroot/sitebot/eggdrop.conf
	echo -e "[\e[32mDone\e[0m]"
}

function irc
{
	if [[ -f "$cache" && "$(grep -c -w ircserver "$cache")" = 1 ]]
	then
		sed -i "s/servername/$ircserver/" $glroot/sitebot/eggdrop.conf
	else
		echo
	    	echo -n "What irc server ? default irc.example.org : " ; read -r servername
	
		if [ "$servername" = "" ] 
		then
			servername="irc.example.org"
		fi
		
		echo -n "What port for irc server ? default 7000 : " ; read -r serverport
		if [ "$serverport" = "" ] 
		then
			serverport="7000"
		fi
		
		echo -n "Is the port above a SSL port ? [Y]es [N]o, default Y : " ; read -r serverssl
		case $serverssl in
			[Yy])
			ssl=1
			;;
			[Nn])
			ssl=0
			;;
			*)
			ssl=1
			;;
		esac
		
		echo -n "Does it require a password ? [Y]es [N]o, default N : " ; read -r serverpassword
		case $serverpassword in
			[Yy])
			echo -n "Please enter the password for irc server, default ircpassword : " ; read -r password
			if [ "$password" = "" ] 
			then
				password=":ircpassword"
			else
				password=":$password"
			fi
			;;
			[Nn])
			password=""
			;;
			*)
			password=""
			;;
		esac
		
		case $ssl in
			1)
			sed -i "s/servername/${servername}:+${serverport}${password}/" $glroot/sitebot/eggdrop.conf
			
			if [ "$(grep -c -w ircserver= "$cache")" = 0 ]
			then
				echo "ircserver=\"${servername}:+${serverport}${password}\"" >> "$cache"
			fi
			;;
			0)
			sed -i "s/servername/${servername}:${serverport}${password}/" $glroot/sitebot/eggdrop.conf
			
			if [ "$(grep -c -w ircserver= "$cache")" = 0 ]
			then
				echo "ircserver=\"${servername}:${serverport}${password}\"" >> "$cache"
			fi
			;;
		esac
	fi
}

## zsconfig.h
function pzshfile
{
	cd ../../
	cat packages/data/pzshead > zsconfig.h
	path=$(cat "$rootdir/.tmp/.path")
		printf '%s\n' \
				"#define check_for_missing_nfo_dirs                \"$path\""                                                           \
				"#define cleanupdirs                               \"$path\""                                                           \
				"#define cleanupdirs_dated                 \"/site/0DAY/%m%d/ /site/FLAC/%m%d/ /site/MP3/%m%d/ /site/EBOOKS/%m%d/\""    \
				"#define sfv_dirs                          \"$path\""                                                                   \
				"#define short_sitename                            \"$sitename\""                                                       \
		>> zsconfig.h

	chmod 755 zsconfig.h
	mv zsconfig.h packages/pzs-ng/zipscript/conf/zsconfig.h
}

## dZSbot.tcl
function pzsbotfile
{
		echo "REQUEST" >> "$rootdir/.tmp/.validsections"
		echo "set paths(REQUEST)			\"/site/_REQUESTS/*/*\"" >> "$rootdir/.tmp/dzsrace"
	echo "set chanlist(REQUEST)			\"$announcechannels\"" >> "$rootdir/.tmp/dzschan"
		printf '%s\n' \
				"$(cat packages/data/dzshead)"                                                          \
				"set device(0)"                            '"'$device SITE'"'                           \
				"$(cat packages/data/dzsbnc)"                                                          \
				"$(cat packages/data/dzsmidl)"                                                          \
				"set sections                              \"$(cat "$rootdir/.tmp/.validsections")\""   \
				''                                                                                      \
				"$(cat "$rootdir/.tmp/dzsrace")"                                                          \
				"$(cat "$rootdir/.tmp/dzschan")"                                                          \
				"$(cat "packages/data/dzsfoot")"                                                          \
		> ngBot.conf

	chmod 644 ngBot.conf
	rm "$rootdir/.tmp/dzsrace"
	rm "$rootdir/.tmp/dzschan"
	FCT_CreateDir "$glroot/sitebot/scripts/pzs-ng/themes"
	mv ngBot.conf $glroot/sitebot/scripts/pzs-ng/ngBot.conf
}

## PROJECTZS
function pzsng
{
	if [[ -f "$cache" && "$(grep -c -w eur0presystem "$cache")" = 0 ]]
	then
		echo
	fi
	echo -n "Installing pzs-ng, please wait...                               "
	cd packages/pzs-ng || exit
	./configure >/dev/null 2>&1 ; make >/dev/null 2>&1 ; make install >/dev/null 2>&1
	$glroot/libcopy.sh >/dev/null 2>&1
	echo -e "[\e[32mDone\e[0m]"
	cp sitebot/ngB* $glroot/sitebot/scripts/pzs-ng/
	cp -r sitebot/modules $glroot/sitebot/scripts/pzs-ng/
	cp -r sitebot/plugins $glroot/sitebot/scripts/pzs-ng/
	cp -r sitebot/themes $glroot/sitebot/scripts/pzs-ng/
	cp ../data/glftpd.installer.theme $glroot/sitebot/scripts/pzs-ng/themes
	cp ../data/ngBot.vars $glroot/sitebot/scripts/pzs-ng
	cp -f ../data/sitewho.conf $glroot/bin
	cd ../scripts || exit
	chmod u+s $glroot/bin/cleanup
	rm -f $glroot/sitebot/scripts/pzs-ng/ngBot.conf.dist
}

## eur0-pre-system
function presystem
{
	if [[ -f "$cache" && "$(grep -c -w eur0presystem "$cache")" = 1 ]]
	then
		ask=$(grep -w eur0presystem "$cache" | cut -d "=" -f2 | tr -d "\"")
	else
		echo
		echo -e "\e[4mDescription for Eur0-pre-system + foo-pre:\e[0m"
		cat "$rootdir/packages/scripts/eur0-pre-system/description"
		echo
		echo -n "Install Eur0-pre-system + foo-pre ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case $ask in
		[Nn])
		if [ "$(grep -c -w eur0presystem= "$cache")" = 0 ]
		then
			echo "eur0presystem=\"n\"" >> "$cache"
		fi
		;;
		[Yy]|*)
		if [ "$(grep -c -w eur0presystem= "$cache")" = 0 ]
		then
			echo "eur0presystem=\"y\"" >> "$cache"
		fi

		echo -n "Installing Eur0-pre-system + foo-pre, please wait...            "
		cd eur0-pre-system || exit
		make  >/dev/null 2>&1
		make install  >/dev/null 2>&1
		make clean >/dev/null 2>&1
		cp ./*.sh $glroot/bin
		cp ./*.tcl $glroot/sitebot/scripts
		echo "source scripts/affils.tcl" >> $glroot/sitebot/eggdrop.conf
		bins="bc du expr echo sed touch chmod pwd grep basename date mv bash find sort"
		
		for file in $bins
		do
		cp "$(which "$file")" $glroot/bin
		done
		
		cat gl >> $glroot/etc/glftpd.conf
	
		if [ -d foo-tools ]
		then
			rm -rf foo-tools >/dev/null 2>&1
		fi
	
		git clone https://github.com/silv3rr/foo-tools >/dev/null 2>&1
		cp -f ../../data/pre.cfg $glroot/etc
		cd foo-tools || exit
		git checkout cdb77c1 >/dev/null 2>&1
		cd src || exit
		./configure -q && make build >/dev/null 2>&1
		cp pre/foo-pre $glroot/bin && chmod u+s $glroot/bin/foo-pre
		make -s distclean
		echo -e "[\e[32mDone\e[0m]"
		cd ../../
		sections=$(sed "s/REQUEST//g" "$rootdir/.tmp/.validsections" | sed "s/ /|/g" | sed "s/|$//g")
		cat "$rootdir/.tmp/footools" >> $glroot/etc/pre.cfg
		rm -f "$rootdir/.tmp/footools"
		sed -i '/# group.dir/a group.SiteOP.dir=/site/_PRE/SiteOP' $glroot/etc/pre.cfg
		sed -i '/# group.allow/a group.SiteOP.allow='"$sections" $glroot/etc/pre.cfg
		sed -i "s/allow=/allow=$sections/" $glroot/bin/addaffil.sh
		touch $glroot/ftp-data/logs/foo-pre.log
		mknod $glroot/dev/full c 1 7 && chmod 666 $glroot/dev/full
		mknod $glroot/dev/urandom c 1 9 && chmod 666 $glroot/dev/urandom
		cd ..
		;;
	esac
}

## slv-prebw
function slvprebw
{
	if [[ -f "$cache" && "$(grep -c -w slvprebw "$cache")" = 1 ]]
	then
		ask=$(grep -w slvprebw "$cache" | cut -d "=" -f2 | tr -d "\"")
	else
		echo
				echo -e "\e[4mDescription for slv-PreBW:\e[0m"
				cat "$rootdir/packages/scripts/slv-prebw/description"
		echo
		echo -n "Install slv-PreBW ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case $ask in
		[Nn])
		if [ "$(grep -c -w slvprebw= "$cache")" = 0 ]
		then
			echo "slvprebw=\"n\"" >> "$cache"
		fi
		;;
		[Yy]|*)
		if [ "$(grep -c -w slvprebw= "$cache")" = 0 ]
		then
			echo "slvprebw=\"y\"" >> "$cache"
		fi
		
		echo -n "Installing slv-PreBW, please wait...                            "
		cp slv-prebw/*.sh $glroot/bin 
		cp slv-prebw/*.tcl $glroot/sitebot/scripts/pzs-ng/plugins
		echo "source scripts/pzs-ng/plugins/PreBW.tcl" >> $glroot/sitebot/eggdrop.conf
		echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}

## idlebotkick
function idlebotkick
{
	if [[ -f "$cache" && "$(grep -c -w idlebotkick "$cache")" = 1 ]]
	then
		ask=$(grep -w idlebotkick "$cache" | cut -d "=" -f2 | tr -d "\"")
	else
		echo
				echo -e "\e[4mDescription for Idlebotkick:\e[0m"
				cat "$rootdir/packages/scripts/idlebotkick/description"
		echo
		echo -n "Install Idlebotkick ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case $ask in
		[Nn])
		if [ "$(grep -c -w idlebotkick= "$cache")" = 0 ]
		then
			echo "idlebotkick=\"n\"" >> "$cache"
		fi
		;;
		[Yy]|*)
		if [ "$(grep -c -w idlebotkick= "$cache")" = 0 ]
		then
			echo "idlebotkick=\"y\"" >> "$cache"
		fi
		echo -n "Installing Idlebotkick, please wait...                          "
		cd idlebotkick || exit
		cp idlebotkick.sh $glroot/bin
		sed -i "s/changeme/$port/g" $glroot/bin/idlebotkick.sh
		chmod 755 $glroot/bin/idlebotkick.sh
		cp idlebotkick.tcl $glroot/sitebot/scripts
		echo "source scripts/idlebotkick.tcl" >> $glroot/sitebot/eggdrop.conf
		cd ..
		echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}

## tur-ircadmin
function ircadmin
{
	if [[ -f "$cache" && "$(grep -c -w ircadmin "$cache")" = 1 ]]
	then
		ask=$(grep -w ircadmin "$cache" | cut -d "=" -f2 | tr -d "\"")
	else
		echo
				echo -e "\e[4mDescription for Tur-Ircadmin:\e[0m"
				cat "$rootdir/packages/scripts/tur-ircadmin/description"
		echo
		echo -n "Install Tur-Ircadmin ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case $ask in
		[Nn])
		if [ "$(grep -c -w ircadmin= "$cache")" = 0 ]
		then
			echo "ircadmin=\"n\"" >> "$cache"
		fi
		;;
		[Yy]|*)
		if [ "$(grep -c -w ircadmin= "$cache")" = 0 ]
		then
			echo "ircadmin=\"y\"" >> "$cache"
		fi
		
		echo -n "Installing Tur-Ircadmin, please wait...                       	"
		cd tur-ircadmin || exit
		cp tur-ircadmin.sh $glroot/bin
		chmod 755 $glroot/bin/tur-ircadmin.sh
		cp tur-ircadmin.tcl $glroot/sitebot/scripts
		touch $glroot/ftp-data/logs/tur-ircadmin.log
		chmod 666 $glroot/ftp-data/logs/tur-ircadmin.log
		echo "source scripts/tur-ircadmin.tcl" >> $glroot/sitebot/eggdrop.conf
		sed -i "s/changeme/$channelops/" $glroot/sitebot/scripts/tur-ircadmin.tcl
		sed -i "s/changeme/$port/" $glroot/bin/tur-ircadmin.sh
		cd ..
		echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}

## tur-request
function request
{
	if [[ -f "$cache" && "$(grep -c -w request "$cache")" = 1 ]]
	then
		ask=$(grep -w request "$cache" | cut -d "=" -f2 | tr -d "\"")
	else
		echo
				echo -e "\e[4mDescription for Tur-Request:\e[0m"
				cat "$rootdir/packages/scripts/tur-request/description"
		echo
		echo -n "Install Tur-Request ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case $ask in
		[Nn])
		if [ "$(grep -c -w request= "$cache")" = 0 ]
		then
			echo "request=\"n\"" >> "$cache"
		fi
		;;
		[Yy]|*)
		if [ "$(grep -c -w request= "$cache")" = 0 ]
		then
			echo "request=\"y\"" >> "$cache"
		fi
		
		echo -n "Installing Tur-Request, please wait...                       	"
		cd tur-request || exit
		cp tur-request.sh $glroot/bin
		chmod 755 $glroot/bin/tur-request.sh
		cp ./*.tcl $glroot/sitebot/scripts
		cp file_date $glroot/bin
		sed -e "s/changeme/$sitename/" tur-request.conf > $glroot/bin/tur-request.conf
		touch $glroot/site/_REQUESTS/.requests ; chmod 666 $glroot/site/_REQUESTS/.requests
		echo "1 18 * * * 		$glroot/bin/tur-request.sh status auto >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
		echo "1 0 * * * 		$glroot/bin/tur-request.sh checkold >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
		touch $glroot/ftp-data/logs/tur-request.log
		chmod 666 $glroot/ftp-data/logs/tur-request.log
		echo "source scripts/tur-request.auth.tcl" >> $glroot/sitebot/eggdrop.conf
		cat gl >> $glroot/etc/glftpd.conf
		cd ..
		echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}

## tur-trial
function trial
{
	if [[ -f "$cache" && "$(grep -c -w trial "$cache")" = 1 ]]
	then
		ask=$(grep -w trial "$cache" | cut -d "=" -f2 | tr -d "\"")
	else
		echo
				echo -e "\e[4mDescription for Tur-Trial3:\e[0m"
				cat "$rootdir/packages/scripts/tur-trial3/description"
		echo
		echo -n "Install Tur-Trial3 ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case $ask in
		[Nn])
		if [ "$(grep -c -w trial= "$cache")" = 0 ]
		then
			echo "trial=\"n\"" >> "$cache"
		fi
		#echo "0 0 * * * 		$glroot/bin/reset -d" >> /var/spool/cron/crontabs/root
		;;
		[Yy]|*)
		if [ "$(grep -c -w trial= "$cache")" = 0 ]
		then
			echo "trial=\"y\"" >> "$cache"
		fi
		
		if [ ! -e "/usr/bin/mysql" ] 
		then
			echo
			echo "Tur-Trial3 needs a SQL server but MySQL was not found on your server"
			echo "No need to panic though, Tur-Trial3 will still be installed - you will just have to install"
			echo "MySQL before you can use the script."
			echo
		fi
		
		echo -n "Installing Tur-Trial3, please wait...                       	"
		cd tur-trial3 || exit 
		cp ./*.sh $glroot/bin
		cp tur-trial3.conf $glroot/bin
		cp tur-trial3.theme $glroot/bin
		cp tur-trial3.tcl $glroot/sitebot/scripts
		echo "source scripts/tur-trial3.tcl" >> $glroot/sitebot/eggdrop.conf
		echo "*/31 * * * * 		$glroot/bin/tur-trial3.sh update >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
		echo "*/30 * * * * 		$glroot/bin/tur-trial3.sh tcron >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
		echo "45 23 * * * 		$glroot/bin/tur-trial3.sh qcron >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
		echo "0 0 * * * 		$glroot/bin/midnight.sh >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
		
		if [ -f "$(which mysql)" ]
		then
			cp "$(which mysql)" $glroot/bin
		fi
		
		cat gl >> $glroot/etc/glftpd.conf
		cd ..
		touch $glroot/ftp-data/logs/tur-trial3.log
		echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}

## tur-vacation
function vacation
{
	if [[ -f "$cache" && "$(grep -c -w vacation "$cache")" = 1 ]]
	then
		ask=$(grep -w vacation "$cache" | cut -d "=" -f2 | tr -d "\"")
	else
		echo
				echo -e "\e[4mDescription for Tur-Vacation:\e[0m"
				cat "$rootdir/packages/scripts/tur-vacation/description"
		echo
		echo -n "Install Tur-Vacation ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case $ask in
		[Nn])
		if [ "$(grep -c -w vacation= "$cache")" = 0 ]
		then
			echo "vacation=\"n\"" >> "$cache"
		fi
		;;
		[Yy]|*)
		if [ "$(grep -c -w vacation= "$cache")" = 0 ]
		then
			echo "vacation=\"y\"" >> "$cache"
		fi
		
		echo -n "Installing Tur-Vacation, please wait...                       	"
		cp tur-vacation/tur-vacation.sh $glroot/bin
		touch $glroot/etc/vacation.index ; chmod 666 $glroot/etc/vacation.index
		touch $glroot/etc/quota_vacation.db ; chmod 666 $glroot/etc/quota_vacation.db
		cat tur-vacation/gl >> $glroot/etc/glftpd.conf
		echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}

## whereami
function whereami
{
	if [[ -f "$cache" && "$(grep -c -w whereami "$cache")" = 1 ]]
	then
		ask=$(grep -w whereami "$cache" | cut -d "=" -f2 | tr -d "\"")
	else
		echo
				echo -e "\e[4mDescription for Whereami:\e[0m"
				cat "$rootdir/packages/scripts/whereami/description"
		echo
		echo -n "Install Whereami ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case $ask in
		[Nn])
		if [ "$(grep -c -w whereami= "$cache")" = 0 ]
		then
			echo "whereami=\"n\"" >> "$cache"
		fi
		;;
		[Yy]|*)
		if [ "$(grep -c -w whereami= "$cache")" = 0 ]
		then
			echo "whereami=\"y\"" >> "$cache"
		fi

		echo -n "Installing Whereami, please wait...                             "
		cp whereami/whereami.sh $glroot/bin
		chmod 755 $glroot/bin/whereami.sh
		cp whereami/whereami.tcl $glroot/sitebot/scripts
		echo "source scripts/whereami.tcl" >> $glroot/sitebot/eggdrop.conf
		echo -e "[\e[32mDone\e[0m]"
	esac
}


## tur-undupe
function undupe
{
	if [[ -f "$cache" && "$(grep -c -w undupe "$cache")" = 1 ]]
	then
		ask=$(grep -w undupe "$cache" | cut -d "=" -f2 | tr -d "\"")
	else
		echo
				echo -e "\e[4mDescription for Tur-Undupe:\e[0m"
				cat "$rootdir/packages/scripts/tur-undupe/description"
		echo
		echo -n "Install Tur-Undupe ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case $ask in
		[Nn])
		if [ "$(grep -c -w undupe= "$cache")" = 0 ]
		then
			echo "undupe=\"n\"" >> "$cache"
		fi
		;;
		[Yy]|*)
		if [ "$(grep -c -w undupe= "$cache")" = 0 ]
		then
			echo "undupe=\"y\"" >> "$cache"
		fi
		
		echo -n "Installing Tur-Undupe, please wait...                       	"
		cp tur-undupe/tur-undupe.sh $glroot/bin
		chmod 755 $glroot/bin/tur-undupe.sh
		chmod 6755 $glroot/bin/undupe
		cp tur-undupe/tur-undupe.tcl $glroot/sitebot/scripts
		echo "source scripts/tur-undupe.tcl" >> $glroot/sitebot/eggdrop.conf
		echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}

## precheck
function precheck
{
	if [[ -f "$cache" && "$(grep -c -w precheck "$cache")" = 1 ]]
	then
		ask=$(grep -w precheck "$cache" | cut -d "=" -f2 | tr -d "\"")
	else
		echo
		echo -e "\e[4mDescription for Precheck:\e[0m"
		cat "$rootdir/packages/scripts/precheck/description"
		echo
		echo -n "Install Precheck ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case $ask in
		[Nn])
		if [ "$(grep -c -w precheck= "$cache")" = 0 ]
		then
			echo "precheck=\"n\"" >> "$cache"
		fi
		;;
		[Yy]|*)
		if [ "$(grep -c -w precheck= "$cache")" = 0 ]
		then
			echo "precheck=\"y\"" >> "$cache"
		fi
		
		echo -n "Installing Precheck, please wait...                             "
		cp precheck/precheck*.sh $glroot/bin
		chmod +x $glroot/bin/precheck*.sh
		cp precheck/precheck.tcl $glroot/sitebot/scripts
		echo "source scripts/precheck.tcl" >> $glroot/sitebot/eggdrop.conf
		touch $glroot/ftp-data/logs/precheck.log
		echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}

## tur-autonuke
function autonuke
{
	if [[ -f "$cache" && "$(grep -c -w autonuke "$cache")" = 1 ]]
	then
		ask=$(grep -w autonuke "$cache" | cut -d "=" -f2 | tr -d "\"")
	else
		echo
				echo -e "\e[4mDescription for Tur-Autonuke:\e[0m"
				cat "$rootdir/packages/scripts/tur-autonuke/description"
		echo
		echo -n "Install Tur-Autonuke ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case $ask in
		[Nn])
		if [ "$(grep -c -w autonuke= "$cache")" = 0 ]
		then
			echo "autonuke=\"n\"" >> "$cache"
		fi
		;;
		[Yy]|*)
		if [ "$(grep -c -w autonuke= "$cache")" = 0 ]
		then
			echo "autonuke=\"y\"" >> "$cache"
		fi
		
		echo -n "Installing Tur-Autonuke, please wait...                       	"
		mv tur-autonuke/tur-autonuke.conf $glroot/bin
		cp tur-autonuke/tur-autonuke.sh $glroot/bin
		echo "*/10 * * * *		$glroot/bin/tur-autonuke.sh >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
		touch $glroot/ftp-data/logs/tur-autonuke.log
		echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}

## psxc-imdb
function psxcimdb
{
	if [[ -f "$cache" && "$(grep -c -w psxcimdb "$cache")" = 1 ]]
	then
		ask=$(grep -w psxcimdb "$cache" | cut -d "=" -f2 | tr -d "\"")
	else
		echo
				echo -e "\e[4mDescription for PSXC-IMDB:\e[0m"
				cat "$rootdir/packages/scripts/psxc-imdb/description"
		echo
		echo -n "Install PSXC-IMDB ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case $ask in
		[Nn])
		if [ "$(grep -c -w psxcimdb= "$cache")" = 0 ]
		then
			echo "psxcimdb=\"n\"" >> "$cache"
		fi
		;;
		[Yy]|*)
		if [ "$(grep -c -w psxcimdb= "$cache")" = 0 ]
		then
			echo "psxcimdb=\"y\"" >> "$cache"
		fi
		
		if [[ -f "$cache" && "$(grep -c -w psxcimdbchan "$cache")" = 1 ]]
		then
			imdbchan=$(grep -w psxcimdbchan "$cache" | cut -d "=" -f2 | tr -d "\"")
		else
			while [[ -z $imdbchan ]] 
			do
				echo -n "IMDB trigger chan for !imdb requests : " ; read -r imdbchan
			done
		fi
		
		
		echo -n "Installing PSXC-IMDB, please wait...                            "
		cd psxc-imdb || exit
		cp ./extras/* $glroot/bin
		cp ./addons/* $glroot/bin
		cp ./main/psxc-imdb.sh $glroot/bin
		cp ./main/psxc-imdb.conf $glroot/etc
		cp ./main/psxc-imdb.tcl $glroot/sitebot/scripts/pzs-ng/plugins
		cp ./main/psxc-imdb.zpt $glroot/sitebot/scripts/pzs-ng/plugins
		$glroot/bin/psxc-imdb-sanity.sh >/dev/null 2>&1
		touch $glroot/ftp-data/logs/psxc-moviedata.log ; chmod 666 $glroot/ftp-data/logs/psxc-moviedata.log
		echo "source scripts/pzs-ng/plugins/psxc-imdb.tcl" >> $glroot/sitebot/eggdrop.conf
		cat gl >> $glroot/etc/glftpd.conf
		echo -e "[\e[32mDone\e[0m]"
		CHECK=$(grep -w ".imdb" $glroot/etc/glftpd.conf)
		
		if [ "$CHECK" = "" ] 
		then
			sed -e "s/show_diz .message/show_diz .message .imdb/" "$glroot/etc/glftpd.conf" > $glroot/etc/glftpd.conf
			touch $glroot/ftp-data/logs/psxc-moviedata.log;
			chmod 666 $glroot/ftp-data/logs/psxc-moviedata.log;
		fi
		
		sed -i "s/#changethis/$imdbchan/" $glroot/sitebot/scripts/pzs-ng/plugins/psxc-imdb.tcl
		cd ..
		
		if [ "$(grep -c -w psxcimdbchan= "$cache")" = 0 ]
		then
			echo "psxcimdbchan=\"$imdbchan\"" >> "$cache"
		fi
		;;
	esac
}

## tur-addip
function addip
{
	if [[ -f "$cache" && "$(grep -c -w addip "$cache")" = 1 ]]
	then
		ask=$(grep -w addip "$cache" | cut -d "=" -f2 | tr -d "\"")
	else
				echo
		echo -e "\e[4mDescription for Tur-Addip:\e[0m"
				cat "$rootdir/packages/scripts/tur-addip/description"
		echo
		echo -n "Install Tur-Addip ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case $ask in
		[Nn])
		if [ "$(grep -c -w addip= "$cache")" = 0 ]
		then
			echo "addip=\"n\"" >> "$cache"
		fi
		;;
		[Yy]|*)
		if [ "$(grep -c -w addip= "$cache")" = 0 ]
		then
			echo "addip=\"y\"" >> "$cache"
		fi
		
		echo -n "Installing Tur-Addip, please wait...                            "
		cd tur-addip || exit
		cp ./*.tcl $glroot/sitebot/scripts
		cp ./*.sh $glroot/bin
		echo "source scripts/tur-addip.tcl" >> $glroot/sitebot/eggdrop.conf
		touch $glroot/ftp-data/logs/tur-addip.log ; chmod 666 $glroot/ftp-data/logs/tur-addip.log
		sed -i "s/changeme/$port/" $glroot/bin/tur-addip.sh
		sed -i "s/changeme/$channelops/" $glroot/sitebot/scripts/tur-addip.tcl
		cd ..
		echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}

## tur-oneline_stats
function oneline_stats
{
	if [[ -f "$cache" && "$(grep -c -w oneline_stats "$cache")" = 1 ]]
	then
		ask=$(grep -w oneline_stats "$cache" | cut -d "=" -f2 | tr -d "\"")
	else
		echo
				echo -e "\e[4mDescription for Tur-Oneline_stats:\e[0m"
				cat "$rootdir/packages/scripts/tur-oneline_stats/description"
		echo
		echo -n "Install Tur-Oneline_Stats ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case $ask in
		[Nn])
		if [ "$(grep -c -w oneline_stats= "$cache")" = 0 ]
		then
			echo "oneline_stats=\"n\"" >> "$cache"
		fi
		;;
		[Yy]|*)
		if [ "$(grep -c -w oneline_stats= "$cache")" = 0 ]
		then
			echo "oneline_stats=\"y\"" >> "$cache"
		fi
		
		echo -n "Installing Tur-Oneline_Stats, please wait...                    "
		cd tur-oneline_stats || exit
		cp ./*.tcl $glroot/sitebot/scripts
		cp ./*.sh $glroot/bin 
		echo "source scripts/tur-oneline_stats.tcl" >> $glroot/sitebot/eggdrop.conf
		cd ..
		echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}

## ircnick
function ircnick
{
	if [[ -f "$cache" && "$(grep -c -w ircnick "$cache")" = 1 ]]
	then
		ask=$(grep -w ircnick "$cache" | cut -d "=" -f2 | tr -d "\"")
	else
		echo
				echo -e "\e[4mDescription for Ircnick:\e[0m"
				cat "$rootdir/packages/scripts/ircnick/description"
		echo
		echo -n "Install Ircnick ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case $ask in
		[Nn])
		if [ "$(grep -c -w ircnick= "$cache")" = 0 ]
		then
			echo "ircnick=\"n\"" >> "$cache"
		fi
		;;
		[Yy]|*)
		if [ "$(grep -c -w ircnick= "$cache")" = 0 ]
		then
			echo "ircnick=\"y\"" >> "$cache"
		fi
		
		echo -n "Installing Ircnick, please wait...                              "
		cp ircnick/*.sh $glroot/bin
		cp ircnick/*.tcl $glroot/sitebot/scripts
		sed -i "s/changeme/$channelops/" $glroot/sitebot/scripts/ircnick.tcl
		echo "source scripts/ircnick.tcl" >> $glroot/sitebot/eggdrop.conf
		echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}

## usercreation
function usercreation
{
	if [[ -f "$cache" && "$(grep -c -w username "$cache")" = 1 ]]
	then
		username=$(grep -w username "$cache" | cut -d "=" -f2 | tr -d "\"")
	else
		echo
		echo -n "Please enter the username of admin, default admin : " ; read -r username
	fi
	
	if [ "$username" = "" ] 
	then
		username="admin"
	fi

	if [[ -f "$cache" && "$(grep -c -w password "$cache")" = 1 ]]
	then
		password=$(grep -w password "$cache" | cut -d "=" -f2 | tr -d "\"")
	else
		echo -n "Please enter the password [$username], default password : " ; read -r password
	fi
	
	if [ "$password" = "" ] 
	then
		password="password"
	fi

	ipbinary=$(which ip)
	localip=$($ipbinary addr show | awk '$1 == "inet" && $3 == "brd" { sub (/\/.*/,""); print $2 }' | head | awk -F "." '{print $1"."$2"."$3.".*"}')
	
	if [[ -f "$cache" && "$(grep -c -w ip "$cache")" = 1 ]]
	then
		ip=$(grep -w ip "$cache" | cut -d "=" -f2 | tr -d "\"")
	else
		echo -n "IP for [$username] ? Minimum *@xxx.xxx.* default *@${localip} : " ; read -r ip
	fi
	
	if [ "$ip" = "" ] 
	then
		ip="*@$localip"
	fi

	if [ "$router" = "y" ] 
	then
		connection="-E ftp://localhost"
	else
		connection="ftp://localhost"
	fi
	ncftpls -u glftpd -p glftpd -P $port -Y "site change glftpd flags +347ABCDEFGH" $connection > /dev/null
	ncftpls -u glftpd -p glftpd -P $port -Y "site grpadd SiteOP SiteOP" $connection > /dev/null
	ncftpls -u glftpd -p glftpd -P $port -Y "site grpadd Admin Administrators/SYSOP" $connection > /dev/null
	ncftpls -u glftpd -p glftpd -P $port -Y "site grpadd Friends Friends" $connection > /dev/null
	ncftpls -u glftpd -p glftpd -P $port -Y "site grpadd NUKERS NUKERS" $connection > /dev/null
	ncftpls -u glftpd -p glftpd -P $port -Y "site grpadd VACATION VACATION" $connection > /dev/null
	ncftpls -u glftpd -p glftpd -P $port -Y "site grpadd iND Independent Racers" $connection > /dev/null
	ncftpls -u glftpd -p glftpd -P $port -Y "site gadduser Admin $username $password $ip" $connection > /dev/null
	ncftpls -u glftpd -p glftpd -P $port -Y "site chgrp $username SiteOP" $connection > /dev/null
	ncftpls -u glftpd -p glftpd -P $port -Y "site change $username flags +1347ABCDEFGH" $connection > /dev/null
	ncftpls -u glftpd -p glftpd -P $port -Y "site change $username ratio 0" $connection > /dev/null
	ncftpls -u glftpd -p glftpd -P $port -Y "site chgrp glftpd Admin" $connection > /dev/null
	ncftpls -u glftpd -p glftpd -P $port -Y "site chgrp glftpd SiteOP" $connection > /dev/null
	echo
	echo "[$username] created successfully and added to the groups Admin and SiteOP"
	echo "These groups were also created: NUKERS, iND, VACATION & Friends"
	sed -i "s/\"changeme\"/\"$username\"/" $glroot/sitebot/eggdrop.conf
	sed -i "s/\"sname\"/\"$sitename\"/" $glroot/sitebot/scripts/pzs-ng/ngBot.conf
	sed -i "s/\"ochan\"/\"$channelops\"/" $glroot/sitebot/scripts/pzs-ng/ngBot.conf
	sed -i "s/\"channame\"/\"$announcechannels\"/" $glroot/sitebot/scripts/pzs-ng/ngBot.conf
	
	if [ "$(grep -c -w username= "$cache")" = 0 ]
	then
			printf '%s\n' \
						"username=\"$username\""        \
						"password=\"$password\""        \
						"ip=\"$ip\""                    \
				>> "$cache"

	fi
}

## CleanUp / Config
function cleanup
{
	cd ../../
	FCT_CreateDir "$glroot/backup"
	mv "packages/$PK1DIR" packages/source/
	mv packages/$PK2DIR packages/source/
	mv packages/$PK3DIR packages/source/
	mv packages/scripts/eur0-pre-system/foo-tools packages/source/
	mv "$rootdir/.tmp/site/*" $glroot/site/
	cp -r packages/source/pzs-ng $glroot/backup
	cp packages/data/pzs-ng-update.sh $glroot/backup 
	cp $glroot/backup/pzs-ng/sitebot/extra/invite.sh $glroot/bin
	cp -f packages/data/syscheck.sh $glroot/bin
	mv -f "$rootdir/.tmp/dated.sh" $glroot/bin
	local DIRDATED=0
	[ -d "$glroot/site/0DAY" ] && sed -i '/^sections/a '"0DAY" $glroot/bin/dated.sh && DIRDATED=1
	[ -d "$glroot/site/FLAC" ] && sed -i '/^sections/a '"FLAC" $glroot/bin/dated.sh && DIRDATED=1
	[ -d "$glroot/site/MP3" ] && sed -i '/^sections/a '"MP3" $glroot/bin/dated.sh && DIRDATED=1
	[ -d "$glroot/site/EBOOKS" ] && sed -i '/^sections/a '"EBOOKS" $glroot/bin/dated.sh && DIRDATED=1

	if [[ $DIRDATED == 1 ]]
	then
		echo "0 0 * * *         	$glroot/bin/dated.sh >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
		echo "0 1 * * *         	$glroot/bin/dated.sh close >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
		$glroot/bin/dated.sh >/dev/null 2>&1
	fi
		local DIRTV=0
		[ -d "$glroot/site/TV-HD" ] && sed -i '/^sections/a '"0DAY" $glroot/bin/dated.sh && DIRTV=1
	[ -d "$glroot/site/TV-NL" ] && sed -i '/^sections/a '"FLAC" $glroot/bin/dated.sh && DIRTV=1
	[ -d "$glroot/site/TV-SD" ] && sed -i '/^sections/a '"MP3" $glroot/bin/dated.sh && DIRTV=1
	[ -d "$glroot/site/EBOOKS" ] && sed -i '/^sections/a '"EBOOKS" $glroot/bin/dated.sh && DIRTV=1
	if [[ $DIRTV == 1 ]]
	then
		cp -f packages/scripts/extra/TVMaze.tcl $glroot/sitebot/scripts/pzs-ng/plugins
		cp -f packages/scripts/extra/TVMaze.zpt $glroot/sitebot/scripts/pzs-ng/plugins
		cp -f packages/scripts/extra/TVMaze_nuke.sh $glroot/bin
		echo "source scripts/pzs-ng/plugins/TVMaze.tcl" >> $glroot/sitebot/eggdrop.conf
		touch $glroot/ftp-data/logs/tvmaze_nuke.log
	fi

	echo "#*/5 * * * *		$glroot/bin/tur-space.sh go >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
	touch $glroot/ftp-data/logs/tur-space.log
	FCT_CreateDir $glroot/tmp
	chmod 777 $glroot/tmp
	chown -R $BOTU:glftpd $glroot/sitebot
	chmod 755 $glroot/bin/*.sh
	chmod 777 $glroot/ftp-data/logs
	chmod 666 $glroot/ftp-data/logs/*
	rm -rf .tmp >/dev/null 2>&1
	
}
start
port
version
device_name
channel
announce
opschan
ircnickname
section_names
glftpd
eggdrop
irc
pzshfile
pzsbotfile
pzsng
presystem
slvprebw
idlebotkick
ircadmin
request
trial
vacation
whereami
undupe
precheck
autonuke
psxcimdb
addip
oneline_stats
ircnick
usercreation
cleanup
echo 
if [ -f $glroot/bin/tur-trial3.sh ]
then
		echo "You have chosen to install Tur-Trial3, please run $glroot/bin/setupsql.sh"
		echo
fi
echo "If you are planning to uninstall glFTPD, then run cleanup.sh"
echo
echo "To get the bot running you HAVE to do this ONCE to create the initial userfile"
echo "su - sitebot -c \"$glroot/sitebot/sitebot -m\""
echo
echo "If you want automatic cleanup of site then please review the settings in $glroot/bin/tur-space.conf and enable the line in crontab"
echo 
echo "All good to go and I recommend people to check the different settings for the different scripts including glFTPD itself."
echo
echo "Enjoy!"
echo 
echo "Installer script created by Teqno" 

exit 0

