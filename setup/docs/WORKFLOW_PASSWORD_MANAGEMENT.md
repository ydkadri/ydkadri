# Workflow: Password Management

How to securely manage passwords and secrets using Pass (password-store) with GPG encryption.

## The Problem

Developers need to manage many secrets:
- API keys and tokens
- Database credentials
- SSH passphrases
- Service passwords
- Personal accounts

**Common anti-patterns**:
```bash
# ❌ Plaintext in shell history
export API_KEY="super-secret-key"

# ❌ Hardcoded in scripts
TOKEN = "ghp_abc123def456"

# ❌ Stored in .env files (risk of accidental commit)
DATABASE_URL=postgresql://user:password@localhost/db

# ❌ Browser-saved passwords (not accessible from terminal)
```

**Problems**:
- Secrets leak in git history
- Plaintext in config files
- Shared across machines insecurely
- Hard to rotate/update
- No audit trail

## The Solution

**Pass (password-store)** = Unix philosophy password manager:
- Encrypted with GPG (industry-standard)
- Stored as files (easy to understand)
- Git-backed (version control, sync)
- Command-line first (scriptable)
- Open source (auditable)

### The Stack

1. **GPG** - Encryption engine (GNU Privacy Guard)
2. **Pass** - Password management tool built on GPG
3. **Git** - Optional backup/sync
4. **Shell helpers** - Quick access functions

## How It Works

```
┌─────────────────────────────────────────────────────┐
│  You store a password                               │
└──────────────────┬──────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────────┐
│  pass insert github/token                           │
│  Enter password: ********                           │
└──────────────────┬──────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────────┐
│  Pass encrypts with your GPG key                    │
│  Saves to: ~/.password-store/github/token.gpg       │
└──────────────────┬──────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────────┐
│  Optionally commits to git                          │
│  Can push to remote for backup                      │
└─────────────────────────────────────────────────────┘


Later:

┌─────────────────────────────────────────────────────┐
│  You need the password                              │
│  pass show github/token                             │
└──────────────────┬──────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────────┐
│  GPG prompts for your passphrase (once per session) │
│  Enter passphrase: ********                         │
└──────────────────┬──────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────────┐
│  Pass decrypts and shows password                   │
│  ghp_abc123def456                                   │
└─────────────────────────────────────────────────────┘
```

## Initial Setup

### 1. Create GPG Key

```bash
# Generate new GPG key
$ gpg --gen-key

# Follow prompts:
Real name: Youcef Kadri
Email address: your-email@example.com
Passphrase: (choose strong passphrase)

# This creates your encryption key
```

**Output**:
```
pub   rsa3072 2026-04-01 [SC] [expires: 2028-04-01]
      AB12CD34EF56GH78IJ90KL12MN34OP56QR78ST90
uid   Youcef Kadri <your-email@example.com>
sub   rsa3072 2026-04-01 [E]
```

**Key ID**: `AB12CD34EF56GH78IJ90KL12MN34OP56QR78ST90` (long hex string)

### 2. Initialize Pass

```bash
# Initialize password store with your GPG key
$ pass init "your-email@example.com"

# Creates ~/.password-store/ directory
```

**Output**:
```
Password store initialized for your-email@example.com
```

### 3. (Optional) Setup Git Sync

```bash
# Initialize git in password store
$ cd ~/.password-store
$ git init
$ git remote add origin git@github.com:yourusername/password-store.git

# Future password changes auto-commit
# Push manually or setup auto-push
```

**Directory structure**:
```
~/.password-store/
├── .git/
├── .gpg-id                 (Your GPG key ID)
└── (your passwords will go here as .gpg files)
```

## Daily Usage

### Storing a Password

```bash
# Store password interactively (most secure)
$ pass insert github/personal-token
Enter password for github/personal-token: ********
Retype password for github/personal-token: ********

# Generated by pass and saved encrypted
```

**File created**: `~/.password-store/github/personal-token.gpg`

