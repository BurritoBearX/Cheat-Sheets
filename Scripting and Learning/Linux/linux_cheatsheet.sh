#!/bin/bash
# =============================================================================
# LINUX / BASH CHEAT SHEET — Beginner Reference
# =============================================================================


# =============================================================================
# NAVIGATION & FILE SYSTEM
# =============================================================================

pwd                         # print working directory — shows where you are
ls                          # list files in current directory
ls -l                       # long format — shows permissions, size, date
ls -a                       # show hidden files (names starting with .)
ls -lh                      # long format with human-readable file sizes
ls -lt                      # sort by modification time, newest first
ls /etc                     # list files in a specific directory

cd /home/alice              # change to an absolute path
cd Documents                # change to a relative path
cd ..                       # go up one directory
cd ~                        # go to your home directory
cd -                        # go back to the previous directory

# Paths
# /           root of the file system
# ~           your home directory  (/home/username)
# .           current directory
# ..          parent directory


# =============================================================================
# FILES & DIRECTORIES
# =============================================================================

touch notes.txt             # create an empty file (or update its timestamp)
mkdir Projects              # create a new directory
mkdir -p a/b/c              # create nested directories all at once

cp file.txt backup.txt      # copy a file
cp -r folder/ folder_copy/  # copy a folder and all its contents (-r = recursive)
mv file.txt /tmp/file.txt   # move a file to another location
mv old.txt new.txt          # rename a file (move in place)
rm file.txt                 # delete a file
rm -r folder/               # delete a folder and its contents
rm -rf folder/              # force delete — no prompts (use carefully!)

ln -s /path/to/target link  # create a symbolic link (shortcut)

# Check file type and info
file notes.txt              # reports the type of file (text, binary, etc.)
stat notes.txt              # detailed metadata: size, permissions, timestamps
du -sh folder/              # disk usage of a folder in human-readable size
df -h                       # free disk space on all mounted filesystems


# =============================================================================
# VIEWING & EDITING FILES
# =============================================================================

cat file.txt                # print entire file to terminal
less file.txt               # view file one page at a time (q to quit)
more file.txt               # like less but simpler
head file.txt               # show first 10 lines
head -n 20 file.txt         # show first 20 lines
tail file.txt               # show last 10 lines
tail -n 20 file.txt         # show last 20 lines
tail -f app.log             # follow a file in real time (useful for logs)

# Text editors (terminal-based)
nano file.txt               # beginner-friendly editor  (Ctrl+S save, Ctrl+X exit)
vim file.txt                # powerful editor  (i to insert, Esc :wq to save+quit)

# Write text directly to a file
echo "Hello" > file.txt     # write (overwrite if file exists)
echo "World" >> file.txt    # append — adds to end of file

# Count lines, words, characters
wc -l file.txt              # number of lines
wc -w file.txt              # number of words
wc -c file.txt              # number of bytes


# =============================================================================
# PERMISSIONS
# =============================================================================

# Every file has three permission sets:
#   owner  (u)    group  (g)    everyone else  (o)
# Each set can have: r (read=4)  w (write=2)  x (execute=1)

ls -l file.txt              # -rwxr-xr-- means owner=rwx group=r-x others=r--

chmod 755 script.sh         # set permissions numerically (rwxr-xr-x)
chmod +x script.sh          # add execute permission for everyone
chmod -w file.txt           # remove write permission for everyone
chmod u+x file.txt          # add execute permission for the owner only
chmod go-w file.txt         # remove write from group and others

chown alice file.txt        # change file owner to alice
chown alice:devs file.txt   # change owner to alice, group to devs
chgrp devs file.txt         # change group only

# Common permission combos
# 777  rwxrwxrwx  everyone can do everything  (dangerous)
# 755  rwxr-xr-x  owner full, others read+exec  (typical for scripts)
# 644  rw-r--r--  owner read+write, others read  (typical for files)
# 600  rw-------  owner only  (private keys, sensitive files)


# =============================================================================
# USERS & GROUPS
# =============================================================================

whoami                      # print the current user's name
id                          # show user ID, group ID, and all group memberships
id alice                    # same for another user
groups                      # list groups the current user belongs to

sudo command                # run a command as root (superuser)
sudo -i                     # open a root shell
su alice                    # switch to another user (needs their password)

# User management (requires root/sudo)
useradd alice               # create a new user
useradd -m alice            # create user and automatically create home directory
passwd alice                # set or change a user's password
usermod -aG devs alice      # add alice to the devs group  (-a = append)
userdel alice               # delete a user
userdel -r alice            # delete user and their home directory

