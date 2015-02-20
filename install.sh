#!/bin/bash

# Install the Minecraft server supervision scripts to the
# requested location, and set up reasonable defaults

# The lazy can just run out of the "files" directory. Symlink "server.jar" to
# the actual Minecraft server jar (or copy it in), cd files, ./run

# defaults
force=0;   # check for errors
quiet=0;   # display warnings
verbose=0; # supress excessive verbiage

# globals
eula_file='eula.txt';           # Minecraft's EULA acceptance
env_dir='ENV';                  # daemontools' environment directory
icon_file='server-icon.png';    # Minecraft's server icon (64x64 PNG)
properties='server.properties'; # Minecraft's defaults
source_dir="$(dirname "$0")";   # Where the wild files are

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
  -J, --jvm=JAVA       Use JAVA as the JVM
  -m, --motd=MOTD      Assigns MOTD to motd
  -o, --options=OPTS   Additional java options
  -P, --png=IMAGE      Symlinks IMAGE to server-icon.png
  -p, --port=PORT      Binds Minecraft server to PORT
  -q, --quiet          Supresses warnings
  -r, --RAM=SIZE       Allocates SIZE to server at start
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

warn() {
   if [[ $1 ]]; then
      printf 'W: %s\n' "$*"
   fi
}

if [ -z "$1" ]; then
   help
   error
fi

## "Definers"

