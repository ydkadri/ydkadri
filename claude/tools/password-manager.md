# Password Manager (pass)

Complete guide to using `pass` (the standard Unix password manager) with GPG encryption.

## What is pass?

`pass` is a Unix password manager that stores passwords as GPG-encrypted files in `~/.password-store/`. Each password is a separate `.gpg` file that can only be decrypted with your GPG private key.

**Key features:**
- GPG encryption for security
- Git integration for backup and sync
- Simple file-based storage (no database)
- Multi-user support via GPG keys
- Works across all platforms

## Quick Reference

```bash
pass                              # List all passwords
pass insert client/api-key        # Add password (groups = directory paths)
pass generate client/token 25     # Generate random password (25 chars)
pass show client/api-key          # Display password
pass show -c client/api-key       # Copy to clipboard (45s timeout)
pass edit client/api-key          # Edit password
pass rm client/api-key            # Remove password
pass rm -r client/                # Remove entire group
```

## GPG Keys

### Understanding GPG Keys

GPG (GNU Privacy Guard) uses asymmetric encryption with two keys:

- **Private key**: Decrypts passwords (keep secret, back up securely)
- **Public key**: Encrypts passwords (can be shared, regenerated from private)

**Critical**: Your GPG private key is the master key to your entire password store. Losing it means losing access to all passwords permanently. No recovery mechanism exists.

### Creating GPG Keys

```bash
# Generate new GPG key pair
gpg --full-generate-key

# Prompts:
# - Key type: (1) RSA and RSA (default)
# - Key size: 4096 (more secure)
# - Expiration: 0 (no expiration) or set date
# - Name: Your actual name
# - Email: Your email address
# - Passphrase: Strong passphrase to protect private key

# Verify key was created
gpg --list-secret-keys
```

### Backing Up GPG Keys

**CRITICAL: Back up your GPG keys immediately after creation.**

```bash
# Find your key ID
gpg --list-secret-keys
# Look for line like: B60D2B46C1C71BBB89C911AD50F2BA735965126C

# Export private key (KEEP VERY SECURE)
gpg --export-secret-keys --armor YOUR_KEY_ID > gpg-private-backup.asc

# Export public key (for convenience)
gpg --export --armor YOUR_KEY_ID > gpg-public-backup.asc

# Copy revocation certificate (to revoke key if compromised)
cp ~/.gnupg/openpgp-revocs.d/YOUR_KEY_ID.rev gpg-revocation-backup.rev
```

**Where to store GPG backups:**

1. **Encrypted USB drive** - Store in physical safe or lockbox
2. **Print on paper** - Store in physical safe (sounds old-school, works great)
3. **Separate private repository** - NOT the same repo as password-store
4. **Inside pass itself** (recursive but provides redundancy):
   ```bash
   gpg --export-secret-keys --armor YOUR_KEY_ID | pass insert -m backup/gpg-private-key
   ```

**NEVER store GPG keys in the same repository as your password store.** Storing them together defeats the entire purpose of encryption.

### Restoring GPG Keys

```bash
# Import private key
gpg --import gpg-private-backup.asc

# Trust the imported key (required for pass to work)
gpg --edit-key YOUR_KEY_ID
gpg> trust
Your decision? 5 (ultimate trust)
gpg> quit

# Verify it worked
gpg --list-secret-keys
```

### GPG Key Locations

Your GPG keys are stored in `~/.gnupg/`:

```
~/.gnupg/
├── private-keys-v1.d/*.key    # Private keys (CRITICAL - back up)
├── pubring.kbx                # Public keyring (back up)
├── trustdb.gpg                # Trust database (back up)
├── openpgp-revocs.d/*.rev     # Revocation certificates (back up)
├── gpg.conf                   # Configuration (managed by home-manager)
├── gpg-agent.conf             # Agent config (managed by home-manager)
└── S.gpg-agent*               # Runtime sockets (temporary)
```

## Password Store Setup

### Initial Setup

