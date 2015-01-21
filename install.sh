#!/bin/bash

# Install the Minecraft server supervision scripts to the
# requested location, and set up reasonable defaults

# The lazy can just run out of the "files" directory. Symlink "server.jar" to
# the actual Minecraft server jar (or copy it in), cd files, ./run

# defaults
force=0;   # check for errors
quiet=0;   # display warnings
verbose=0; # supress excessive verbiage

help() {
   # this format loosely based upon GNU coreutils 8.23 --help format

   cat <<EOF
Usage: $(basename "$0") [OPTION]... [-d|--directory] DIRECTORY
Installs the Minecraft server supervision files to DIRECTORY

Mandatory arguments to long options are mandatory for short options too.

  -d, --directory=DIR  Installation directory
  -f, --force          Overrides sanity checks
  -h, --help           This help
  -i, --interactive    Uses question/answer to install
  -I, --ip=IP          Binds Minecraft server to IP
  -j, --jar=SERVER     Uses SERVER as server.jar
  -J, --java=JVM       Use JVM
  -m, --motd=MOTD      Assigns MOTD to motd
  -P, --png=IMAGE      Symlinks IMAGE to server-icon.png
  -p, --port=PORT      Binds Minecraft server to PORT
  -q, --quiet          Supresses warnings
  -r, --RAM=SIZE       Allocats SIZE to server at start
  -u, --user=ACCOUNT   Changes to ACCOUNT prior to installing / starting
  -w, --world=WORLD    Assigns WORLD to level-name
  -v, --verbose        Increases verbosity
  --eula=yes           Accept the EULA
                         https://account.mojang.com/documents/minecraft_eula
EOF
}

error() {
   if [[ $1 ]]; then
      printf 'E: %s\n' "$*"
   fi
   exit 1
}

if [ -z "$1" ]; then
   help
   error
fi

# looks like passing "option=" will pass validation, but likely
# cause problems later. Caveat emptor.
while [[ "$1" == -* ]]; do
   case "$1" in

      -h|--help) help; exit 0 ;;
      -f|--force) force=1; shift; ;;
      -i|--interactive) interactive=1; shift ;;
      -q|--quiet) verbose=0; quiet=1; shift ;;
      -v|--verbose) verbose=1; quiet=0; shift ;;

      -d|--directory)
         if [[ -z $2 ]]; then help; error "$1 requires an directory (eg: /opt/minecraft)"; fi
         target=$2; shift 2 ;;
      --directory=*) target=${1#*=}; shift ;;

      -I|--ip)
         if [[ -z $2 ]]; then help; error "$1 requires an address (eg: 0.0.0.0)"; fi
         ip=$2; shift 2 ;;
      --ip=*) ip=${1#*=}; shift ;;

      -j|--jar)
         if [[ -z $2 ]]; then help; error "$1 requires a path to Minecraft server (eg: /opt/minecraft_server.1.8.1.jar)"; fi
         jar=$2; shift 2 ;;
      --jar=*) jar=${1#*=}; shift ;;

      -J|--java)
         if [[ -z $2 ]]; then help; error "$1 requires a path to java (eg: /usr/bin/java)"; fi
         java=$2; shift 2 ;;
      --java=*) java=${1#*=}; shift ;;

      -m|--motd)
         if [[ -z $2 ]]; then help; error "$1 requires an argument (eg: \"A Minecraft Server\")"; fi
         motd=$2; shift 2 ;;
      --motd=*) motd=${1#*=}; shift ;;

      -P|--png)
         if [[ -z $2 ]]; then help; error "$1 requires an argument (eg: server-icon.png)"; fi
         png=$2; shift 2 ;;
      --png=*) png=${1#*=}; shift ;;

      -p|--port)
         if [[ -z $2 ]]; then help; error "$1 requires a port (eg: 25565)"; fi
         port=$2; shift 2 ;;
      --port=*) port=${1#*=}; shift ;;

      -r|--ram)
         if [[ -z $2 ]]; then help; error "$1 requires a size (eg: 1024M)"; fi
         ram=$2; shift 2 ;;
      --ram=*) ram=${1#*=}; shift ;;

      -u|--user)
         if [[ -z $2 ]]; then help; error "$1 requires an account (eg: minecraft)"; fi
         user=$2; shift 2 ;;
      --user=*) user=${1#*=}; shift ;;

      -w|--world)
         if [[ -z $2 ]]; then help; error "$1 requires an argument (eg: world)"; fi
         world=$2; shift 2 ;;
      --world=*) world=${1#*=}; shift ;;

      --) shift; break ;;
      *) help; error "${1%%=*}: unrecognized option" ;;
   esac
