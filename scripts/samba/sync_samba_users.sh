#!/bin/bash
# scripts/samba/sync_samba_users.sh

LDAP_BASE="ou=users,dc=technova,dc=local"
LDAP_ADMIN="cn=admin,dc=technova,dc=local"
LDAP_PASS="manager"
DEFAULT_PASS="Change2026!"
LOG="/var/log/samba_sync.log"

# Technical users to always exclude
EXCLUDED_USERS="sysadmin operator"

# -------------------------------
# Get users from LDAP
# -------------------------------
LDAP_USERS=$(ldapsearch -x \
  -H ldap://127.0.0.1 \
  -D "$LDAP_ADMIN" \
  -w "$LDAP_PASS" \
  -b "$LDAP_BASE" \
  "(objectClass=posixAccount)" uid 2>/dev/null \
  | grep "^uid:" | awk '{print $2}')

# -------------------------------
# Get users from Samba
# -------------------------------
SAMBA_USERS=$(pdbedit -L 2>/dev/null | awk -F: '{print $1}')

# -------------------------------
# ADD — present in LDAP but not in Samba
# -------------------------------
for USERNAME in $LDAP_USERS; do

  # Skip technical users
  if echo "$EXCLUDED_USERS" | grep -qw "$USERNAME"; then
    continue
  fi

  # Already exists in Samba — skip
  if echo "$SAMBA_USERS" | grep -qw "$USERNAME"; then
    continue
  fi

  # Check if SSSD resolves the user
  FOUND=0
  for i in $(seq 1 5); do
    if getent passwd "$USERNAME" > /dev/null 2>&1; then
      FOUND=1
      break
    fi
    sleep 2
  done

  if [ "$FOUND" -eq 0 ]; then
    echo "$(date): SKIP - $USERNAME not available via SSSD" >> "$LOG"
    continue
  fi

  # Register in Samba with default password
  (echo "$DEFAULT_PASS"; echo "$DEFAULT_PASS") | smbpasswd -a -s "$USERNAME"
  smbpasswd -e "$USERNAME"

  # Force password change on first login
  pdbedit -u "$USERNAME" --pwd-must-change-time=1

  echo "$(date): ADD - $USERNAME registered in Samba — must change password on first login" >> "$LOG"

done

# -------------------------------
# REMOVE — present in Samba but no longer in LDAP
# -------------------------------
for USERNAME in $SAMBA_USERS; do

  # Never remove technical users
  if echo "$EXCLUDED_USERS" | grep -qw "$USERNAME"; then
    continue
  fi

  # Still exists in LDAP — skip
  if echo "$LDAP_USERS" | grep -qw "$USERNAME"; then
    continue
  fi

  # Remove from Samba
  smbpasswd -x "$USERNAME" 2>/dev/null
  echo "$(date): REMOVE - $USERNAME removed from Samba (not found in LDAP)" >> "$LOG"

done