#!/bin/bash

### CONFIGURATION

	# Account shell for eggdrop
UNIX_USER_EGGDROP="sitebot"

	# Active debug mode ? true or false
DEBUGINSTALL=true

	# Core variables configuration (don't touch)
rootdir="$(pwd)"
PACKAGES_NEEDED="libncurses-dev libc6-i386 dnsutils git tcl8.6-dev tcllib autoconf bc curl diffutils ftp libflac-dev libssl-dev lm-sensors lynx make mariadb-server mkvtoolnix ncftp passwd rsync smartmontools tcl tcl-dev tcl-tls tcpd wget zip"
BINARY_NEEDED="lynx wget tar tcpd gcc openssl dig nslookup cc bc du expr echo sed touch chmod pwd grep basename date mv bash find sort"

GL_URL_WEBSITE="https://glftpd.io"
MYIPCHECK_URL_WEBSITE="http://ipecho.net/plain"

GIT_URL__PZS_NG="https://github.com/pzs-ng/pzs-ng"
GIT_URL__EGG="https://github.com/eggheads/eggdrop";
GIT_URL__FOO_TOOLS="https://github.com/MalaGaM/Foo-Tools"

GIT_URL__GL_SCRIPTS__GL__IMDb_Rating="https://github.com/MalaGaM/GL-IMDb_Rating"

GIT_URL__GL_SCRIPTS__EUR0__PRE_SYSTEM="https://github.com/MalaGaM/eur0-pre-system"
GIT_URL__GL_SCRIPTS__SLV__PreBW="https://github.com/MalaGaM/SLV-PreBW"

GIT_URL__GL_SCRIPTS__PSXC__IMDB="https://github.com/MalaGaM/PSXC-IMDB"

GIT_URL__GL_SCRIPTS__Teqno__IRCNick="https://github.com/MalaGaM/Teqno-IRCNick"
GIT_URL__GL_SCRIPTS__Teqno__Section_Manager="https://github.com/MalaGaM/Teqno-Section_Manager"

GIT_URL__GL_SCRIPTS__Tur__IdleBotKick="https://github.com/MalaGaM/Tur-IdleBotKick"
GIT_URL__GL_SCRIPTS__Tur__IrcAdmin="https://github.com/MalaGaM/Tur-IrcAdmin"
GIT_URL__GL_SCRIPTS__Tur__Request="https://github.com/MalaGaM/Tur-Request"
GIT_URL__GL_SCRIPTS__Tur__Trial3="https://github.com/MalaGaM/Tur-Trial3"
GIT_URL__GL_SCRIPTS__Tur__Vacation="https://github.com/MalaGaM/Tur-Vacation"
GIT_URL__GL_SCRIPTS__Tur__WhereAmi="https://github.com/MalaGaM/Tur-WhereAmi"
GIT_URL__GL_SCRIPTS__Tur__Undupe="https://github.com/MalaGaM/Tur-Undupe"
GIT_URL__GL_SCRIPTS__Tur__PreCheck="https://github.com/MalaGaM/Tur-PreCheck"
GIT_URL__GL_SCRIPTS__Tur__AutoNuke="https://github.com/MalaGaM/Tur-AutoNuke"
GIT_URL__GL_SCRIPTS__Tur__AddIp="https://github.com/MalaGaM/Tur-AddIp"
GIT_URL__GL_SCRIPTS__Tur__Oneline_Stats="https://github.com/MalaGaM/Tur-Oneline_Stats"
GIT_URL__GL_SCRIPTS__Tur__Space="https://github.com/MalaGaM/Tur-Space"
GIT_URL__GL_SCRIPTS__Tur__PreDirCheck="https://github.com/MalaGaM/Tur-PreDirCheck"
GIT_URL__GL_SCRIPTS__Tur__PreDirCheck_Manager="https://github.com/MalaGaM/Tur-PreDirCheck_Manager"
GIT_URL__GL_SCRIPTS__Tur__Rules="https://github.com/MalaGaM/Tur-Rules"
GIT_URL__GL_SCRIPTS__Tur__Free="https://github.com/MalaGaM/Tur-Free"
GIT_URL__GL_SCRIPTS__Tur__FTPWho="https://github.com/MalaGaM/Tur-FTPWho"
GIT_URL__GL_SCRIPTS__Tur__Tuls="https://github.com/MalaGaM/Tur-Tuls"


PACKAGES_PATH="${rootdir}/packages"
PACKAGES_PATH_DOWNLOADS="${PACKAGES_PATH}/downloads"
PACKAGES_PATH_DATA="${PACKAGES_PATH}/data"
PACKAGES_PATH_GL_SCRIPTS="${PACKAGES_PATH}/scripts"

BINARY_WGET="$(which wget)"
BINARY_IP="$(which ip)"
BINARY_LYNX="$(which lynx)"
BINARY_GCC="$(which gcc)"
BINARY_NCFTPLS="$(which ncftpls)"
BINARY_TAR="$(which tar)"

VER=11.0
AUTHOR="SiteTechicien@GMail.Com"


# verification
BASH_CHECK_ROOT () {
	Banner_Show "Checking root or sudo rights" silent
	# Verification des droits user (besoin de root, ou sudo user)
	if [ ! "$(whoami)" = "root" ]; then
		echo "The installer should be run as root or sudo";
		exit 0;
	fi
}
BASH_CHECK_IF_DEBIAN_INSTALL_DEPENDANCIES () {
	# Verifications si la distro est debian, et installation des dependances pour GLFTPD et les extra scripts via APT
	if [ -f "/etc/debian_version" ]; then
		Banner_Show "Install dependancies (debian)" silent
		for pkg in $PACKAGES_NEEDED; do
			if apt-get -qq install "$pkg"; then
				echo "* Successfully installed "$pkg""
			else
				echo "- Error installing "$pkg""
				exit
			fi
		done
	fi
}
BASH_CHECK_IF_BINARY_EXISTS () {
	# On verifie aussi que les binaire sont bien installer
	Banner_Show "Check Binary needed as installed" silent
	for cmd in $BINARY_NEEDED; do
		if ! command -v "$cmd" &> /dev/null; then
			echo "$cmd need be installed"
			exit
		fi
	done
}

BASH_INIT () {
	cache="${rootdir}/install.cache"
	# creation du repertoire temporaire
	FCT_CreateDir "${rootdir}/.tmp"
	if [ "$(echo "$PATH" | grep -c /usr/sbin)" = 0 ]; then
		echo "/usr/sbin not found in environmental PATH" 
		echo "Default PATH should be : /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
		echo "Current PATH is : "$PATH""
		echo "Correcting PATH"
		export PATH="$PATH:/usr/sbin"
		echo "Done"
	fi
	# clean up comments and trailing spaces in install.cache to avoid problems with unattended installation
	if [ -f "$cache" ]; then sed -i -e 's/" #.*/"/g' -e 's/^#.*//g' -e '/^\s*$/d' -e 's/[ \t]*$//' "$cache"; fi
}
GLFTPD_CONF_INIT () {
	Banner_Show "Configuration GLFTPD" silent
	echo "--------[ Server configuration ]--------------------------------------"
	echo
	if [[ -f "$cache" && "$(grep -c -w GL_SiteName "$cache")" = 1 ]]; then
		GL_SiteName="$(grep -w GL_SiteName "$cache" | cut -d "=" -f2 | tr -d "\"")"
	fi
	
	echo
	while [[ -z "${GL_SiteName}" ]]; do
		echo -n "Please enter the name of the site, without space : " ; read -r GL_SiteName
	done
	# replace space by _
	GL_SiteName="${GL_SiteName// /_}"
	
	if [ ! -f "$cache" ]; then
		echo GL_SiteName=\""${GL_SiteName}"\" > "$cache"
	fi
	# export sitename
	export ${GL_SiteName}
	until [ -n "${glroot}" ]; do
		echo -n "Please enter the private directory to install glftpd [/glftpd/"${GL_SiteName}"]: "
		read -r glroot
		case ${glroot} in
			/)
				echo "You can't have / as your private dir!  Try again."
				echo ""
				unset glroot
				continue
			;;
			/*|"")
			[ -z "${glroot}" ] && glroot="/glftpd/${GL_SiteName}"
				[ -d "${glroot}" ] && {
					echo -n "Path already exists. [D]elete it, [A]bort, [T]ry again, [I]gnore? "
					read -r reply
					case "$reply" in
						[dD]*)
							rm -rf "${glroot}"
						;;
						[tT]*)
							unset glroot;
							continue
						;;
						[iI]*)
							
						;;
						*)
							echo "Aborting.";
							exit 1
						;;
					esac
				}
				mkdir -p ${glroot}
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
	echo " ----------------------------> glroot ${glroot} <----------------------------"

}

GLFTPD_CONF_PORT () {
	if [[ -f "$cache" && "$(grep -c -w GL_Port "$cache")" = 1 ]]; then
		GL_Port="$(grep -w GL_Port "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo -n "Please enter the port number for your site, default 2010 : " ; read -r GL_Port
		
		if [ "${GL_Port}" = "" ]; then
			GL_Port="2010"
		fi
		
		if [ "$(grep -c -w GL_Port= "$cache")" = 0 ]; then
			echo GL_Port=\"${GL_Port}\" >> "$cache"
		fi
	fi
}

GLFTPD_CONF_VERSION () {
	if [[ -f "$cache" && "$(grep -c -w GL_VERS_BRANCH "$cache")" = 1 ]]; then
		GL_VERS_BRANCH="$(grep -w GL_VERS_BRANCH "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo -n "Install stable or beta version of glFTPD ? [stable] [beta], default stable : " ; read -r GL_VERS_BRANCH
	fi
	if [ "${GL_VERS_BRANCH}" = "" ] || [ "${GL_VERS_BRANCH}" = "stable" ]; then
		GL_VERS_BRANCH="The latest stable version"
	else
		GL_VERS_BRANCH="The latest version"
	fi

	if [[ -f "$cache" && "$(grep -c -w GL_ARCH "$cache")" = 1 ]]; then
		GL_ARCH="$(grep -w GL_ARCH "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo -n "Install 32 or 64 bit ARCH of glFTPD ? [32] [64], default 64 : " ; read -r GL_ARCH
	fi
	case "${GL_ARCH}" in
		32)
			
		;;
		64)
			
		;;
		*)
			GL_ARCH="64"
		;;
	esac
	if [ "$(grep -c -w GL_ARCH= "$cache")" = 0 ]; then
		echo GL_ARCH=\"${GL_ARCH}\" >> "$cache"
	fi
}
GLFTPD_DOWNLOAD () {
	Banner_Show "Download GLFTPD" silent
	TMP_DIR_DEST_DOWNLOAD="${PACKAGES_PATH_DOWNLOADS}/${GL_SiteName}"
	mkdir -p ${TMP_DIR_DEST_DOWNLOAD}
	GL_VERS_LATEST="$("${BINARY_LYNX}" --dump "${GL_URL_WEBSITE}" | grep "${GL_VERS_BRANCH}" | cut -d ":" -f2 | sed -e 's/20[1-9][0-9].*//' -e 's/^  //' -e 's/^v//' | tr "[:space:]" "_" | sed 's/_$//')"
	GL_ARCHIVE_FILE="$("${BINARY_WGET}" -q -O - "${GL_URL_WEBSITE}/files/" | grep "LNX-"${GL_VERS_LATEST}".*x"${GL_ARCH}".*" | grep -o -P '(?=glftpd).*(?=.tgz">)').tgz"
	GL_ARCHIVE_PATH="${TMP_DIR_DEST_DOWNLOAD}/${GL_ARCHIVE_FILE}"
	GL_DIR_SOURCE="${GL_ARCHIVE_PATH/.tgz/}"
	if [ -f "${GL_ARCHIVE_PATH}" ] ; then
		echo "Package glftpd '"${TMP_DIR_DEST_DOWNLOAD}"' exists, no downloading again."
	else
		echo "Downloading relevant packages '"${GL_ARCHIVE_PATH}"', please wait..."
		${BINARY_WGET} -q "${GL_URL_WEBSITE}/files/${GL_ARCHIVE_FILE}" -O "${GL_ARCHIVE_PATH}"
		
		echo "Extracting glftpd Source files, please wait..."
		FCT_EXEC_SHOW_ERROR ${BINARY_TAR} xfv ${GL_ARCHIVE_PATH} -C ${TMP_DIR_DEST_DOWNLOAD}/
	fi
}
UNIX_CREATE_USER_AND_GROUP () {
	# Create unix group if dont exists
	CHKGR="$(grep -w "glftpd" /etc/group | cut -d ":" -f1)"
	if [ "$CHKGR" != "glftpd" ]; then
		groupadd glftpd -g 199
		if [ "$DEBUGINSTALL" = true ] ; then echo "Group glftpd added"; fi
	fi
	# Create unix user for eggdrop if dont exists
	CHKUS="$(grep -w "${UNIX_USER_EGGDROP}" /etc/passwd | cut -d ":" -f1)"
	if [ "$CHKUS" != "${UNIX_USER_EGGDROP}" ]; then
		useradd -d "${glroot}/sitebot" -m -g glftpd -s /bin/bash "${UNIX_USER_EGGDROP}"
		chfn -f 0 -r 0 -w 0 -h 0 "${UNIX_USER_EGGDROP}"
		if [ "$DEBUGINSTALL" = true ] ; then echo "User "${UNIX_USER_EGGDROP}" added"; fi
	fi 
}

PZSNG_DOWNLOAD () {
	Banner_Show "Downloads/Update 'pzs-ng' from git" silent
	FCT_GIT_GET "${GIT_URL__PZS_NG}" "${PACKAGES_PATH_DOWNLOADS}/${GL_SiteName}/pzs-ng"
}
EGGDROP_DOWNLOAD () {
	Banner_Show "Downloads/Update 'Eggdrop' from git" silent
	FCT_GIT_GET "${GIT_URL__EGG}" "${PACKAGES_PATH_DOWNLOADS}/eggdrop"
	#FCT_CreateDir source
	#FCT_INSTALL scripts source
	#cd ..
}

GLFTPD_CONF_DEVICE () {
	if [[ -f "$cache" && "$(grep -c -w GL_Device "$cache")" = 1 ]] ; then
		GL_Device="$(grep -w GL_Device "$cache" | cut -d "=" -f2 | tr -d "\"")"
		echo "Sitename           = "${GL_SiteName}""
		echo "Port               = "${GL_Port}""
		echo "glFTPD ARCH        = "${GL_ARCH}"" 
		echo "Device             = "${GL_Device}""
	else
		echo "Please enter which device you will use for the "${glroot}/site" folder"
		echo "eg /dev/sda1"
		echo "eg /dev/mapper/lvm-lvm"
		echo "eg /dev/md0"
		echo "Default: /dev/sda1"
		echo -n "Device : " ; read -r GL_Device
		echo
	
		if [ "${GL_Device}" = "" ] ; then
			GL_Device="/dev/sda1"
		fi
	
	fi


	
	if [ "$(grep -c -w GL_Device= "$cache")" = 0 ]; then
		echo GL_Device=\"${GL_Device}\" >> "$cache"
	fi
}

