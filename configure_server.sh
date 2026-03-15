#!/bin/bash

# Personal script for setting up server efficiently and accurately

set -euo pipefail

ESSENTIAL_CMDS="micro curl wget git gh ufw fail2ban unattended-upgrades gum go sendmail" # discarded: mailutils
CHECKPOINT=${1:-""}
PORT=2983
FIREWALL=
JAIL='/etc/fail2ban/jail.local'
AUTO_UPGRADES_FILE='/etc/apt/apt.conf.d/50unattended-upgrades'

run() {
	if [[ -z "$CHECKPOINT" ]]; then
		check_env
		prompt_system_update
		install_essentials
		list_users
		prompt_create_user
		prompt_authorized_keys
	elif [[ "$CHECKPOINT" == 'A' ]]; then
		check_env
		prompt_sshd_config
	elif [[ "$CHECKPOINT" == 'B' ]]; then
		check_env
		prompt_restart_sshd
		prompt_login_as_user
	elif [[ "$CHECKPOINT" == 'C' ]]; then
		require_sudo
		check_if_firewall_is_active
		prompt_activate_firewall
		enable_fail2ban
		enable_auto_security_updates
		info "Congratulations, you have reached the end of the basic setup script."
	else
		err "❌ UNRECOGNIZED CHECKPOINT"
		exit 2
	fi
	info "Instructions have been pulled from https://www.youtube.com/watch?v=40SnEd1RWUU"
}

am_i_root() {
    if [ "$EUID" -ne 0 ]; then
        err "❌ ERROR - YOU ARE NOT ROOT"
        exit 1
    fi
}

check_env() {
	am_i_root
    setup_data_dir
}

setup_data_dir() {
    if [[ -d "/var/data" ]]; then
        if [[ -L "/data" ]]; then
            echo ""
        else
            ln -sv /var/data /data
        fi
    else
        cat <<EOF

/var/data has not been found. Either mount a block storage on /var/data
(RECOMMENDED FOR VPS), or create it. To mount a storage block on /var/data,
do mount /dev/BLOCK /var/data. Once done, run this script again.

EOF
        exit 1
    fi
}

prompt_system_update() {
    read -rp "Run system updates? [Y/n]: " response
    case "${response,,}" in
        n|no) info "Skipping system updates." ;;
        *)    apply_all_system_updates ;;
    esac
}

apply_all_system_updates() {
	info 'UPDATING SYSTEM...'
	apt update && apt upgrade -y
}

install_essentials() {
	info "INSTALLING ESSENTIALS..."
	apt install -y $ESSENTIAL_CMDS
}

list_users() {
    local users
    mapfile -t users < <(awk -F: '($3 >= 1000 && $3 < 65534) { print $1 }' /etc/passwd)

    if [[ ${#users[@]} -eq 0 ]]; then
        info "No regular users found."
    else
        info "Regular users:"
        for user in "${users[@]}"; do
            echo "  - $user"
        done
    fi
    sleep 1.5
}

create_user() {
	adduser "$username"
	usermod -aG sudo "$username"
	info "User $username created and added to sudo."
	info "Users can be deleted with userdel -r USER"
}

prompt_create_user() {
    ans=$(confirm "Create a new user?")
    case $ans in
        1) ;;
        0) info "Skipping user creation." ; return 0 ;;
    esac

    local username
    while true; do
        username=$(input "Enter new username:")

        if [[ -z "$username" ]]; then
            echo "Username cannot be empty. Try again."
            continue
        fi

        if id "$username" &>/dev/null; then
            echo "User '$username' already exists. Try again."
            continue
        fi

        break
    done

    create_user "$username"
}

prompt_authorized_keys() {
	cat << EOF
CHECKPOINT A

Now is the time to edit ~/.ssh/authorized_keys for the selected user.
Read these instructions carefully.

You should have at least one regular user at this point. For the user you
wish to ssh into, you must edit his authorized_keys file in order to allow
clients to connect via key. Clients keep their private key in the path
defined as IdentityFile in ~/.ssh/config. The devices\' public ssh keys
should be available at https://vault.alj.app. Fetch the public keys, and
paste them unto /home/USERNAME/.ssh/authorized_keys.

Once over, return to me by running this script again with a checkpoint:

setup-server A

EOF
}

prompt_sshd_config() {
	cat << EOF
CHECKPOINT B

Now is the time to harden the server.

To enhance safety, set the following configuration in
/etc/ssh/sshd_config:

Port 2983
Protocol 2
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no
UsePAM yes
X11Forwarding no
AllowUsers ash solaire
MaxAuthTries 3
LoginGraceTime 30

Make sure you copied this config to clipboard. I will now open the editor
and release the terminal for you. Once over, return to me by running this
script again with a checkpoint:

setup-server B

EOF

read -rp "OK?" -n1
echo
nano /etc/ssh/sshd_config
sshd -t
info "Checkpoint: B"
exit 0
}

restart_sshd() {
    info "RESTARTING SSHD..."
    systemctl reload  ssh
    systemctl restart ssh
}

prompt_restart_sshd() {
    if sshd -t; then
        info "SSHD CONFIG IS OK."
        ans=$(confirm "DO YOU WISH TO RESTART SSHD?")
        case $ans in
            1)  restart_sshd ;;
            0)  echo "Checkpoint: B" ; exit 0 ;;
        esac
    else
        echo "SSHD CONFIG IS INVALID. Fix the errors above before continuing."
        exit 1
    fi
}

