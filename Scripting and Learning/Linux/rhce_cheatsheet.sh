#!/bin/bash
# =============================================================================
# RHCE (EX294) CHEAT SHEET — Red Hat Certified Engineer
# Exam is almost entirely Ansible — RHCSA skills are assumed as a prerequisite
# =============================================================================


# =============================================================================
# INSTALLATION & SETUP
# =============================================================================

# Install Ansible on the control node (RHEL 9)
dnf install -y ansible-core              # base ansible
dnf install -y ansible                   # full Ansible (includes more modules/collections)

ansible --version                        # confirm install and show config paths
ansible-doc -l                           # list all installed modules
ansible-doc copy                         # show documentation for the copy module
ansible-doc -s copy                      # show short synopsis (useful during exam)

# Key paths:
#   /etc/ansible/ansible.cfg    — system-wide config (lowest priority)
#   ~/.ansible.cfg              — user-level config
#   ./ansible.cfg               — project-level config (HIGHEST priority — use this on exam)
#   /etc/ansible/hosts          — default inventory
#   ~/.ansible/roles/           — user role path
#   /etc/ansible/roles/         — system role path


# =============================================================================
# ANSIBLE.CFG — CONFIGURATION FILE
# =============================================================================

# Create ansible.cfg in your project directory — it takes priority over all others
# On the exam, always work from a project directory with its own ansible.cfg

# Minimal ansible.cfg for the exam:
cat > ansible.cfg << 'EOF'
[defaults]
inventory       = ./inventory
remote_user     = ansible
host_key_checking = False
roles_path      = ./roles:/etc/ansible/roles

[privilege_escalation]
become          = True
become_method   = sudo
become_user     = root
become_ask_pass = False
EOF

# Key [defaults] settings:
#   inventory         — path to inventory file or directory
#   remote_user       — SSH user to connect as
#   host_key_checking — set False to skip SSH host key prompts
#   roles_path        — colon-separated list of paths to search for roles
#   forks             — number of parallel hosts (default: 5)
#   log_path          — path to write execution log

# Key [privilege_escalation] settings:
#   become            — enable sudo by default
#   become_method     — sudo (default), su, pbrun, etc.
#   become_user       — which user to become (root is default)
#   become_ask_pass   — prompt for sudo password (set False if NOPASSWD in sudoers)


# =============================================================================
# INVENTORY — DEFINING MANAGED HOSTS
# =============================================================================

# Static inventory in INI format (most common on exam)
cat > inventory << 'EOF'
# Ungrouped hosts
192.168.1.10
srv1.example.com

[webservers]
web1.example.com
web2.example.com

[dbservers]
db1.example.com
db2.example.com

[dev]
web1.example.com
db1.example.com

# Group of groups
[production:children]
webservers
dbservers

# Variables applied to all hosts in a group
[webservers:vars]
http_port=80
max_connections=100

[all:vars]
ansible_user=ansible
EOF

# YAML inventory format (alternative)
cat > inventory.yml << 'EOF'
all:
  children:
    webservers:
      hosts:
        web1.example.com:
        web2.example.com:
          ansible_port: 2222       # per-host variable
    dbservers:
      hosts:
        db1.example.com:
      vars:
        db_port: 5432              # group variable
  vars:
    ansible_user: ansible          # applies to all hosts
EOF

# Test inventory
ansible all -i inventory --list-hosts          # list all hosts in inventory
ansible webservers --list-hosts                # list hosts in a group
ansible-inventory --list                       # show full inventory as JSON
ansible-inventory --graph                      # show inventory tree

# Special groups:
#   all       — every host in inventory
#   ungrouped — hosts not in any group

# Host patterns for targeting:
#   all                 — all hosts
#   webservers          — all hosts in webservers group
#   webservers,dbservers  — union of both groups
#   webservers:dbservers  — same as above (colon syntax)
#   webservers:!dbservers — webservers EXCLUDING those also in dbservers
#   webservers:&dbservers — intersection (hosts in both groups)
#   web*.example.com    — wildcard
#   web[1:3].example.com — web1, web2, web3

# Variable files:
# host_vars/web1.example.com.yml — variables specific to web1
# group_vars/webservers.yml      — variables for webservers group
# group_vars/all.yml             — variables for all hosts


# =============================================================================
# AD-HOC COMMANDS
# =============================================================================