```bash
# Initialize password store with your GPG key
pass init YOUR_EMAIL@example.com
# Or use key ID directly
pass init YOUR_KEY_ID

# Verify it worked
pass
```

This creates `~/.password-store/` directory with a `.gpg-id` file containing your key ID.

### Directory Structure

Passwords are organised by directory paths (groups):

```
~/.password-store/
├── .gpg-id                    # GPG key(s) for this directory
├── github/
│   ├── personal-token.gpg
│   └── work-account.gpg
├── databricks/
│   ├── workspace-token.gpg
│   └── admin-password.gpg
├── client/
│   ├── production/
│   │   ├── .gpg-id            # Can have different keys per subdirectory
│   │   ├── api-key.gpg
│   │   └── database.gpg
│   └── staging/
│       └── api-key.gpg
└── personal/
    └── credit-card.gpg
```

**Groups are just directory paths** - no need to create them manually. They're created automatically when you insert passwords.

## Basic Operations

### Adding Passwords

```bash
# Add password (you'll be prompted to type it)
pass insert github/personal-token

# Add password with confirmation
pass insert -m github/personal-token

# Generate random password (recommended)
pass generate github/api-key 32

# Generate without symbols (for systems that don't allow them)
pass generate -n github/numeric-pin 8
```

### Viewing Passwords

```bash
# Display password
pass show github/personal-token

# Copy to clipboard (auto-clears after 45 seconds)
pass show -c github/personal-token

# Show first line only (useful for multiline entries)
pass show github/personal-token | head -n1
```

### Editing Passwords

```bash
# Edit password in default editor
pass edit github/personal-token

# This opens the decrypted file in $EDITOR (nvim)
# Save and close to re-encrypt
```

### Removing Passwords

```bash
# Remove single password
pass rm github/personal-token

# Remove entire directory (recursive)
pass rm -r client/

# Force remove without confirmation
pass rm -f github/old-token
```

### Listing Passwords

```bash
# List all passwords
pass

# List specific directory
pass github/

# Search for passwords
pass grep "api"
pass grep -i "TOKEN"  # Case insensitive
```

## Storing Files

### Text Files (SSH Keys, Certificates, Config)

`pass` works great for multiline text content:

```bash
# Pipe file into pass
cat ~/.ssh/id_ed25519 | pass insert -m backup/ssh-private-key

# Or use input redirection
pass insert -m backup/ssh-key < ~/.ssh/id_ed25519

# Restore file
pass show backup/ssh-key > ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519

# Regenerate public key from private key (SSH keys only)
ssh-keygen -y -f ~/.ssh/id_ed25519 > ~/.ssh/id_ed25519.pub
```

**Common use cases:**
- SSH private keys
- SSL/TLS certificates
- API configuration files (JSON, YAML)
- Service account credentials

### Binary Files (Not Recommended)

For binary files, use GPG directly instead of `pass`:

```bash
# Encrypt binary file
gpg --encrypt --recipient your-email@example.com file.pdf
# Creates: file.pdf.gpg

# Decrypt binary file
gpg --decrypt file.pdf.gpg > file.pdf
```

## Git Backup and Sync

### Why Use Git?

Backing up your password store to a private Git repository provides:
- **Cloud backup** - Don't lose passwords if machine dies
- **Version history** - Revert password changes if needed
- **Multi-machine sync** - Access passwords on all your devices
- **Encrypted storage** - Files are encrypted, safe to store remotely

### Initial Git Setup

```bash
# Initialize git repository in password store
pass git init

# Create private GitHub repository (CRITICAL: must be private!)
gh repo create password-store --private

# Add remote
pass git remote add origin git@github.com:YOUR_USERNAME/password-store.git

# Push initial passwords
pass git push -u origin main

# Enable auto-commit on changes (optional)
pass git config --bool --add pass.signcommits false
```

### Git Operations

Every `pass git <command>` runs git commands in `~/.password-store/`:

