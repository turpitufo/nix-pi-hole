# SKB Project - S33843

**GitHub Repository**: [https://github.com/poaeo/skb-project](https://github.com/poaeo/skb-project)

**Created**: June 8, 2026  
**Author**: S33843

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [DNS Configuration](#dns-configuration)
3. [Pi-hole Setup](#pi-hole-setup)
4. [NixOS Configuration](#nixos-configuration)
5. [Network Configuration](#network-configuration)
6. [Testing and Verification](#testing-and-verification)
7. [Services](#services)
8. [Additional Configuration Details](#additional-configuration-details)
9. [Summary](#summary)
10. [References](#references)

---

## Project Overview

This project demonstrates the setup and configuration of Pi-hole as a DNS ad-blocker on a NixOS system. It includes comprehensive DNS query handling, upstream DNS configuration, and integration with system services.

![Project Overview Diagram](./1.png)

The Pi-hole DNS ad-blocker intercepts DNS queries from client devices, checks them against blocklists, and either returns 0.0.0.0 for blocked domains or forwards allowed queries to upstream DNS providers.

---

## DNS Configuration

### DNS Query Flow

The following table demonstrates how DNS queries are processed through Pi-hole:

| Client Device | DNS Query | Pi-hole :53 | Blocklist match? | Action | Upstream DNS |
|--------------|-----------|-------------|------------------|--------|---------------|
| Any | doubleclick.net | Yes | YES | return 0.0.0.0 | (blocked) |
| Any | google.com | Yes | NO | return real IP | 9.9.9.9 / 1.1.1.1 |

![DNS Query Flow Diagram](./2.png)

### DNS Query Examples

#### Query: doubleclick.net (Blocked)

```
; <<>> DiG 9.20.22 <<>> @192.168.0.171 doubleclick.net
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 36218
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
;; QUESTION SECTION:
;doubleclick.net.            IN  A

;; ANSWER SECTION:
doubleclick.net.     2   IN  A   0.0.0.0

;; Query time: 403 msec
;; SERVER: 192.168.0.171#53(192.168.0.171) (UDP)
;; WHEN: Mon Jun 08 08:10:44 CEST 2026
;; MSG SIZE  rcvd: 60
```

**Result**: Blocked - Returns 0.0.0.0 (blocked by Pi-hole)

#### Query: google.com (Allowed)

```
; <<>> DiG 9.20.22 <<>> @192.168.0.171 google.com
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 31485
;; flags: qr rd ra; QUERY: 1, ANSWER: 6, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
;; QUESTION SECTION:
;google.com.             IN  A

;; ANSWER SECTION:
google.com.          153 IN  A   142.251.98.100
google.com.          153 IN  A   142.251.98.113
google.com.          153 IN  A   142.251.98.138
google.com.          153 IN  A   142.251.98.139
google.com.          153 IN  A   142.251.98.101
google.com.          153 IN  A   142.251.98.102

;; Query time: 412 msec
;; SERVER: 192.168.0.171#53(192.168.0.171) (UDP)
;; WHEN: Mon Jun 08 08:10:52 CEST 2026
;; MSG SIZE  rcvd: 1356
```

**Result**: Allowed - Returns real IP addresses from upstream DNS (9.9.9.9 / 1.1.1.1)

![DNS Resolution Flow Diagram](./3.png)

---

## Pi-hole Setup

### Configuration File: configuration.nix

The main Pi-hole configuration in NixOS:

```nix
services.pihole-ftl = {
  enable = true;
  settings = {
    dns.upstreams = [ "9.9.9.9" "1.1.1.1" ];
    misc.readOnly = true;
  };
};
```

### Installation

The Pi-hole FTL service is installed at:
```
/nix/store/<hash>/bin/pihole-FTL
```

![Pi-hole Configuration Screenshot](./4.png)

---

## NixOS Configuration

### System Configuration

**File**: `/etc/nixos/configuration.nix`

```nix
{ config, pkgs, ... }:

{
  # Pi-hole Configuration
  services.pihole-ftl = {
    enable = true;
    settings = {
      dns.upstreams = [ "9.9.9.9" "1.1.1.1" ];
      misc.readOnly = true;
    };
  };

  # Network Configuration
  networking.nameservers = [ ... ];
  networking.networkmanager.insertNameservers = true;

  # Systemd-resolved
  services.systemd-resolved = {
    enable = true;
    dnsStubListener = false;
  };

  # Required for DNS
  hardware.enableRedistributableFirmware = true;
}
```

### NixOS Installation

Standard NixOS installation with Pi-hole:

```bash
# Install with Pi-hole configuration
nixos-install
```

![NixOS Installation Screenshot](./5.png)

---

## Network Configuration

### DNS Servers

**Upstream DNS:**
- Primary: 9.9.9.9 (Quad9)
- Secondary: 1.1.1.1 (Cloudflare)

**Local DNS:**
- Pi-hole: 192.168.0.171:53
- Local network: 192.168.122.1:53 (dnsmasq)
- Additional server: 192.168.0.50:250

### Service: dnsmasq

Running on: `192.168.122.1:53`

**Configuration:**
```
DNSStubListener=no
```

### Service: libvirt

Libvirt is configured with its own DNS management:

```bash
# Manage libvirt network
sudo virsh net-destroy default
sudo virsh net-autostart default
```

### Network Diagram

```
[Client Device]
       |
       v
[Pi-hole :53]
       |
       v
[Blocklist Check]
       |-- YES --> return 0.0.0.0 (Blocked)
       |-- NO  --> [Upstream DNS] --> return real IP
       |                                 (9.9.9.9 / 1.1.1.1)
```

![Network Topology Diagram](./6.png)

---

## Testing and Verification

### Commands for Testing

```bash
# Test DNS resolution through Pi-hole
dig @192.168.0.171 doubleclick.net
dig @192.168.0.171 google.com

# Test DNS resolution through upstream
dig @9.9.9.9 google.com
dig @1.1.1.1 google.com

# Check DNS configuration
cat /etc/resolv.conf
```

### Expected Results

| Domain | Expected Result | Status |
|--------|----------------|--------|
| doubleclick.net | 0.0.0.0 (Blocked) | Blocked by Pi-hole |
| google.com | Real IP addresses | Allowed |

### Dig Output Analysis

The `dig` command outputs show:
- **Blocked domains**: Return `0.0.0.0` with NOERROR status
- **Allowed domains**: Return real IP addresses from upstream DNS
- **Response time**: Typically 400-450 msec
- **Server**: 192.168.0.171#53 (Pi-hole)

![Dig Command Output Screenshot](./7.png)

![Blocked Domain Example Screenshot](./8.png)

![Allowed Domain Example Screenshot](./9.png)

---

## Services

### Service List

1. **pihole-FTL**
   - DNS ad-blocking service
   - Configuration: `configuration.nix`
   - Port: 53 (DNS)
   - Binary: `/nix/store/<hash>/bin/pihole-FTL`

2. **systemd-resolved**
   - System DNS resolver
   - DNSStubListener: Disabled

3. **dnsmasq**
   - Lightweight DNS forwarder
   - Running on: 192.168.122.1:53
   - Managed by: libvirt

4. **libvirt**
   - Virtualization management
   - Network: default
   - DNS: dnsmasq

![Pi-hole Dashboard Screenshot](./10.png)

![Configuration File Contents Screenshot](./11.png)

---

## Additional Configuration Details

### Security Features

The configuration includes BALLOON-SHA256 for enhanced security:

```
# Security hash algorithm for password storage
BALLOON-SHA256
```

This provides secure password hashing for the Pi-hole web interface.

### Complete Service Configuration

```nix
services.pihole-ftl = {
  enable = true;
  settings = {
    dns.upstreams = [ "9.9.9.9" "1.1.1.1" ];
    misc.readOnly = true;
    webserver.api.password = "...";
    webserver.api.pwhash = "...";
  };
};
```

### DNS Stub Listener Configuration

```nix
services.systemd-resolved = {
  enable = true;
  dnsStubListener = false;  # Disable to avoid conflicts with Pi-hole
};
```

![Service Status Screenshot](./12.png)

![DNS Settings Screenshot](./13.png)

![Network Configuration Screenshot](./14.png)

![Command Line Examples Screenshot](./15.png)

![System Services Overview Screenshot](./16.png)

---

## Summary

This project successfully demonstrates:

1. Pi-hole DNS ad-blocking configuration on NixOS
2. Custom upstream DNS servers (Quad9 and Cloudflare)
3. Proper DNS query handling (blocking ads, allowing legitimate traffic)
4. Integration with system services (libvirt, dnsmasq, systemd-resolved)
5. Verification through `dig` commands
6. Secure password hashing with BALLOON-SHA256
7. Comprehensive documentation with screenshots

The configuration provides a robust DNS ad-blocking solution with privacy-focused upstream DNS providers and proper system integration.

---

## References

- [Pi-hole Documentation](https://docs.pi-hole.net/)
- [NixOS Manual](https://nixos.org/manual/)
- [Quad9 DNS](https://www.quad9.net/)
- [Cloudflare DNS](https://1.1.1.1/)

---

**Document Source**: Recreated from `SKB_Project_S33843.pdf`  
**GitHub Repository**: [https://github.com/poaeo/skb-project](https://github.com/poaeo/skb-project)  
**Recreation Date**: July 25, 2026  
**Original Format**: Markdown to PDF (via Chromium)  
**Recreated By**: Mistral Vibe CLI  
**Images**: 17 PNG files (1-16, 70) extracted from PDF

![Additional Network Diagram](./70.png)