# ansible HOST_PATTERN -m MODULE -a "ARGUMENTS"
# -i = inventory   -m = module   -a = module arguments   -b = become (sudo)

ansible all -m ping                                     # test connectivity
ansible webservers -m ping                              # test specific group
ansible web1.example.com -m ping                        # test specific host

ansible all -m command -a "uptime"                      # run a command (no shell features)
ansible all -m shell -a "df -h | grep /dev/sda"        # run via shell (supports pipes etc.)
ansible all -m raw -a "uptime"                          # raw SSH — no Python needed on target

ansible all -m copy -a "src=/tmp/file.txt dest=/tmp/"  # copy file to remote hosts
ansible all -m file -a "path=/tmp/test.txt state=absent" # delete a file
ansible all -m dnf -a "name=nginx state=present" -b    # install nginx
ansible all -m dnf -a "name=nginx state=absent" -b     # remove nginx
ansible all -m service -a "name=nginx state=started enabled=yes" -b  # start + enable

ansible all -m setup                                    # gather all facts from hosts
ansible all -m setup -a "filter=ansible_os_family"     # filter specific fact
ansible all -m setup -a "filter=ansible_distribution*" # wildcard fact filter


# =============================================================================
# PLAYBOOK STRUCTURE
# =============================================================================

# A playbook is a YAML file containing one or more plays
# Each play targets hosts and runs tasks in order

cat > site.yml << 'EOF'
---
- name: Configure web servers          # play name — descriptive
  hosts: webservers                    # which hosts to run on
  become: true                         # use sudo for all tasks
  vars:
    http_port: 80
    server_name: myserver

  pre_tasks:
    - name: Ensure system is up to date
      dnf:
        name: "*"
        state: latest

  tasks:
    - name: Install nginx
      dnf:
        name: nginx
        state: present

    - name: Start and enable nginx
      service:
        name: nginx
        state: started
        enabled: yes

    - name: Open firewall for http
      firewalld:
        service: http
        permanent: yes
        state: enabled
        immediate: yes

  post_tasks:
    - name: Verify nginx is responding
      uri:
        url: "http://localhost"
        status_code: 200

- name: Configure database servers     # second play in same playbook
  hosts: dbservers
  become: true
  tasks:
    - name: Install postgresql
      dnf:
        name: postgresql-server
        state: present
EOF

# Run a playbook
ansible-playbook site.yml                               # run the playbook
ansible-playbook site.yml -v                            # verbose output
ansible-playbook site.yml -vv                           # more verbose
ansible-playbook site.yml -vvv                          # connection-level debug
ansible-playbook site.yml --check                       # dry run — no changes made
ansible-playbook site.yml --diff                        # show file diffs
ansible-playbook site.yml --check --diff                # dry run + show diffs
ansible-playbook site.yml --list-tasks                  # list task names, don't run
ansible-playbook site.yml --list-hosts                  # list target hosts, don't run
ansible-playbook site.yml --syntax-check                # validate YAML syntax
ansible-playbook site.yml -l webservers                 # limit to a subset of hosts
ansible-playbook site.yml -l web1.example.com
ansible-playbook site.yml --start-at-task "Install nginx"  # start from a specific task
ansible-playbook site.yml -e "http_port=8080"           # pass extra variable


# =============================================================================
# VARIABLES & FACTS
# =============================================================================

# --- Defining variables ---
# In a play:
#   vars:
#     my_var: "value"
#     port: 8080

# In a vars file:
#   vars_files:
#     - vars/main.yml

# In inventory group_vars/all.yml or host_vars/hostname.yml

# At the command line (highest priority):
#   ansible-playbook site.yml -e "var=value"
#   ansible-playbook site.yml -e "@vars_file.yml"    # load from file

# --- Using variables ---
# {{ my_var }}                 — use in task arguments
# "{{ my_var }}"               — must quote when value starts with {{ }}
# "Port: {{ port }}"           — string interpolation

# --- Variable precedence (lowest to highest) ---
# role defaults < inventory < group_vars < host_vars < play vars < task vars < extra vars (-e)

# --- Register — capture command output as a variable ---
cat >> /dev/null << 'EOF'
    - name: Check if file exists
      command: ls /tmp/myfile
      register: result
      ignore_errors: yes

    - name: Show result
      debug:
        msg: "Command output: {{ result.stdout }}"

    - name: Act on result
      debug:
        msg: "File was found"
      when: result.rc == 0
