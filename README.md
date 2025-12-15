# Tailscale Private DERP Server

A private Tailscale DERP (Designated Encrypted Relay for Packets) server setup for self-hosted mesh networking with client verification.

## Overview

DERP servers are used by Tailscale to relay encrypted packets between nodes when a direct connection is not possible. This repository contains everything needed to set up a private DERP server with:

- Self-signed SSL certificates
- Client verification enabled
- Systemd service management
- STUN (Session Traversal Utilities for NAT) support

## Project Structure

```
.
├── init.sh                      # Initialization and installation script
├── tailscale-derp.service       # Systemd service file
├── derper-init/
│   └── 00_makecert.sh          # Certificate generation script
├── certdir/                     # Directory for SSL certificates (created during setup)
├── LICENSE                      # License file
└── README.md                    # This file
```

## Prerequisites

- Linux system (tested on ARM64, also supports x86_64)
- Root or sudo access
- Git
- wget
- OpenSSL
- systemd

## Installation

### 1. Clone and Setup

```bash
git clone https://github.com/jryaonj/tailscale-private-derper.git
cd tailscale-private-derper
```

### 2. Generate SSL Certificates

```bash
bash derper-init/00_makecert.sh
```

This script will:
- Create a `~/certdir` directory
- Generate a private key and certificate signing request (CSR)
- Create a self-signed certificate valid for 100 years
- Add a subject alternative name (SAN) for `priv-derp`

**Note:** The certificate is self-signed. Clients connecting to this DERP server should be configured to accept these certificates.

### 3. Install Dependencies and Build DERP Server

```bash
bash init.sh
```

This script will:
- Download and install Go 1.21.3 (ARM64)
- Install the `derper` binary from Tailscale
- Optionally install Tailscale client tools
- Set up necessary environment variables

### 4. Install as Systemd Service

```bash
sudo cp tailscale-derp.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable tailscale-derp.service
sudo systemctl start tailscale-derp.service
```

### 5. Verify the Service

```bash
sudo systemctl status tailscale-derp.service
```

## Configuration

### DERP Server Parameters

The `tailscale-derp.service` file contains the following configuration:

| Parameter | Value | Description |
|-----------|-------|-------------|
| `hostname` | `priv-derp` | Server hostname for certificate validation |
| `-a` | `:8888` | DERP protocol listening port |
| `-stun-port` | `8889` | STUN protocol listening port |
| `-certdir` | `/root/certdir` | Directory containing SSL certificates |
| `--verify-clients` | - | Enable client verification (Tailscale auth required) |
| `--certmode` | `manual` | Use manually provided certificates |

### Modifying Configuration

To change ports, hostname, or other settings:

1. Edit `/etc/systemd/system/tailscale-derp.service`
2. Run `sudo systemctl daemon-reload`
3. Restart the service: `sudo systemctl restart tailscale-derp.service`

## Client Configuration

To connect clients to this private DERP server:

1. Configure your Tailscale nodes to use the private DERP server
2. Ensure clients trust the self-signed certificate or configure certificate pinning
3. The `--verify-clients` flag requires authenticated Tailscale users

Example ACL configuration (for Tailscale control server):
```
{
  "DERPs": {
    "999": {
      "Name": "private-derp",
      "RegionID": 999,
      "Nodes": [
        {
          "Name": "priv-derp-1",
          "RegionID": 999,
          "HostName": "priv-derp",
          "IPv4": "YOUR_SERVER_IP",
          "IPv6": "YOUR_SERVER_IPV6",
          "STUNPort": 8889,
          "DERPPort": 8888
        }
      ]
    }
  }
}
```

## Troubleshooting

### Service fails to start

```bash
sudo journalctl -u tailscale-derp.service -n 50
```

### Certificate issues

Ensure certificates exist in `/root/certdir`:
```bash
ls -la /root/certdir/
# Should contain: priv-derp.crt, priv-derp.key, priv-derp.csr
```

### Port conflicts

Check if ports 8888 or 8889 are already in use:
```bash
sudo netstat -tlnp | grep -E '8888|8889'
```

### Network connectivity

Test DERP server connectivity:
```bash
curl -k https://priv-derp:8888/
# Should return an empty response or connection details
```

Test STUN server:
```bash
stunclient priv-derp 8889
```

## Port Forwarding

If your server is behind a NAT/firewall, ensure the following ports are forwarded:

- **TCP 8888**: DERP protocol (primary)
- **UDP 8889**: STUN protocol (NAT traversal)

## Logs

View service logs:
```bash
sudo journalctl -u tailscale-derp.service -f
```

View filtered logs:
```bash
sudo journalctl -u tailscale-derp.service --since "1 hour ago"
```

## Security Considerations

- **Certificate Verification**: The self-signed certificate should be verified out-of-band or pinned in client configurations
- **Client Verification**: The `--verify-clients` flag ensures only authenticated Tailscale users can connect
- **Firewall**: Consider restricting access to known Tailscale networks
- **Monitoring**: Regular log monitoring is recommended for security and performance

## References

- [Tailscale DERP Documentation](https://tailscale.com/blog/how-tailscale-works/)
- [Running a Private DERP Server](https://tailscale.com/kb/1118/custom-derp-servers/)
- [Tailscale GitHub Repository](https://github.com/tailscale/tailscale)

## License

See [LICENSE](LICENSE) file for licensing information.

## Support

For issues or questions:
1. Check the Troubleshooting section above
2. Review systemd service logs
3. Consult Tailscale official documentation
4. Open an issue in the GitHub repository

---

**Last Updated**: December 2025