# looks like passing "--option=" will pass validation, but likely
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

      --eula)
         if [[ -z $2 ]]; then help; error "$1 must be accepted"; fi
         eula=$2; shift 2 ;;
      --eula=*)
         eula=${1#*=}; shift ;;

      -I|--ip)
         if [[ -z $2 ]]; then help; error "$1 requires an address (eg: 0.0.0.0)"; fi
         ip=$2; shift 2 ;;
      --ip=*) ip=${1#*=}; shift ;;

      -j|--jar)
         if [[ -z $2 ]]; then help; error "$1 requires a path to Minecraft server (eg: /opt/minecraft_server.1.8.1.jar)"; fi
         jar=$2; shift 2 ;;
      --jar=*) jar=${1#*=}; shift ;;

      -J|--jvm|--java)
         if [[ -z $2 ]]; then help; error "$1 requires a path to java (eg: /usr/bin/java)"; fi
         jvm=$2; shift 2 ;;
      --jvm=*|--java=*) jvm=${1#*=}; shift ;;

      -m|--motd)
         if [[ -z $2 ]]; then help; error "$1 requires an argument (eg: \"A Minecraft Server\")"; fi
         motd=$2; shift 2 ;;
      --motd=*) motd=${1#*=}; shift ;;

      -o|--options)
         if [[ -z $2 ]]; then help; error "$1 requires an argument (eg: \"-Xincgc\")"; fi
         jvm_options=$2; shift 2 ;;
      --options=*) jvm_options=${1#*=}; shift ;;

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

# TODO? Combine like options, so its verifier is followed
# immediately by its setter
# eg verify_target() {...}; set_target() {...};

# TODO? Call verifier immediately after it's defined
# eg verify_foo() {...; }; verify_foo;

## Verifiers

verify_target() {
   [[ $1 ]] || { help; error; }; # blank is a problem!

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

verify_jvm_options() {
   [[ $1 ]] || return 0; # blank is okay!
}

verify_jvm() {
   [[ $1 ]] || return 0; # blank is okay!

   # Exists, and is executable.
   # Could verify the -version information

   [[ -e $1 ]] || error "$1: No such file."
   [[ -x $1 ]] || error "$1: Not an executable"
}

verify_motd() {
   [[ $1 ]] || return 0; # blank is okay!

   local max=59
   [[ ${#1} -gt $max ]] && error "MOTD too long. Max=$max; supplied=${#1}"
}

verify_png() {
   [[ $1 ]] || return 0; # blank is okay!

   case $1 in
      http://*)  ;; # URIs are okay
      https://*) ;;
      *.png)     [[ -f $1 ]] || error "$1: No such file" ;;
      *)         error "$1: Doesn't look like a PNG to me." ;;
   esac
}

verify_port() {
   [[ $1 ]] || return 0; # blank is okay!

   # a non-number will parse as zero
   local privileged=1023
   local maxport=65535
   [[ $1 -le $privileged ]] && error "$1: port must be greater than $privileged"
   [[ $1 -gt $maxport ]] && error "$1: port must be less than $maxport"
}

verify_ram() {
   [[ $1 ]] || return 0; # blank is okay!

   # uhm...
}

verify_user() {
   [[ $1 ]] || return 0; #blank is okay!

   id "$1" &> /dev/null || error "$1: no such user"
}

verify_world() {
   [[ $1 ]] || return 0; # blank is okay!

   if [[ -d  "$target" ]]; then
      # if installing into current server, make sure the world exists
      [[ ! -d "$1" ]] || error "$1: no such world"
   fi
}

verify_eula() {
   [[ $1 ]] || return 0; # blank is okay!

   if [[ $1 != 'yes' ]]; then
      error "EULA must be accepted";
   fi
}

## Setters

set_target() {
   local target="$1"
   mkdir "$target" || error "Could not make $target"
   #mkdir "$target/$env_dir" || error "Could not make $target"
   cp -a "$source_dir/files/." "$target"

}

set_ip() {
   [[ $1 ]] || return
   printf 'server-ip=%s\n' $1 >> "$target/$properties"
}

set_motd() {
   [[ $1 ]] || return
   printf 'motd=%s\n' "$1" >> "$target/$properties"
}

set_port() {
   [[ $1 ]] || return
   printf 'server-port=%s\n' $1 >> "$target/$properties"
}

set_world() {
   [[ $1 ]] || return
   printf 'level-name=%s\n' "$1" >> "$target/$properties"
}

set_user() {
   [[ "$1" ]] || return
   sed -i '' -e "/setuidgid/s/minecraft/$1/" "$target/run"
}

set_jvm() {
   [[ $1 ]] || return
   sed -i '' -e "1c\\
$1
" "$target/$env_dir/JAVA"
}

set_jvm_options() {
   [[ $1 ]] || return
   sed -i '' -e "1c\\
$1
" "$target/$env_dir/JAVA_OPTS"
}

set_jar() {
   [[ $1 ]] || return
   sed -i '' -e "1c\\
$1
" "$target/$env_dir/SERVER"
}

set_ram() {
   [[ $1 ]] || return
   sed -i '' -e "1c\\
$1
" "$target/$env_dir/RAM"
}

set_eula() {
   # TODO: Download and save the EULA
   case "$1" in
      true|yes) printf 'eula=true\n' > "$eula_file" ;;
   esac
}

set_png() {
   [[ $1 ]] || return; # No PNG? No setting it.

   case "$1" in
      http://*|https://*)
         wget \
            --no-check-certificate \
            --quiet \
            --output-document="$target/$icon_file" \
            "$1" || warn "Could not download $1"
         printf '%s\n' "$1" > "$target/$icon_file.uri"
         ;;
      *) cp "$1" "$target"
         ln -s "$(basename "$1")" "$target/$icon_file"
         ;;
   esac
}

# Do it

verify_target "$target"
verify_ip "$ip"
verify_jar "$jar"
verify_jvm_options "$jvm_options"
verify_jvm "$jvm"
verify_motd "$motd"
verify_png "$png"
verify_port "$port"
verify_ram "$ram"
verify_user "$user"
verify_world "$word"
verify_eula "$eula"


# Create / Set up service directory
set_target "$target"

# server.properties
set_port $port
set_ip $ip
set_world "$world"
set_motd "$motd"

# ENV
set_user $user
set_jvm "$jvm"
set_jvm_options "$jvm_options"
set_jar "$jar"
set_ram "$ram"

# eula.txt
set_eula "$eula"

# server-icon.png
set_png "$png"
