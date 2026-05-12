#!/bin/bash
# =============================================================================
# RHCSA (EX200) CHEAT SHEET — Red Hat Certified Systems Administrator
# Covers topics NOT in linux_cheatsheet.sh — assumes that as a foundation
# =============================================================================


# =============================================================================
# SPECIAL PERMISSIONS — SUID, SGID, STICKY BIT
# =============================================================================

# SUID (4) — file runs as its owner, not the invoking user (e.g. /usr/bin/passwd)
# SGID (2) — file runs as group owner; on directories, new files inherit the group
# Sticky bit (1) — on directories, only the file owner can delete their own files (e.g. /tmp)

chmod u+s script.sh         # add SUID symbolically
chmod g+s shared_dir/       # add SGID to a directory
chmod +t /tmp               # add sticky bit

chmod 4755 script.sh        # SUID + rwxr-xr-x  (4 = SUID)
chmod 2755 shared_dir/      # SGID + rwxr-xr-x  (2 = SGID)
chmod 1777 /tmp             # sticky + rwxrwxrwx (1 = sticky)
chmod 6755 script.sh        # SUID + SGID combined (4+2=6)

ls -l script.sh             # SUID shows as 's' in owner execute:  -rwsr-xr-x
ls -l shared_dir/           # SGID shows as 's' in group execute:  drwxr-sr-x
ls -ld /tmp                 # sticky shows as 't' in other execute: drwxrwxrwt

# Find files with special bits set
find / -perm -4000 2>/dev/null          # find all SUID files
find / -perm -2000 2>/dev/null          # find all SGID files
find / -perm -1000 -type d 2>/dev/null  # find directories with sticky bit


# =============================================================================
# ACCESS CONTROL LISTS (ACLs)
# =============================================================================

# ACLs extend standard permissions — grant/deny access per-user or per-group
# Filesystem must be mounted with ACL support (default on ext4/xfs)

getfacl file.txt                        # view ACL entries on a file
getfacl -R dir/                         # view ACLs recursively

setfacl -m u:alice:rw file.txt          # grant alice read+write
setfacl -m u:bob:--- file.txt           # explicitly deny bob all access
setfacl -m g:devs:rx file.txt           # grant devs group read+execute
setfacl -m o::- file.txt               # remove all permissions from others

setfacl -x u:alice file.txt             # remove alice's ACL entry
setfacl -b file.txt                     # remove ALL ACL entries

setfacl -R -m u:alice:rw dir/           # apply ACL recursively to a directory

# Default ACLs — new files/dirs inside the directory inherit these ACLs
setfacl -d -m u:alice:rw dir/           # set default ACL for new files
setfacl -d -m g:devs:rx dir/           # set default ACL for new files (group)
setfacl -k dir/                         # remove all default ACLs

# Copy ACLs from one file to another
getfacl source.txt | setfacl --set-file=- dest.txt


# =============================================================================
# SELINUX
# =============================================================================

# SELinux enforces mandatory access control — every process and file has a context
# Context format:  user:role:type:level  (type is what matters most)

# --- Check and change mode ---
getenforce                              # Enforcing / Permissive / Disabled
sestatus                                # detailed SELinux status

setenforce 1                            # set Enforcing  (temporary — survives until reboot)
setenforce 0                            # set Permissive (temporary — survives until reboot)

# Permanent mode — edit /etc/selinux/config, then reboot
# SELINUX=enforcing | permissive | disabled

# --- View contexts ---
ls -Z file.txt                          # show file SELinux context
ls -Zd dir/                             # show directory context
ps -eZ | grep nginx                     # show process context
id -Z                                   # show current user context

# --- Change file contexts ---
chcon -t httpd_sys_content_t /var/www/html/index.html   # temporary — lost on relabel
chcon -R -t httpd_sys_content_t /var/www/html/          # recursive

# Permanent context rules — survives relabel and reboot
semanage fcontext -a -t httpd_sys_content_t '/web(/.*)?'  # add rule
semanage fcontext -m -t httpd_sys_content_t '/web(/.*)?'  # modify rule
semanage fcontext -d '/web(/.*)?'                          # delete rule
semanage fcontext -l                                       # list all rules