```bash
# Check status
pass git status

# View history
pass git log

# Pull latest changes
pass git pull

# Push local changes
pass git push

# View diff
pass git diff

# Manual commit (if auto-commit disabled)
pass git add -A
pass git commit -m "Add new client passwords"
pass git push
```

### Automatic Git Commits

When auto-commit is enabled, `pass` automatically commits changes:

```bash
pass insert github/token
# Auto-commits with message: "Add generated password for github/token."

pass edit github/token
# Auto-commits with message: "Edit password for github/token using nvim."

pass rm github/old-token
# Auto-commits with message: "Remove github/old-token from store."
```

Then just `pass git push` to sync to remote.

## Multi-Machine Setup

### Setting Up New Machine

**Step 1: Import GPG Key**
```bash
# Copy gpg-private-backup.asc to new machine, then:
gpg --import gpg-private-backup.asc

# Trust the imported key (required)
gpg --edit-key YOUR_KEY_ID
gpg> trust
Your decision? 5 (ultimate trust)
gpg> quit
```

**Step 2: Clone Password Store**
```bash
git clone git@github.com:YOUR_USERNAME/password-store.git ~/.password-store
```

**Step 3: Verify It Works**
```bash
pass
pass show github/token
```

Done! The machine can now read and write passwords.

### Sync Workflow

**On Machine A (add password):**
```bash
pass insert client/new-api-key
pass git push
```

**On Machine B (get new password):**
```bash
pass git pull
pass show client/new-api-key
```

**Best practice:**
- `pass git pull` before adding new passwords (avoid conflicts)
- `pass git push` after adding/editing passwords (share changes)

### Handling Conflicts

If both machines modify passwords simultaneously:

```bash
pass git pull
# Conflict detected

# Resolve manually
cd ~/.password-store
git status
# Edit conflicting files or choose version
git add .
git commit -m "Resolve merge conflict"
pass git push
```

Better to avoid conflicts by pulling before changes.

## Multi-User / Team Access

### Per-Directory Access Control

`pass` supports different GPG keys for different directories using `.gpg-id` files:

```bash
# Root level - everyone can access
pass init key0@me.com key1@teammate.com key2@other.com

# Subdirectory - only you and teammate 1
pass init -p team1 key0@me.com key1@teammate.com

# Subdirectory - only you and teammate 2
pass init -p team2 key0@me.com key2@other.com

# Subdirectory - only you
pass init -p personal key0@me.com
```

**Directory structure:**
```
~/.password-store/
├── .gpg-id                    # key0, key1, key2
├── shared/
│   └── database.gpg           # All 3 can decrypt
├── team1/
│   ├── .gpg-id                # key0, key1 only
│   └── api-key.gpg            # Only you and teammate 1
├── team2/
│   ├── .gpg-id                # key0, key2 only
│   └── secret.gpg             # Only you and teammate 2
└── personal/
    ├── .gpg-id                # key0 only
    └── private.gpg            # Only you
```

### Adding Passwords with Access Control

```bash
# Everyone can read
pass insert shared/database-password

# Only team1 members
pass insert team1/project-api-key

# Only team2 members
pass insert team2/client-token

# Only you
pass insert personal/master-password
```

### Sharing Password Store

**Setup shared repository:**

```bash
# Create shared private repository
gh repo create team-passwords --private

# Add team members as collaborators
gh api repos/YOUR_ORG/team-passwords/collaborators/teammate1 -X PUT

# Initialize with all team GPG keys
pass init key0@me.com key1@teammate1.com key2@teammate2.com

# Push to shared repo
pass git remote add origin git@github.com:YOUR_ORG/team-passwords.git
pass git push -u origin main
```

**Each team member:**
1. Imports their own GPG key
2. Clones the repository
3. Can decrypt passwords encrypted with their key

### Managing Access

**Add user to directory:**
```bash
# Add teammate3's key to team1
pass init -p team1 key0@me.com key1@teammate.com key3@teammate3.com

# Commit the change
pass git add team1/.gpg-id
pass git commit -m "Add teammate3 to team1 access"
pass git push
```

