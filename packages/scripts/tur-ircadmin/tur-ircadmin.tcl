##############################################################################
# Tur-IrcAdmin.tcl 1.2 by ARTISPRETIS (artispretis@gmail.com)                #
#                                                                            #
#  [ CHANGELOG ]                                                             #
# ADD: TCL NAME SPACE :    Avoid conflicts with other scripts                #
# ADD: TCL UNLOAD     :    totally unloaded the script at each rehash        #
# ADD: MSG ERROR      :    return access denied if user not allow            #
# MOD: binary         :    binary is now configurable in the global          #
# MOD: channel_list   :    Allows multiple channels work                     #
# improvement         :    Compare nick and channel                          #
# ......                                                                     #
##############################################################################
# Tur-IrcAdmin.tcl 1.1 by Turranius                                          #
# Change binds below to whatever you want the trigger the script with.       #
# pub is for public chan command & msg is for private msg.                   #
#                                                                            #
# If tur-ircadmin.sh is not located in /glftpd/bin/, then change the path    #
# in all 'set binary' below.                                                 #
#                                                                            #
# Change mainchania below to your irc channel. Users must be in that chan or #
# they will be ignored. No capital letters in mainchan.                      #
#                                                                            #
# If using a /msg to the bot, the user must be in the mainchan.              #
#                                                                            #
# The o in the binds means that only ops can run it. By ops, I mean users    #
# added to THIS bot with +o in the mainchan. Just being a @ dosnt help.      #
# You can use any flag you want, just make sure the user is added in the bot #
# with that flag, in the #mainchan.                                          #
##############################################################################

namespace eval ::Tur::IrcAdmin {
    # Configuration
    variable channel_list   "changeme"
    variable binary         {/glftpd/bin/tur-ircadmin.sh}
    # Configuration END

    bind pub o !site ::Tur::IrcAdmin::pub
    bind msg o !site ::Tur::IrcAdmin::msg
    bind evnt - prerehash ::Tur::IrcAdmin::unload
}
 ###############################################################################
# Désallocation des ressources : le script se décharge totalement avant chaque
# rehash ou à chaque relecture au moyen de la commande "source" ou autre.
 ###############################################################################
proc ::Tur::IrcAdmin::unload {args} {
	putlog "Désallocation des ressources de ::Tur::IrcAdmin..."
	# Suppression des binds.
	foreach binding [lsearch -inline -all -regexp [binds *[set ns [::tcl::string::range [namespace current] 2 end]]*] " \{?(::)?$ns"] {
		unbind [lindex $binding 0] [lindex $binding 1] [lindex $binding 2] [lindex $binding 4]
	}
	# On décharge le catalogue de messages.
	namespace delete ::Tur::IrcAdmin
}

##############################################################################
## Public chan.
proc ::Tur::IrcAdmin::pub { nick output binary chan text } {
	if { [lsearch -nocase ${::Tur::IrcAdmin::channel_list} $chan] != "-1" } {
		foreach line [split [exec ${::Tur::IrcAdmin::binary} $nick $text] "\n"] {
			putnow "PRIVMSG $chan :$line"
		}
		putnow "PRIVMSG $chan :Done."
	} else {
		putnow "PRIVMSG $chan :Access denied"
	}
}

## /msg to bot.
proc ::Tur::IrcAdmin::msg { nick host hand text } {
	
	set UserChanList    "";
	foreach ChanList ${::Tur::IrcAdmin::channel_list} {
		set UserChanList	[lsort -unique [list {*}$UserChanList {*}[chanlist $ChanList ]]]
	};
	if { [lsearch $UserChanList $nick] != "-1"} {
		foreach line [split [exec ${::Tur::IrcAdmin::binary} $nick $text] "\n"] {
			putnow "PRIVMSG $nick :$line"
		}
		putnow "PRIVMSG $nick :Done."
	} else {
		putnow "PRIVMSG $nick :Access denied"
	}
}

putlog "Tur-IrcAdmin.tcl 1.2 by artispretis loaded"
