# bashinator

**Version:** `0.1.0`

Lightweight Bash validation helpers for common types, formats, and safe text.
Designed for CLI scripts, CI/CD jobs, and automation where quick input checks
save time and prevent mistakes.

## Features

- Type and format checks (integers, UUID, IP, CIDR, Base64, date format)
- Safe text validation to reduce shell injection risk
- Small, dependency-free, easy to source
- Clear return codes: `0` pass, `1` fail

## About

I use this library in my own projects and decided to share these small helpers
with the community. This is my first public library, so feedback and suggestions
are welcome.

## Install

Clone or copy `bashinator.sh` into your project.

## Usage

```bash
source "./bashinator.sh"

if ! IsInteger "$PORT"; then
  printf '%s\n' "PORT must be an integer" >&2
  exit 1
fi
```

## Functions

Each function returns a status code: `0` means valid, `1` means invalid.

| Function | Input | Output | Meaning |
| --- | --- | --- | --- |
| `IsEmpty value` | string | status | `0` if empty |
| `IsNull value` | string | status | `0` if value is `null` |
| `IsBoolean value` | string | status | `0` if `true`/`false` |
| `IsString value` | string | status | `0` if contains letters |
| `IsInteger value` | string | status | `0` if signed integer |
| `IsPositiveInteger value` | string | status | `0` if integer > 0 |
| `IsGreaterZero value` | string | status | `0` if integer >= 0 |
| `IsIPv4 value` | string | status | `0` if valid IPv4 |
| `IsIPv6 value` | string | status | `0` if IPv6 format |
| `IsCidr value` | string | status | `0` if CIDR format |
| `IsUUID value` | string | status | `0` if UUID 8-4-4-4-12 |
| `IsBase64 value` | string | status | `0` if Base64 chars/padding |
| `IsDate value` | string | status | `0` if `YYYY-MM-DD` format |
| `IsEnum value values...` | value + list | status | `0` if match found |
| `ContainsDangerousChars text` | string | status | `0` if dangerous chars |
| `IsSafeText text [max_len]` | string + max | status | `0` if safe |
| `IsEmptyOrWhitespace text` | string | status | `0` if whitespace only |
| `IsValueInArray value array_name` | value + array | status | `0` if found |
| `WhatIs value` | string | stdout | prints type name |

## Practical examples

### Validate env and defaults

```bash
source "./bashinator.sh"

if IsEmpty "$API_TOKEN"; then
  printf '%s\n' "API_TOKEN is required" >&2
  exit 1
fi

if ! IsPositiveInteger "$RETRIES"; then
  RETRIES=3
fi
```

### Guard user input before shell usage

```bash
if ContainsDangerousChars "$user_input"; then
  printf '%s\n' "Unsafe characters in input" >&2
  exit 1
fi
```

### Route behavior by detected type

```bash
case "$(WhatIs "$value")" in
  integer) timeout="$value" ;;
  ipv4) target_ip="$value" ;;
  *) printf '%s\n' "Unknown input type" >&2; exit 1 ;;
esac
```

## Documentation

- English: `Doc/bashinator_doc_en.md`
- Russian: `Doc/bashinator_doc_ru.md`

## Contributing

Contributions are welcome. Please follow these simple rules to keep the project
consistent and easy to review:

- Open an issue or describe the change in the PR (what/why).
- Keep changes focused and small; avoid mixing refactors with new features.
- Add or update docs when behavior changes.
- Prefer tests or reproducible examples for bug fixes.
- Run formatting and `shellcheck` if you use it locally.

## Code style

Based on the current code style and common Bash repos:

- Use `UpperCamelCase` for function names, and `local` for variables.
- Prefer early returns for validation checks.
- Keep functions small and single-purpose.
- Use `[[ ... ]]` for regex and string tests; quote variables in tests.
- Always return `0` for success and `1` for validation failure.
- Avoid external dependencies unless absolutely necessary.

## Notes

- `IsDate` validates format only (`YYYY-MM-DD`), not calendar correctness.
- `IsIPv6` and `IsCidr` are basic format checks, not deep validation.
- `IsBase64` checks allowed characters and padding only.
- `IsInteger` accepts signed integers but not `+` sign or dots.

## License

MIT