EGGDROP_CONF_CHANNELS_ADD () {
	#FCT_CreateDir ".tmp"
	if [[ -f "$cache" && "$(grep -c -w EGG_IRC_SERVER "$cache")" = 1 ]]; then
		EGG_IRC_SERVER=$(grep -w EGG_IRC_SERVER "$cache" | cut -d "=" -f2 | tr -d "\"")
		echo -n "Irc server         = "${EGG_IRC_SERVER}""
	fi
	
	if [[ -f "$cache" && "$(grep -c -w channelnr "$cache")" = 1 ]]; then
		echo
		channelnr="$(grep -w channelnr "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		while [[ -z "$channelnr" || "$channelnr" -gt 15 ]]; do
			echo -n "How many channels do you require the bot to be in (max 15)? : " ; read -r channelnr
		done
	fi
	
	counta=0
	
	
	if [ "$(grep -c -w channelnr= "$cache")" = 0 ]; then
		echo channelnr=\""$channelnr"\" >> "$cache"
	fi
	
	while [ "$counta" -lt "$channelnr" ]; do
		if [[ -f "$cache" && "$(grep -c -w "channame$((counta+1))" "$cache")" = 1 ]]; then
			channame="$(grep -w "channame$((counta+1))" "$cache" | cut -d "=" -f2 | tr -d "\"" | cut -d " " -f1)"
			echo "Channel "$((counta+1))"          = "$channame""
		else	
			echo "Include # in name of channel ie #"${GL_SiteName}""
			while [[ -z "$channame" ]]; do
				echo -n "Channel "$((counta+1))" is : " ; read -r channame
			done
		fi
		
		if [[ -f "$cache" && "$(grep -c -w "channame$((counta+1))" "$cache")" = 1 ]]; then 
			chanpasswd="$(grep -w "channame$((counta+1))" "$cache" | cut -d "=" -f2 | tr -d "\"" | cut -d " " -f2)"
			echo "Requires password  = "$chanpasswd""
		else
			echo -n "Channel password ? [Y]es [N]o, default N : " ; read -r chanpasswd
		fi
		
		case "$chanpasswd" in
			[Yy])
				if [[ -f "$cache" && "$(grep -c -w "EGGDROP_CONF_ANNOUNCE_CHANNELS" "$cache")" = 1 ]]; then
					echo "Channel mode       = password protected"
				fi
			
				if [[ -f "$cache" && "$(grep -c -w "channame$((counta+1))" "$cache")" = 1 ]]; then
					chanpassword="$(grep -w "channame$((counta+1))" "$cache" | cut -d "=" -f2 | tr -d "\"" | cut -d " " -f3)"
					echo "Channel password   = "$chanpassword""
				else
					while [[ -z "$chanpassword" ]]; do
						echo -n "Enter the channel password : " ; read -r chanpassword
					done
				fi
				echo "channel set "$channame" chanmode {+ntpsk "$chanpassword"}" >> "${rootdir}/.tmp/bot.chan.tmp"
				echo "channel add "$channame" {" >> "${rootdir}/.tmp/eggchan"
				echo "idle-kick 0" >> "${rootdir}/.tmp/eggchan"
				echo "stopnethack-mode 0" >> "${rootdir}/.tmp/eggchan"
				echo "flood-chan 0:0" >> "${rootdir}/.tmp/eggchan"
				echo "flood-join 0:0" >> "${rootdir}/.tmp/eggchan"
				echo "flood-ctcp 0:0" >> "${rootdir}/.tmp/eggchan"
				echo "flood-kick 0:0" >> "${rootdir}/.tmp/eggchan"
				echo "flood-deop 0:0" >> "${rootdir}/.tmp/eggchan"
				echo "flood-nick 0:0" >> "${rootdir}/.tmp/eggchan"
				echo "aop-delay 0:0" >> "${rootdir}/.tmp/eggchan"
				echo "chanmode \"+ntsk "$chanpassword"\"" >> "${rootdir}/.tmp/eggchan"
				echo "}" >> "${rootdir}/.tmp/eggchan"
				echo "" >> "${rootdir}/.tmp/eggchan"
				echo "$channame" >> "${rootdir}/.tmp/channels"
			
				if [ "$(grep -c -w channame$((counta+1))= "$cache")" = 0 ]; then
					echo "channame$((counta+1))=\"$channame $chanpasswd $chanpassword\"" >> "$cache"
				fi
			
			;;
			[Nn])
				if [[ -f "$cache" && "$(grep -c -w "EGGDROP_CONF_ANNOUNCE_CHANNELS" "$cache")" = 1 ]]; then
					echo "Channel mode       = invite only"
				fi

				echo "channel set "$channame" chanmode {+ntpsi}" >> "${rootdir}/.tmp/bot.chan.tmp"
				echo "channel add "$channame" {" >> "${rootdir}/.tmp/eggchan"
				echo "idle-kick 0" >> "${rootdir}/.tmp/eggchan"
				echo "stopnethack-mode 0" >> "${rootdir}/.tmp/eggchan"
				echo "flood-chan 0:0" >> "${rootdir}/.tmp/eggchan"
				echo "aop-delay 0:0" >> "${rootdir}/.tmp/eggchan"
				echo "chanmode +ntsi" >> "${rootdir}/.tmp/eggchan"
				echo "}" >> "${rootdir}/.tmp/eggchan"
				echo "" >> "${rootdir}/.tmp/eggchan"
				echo "$channame" >> "${rootdir}/.tmp/channels"
				
				if [ "$(grep -c -w channame$((counta+1))= "$cache")" = 0 ]; then
					echo "channame$((counta+1))=\"$channame n nopass\"" "$cache"
				fi
			
			;;
			*)
				if [[ -f "$cache" && "$(grep -c -w "EGGDROP_CONF_ANNOUNCE_CHANNELS" "$cache")" = 1 ]]; then
					echo "Channel mode       = invite only"
				fi
				echo "channel set "$channame" chanmode {+ntpsi}" >> "${rootdir}/.tmp/bot.chan.tmp"
				echo "channel add "$channame" {" >> "${rootdir}/.tmp/eggchan"
				echo "idle-kick 0" >> "${rootdir}/.tmp/eggchan"
				echo "stopnethack-mode 0" >> "${rootdir}/.tmp/eggchan"
				echo "flood-chan 0:0" >> "${rootdir}/.tmp/eggchan"
				echo "aop-delay 0:0" >> "${rootdir}/.tmp/eggchan"
				echo "chanmode +ntsi" >> "${rootdir}/.tmp/eggchan"
				echo "}" >> "${rootdir}/.tmp/eggchan"
				echo "" >> "${rootdir}/.tmp/eggchan"
				echo "$channame" >> "${rootdir}/.tmp/channels"
				
				if [ "$(grep -c -w channame$((counta+1))= "$cache")" = 0 ]; then
					echo "channame$((counta+1))=\"$channame n nopass\"" >> "$cache"
				fi
				
			;;
		esac
		channame=""
		chanpasswd=""
		((counta++))
	done

}

EGGDROP_CONF_ANNOUNCE_CHANNELS () {
	sed -i -e :a -e N -e 's/\n/ /' -e ta "${rootdir}/.tmp/channels"
	if [[ -f "$cache" && "$(grep -c -w EGGDROP_CONF_ANNOUNCE_CHANNELS "$cache")" = 1 ]]; then
		EGGDROP_CONF_ANNOUNCE_CHANNELS="$(grep -w EGGDROP_CONF_ANNOUNCE_CHANNELS "$cache" | cut -d "=" -f2 | tr -d "\"")"
		echo "Announce channels  = "${EGGDROP_CONF_ANNOUNCE_CHANNELS}""
	else
		echo -n "Which should be announce channels,  default: "$(cat "${rootdir}/.tmp/channels")" : " ; read -r EGGDROP_CONF_ANNOUNCE_CHANNELS
	fi
	
	if [ "${EGGDROP_CONF_ANNOUNCE_CHANNELS}" = "" ]; then
		EGGDROP_CONF_ANNOUNCE_CHANNELS="$(cat "${rootdir}/.tmp/channels")"
		cat "${rootdir}/.tmp/channels" > "${rootdir}/.tmp/dzchan"
	
		if [ "$(grep -c -w EGGDROP_CONF_ANNOUNCE_CHANNELS= "$cache")" = 0 ]; then
			echo "EGGDROP_CONF_ANNOUNCE_CHANNELS=\"$(cat "${rootdir}/.tmp/channels")\"" >> "$cache"
		fi
		
	else 
		echo "${EGGDROP_CONF_ANNOUNCE_CHANNELS}" > "${rootdir}/.tmp/dzchan"
	
		if [ "$(grep -c -w EGGDROP_CONF_ANNOUNCE_CHANNELS= "$cache")" = 0 ]; then
			echo "EGGDROP_CONF_ANNOUNCE_CHANNELS=\"${EGGDROP_CONF_ANNOUNCE_CHANNELS}\"" >> "$cache"
		fi
	
	fi
}

EGGDROP_CONF_ANNOUNCE_CHANNELS_ADMIN () {
	if [[ -f "$cache" && "$(grep -c -w EGGDROP_CONF_ANNOUNCE_CHANNELS_ADMIN "$cache")" = 1 ]]; then
		EGGDROP_CONF_ANNOUNCE_CHANNELS_ADMIN="$(grep -w EGGDROP_CONF_ANNOUNCE_CHANNELS_ADMIN "$cache" | cut -d "=" -f2 | tr -d "\"")"
		echo "Ops channel        = "${EGGDROP_CONF_ANNOUNCE_CHANNELS_ADMIN}""
	else
		echo "Channels: "$(cat "${rootdir}/.tmp/channels")""
		while [[ -z "${EGGDROP_CONF_ANNOUNCE_CHANNELS_ADMIN}" ]]; do
			echo -n "Which of these channels as ops channel ? : " ; read -r EGGDROP_CONF_ANNOUNCE_CHANNELS_ADMIN
		done
	fi
	
	echo "${EGGDROP_CONF_ANNOUNCE_CHANNELS_ADMIN}" > "${rootdir}/.tmp/dzochan"
	
	if [ "$(grep -c -w EGGDROP_CONF_ANNOUNCE_CHANNELS_ADMIN= "$cache")" = 0 ]; then
		echo "EGGDROP_CONF_ANNOUNCE_CHANNELS_ADMIN=\"${EGGDROP_CONF_ANNOUNCE_CHANNELS_ADMIN}\"" >> "$cache"
	fi
	
	rm "${rootdir}/.tmp/channels"
}

EGG__YOUR_IRC_NICKNAME () {
	if [[ -f "$cache" && "$(grep -c -w EGG__YOUR_IRC_NICKNAME "$cache")" = 1 ]]; then
		EGG__YOUR_IRC_NICKNAME="$(grep -w EGG__YOUR_IRC_NICKNAME "$cache" | cut -d "=" -f2 | tr -d "\"")"
		echo "Nickname           = "$EGG__YOUR_IRC_NICKNAME""
	else	
		while [[ -z "$EGG__YOUR_IRC_NICKNAME" ]]; do
			echo -n "What is your nickname on irc ? ie SiteTech : " ; read -r EGG__YOUR_IRC_NICKNAME
		done
	fi
	
	if [ "$(grep -c -w EGG__YOUR_IRC_NICKNAME= "$cache")" = 0 ]; then
		echo "EGG__YOUR_IRC_NICKNAME=\"$EGG__YOUR_IRC_NICKNAME\"" >> "$cache"
	fi
}

## how many sections
GLFTPD_CONF_SECTIONS_NAME () {
	#FCT_CreateDir ".tmp"
	if [[ -f "$cache" && "$(grep -c -w sections "$cache")" = 1 ]]; then
		sections="$(grep -w sections "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo "Valid Sections are : "
		echo "0DAY ANIME APPS DVDR EBOOKS FLAC GAMES MP3 MBLURAY MVDVDR NSW PDA PS4 TV-HD TV-NL TV-SD X264 X265-2160 XVID XXX XXX-PAYSITE"
		echo
		while [[ -z "$sections" || "$sections" -gt 20 ]]; do
			echo -n "How many sections do you require for your site (max 20)? : " ; read -r sections
		done
	fi
	
	FCT_INSTALL "${PACKAGES_PATH_DATA}/dated.sh.org" "${rootdir}/.tmp/dated.sh"
	counta=0
	
	if [ "$(grep -c -w sections= "$cache")" = 0 ]; then
		echo sections=\""$sections"\" >> "$cache"
	fi
	
	while [ "$counta" -lt "$sections" ]; do
		section_generate
		((counta++))
	done
}

## which Sections
section_generate () {
	if [[ -f "$cache" && "$(grep -c -w "section$((counta+1))" "$cache")" = 1 ]]; then
		section="$(grep -w "section$((counta+1))" "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo -n "Section "$((counta+1))" is : " ; read -r section
	fi
	case ${section^^} in 0DAY|ANIME|APPS|DVDR|EBOOKS|FLAC|GAMES|MP3|MBLURAY|MVDVDR|NSW|PDA|PS4|TV-HD|TV-NL|TV-SD|X264|X265-2160|XVID|XXX|XXX-PAYSITE)
			writ
		;;
		*)
			while [[ "${section^^}" != @(0DAY|ANIME|APPS|DVDR|EBOOKS|FLAC|GAMES|MP3|MBLURAY|MVDVDR|NSW|PDA|PS4|TV-HD|TV-NL|TV-SD|X264|X265-2160|XVID|XXX|XXX-PAYSITE) ]]; do
				echo "Section ["$section"] is not in the above list of available sections, please try again."
				echo -n "Section "$((counta+1))" is : " ; read -r section
			done
		;;
	esac
}

