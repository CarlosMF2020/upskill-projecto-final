# ldap

Installs and configures OpenLDAP (`slapd`) on the `infra` node for the TechNova domain. Manages the directory structure, schema loading, TLS with a CA-signed certificate, bootstrap users, ACLs, and LDAP Account Manager (LAM) as the web interface.

## Requirements

- Ubuntu 24.04
- Ansible 2.14+
- `python3-ldap` (installed by the role)

## Role Variables

| Variable | Default | Description |
|---|---|---|
| `ldap_domain` | `technova.local` | LDAP domain |
| `ldap_base_dn` | `dc=technova,dc=local` | Base DN |
| `ldap_organization` | `TechNova` | Organisation name |
| `ldap_server_ip` | `192.168.10.10` | LDAP server IP |
| `ldap_server_fqdn` | `ldap.technova.local` | LDAP server FQDN (used in certificate SAN) |
| `ldap_bootstrap_users` | `true` | Whether to create sysadmin and operator users |
| `ldap_tls_enabled` | `true` | Enable TLS with CA-signed certificate |
| `ldap_ca_dir` | `/etc/ssl/technova-ca` | Directory for CA key and certificate |
| `ldap_certs_dir` | `/etc/ldap/certs` | Directory for server certificate and key |
| `ldap_ca_days` | `3650` | CA certificate validity (days) |
| `ldap_cert_days` | `825` | Server certificate validity (days) |

### Sensitive Variables

| Variable | Description |
|---|---|
| `ldap_admin_password` | `cn=admin` rootDN password (used by Ansible and Samba) |
| `ldap_sysadmin_password` | Password for `uid=sysadmin` |
| `ldap_operator_password` | Password for `uid=operator` |

## Dependencies

None.

## TLS Architecture

```
Internal CA (self-signed, 10 years)
    └── ldap.crt (CA-signed, 825 days)
            SAN: DNS=ldap.technova.local, IP=192.168.10.10
```

- The CA certificate is added to the system trust store via `update-ca-certificates`
- The certificate supports access via IP (`192.168.10.10`) and FQDN (`ldap.technova.local`)
- Samba connects to LDAP over StartTLS and validates the certificate using this CA

## Windows Host — Trusting the CA Certificate

The CA certificate is generated on the `infra` VM and is not distributed through the repository (listed in `.gitignore`). For the browser on the Windows host to trust the LDAP web interface without a security warning, the CA certificate must be imported into the Windows trust store once.

**1. Copy the CA certificate from the VM to the Windows host** (run from the project root):

```bash
vagrant scp infra:/etc/ssl/technova-ca/ca.crt ./ca.crt
```

**2. Import into the Windows trusted root store** (PowerShell as Administrator):

```powershell
Import-Certificate -FilePath ".\ca.crt" -CertStoreLocation Cert:\LocalMachine\Root
```

After this, the browser will trust `https://192.168.10.10` without warnings. This step is required once per machine.

---

### macOS

**1. Copy the CA certificate from the VM** (run from the project root):

```bash
vagrant scp infra:/etc/ssl/technova-ca/ca.crt ./ca.crt
```

**2. Add to the system keychain as a trusted root:**

```bash
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain ./ca.crt
```

After this, restart the browser. This step is required once per machine.

> The `vagrant-scp` plugin must be installed: `vagrant plugin install vagrant-scp`

## Access Control

- `uid=sysadmin` has write access to the directory tree via ACL
- LAM login is restricted to `sysadmin` only via `loginSearchFilter`
- `uid=operator` exists in the directory but cannot log into LAM

## Web Interface

LAM is served over HTTPS via Nginx on port 443.

- URL: `https://192.168.10.10`
- Login: `sysadmin` / `Sysadmin2026!`

## Verification

Run the following commands on the `infra` VM.

**List all users:**

```bash
ldapsearch -x -H ldap://127.0.0.1 \
  -D "cn=admin,dc=technova,dc=local" \
  -w Sysadmin2026! \
  -b "ou=users,dc=technova,dc=local" \
  "(objectClass=posixAccount)" uid
```

**Search a specific user:**

```bash
ldapsearch -x -H ldap://127.0.0.1 \
  -D "cn=admin,dc=technova,dc=local" \
  -w Sysadmin2026! \
  -b "dc=technova,dc=local" \
  "(uid=jjunior)"
```

**Confirm POSIX resolution via SSSD:**

```bash
id jjunior
```

## Example Playbook

```yaml
- hosts: infra
  roles:
    - role: ldap
```

Run from the `auto` VM:

```bash
vagrant ssh auto
cd /vagrant/ansible
ansible-playbook -i inventory.ini playbook.yml --limit infra
```

## Idempotency

- `slapd` is only reset on first provision (`/var/lib/ldap/data.mdb` absent)
- Admin password is enforced on every run via `ldappasswd -Y EXTERNAL`
- `ldapadd` tasks are safe to re-run — they ignore `Already exists` errors

## License

MIT

## Author

lopesfabri