**Remove user from directory:**
```bash
# Remove teammate1 from team1
pass init -p team1 key0@me.com key3@teammate3.com

# This re-encrypts all passwords in team1/ without key1
# Teammate1 can no longer decrypt future changes
pass git add team1/
pass git commit -m "Remove teammate1 from team1 access"
pass git push
```

**Note**: Removed users can still decrypt old commits (git history). For full revocation, you must:
1. Change the actual passwords
2. Re-encrypt with new GPG keys
3. Optionally rewrite git history (advanced, risky)

## Advanced Operations

### Changing GPG Key

If you need to change the GPG key used for encryption:

```bash
# Generate new GPG key (if needed)
gpg --full-generate-key

# Re-initialize pass with new key
pass init new-email@example.com

# This automatically:
# - Updates .gpg-id file
# - Re-encrypts ALL passwords with new key
# - Old key can no longer decrypt

# Push changes
pass git push
```

On other machines:
1. Import new GPG key
2. Pull changes: `pass git pull`
3. Passwords now use new key

### Searching Passwords

```bash
# Search password names
pass | grep github

# Search password contents
pass grep "api.example.com"

# Case-insensitive search
pass grep -i "token"

# Search specific directory
pass grep "key" client/
```

### OTP / TOTP Support

`pass` can store one-time passwords (2FA codes) with `pass-otp` extension:

```bash
# Install pass-otp (if needed)
# Already available on most systems with pass

# Add OTP secret
pass otp insert github/2fa
# Paste your OTP secret (from QR code or base32 string)

# Generate OTP code
pass otp github/2fa

# Copy OTP code to clipboard
pass otp -c github/2fa
```

### Generating Secure Passphrases

```bash
# Generate memorable passphrase (using diceware-style)
pass generate -n passwords/master-passphrase 6

# This generates 6 random words, easier to remember than random chars
# Example: correct-horse-battery-staple-purple-monkey
```

## Integration with Shell

### Shell Functions

Add these to `~/.managed/pass/functions.sh` (managed by home-manager):

```bash
# Copy GitHub token from pass
pass-github() {
    pass show -c github/personal-token
    echo "GitHub token copied to clipboard"
}

# Search and copy password interactively
pass-find() {
    local password=$(pass | fzf --height 40% --reverse)
    if [[ -n "$password" ]]; then
        pass show -c "$password"
        echo "Password copied to clipboard"
    fi
}

# Quick insert with random password
pass-quick() {
    if [[ -z "$1" ]]; then
        echo "Usage: pass-quick <name>"
        return 1
    fi
    pass generate "$1" 32
    pass show -c "$1"
    echo "Generated and copied to clipboard"
}
```

### Environment Variables from pass

Export secrets from pass to environment:

```bash
# In ~/.zshrc.local (not tracked in git)
export GITHUB_TOKEN=$(pass show github/personal-token)
export DATABRICKS_TOKEN=$(pass show databricks/workspace-token)
export AWS_ACCESS_KEY=$(pass show aws/access-key)
```

Or use pass dynamically in scripts:

```bash
#!/bin/bash
API_KEY=$(pass show client/api-key)
curl -H "Authorization: Bearer $API_KEY" https://api.example.com/
```

## Troubleshooting

### "gpg: decryption failed: No secret key"

**Problem**: Your GPG private key is not available.

**Solution**:
```bash
# Check if key exists
gpg --list-secret-keys

# If missing, import from backup
gpg --import gpg-private-backup.asc

# Trust the key
gpg --edit-key YOUR_KEY_ID
gpg> trust
Your decision? 5
gpg> quit
```

### "gpg: public key decryption failed: Inappropriate ioctl for device"

**Problem**: GPG agent can't prompt for passphrase.

**Solution**:
```bash
# Set GPG_TTY environment variable
export GPG_TTY=$(tty)

# Add to ~/.zshrc or ~/.zshrc.local
echo 'export GPG_TTY=$(tty)' >> ~/.zshrc.local
```