## TMP_dZSbot.tcl_Config
writ () {
	section="${section^^}"
	if [[ "${section^^}" = 0DAY || "${section^^}" = FLAC || "${section^^}" = MP3 || "${section^^}" = EBOOKS ]]; then
	
		# FCT_CreateDir "${rootdir}/.tmp/site/${section^^}"
		mkdir -p "${rootdir}/.tmp/site/${section^^}"
		FCT_CHMOD 777 "${rootdir}/.tmp/site/${section^^}"
		echo "${section^^} " > "${rootdir}/.tmp/.section" 
		cat "${rootdir}/.tmp/.section" >> "${rootdir}/.tmp/.sections"
		awk -F '[" "]+' '{printf "$0"}' "${rootdir}/.tmp/.sections" > "${rootdir}/.tmp/.validsections"
		#echo "set statsection($counta) \"${section^^}\"" >> "${rootdir}/.tmp/dzsstats"
		echo "set paths("${section^^}")				\"/site/"${section^^}"/*/*\"" >> "${rootdir}/.tmp/dzsrace"
		echo "set chanlist("${section^^}") 			\""${EGGDROP_CONF_ANNOUNCE_CHANNELS}"\"" >> "${rootdir}/.tmp/dzschan"
		#echo "#stat_section 	${section^^}	/site/"${section^^}"/* no" >> "${rootdir}/.tmp/glstat"
		printf '%s\n' \
				"section."${section^^}".name="${section^^}"" \
				"section."${section^^}".dir="/site/${section^^}/MMDD"" \
				"section."${section^^}".gl_credit_section=0" \
				"section."${section^^}".gl_stat_section=0" \
		>> "${rootdir}/.tmp/footools"

		sed -i "s/\bDIRS=\"/DIRS=\"\n\/site\/${section^^}\/\$today/" "${PACKAGES_PATH_GL_SCRIPTS}/Tur-AutoNuke/tur-autonuke.conf"
		sed -i "s/\bDIRS=\"/DIRS=\"\n\/site\/${section^^}\/\$yesterday/" "${PACKAGES_PATH_GL_SCRIPTS}/Tur-AutoNuke/tur-autonuke.conf"
		echo "INC${section^^}="${GL_Device}":"${glroot}/site/${section^^}":DATED" >> "${PACKAGES_PATH_GL_SCRIPTS}/Tur-Space/tur-space.conf.new"
		echo "${glroot}/site/${section^^}" >> "${rootdir}/.tmp/.fullpath"
	
		if [[ "${section^^}" = FLAC || "${section^^}" = MP3 ]]; then
			echo "/site/"${section^^}"/ " > "${rootdir}/.tmp/.section" 
			cat "${rootdir}/.tmp/.section" >> "${rootdir}/.tmp/.temp"
			awk -F '[" "]+' '{printf "$0"}' "${rootdir}/.tmp/.temp" > "${rootdir}/.tmp/.path"
		fi
		
		if [ "$(grep -c -w section$((counta+1))= "$cache")" = 0 ]; then
			echo "section$((counta+1))=\"$section\"" >> "$cache"
		fi
	
	else
		# FCT_CreateDir "${rootdir}/.tmp/site/${section^^}"
		mkdir -p "${rootdir}/.tmp/site/${section^^}"
		FCT_CHMOD 777 "${rootdir}/.tmp/site/${section^^}"
		echo "${section^^} " > "${rootdir}/.tmp/.section"
		cat "${rootdir}/.tmp/.section" >> "${rootdir}/.tmp/.sections"
		awk -F '[" "]+' '{printf "$0"}' "${rootdir}/.tmp/.sections" > "${rootdir}/.tmp/.validsections"
		#echo "set statsection($counta) \"${section^^}\"" >> "${rootdir}/.tmp/dzsstats"
		echo "set paths("${section^^}") 			\"/site/"${section^^}"/*\"" >> "${rootdir}/.tmp/dzsrace"
		echo "set chanlist("${section^^}") 			\""${EGGDROP_CONF_ANNOUNCE_CHANNELS}"\"" >> "${rootdir}/.tmp/dzschan"
		echo "/site/"${section^^}"/ " > "${rootdir}/.tmp/.section"
		cat "${rootdir}/.tmp/.section" >> "${rootdir}/.tmp/.temp"
		awk -F '[" "]+' '{printf "$0"}' "${rootdir}/.tmp/.temp" > "${rootdir}/.tmp/.path"
		#echo "#stat_section 	"${section^^}" /site/"${section^^}"/* no" >> "${rootdir}/.tmp/glstat"
		printf '%s\n' \
				"section."${section^^}".name="${section^^}""                \
				"section."${section^^}".dir=/site/"${section^^}""           \
				"section."${section^^}".gl_credit_section=0"              \
				"section."${section^^}".gl_stat_section=0"                \
			>> "${rootdir}/.tmp/footools"

		sed -i "s/\bDIRS=\"/DIRS=\"\n\/site\/${section^^}/" "${PACKAGES_PATH_GL_SCRIPTS}/Tur-AutoNuke/tur-autonuke.conf"
		echo "INC${section^^}="${GL_Device}":"${glroot}/site/${section^^}":" >> "${PACKAGES_PATH_GL_SCRIPTS}/Tur-Space/tur-space.conf.new"
		echo "${glroot}/site/"${section^^}"" >> "${rootdir}/.tmp/.fullpath"
		
		if [ "$(grep -c -w section$((counta+1))= "$cache")" = 0 ]; then
			echo "section$((counta+1))=\"$section\"" >> "$cache"
		fi
	
	fi
	incom
}

incom () {
	"${PACKAGES_PATH_GL_SCRIPTS}/tur-rules/rulesgen.sh" "${section^^}"
	echo "/site/_REQUESTS/" >> "${rootdir}/.tmp/.path"
}


## GLFTPD_INSTALL
GLFTPD_INSTALL () {
	if [[ -f "$cache" && "$(grep -c -w GL_SCRIPTS__eur0__pre_system "$cache")" = 1 ]]; then
		echo "Sections           = "$(cat "${rootdir}/.tmp/.validsections")""
	fi
	if [[ -f "$cache" && "$(grep -c -w router "$cache")" = 1 ]]; then
		echo "Router             = "$(grep -w router "$cache" | cut -d "=" -f2 | tr -d "\"")""
	fi
	if [[ -f "$cache" && "$(grep -c -w pasv_addr "$cache")" = 1 ]]; then
		echo "Passive address    = "$(grep -w pasv_addr "$cache" | cut -d "=" -f2 | tr -d "\"")""
	fi
	if [[ -f "$cache" && "$(grep -c -w pasv_ports "$cache")" = 1 ]]; then
		echo "Port range         = "$(grep -w pasv_ports "$cache" | cut -d "=" -f2 | tr -d "\"")""
	fi
	if [[ -f "$cache" && "$(grep -c -w GL_SCRIPTS__PSXC__IMDB_CHAN "$cache")" = 1 ]]; then
		echo "IMDB trigger chan  = "$(grep -w GL_SCRIPTS__PSXC__IMDB_CHAN "$cache" | cut -d "=" -f2 | tr -d "\"")""
	fi

	echo
	echo "--------[ Installation of software and scripts ]----------------------"
	
	cd "${PACKAGES_PATH}" || exit
	echo
	echo "Installing glftpd, please wait..."
	echo "####### Here starts glFTPD scripts of "${GL_SiteName}" #######" >> /var/spool/cron/crontabs/root
	cd "${GL_DIR_SOURCE}" || exit
	sed "s/changeme/${GL_Port}/" "${PACKAGES_PATH_DATA}/installgl.sh.org" > "${GL_DIR_SOURCE}/installgl.sh"
	FCT_CHMOD +x "${GL_DIR_SOURCE}/installgl.sh"
	export glservicename="glftpd-${GL_SiteName}"
	"${GL_DIR_SOURCE}/installgl.sh"
	echo "----> debug ----> $glservicename"
	#FCT_CreateDir "${glroot}/ftp-data/misc/"
	mkdir -p "${glroot}/ftp-data/misc/"
	echo "By SiteTechicien@GMail.Com" >> "${glroot}/ftp-data/misc/welcome.msg"
	echo -e "[\e[32mDone\e[0m]"
	cd "${PACKAGES_PATH_DATA}" || exit
		printf '%s\n' \
				'##########################################################################'            \
				'# Server shutdown: 0=server open, 1=deny all but siteops, !*=deny all, etc'            \
				'shutdown				1'                                                              \
				'#'                                                                                     \
				"sitename_long			"${GL_SiteName}""                                                 \
				"sitename_short			"${GL_SiteName}""                                                 \
				'email					SiteTechicien@GMail.Xom'                                        \
				"login_prompt			"${GL_SiteName}"[:space:]Ready"                                      \
				'mmap_amount			100'                                                            \
				'dl_sendfile			4096'                                                           \
				'# SECTION			KEYWORD			DIRECTORY			SEPARATE CREDITS'       \
				'stat_section		DEFAULT			*					no'                     \
		> glftpd.conf

	if [[ -f "$cache" && "$(grep -c -w router "$cache")" = 1 ]]; then
		router="$(grep -w router "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo -n "Do you use a router ? [Y]es [N]o, default N : " ; read -r router
	fi
	case "$router" in
		[Yy])
			ipcheck="$("${BINARY_WGET}" -qO- "${MYIPCHECK_URL_WEBSITE}"; echo)"
	
			if [[ -f "$cache" && "$(grep -c -w pasv_addr "$cache")" = 1 ]]; then
				pasv_addr="$(grep -w pasv_addr "$cache" | cut -d "=" -f2 | tr -d "\"")"
			else	
				echo -n "Please enter the DNS or IP for the site, default "$ipcheck" : " ; read -r pasv_addr
			fi
			
			if [ "$pasv_addr" = "" ]; then
				pasv_addr="$ipcheck"
			fi
		
			if [[ -f "$cache" && "$(grep -c -w pasv_ports "$cache")" = 1 ]]; then
				pasv_ports="$(grep -w pasv_ports "$cache" | cut -d "=" -f2 | tr -d "\"")"
			else
				echo -n "Please enter the port range for passive mode, default 6000-7000 : " ; read -r pasv_ports
			fi
		
			echo "pasv_addr		$pasv_addr	1" >> glftpd.conf
			
			if [ "$pasv_ports" = "" ]; then
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
	
	if [ "$(grep -c -w router= "$cache")" = 0 ]; then
		echo "router=\"$router\"" >> "$cache"
	fi
	
	if [[ "$(grep -c -w pasv_addr= "$cache")" = 0 && "$pasv_addr" != "" ]]; then
		echo "pasv_addr=\"$pasv_addr\"" >> "$cache"
	fi
	
	if [[ "$(grep -c -w pasv_ports= "$cache")" = 0 && "$pasv_addr" != "" ]]; then
		echo "pasv_ports=\"$pasv_ports\"" >> "$cache"
	fi
	
	#cat glstat >> glftpd.conf && rm glstat
	cat glfoot >> glftpd.conf 
	FCT_INSTALL glftpd.conf "${glroot}/etc/"
	FCT_INSTALL default.user "${glroot}/ftp-data/users/"
	printf '%s\n' \
		"59 23 * * * 		$(which chroot) "${glroot}" /bin/cleanup >/dev/null 2>&1"		\
		"29 4 * * * 		$(which chroot) "${glroot}" /bin/datacleaner >/dev/null 2>&1"	\
		"*/10 * * * *		"${glroot}/bin/incomplete-list-nuker.sh" >/dev/null 2>&1"		\
		"0 1 * * *			"${glroot}/bin/olddirclean2" -PD >/dev/null 2>&1"				\
	>> /var/spool/cron/crontabs/root
	touch "${glroot}/ftp-data/logs/incomplete-list-nuker.log"
	rm -f "${glroot}/README"
	rm -f "${glroot}/README.ALPHA"
	rm -f "${glroot}/UPGRADING"
	rm -f "${glroot}/changelog"
	rm -f "${glroot}/LICENSE"
	rm -f "${glroot}/glftpd.conf"
	rm -f "${glroot}/installgl.debug"
	rm -f "${glroot}/installgl.sh"
	rm -f "${glroot}/glftpd.conf.dist"
	rm -f "${glroot}/convert_to_2.0.pl"
	rm -f /etc/glftpd.conf
	FCT_INSTALL "${glroot}/create_server_key.sh" "${glroot}/etc/"
	FCT_INSTALL "${PACKAGES_PATH_DATA}/site.rules" "${glroot}/ftp-data/misc/"
	FCT_INSTALL incomplete-list.sh "${glroot}/bin/"
	FCT_INSTALL incomplete-list-nuker.sh "${glroot}/bin/"
	FCT_CHMOD 755 "${glroot}/site"
	#ln -s "${glroot}/etc/glftpd.conf" /etc/glftpd.conf
	FCT_CHMOD 777 "${glroot}/ftp-data/msgs"
	### A voir l'utilité ..
	#FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/extra/update_perms.sh" "${glroot}/bin/"
	#FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/extra/mkv_check.sh" "${glroot}/bin/"
	#FCT_INSTALL "$(which mkvinfo)" "${glroot}/bin/"
	#FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/extra/glftpd-version_check.sh" "${glroot}/bin/"
	#echo "0 18 * * *              "${glroot}/bin/glftpd-version_check.sh" >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
	chown -R root:root "${glroot}/bin/"
	FCT_CHMOD u+s "${glroot}/bin/sed"
	FCT_CHMOD u+s "${glroot}/bin/nuker"
	if [ -f "/etc/systemd/system/"${GL_SiteName}".socket" ]; then
		sed -i 's/#MaxConnections=64/MaxConnections=300/' "/etc/systemd/system/"${GL_SiteName}".socket"
	fi
	systemctl daemon-reload 
	systemctl restart ${glservicename}.socket
}