EOF

# --- Facts — auto-gathered host information ---
# Gathered automatically at play start (can disable with gather_facts: false)
# ansible_facts['distribution']       — e.g. "RedHat"
# ansible_facts['os_family']          — e.g. "RedHat"
# ansible_facts['hostname']
# ansible_facts['default_ipv4']['address']
# ansible_facts['memory_mb']['real']['total']
# ansible_facts['mounts']
# ansible_distribution                — short form (magic variable)

# Access in playbook: {{ ansible_facts['distribution'] }} or {{ ansible_distribution }}

# --- Custom facts ---
# Place .fact files (INI or JSON) in /etc/ansible/facts.d/ on managed hosts
# Access via: {{ ansible_local['factname']['section']['key'] }}

# --- set_fact — define a variable mid-play ---
cat >> /dev/null << 'EOF'
    - name: Set a derived variable
      set_fact:
        full_name: "{{ first_name }} {{ last_name }}"
EOF

# --- Magic variables ---
#   hostvars['web1.example.com']['ansible_hostname']  — access another host's facts
#   groups['webservers']                              — list of hosts in a group
#   group_names                                       — groups the current host belongs to
#   inventory_hostname                                — name of the current host as in inventory
#   ansible_play_hosts                                — all hosts in current play


# =============================================================================
# CONDITIONALS — when
# =============================================================================

cat >> /dev/null << 'EOF'
  tasks:
    # Skip task based on OS family
    - name: Install Apache on RedHat
      dnf:
        name: httpd
        state: present
      when: ansible_facts['os_family'] == "RedHat"

    - name: Install Apache on Debian
      apt:
        name: apache2
        state: present
      when: ansible_facts['os_family'] == "Debian"

    # Multiple conditions — AND (both must be true)
    - name: Configure for RHEL 9
      debug:
        msg: "RHEL 9 detected"
      when:
        - ansible_facts['distribution'] == "RedHat"
        - ansible_facts['distribution_major_version'] == "9"

    # OR condition
    - name: Act on RHEL or CentOS
      debug:
        msg: "Red Hat family"
      when: >
        ansible_facts['distribution'] == "RedHat" or
        ansible_facts['distribution'] == "CentOS"

    # Check registered variable
    - name: Check service status
      command: systemctl is-active nginx
      register: nginx_status
      ignore_errors: yes

    - name: Start nginx if not running
      service:
        name: nginx
        state: started
      when: nginx_status.rc != 0

    # Check if variable is defined
    - name: Use optional variable
      debug:
        msg: "{{ my_var }}"
      when: my_var is defined

    # String tests
    - name: Check environment
      debug:
        msg: "Production!"
      when: env == "prod"
EOF


# =============================================================================
# LOOPS
# =============================================================================

cat >> /dev/null << 'EOF'
  tasks:
    # Simple list loop
    - name: Install multiple packages
      dnf:
        name: "{{ item }}"
        state: present
      loop:
        - nginx
        - git
        - vim

    # Loop over list variable
    - name: Create multiple users
      user:
        name: "{{ item }}"
        state: present
      loop: "{{ user_list }}"        # user_list is defined in vars

    # Loop over list of dicts
    - name: Create users with details
      user:
        name: "{{ item.name }}"
        uid: "{{ item.uid }}"
        state: present
      loop:
        - { name: alice, uid: 1001 }
        - { name: bob,   uid: 1002 }

    # loop_var — rename 'item' to avoid conflicts in nested loops
    - name: Install packages
      dnf:
        name: "{{ pkg }}"
        state: present
      loop: "{{ packages }}"
      loop_control:
        loop_var: pkg
        label: "{{ pkg }}"          # label controls what shows in output

    # with_items — older syntax, still valid
    - name: Create directories
      file:
        path: "{{ item }}"
        state: directory
      with_items:
        - /tmp/dir1
        - /tmp/dir2

    # with_dict — iterate over a dictionary
    - name: Iterate dict
      debug:
        msg: "key={{ item.key }} val={{ item.value }}"
      with_dict:
        key1: val1
        key2: val2
EOF


# =============================================================================
# HANDLERS
# =============================================================================

# Handlers run at the END of a play, only if notified, and only ONCE regardless
# of how many tasks notify them — ideal for service restarts after config changes