**With multi-line data** (e.g., SSH key):
```bash
$ pass insert -m github/ssh-key
Enter contents of github/ssh-key and press Ctrl+D when finished:
-----BEGIN OPENSSH PRIVATE KEY-----
...key contents...
-----END OPENSSH PRIVATE KEY-----
^D
```

### Retrieving a Password

```bash
# Show password
$ pass show github/personal-token
ghp_abc123def456ghi789

# Copy to clipboard (45 second timeout)
$ pass show -c github/personal-token
Copied github/personal-token to clipboard. Will clear in 45 seconds.

# Show without newline (for piping)
$ pass show -n github/personal-token | some-command
```

### Generating Secure Passwords

```bash
# Generate 20-character password
$ pass generate github/new-token 20
The generated password for github/new-token is:
Xk2$mP9@nQ7#vR4&wS1^

# Without symbols
$ pass generate -n github/simple-pass 16

# Don't show password (only store)
$ pass generate -c github/secret 32
Copied github/secret to clipboard.
```

### Listing Passwords

```bash
# Show all passwords (tree view)
$ pass
Password Store
├── github
│   ├── personal-token
│   └── work-token
├── aws
│   ├── access-key-id
│   └── secret-access-key
├── database
│   ├── prod-url
│   └── dev-url
└── services
    ├── api-key
    └── webhook-secret

# List specific folder
$ pass github
github
├── personal-token
└── work-token
```

### Searching for Passwords

```bash
# Find passwords matching pattern
$ pass find api
Search Terms: api
├── services/api-key
└── aws/api-gateway-key

# Grep through password contents (decrypts each)
$ pass grep "prod"
database/prod-url:
postgresql://user:pass@prod.example.com/db
```

### Editing Passwords

```bash
# Edit password in $EDITOR
$ pass edit github/personal-token

# Opens nvim with decrypted content
# Edit and save
# Automatically re-encrypts
```

### Deleting Passwords

```bash
# Delete password (with confirmation)
$ pass rm github/old-token
Are you sure you would like to delete github/old-token? [y/N] y
removed '/Users/you/.password-store/github/old-token.gpg'

# Force delete (no confirmation)
$ pass rm -f github/old-token
```

### Moving/Renaming

```bash
# Rename password
$ pass mv github/old-name github/new-name

# Move to different folder
$ pass mv github/token api-keys/github-token
```

### Copying Passwords

```bash
# Copy password entry
$ pass cp github/token github/token-backup
```

## Organizing Passwords

### Recommended Structure

```
~/.password-store/
├── personal/
│   ├── email/
│   │   ├── gmail
│   │   └── protonmail
│   ├── social/
│   │   ├── github
│   │   └── twitter
│   └── finance/
│       ├── bank
│       └── credit-card
├── work/
│   ├── github/
│   │   ├── personal-token
│   │   └── work-token
│   ├── aws/
│   │   ├── access-key-id
│   │   ├── secret-access-key
│   │   └── session-token
│   └── databases/
│       ├── prod-postgres
│       ├── staging-postgres
│       └── redis-url
├── services/
│   ├── api-keys/
│   │   ├── openai
│   │   ├── stripe
│   │   └── twilio
│   └── webhooks/
│       ├── github-webhook
│       └── slack-webhook
└── ssh/
    ├── id_rsa-passphrase
    └── server-passwords
```

**Naming conventions**:
- Use folders for categories
- Use descriptive names (not "password1")
- Include context (github/personal-token vs just token)
- Use hyphens or underscores (not spaces)

### Multi-line Entries

Store more than just passwords:
```bash
$ pass insert -m aws/credentials
username: aws_user
access_key: AKIAIOSFODNN7EXAMPLE
secret_key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
region: us-east-1
^D
```

Retrieve specific line:
```bash
$ pass show aws/credentials | grep access_key
access_key: AKIAIOSFODNN7EXAMPLE
```

## Shell Integration

### Helper Functions (Already in shell.nix)

```zsh
# Copy GitHub token to clipboard
pass-github() {
  pass show -c github/personal-token
  echo "GitHub token copied to clipboard"
}
```

Usage:
```bash
$ pass-github
GitHub token copied to clipboard
```