## EGGDROP
EGG_INSTALL () {
	Banner_Show "Installing eggdrop to '"${glroot}/sitebot"'" silent
	cd "${PACKAGES_PATH_DOWNLOADS}/eggdrop" || exit ;
	echo "./configure eggdrop in "${glroot}/sitebot", please wait..."
	FCT_EXEC_SHOW_ERROR ./configure --prefix="${glroot}/sitebot"
	echo "eggdrop : make config, please wait..."
	FCT_EXEC_SHOW_ERROR make config 
	echo "eggdrop : make, please wait..."
	FCT_EXEC_SHOW_ERROR make
	echo "eggdrop : make install, please wait..."
	FCT_EXEC_SHOW_ERROR make install
	echo "eggdrop : make sslsilent, please wait..."
	FCT_EXEC_SHOW_ERROR make sslsilent;
	cd "${PACKAGES_PATH_DATA}" || exit
	
	# FCT_CreateDir "${glroot}/sitebot/data"
	mkdir -p "${glroot}/sitebot/data"
	FCT_CHMOD 777 "${glroot}/sitebot/data"
	cat egghead > "${GL_SiteName}.conf"
	cat "${rootdir}/.tmp/eggchan" >> "${GL_SiteName}.conf"
	sed -e "s/changeme/"${GL_SiteName}"/" bot.chan > ""${glroot}"/sitebot/data/"${GL_SiteName}".chan"
	cat "${rootdir}/.tmp/bot.chan.tmp" >> ""${glroot}"/sitebot/data/"${GL_SiteName}".chan"
		printf '%s\n' \
			"set username			\""${GL_SiteName}"\""       \
			"set nick				\""${GL_SiteName}"\""       \
			"set altnick			\"_"${GL_SiteName}"\""      \
		> ""${GL_SiteName}".conf"
	sed -i "s/changeme/"$EGG__YOUR_IRC_NICKNAME"/" ""${GL_SiteName}".conf"
	FCT_INSTALL "${GL_SiteName}.conf" "${glroot}/sitebot/"
	FCT_INSTALL botchkhead .botchkhead
		printf '%s\n' \
			"botdir="${glroot}"/sitebot"                \
			"botscript=eggdrop"                     \
			"botname="${GL_SiteName}""                     \
			"userfile=./data/"${GL_SiteName}".user"        \
			"pidfile=pid."${GL_SiteName}""                 \
		> .botchkhead

	FCT_CHMOD 755 .botchkhead
	FCT_INSTALL .botchkhead "${glroot}/sitebot/botchk"
	cat botchkfoot >> "${glroot}/sitebot/botchk"
	touch "/var/spool/cron/crontabs/"${UNIX_USER_EGGDROP}""
	echo "*/10 * * * *	${glroot}/sitebot/botchk >/dev/null 2>&1" >> "/var/spool/cron/crontabs/"${UNIX_USER_EGGDROP}""
	FCT_CHMOD 777 "${glroot}/sitebot/logs"
	chown -R sitebot:glftpd "${glroot}/sitebot/"
	rm -f "${glroot}/sitebot/BOT.INSTALL"
	rm -f "${glroot}/sitebot/README"
	rm -f "${glroot}/sitebot/eggdrop1.8"
	rm -f "${glroot}/sitebot/${glroot}-tcl.old-TIMER"
	rm -f "${glroot}/sitebot/${glroot}.tcl-TIMER"
	
	rm -f "${glroot}/sitebot/eggdrop-basic.conf"
	rm -f "${glroot}/sitebot/scripts/CONTENTS"
	rm -f "${glroot}/sitebot/scripts/autobotchk"
	rm -f "${glroot}/sitebot/scripts/botchk"
	rm -f "${glroot}/sitebot/scripts/weed"
	ln -s "${glroot}/sitebot/eggdrop" "${glroot}/sitebot/sitebot"
	rm -f "${glroot}/sitebot/eggdrop"
	FCT_CHMOD 666 "${glroot}/etc/glftpd.conf"
	# FCT_CHMOD 666 "${glroot}/etc/glroot.conf"
	# FCT_CreateDir "${glroot}/site/_PRE/SiteOP" "${glroot}/site/_REQUESTS" "${glroot}/site/_SPEEDTEST"
	mkdir -p "${glroot}/site/_PRE/SiteOP" "${glroot}/site/_REQUESTS" "${glroot}/site/_SPEEDTEST"
	FCT_CHMOD 777 "${glroot}/site/_PRE" "${glroot}/site/_PRE/SiteOP" "${glroot}/site/_REQUESTS" "${glroot}/site/_SPEEDTEST"
	FCT_Create_SPEEDTEST_FILE
	rm -f "${glroot}/sitebot/scripts/*.tcl"
	FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/extra/*.tcl" "${glroot}/sitebot/scripts/"
	sed -i "s/#changeme/"${EGGDROP_CONF_ANNOUNCE_CHANNELS}"/" "${glroot}/sitebot/scripts/rud-news.tcl"
	sed -i "s/#personal/"${EGGDROP_CONF_ANNOUNCE_CHANNELS_ADMIN}"/" "${glroot}/sitebot/scripts/rud-news.tcl"
	
	sed -i "s/changeme/"${EGGDROP_CONF_ANNOUNCE_CHANNELS_ADMIN}"/g" "${glroot}/sitebot/scripts/tur-predircheck_manager.tcl"
	FCT_INSTALL "${PACKAGES_PATH_DATA}kill.sh" "${glroot}/sitebot/"
	sed -i "s/changeme/"${GL_SiteName}"/g" "${glroot}/sitebot/kill.sh"
	
	echo -e "[\e[32mDone\e[0m]"
}

FCT_Create_SPEEDTEST_FILE () {
	Banner_Show "Create speedtest files" silent
	dd if=/dev/urandom of="${glroot}/site/_SPEEDTEST/150MB" bs=1M count=150 >/dev/null 2>&1
	dd if=/dev/urandom of="${glroot}/site/_SPEEDTEST/250MB" bs=1M count=250 >/dev/null 2>&1
	dd if=/dev/urandom of="${glroot}/site/_SPEEDTEST/500MB" bs=1M count=500 >/dev/null 2>&1
	dd if=/dev/urandom of="${glroot}/site/_SPEEDTEST/1GB" bs=1M count=1000 >/dev/null 2>&1
	dd if=/dev/urandom of="${glroot}/site/_SPEEDTEST/5GB" bs=1M count=5000 >/dev/null 2>&1
	dd if=/dev/urandom of="${glroot}/site/_SPEEDTEST/10GB" bs=1M count=10000 >/dev/null 2>&1
}
EGG_CONFIG_IRC () {
	if [[ -f "$cache" && "$(grep -c -w EGG_IRC_SERVER "$cache")" = 1 ]]; then
		sed -i "s/EGG_IRC_SERVER/"${EGG_IRC_SERVER}"/" "${glroot}/sitebot/eggdrop.conf"
	else
		echo
	    	echo -n "What irc server ? default irc.example.org : " ; read -r EGG_IRC_SERVER
	
		if [ "$EGG_IRC_SERVER" = "" ]; then
			EGG_IRC_SERVER="irc.example.org"
		fi
		
		echo -n "What port for irc server ? default 7000 : " ; read -r EGG_IRC_PORT
		if [ "${EGG_IRC_PORT}" = "" ]; then
			EGG_IRC_PORT="7000"
		fi
		
		echo -n "Is the port above a SSL port ? [Y]es [N]o, default Y : " ; read -r serverssl
		case "$serverssl" in
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
		case "$serverpassword" in
			[Yy])
				echo -n "Please enter the password for irc server, default NULL : " ; read -r EGG_IRC_PASSWORD
				if [ "${EGG_IRC_PASSWORD}" = "" ]; then
					EGG_IRC_PASSWORD=""
				else
					EGG_IRC_PASSWORD=":"${EGG_IRC_PASSWORD}""
				fi
			;;
			[Nn])
				EGG_IRC_PASSWORD=""
			;;
			*)
				EGG_IRC_PASSWORD=""
			;;
		esac
		
		case "$ssl" in
			1)
				sed -i "s/EGG_IRC_SERVER/"${EGG_IRC_SERVER}":+"${EGG_IRC_PORT}""${EGG_IRC_PASSWORD}"/" "${glroot}/sitebot/eggdrop.conf"
				
				if [ "$(grep -c -w EGG_IRC_SERVER= "$cache")" = 0 ]; then
					echo "${EGG_IRC_SERVER}=\""${EGG_IRC_SERVER}":+"${EGG_IRC_PORT}""${EGG_IRC_PASSWORD}"\"" >> "$cache"
				fi
			;;
			0)
				sed -i "s/EGG_IRC_SERVER/"${EGG_IRC_SERVER}":"${EGG_IRC_PORT}""${EGG_IRC_PASSWORD}"/" "${glroot}/sitebot/eggdrop.conf"
				
				if [ "$(grep -c -w EGG_IRC_SERVER= "$cache")" = 0 ]; then
					echo "${EGG_IRC_SERVER}=\""${EGG_IRC_SERVER}":"${EGG_IRC_PORT}""${EGG_IRC_PASSWORD}"\"" >> "$cache"
				fi
			;;
		esac
	fi
}

## zsconfig.h
PZS_PATCH_CONFIG_FILE () {
	cd "${PACKAGES_PATH_DOWNLOADS}/${GL_SiteName}/pzs-ng" || exit
	cat "${PACKAGES_PATH_DATA}/pzshead" > zsconfig.h
	path="$(cat ""${rootdir}"/.tmp/.path")"
	printf '%s\n' \
			"#define check_for_missing_nfo_dirs				\"$path\"" \
			"#define cleanupdirs							\"$path\"" \
			"#define cleanupdirs_dated						\"/site/0DAY/%m%d/ /site/FLAC/%m%d/ /site/MP3/%m%d/ /site/EBOOKS/%m%d/\"" \
			"#define sfv_dirs								\"$path\"" \
			"#define short_sitename							\"${GL_SiteName}\"" \
	>> zsconfig.h

	FCT_CHMOD 755 zsconfig.h
	FCT_INSTALL zsconfig.h "${PACKAGES_PATH_DOWNLOADS}/${GL_SiteName}/pzs-ng/zipscript/conf/zsconfig.h"
}

## dZSbot.tcl
PZS_CONFIG_CHANNELS () {
	echo "REQUEST" >> "${rootdir}/.tmp/.validsections"
	echo "set paths(REQUEST)							\"/site/_REQUESTS/*/*\"" >> "${rootdir}/.tmp/dzsrace"
	echo "set chanlist(REQUEST)							\"${EGGDROP_CONF_ANNOUNCE_CHANNELS}\"" >> "${rootdir}/.tmp/dzschan"
	printf '%s\n' \
			"$(cat "${PACKAGES_PATH_DATA}/dzshead")" \
			"set device(0)"							'"'${GL_Device} SITE'"' \
			"$(cat "${PACKAGES_PATH_DATA}/dzsbnc")" \
			"$(cat "${PACKAGES_PATH_DATA}/dzsmidl")" \
			"set sections							\"$(cat "${rootdir}/.tmp/.validsections")\"" \
			'' \
			"$(cat "${rootdir}/.tmp/dzsrace")" \
			"$(cat "${rootdir}/.tmp/dzschan")" \
			"$(cat "${PACKAGES_PATH}/data/dzsfoot")" \
	> ngBot.conf

	FCT_CHMOD 644 ngBot.conf
	rm "${rootdir}/.tmp/dzsrace"
	rm "${rootdir}/.tmp/dzschan"
	# FCT_CreateDir "${glroot}/sitebot/scripts/pzs-ng/themes"
	mkdir -p "${glroot}/sitebot/scripts/pzs-ng/themes"
	FCT_INSTALL ngBot.conf "${glroot}/sitebot/scripts/pzs-ng/ngBot.conf"
}

## PROJECTZS
PZS_INSTALL () {
	# if [[ -f "$cache" && "$(grep -c -w GL_SCRIPTS__eur0__pre_system "$cache")" = 0 ]]; then
		# echo
	# fi
	echo "Installing pzs-ng, please wait..."
	cd "${PACKAGES_PATH_DOWNLOADS}/${GL_SiteName}/pzs-ng" || exit
	FCT_EXEC_SHOW_ERROR ./configure
	FCT_EXEC_SHOW_ERROR make
	FCT_EXEC_SHOW_ERROR make install
	FCT_EXEC_SHOW_ERROR "${glroot}/libcopy.sh"
	echo -e "[\e[32mDone\e[0m]"
	FCT_INSTALL sitebot/ngB* "${glroot}/sitebot/scripts/pzs-ng/"
	FCT_INSTALL sitebot/modules "${glroot}/sitebot/scripts/pzs-ng/"
	FCT_INSTALL sitebot/plugins "${glroot}/sitebot/scripts/pzs-ng/"
	FCT_INSTALL sitebot/themes "${glroot}/sitebot/scripts/pzs-ng/"
	FCT_INSTALL "${PACKAGES_PATH_DATA}/glftpd.installer.theme" "${glroot}/sitebot/scripts/pzs-ng/themes/"
	FCT_INSTALL "${PACKAGES_PATH_DATA}/ngBot.vars" "${glroot}/sitebot/scripts/pzs-ng/"
	FCT_INSTALL "${PACKAGES_PATH_DATA}/sitewho.conf" "${glroot}/bin/"
	cd "${PACKAGES_PATH_GL_SCRIPTS}" || exit
	FCT_CHMOD u+s "${glroot}/bin/cleanup"
	rm -f "${glroot}/sitebot/scripts/pzs-ng/ngBot.conf.dist"
}

## Tur-Space
GL_SCRIPTS__Tur__Space () {
	if [[ -f "$cache" && "$(grep -c -w GL_SCRIPTS__Tur__Space "$cache")" = 1 ]]; then
		ask="$(grep -w GL_SCRIPTS__Tur__Space "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo
		echo -e "\e[4mDescription for Tur-Space:\e[0m"
		FCT_GIT_GET_DESCRIPTION "${GIT_URL__GL_SCRIPTS__Tur__Space}"
		echo
		echo -n "Install Tur-Space ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case "$ask" in
		[Nn])
			if [ "$(grep -c -w GL_SCRIPTS__Tur__Space= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__Space=\"n\"" >> "$cache"
			fi
		;;
		[Yy]|*)
			if [ "$(grep -c -w GL_SCRIPTS__Tur__Space= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__Space=\"y\"" >> "$cache"
			fi
			echo "Installing Tur-Space, please wait..."
			FCT_GIT_GET "${GIT_URL__GL_SCRIPTS__Tur__Space}" "${PACKAGES_PATH_GL_SCRIPTS}/Tur-Space"
			cd "${PACKAGES_PATH_GL_SCRIPTS}/Tur-Space" || exit
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/Tur-Space/tur-space.conf" "${PACKAGES_PATH_GL_SCRIPTS}/Tur-Space/tur-space.conf.new"
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/Tur-Space/tur-space.conf.new" "${glroot}/bin/tur-space.conf"
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/Tur-Space/tur-space.sh" "${glroot}/bin/"
			printf '%s\n' \
				'[TRIGGER]'                            \
				"TRIGGER="${GL_Device}":25000:50000"   \
				''                                     \
				'[INCOMING]'                           \
			>> "${PACKAGES_PATH_GL_SCRIPTS}/Tur-Space/tur-space.conf.new"
			echo "#*/5 * * * *		${glroot}/bin/tur-space.sh go >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
			touch "${glroot}/ftp-data/logs/tur-space.log"
			#FCT_INSTALL idlebotkick.sh "${glroot}/bin/"
			#sed -i "s/changeme/"${GL_Port}"/g" "${glroot}/bin/idlebotkick.sh"
			#FCT_CHMOD 755 "${glroot}/bin/idlebotkick.sh"
			#FCT_INSTALL "idlebotkick.tcl" "${glroot}/sitebot/scripts/"
			#echo "source scripts/idlebotkick.tcl" >> "${glroot}/sitebot/eggdrop.conf"
			cd ..
			echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}
## idlebotkick
GL_SCRIPTS__Tur__IdleBotKick () {
	if [[ -f "$cache" && "$(grep -c -w GL_SCRIPTS__Tur__IdleBotKick "$cache")" = 1 ]]; then
		ask="$(grep -w GL_SCRIPTS__Tur__IdleBotKick "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo
		echo -e "\e[4mDescription for Idlebotkick:\e[0m"
		FCT_GIT_GET_DESCRIPTION "${GIT_URL__GL_SCRIPTS__Tur__IdleBotKick}"
		echo
		echo -n "Install Idlebotkick ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case "$ask" in
		[Nn])
			if [ "$(grep -c -w GL_SCRIPTS__Tur__IdleBotKick= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__IdleBotKick=\"n\"" >> "$cache"
			fi
		;;
		[Yy]|*)
			if [ "$(grep -c -w GL_SCRIPTS__Tur__IdleBotKick= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__IdleBotKick=\"y\"" >> "$cache"
			fi
			echo "Installing Idlebotkick, please wait..."
			FCT_GIT_GET "${GIT_URL__GL_SCRIPTS__Tur__IdleBotKick}" "${PACKAGES_PATH_GL_SCRIPTS}/Tur-IdleBotKick"
			cd "${PACKAGES_PATH_GL_SCRIPTS}/Tur-IdleBotKick" || exit
			FCT_INSTALL idlebotkick.sh "${glroot}/bin/"
			sed -i "s/changeme/"${GL_Port}"/g" "${glroot}/bin/idlebotkick.sh"
			FCT_CHMOD 755 "${glroot}/bin/idlebotkick.sh"
			FCT_INSTALL "idlebotkick.tcl" "${glroot}/sitebot/scripts/"
			echo "source scripts/idlebotkick.tcl" >> "${glroot}/sitebot/eggdrop.conf"
			cd ..
			echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}