cat >> /dev/null << 'EOF'
  tasks:
    - name: Copy nginx config
      copy:
        src: nginx.conf
        dest: /etc/nginx/nginx.conf
      notify: Restart nginx          # trigger handler by name

    - name: Open firewall for HTTP
      firewalld:
        service: http
        state: enabled
        permanent: yes
      notify:
        - Restart nginx              # multiple handlers can be notified
        - Reload firewalld

  handlers:
    - name: Restart nginx
      service:
        name: nginx
        state: restarted

    - name: Reload firewalld
      service:
        name: firewalld
        state: reloaded
EOF

# Force handlers to run immediately (before end of play):
cat >> /dev/null << 'EOF'
    - name: Flush handlers now
      meta: flush_handlers
EOF


# =============================================================================
# ERROR HANDLING
# =============================================================================

cat >> /dev/null << 'EOF'
  tasks:
    # Ignore errors on a specific task
    - name: Try something that might fail
      command: /bin/false
      ignore_errors: yes

    # Treat non-zero RC as success (custom failure condition)
    - name: Check for string in file
      command: grep "pattern" /etc/hosts
      register: result
      failed_when: result.rc > 1    # rc 0 = found, rc 1 = not found (ok), rc 2 = error

    # Define when a task is considered "changed"
    - name: Run script
      command: /opt/myscript.sh
      changed_when: false           # never report as changed (idempotent wrapper)

    # block / rescue / always — try/catch/finally for tasks
    - name: Attempt risky operation
      block:
        - name: Install package
          dnf:
            name: risky-pkg
            state: present

        - name: Start service
          service:
            name: risky-pkg
            state: started

      rescue:
        - name: Handle failure — runs only if block fails
          debug:
            msg: "Something failed in the block, recovering..."

        - name: Remove broken package
          dnf:
            name: risky-pkg
            state: absent

      always:
        - name: Always runs regardless of success or failure
          debug:
            msg: "Block completed"
EOF

# Play-level error control
cat >> /dev/null << 'EOF'
- name: Configure hosts
  hosts: all
  any_errors_fatal: true          # stop play on ALL hosts if any host fails
  max_fail_percentage: 30         # stop if more than 30% of hosts fail
EOF


# =============================================================================
# ROLES
# =============================================================================

# Roles organize playbook content into reusable, self-contained units
# Standard role directory structure:
#
# roles/
#   myrole/
#     tasks/main.yml        — task list (required)
#     handlers/main.yml     — handlers
#     vars/main.yml         — variables (high priority)
#     defaults/main.yml     — default variables (lowest priority — easily overridden)
#     templates/            — Jinja2 .j2 template files
#     files/                — static files to copy
#     meta/main.yml         — role metadata and dependencies
#     README.md

# Create role scaffold
ansible-galaxy role init myrole                        # create directory structure
ansible-galaxy role init roles/myrole                  # create inside roles/ dir

# Use a role in a playbook
cat >> /dev/null << 'EOF'
- name: Configure web servers
  hosts: webservers
  roles:
    - myrole                        # simple usage
    - role: myrole                  # explicit
      vars:
        http_port: 8080             # override role variable

  # include_role — can be used inside tasks (allows conditionals/loops on roles)
  tasks:
    - name: Apply role conditionally
      include_role:
        name: myrole
      when: ansible_os_family == "RedHat"
EOF

# --- meta/main.yml — role metadata and dependencies ---
cat >> /dev/null << 'EOF'
galaxy_info:
  author: myname
  description: Configures nginx
  min_ansible_version: "2.9"
  platforms:
    - name: EL
      versions:
        - "9"

dependencies:
  - role: common                    # common role runs before this role
  - role: firewall
    vars:
      open_ports: [80, 443]
EOF


# =============================================================================
# ANSIBLE GALAXY — ROLES & COLLECTIONS
# =============================================================================

# Download roles from galaxy.ansible.com
ansible-galaxy role install geerlingguy.nginx              # install a role
ansible-galaxy role install geerlingguy.nginx -p ./roles   # install to local roles dir
ansible-galaxy role list                                   # list installed roles
ansible-galaxy role remove geerlingguy.nginx               # remove role

# requirements.yml — declarative way to specify roles/collections to install
cat > requirements.yml << 'EOF'
roles:
  - name: geerlingguy.nginx
    version: "3.2.0"
  - src: https://github.com/user/repo
    name: custom_role