# Group management
groupadd devs               # create a new group
groupdel devs               # delete a group

# User info files
cat /etc/passwd             # list of all user accounts
cat /etc/group              # list of all groups


# =============================================================================
# PROCESSES
# =============================================================================

ps                          # list processes owned by you in current shell
ps aux                      # list all running processes with detail
top                         # live process monitor (q to quit)
htop                        # interactive process monitor (if installed)

# Find a process by name
pgrep nginx                 # print PIDs of processes named nginx
ps aux | grep nginx         # search process list for nginx

# Kill processes
kill 1234                   # send SIGTERM (graceful stop) to process ID 1234
kill -9 1234                # send SIGKILL (force kill) — no cleanup
pkill nginx                 # kill all processes named nginx
killall nginx               # same as pkill nginx

# Run in background
./script.sh &               # run a command in the background
jobs                        # list background jobs in current shell
fg                          # bring background job to foreground
fg %2                       # bring job #2 to foreground
bg                          # resume a stopped job in the background

# Keep running after logout
nohup ./script.sh &         # run and ignore hangup signal
disown %1                   # detach job from current shell

# Process priority (nice value: -20 = highest, 19 = lowest)
nice -n 10 ./script.sh      # start a process with lower priority
renice 5 -p 1234            # change priority of an existing process


# =============================================================================
# SEARCHING
# =============================================================================

# Find files by name or property
find . -name "*.txt"                    # find all .txt files under current dir
find /home -name "notes.txt"            # search from a specific directory
find . -type d                          # find only directories
find . -type f -size +10M               # files larger than 10 megabytes
find . -newer reference.txt             # files modified more recently than reference.txt
find . -mtime -7                        # files modified in the last 7 days
find . -name "*.log" -delete            # find and delete all .log files

# Search file contents with grep
grep "error" app.log                    # find lines containing "error"
grep -i "error" app.log                 # case-insensitive search
grep -r "TODO" ./src/                   # search recursively in a directory
grep -n "error" app.log                 # show line numbers
grep -v "debug" app.log                 # show lines that do NOT match
grep -c "error" app.log                 # count matching lines
grep -l "error" *.log                   # list only the file names that match

# Grep with regex
grep -E "err|warn" app.log              # match "err" or "warn" (extended regex)
grep "^2024" app.log                    # lines starting with 2024
grep "\.sh$" file.txt                   # lines ending with .sh

# Search command history
history                                 # show recent commands
history | grep "git"                    # find past git commands
Ctrl+R                                  # interactive reverse search in history


# =============================================================================
# PIPES & REDIRECTION
# =============================================================================

# Pipes — pass output of one command as input to the next
ls -l | grep ".txt"         # list files, then filter to only .txt lines
cat file.txt | sort         # sort the lines of a file
cat file.txt | sort | uniq  # sort lines and remove duplicates
ps aux | grep nginx | wc -l # count running nginx processes

# Redirection — control where output goes
command > file.txt          # redirect stdout to file (overwrites)
command >> file.txt         # redirect stdout to file (appends)
command 2> error.log        # redirect stderr to file
command 2>&1                # redirect stderr to the same place as stdout
command > out.txt 2>&1      # both stdout and stderr to the same file
command < input.txt         # use file contents as stdin

# Discard output
command > /dev/null         # throw away stdout
command > /dev/null 2>&1    # throw away both stdout and stderr

# Useful pipe commands
sort file.txt               # sort lines alphabetically
sort -n numbers.txt         # sort numerically
sort -r file.txt            # sort in reverse
uniq file.txt               # remove consecutive duplicate lines
uniq -c file.txt            # count how many times each line appears
cut -d',' -f1 data.csv      # extract the first column of a CSV
tr 'a-z' 'A-Z'              # translate — convert lowercase to uppercase
sed 's/foo/bar/g' file.txt  # replace all occurrences of "foo" with "bar"
awk '{print $1}' file.txt   # print the first column of each line
xargs                       # build and run commands from stdin


# =============================================================================
# VARIABLES & ENVIRONMENT
# =============================================================================

# Define a variable — no spaces around =
name="Alice"
age=25

# Use a variable — prefix with $
echo $name              # Alice
echo "Hello, $name!"    # Hello, Alice!
echo "Age: ${age}"      # Age: 25  — braces separate variable from surrounding text