done

# if --directory wasn't used above, we need to have it passed separately
if [[ -z $target ]]; then
   target="$1"
   shift
fi

# do we have any options left?
if [[ $# -gt 0 ]]; then
   help
   error
fi

verify_target() {
   if [[ -e "$1" ]]; then
      if [[ -d "$1" ]]; then
         error "Installing to an existing Minecraft server isn't supported ... yet!"
      else
         error "$1: file exists, and isn't a directory"
      fi
   fi
}

verify_ip() {
   [[ $1 ]] || return 0; # blank is okay!

   # At least make sure it has three dots
   local valid=0
   case $1 in
      .*) ;; # begins with a dot? nope!
      *.) ;; # ends with a dot? nope!
      *..* ) ;; # two dots in a row? nope!
      *.*.*.*.*) ;; # dotted quint?! nope! (also catches dotted hexes, and beyond)
      *' '*) ;; # spaces? nope!
      *.*.*.*) valid=1 ;; # Close enough to a valid IP address, I guess
      *) ;; # Not enough dots? nope!
   esac
   if [[ $valid -eq 0 ]]; then
      error "$1: Not even close to a valid IP address"
   fi
   # Could still be invalid, but at least it has three dots.
}

verify_jar() {
   [[ $1 ]] || return 0; # blank is okay!

   # should probably ensure it has a *.jar suffix
   if [[ ! -f $1 ]]; then
      error "$1: no such Minecraft server jar"
   fi

   local valid=0
   case $1 in
      *.jar) valid=1 ;;
   esac
   if [[ $valid -eq 0 ]]; then
      error "$1: Doesn't look like a jar file to me."
   fi
}

verify_jvm() {
   [[ $1 ]] || return 0; # blank is okay!

   # Exists, and is executable.
   # Could verify the -version information

   [[ -e $1 ]] || error "$1: No such file."
   [[ -x $1 ]] || error "$1: Not an executable"
}

verify_motd() {
   :
}

verify_png() {
   :
}

verify_port() {
   :
}

verify_ram() {
   :
}

verify_user() {
   :
}

verify_world() {
   :
}

verify_target "$target"
verify_ip "$ip"
verify_jar "$jar"
verify_jvm "$java"
verify_motd "$motd"
verify_png "$png"
verify_port "$port"
verify_ram "$ram"
verify_user "$user"
verify_world "$word"

set_ip() {
   # is $1 a valid IP? Do we care?
   printf 'server-ip=%s\n' $1
}

set_motd() {
   # MOTD can only be 59 characters. Warn?
   printf 'motd=%s\n' "$1"
}

set_port() {
   # is $1 a valid port? Do we care? Do we care if it's <1024?
   printf 'server-port=%s\n' $1
}

set_world() {
   # If the target dir already exists, we could check that this is a valid path.
   printf 'level-name=%s\n' "$1"
}

set_port $port
set_ip $ip
set_world "$world"
set_motd "$motd"

set_user() {
   if [[ "$1" ]]; then
      sed -e "/setuidgid/s/minecraft/$1/" files/run
   fi
}

set_user $user

set_java() {

   if [[ $1 ]] && [[ ! -x $1 ]]; then
      error "$1: no such file"
   fi

   cat<<EOF
${1:+$1}
Path to desired JVM
EOF
}

set_java "$java"


set_jar() {

   if [[ $1 ]] && [[ ! -e $1 ]]; then
      error "$1: no such file"
   fi

   cat<<EOF
${1:+$1}
Path to desired Minecraft server jar
EOF
}

set_jar "$jar"