### "pass: .gpg-id not found"

**Problem**: Password store not initialized.

**Solution**:
```bash
pass init your-email@example.com
```

### Clipboard Not Working

**Problem**: `pass show -c` doesn't copy to clipboard.

**Solution** (macOS):
```bash
# Install pbcopy (should be built-in on macOS)
which pbcopy

# If missing, install via homebrew
brew install pbcopy
```

**Solution** (Linux):
```bash
# Install xclip or wl-clipboard
sudo apt install xclip          # X11
sudo apt install wl-clipboard   # Wayland
```

### Git Push Fails

**Problem**: Can't push to remote repository.

**Solution**:
```bash
# Check remote URL
pass git remote -v

# Update remote if needed
pass git remote set-url origin git@github.com:YOUR_USERNAME/password-store.git

# Ensure you have SSH key configured for GitHub
ssh -T git@github.com
```

## Security Best Practices

### GPG Key Security

- ✅ **Back up GPG keys immediately** after creation
- ✅ **Store backups separately** from password store
- ✅ **Use strong passphrase** for GPG key (12+ characters)
- ✅ **Keep private key secure** - never share or commit to git
- ❌ **Never store GPG key in password-store repo**

### Password Store Security

- ✅ **Use private repositories** for git backup (never public)
- ✅ **Enable two-factor authentication** on GitHub/GitLab
- ✅ **Review access regularly** in multi-user setups
- ✅ **Rotate passwords periodically** especially for critical services
- ❌ **Don't share password store with untrusted users**

### Machine Security

- ✅ **Lock screen** when away from computer
- ✅ **Encrypt disk** (FileVault on macOS, LUKS on Linux)
- ✅ **Keep OS updated** to patch security vulnerabilities
- ❌ **Don't leave GPG passphrase unlocked indefinitely**

### Team Security

- ✅ **Remove access immediately** when team members leave
- ✅ **Rotate shared passwords** after removing access
- ✅ **Use per-directory access control** to limit exposure
- ✅ **Audit git history** for unexpected changes
- ❌ **Don't share GPG private keys** - each person has their own

## Reference

### Common Commands Summary

| Command | Description |
|---------|-------------|
| `pass` | List all passwords |
| `pass insert <name>` | Add new password |
| `pass generate <name> <length>` | Generate random password |
| `pass show <name>` | Display password |
| `pass show -c <name>` | Copy password to clipboard |
| `pass edit <name>` | Edit password |
| `pass rm <name>` | Remove password |
| `pass rm -r <dir>` | Remove directory |
| `pass grep <pattern>` | Search passwords |
| `pass git <command>` | Run git command in password store |
| `pass init <gpg-id>` | Initialize password store |
| `pass init -p <dir> <gpg-id>` | Set GPG key for subdirectory |

### GPG Commands Summary

| Command | Description |
|---------|-------------|
| `gpg --full-generate-key` | Generate new GPG key pair |
| `gpg --list-keys` | List public keys |
| `gpg --list-secret-keys` | List private keys |
| `gpg --export-secret-keys --armor <id>` | Export private key |
| `gpg --export --armor <id>` | Export public key |
| `gpg --import <file>` | Import key from file |
| `gpg --edit-key <id>` | Edit key (trust, sign, etc.) |
| `gpg --delete-secret-keys <id>` | Delete private key |
| `gpg --delete-keys <id>` | Delete public key |

### File Locations

| Path | Description |
|------|-------------|
| `~/.password-store/` | Password store directory |
| `~/.password-store/.gpg-id` | GPG key ID(s) for root directory |
| `~/.gnupg/` | GPG configuration and keys |
| `~/.gnupg/private-keys-v1.d/` | GPG private keys |
| `~/.gnupg/pubring.kbx` | GPG public keyring |
| `~/.gnupg/trustdb.gpg` | GPG trust database |

---

**Last Updated**: 2026-04-24