## Tur-IrcAdmin
GL_SCRIPTS__Tur__IrcAdmin () {
	if [[ -f "$cache" && "$(grep -c -w GL_SCRIPTS__Tur__IrcAdmin "$cache")" = 1 ]]; then
		ask="$(grep -w GL_SCRIPTS__Tur__IrcAdmin "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo
		echo -e "\e[4mDescription for Tur-IrcAdmin:\e[0m"
		FCT_GIT_GET_DESCRIPTION "${GIT_URL__GL_SCRIPTS__Tur__IrcAdmin}"
		echo
		echo -n "Install Tur-IrcAdmin? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case "$ask" in
		[Nn])
			if [ "$(grep -c -w GL_SCRIPTS__Tur__IrcAdmin= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__IrcAdmin=\"n\"" >> "$cache"
			fi
		;;
		[Yy]|*)
			if [ "$(grep -c -w GL_SCRIPTS__Tur__IrcAdmin= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__IrcAdmin=\"y\"" >> "$cache"
			fi
			
			echo "Installing Tur-IrcAdmin, please wait..."
			FCT_GIT_GET "${GIT_URL__GL_SCRIPTS__Tur__IrcAdmin}" "${PACKAGES_PATH_GL_SCRIPTS}/Tur-IrcAdmin"
			
			cd "${PACKAGES_PATH_GL_SCRIPTS}/Tur-IrcAdmin" || exit
			FCT_INSTALL tur-ircadmin.sh "${glroot}/bin/"
			FCT_CHMOD 755 "${glroot}/bin/tur-ircadmin.sh"
			FCT_INSTALL tur-ircadmin.tcl "${glroot}/sitebot/scripts/"
			touch "${glroot}/ftp-data/logs/tur-ircadmin.log"
			FCT_CHMOD 666 "${glroot}/ftp-data/logs/tur-ircadmin.log"
			echo "source scripts/tur-ircadmin.tcl" >> "${glroot}/sitebot/eggdrop.conf"
			sed -i "s/changeme/"${EGGDROP_CONF_ANNOUNCE_CHANNELS_ADMIN}"/" "${glroot}/sitebot/scripts/tur-ircadmin.tcl"
			sed -i "s/changeme/"${GL_Port}"/" "${glroot}/bin/tur-ircadmin.sh"
			cd ..
			echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}

## Tur-Request
GL_SCRIPTS__Tur__Request () {
	if [[ -f "$cache" && "$(grep -c -w GL_SCRIPTS__Tur__Request "$cache")" = 1 ]]; then
		ask="$(grep -w GL_SCRIPTS__Tur__Request "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo
		echo -e "\e[4mDescription for Tur-Request:\e[0m"
		FCT_GIT_GET_DESCRIPTION "${GIT_URL__GL_SCRIPTS__Tur__Request}"
		echo
		echo -n "Install Tur-Request ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case "$ask" in
		[Nn])
			if [ "$(grep -c -w GL_SCRIPTS__Tur__Request= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__Request=\"n\"" >> "$cache"
			fi
		;;
		[Yy]|*)
			if [ "$(grep -c -w GL_SCRIPTS__Tur__Request= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__Request=\"y\"" >> "$cache"
			fi
			FCT_GIT_GET "${GIT_URL__GL_SCRIPTS__Tur__Request}" "${PACKAGES_PATH_GL_SCRIPTS}/Tur-Request"
			echo "Installing Tur-Request, please wait..."
			cd "${PACKAGES_PATH_GL_SCRIPTS}/Tur-Request" || exit
			FCT_INSTALL tur-request.sh "${glroot}/bin/"
			FCT_CHMOD 755 "${glroot}/bin/tur-request.sh"
			FCT_INSTALL ./*.tcl "${glroot}/sitebot/scripts/"
			FCT_INSTALL file_date "${glroot}/bin/"
			sed -e "s/changeme/"${GL_SiteName}"/" tur-request.conf > "${glroot}/bin/tur-request.conf"
			touch "${glroot}/site/_REQUESTS/.requests";
			FCT_CHMOD 666 "${glroot}/site/_REQUESTS/.requests"
			echo "1 18 * * * 		${glroot}/bin/tur-request.sh status auto >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
			echo "1 0 * * * 		${glroot}/bin/tur-request.sh checkold >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
			touch "${glroot}/ftp-data/logs/tur-request.log"
			FCT_CHMOD 666 "${glroot}/ftp-data/logs/tur-request.log"
			echo "source scripts/tur-request.auth.tcl" >> "${glroot}/sitebot/eggdrop.conf"
			cat gl >> "${glroot}/etc/glftpd.conf"
			cd ..
			echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}

## Tur-Trial3
GL_SCRIPTS__Tur__Trial () {
	if [[ -f "$cache" && "$(grep -c -w GL_SCRIPTS__Tur__Trial "$cache")" = 1 ]]; then
		ask=$(grep -w GL_SCRIPTS__Tur__Trial "$cache" | cut -d "=" -f2 | tr -d "\"")
	else
		echo
		echo -e "\e[4mDescription for Tur-Trial3:\e[0m"
		FCT_GIT_GET_DESCRIPTION "${GIT_URL__GL_SCRIPTS__Tur__Trial3}"
		echo
		echo -n "Install Tur-Trial3 ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case "$ask" in
		[Nn])
			if [ "$(grep -c -w GL_SCRIPTS__Tur__Trial= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__Trial=\"n\"" >> "$cache"
			fi
			#echo "0 0 * * * 		${glroot}/bin/reset -d" >> /var/spool/cron/crontabs/root
		;;
		[Yy]|*)
			if [ "$(grep -c -w GL_SCRIPTS__Tur__Trial= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__Trial=\"y\"" >> "$cache"
			fi
			
			if [ ! -e "/usr/bin/mysql" ]; then
				echo
				echo "Tur-Trial3 needs a SQL server but MySQL was not found on your server"
				echo "No need to panic though, Tur-Trial3 will still be installed - you will just have to install"
				echo "MySQL before you can use the script."
				echo
			fi
			FCT_GIT_GET "${GIT_URL__GL_SCRIPTS__Tur__Trial3}" "${PACKAGES_PATH_GL_SCRIPTS}/Tur-Trial3"
			echo "Installing Tur-Trial3, please wait..."
			cd "${PACKAGES_PATH_GL_SCRIPTS}/Tur-Trial3" || exit 
			FCT_INSTALL ./*.sh					"${glroot}/bin/"
			FCT_INSTALL tur-trial3.conf.conf	"${glroot}/bin/"
			FCT_INSTALL tur-trial3.theme		"${glroot}/bin/"
			FCT_INSTALL tur-trial3.tcl			"${glroot}/sitebot/scripts/"
			echo "source scripts/tur-trial3.tcl" >> "${glroot}/sitebot/eggdrop.conf"
			echo "*/31 * * * * 		${glroot}/bin/tur-trial3.sh update >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
			echo "*/30 * * * * 		${glroot}/bin/tur-trial3.sh tcron >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
			echo "45 23 * * * 		${glroot}/bin/tur-trial3.sh qcron >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
			echo "0 0 * * * 		${glroot}/bin/midnight.sh >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
			
			if [ -f "$(which mysql)" ]; then
				FCT_INSTALL "$(which mysql)" "${glroot}/bin/"
			fi
			
			cat gl >> "${glroot}/etc/glftpd.conf"
			cd ..
			touch "${glroot}/ftp-data/logs/tur-trial3.log"
			echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}

## Tur-Vacation
GL_SCRIPTS__Tur__Vacation () {
	if [[ -f "$cache" && "$(grep -c -w GL_SCRIPTS__Tur__Vacation "$cache")" = 1 ]]; then
		ask="$(grep -w GL_SCRIPTS__Tur__Vacation "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo
		echo -e "\e[4mDescription for Tur-Vacation:\e[0m"
		FCT_GIT_GET_DESCRIPTION "${GIT_URL__GL_SCRIPTS__Tur__Vacation}"
		echo
		echo -n "Install Tur-Vacation ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case "$ask" in
		[Nn])
			if [ "$(grep -c -w GL_SCRIPTS__Tur__Vacation= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__Vacation=\"n\"" >> "$cache"
			fi
		;;
		[Yy]|*)
			if [ "$(grep -c -w GL_SCRIPTS__Tur__Vacation= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__Vacation=\"y\"" >> "$cache"
			fi
			FCT_GIT_GET "${GIT_URL__GL_SCRIPTS__Tur__Trial3}" "${PACKAGES_PATH_GL_SCRIPTS}/Tur-Vacation"
			echo "Installing Tur-Vacation, please wait..."
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/Tur-Vacation/tur-vacation.sh" "${glroot}/bin/"
			touch "${glroot}/etc/vacation.index";
			FCT_CHMOD 666 "${glroot}/etc/vacation.index"
			touch "${glroot}/etc/quota_vacation.db";
			FCT_CHMOD 666 "${glroot}/etc/quota_vacation.db"
			cat "${PACKAGES_PATH_GL_SCRIPTS}/Tur-Vacation/gl" >> "${glroot}/etc/glftpd.conf"
			echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}

## Tur-Vacation
GL_SCRIPTS__Tur__Tuls () {
	if [[ -f "$cache" && "$(grep -c -w GL_SCRIPTS__Tur__Tuls "$cache")" = 1 ]]; then
		ask="$(grep -w GL_SCRIPTS__Tur__Tuls "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo
		echo -e "\e[4mDescription for Tur-Vacation:\e[0m"
		FCT_GIT_GET_DESCRIPTION "${GIT_URL__GL_SCRIPTS__Tur__Tuls}"
		echo
		echo -n "Install Tur-Tuls ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case "$ask" in
		[Nn])
			if [ "$(grep -c -w GL_SCRIPTS__Tur__Tuls= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__Tuls=\"n\"" >> "$cache"
			fi
		;;
		[Yy]|*)
			if [ "$(grep -c -w GL_SCRIPTS__Tur__Tuls= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__Tuls=\"y\"" >> "$cache"
			fi
			FCT_GIT_GET "${GIT_URL__GL_SCRIPTS__Tur__Tuls}" "${PACKAGES_PATH_GL_SCRIPTS}/Tur-Tuls"
			echo "Installing Tur-Tuls, please wait..."
			FCT_EXEC_SHOW_ERROR ${BINARY_GCC} "${PACKAGES_PATH_GL_SCRIPTS}/Tur-Tuls/tuls.c" -o "${glroot}/bin/tuls"
			echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}

## Tur-WhereAmi
GL_SCRIPTS__Tur__WhereAmi () {
	if [[ -f "$cache" && "$(grep -c -w GL_SCRIPTS__Tur__WhereAmi "$cache")" = 1 ]]; then
		ask="$(grep -w GL_SCRIPTS__Tur__WhereAmi "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo
		echo -e "\e[4mDescription for Tur-WhereAmi:\e[0m"
		FCT_GIT_GET_DESCRIPTION "${GIT_URL__GL_SCRIPTS__Tur__WhereAmi}"
		echo
		echo -n "Install Tur-WhereAmi ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case "$ask" in
		[Nn])
			if [ "$(grep -c -w GL_SCRIPTS__Tur__WhereAmi= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__WhereAmi=\"n\"" >> "$cache"
			fi
		;;
		[Yy]|*)
			if [ "$(grep -c -w GL_SCRIPTS__Tur__WhereAmi= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__WhereAmi=\"y\"" >> "$cache"
			fi
			FCT_GIT_GET "${GIT_URL__GL_SCRIPTS__Tur__WhereAmi}" "${PACKAGES_PATH_GL_SCRIPTS}/Tur-WhereAmi"
			echo "Installing Tur-WhereAmi, please wait..."
			
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/Tur-WhereAmi/whereami.sh" "${glroot}/bin/"
			FCT_CHMOD 755 "${glroot}/bin/whereami.sh"
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/Tur-WhereAmi/whereami.tcl" "${glroot}/sitebot/scripts/"
			echo "source scripts/whereami.tcl" >> "${glroot}/sitebot/eggdrop.conf"
			echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}


## Tur-Undupe
GL_SCRIPTS__Tur__Undupe () {
	if [[ -f "$cache" && "$(grep -c -w GL_SCRIPTS__Tur__Undupe "$cache")" = 1 ]]; then
		ask="$(grep -w GL_SCRIPTS__Tur__Undupe "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo
		echo -e "\e[4mDescription for Tur-Undupe:\e[0m"
		FCT_GIT_GET_DESCRIPTION "${GIT_URL__GL_SCRIPTS__Tur__Undupe}"
		echo
		echo -n "Install Tur-Undupe ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case "$ask" in
		[Nn])
			if [ "$(grep -c -w GL_SCRIPTS__Tur__Undupe= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__Undupe=\"n\"" >> "$cache"
			fi
		;;
		[Yy]|*)
			if [ "$(grep -c -w GL_SCRIPTS__Tur__Undupe= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__Undupe=\"y\"" >> "$cache"
			fi
			FCT_GIT_GET "${GIT_URL__GL_SCRIPTS__Tur__Undupe}" "${PACKAGES_PATH_GL_SCRIPTS}/Tur-Undupe"
			echo "Installing Tur-Undupe, please wait..."
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/Tur-Undupe/tur-undupe.sh" "${glroot}/bin/"
			FCT_CHMOD 755 "${glroot}/bin/tur-undupe.sh"
			FCT_CHMOD u+s "${glroot}/bin/undupe"
			FCT_CHMOD 6755 "${glroot}/bin/undupe"
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/Tur-Undupe/tur-undupe.tcl" "${glroot}/sitebot/scripts/"
			echo "source scripts/tur-undupe.tcl" >> "${glroot}/sitebot/eggdrop.conf"
			echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}

## Tur-FTPWho
GL_SCRIPTS__Tur__FTPWho () {
	if [[ -f "$cache" && "$(grep -c -w GL_SCRIPTS__Tur__FTPWho "$cache")" = 1 ]]; then
		ask="$(grep -w GL_SCRIPTS__Tur__FTPWho "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo
		echo -e "\e[4mDescription for Tur-FTPWho:\e[0m"
		FCT_GIT_GET_DESCRIPTION "${GIT_URL__GL_SCRIPTS__Tur__FTPWho}"
		echo
		echo -n "Install Tur-FTPWho ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case "$ask" in
		[Nn])
			if [ "$(grep -c -w GL_SCRIPTS__Tur__FTPWho= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__FTPWho=\"n\"" >> "$cache"
			fi
		;;
		[Yy]|*)
			if [ "$(grep -c -w GL_SCRIPTS__Tur__FTPWho= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__FTPWho=\"y\"" >> "$cache"
			fi
			FCT_GIT_GET "${GIT_URL__GL_SCRIPTS__Tur__FTPWho}" "${PACKAGES_PATH_GL_SCRIPTS}/Tur-FTPWho"
			${BINARY_GCC} -O2 "${PACKAGES_PATH_GL_SCRIPTS}/Tur-FTPWho/tur-ftpwho.c" -o "${glroot}/bin/tur-ftpwho"
			echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}

## Tur-PreCheck
GL_SCRIPTS__Tur__PreCheck () {
	if [[ -f "$cache" && "$(grep -c -w GL_SCRIPTS__Tur__PreCheck "$cache")" = 1 ]]; then
		ask="$(grep -w GL_SCRIPTS__Tur__PreCheck "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo
		echo -e "\e[4mDescription for Tur-PreCheck:\e[0m"
		FCT_GIT_GET_DESCRIPTION "${GIT_URL__GL_SCRIPTS__Tur__PreCheck}"
		echo
		echo -n "Install Tur-PreCheck ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case "$ask" in
		[Nn])
			if [ "$(grep -c -w GL_SCRIPTS__Tur__PreCheck= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__PreCheck=\"n\"" >> "$cache"
			fi
		;;
		[Yy]|*)
			if [ "$(grep -c -w GL_SCRIPTS__Tur__PreCheck= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__PreCheck=\"y\"" >> "$cache"
			fi
			FCT_GIT_GET "${GIT_URL__GL_SCRIPTS__Tur__PreCheck}" "${PACKAGES_PATH_GL_SCRIPTS}/Tur-PreCheck"
			echo "Installing Tur-PreCheck, please wait..."
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/Tur-PreCheck/precheck*.sh" "${glroot}/bin/"
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/Tur-PreCheck/tur-precheck.sh" "${glroot}/bin/"
			FCT_CHMOD +x "${glroot}/bin/precheck*.sh"
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/Tur-PreCheck/precheck.tcl" "${glroot}/sitebot/scripts/"
			echo "source scripts/precheck.tcl" >> "${glroot}/sitebot/eggdrop.conf"
			touch "${glroot}/ftp-data/logs/precheck.log"
			echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}