restorecon -Rv /web/                    # apply stored rules (restore contexts)
restorecon -v /web/index.html           # restore single file
# -R = recursive  -v = verbose (show what changed)

# Force full filesystem relabel on next boot (needed after disabling then re-enabling)
touch /.autorelabel

# --- Ports ---
semanage port -l                                        # list all port labels
semanage port -l | grep http                            # filter for http ports
semanage port -a -t http_port_t -p tcp 8080             # label port 8080 as http
semanage port -m -t http_port_t -p tcp 8080             # modify existing label
semanage port -d -t http_port_t -p tcp 8080             # delete port label

# --- Booleans ---
getsebool -a                            # list all booleans and values
getsebool httpd_enable_homedirs         # check a specific boolean
semanage boolean -l                     # list with descriptions

setsebool httpd_enable_homedirs on      # set boolean (temporary)
setsebool -P httpd_enable_homedirs on   # set boolean (permanent — writes to policy)

# --- Troubleshooting AVC denials ---
ausearch -m avc -ts recent              # search audit log for recent denials
ausearch -m avc -ts today               # denials from today
ausearch -m avc -c httpd               # denials involving httpd process

audit2why < /var/log/audit/audit.log    # explain why access was denied
audit2allow -w -a                       # human-readable explanation of all denials

# Create a custom policy module to allow denied actions
audit2allow -a -M mypolicy              # generate policy module from audit log
semodule -i mypolicy.pp                 # install the module
semodule -l                             # list installed modules
semodule -r mypolicy                    # remove module


# =============================================================================
# PARTITIONING & BLOCK DEVICES
# =============================================================================

lsblk                               # list block devices as a tree
lsblk -f                            # include filesystem types and UUIDs
blkid                               # show UUID and type for all devices
blkid /dev/sdb1                     # show UUID for specific partition

# --- fdisk (MBR — up to 2TB, max 4 primary partitions) ---
fdisk /dev/sdb                      # open interactive partition editor
# Inside fdisk:
#   p   — print partition table
#   n   — new partition
#   d   — delete partition
#   t   — change partition type  (82=swap, 83=Linux, 8e=LVM)
#   w   — write changes and exit
#   q   — quit without saving

# --- gdisk (GPT — supports >2TB, up to 128 partitions) ---
gdisk /dev/sdb                      # open interactive GPT editor
# Inside gdisk: same key bindings as fdisk, type codes differ
#   8300 = Linux filesystem
#   8200 = Linux swap
#   8e00 = Linux LVM

# --- parted (scriptable, supports both MBR and GPT) ---
parted /dev/sdb print                           # print partition table
parted /dev/sdb mklabel gpt                     # create GPT label (destroys data!)
parted /dev/sdb mklabel msdos                   # create MBR label
parted /dev/sdb mkpart primary xfs 1MiB 1GiB   # create a partition
parted /dev/sdb rm 1                            # remove partition 1
parted /dev/sdb print free                      # show free space

partprobe /dev/sdb                  # tell the kernel to re-read partition table
                                    # (use after creating/deleting partitions)
udevadm settle                      # wait for udev to process partition events


# =============================================================================
# LVM — LOGICAL VOLUME MANAGER
# =============================================================================

# Stack: Physical Volumes (PV) → Volume Groups (VG) → Logical Volumes (LV)

# --- Physical Volumes ---
pvcreate /dev/sdb1                  # initialize a partition as a PV
pvcreate /dev/sdb1 /dev/sdc1        # initialize multiple at once
pvs                                 # brief list of PVs
pvdisplay                           # detailed PV info
pvdisplay /dev/sdb1                 # info for one PV
pvremove /dev/sdb1                  # remove PV label (data is gone)

# --- Volume Groups ---
vgcreate vg_data /dev/sdb1          # create VG named vg_data
vgcreate vg_data /dev/sdb1 /dev/sdc1  # create from multiple PVs
vgs                                 # brief list of VGs
vgdisplay vg_data                   # detailed VG info
vgextend vg_data /dev/sdc1          # add a PV to existing VG
vgreduce vg_data /dev/sdc1          # remove a PV from VG (must be empty)
vgrename vg_data vg_new             # rename a VG
vgremove vg_data                    # remove VG (all LVs must be removed first)