collections:
  - name: ansible.posix
    version: "1.5.4"
  - name: community.general
EOF

ansible-galaxy install -r requirements.yml                 # install all from file
ansible-galaxy install -r requirements.yml -p ./roles      # install roles locally

# Collections
ansible-galaxy collection install ansible.posix            # install a collection
ansible-galaxy collection install community.general
ansible-galaxy collection list                             # list installed collections
ansible-galaxy collection install -r requirements.yml

# Use a collection in a playbook — reference with FQCN (Fully Qualified Collection Name)
cat >> /dev/null << 'EOF'
  tasks:
    - name: Manage SELinux boolean
      ansible.posix.seboolean:
        name: httpd_enable_homedirs
        state: yes
        persistent: yes

    - name: Manage firewall
      ansible.posix.firewalld:
        service: http
        state: enabled
        permanent: yes
EOF


# =============================================================================
# JINJA2 TEMPLATES
# =============================================================================

# Templates are .j2 files — Jinja2 syntax with variables and logic
# Stored in roles/myrole/templates/ or a local templates/ directory

# Example template: templates/nginx.conf.j2
cat > /tmp/nginx.conf.j2 << 'TEMPLATE'
# Managed by Ansible — do not edit manually
server {
    listen {{ http_port }};
    server_name {{ server_name }};

    {% if enable_ssl %}
    listen 443 ssl;
    ssl_certificate {{ ssl_cert_path }};
    {% endif %}

    root /var/www/{{ server_name }};

    {% for vhost in virtual_hosts %}
    location /{{ vhost.path }} {
        proxy_pass http://{{ vhost.backend }};
    }
    {% endfor %}
}
TEMPLATE

# Jinja2 syntax:
#   {{ variable }}              — output variable value
#   {% if condition %}...{% endif %}   — conditional block
#   {% for item in list %}...{% endfor %} — loop
#   {{ my_list | join(', ') }}  — pipe to a filter
#   {{ my_var | default('fallback') }}  — default if undefined
#   {{ name | upper }}          — uppercase
#   {{ name | lower }}          — lowercase
#   {{ value | int }}           — cast to int
#   {{ list | length }}         — get length
#   {# This is a comment #}     — comment (not rendered)

# Deploy a template with the template module
cat >> /dev/null << 'EOF'
    - name: Deploy nginx config from template
      template:
        src: nginx.conf.j2          # relative to templates/ dir or playbook dir
        dest: /etc/nginx/nginx.conf
        owner: root
        group: root
        mode: '0644'
        validate: nginx -t -c %s   # validate config before deploying
      notify: Restart nginx
EOF


# =============================================================================
# ANSIBLE VAULT — ENCRYPTING SENSITIVE DATA
# =============================================================================

# Vault encrypts variables and files so secrets are not stored in plaintext

# --- Encrypt a whole file ---
ansible-vault encrypt secrets.yml                   # encrypt existing file
ansible-vault decrypt secrets.yml                   # decrypt back to plaintext
ansible-vault view secrets.yml                      # view without decrypting on disk
ansible-vault edit secrets.yml                      # edit encrypted file
ansible-vault rekey secrets.yml                     # change vault password

# --- Create a new encrypted file ---
ansible-vault create secrets.yml                    # open editor, encrypt on save

# --- Encrypt a single string value ---
ansible-vault encrypt_string 'mysecretpassword' --name 'db_password'
# Output can be pasted directly into a vars file

# --- Using vaulted files in playbooks ---
cat >> /dev/null << 'EOF'
  vars_files:
    - vars/secrets.yml              # if this is encrypted, vault password required at run time
EOF

# Run playbook with vault password
ansible-playbook site.yml --ask-vault-pass           # prompt for password
ansible-playbook site.yml --vault-password-file vault_pass.txt  # read from file

# Use a vault password file (common on exam):
echo "mypassword" > ~/.vault_pass
chmod 600 ~/.vault_pass
# In ansible.cfg:
#   vault_password_file = ~/.vault_pass

# Multiple vault IDs (different passwords for different secrets)
ansible-vault encrypt secrets.yml --vault-id prod@prompt
ansible-vault encrypt dev_secrets.yml --vault-id dev@dev_pass.txt
ansible-playbook site.yml --vault-id prod@prompt --vault-id dev@dev_pass.txt


# =============================================================================
# COMMON MODULES REFERENCE
# =============================================================================