## Tur-PreDirCheck
GL_SCRIPTS__Tur__PreDirCheck () {
	if [[ -f "$cache" && "$(grep -c -w GL_SCRIPTS__Tur__PreDirCheck "$cache")" = 1 ]]; then
		ask="$(grep -w GL_SCRIPTS__Tur__PreDirCheck "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo
		echo -e "\e[4mDescription for Tur-PreDirCheck:\e[0m"
		FCT_GIT_GET_DESCRIPTION "${GIT_URL__GL_SCRIPTS__Tur__PreDirCheck}"
		echo
		echo -n "Install Tur-PreDirCheck ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case "$ask" in
		[Nn])
			if [ "$(grep -c -w GL_SCRIPTS__Tur__PreDirCheck= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__PreDirCheck=\"n\"" >> "$cache"
			fi
		;;
		[Yy]|*)
			if [ "$(grep -c -w GL_SCRIPTS__Tur__PreDirCheck= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__PreDirCheck=\"y\"" >> "$cache"
			fi
			FCT_GIT_GET "${GIT_URL__GL_SCRIPTS__Tur__PreDirCheck}" "${PACKAGES_PATH_GL_SCRIPTS}/Tur-PreDirCheck"
			echo "Installing Tur-PreDirCheck, please wait..."
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/Tur-PreDirCheck/tur-predircheck.sh" "${glroot}/bin/"
			${BINARY_GCC} "${PACKAGES_PATH_GL_SCRIPTS}/Tur-PreDirCheck/glftpd2/dirloglist_gl.c" -o "${glroot}/bin/dirloglist_gl"
			echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}
## Tur-Free
GL_SCRIPTS__Tur__Free () {
	if [[ -f "$cache" && "$(grep -c -w GL_SCRIPTS__Tur__Free "$cache")" = 1 ]]; then
		ask="$(grep -w GL_SCRIPTS__Tur__Free "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo
		echo -e "\e[4mDescription for Tur-Free:\e[0m"
		FCT_GIT_GET_DESCRIPTION "${GIT_URL__GL_SCRIPTS__Tur__Free}"
		echo
		echo -n "Install Tur-Free ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case "$ask" in
		[Nn])
			if [ "$(grep -c -w GL_SCRIPTS__Tur__Free= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__Free=\"n\"" >> "$cache"
			fi
		;;
		[Yy]|*)
			if [ "$(grep -c -w GL_SCRIPTS__Tur__Free= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__Free=\"y\"" >> "$cache"
			fi
			FCT_GIT_GET "${GIT_URL__GL_SCRIPTS__Tur__Free}" "${PACKAGES_PATH_GL_SCRIPTS}/Tur-Free"
			echo "Installing Tur-Free, please wait..."
			sed -i "s/changeme/"${GL_SiteName}"/" "${glroot}/bin/tur-free.sh"
			sed -i '/^SECTIONS/a '"TOTAL:"${GL_Device}"" "${glroot}/bin/tur-free.sh"
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/Tur-Free/*.tcl" "${glroot}/sitebot/scripts/"
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/Tur-Free/tur-free.sh" "${glroot}/bin/"
			echo "source scripts/tur-free.tcl" >> "${glroot}/sitebot/eggdrop.conf"
			echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}

## Tur-PreDirCheck
GL_SCRIPTS__Tur__PreDirCheck_Manager () {
	if [[ -f "$cache" && "$(grep -c -w GL_SCRIPTS__Tur__PreDirCheck_Manager "$cache")" = 1 ]]; then
		ask="$(grep -w GL_SCRIPTS__Tur__PreDirCheck_Manager "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo
		echo -e "\e[4mDescription for Tur-PreDirCheck:\e[0m"
		FCT_GIT_GET_DESCRIPTION "${GIT_URL__GL_SCRIPTS__Tur__PreDirCheck_Manager}"
		echo
		echo -n "Install Tur-PreDirCheck_Manager ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case "$ask" in
		[Nn])
			if [ "$(grep -c -w GL_SCRIPTS__Tur__PreDirCheck_Manager= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__PreDirCheck_Manager=\"n\"" >> "$cache"
			fi
		;;
		[Yy]|*)
			if [ "$(grep -c -w GL_SCRIPTS__Tur__PreDirCheck_Manager= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__PreDirCheck_Manager=\"y\"" >> "$cache"
			fi
			FCT_GIT_GET "${GIT_URL__GL_SCRIPTS__Tur__PreDirCheck_Manager}" "${PACKAGES_PATH_GL_SCRIPTS}/Tur-PreDirCheck_Manager"
			echo "Installing Tur-PreDirCheck_Manager, please wait..."
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/Tur-PreDirCheck_Manager/tur-predircheck_manager.tcl" "${glroot}/sitebot/scripts/"
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/Tur-PreDirCheck_Manager/tur-predircheck_manager.sh" "${glroot}/bin/"
			echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}

## Tur-Rules
GL_SCRIPTS__Tur__Rules () {
	if [[ -f "$cache" && "$(grep -c -w GL_SCRIPTS__Tur__Rules "$cache")" = 1 ]]; then
		ask="$(grep -w GL_SCRIPTS__Tur__Rules "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo
		echo -e "\e[4mDescription for Tur-PreDirCheck:\e[0m"
		FCT_GIT_GET_DESCRIPTION "${GIT_URL__GL_SCRIPTS__Tur__Rules}"
		echo
		echo -n "Install Tur-PreDirCheck_Manager ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case "$ask" in
		[Nn])
			if [ "$(grep -c -w GL_SCRIPTS__Tur__Rules= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__Rules=\"n\"" >> "$cache"
			fi
		;;
		[Yy]|*)
			if [ "$(grep -c -w GL_SCRIPTS__Tur__Rules= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__Rules=\"y\"" >> "$cache"
			fi
			FCT_GIT_GET "${GIT_URL__GL_SCRIPTS__Tur__Rules}" "${PACKAGES_PATH_GL_SCRIPTS}/Tur-Rules"
			echo "Installing Tur-Rules, please wait..."
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/Tur-Rules/tur-rules.sh" "${glroot}/bin/"
			FCT_INSTALL ${PACKAGES_PATH_GL_SCRIPTS}/Tur-Rules/*.tcl "${glroot}/sitebot/scripts/"
			FCT_CHMOD 755 "${PACKAGES_PATH_GL_SCRIPTS}/Tur-Rules/rulesgen.sh"
			"${PACKAGES_PATH_GL_SCRIPTS}/Tur-Rules/rulesgen.sh" MISC
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/Tur-Rules/tur-rules.sh.org" "${PACKAGES_PATH_GL_SCRIPTS}/Tur-Rules/tur-rules.sh"
			"${PACKAGES_PATH_GL_SCRIPTS}/Tur-Rules/rulesgen.sh" GENERAL
			echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}

## Tur__AutoNuke
GL_SCRIPTS__Tur__AutoNuke () {
	if [[ -f "$cache" && "$(grep -c -w GL_SCRIPTS__Tur__AutoNuke "$cache")" = 1 ]]; then
		ask="$(grep -w GL_SCRIPTS__Tur__AutoNuke "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo
		echo -e "\e[4mDescription for Tur-AutoNuke:\e[0m"
		FCT_GIT_GET_DESCRIPTION "${GIT_URL__GL_SCRIPTS__Tur__AutoNuke}"
		echo
		echo -n "Install AutoNuke ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case "$ask" in
		[Nn])
			if [ "$(grep -c -w GL_SCRIPTS__Tur__AutoNuke= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__AutoNuke=\"n\"" >> "$cache"
			fi
		;;
		[Yy]|*)
			if [ "$(grep -c -w GL_SCRIPTS__Tur__AutoNuke= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__AutoNuke=\"y\"" >> "$cache"
			fi
			FCT_GIT_GET "${GIT_URL__GL_SCRIPTS__Tur__AutoNuke}" "${PACKAGES_PATH_GL_SCRIPTS}/Tur-AutoNuke"
			echo "Installing Tur-AutoNuke, please wait..."
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/Tur-AutoNuke/tur-autonuke.conf" "${glroot}/bin/"
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/Tur-AutoNuke/tur-autonuke.sh" "${glroot}/bin/"
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/Tur-AutoNuke/tur-autonuke.conf.org" "${PACKAGES_PATH_GL_SCRIPTS}/Tur-AutoNuke/tur-autonuke.conf"
			echo "*/10 * * * *		${glroot}/bin/tur-autonuke.sh >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
			touch "${glroot}/ftp-data/logs/tur-autonuke.log"
			echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}