# Command substitution — capture output of a command as a value
today=$(date +%Y-%m-%d)
files=$(ls | wc -l)
echo "Today is $today"
echo "There are $files files"

# Environment variables — available to the current shell and all child processes
export MY_VAR="hello"       # export makes it visible to child processes
echo $MY_VAR                # hello

# Common built-in environment variables
echo $HOME          # /home/alice         — home directory
echo $USER          # alice               — current username
echo $PATH          # /usr/bin:/bin:...   — directories searched for commands
echo $SHELL         # /bin/bash           — current shell
echo $PWD           # /home/alice/docs    — current directory
echo $HOSTNAME      # my-machine          — machine name
echo $RANDOM        # random integer 0–32767

# Modify PATH to include a custom directory of scripts
export PATH="$PATH:/home/alice/scripts"

# View all environment variables
env
printenv
printenv HOME               # print a specific variable

# Unset a variable
unset MY_VAR


# =============================================================================
# CONDITIONALS
# =============================================================================

# if / elif / else  —  condition is a command; exit code 0 = true
score=85

if [ $score -ge 90 ]; then
    echo "A"
elif [ $score -ge 80 ]; then
    echo "B"
elif [ $score -ge 70 ]; then
    echo "C"
else
    echo "F"
fi

# Integer comparison operators (inside [ ] )
# -eq   equal to
# -ne   not equal to
# -gt   greater than
# -lt   less than
# -ge   greater than or equal
# -le   less than or equal

# String comparison operators
name="Alice"
if [ "$name" = "Alice" ]; then echo "Hi Alice"; fi
if [ "$name" != "Bob" ]; then echo "Not Bob"; fi
if [ -z "$name" ]; then echo "Empty string"; fi    # -z = zero length
if [ -n "$name" ]; then echo "Not empty"; fi       # -n = non-zero length

# File test operators
if [ -f "file.txt" ]; then echo "Is a file"; fi    # -f = regular file
if [ -d "folder" ]; then echo "Is a directory"; fi # -d = directory
if [ -e "path" ]; then echo "Exists"; fi           # -e = exists (any type)
if [ -r "file" ]; then echo "Readable"; fi         # -r = readable
if [ -x "script.sh" ]; then echo "Executable"; fi # -x = executable

# Logical operators
if [ $age -ge 18 ] && [ "$has_id" = "true" ]; then
    echo "Allowed"
fi

if [ $age -lt 13 ] || [ $age -gt 65 ]; then
    echo "Discount applies"
fi

# [[ ]] — extended test, supports && || and regex  (bash-specific)
if [[ $name == "Al"* ]]; then echo "Starts with Al"; fi
if [[ $str =~ ^[0-9]+$ ]]; then echo "All digits"; fi

# case statement — like switch
day="Monday"
case $day in
    Monday)    echo "Start of week" ;;
    Friday)    echo "End of week" ;;
    Saturday|Sunday)  echo "Weekend" ;;
    *)         echo "Midweek" ;;
esac


# =============================================================================
# LOOPS
# =============================================================================

# for — iterate over a list of values
for fruit in apple banana cherry; do
    echo $fruit
done

# for — iterate over files matching a pattern
for file in *.txt; do
    echo "Processing $file"
done

# for — C-style counter loop
for (( i=0; i<5; i++ )); do
    echo $i          # 0 1 2 3 4
done

# while — repeat while condition is true
count=0
while [ $count -lt 5 ]; do
    echo $count
    (( count++ ))
done

# until — repeat until condition becomes true
count=0
until [ $count -ge 5 ]; do
    echo $count
    (( count++ ))
done

# Loop through lines of a file
while IFS= read -r line; do
    echo "$line"
done < file.txt

# Loop through output of a command
while IFS= read -r line; do
    echo "$line"
done < <(ls -1)

# break — exit the loop early
for n in 1 2 3 4 5; do
    if [ $n -eq 3 ]; then break; fi
    echo $n             # prints 1 2
done

# continue — skip the rest of this iteration
for n in 1 2 3 4 5; do
    if [ $n -eq 3 ]; then continue; fi
    echo $n             # prints 1 2 4 5
done


# =============================================================================
# FUNCTIONS
# =============================================================================

# Define a function
greet() {
    echo "Hello, $1!"       # $1 is the first argument passed to the function
}

greet "Alice"               # Hello, Alice!

# Function with multiple arguments
add() {
    echo $(( $1 + $2 ))
}

result=$(add 3 4)           # capture return value into a variable
echo $result                # 7