# --- Logical Volumes ---
lvcreate -L 5G -n lv_data vg_data           # create 5 GB LV
lvcreate -L 500M -n lv_swap vg_data         # create 500 MB LV
lvcreate -l 100%FREE -n lv_data vg_data     # use ALL remaining space
lvcreate -l 50%VG -n lv_data vg_data        # use 50% of VG size
lvs                                          # brief list of LVs
lvdisplay /dev/vg_data/lv_data               # detailed LV info
lvrename vg_data lv_data lv_new              # rename an LV
lvremove /dev/vg_data/lv_data                # remove LV (unmount first)

# --- Extending an LV (online — no unmount needed for xfs) ---
lvextend -L +2G /dev/vg_data/lv_data         # add 2 GB to LV
lvextend -L 10G /dev/vg_data/lv_data         # resize LV to exactly 10 GB
lvextend -l +100%FREE /dev/vg_data/lv_data   # use all remaining VG space

# After extending, resize the filesystem to use the new space:
xfs_growfs /mnt/data                         # xfs — resize by mount point (must be mounted)
resize2fs /dev/vg_data/lv_data               # ext4 — resize by device (can be unmounted)
lvextend -r -L +2G /dev/vg_data/lv_data      # -r auto-resizes filesystem for you

# --- Reducing an LV (ext4 only — xfs cannot shrink) ---
# unmount → fsck → resize2fs → lvreduce
umount /mnt/data
e2fsck -f /dev/vg_data/lv_data
resize2fs /dev/vg_data/lv_data 3G
lvreduce -L 3G /dev/vg_data/lv_data
mount /dev/vg_data/lv_data /mnt/data


# =============================================================================
# FILESYSTEMS, MOUNTING & /etc/fstab
# =============================================================================

# --- Create filesystems ---
mkfs.xfs /dev/sdb1                  # XFS (default on RHEL 9)
mkfs.xfs -f /dev/sdb1               # force — overwrite existing filesystem
mkfs.ext4 /dev/sdb1                 # ext4
mkfs.vfat /dev/sdb1                 # FAT32 (USB drives)

# --- Mount / unmount ---
mount /dev/sdb1 /mnt/data           # mount by device path
mount UUID="abc-123" /mnt/data      # mount by UUID
mount -t xfs /dev/sdb1 /mnt/data    # specify filesystem type
umount /mnt/data                    # unmount by mount point
umount /dev/sdb1                    # unmount by device

# --- /etc/fstab — persistent mounts ---
# Format:  DEVICE   MOUNTPOINT   FSTYPE   OPTIONS   DUMP   PASS
# PASS: 0=skip fsck, 1=root (first), 2=other (after root)
# Examples:
# UUID=abc-123   /data   xfs    defaults        0 0
# UUID=def-456   /home   ext4   defaults        0 0
# /dev/vg_data/lv_data   /mnt/lvm   xfs   defaults   0 0
# UUID=ghi-789   swap    swap   defaults        0 0
# server:/export /mnt/nfs nfs   defaults,_netdev 0 0

blkid /dev/sdb1                     # get UUID to paste into fstab
mount -a                            # mount everything in fstab (test fstab is valid)
systemctl daemon-reload             # reload after editing fstab

# --- Swap ---
mkswap /dev/sdb2                    # create swap space on a partition
mkswap /dev/vg_data/lv_swap         # create swap on an LV
swapon /dev/sdb2                    # enable swap (temporary)
swapoff /dev/sdb2                   # disable swap
swapon -s                           # list active swap
free -h                             # show RAM and swap usage


# =============================================================================
# AUTOFS — AUTOMATIC MOUNTING
# =============================================================================

# autofs mounts filesystems on demand and unmounts after idle timeout
# Useful for NFS home directories and removable media

dnf install -y autofs               # install autofs if not present
systemctl enable --now autofs       # start and enable