## Tur-AddIp
GL_SCRIPTS__Tur__AddIp () {
	if [[ -f "$cache" && "$(grep -c -w GL_SCRIPTS__Tur__AddIp "$cache")" = 1 ]]; then
		ask="$(grep -w GL_SCRIPTS__Tur__AddIp "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo
		echo -e "\e[4mDescription for Tur-AddIp:\e[0m"
		FCT_GIT_GET_DESCRIPTION "${GIT_URL__GL_SCRIPTS__Tur__AddIp}"
		echo
		echo -n "Install Tur-AddIp ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case "$ask" in
		[Nn])
			if [ "$(grep -c -w GL_SCRIPTS__Tur__AddIp= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__AddIp=\"n\"" >> "$cache"
			fi
		;;
		[Yy]|*)
			if [ "$(grep -c -w GL_SCRIPTS__Tur__AddIp= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__AddIp=\"y\"" >> "$cache"
			fi
			FCT_GIT_GET "${GIT_URL__GL_SCRIPTS__Tur__AddIp}" "${PACKAGES_PATH_GL_SCRIPTS}/Tur-AddIp"
			echo "Installing Tur-AddIp, please wait..."
			cd "${PACKAGES_PATH_GL_SCRIPTS}/Tur-AddIp" || exit
			FCT_INSTALL ./*.tcl "${glroot}/sitebot/scripts/"
			FCT_INSTALL ./*.sh "${glroot}/bin/"
			echo "source scripts/tur-addip.tcl" >> "${glroot}/sitebot/eggdrop.conf"
			touch "${glroot}/ftp-data/logs/tur-addip.log"
			FCT_CHMOD 666 "${glroot}/ftp-data/logs/tur-addip.log"
			sed -i "s/changeme/"${GL_Port}"/" "${glroot}/bin/tur-addip.sh"
			sed -i "s/changeme/"${EGGDROP_CONF_ANNOUNCE_CHANNELS_ADMIN}"/" "${glroot}/sitebot/scripts/tur-addip.tcl"
			cd ..
			echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}

## Tur__oneline_stats
GL_SCRIPTS__Tur__Oneline_Stats () {
	if [[ -f "$cache" && "$(grep -c -w GL_SCRIPTS__Tur__Oneline_Stats "$cache")" = 1 ]]; then
		ask="$(grep -w GL_SCRIPTS__Tur__Oneline_Stats "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo
		echo -e "\e[4mDescription for Tur-Oneline_Stats:\e[0m"
		FCT_GIT_GET_DESCRIPTION "${GIT_URL__GL_SCRIPTS__Tur__Oneline_Stats}"
		echo
		echo -n "Install Tur-Oneline_Stats ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case "$ask" in
		[Nn])
			if [ "$(grep -c -w GL_SCRIPTS__Tur__Oneline_Stats= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__Oneline_Stats=\"n\"" >> "$cache"
			fi
		;;
		[Yy]|*)
			if [ "$(grep -c -w GL_SCRIPTS__Tur__Oneline_Stats= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Tur__Oneline_Stats=\"y\"" >> "$cache"
			fi
			FCT_GIT_GET "${GIT_URL__GL_SCRIPTS__Tur__Oneline_Stats}" "${PACKAGES_PATH_GL_SCRIPTS}/Tur-Oneline_Stats"
			echo "Installing Tur-Oneline_Stats, please wait..."
			cd Tur-"${PACKAGES_PATH_GL_SCRIPTS}/Tur-Oneline_Stats" || exit
			FCT_INSTALL ./*.tcl "${glroot}/sitebot/scripts/"
			FCT_INSTALL ./*.sh "${glroot}/bin/"
			echo "source scripts/tur-oneline_stats.tcl" >> "${glroot}/sitebot/eggdrop.conf"
			cd ..
			echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}

## PSXC_IMDB
GL_SCRIPTS__PSXC__IMDB () {
	if [[ -f "$cache" && "$(grep -c -w GL_SCRIPTS__PSXC__IMDB "$cache")" = 1 ]]; then
		ask="$(grep -w GL_SCRIPTS__PSXC__IMDB "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo
		echo -e "\e[4mDescription for PSXC-IMDB:\e[0m"
		FCT_GIT_GET_DESCRIPTION "${GIT_URL__GL_SCRIPTS__PSXC__IMDB}"
		echo
		echo -n "Install PSXC_IMDB ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case "$ask" in
		[Nn])
			if [ "$(grep -c -w GL_SCRIPTS__PSXC__IMDB= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__PSXC__IMDB=\"n\"" >> "$cache"
			fi
		;;
		[Yy]|*)
			if [ "$(grep -c -w GL_SCRIPTS__PSXC__IMDB= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__PSXC__IMDB=\"y\"" >> "$cache"
			fi
			
			
			FCT_GIT_GET "${GIT_URL__GL_SCRIPTS__PSXC__IMDB}" "${PACKAGES_PATH_GL_SCRIPTS}/PSXC-IMDB"
			echo "Installing PSXC_IMDB, please wait..."
			if [[ -f "$cache" && "$(grep -c -w GL_SCRIPTS__PSXC__IMDBchan "$cache")" = 1 ]]; then
				imdbchan="$(grep -w GL_SCRIPTS__PSXC__IMDBchan "$cache" | cut -d "=" -f2 | tr -d "\"")"
			else
				while [[ -z "$imdbchan" ]]; do
					echo -n "IMDB trigger chan for !imdb requests : " ; read -r imdbchan
				done
			fi
			cd PSXC_IMDB || exit
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/PSXC-IMDB/extras/*" "${glroot}/bin/"
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/PSXC-IMDB/addons/*" "${glroot}/bin/"
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/PSXC-IMDB/main/PSXC_IMDB.sh" "${glroot}/bin/"
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/PSXC-IMDB/main/PSXC_IMDB.conf" "${glroot}/etc"
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/PSXC-IMDB/main/PSXC_IMDB.tcl" "${glroot}/sitebot/scripts/pzs-ng/plugins"
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/PSXC-IMDB/main/PSXC_IMDB.zpt" "${glroot}/sitebot/scripts/pzs-ng/plugins"
			"${glroot}/bin/PSXC_IMDB-sanity.sh" >/dev/null 2>&1
			touch "${glroot}/ftp-data/logs/psxc-moviedata.log"
			FCT_CHMOD 666 "${glroot}/ftp-data/logs/psxc-moviedata.log"
			echo "source scripts/pzs-ng/plugins/PSXC_IMDB.tcl" >> "${glroot}/sitebot/eggdrop.conf"
			cat gl >> "${glroot}/etc/glftpd.conf"
			echo -e "[\e[32mDone\e[0m]"
			CHECK="$(grep -w ".imdb" "${glroot}/etc/glftpd.conf")"
			
			if [ "$CHECK" = "" ]; then
				sed -e "s/show_diz .message/show_diz .message .imdb/" "${glroot}/etc/glftpd.conf" > "${glroot}/etc/glftpd.conf"
				touch "${glroot}/ftp-data/logs/psxc-moviedata.log";
				FCT_CHMOD 666 "${glroot}/ftp-data/logs/psxc-moviedata.log";
			fi
			
			sed -i "s/#changethis/"$imdbchan"/" "${glroot}/sitebot/scripts/pzs-ng/plugins/PSXC_IMDB.tcl"
			cd ..
			
			if [ "$(grep -c -w GL_SCRIPTS__PSXC__IMDBchan= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__PSXC__IMDBchan=\"$imdbchan\"" >> "$cache"
			fi
		;;
	esac
}


## eur0-pre-system
GL_SCRIPTS__eur0__pre_system () {
	if [[ -f "$cache" && "$(grep -c -w GL_SCRIPTS__eur0__pre_system "$cache")" = 1 ]]; then
		ask="$(grep -w GL_SCRIPTS__eur0__pre_system "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo
		echo -e "\e[4mDescription for Eur0-pre-system + foo-pre:\e[0m"
		FCT_GIT_GET_DESCRIPTION "${GIT_URL__GL_SCRIPTS__EUR0__PRE_SYSTEM}"
		echo
		echo -n "Install Eur0-pre-system + foo-pre ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case "$ask" in
		[Nn])
			if [ "$(grep -c -w GL_SCRIPTS__eur0__pre_system= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__eur0__pre_system=\"n\"" >> "$cache"
			fi
			;;
			[Yy]|*)
			if [ "$(grep -c -w GL_SCRIPTS__eur0__pre_system= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__eur0__pre_system=\"y\"" >> "$cache"
			fi
			
			FCT_GIT_GET "${GIT_URL__GL_SCRIPTS__EUR0__PRE_SYSTEM}" "${PACKAGES_PATH_GL_SCRIPTS}/eur0-pre-system"
			
			echo "Installing Eur0-pre-system, please wait..."
			cd "${PACKAGES_PATH_GL_SCRIPTS}/eur0-pre-system" || exit
			FCT_EXEC_SHOW_ERROR make;
			FCT_EXEC_SHOW_ERROR make install;
			FCT_EXEC_SHOW_ERROR make clean;
			FCT_INSTALL ./*.sh "${glroot}/bin/"
			FCT_INSTALL ./*.tcl "${glroot}/sitebot/scripts/"
			echo "source scripts/affils.tcl" >> "${glroot}/sitebot/eggdrop.conf"
			bins="bc du expr echo sed touch chmod pwd grep basename date mv bash find sort"
			
			for file in $bins; do
				FCT_INSTALL "$(which "$file")" "${glroot}/bin/"
			done
			
			cat gl >> "${glroot}/etc/glftpd.conf"
		
			if [ -d Foo-Tools ]; then
				rm -rf Foo-Tools >/dev/null 2>&1
			fi
		echo "Installing Foo-Tools, please wait..."
			FCT_GIT_GET "${GIT_URL__FOO_TOOLS}" "${PACKAGES_PATH_DOWNLOADS}/"${GL_SiteName}"/Foo-Tools"
			FCT_INSTALL "${PACKAGES_PATH_DATA}/pre.cfg" "${glroot}/etc"
			cd "${PACKAGES_PATH_DOWNLOADS}/"${GL_SiteName}"/Foo-Tools" || exit
			git checkout cdb77c1 >/dev/null 2>&1
			cd src || exit
			FCT_EXEC_SHOW_ERROR ./configure 
			FCT_EXEC_SHOW_ERROR make build
			FCT_INSTALL pre/foo-pre "${glroot}/bin/"
			FCT_CHMOD u+s "${glroot}/bin/foo-pre"
			FCT_EXEC_SHOW_ERROR make -s distclean
			echo -e "[\e[32mDone\e[0m]"
			cd ../../
			sections="$(sed "s/REQUEST//g" "${rootdir}/.tmp/.validsections" | sed "s/ /|/g" | sed "s/|$//g")"
			cat "${rootdir}/.tmp/footools" >> "${glroot}/etc/pre.cfg"
			rm -f "${rootdir}/.tmp/footools"
			sed -i '/# group.dir/a group.SiteOP.dir=/site/_PRE/SiteOP' "${glroot}/etc/pre.cfg"
			sed -i '/# group.allow/a group.SiteOP.allow='"$sections" "${glroot}/etc/pre.cfg"
			sed -i "s/allow=/allow="$sections"/" "${glroot}/bin/addaffil.sh"
			touch "${glroot}/ftp-data/logs/foo-pre.log"
			mknod "${glroot}/dev/full" c 1 7
			FCT_CHMOD 666 "${glroot}/dev/full"
			mknod "${glroot}/dev/urandom" c 1 9
			FCT_CHMOD 666 "${glroot}/dev/urandom"
			cd ..
		;;
	esac
}

## slv__prebw
GL_SCRIPTS__slv__prebw () {
	if [[ -f "$cache" && "$(grep -c -w GL_SCRIPTS__slv__prebw "$cache")" = 1 ]]; then
		ask="$(grep -w GL_SCRIPTS__slv__prebw "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo
		echo -e "\e[4mDescription for SLV-PreBW.:\e[0m"
		FCT_GIT_GET_DESCRIPTION "${GIT_URL__GL_SCRIPTS__SLV__PreBW}"
		echo
		echo -n "Install SLV-PreBW ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case "$ask" in
		[Nn])
			if [ "$(grep -c -w GL_SCRIPTS__slv__prebw= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__slv__prebw=\"n\"" >> "$cache"
			fi
		;;
		[Yy]|*)
			if [ "$(grep -c -w GL_SCRIPTS__slv__prebw= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__slv__prebw=\"y\"" >> "$cache"
			fi
			FCT_GIT_GET "${GIT_URL__GL_SCRIPTS__SLV__PreBW}" "${PACKAGES_PATH_GL_SCRIPTS}/slv-prebw"
			cd "${PACKAGES_PATH_GL_SCRIPTS}/slv-prebw" || exit 
			echo "Installing SLV-PreBW, please wait..."
			FCT_INSTALL ./*.sh "${glroot}/bin/"
			FCT_INSTALL ./*.tcl "${glroot}/sitebot/scripts/pzs-ng/plugins"
			echo "source scripts/pzs-ng/plugins/PreBW.tcl" >> "${glroot}/sitebot/eggdrop.conf"
			echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}

## ircnick
GL_SCRIPTS__Teqno__IRCNick () {
	if [[ -f "$cache" && "$(grep -c -w GL_SCRIPTS__Teqno__IRCNick "$cache")" = 1 ]]; then
		ask="$(grep -w GL_SCRIPTS__Teqno__IRCNick "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo
		echo -e "\e[4mDescription for Teqno-IRCNick:\e[0m"
		FCT_GIT_GET_DESCRIPTION "${GIT_URL__GL_SCRIPTS__Teqno__IRCNick}"
		echo
		echo -n "Install Teqno-IRCNick ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case "$ask" in
		[Nn])
			if [ "$(grep -c -w GL_SCRIPTS__Teqno__IRCNick= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Teqno__IRCNick=\"n\"" >> "$cache"
			fi
		;;
		[Yy]|*)
			if [ "$(grep -c -w GL_SCRIPTS__Teqno__IRCNick= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Teqno__IRCNick=\"y\"" >> "$cache"
			fi
			FCT_GIT_GET "${GIT_URL__GL_SCRIPTS__Teqno__IRCNick}" "${PACKAGES_PATH_GL_SCRIPTS}/Teqno-IRCNick"
			echo "Installing Teqno-IRCNick, please wait..."
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/ircnick/*.sh" "${glroot}/bin/"
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/ircnick/*.tcl" "${glroot}/sitebot/scripts/"
			sed -i "s/changeme/"${EGGDROP_CONF_ANNOUNCE_CHANNELS_ADMIN}"/" "${glroot}/sitebot/scripts/ircnick.tcl"
			echo "source scripts/ircnick.tcl" >> "${glroot}/sitebot/eggdrop.conf"
			echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}



GL_SCRIPTS__Teqno__Section_Manager () {
	if [[ -f "$cache" && "$(grep -c -w GL_SCRIPTS__Teqno__Section_Manager "$cache")" = 1 ]]; then
		ask="$(grep -w GL_SCRIPTS__Teqno__Section_Manager "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo
		echo -e "\e[4mDescription for Teqno-IRCNick:\e[0m"
		FCT_GIT_GET_DESCRIPTION "${GIT_URL__GL_SCRIPTS__Teqno__Section_Manager}"
		echo
		echo -n "Install Teqno-IRCNick ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case "$ask" in
		[Nn])
			if [ "$(grep -c -w GL_SCRIPTS__Teqno__Section_Manager= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Teqno__Section_Manager=\"n\"" >> "$cache"
			fi
		;;
		[Yy]|*)
			if [ "$(grep -c -w GL_SCRIPTS__Teqno__Section_Manager= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__Teqno__Section_Manager=\"y\"" >> "$cache"
			fi
			FCT_GIT_GET "${GIT_URL__GL_SCRIPTS__Teqno__Section_Manager}" "${PACKAGES_PATH_GL_SCRIPTS}/Teqno-Section_Manager"
			echo "Installing Teqno-Section_Manager, please wait..."
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/Teqno-Section_Manager/section_manager.sh" "${glroot}"
			sed -i "s|changeme|"${GL_Device}"|" "${glroot}/section_manager.sh"
			echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}


GL_SCRIPTS__GL__IMDb_Rating () {

	if [[ -f "$cache" && "$(grep -c -w GL_SCRIPTS__GL__IMDb_Rating "$cache")" = 1 ]]; then
		ask="$(grep -w GL_SCRIPTS__GL__IMDb_Rating "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo
		echo -e "\e[4mDescription for GL-IMDb-Rating:\e[0m"
		FCT_GIT_GET_DESCRIPTION "${GIT_URL__GL_SCRIPTS__GL__IMDb_Rating}"
		echo
		echo -n "Install Teqno-IRCNick ? [Y]es [N]o, default Y : " ; read -r ask
	fi
	
	case "$ask" in
		[Nn])
			if [ "$(grep -c -w GL_SCRIPTS__GL__IMDb_Rating= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__GL__IMDb_Rating=\"n\"" >> "$cache"
			fi
		;;
		[Yy]|*)
			if [ "$(grep -c -w GL_SCRIPTS__GL__IMDb_Rating= "$cache")" = 0 ]; then
				echo "GL_SCRIPTS__GL__IMDb_Rating=\"y\"" >> "$cache"
			fi
			FCT_GIT_GET "${GIT_URL__GL_SCRIPTS__GL__IMDb_Rating}" "${PACKAGES_PATH_GL_SCRIPTS}/Teqno-Section_Manager"
			echo "Installing GL-IMDb-Rating, please wait..."
			FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/imdbrating/imdbrating.sh" "${glroot}"
			echo -e "[\e[32mDone\e[0m]"
		;;
	esac
}


GLFTPD_INSTALLER_DISCLAIMER () {
	Banner_Show "Welcome to the glFTPD installer v"$VER"" silent
	echo
	echo "Disclaimer:" 
	echo "This software is used at your own risk!"
	echo "The author of this installer takes no responsibility for any damage done to your system."
	echo
	echo -n "Have you read and installed the Requirements in README.MD ? [Y]es [N]o, default N : " ; read -r requirement
	echo
	case "$requirement" in
		[Yy]) ;;
		[Nn])
			rm -r .tmp;
			exit 1
		;;
		*)
			rm -r .tmp;
			exit 1
		;;
	esac
}
## GLFTPD_FTP_CREATATION_USER
GLFTPD_FTP_CREATATION_USER () {
	if [[ -f "$cache" && "$(grep -c -w username "$cache")" = 1 ]]; then
		username="$(grep -w username "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo
		echo -n "Please enter the username of admin, default admin : " ; read -r username
	fi
	
	if [ "$username" = "" ]; then
		username="admin"
	fi

	if [[ -f "$cache" && "$(grep -c -w password "$cache")" = 1 ]]; then
		password="$(grep -w password "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo -n "Please enter the password ["$username"], default password : " ; read -r password
	fi
	
	if [ "$password" = "" ]; then
		password="password"
	fi

	localip="$("${BINARY_IP}" addr show | awk '$1 == "inet" && $3 == "brd" { sub (/\/.*/,""); print "$2" }' | head | awk -F "." '{print $1"."$2"."$3.".*"}')"
	
	if [[ -f "$cache" && "$(grep -c -w ip "$cache")" = 1 ]]; then
		ip="$(grep -w ip "$cache" | cut -d "=" -f2 | tr -d "\"")"
	else
		echo -n "IP for ["$username"] ? Minimum *@xxx.xxx.* default *@${localip} : " ; read -r ip
	fi
	
	if [ "$ip" = "" ]; then
		ip="*@"$localip""
	fi

	if [ "$router" = "y" ]; then
		connection="-E ftp://localhost"
	else
		connection="ftp://localhost"
	fi
	${BINARY_NCFTPLS} -u glftpd -p glftpd -P ${GL_Port} -Y "site change glftpd flags +347ABCDEFGH" "$connection" > /dev/null
	${BINARY_NCFTPLS} -u glftpd -p glftpd -P ${GL_Port} -Y "site grpadd SiteOP SiteOP" "$connection" > /dev/null
	${BINARY_NCFTPLS} -u glftpd -p glftpd -P ${GL_Port} -Y "site grpadd Admin Administrators/SYSOP" "$connection" > /dev/null
	${BINARY_NCFTPLS} -u glftpd -p glftpd -P ${GL_Port} -Y "site grpadd Friends Friends" "$connection" > /dev/null
	${BINARY_NCFTPLS} -u glftpd -p glftpd -P ${GL_Port} -Y "site grpadd NUKERS NUKERS" "$connection" > /dev/null
	${BINARY_NCFTPLS} -u glftpd -p glftpd -P ${GL_Port} -Y "site grpadd VACATION VACATION" "$connection" > /dev/null
	${BINARY_NCFTPLS} -u glftpd -p glftpd -P ${GL_Port} -Y "site grpadd iND Independent Racers" "$connection" > /dev/null
	${BINARY_NCFTPLS} -u glftpd -p glftpd -P ${GL_Port} -Y "site gadduser Admin "$username" "$password" "$ip"" "$connection" > /dev/null
	${BINARY_NCFTPLS} -u glftpd -p glftpd -P ${GL_Port} -Y "site chgrp "$username" SiteOP" "$connection" > /dev/null
	${BINARY_NCFTPLS} -u glftpd -p glftpd -P ${GL_Port} -Y "site change "$username" flags +1347ABCDEFGH" "$connection" > /dev/null
	${BINARY_NCFTPLS} -u glftpd -p glftpd -P ${GL_Port} -Y "site change "$username" ratio 0" "$connection" > /dev/null
	${BINARY_NCFTPLS} -u glftpd -p glftpd -P ${GL_Port} -Y "site chgrp glftpd Admin" "$connection" > /dev/null
	${BINARY_NCFTPLS} -u glftpd -p glftpd -P ${GL_Port} -Y "site chgrp glftpd SiteOP" "$connection" > /dev/null
	echo
	echo "["$username"] created successfully and added to the groups Admin and SiteOP"
	echo "These groups were also created: NUKERS, iND, VACATION & Friends"
	sed -i "s/\"changeme\"/\"$username\"/" "${glroot}/sitebot/eggdrop.conf"
	sed -i "s/\"sname\"/\"${GL_SiteName}\"/" "${glroot}/sitebot/scripts/pzs-ng/ngBot.conf"
	sed -i "s/\"ochan\"/\"${EGGDROP_CONF_ANNOUNCE_CHANNELS_ADMIN}\"/" "${glroot}/sitebot/scripts/pzs-ng/ngBot.conf"
	sed -i "s/\"channame\"/\"${EGGDROP_CONF_ANNOUNCE_CHANNELS}\"/" "${glroot}/sitebot/scripts/pzs-ng/ngBot.conf"
	
	if [ "$(grep -c -w username= "$cache")" = 0 ]; then
		printf '%s\n' \
				"username=\"$username\""        \
				"password=\"$password\""        \
				"ip=\"$ip\""                    \
		>> "$cache"

	fi
}