# Return an exit code (0 = success, non-zero = failure)
is_even() {
    if (( $1 % 2 == 0 )); then
        return 0            # success / true
    else
        return 1            # failure / false
    fi
}

is_even 4 && echo "Even" || echo "Odd"

# Local variables — scoped to the function
calculate() {
    local result=$(( $1 * $2 ))     # local prevents leaking to outer scope
    echo $result
}

# Special variables inside scripts and functions
# $0       name of the script itself
# $1 $2    positional arguments (first, second, …)
# $@       all arguments as separate words
# $#       number of arguments
# $?       exit code of the last command (0 = success)
# $$       PID of the current script/shell
# $!       PID of the last background process


# =============================================================================
# SCRIPTS
# =============================================================================

# A script file starts with a shebang line
#!/bin/bash

# Make it executable and run it
chmod +x myscript.sh
./myscript.sh

# Pass arguments to a script
./deploy.sh production 443

# Inside the script
echo "Environment: $1"      # production
echo "Port: $2"             # 443
echo "All args: $@"         # production 443
echo "Arg count: $#"        # 2

# Check exit code of last command
git push
if [ $? -ne 0 ]; then
    echo "Push failed!"
    exit 1                  # exit script with failure code
fi

# Short-circuit — run next command only if previous succeeded
mkdir output && cp file.txt output/     # && = and
mkdir output || echo "mkdir failed"     # || = or  (run if previous failed)

# Read user input
echo -n "Enter your name: "
read username
echo "Hello, $username!"

# Read with a prompt
read -p "Enter port number: " port

# Read silently (for passwords)
read -s -p "Password: " password

# Arithmetic in scripts  (( ))  evaluates math
x=10
(( x += 5 ))
echo $x                     # 15
echo $(( 2 ** 8 ))          # 256