# Master map file: /etc/auto.master or /etc/auto.master.d/*.autofs
# Format:  MOUNT-POINT   MAP-FILE   [OPTIONS]

# /etc/auto.master.d/nfs.autofs
# /mnt/nfs   /etc/auto.nfs   --timeout=60

# Indirect map: /etc/auto.nfs
# Each key is a subdirectory under the master mount point
# homes   -rw,sync   server:/exports/homes
# data    -rw,sync   server:/exports/data
# &       -rw,sync   server:/home/&    # & = wildcard key (great for user homes)

# Direct map — mounts at exact paths specified in the map
# /etc/auto.master.d/direct.autofs
# /-   /etc/auto.direct

# /etc/auto.direct
# /mnt/db   -rw,sync   server:/exports/db

systemctl restart autofs            # apply config changes


# =============================================================================
# STRATIS STORAGE (RHEL 9)
# =============================================================================

# Stratis is an easy-to-use local storage management layer (thin provisioning, snapshots)
# Stratis pools are always XFS — you cannot choose the filesystem type

dnf install -y stratisd stratis-cli
systemctl enable --now stratisd

stratis pool create mypool /dev/sdb             # create a pool on one device
stratis pool add-data mypool /dev/sdc           # add device to existing pool
stratis pool list                               # list pools
stratis pool destroy mypool                     # destroy pool

stratis filesystem create mypool myfs           # create a filesystem in pool
stratis filesystem list                         # list filesystems
stratis filesystem rename mypool myfs newname   # rename filesystem
stratis filesystem destroy mypool myfs          # destroy filesystem

# Snapshots
stratis filesystem snapshot mypool myfs snap1   # create snapshot
stratis filesystem list mypool                  # list includes snapshots

# Mounting
mount /stratis/mypool/myfs /mnt/stratis         # mount temporarily

# In /etc/fstab — must use x-systemd.requires to ensure stratisd starts first
# UUID=...  /mnt/stratis  xfs  defaults,x-systemd.requires=stratisd.service  0 0
blkid /stratis/mypool/myfs                      # get UUID for fstab


# =============================================================================
# NETWORK CONFIGURATION — nmcli
# =============================================================================

# nmcli — command-line tool for NetworkManager

# --- View status ---
nmcli device status                             # list all interfaces and state
nmcli device show eth0                          # detailed info for one interface
nmcli connection show                           # list all connection profiles
nmcli connection show "Wired connection 1"      # detailed info for a profile
nmcli general status                            # overall NM status

# --- Manage connections ---
nmcli device connect eth0                       # activate interface with default profile
nmcli device disconnect eth0                    # deactivate interface
nmcli connection up "eth0-static"               # activate a specific connection
nmcli connection down "eth0-static"             # deactivate a connection
nmcli connection delete "eth0-static"           # delete a connection profile

# --- Create a static IP connection ---
nmcli connection add \
    type ethernet \
    ifname eth0 \
    con-name eth0-static \
    ipv4.method manual \
    ipv4.addresses 192.168.1.100/24 \
    ipv4.gateway 192.168.1.1 \
    ipv4.dns "8.8.8.8 8.8.4.4"

# --- Modify an existing connection ---
nmcli connection modify eth0-static ipv4.addresses 192.168.1.200/24
nmcli connection modify eth0-static ipv4.dns 8.8.8.8
nmcli connection modify eth0-static ipv4.method manual
nmcli connection modify eth0-static +ipv4.dns 1.1.1.1  # add a second DNS
nmcli connection modify eth0-static -ipv4.dns 8.8.4.4  # remove a DNS

# After modifying, bring the connection up to apply changes
nmcli connection up eth0-static

# --- Hostname ---
hostnamectl set-hostname myserver.example.com   # set FQDN hostname
hostnamectl status                              # show hostname info
nmcli general hostname myserver                 # alternative

# /etc/hosts — local hostname resolution (used before DNS)
# 192.168.1.50   db.example.com db

# --- nmtui — text UI (easier for interactive use) ---
nmtui                               # open menu-driven network config tool


# =============================================================================
# FIREWALLD
# =============================================================================