prompt_login_as_user() {
	cat << EOF
The SSH daemon should now have been restarted. Make sure you can ssh to your user
from another terminal before disconnecting this one. If you have successfully connected,
exit this section and carry on with checkpoint C by running setup-server C as a regular user.
EOF
	confirm "Understood?"
}

check_if_firewall_is_active() {
	if sudo ufw status | grep -q "Status: active"; then
	    FIREWALL=1
	else
	    FIREWALL=0
	fi
}

prompt_activate_firewall() {
	if [[ $FIREWALL -eq 1 ]]; then
		info "Firewall is already active."
		sudo ufw status
		ans=$(confirm "DEACTIVATE? (Don't)")
		case $ans in
			1) sudo ufw disable ;;
			0) ;;
		esac
	elif [[ $FIREWALL -eq 0 ]]; then
		info "Firewall is INACTIVE."
		ans=$(confirm "ACTIVATE THE FIREWALL? This might reset all ufw config if already configured.")
		case $ans in
			1) activate_firewall ;;
			0) info "Skipped firewall activation" ;;
		esac
	else
		err "Firewall is neither active nor inactive? Sum went wrong."
		exit 3
	fi
}

activate_firewall() {
	sudo ufw default deny incoming
	sudo ufw default allow outgoing
	sudo ufw allow 2983/tcp comment "SSH"
	sudo ufw allow 443/tcp  comment "HTTPS"
	sudo ufw enable
	sudo ufw status numbered
}

enable_fail2ban() {
	jail_exists=$(check_jail_exists)
	case $jail_exists in
		1) prompt_overwrite_jail ;;
		0) write_jail ;;
	esac
}

check_jail_exists() {
	if [[ -f $JAIL ]]
		then echo 1
		else echo 0
	fi
}

prompt_overwrite_jail() {
	ans=$(confirm "$JAIL already exists. Overwrite?")
	case $ans in
		1) write_jail ;;
		0) info "$JAIL untouched" ;;
	esac
}

write_jail() {
	cat <<EOF > $JAIL
# /etc/fail2ban/jail.local
[sshd]
enabled = true
port = 2983
maxretry = 3
bantime = 1h
findtime = 10m

# EXAMPLE, TODO
#[caddy]
#enabled = true
#port = 443
#logpath = /path/to/access.log
#maxretry = 5
#bantime = 1h
#findtime = 10m

EOF
	info "$JAIL created"
	sudo systemctl restart fail2ban
}

enable_auto_security_updates() {
	sudo dpkg-reconfigure unattended-upgrades
	cat <<EOF
TASK: you must locate this commented line in $AUTO_UPGRADES_FILE:

//Unattended-Upgrade::Remove-Unused-Dependencies "false";

and change it to:

Unattended-Upgrade::Remove-Unused-Dependencies "true";

I will now launch the editor so you can carry out your task.
Simply continue the script when it's over. This only needs to be
done once.

EOF
	# ans=$(confirm "Proceed?")
	case $(confirm "Proceed? Copy the line to clipboard first.") in
		0) info "Run setup-server 'C' to resume this flow" ; exit 0 ;;
		1) ;;
	esac
	sudo micro $AUTO_UPGRADES_FILE
}

# helpers
info()    { echo -e "\n$*\n" ; sleep 1.3 ; }
err()     { echo -e "\e[1;31m$*\e[0m" ; }
input()   { gum input --prompt "$* " ; }
confirm() {
	if gum confirm "\"$*\""
		then echo 1
		else echo 0
	fi
}
require_sudo() {
    if [[ "$EUID" -ne 0 ]]; then
        echo "This script must be run as root. Use sudo."
        exit 1
    fi
}
# helpers

run
