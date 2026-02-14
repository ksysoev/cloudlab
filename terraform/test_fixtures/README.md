# Test Fixtures

This directory contains test fixtures used by Terraform tests.

## SSH Keys

- `test_key` - Private key (not committed to git)
- `test_key.pub` - Public key (committed for tests)

These keys are generated automatically and used only for Terraform test validation.
They are never used for actual infrastructure deployment.

## Regenerating Keys

If you need to regenerate the test keys:

```bash
ssh-keygen -t ed25519 -C "test-key-for-terraform-tests" -f test_key -N ""
```

The private key (`test_key`) will be ignored by git, but the public key (`test_key.pub`) will be committed.