# firewalld uses zones — each zone has rules for interfaces/sources assigned to it
# Always use --permanent to survive reboots, then --reload to apply now

systemctl enable --now firewalld    # start and enable
firewall-cmd --state                # is firewalld running?

# --- Zones ---
firewall-cmd --get-zones                        # list all zone names
firewall-cmd --get-default-zone                 # show default zone
firewall-cmd --set-default-zone=public          # change default zone
firewall-cmd --get-active-zones                 # show zones with assigned interfaces
firewall-cmd --list-all                         # list rules in default zone
firewall-cmd --zone=public --list-all           # list rules in specific zone
firewall-cmd --list-all-zones                   # list rules for all zones

# --- Services ---
firewall-cmd --get-services                     # list all predefined service names
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --permanent --zone=public --remove-service=http
firewall-cmd --zone=public --list-services      # list active services in zone

# --- Ports ---
firewall-cmd --permanent --zone=public --add-port=8080/tcp
firewall-cmd --permanent --zone=public --add-port=8080-8090/tcp
firewall-cmd --permanent --zone=public --remove-port=8080/tcp
firewall-cmd --zone=public --list-ports

# --- Apply changes ---
firewall-cmd --reload                           # apply all --permanent rules

# --- Interfaces ---
firewall-cmd --permanent --zone=internal --add-interface=eth1
firewall-cmd --permanent --zone=internal --change-interface=eth1  # move from another zone

# --- Rich rules (advanced — source IP-based control) ---
firewall-cmd --permanent --zone=public --add-rich-rule=\
    'rule family="ipv4" source address="192.168.1.0/24" service name="ssh" accept'
firewall-cmd --permanent --zone=public --add-rich-rule=\
    'rule family="ipv4" source address="10.0.0.5" drop'
firewall-cmd --zone=public --list-rich-rules


# =============================================================================
# ADVANCED USER & GROUP MANAGEMENT
# =============================================================================

# --- Password aging (chage) ---
chage -l alice                      # list current aging settings for alice
chage -M 90 alice                   # max password age: 90 days
chage -m 7 alice                    # min days between password changes
chage -W 14 alice                   # warn user 14 days before expiry
chage -I 30 alice                   # lock account 30 days after password expires
chage -E 2026-12-31 alice           # account hard expiry date
chage -d 0 alice                    # force password change on next login
chage -E -1 alice                   # remove account expiry

# /etc/login.defs — system-wide defaults for new users
#   PASS_MAX_DAYS   90
#   PASS_MIN_DAYS   7
#   PASS_WARN_AGE   14

# /etc/shadow — password hashes and aging data
#   format: user:hash:lastchange:min:max:warn:inactive:expire

# --- User creation with options ---
useradd -u 1500 -g devs -G wheel -s /bin/bash -m -d /home/alice -c "Alice Smith" alice
#       -u UID   -g primary_group   -G supplementary_groups   -s shell
#       -m create_home   -d home_dir   -c comment

usermod -s /sbin/nologin alice      # prevent interactive login
usermod -L alice                    # lock account (prepends ! to hash)
usermod -U alice                    # unlock account
usermod -aG wheel alice             # add to group without removing from others (-a is critical)
usermod -e 2026-12-31 alice         # set expiry with usermod

# --- sudo configuration ---
visudo                              # safe editor for /etc/sudoers (validates syntax)

# /etc/sudoers examples:
#   alice ALL=(ALL) ALL                   — full sudo, password required
#   alice ALL=(ALL) NOPASSWD: ALL         — full sudo, no password
#   alice ALL=(ALL) NOPASSWD: /bin/systemctl restart httpd   — specific command
#   %wheel ALL=(ALL) ALL                  — all members of wheel group

# Preferred: add files to /etc/sudoers.d/ (not directly to /etc/sudoers)
echo "alice ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/alice
chmod 440 /etc/sudoers.d/alice      # sudoers files must be 440 or 400


# =============================================================================
# TASK SCHEDULING — cron & at
# =============================================================================

