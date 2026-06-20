# Incident Response Report: DMZ Compromise & Lateral Movement

**Document Version:** 1.0
**Date of Report:** 2026-06-20
**Incident Commander:** Antoni Wnęk/ Blue Team Lead
**Status:** Closed

---

## 1. Executive Summary

The deployed cloud environment was subjected to a targeted cyber attack. A threat actor exploited a critical vulnerability in a web application (DVWA) exposed in the DMZ to gain initial access to the edge server (Bastion) by uploading a malicious payload (Web Shell). 

From the compromised Bastion, the attacker conducted reconnaissance of the internal network, discovering and utilizing an unsecured SSH cryptographic key. This enabled lateral movement and successful authentication to the isolated internal server. The incident culminated in the unauthorized read of a highly sensitive file (`hasla.txt`). The attack was effectively contained through immediate network isolation protocols.

---

## 2. Incident Timeline

*Note: All timestamps are recorded in UTC, correlated from Google Cloud VPC Flow Logs and the auditd daemon.*

| Time (UTC) | Attack Phase | Event Description |
| :--- | :--- | :--- |
| `2026-06-19 14:11:56` | Initial Access | Deployment of `webshell.php` payload on the Bastion host. |
| `2026-06-19 14:13:44` | Local Reconnaissance | Execution of the `whoami` command to enumerate system privileges on the Bastion host. |
| `2026-06-19 14:15:25` | Network Reconnaissance | Initial network probing against port 22 on the internal subnet (`10.0.2.0/24`). |
| `2026-06-19 14:15:52` | Credential Access | Discovery and reading of the `id_ed25519` private key stored within the web directory. |
| `2026-06-19 14:17:12` | Lateral Movement | Successful SSH authentication from Bastion to the target server after identifying the `admin` account, followed by a significant data transfer spike. |
| `2026-06-19 15:26:07` | Data Exfiltration | Unauthorized access and reading of the `/home/admin/backup/hasla.txt` honeytoken file. |

*Analytical Note: A significant time gap was identified between the successful lateral movement and the final action on objectives. This indicates the threat actor secured the session, conducted stealthy internal enumeration, and returned to exfiltrate the target file at a later stage.*

---

## 3. Technical Findings & IoCs 

During the Threat Hunting phase, telemetry data within BigQuery was analyzed. The following Indicators of Compromise (IoCs) were identified:

### Network IoCs
* **Attacker IP:** `[REDACTED_EXTERNAL_IP]`
* **Pivoting Node (Compromised Bastion):** `10.0.1.2`
* **Target Host:** `10.0.2.2`

### Host Artifacts
* **Web Shell Path:** `/var/www/html/hackable/uploads/webshell.php`
* **Stolen SSH Key Path:** `/var/www/html/hackable/uploads/.ssh/id_ed25519`

### Evidentiary Artifacts
Below are the key SIEM screenshots (Google Cloud Logging / BigQuery) documenting the progression of the kill chain:

**1. Initial Access (Web Shell Deployment)**

<img width="404" height="516" alt="image" src="https://github.com/user-attachments/assets/9d61914a-e189-44d2-9d84-d9ecac4ef2a9" />


**2. Reconnaissance (Situational Awareness)**

<img width="662" height="537" alt="image" src="https://github.com/user-attachments/assets/f9c53334-1933-4087-9cac-e018783076ac" />
<img width="664" height="512" alt="image" src="https://github.com/user-attachments/assets/e9e99594-4b90-4796-94be-75bacd5f036a" />


**3. Credential Access (SSH Key Hijacking)**

<img width="663" height="268" alt="image" src="https://github.com/user-attachments/assets/42031eb6-17b5-4e4c-aaea-7188499591d5" />


**4. Lateral Movement (VPC Flow Logs - Port 22)**

<img width="929" height="266" alt="image" src="https://github.com/user-attachments/assets/676776de-a108-4f1b-899b-fee2432c3b4d" />


**5. Action on Objectives (Data Exfiltration - hasla.txt)**

<img width="662" height="125" alt="image" src="https://github.com/user-attachments/assets/4c4c0f02-9cd6-431f-b986-44dada819b83" />


---

## 4. Containment, Eradication & Recovery

The following incident response procedures were executed to halt the attack and secure the perimeter:
1. **Network Containment:** Egress network traffic from the DMZ to the internet was immediately blocked, severing the compromised server's connection to external Command & Control (C2) infrastructure.
2. **Credential Revocation:** The compromised `id_ed25519` key was classified as burned. It was permanently removed from the `authorized_keys` file on the internal server, eliminating the attacker's persistence mechanism.
3. **Evidence Preservation:** Immutable audit logs were secured within the BigQuery data warehouse to facilitate further forensic analysis.

---

## 5. Lessons Learned & Recommendations

To mitigate similar attack vectors in the future, the immediate implementation of the following architectural remediations is highly recommended:

* **Secrets Management:** A strict policy prohibiting the storage of plaintext cryptographic keys on application servers must be enforced. It is recommended to deploy **Google Cloud Secret Manager** or utilize **OS Login** mechanisms.
* **Application Security (AppSec):** The web application requires an urgent code audit focusing on Unrestricted File Upload vulnerabilities. Deploying a Web Application Firewall (WAF) via **Google Cloud Armor** is necessary to automatically block malicious scripts (e.g., PHP payloads).
* **Zero-Trust Network Segmentation:** Internal firewall ingress rules were found to be overly permissive. The Bastion host possessed unrestricted access to port 22 across the entire `10.0.2.0/24` subnet. Ingress rules for the internal zone must be restricted exclusively to essential, specific target IP addresses (micro-segmentation).