## GL_UNINSTALL / Config
GL_UNINSTALL () {

	FCT_INSTALL "${PACKAGES_PATH_DATA}/uninstall.sh" ""${rootdir}"/uninstall-"${GL_SiteName}".sh"
	printf '%s\n' \
				"#!/bin/bash" \
				"rm -rf "${glroot}"" \
				"rm -rf "${PACKAGES_PATH_DOWNLOADS}/${GL_SiteName}"" \
				"rm -rf /etc/glftpd-"${GL_SiteName}".conf" \
				"sed -i @"${glservicename}"@d /etc/services" \
				"if [ -f \"/etc/inetd.conf\" ]; then" \
				"	sed -i @"${glservicename}"@d /etc/inetd.conf" \
				"	killall -HUP inetd" \
				"fi" \
				"sed -i @"${glroot}"@Id /var/spool/cron/crontabs/root" \
				"if [ -f \"/bin/systemctl\" ];then" \
				"	systemctl stop "${GL_SiteName}".socket" \
				"	systemctl disable "${GL_SiteName}".socket >/dev/null 2>&1" \
				"	rm -f /etc/systemd/system/"${GL_SiteName}"*" \
				"	systemctl daemon-reload" \
				"	systemctl reset-failed" \
				"fi" \
	>> ""${rootdir}"/uninstall-"${GL_SiteName}".sh"
	
	PACKAGES_PATH_DOWNLOADS
	
	#cd ../../
	# FCT_CreateDir "${glroot}/backup"
	mkdir -p "${glroot}/backup"
	FCT_INSTALL "${PACKAGES_PATH}/"${GL_ARCHIVE_FILE}"DIR" "${PACKAGES_PATH}/source/"
	FCT_INSTALL "${PACKAGES_PATH}/pzs-ng" "${PACKAGES_PATH}/source/"
	FCT_INSTALL "${PACKAGES_PATH}/eggdrop" "${PACKAGES_PATH}/source/"
	FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/eur0-pre-system/Foo-Tools" "${PACKAGES_PATH}/source/"
	FCT_INSTALL "${rootdir}/.tmp/site/*" "${glroot}/site/"
	FCT_INSTALL "${PACKAGES_PATH}/source/pzs-ng" "${glroot}/backup"
	FCT_INSTALL "${PACKAGES_PATH_DATA}/pzs-ng-update.sh" "${glroot}/backup"
	FCT_INSTALL "${glroot}/backup/pzs-ng/sitebot/extra/invite.sh" "${glroot}/bin/"
	FCT_INSTALL "${PACKAGES_PATH_DATA}/syscheck.sh" "${glroot}/bin/"
	FCT_INSTALL "${rootdir}/.tmp/dated.sh" "${glroot}/bin/"
	local DIRDATED=0
	[ -d "${glroot}/site/0DAY" ] && sed -i '/^sections/a '"0DAY" "${glroot}/bin/dated.sh" && DIRDATED=1
	[ -d "${glroot}/site/FLAC" ] && sed -i '/^sections/a '"FLAC" "${glroot}/bin/dated.sh" && DIRDATED=1
	[ -d "${glroot}/site/MP3" ] && sed -i '/^sections/a '"MP3" "${glroot}/bin/dated.sh" && DIRDATED=1
	[ -d "${glroot}/site/EBOOKS" ] && sed -i '/^sections/a '"EBOOKS" "${glroot}/bin/dated.sh" && DIRDATED=1

	if [[ "$DIRDATED" == 1 ]]; then
		echo "0 0 * * *         	${glroot}/bin/dated.sh >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
		echo "0 1 * * *         	${glroot}/bin/dated.sh close >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
		"${glroot}/bin/dated.sh" >/dev/null 2>&1
	fi
		local DIRTV=0
		[ -d "${glroot}/site/TV-HD" ] && sed -i '/^sections/a '"0DAY" "${glroot}/bin/dated.sh" && DIRTV=1
	[ -d "${glroot}/site/TV-NL" ] && sed -i '/^sections/a '"FLAC" "${glroot}/bin/dated.sh" && DIRTV=1
	[ -d "${glroot}/site/TV-SD" ] && sed -i '/^sections/a '"MP3" "${glroot}/bin/dated.sh" && DIRTV=1
	[ -d "${glroot}/site/EBOOKS" ] && sed -i '/^sections/a '"EBOOKS" "${glroot}/bin/dated.sh" && DIRTV=1
	if [[ "$DIRTV" == 1 ]]; then
		FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/extra/TVMaze.tcl" "${glroot}/sitebot/scripts/pzs-ng/plugins"
		FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/extra/TVMaze.zpt" "${glroot}/sitebot/scripts/pzs-ng/plugins"
		FCT_INSTALL "${PACKAGES_PATH_GL_SCRIPTS}/extra/TVMaze_nuke.sh" "${glroot}/bin/"
		echo "source scripts/pzs-ng/plugins/TVMaze.tcl" >> "${glroot}/sitebot/eggdrop.conf"
		touch "${glroot}/ftp-data/logs/tvmaze_nuke.log"
	fi


	# FCT_CreateDir "${glroot}/tmp"
	mkdir -p "${glroot}/tmp"
	FCT_CHMOD 777 "${glroot}/tmp"
	chown -R "${UNIX_USER_EGGDROP}:glftpd" "${glroot}/sitebot"
	FCT_CHMOD 755 "${glroot}/bin/*.sh"
	FCT_CHMOD 777 "${glroot}/ftp-data/logs"
	FCT_CHMOD 666 "${glroot}/ftp-data/logs/*"
	rm -rf .tmp >/dev/null 2>&1
	
}
Banner_Show () {
	if test -z "$2" || "$DEBUGINSTALL" = true; then
		read -r -t 5 -p "[*] I am going to wait for 5 seconds or Press any key to continue . . ."
	fi
	#clear
	echo -e "\e[32m+--------------------------------------------------------------+"
	echo -e "\e[32m|\e[94m GLFTPD INSTALLER V"$VER" By "$AUTHOR"            \e[32m|"
	echo -e "\e[32m+--------------------------------------------------------------+"
	printf "\e[32m|\e[96m"$(tput bold)" %-60s "$(tput sgr0)"\e[32m|\n" "$1"
	echo -e "\e[32m+--------------------------------------------------------------+\e[0m"
	
}

# download or update local git repo
FCT_CHMOD () {
	if [ "$DEBUGINSTALL" = true ] ; then echo "chmod '$*' ($(pwd))"; fi
	chmod "$@"
}
FCT_GIT_GET () {
	TMP_DIR="$(pwd)"
	REPOSRC="$1"
	LOCALREPO="$2"
	LOCALREPO_VC_DIR="$LOCALREPO/.git"

	if [ ! -d "$LOCALREPO_VC_DIR" ]; then
		git clone "$REPOSRC" "$LOCALREPO"
	else
		cd "$LOCALREPO" || exit
		git pull "$REPOSRC"
	fi
	cd "$TMP_DIR" || exit
}

FCT_GIT_GET_DESCRIPTION () {
	GIT_DESCRIPTION="${1/github.com/raw.githubusercontent.com}/master/description"
	echo "$("${BINARY_WGET}" "$GIT_DESCRIPTION" -q -O -)"
}
FCT_CreateDir () {
	if [ -d "$1" ]; then
		if [ "$DEBUGINSTALL" = true ] ; then echo "remove directory '$1' executed in '$(pwd)'"; fi
		rm -rf "$1"
	fi
	if [ "$DEBUGINSTALL" = true ] ; then echo "Create directory '$1' executed in '$(pwd)'"; fi
	mkdir -p "$1"
	
}

FCT_INSTALL () {
	install -v "$@"
}
FCT_EXEC_SHOW_ERROR () {
	"$@" >/dev/null || ("$@" && exit 1);
}
BASH_END () {
	echo "####### Here END glFTPD scripts of "${GL_SiteName}" #######" >> /var/spool/cron/crontabs/root
	echo 
	if [ -f "${glroot}/bin/tur-trial3.sh" ]; then
			echo "You have chosen to install Tur__Trial3, please run "${glroot}/bin/setupsql.sh""
			echo
	fi
	echo "If you are planning to uninstall glFTPD, then run uninstall-"${GL_SiteName}".sh"
	echo
	echo "To get the bot running you HAVE to do this ONCE to create the initial userfile"
	echo "su - sitebot -c \"${glroot}/sitebot/sitebot -m\""
	echo
	echo "If you want automatic uninstall of site then please review the settings in "${glroot}/bin/tur-space.conf" and enable the line in crontab"
	echo 
	echo "All good to go and I recommend people to check the different settings for the different scripts including glFTPD itself."
	echo
	echo "Enjoy!"
	echo 
	echo "Installer script created by Teqno" 
}
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN BASH_CHECK_ROOT' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
BASH_CHECK_ROOT
#if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GLFTPD_INSTALLER_DISCLAIMER' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
#GLFTPD_INSTALLER_DISCLAIMER
#if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN BASH_CHECK_IF_DEBIAN_INSTALL_DEPENDANCIES' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
#BASH_CHECK_IF_DEBIAN_INSTALL_DEPENDANCIES
#if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN BASH_CHECK_IF_BINARY_EXISTS' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
#BASH_CHECK_IF_BINARY_EXISTS
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN BASH_INIT' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
BASH_INIT
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GLFTPD_CONF_INIT' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GLFTPD_CONF_INIT
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GLFTPD_CONF_PORT' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GLFTPD_CONF_PORT
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GLFTPD_CONF_VERSION' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GLFTPD_CONF_VERSION
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GLFTPD_CONF_DEVICE' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GLFTPD_CONF_DEVICE
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GLFTPD_DOWNLOAD' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GLFTPD_DOWNLOAD
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GLFTPD_INSTALL' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GLFTPD_INSTALL
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN UNIX_CREATE_USER_AND_GROUP' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
UNIX_CREATE_USER_AND_GROUP
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN PZSNG_DOWNLOAD' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
PZSNG_DOWNLOAD
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN EGGDROP_DOWNLOAD' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
EGGDROP_DOWNLOAD
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN EGGDROP_CONF_CHANNELS_ADD' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
EGGDROP_CONF_CHANNELS_ADD
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN EGGDROP_CONF_ANNOUNCE_CHANNELS' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
EGGDROP_CONF_ANNOUNCE_CHANNELS
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN EGGDROP_CONF_ANNOUNCE_CHANNELS_ADMIN' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
EGGDROP_CONF_ANNOUNCE_CHANNELS_ADMIN
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN EGG__YOUR_IRC_NICKNAME' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
EGG__YOUR_IRC_NICKNAME
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GL_SCRIPTS__Tur__Rules' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GL_SCRIPTS__Tur__Rules
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GL_SCRIPTS__Tur__Space' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GL_SCRIPTS__Tur__Space
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GL_SCRIPTS__Tur__AutoNuke' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GL_SCRIPTS__Tur__AutoNuke
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GLFTPD_CONF_SECTIONS_NAME' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GLFTPD_CONF_SECTIONS_NAME
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN EGG_INSTALL' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
EGG_INSTALL
#if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN eggdrop' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
#eggdrop
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN EGG_CONFIG_IRC' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
EGG_CONFIG_IRC
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN PZS_PATCH_CONFIG_FILE' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
PZS_PATCH_CONFIG_FILE
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN PZS_CONFIG_CHANNELS' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
PZS_CONFIG_CHANNELS
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN PZS_INSTALL' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
PZS_INSTALL
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GL_SCRIPTS__eur0__pre_system' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GL_SCRIPTS__eur0__pre_system
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GL_SCRIPTS__GL__IMDb_Rating' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GL_SCRIPTS__GL__IMDb_Rating
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GL_SCRIPTS__slv__prebw' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GL_SCRIPTS__slv__prebw
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GL_SCRIPTS__Tur__IdleBotKick' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GL_SCRIPTS__Tur__IdleBotKick
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GL_SCRIPTS__Tur__IrcAdmin' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GL_SCRIPTS__Tur__IrcAdmin
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GL_SCRIPTS__Tur__FTPWho' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GL_SCRIPTS__Tur__FTPWho
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GL_SCRIPTS__Tur__Request' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GL_SCRIPTS__Tur__Request
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GL_SCRIPTS__Tur__Trial' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GL_SCRIPTS__Tur__Trial
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GL_SCRIPTS__Tur__Vacation' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GL_SCRIPTS__Tur__Vacation
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GL_SCRIPTS__Tur__WhereAmi' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GL_SCRIPTS__Tur__WhereAmi
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GL_SCRIPTS__Tur__Undupe' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GL_SCRIPTS__Tur__Undupe
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GL_SCRIPTS__Tur__PreCheck' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GL_SCRIPTS__Tur__PreCheck
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GL_SCRIPTS__Tur__PreDirCheck' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GL_SCRIPTS__Tur__PreDirCheck
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GL_SCRIPTS__Tur__PreDirCheck_Manager' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GL_SCRIPTS__Tur__PreDirCheck_Manager
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GL_SCRIPTS__PSXC__IMDB' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GL_SCRIPTS__PSXC__IMDB
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GL_SCRIPTS__Tur__AddIp' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GL_SCRIPTS__Tur__AddIp
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GL_SCRIPTS__Tur__Oneline_Stats' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GL_SCRIPTS__Tur__Oneline_Stats
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GL_SCRIPTS__Teqno__IRCNick' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GL_SCRIPTS__Teqno__IRCNick
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GL_SCRIPTS__Teqno__Section_Manager' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GL_SCRIPTS__Teqno__Section_Manager
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GL_SCRIPTS__Tur__Tuls' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GL_SCRIPTS__Tur__Tuls
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GLFTPD_FTP_CREATATION_USER' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GLFTPD_FTP_CREATATION_USER
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN GL_UNINSTALL' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
GL_UNINSTALL
if [ "$DEBUGINSTALL" = true ] ; then echo 'RUN BASH_END' && read -p "[${glroot}] [$(pwd)] Press Enter to continue..."; fi
BASH_END

exit 0