# --- cron — recurring scheduled tasks ---
# Crontab format:  minute  hour  day-of-month  month  day-of-week  command
# Fields accept: *=any  ,=list  -=range  /=step
# Examples:
#   30 2 * * *       — 2:30 AM every day
#   0 */4 * * *      — every 4 hours
#   0 9 * * 1-5      — 9:00 AM Monday through Friday
#   */15 * * * *     — every 15 minutes
#   0 0 1 * *        — midnight on the 1st of every month

crontab -e                          # edit current user's crontab
crontab -l                          # list current user's crontab
crontab -r                          # remove current user's crontab
crontab -u alice -e                 # edit alice's crontab (as root)
crontab -u alice -l                 # list alice's crontab (as root)

# System-wide cron locations:
# /etc/crontab          — system crontab (has username field before command)
# /etc/cron.d/          — package-managed cron files
# /etc/cron.hourly/     — scripts run hourly by /etc/cron.d/0hourly
# /etc/cron.daily/      — scripts run daily
# /etc/cron.weekly/     — scripts run weekly
# /etc/cron.monthly/    — scripts run monthly

# Control who can use cron:
# /etc/cron.allow — if exists, only listed users can use cron
# /etc/cron.deny  — if exists, listed users cannot use cron

# --- at — one-time scheduled tasks ---
dnf install -y at                   # install at if needed
systemctl enable --now atd          # start and enable the at daemon

at 14:30                            # schedule commands for 2:30 PM today
at 09:00 tomorrow
at now +1 hour
at now +30 minutes
at 08:00 2026-12-25
# Type command(s) and press Ctrl+D to submit

echo "systemctl restart httpd" | at now +5 minutes  # non-interactive

atq                                 # list pending at jobs (same as at -l)
at -l                               # list pending at jobs
atrm 3                              # remove at job number 3
at -c 3                             # show contents of at job number 3

# /etc/at.allow and /etc/at.deny — same logic as cron.allow/deny


# =============================================================================
# SYSTEMD TARGETS
# =============================================================================

# Targets replace SysV runlevels — they group units that should be active together

# Common targets:
#   poweroff.target   — runlevel 0  (shutdown)
#   rescue.target     — runlevel 1  (single user, basic services only)
#   multi-user.target — runlevel 3  (multi-user, no GUI)
#   graphical.target  — runlevel 5  (multi-user + GUI)
#   reboot.target     — runlevel 6  (reboot)
#   emergency.target  — minimal environment, even less than rescue

systemctl get-default                           # show current default target
systemctl set-default multi-user.target         # set default (survives reboot)
systemctl set-default graphical.target

systemctl isolate rescue.target                 # switch to target NOW (non-persistent)
systemctl isolate multi-user.target             # drops GUI services if running
systemctl isolate emergency.target              # minimal recovery environment

systemctl poweroff                              # shut down immediately
systemctl reboot                                # reboot immediately
systemctl halt                                  # halt without powering off


# =============================================================================
# BOOT & RECOVERY — ROOT PASSWORD RESET
# =============================================================================

# Interrupt boot to reset lost root password:
# 1. At GRUB menu — press any key to stop countdown
# 2. Press 'e' to edit the selected boot entry
# 3. Find the line starting with 'linux' (the kernel line)
# 4. At the END of that line, add:   rd.break
#    The line becomes something like:
#    linux /vmlinuz-... root=/dev/mapper/rhel-root ro ... quiet rd.break
# 5. Press Ctrl+X to boot with that modification
# 6. At the (initramfs) switch_root prompt:

mount -o remount,rw /sysroot    # remount /sysroot with write permission
chroot /sysroot                 # change root into the real system
passwd root                     # set new root password
touch /.autorelabel             # force SELinux relabel on next boot (IMPORTANT)
exit                            # exit chroot
exit                            # exit initramfs — system reboots

# SELinux will relabel on next boot which takes a few extra minutes — this is normal

# --- GRUB2 configuration ---
# /etc/default/grub — user-editable GRUB settings
#   GRUB_TIMEOUT=5
#   GRUB_CMDLINE_LINUX="..."

# After editing /etc/default/grub, regenerate config:
grub2-mkconfig -o /boot/grub2/grub.cfg          # BIOS systems
grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg # UEFI systems


