[🇵🇱 Wersja Polska](#wersja-polska) | [🇬🇧 English Version](#english-version)

---

<a id="wersja-polska"></a>
# Wersja Polska: GCP Enterprise Security Lab & DFIR Pipeline

**TL;DR:** Infrastruktura jako kod (IaC) wdrażająca w Google Cloud środowisko typu Zero-Trust do symulacji ataków i analizy śledczej. Projekt demonstruje pełen łańcuch ataku (Web Shell, SSH Key Hijacking, Lateral Movement) oraz automatyzuje routing logów (Auditd, VPC Flow) do bazy BigQuery w celu poszukiwania zagrożeń (Threat Hunting).

Zautomatyzowane laboratorium przeznaczone do testowania scenariuszy bezpieczeństwa ofensywnego (Red Team) i prowadzenia analizy śledczej (Blue Team/DFIR). Projekt wykorzystuje narzędzie Terraform do budowy odizolowanej infrastruktury, umożliwiając przeprowadzenie symulowanego ataku oraz eksport pełnej telemetrii z systemów operacyjnych i warstwy sieciowej do analizy.

## Technologie
* Infrastruktura: Terraform, Google Cloud Platform (GCP)
* Bezpieczeństwo i telemetria: Auditd, VPC Flow Logs, BigQuery, IAM, IAP (Identity-Aware Proxy)
* Konfiguracja sieci: Custom VPC, Firewall Tags, Zero-Trust Bridge
* Aplikacje: Docker, Damn Vulnerable Web Application (DVWA), środowisko Bash

## Architektura sieciowa

![Architektura Sieciowa](./Topologia.png)

## Konfiguracja ruchu wychodzącego (Drawbridge Pattern)

Z uwagi na restrykcyjną politykę Google Cloud AUP oraz zasady minimalnego uprzywilejowania, wdrożono architekturę całkowicie blokującą ruch wychodzący (Egress DENY ALL). Zapobiega to wykorzystaniu środowiska przez botnety, np. do ataków DDoS czy komunikacji z serwerami C2.

Proces wdrożenia wymaga tymczasowego otwarcia zapory (tzw. mostu zwodzonego) w celu pobrania obrazów aplikacji podatnej:

1. Wdrożenie infrastruktury z tymczasową regułą zezwalającą na pobranie pakietów HTTP/HTTPS. [Kod źródłowy reguły](./terraform/02-security-lab/drawbridge_firewall.tf.example)
2. Inicjalizacja kontenerów Docker na maszynie brzegowej (Bastion).
3. Usunięcie reguły Egress z konfiguracji Terraform i ponowna aplikacja stanu (`terraform apply`).
4. Pełna izolacja środowiska. Złośliwy ruch wychodzący jest blokowany przez zaporę, jednak próby połączeń są logowane i przesyłane do analizy.

## Scenariusz ataku (Red Team)

Środowisko umożliwia przeprowadzenie pełnego łańcucha ataku (Cyber Kill Chain):

1. Initial Access: Wykorzystanie podatności w DVWA do wgrania skryptu typu Web Shell.
2. Reconnaissance: Mapowanie podsieci wewnętrznej z poziomu przejętego Bastionu.
3. Credential Harvesting: Zlokalizowanie niezabezpieczonego klucza prywatnego ED25519 oraz enumeracja kont systemowych.
4. Lateral Movement: Wykorzystanie ataku typu Username Spraying przy użyciu przejętego klucza i utworzenie sesji SSH z odizolowaną maszyną wewnętrzną z pominięciem obostrzeń systemowych klienta.
5. Data Exfiltration: Nieautoryzowany odczyt wrażliwych danych, generujący zdarzenia w demonie audytowym.

## Scenariusz analizy śledczej (Blue Team / DFIR)

Po wykonaniu ataku, laboratorium umożliwia realizację zadań defensywnych:

1. Log Routing: Automatyczny przesył zdarzeń systemowych i sieciowych do wyizolowanego zbioru danych w BigQuery.
2. Threat Hunting: Wykorzystanie zapytań SQL do filtrowania logów, odseparowania ruchu tła i identyfikacji anomalii sieciowych.
3. Incident Response: Wyodrębnienie wskaźników kompromitacji (IoC) i przygotowanie dokumentacji powłamaniowej.

## Instrukcja wdrożenia

Projekt został podzielony na dwie niezależne warstwy: trwałą (infrastruktura danych) oraz ulotną (właściwe środowisko testowe). Wymagane jest posiadanie uprawnień Owner/Editor w projekcie GCP.

```bash
# 1. Klonowanie repozytorium
git clone https://github.com/[TWÓJ_GITHUB]/[NAZWA_REPO].git
cd [NAZWA_REPO]/terraform

# 2. Wdrożenie warstwy trwałej (BigQuery)
cd 01-data-foundation
terraform init
terraform apply -auto-approve

# 3. Wdrożenie warstwy ulotnej (Środowisko testowe z otwartym ruchem wychodzącym)
cd ../02-security-lab
terraform init -upgrade
terraform apply -auto-approve

# 4. Po inicjalizacji środowiska (ok. 2-3 minuty), usuń blok mostu zwodzonego z pliku firewall.tf.

# 5. Zamknięcie zapory sieciowej
terraform apply -auto-approve
```

## Dokumentacja z incydentu

Pełny raport powłamaniowy (Post-Mortem), zawierający szczegółową analizę logów, oś czasu zdarzeń (Timeline) oraz zidentyfikowane wskaźniki kompromitacji (IoC), znajduje się w katalogu z raportami:
[Incident_Response_Report.md](./reports/Incident_Response_Report.md)

*Zrzuty surowych logów oraz robocze zapytania SQL wykorzystane podczas analizy dostępne są w katalogu `/docs`.*

**Zastrzeżenie:** Repozytorium zawiera kod wdrażający celowo podatne oprogramowanie oraz osłabione mechanizmy bezpieczeństwa. Służy ono wyłącznie celom badawczym i edukacyjnym w izolowanych środowiskach. Nie należy wdrażać tego kodu w środowiskach produkcyjnych.

---
---

<a id="english-version"></a>
# English Version: GCP Enterprise Security Lab & DFIR Pipeline

**TL;DR:** Infrastructure as Code (IaC) deploying a Zero-Trust environment in Google Cloud for attack simulation and digital forensics. The project demonstrates a full kill chain (Web Shell, SSH Key Hijacking, Lateral Movement) and automates log routing (Auditd, VPC Flow) to BigQuery for Threat Hunting.

An automated laboratory designed for testing offensive security scenarios (Red Team) and conducting digital forensics and incident response (Blue Team/DFIR). The project uses Terraform to provision an isolated network architecture, facilitating the execution of a simulated attack and exporting comprehensive telemetry from operating systems and network layers for analysis.

## Technologies
* Infrastructure: Terraform, Google Cloud Platform (GCP)
* Security & Telemetry: Auditd, VPC Flow Logs, BigQuery, IAM, Identity-Aware Proxy (IAP)
* Network Configuration: Custom VPC, Firewall Tags, Zero-Trust Bridge
* Applications: Docker, Damn Vulnerable Web Application (DVWA), Bash scripting

## Network Architecture

![Network Architecture](./Topologia.png)

## Outbound Traffic Configuration (Drawbridge Pattern)

To comply with Google Cloud's Acceptable Use Policy (AUP) and enforce the principle of least privilege, the environment implements a strict Egress DENY ALL firewall configuration. This prevents the lab from being utilized by botnets for outbound attacks or C2 communication.

The provisioning process requires temporarily opening the firewall (the "drawbridge") to pull necessary application images:

1. Deploy infrastructure with a temporary rule allowing outbound HTTP/HTTPS traffic. [View rule source code](./terraform/02-security-lab/drawbridge_firewall.tf.example)
2. Wait for Docker containers to initialize on the Bastion host.
3. Remove the Egress rule from the Terraform configuration and reapply the state (`terraform apply`).
4. Full isolation is achieved. Malicious outbound traffic is blocked by the firewall, while connection attempts are logged and routed for analysis.

## Attack Scenario (Red Team)

The environment allows for the execution of a complete Cyber Kill Chain:

1. Initial Access: Exploiting vulnerabilities in DVWA to deploy a Web Shell.
2. Reconnaissance: Mapping the internal subnet from the compromised Bastion.
3. Credential Harvesting: Locating an unsecured ED25519 private key and enumerating system accounts.
4. Lateral Movement: Executing a Username Spraying attack with the stolen key to establish a quiet SSH session with the isolated internal machine, bypassing local SSH client restrictions.
5. Data Exfiltration: Unauthorized reading of sensitive data (honeytoken), triggering system audit alerts.

## Forensics and Defense Scenario (Blue Team / DFIR)

Following the attack execution, the lab facilitates defensive operations:

1. Log Routing: Automated streaming of system and network events to an isolated BigQuery dataset.
2. Threat Hunting: Utilizing SQL queries to filter logs, separate background noise, and identify network anomalies.
3. Incident Response: Extracting Indicators of Compromise (IoCs) and compiling an incident report.

## Deployment Guide

The project is structured into two independent layers: a persistent data foundation and an ephemeral testing environment. Owner/Editor permissions in a GCP project are required.

```bash
# 1. Clone the repository
git clone https://github.com/[YOUR_GITHUB]/[REPO_NAME].git
cd [REPO_NAME]/terraform

# 2. Deploy the data foundation (BigQuery)
cd 01-data-foundation
terraform init
terraform apply -auto-approve

# 3. Deploy the ephemeral lab (with the drawbridge open)
cd ../02-security-lab
terraform init -upgrade
terraform apply -auto-approve

# 4. Wait 2-3 minutes for initialization, then remove the drawbridge block from firewall.tf.

# 5. Close the firewall (Secure the perimeter)
terraform apply -auto-approve
```

## Incident Documentation

The comprehensive Post-Mortem incident report, containing detailed log analysis, an attack timeline, and identified IoCs, can be found in the reports directory:
[Incident_Response_Report.md](./reports/Incident_Response_Report.md)

*Raw log dumps and working SQL queries used during the analysis are stored in the `/docs` directory.*

**Disclaimer:** This repository contains code that intentionally deploys vulnerable software and weakened security configurations. It is intended strictly for educational and research purposes in isolated environments. Do not deploy this code in production networks.