### Create Your Own Helpers

Add to `~/.zshrc` or `programs/shell.nix`:

```zsh
# Get database URL for environment
db-url() {
  local env=${1:-dev}
  pass show database/${env}-url
}

# Usage:
# $ db-url prod
# postgresql://user:pass@prod.example.com/db
```

```zsh
# Set environment variable from pass
export-pass() {
  local var=$1
  local path=$2
  export $var=$(pass show $path)
}

# Usage:
# $ export-pass API_KEY services/api-key
# $ echo $API_KEY
# abc123...
```

### Use in Scripts

```bash
#!/bin/bash

# Get password in script
API_KEY=$(pass show services/api-key)

# Use it
curl -H "Authorization: Bearer $API_KEY" https://api.example.com
```

**Security note**: Scripts using pass require GPG passphrase entry (or cached session).

## Git Integration

### Auto-commit

Pass automatically commits changes:
```bash
$ pass insert github/new-token
Enter password: ********
[master abc1234] Add given password for github/new-token to store.
```

### Manual git operations

```bash
# View history
$ cd ~/.password-store
$ git log --oneline
abc1234 Add given password for github/new-token to store
def5678 Edit password for aws/access-key using nvim
ghi9012 Remove github/old-token from store

# Push to remote
$ pass git push

# Pull from remote
$ pass git pull
```

### Sync Across Machines

**Machine 1** (initial setup):
```bash
$ pass init "your-email@example.com"
$ cd ~/.password-store
$ git init
$ git remote add origin git@github.com:user/password-store.git
$ git push -u origin master
```

**Machine 2** (clone existing):
```bash
# Make sure you have your GPG key on this machine!
$ git clone git@github.com:user/password-store.git ~/.password-store
$ pass
# Works! All passwords available
```

**Note**: Your GPG **private key** must be on both machines. Export/import it securely.

## Security Best Practices

### 1. Strong GPG Passphrase