# =============================================================================
# TIME SERVICES — chrony & timedatectl
# =============================================================================

timedatectl                                     # show current date, time, timezone, NTP status
timedatectl set-time "2026-01-15 14:30:00"     # manually set time (requires NTP off)
timedatectl set-timezone America/New_York       # set timezone
timedatectl list-timezones                      # list all available timezones
timedatectl list-timezones | grep America       # filter timezones
timedatectl set-ntp true                        # enable NTP synchronization
timedatectl set-ntp false                       # disable NTP (required to set time manually)

# chrony — NTP client daemon (default on RHEL 9)
systemctl enable --now chronyd                  # start and enable chronyd

# /etc/chrony.conf — configuration file
# Add/modify NTP servers:
#   server time.example.com iburst
#   pool 2.rhel.pool.ntp.org iburst
# iburst = send burst of packets on first contact for faster sync

chronyc sources                                 # list NTP sources and status
chronyc sources -v                              # verbose — includes column headers
chronyc tracking                                # show clock synchronization details
chronyc makestep                                # immediately step clock to correct time


# =============================================================================
# PACKAGE MANAGEMENT — dnf, modules & rpm
# =============================================================================

# --- Basic dnf operations ---
dnf install -y nginx                # install (−y skips yes/no prompt)
dnf remove nginx                    # remove package
dnf reinstall nginx                 # reinstall
dnf update                          # update all packages
dnf update nginx                    # update specific package
dnf downgrade nginx                 # downgrade to previous version
dnf autoremove                      # remove unused dependencies

dnf search nginx                    # search package name and summary
dnf search all nginx                # search in all fields including description
dnf info nginx                      # show package details
dnf list installed                  # list all installed packages
dnf list available                  # list installable packages
dnf list installed | grep nginx     # check if nginx is installed
dnf provides /usr/sbin/nginx        # find which package owns a file
dnf provides "*/nginx"              # find package containing a filename pattern

# --- Repositories ---
dnf repolist                        # list enabled repos
dnf repolist all                    # list all repos (enabled and disabled)
dnf repolist enabled                # list only enabled repos
dnf repoinfo baseos                 # detailed info about a repo

dnf config-manager --enable rhel-9-for-x86_64-appstream-rpms
dnf config-manager --disable epel
dnf config-manager --add-repo https://example.com/repo.repo

# Repo files live in /etc/yum.repos.d/
# Minimal repo file:
# [myrepo]
# name=My Custom Repo
# baseurl=file:///repo   (or https://...)
# enabled=1
# gpgcheck=0

# --- AppStream Module Streams ---
# AppStream allows multiple versions of software (e.g. Python 3.9 vs 3.11)
dnf module list                                     # list all modules and streams
dnf module list nodejs                              # streams available for nodejs
dnf module info nodejs:18                           # info about a specific stream
dnf module enable nodejs:18                         # enable a stream
dnf module install nodejs:18/default               # install default profile of stream
dnf module install nodejs:18/development           # install development profile
dnf module disable nodejs:18                        # disable the stream
dnf module reset nodejs                             # reset module to default state
dnf module remove nodejs                            # remove installed module

# --- RPM (low-level package tool) ---
rpm -qa                             # list all installed packages
rpm -qa | grep nginx                # check if nginx is installed
rpm -qi nginx                       # query package info (description, version, etc.)
rpm -ql nginx                       # list all files installed by package
rpm -qc nginx                       # list config files of package
rpm -qd nginx                       # list documentation files
rpm -qf /usr/sbin/nginx             # which package owns this file?
rpm -q --requires nginx             # list package dependencies

rpm -ivh package.rpm                # install RPM file (i=install v=verbose h=hash)
rpm -Uvh package.rpm                # upgrade (installs if not present)
rpm -e nginx                        # erase (remove) package
rpm --verify nginx                  # verify package files haven't been tampered with


# =============================================================================
# CONTAINERS — podman
# =============================================================================

# podman — rootless, daemonless container tool (docker-compatible CLI)