# String operations
str="Hello, World!"
echo ${#str}                # 13       — length of string
echo ${str:0:5}             # Hello    — substring from index 0, length 5
echo ${str/World/Linux}     # Hello, Linux!  — replace first match
echo ${str//l/L}            # HeLLo, WorLd!  — replace all matches
echo ${str,,}               # hello, world!  — all lowercase
echo ${str^^}               # HELLO, WORLD!  — all uppercase

# Default values
name=${1:-"World"}          # use $1 if set, otherwise "World"
echo "Hello, $name!"


# =============================================================================
# NETWORKING
# =============================================================================

# Check connectivity
ping google.com                         # send ICMP echo requests (Ctrl+C to stop)
ping -c 4 google.com                    # send exactly 4 pings
traceroute google.com                   # show network route to destination

# DNS lookups
nslookup google.com                     # query DNS for an IP
dig google.com                          # detailed DNS query
host google.com                         # simple DNS lookup

# Network interfaces and addresses
ip addr                                 # show all network interfaces and IPs
ip addr show eth0                       # show a specific interface
ip route                                # show routing table
hostname -I                             # print all local IP addresses

# Open ports and connections
ss -tuln                                # list listening TCP/UDP ports
ss -tlnp                                # same, with process names
netstat -tuln                           # older equivalent (if netstat installed)

# Transfer files
curl -O https://example.com/file.zip   # download file, keep original name
curl -o output.zip https://example.com/file.zip  # download with a custom name
wget https://example.com/file.zip      # download a file with wget
curl -s https://api.example.com/data   # fetch URL silently (no progress bar)
curl -X POST -d '{"key":"val"}' https://api.example.com    # POST request

# SSH
ssh alice@192.168.1.10                 # connect to a remote host
ssh -p 2222 alice@host.com            # connect on a non-default port
ssh -i ~/.ssh/mykey.pem alice@host    # connect using a specific key file
scp file.txt alice@host:/home/alice/  # copy a file to a remote host
scp alice@host:/path/file.txt .       # copy a file from a remote host
scp -r folder/ alice@host:/remote/    # copy a folder recursively

# Generate SSH key pair
ssh-keygen -t ed25519 -C "alice@example.com"

# Copy public key to a server for passwordless login
ssh-copy-id alice@host.com


# =============================================================================
# PACKAGE MANAGEMENT
# =============================================================================

# --- Debian / Ubuntu  (apt) ---
sudo apt update                         # refresh package index
sudo apt upgrade                        # upgrade all installed packages
sudo apt install nginx                  # install a package
sudo apt remove nginx                   # remove a package
sudo apt autoremove                     # remove unused dependencies
apt search nginx                        # search for a package by name
apt show nginx                          # show details about a package
dpkg -l                                 # list all installed packages

# --- Red Hat / CentOS / Fedora  (dnf / yum) ---
sudo dnf update                         # update all packages
sudo dnf install nginx                  # install a package
sudo dnf remove nginx                   # remove a package
dnf search nginx                        # search for a package

# --- Arch Linux  (pacman) ---
sudo pacman -Syu                        # update system
sudo pacman -S nginx                    # install a package
sudo pacman -R nginx                    # remove a package
pacman -Ss nginx                        # search for a package

# Snap and Flatpak (cross-distro)
sudo snap install code --classic        # install via snap
flatpak install flathub com.spotify.Client  # install via flatpak


# =============================================================================
# ARCHIVING & COMPRESSION
# =============================================================================

# tar — bundle files into an archive
tar -cvf archive.tar folder/            # create archive  (c=create v=verbose f=file)
tar -xvf archive.tar                    # extract archive
tar -xvf archive.tar -C /tmp/          # extract into a specific directory
tar -tvf archive.tar                    # list contents without extracting

# tar with gzip compression (.tar.gz or .tgz)
tar -czvf archive.tar.gz folder/        # create compressed archive
tar -xzvf archive.tar.gz               # extract compressed archive

# tar with bzip2 compression (.tar.bz2)  — slower but better compression
tar -cjvf archive.tar.bz2 folder/
tar -xjvf archive.tar.bz2

# zip and unzip
zip -r archive.zip folder/             # create zip archive
zip archive.zip file1.txt file2.txt    # zip specific files
unzip archive.zip                      # extract zip
unzip archive.zip -d /tmp/output/      # extract to a specific directory
unzip -l archive.zip                   # list contents without extracting

# gzip — compress a single file (replaces the original)
gzip file.txt                          # creates file.txt.gz
gunzip file.txt.gz                     # decompress back to file.txt
gzip -k file.txt                       # keep original: creates file.txt.gz alongside it


# =============================================================================
# SYSTEM INFORMATION
# =============================================================================

uname -a                    # kernel name, hostname, version, architecture
uname -r                    # kernel version only
cat /etc/os-release         # distro name and version
lsb_release -a              # distro info  (Debian/Ubuntu)
hostnamectl                 # hostname and OS info (systemd systems)

# Hardware
lscpu                       # CPU info — cores, threads, architecture
free -h                     # RAM usage in human-readable form
lsblk                       # block devices — disks and partitions
lspci                       # PCI devices — GPU, network cards, etc.
lsusb                       # connected USB devices

# System load and uptime
uptime                      # how long the system has been running + load averages
w                           # who is logged in and what they are doing
last                        # login history
dmesg | tail                # kernel log messages (useful for hardware issues)

# Services (systemd)
systemctl status nginx      # check status of a service
systemctl start nginx       # start a service
systemctl stop nginx        # stop a service
systemctl restart nginx     # restart a service
systemctl enable nginx      # start automatically on boot
systemctl disable nginx     # stop starting on boot
systemctl list-units        # list all active units
journalctl -u nginx         # view logs for a specific service
journalctl -f               # follow the system journal log in real time


# =============================================================================
# USEFUL ONE-LINERS
# =============================================================================

# Find the 10 largest files in a directory tree
du -ah . | sort -rh | head -10

# Count the number of lines in all .py files
find . -name "*.py" | xargs wc -l | tail -1

# Find and kill a process by name
kill $(pgrep nginx)

# Watch a command refresh every 2 seconds
watch -n 2 "df -h"

# Show the most frequently used commands
history | awk '{print $2}' | sort | uniq -c | sort -rn | head -10

# Display a file without comments or blank lines
grep -v "^#" config.conf | grep -v "^$"

# Recursively replace a string in all files
find . -name "*.txt" -exec sed -i 's/foo/bar/g' {} +

# Check which process is listening on port 8080
ss -tlnp | grep :8080

# Get your public IP address
curl -s https://ifconfig.me

# Generate a random password (16 characters)
openssl rand -base64 16

# Show disk usage sorted by size
du -sh */ | sort -rh

# Batch rename files — replace spaces with underscores
for f in *\ *; do mv "$f" "${f// /_}"; done

# Run the previous command as sudo
sudo !!

# Create a dated backup of a file
cp file.txt file.txt.$(date +%Y%m%d)

# Monitor log file for errors in real time
tail -f app.log | grep --line-buffered "ERROR"