Your GPG passphrase protects everything:
- Use 20+ characters
- Mix letters, numbers, symbols
- Unique (not used elsewhere)
- Memorable (you'll type it often)

**Good passphrases**:
- `correct-horse-battery-staple-7892!` (diceware-style)
- `MyD0g@teMyH0mew0rk!nSecondGrade` (personal story)

### 2. GPG Agent Caching

GPG remembers your passphrase for a session (default: 1 hour).

Configure in `~/.gnupg/gpg-agent.conf`:
```
default-cache-ttl 3600      # 1 hour
max-cache-ttl 7200          # 2 hours max
```

**Home-manager sets this** in `programs/cli-tools.nix`.

### 3. Clipboard Timeout

Pass clears clipboard after 45 seconds (configured in setup).

Don't leave sensitive data in clipboard!

### 4. Git Repository Security

**Private repo**: Always use private GitHub repo for password-store.

**Don't** push to public repos - even encrypted, it reveals structure.

### 5. Backup GPG Key

Your GPG key is critical:

```bash
# Export private key (keep very secure!)
$ gpg --export-secret-keys --armor your-email@example.com > gpg-private-key.asc

# Store in secure location:
# - Encrypted USB drive
# - Encrypted cloud storage
# - Physical safe
# NOT in git or cloud in plaintext!
```

Restore on new machine:
```bash
$ gpg --import gpg-private-key.asc
$ gpg --edit-key your-email@example.com
gpg> trust
gpg> 5 (ultimate)
gpg> quit
```

### 6. What NOT to Store in Pass

**Safe**:
- API tokens
- Passwords
- Database credentials
- SSH passphrases

**Avoid**:
- Credit card numbers (use 1Password/Bitwarden for PCI compliance)
- Social Security Numbers (use offline storage)
- Crypto wallet seeds (use hardware wallet)

## Troubleshooting

### GPG passphrase prompts every time

GPG agent not running:
```bash
# Check GPG agent
$ gpg-agent --daemon

# Or restart
$ gpgconf --kill gpg-agent
$ gpgconf --launch gpg-agent
```

### "No secret key" error

GPG key not set up:
```bash
# List keys
$ gpg --list-secret-keys

# If empty, generate key
$ gpg --gen-key

# Re-initialize pass
$ pass init "your-email@example.com"
```

### Can't decrypt on new machine

GPG key not imported:
```bash
# On old machine, export key
$ gpg --export-secret-keys --armor your-email@example.com > key.asc

# On new machine, import
$ gpg --import key.asc
$ gpg --edit-key your-email@example.com
gpg> trust
gpg> 5
gpg> quit
```

### Git conflicts in password-store

```bash
$ cd ~/.password-store
$ git status
$ git pull --rebase
$ git push
```

Or use:
```bash
$ pass git pull --rebase
$ pass git push
```

### Forgot GPG passphrase

**No recovery possible** - GPG encryption is unbreakable without passphrase.

This is why backups are critical!

If you have backup, create new GPG key and re-encrypt:
```bash
# Generate new key
$ gpg --gen-key

# Re-encrypt all passwords
$ pass init "new-email@example.com"
```

## Migrating from Other Tools

### From Plaintext .env Files

```bash
# Old way
cat .env
API_KEY=abc123
DB_URL=postgresql://...

# New way
pass insert services/api-key
# Enter: abc123

pass insert database/url
# Enter: postgresql://...

# In code, use pass:
export API_KEY=$(pass show services/api-key)
```

### From 1Password/LastPass

Export to CSV, then import:
```bash
# Export from 1Password → file.csv
# Then import (script):

while IFS=, read -r name username password; do
  echo "$password" | pass insert -e "$name"
done < file.csv

# Delete CSV after import!
```

### From Browser Password Manager

Export, then import similar to above.

**Note**: Browsers store websites, pass doesn't. Add context in path:
```
gmail → personal/email/gmail
github.com → work/github
```

## Advanced Usage

### Multiple GPG Recipients

Share password store with team:
```bash
# Initialize with multiple keys
$ pass init "alice@example.com" "bob@example.com"

# Now both can decrypt
```

### Passwordstore Extensions

Pass supports extensions in `~/.password-store/.extensions/`:
- `pass-otp` - One-time passwords (2FA)
- `pass-tomb` - Extra encryption layer
- `pass-update` - Update stored passwords

### Integration with Password Managers

Some GUIs work with pass:
- **QtPass** - Qt GUI for pass
- **Android Password Store** - Mobile app
- **PassFF** - Firefox extension

## Comparison: Pass vs Alternatives

| Feature | Pass | 1Password | Bitwarden |
|---------|------|-----------|-----------|
| Cost | Free | $3/mo | Free/Open |
| CLI-first | ✅ | ❌ | ⚠️ |
| Browser extension | Manual | ✅ | ✅ |
| Open source | ✅ | ❌ | ✅ |
| Self-hosted | ✅ | ❌ | ✅ |
| Team sharing | Manual | ✅ | ✅ |
| Audit logging | Git | ✅ | ✅ |
| Mobile apps | 3rd-party | ✅ | ✅ |
| Learning curve | High | Low | Low |

**Use Pass if**:
- Terminal-first workflow
- Want full control
- Comfortable with GPG
- Want git-based sync

**Use 1Password/Bitwarden if**:
- Need browser integration
- Team collaboration features
- Want GUI apps
- Less technical users

## Summary

**The workflow**:
1. Store passwords: `pass insert path/to/password`
2. Retrieve: `pass show -c path/to/password` (copies to clipboard)
3. Everything encrypted with GPG
4. Optional git sync for backup

**The benefits**:
- ✅ Secure (GPG encryption, industry standard)
- ✅ Simple (just files and git)
- ✅ Scriptable (use in automation)
- ✅ Auditable (git history shows changes)
- ✅ Free and open source
- ✅ Works offline

**The investment**:
- 30 minutes initial setup (GPG key, pass init)
- Gradually migrate passwords over time
- Learn as you go

---

**Next**: See [WORKFLOW_SHELL_HISTORY.md](WORKFLOW_SHELL_HISTORY.md) for shell history management with atuin.

**Last Updated**: 2026-04-01