# Use 'ansible-doc MODULE' during the exam to see full parameter list

# --- File and content management ---
# copy — copy file from controller to managed host
#   src: local file   dest: remote path   owner/group/mode   backup: yes

# fetch — copy file FROM managed host back to controller
#   src: remote file   dest: local dir   flat: yes

# file — manage file/dir/link properties, create, delete
#   path: /tmp/dir   state: [file|directory|link|absent|touch]   mode/owner/group

# template — deploy Jinja2 template
#   src: template.j2   dest: /remote/path   owner/group/mode   validate

# lineinfile — ensure a line exists or doesn't exist in a file
#   path: /etc/hosts   line: "192.168.1.10 web1"   state: present
#   regexp: "^192.168.1.10"   — match existing line to replace

# replace — replace all occurrences of a regex in a file
#   path: /etc/config   regexp: 'old'   replace: 'new'

# blockinfile — insert/update/remove a block of lines
#   path: /etc/hosts   block: |
#     192.168.1.10 web1
#     192.168.1.20 web2

# --- Package management ---
# dnf — manage packages on RHEL/Fedora
#   name: [nginx | "nginx-1.20*" | ["nginx","git"] | "*"]   state: [present|latest|absent]
#   enablerepo: epel   disablerepo: "*"   update_cache: yes

# --- Service management ---
# service — manage services
#   name: nginx   state: [started|stopped|restarted|reloaded]   enabled: [yes|no]

# systemd — manage systemd units (more options than service)
#   name: nginx   state: started   enabled: yes   daemon_reload: yes

# --- User and group management ---
# user — manage user accounts
#   name: alice   uid: 1001   group: devs   groups: [wheel,docker]   append: yes
#   shell: /bin/bash   home: /home/alice   password: "{{ hashed_password }}"
#   state: [present|absent]   remove: yes   system: yes

# group — manage groups
#   name: devs   gid: 2001   state: [present|absent]   system: yes

# --- Storage ---
# parted — partition management
#   device: /dev/sdb   number: 1   state: present
#   part_type: primary   fs_type: xfs   part_start: 1MiB   part_end: 1GiB

# lvg — manage LVM volume groups
#   vg: vg_data   pvs: /dev/sdb1   state: present

# lvol — manage LVM logical volumes
#   vg: vg_data   lv: lv_data   size: 5g   state: present   resizefs: yes

# filesystem — create a filesystem
#   fstype: xfs   dev: /dev/vg_data/lv_data   force: no

# mount — manage mount points (including /etc/fstab)
#   path: /mnt/data   src: /dev/vg_data/lv_data   fstype: xfs
#   opts: defaults   state: [mounted|unmounted|present|absent]
#   state: mounted = mount now AND add to fstab
#   state: present = add to fstab only (don't mount now)

# --- Networking ---
# firewalld — manage firewalld rules
#   service: http   state: enabled   permanent: yes   immediate: yes
#   port: 8080/tcp   zone: public

# --- Scheduling ---
# cron — manage cron jobs
#   name: "backup job"   job: "/opt/backup.sh"
#   minute: "0"   hour: "2"   day: "*"   month: "*"   weekday: "*"
#   user: alice   state: [present|absent]

# --- Security ---
# sefcontext (ansible.posix) — manage SELinux file contexts
#   target: '/web(/.*)?'   setype: httpd_sys_content_t   state: present

# seboolean (ansible.posix) — manage SELinux booleans
#   name: httpd_enable_homedirs   state: yes   persistent: yes

# --- Commands ---
# command — run a command (no shell features, safer)
#   cmd: /usr/bin/mycommand   argv: [arg1, arg2]   creates: /path/if/exists

# shell — run via shell (supports pipes, redirects, variables)
#   cmd: "df -h | grep /dev/sda"   executable: /bin/bash

# script — run a local script on remote hosts
#   cmd: local_script.sh arg1 arg2   creates: /remote/path/if/exists

# raw — send raw SSH command (no Python needed on target)
#   cmd: "yum install -y python3"

# --- Misc ---
# debug — print messages during playbook
#   msg: "Variable value is {{ my_var }}"
#   var: my_var                    — print variable and its value

# uri — interact with HTTP APIs
#   url: https://api.example.com   method: GET   return_content: yes
#   status_code: 200   body_format: json

# archive — create archives
#   path: /var/log   dest: /tmp/logs.tar.gz   format: gz