# --- Images ---
podman search nginx                             # search registries for images
podman pull docker.io/library/nginx             # pull specific image
podman pull registry.access.redhat.com/ubi9    # pull UBI (Universal Base Image)
podman images                                   # list local images
podman rmi nginx                                # remove image
podman image prune                              # remove unused images
podman inspect docker.io/library/nginx          # inspect image details

# Registry configuration: /etc/containers/registries.conf

# --- Running containers ---
podman run -d --name webserver -p 8080:80 nginx                # detached mode
podman run -it --name mybox ubi9 /bin/bash                     # interactive
podman run --rm nginx nginx -t                                  # run and auto-remove after exit
podman run -d -e MYSQL_ROOT_PASSWORD=secret mysql              # pass env variable
podman run -d -v /host/data:/var/lib/mysql:Z mysql             # bind mount with SELinux label
#              -v host:container:options   :Z = set SELinux svirt_sandbox_file_t context

podman ps                               # list running containers
podman ps -a                            # list all containers (including stopped)
podman start webserver                  # start stopped container
podman stop webserver                   # gracefully stop running container
podman restart webserver                # restart container
podman rm webserver                     # remove container (must be stopped)
podman rm -f webserver                  # force remove running container
podman logs webserver                   # view container stdout/stderr logs
podman logs -f webserver                # follow log output
podman exec -it webserver /bin/bash     # exec into running container
podman inspect webserver                # detailed container info (IP, mounts, etc.)
podman top webserver                    # show processes inside container
podman stats webserver                  # show resource usage

# --- Persistent storage ---
podman volume create mydata             # create a named volume
podman run -d -v mydata:/app/data nginx # use named volume
podman volume ls                        # list volumes
podman volume inspect mydata            # inspect volume
podman volume rm mydata                 # remove volume

# --- Container as a systemd service (rootless — runs as user) ---
mkdir -p ~/.config/systemd/user
podman generate systemd --name webserver --files --new
# --new means the service will pull/create a fresh container each time
mv container-webserver.service ~/.config/systemd/user/

systemctl --user daemon-reload
systemctl --user enable --now container-webserver.service
systemctl --user status container-webserver.service

# Enable user services to persist after logout (linger)
loginctl enable-linger alice            # alice's services survive after she logs out
loginctl disable-linger alice
loginctl show-user alice                # check linger status

# --- Container as a systemd service (root — system-wide) ---
podman generate systemd --name webserver --files --new
mv container-webserver.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now container-webserver.service


# =============================================================================
# TUNED — SYSTEM PERFORMANCE PROFILES
# =============================================================================

tuned-adm list                          # list all available profiles
tuned-adm active                        # show currently active profile
tuned-adm recommend                     # suggest best profile for this system
tuned-adm profile throughput-performance  # switch to a profile
tuned-adm profile virtual-guest         # good for VMs
tuned-adm off                           # disable tuned (not recommended)

# Common profiles:
#   balanced             — power saving vs performance balance
#   throughput-performance — maximize throughput (server workloads)
#   latency-performance  — low latency (trading, RT workloads)
#   powersave            — maximum power saving
#   virtual-guest        — optimized for VMs
#   virtual-host         — optimized for hypervisors


# =============================================================================
# JOURNALCTL & LOGGING
# =============================================================================

journalctl                              # all journal entries (oldest first)
journalctl -r                           # reverse order (newest first)
journalctl -f                           # follow — live tail of journal
journalctl -n 50                        # last 50 entries
journalctl -u nginx                     # entries for nginx service only
journalctl -u nginx -f                  # follow nginx log
journalctl --since "2026-01-01"         # entries since a date
journalctl --since "2026-01-01" --until "2026-01-02"
journalctl --since "1 hour ago"
journalctl -p err                       # entries at error priority or higher
journalctl -p warning                   # warning and above
journalctl -b                           # entries since last boot
journalctl -b -1                        # entries from the previous boot
journalctl -k                           # kernel messages only
journalctl _UID=1000                    # entries from a specific user ID

# Persistent journal — by default journal is lost on reboot
mkdir -p /var/log/journal               # create this dir to make journal persistent
systemctl restart systemd-journald      # apply the change
