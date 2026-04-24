# Security Practices

Security guidelines and vulnerability prevention.

## Common Vulnerabilities to Prevent

### SQL Injection

**Always use parameterized queries. Never concatenate SQL.**

```python
# ✅ CORRECT - Parameterized query
cursor.execute(
    "SELECT * FROM users WHERE email = %s AND status = %s",
    (email, status)
)

# ❌ INCORRECT - SQL injection vulnerability
cursor.execute(
    f"SELECT * FROM users WHERE email = '{email}' AND status = '{status}'"
)
```

See sql.md for complete SQL safety patterns.

### Command Injection

**Never pass user input directly to shell commands.**

```python
# ✅ CORRECT - Use subprocess with list
import subprocess
subprocess.run(["ls", "-l", user_directory], check=True)

# ❌ INCORRECT - Shell injection vulnerability
subprocess.run(f"ls -l {user_directory}", shell=True)
```

### Cross-Site Scripting (XSS)

**Always escape output in HTML contexts.**

```python
# ✅ CORRECT - Use templating engine with auto-escaping
from jinja2 import Template
template = Template("<p>{{ user_input }}</p>")
output = template.render(user_input=user_data)

# ❌ INCORRECT - Raw HTML construction
output = f"<p>{user_data}</p>"
```

### Path Traversal

**Validate and sanitize file paths.**

```python
# ✅ CORRECT - Validate path is within allowed directory
import pathlib

def safe_read_file(user_path: str, base_dir: pathlib.Path) -> str:
    requested_path = (base_dir / user_path).resolve()
    if not requested_path.is_relative_to(base_dir):
        raise ValueError("Path traversal attempt detected")
    return requested_path.read_text()
```

### Insecure Deserialization

**Don't deserialize untrusted data without validation. Prefer JSON over pickle.**

```python
# ✅ CORRECT - Use safe formats
import json
data = json.loads(user_input)

# ❌ INCORRECT - Pickle from untrusted source
import pickle
user = pickle.loads(user_input)  # Code execution vulnerability
```

## Secrets Management

### Never Hardcode Credentials

❌ **Never do this:**
```python
API_KEY = "sk-1234567890abcdef"
PASSWORD = "mypassword123"
DATABASE_URL = "postgresql://user:pass@localhost/db"
```

✅ **Always use environment variables:**
```python
import os

API_KEY = os.getenv("API_KEY")
PASSWORD = os.getenv("PASSWORD")
DATABASE_URL = os.getenv("DATABASE_URL")
```

### Password Manager

Use `pass` (Unix password manager) for storing and managing secrets locally:

```bash
# Store secrets
pass insert github/personal-token
pass insert databricks/api-key

# Export to environment from pass
export GITHUB_TOKEN=$(pass show github/personal-token)

# Or use in scripts directly
API_KEY=$(pass show client/api-key)
```

**See [tools/password-manager.md](tools/password-manager.md) for complete guide** covering:
- GPG key setup and backup
- Multi-machine sync via git
- Team access control
- Integration with shell and scripts

### Environment Variables

- Use `.env` files for local development
- Never commit `.env` files to version control
- Provide `.env.example` as a template
- Use `pass` for storing secrets locally
- Use secure secrets management in production (e.g., AWS Secrets Manager, HashiCorp Vault)

### Pre-Commit Secrets Scanning

Required check before commit:
- Scan for API keys, tokens, passwords
- Flag hardcoded credentials
- Check for accidentally committed `.env` files

## Dependencies

### Keep Dependencies Updated

**Regular updates prevent vulnerabilities:**
- Review dependency updates monthly
- Update patch versions freely (x.y.Z)
- Test minor version updates (x.Y.0)
- Plan major version updates (X.0.0)

### Vulnerability Scanning

**Include in all projects:**

```makefile
# justfile
[group('security')]
vulnerability:
    pip install pip-audit && pip-audit  # Python
    cargo audit                          # Rust
```

**Response times:**
- Critical: Fix immediately
- High: Fix within 1 week
- Medium: Fix within 1 month
- Low: Fix with next update

### Audit Third-Party Packages

**Before adding dependency:**
1. Check maintenance - Recent commits? Active maintainers?
2. Check popularity - Downloads, stars, usage?
3. Check security - Known vulnerabilities? History?
4. Check license - Compatible with project?
5. Check size - Does it pull in many dependencies?

Prefer well-maintained, popular packages.

## Input Validation

### Validate All External Input

**Validate at system boundaries:**
- User input (forms, CLI args)
- API requests
- File uploads

**Don't validate internal function calls between trusted code.**

### Validation with attrs (Python)

```python
from attrs import define, validators

@define
class UserInput:
    email: str = validators.matches_re(r"^[^@]+@[^@]+\.[^@]+$")
    age: int = validators.and_(validators.ge(0), validators.le(150))
    username: str = validators.matches_re(r"^[a-zA-Z0-9_-]{3,20}$")
```

## Sensitive Data Handling

### Don't Log Secrets or PII

❌ **Never log:**
```python
logger.info(f"User password: {password}")
logger.info(f"API response: {api_key_response}")
logger.info(f"User SSN: {user.ssn}")
```

✅ **Safe logging:**
```python
logger.info("User authenticated successfully")
logger.info("API request completed")
logger.info(f"User ID: {user.id}")  # IDs ok, not personal data
```

### Data Encryption

**Encrypt at rest:**
- Database encryption (full disk encryption)
- Sensitive fields (credit cards, SSNs)
- Backup files

**Encrypt in transit:**
- Always use HTTPS/TLS for APIs
- Use TLS for database connections

**For passwords, hash with salt:**
```python
import bcrypt

hashed = bcrypt.hashpw(password.encode(), bcrypt.gensalt())
if bcrypt.checkpw(password.encode(), hashed):
    print("Password correct")
```

## Secure Coding Practices

### Python

**Common issues:**
- Don't use `eval()` or `exec()` with user input
- Don't use `pickle` for untrusted data
- Use `secrets` module for random values, not `random`
- Validate file paths before operations

```python
# ✅ CORRECT - Cryptographically secure random
import secrets
token = secrets.token_urlsafe(32)

# ❌ INCORRECT - Predictable random
import random
token = random.randint(0, 1000000)
```

### Rust

**unsafe code must be justified:**

```rust
/// # Safety
/// Caller must ensure pointer is valid and properly aligned.
/// Buffer must be at least `len` bytes.
pub unsafe fn read_buffer(ptr: *const u8, len: usize) -> Vec<u8> {
    // SAFETY: We trust the caller to provide valid pointer and length
    std::slice::from_raw_parts(ptr, len).to_vec()
}
```

**Minimize unsafe blocks. Prefer safe abstractions.**

Rust's type system prevents many vulnerabilities:
- No null pointer dereferences
- No buffer overflows (with bounds checking)
- No data races (with ownership system)

## Security Review Checklist

Before merging code:
- [ ] No hardcoded credentials or secrets
- [ ] Input validation on all user inputs
- [ ] Output encoding for display
- [ ] Secrets scanning passed
- [ ] Vulnerability scanning passed
- [ ] Dependencies are up to date
- [ ] No sensitive data in logs
- [ ] Authentication/authorization implemented correctly

---

**Last Updated**: 2026-03-23
