# GCP Enterprise Security Lab & DFIR Pipeline

Projekt symulujący środowisko Enterprise w modelu Infrastructure as Code (Terraform), z wydzieloną warstwą telemetrii SOC w BigQuery (Decoupled State) oraz zaporą w konfiguracji Egress DENY ALL.

## Architektura Sieciowa

![Schemat Architektury](Topologia.png)

### Bezpieczeństwo i Wzorzec "Mostu Zwodzonego" (The Drawbridge Pattern)

Ze względu na restrykcyjną politykę Google Cloud AUP (Acceptable Use Policy), wdrożono architekturę w 100% bezpiecznego Honeypota. 

Aby zapobiec wykorzystaniu środowiska przez botnety do ataków wychodzących (DDoS, C2, spam), zastosowano stanowy firewall Egress z regułą DENY ALL. 

**Proces Wdrożenia (Provisioning Window):**
Z uwagi na blokadę ruchu wychodzącego, instalacja aplikacji podatnej (DVWA) via skrypt startowy wymaga tymczasowego otwarcia mostu zwodzonego:
1. Wdrażamy architekturę z regułą `allow_egress_updates` (Porty 80/443).
2. Oczekujemy 2 minuty na pobranie obrazów Docker przez maszynę Bastion.
3. Usuwamy regułę Egress i ponownie wykonujemy `terraform apply`.
4. Most zostaje zatrzaśnięty. Złośliwy ruch z wewnątrz kontenera uderza w zaporę i jest niszczony, ale logi z prób ataku pozostają rejestrowane dla celów analitycznych SOC.

*Szczegóły wdrożenia oraz pełny raport z incydentu (SANS/NIST) zostaną udostępnione wkrótce.*