# unarchive — extract archives
#   src: /tmp/app.tar.gz   dest: /opt/   remote_src: yes  # remote_src: already on target

# get_url — download files
#   url: https://example.com/file.rpm   dest: /tmp/file.rpm   checksum: sha256:abc123

# --- Meta tasks ---
# meta: flush_handlers     — run all notified handlers right now
# meta: end_play           — end play for all hosts
# meta: end_host           — end play for the current host only
# meta: clear_facts        — clear gathered facts from memory


# =============================================================================
# TAGS
# =============================================================================

# Tags allow running only specific tasks from a large playbook

cat >> /dev/null << 'EOF'
  tasks:
    - name: Install nginx
      dnf:
        name: nginx
        state: present
      tags:
        - install
        - nginx

    - name: Configure nginx
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      tags:
        - configure
        - nginx

    - name: Start nginx
      service:
        name: nginx
        state: started
      tags:
        - start
        - nginx
        - always          # 'always' tag ALWAYS runs even with --skip-tags
EOF

# Run specific tags
ansible-playbook site.yml --tags install           # only run install-tagged tasks
ansible-playbook site.yml --tags "install,configure"
ansible-playbook site.yml --skip-tags configure    # skip configure-tagged tasks
ansible-playbook site.yml --list-tags              # list all tags without running


# =============================================================================
# PRIVILEGE ESCALATION
# =============================================================================

# Per-play (overrides ansible.cfg)
cat >> /dev/null << 'EOF'
- name: Run as root
  hosts: all
  become: true
  become_user: root

- name: Run as specific user
  hosts: all
  become: true
  become_user: alice
EOF

# Per-task (overrides play)
cat >> /dev/null << 'EOF'
  tasks:
    - name: Run as root even in non-become play
      command: whoami
      become: true

    - name: Run without privilege escalation
      command: whoami
      become: false
EOF

# Managed host setup — the ansible user needs passwordless sudo:
# /etc/sudoers.d/ansible:
#   ansible ALL=(ALL) NOPASSWD: ALL

# Distribute SSH key to managed hosts:
ssh-keygen -t ed25519 -f ~/.ssh/ansible_key -N ""
ssh-copy-id -i ~/.ssh/ansible_key.pub ansible@web1.example.com


# =============================================================================
# DEBUGGING & TESTING
# =============================================================================

# Syntax and lint
ansible-playbook site.yml --syntax-check           # validate YAML structure
ansible-lint site.yml                              # best practice checks (if installed)

# Dry runs
ansible-playbook site.yml --check                  # simulate without changing anything
ansible-playbook site.yml --check --diff           # show diffs of what would change

# Debug module in playbooks
cat >> /dev/null << 'EOF'
    - name: Print a message
      debug:
        msg: "The value is {{ my_var }}"

    - name: Print variable name and value
      debug:
        var: ansible_facts

    - name: Print at verbosity level 2 only
      debug:
        msg: "Detailed debug info"
        verbosity: 2
EOF

# Verbose levels
ansible-playbook site.yml -v        # task results
ansible-playbook site.yml -vv       # task results + files
ansible-playbook site.yml -vvv      # connection info
ansible-playbook site.yml -vvvv     # connection plugin debug

# Step through playbook task by task
ansible-playbook site.yml --step    # prompt before each task

# Start at a specific task
ansible-playbook site.yml --start-at-task "Configure nginx"

# Test connectivity to all inventory hosts
ansible all -m ping
ansible all -m ping -v              # verbose — shows SSH details on failure


# =============================================================================
# EXAM-DAY QUICK REFERENCE
# =============================================================================

# 1. Always work in a project directory with ./ansible.cfg
# 2. Verify your inventory first:   ansible all --list-hosts
# 3. Test connectivity first:       ansible all -m ping
# 4. Use ansible-doc for module help during the exam:
#        ansible-doc copy
#        ansible-doc -s copy        (short synopsis, faster to read)
# 5. --check --diff before applying changes to verify
# 6. Use --syntax-check before running any playbook
# 7. When roles are required, scaffold with:  ansible-galaxy role init roles/myrole
# 8. For Vault, set vault_password_file in ansible.cfg to avoid typing it every time
# 9. Remember: template files go in templates/, static files in files/, j2 extension required
# 10. module FQCN when using collections:  ansible.posix.firewalld, ansible.posix.seboolean
