# bashinator Library

**Version:** `0.1.1`

A set of Bash functions for validating types, formats, and safe text. All
functions return a status code: `0` means validation passed, `1` means failed.

## Purpose

This library is intended for fast input validation in shell scripts: type and
format checks, basic safety checks, and small utilities to validate data before
further processing.

## Usage

Source the file and call the functions directly:

```bash
source "./bashinator.sh"
```

## Common use cases

- Validate CLI arguments and environment variables before running logic.
- Check formats (IP, UUID, IPv4 CIDR) before network operations.
- Block dangerous characters before using user input in shell commands.
- Fall back to safe defaults on invalid input.
- Ensure values belong to an allowed list.

## Functions and use cases

Below are practical examples for each function. To run them, source the library
first:

```bash
source "./bashinator.sh"
```

### `IsEmpty value`

Use case: required secret in CI/CD, integrations, cron.
Input: string/value. Output: `0` — empty, `1` — has characters.

```bash
if IsEmpty "$API_TOKEN"; then
  printf '%s\n' "API_TOKEN is required" >&2
  exit 1
fi
```

### `IsNull value`

Use case: `jq -r` returned `null`, replace with a default.
Input: string. Output: `0` — value equals `null`, `1` — otherwise.

```bash
json_value="$(jq -r '.owner' config.json)"
if IsNull "$json_value"; then
  json_value="unknown"
fi
```

### `IsBoolean value`

Use case: env flag controls behavior; validate before running.
Input: string. Output: `0` — `true` or `false`, `1` — otherwise.

```bash
if ! IsBoolean "$ENABLE_LOGS"; then
  printf '%s\n' "ENABLE_LOGS must be true/false" >&2
  exit 1
fi
```

### `IsString value`

Use case: username from CLI should not be empty or numeric only.
Input: string. Output: `0` — contains letters, `1` — otherwise.

```bash
if ! IsString "$username"; then
  printf '%s\n' "Invalid username" >&2
  exit 1
fi
```

### `IsInteger value`

Use case: port from arguments for a local service.
Input: string. Output: `0` — signed integer, `1` — otherwise.

```bash
if ! IsInteger "$PORT"; then
  printf '%s\n' "PORT must be an integer" >&2
  exit 1
fi
```

### `IsPositiveInteger value`

Use case: retry count for network failures.
Input: string. Output: `0` — integer > 0, `1` — otherwise.

```bash
if ! IsPositiveInteger "$RETRIES"; then
  RETRIES=3
fi
```

### `IsGreaterZero value`

Use case: offset/page for log fetching.
Input: string. Output: `0` — integer >= 0, `1` — otherwise.

```bash
if ! IsGreaterZero "$OFFSET"; then
  OFFSET=0
fi
```

### `IsIPv4 value`

Use case: target host address for diagnostics/monitoring.
Input: string. Output: `0` — valid IPv4, `1` — otherwise.

```bash
if ! IsIPv4 "$TARGET_IP"; then
  printf '%s\n' "Invalid IPv4: $TARGET_IP" >&2
  exit 1
fi
ping -c 1 "$TARGET_IP"
```

### `IsIPv6 value`

Use case: address for routing/access rules.
Input: string. Output: `0` — IPv6 format, `1` — otherwise.

```bash
if ! IsIPv6 "$TARGET_IP"; then
  printf '%s\n' "Invalid IPv6: $TARGET_IP" >&2
  exit 1
fi
```

### `IsIPv4CIDR value`

Use case: IPv4 network range for firewall/ACL.
Input: string. Output: `0` — IPv4 CIDR format, `1` — otherwise.

```bash
if ! IsIPv4CIDR "$NETWORK"; then
  printf '%s\n' "IPv4 CIDR must look like 10.0.0.0/24" >&2
  exit 1
fi
```

### `IsUUID value`

Use case: request id for tracing/logs.
Input: string. Output: `0` — UUID 8-4-4-4-12, `1` — otherwise.

```bash
if ! IsUUID "$REQUEST_ID"; then
  printf '%s\n' "REQUEST_ID is not a UUID" >&2
  exit 1
fi
```

### `IsBase64 value`

Use case: secrets from Kubernetes/CI are often Base64-encoded.
Input: string. Output: `0` — basic Base64 check passed, `1` — otherwise.

```bash
if ! IsBase64 "$SECRET_B64"; then
  printf '%s\n' "SECRET_B64 must be Base64" >&2
  exit 1
fi
SECRET="$(printf '%s' "$SECRET_B64" | base64 -d)"
```

### `IsDate value`

Use case: backup date before selecting files.
Input: string. Output: `0` — `YYYY-MM-DD` format, `1` — otherwise.

```bash
if ! IsDate "$BACKUP_DATE"; then
  printf '%s\n' "BACKUP_DATE must be YYYY-MM-DD" >&2
  exit 1
fi
```

### `IsEnum value values...`

Use case: limit deployment environment.
Input: value and allowed list. Output: `0` — match found, `1` — otherwise.

```bash
if ! IsEnum "$ENV" "dev" "staging" "prod"; then
  printf '%s\n' "ENV must be dev|staging|prod" >&2
  exit 1
fi
```

### `ContainsDangerousChars text`

Use case: user input used in command or path.
Input: string. Output: `0` — dangerous characters found, `1` — safe.

```bash
if ContainsDangerousChars "$user_input"; then
  printf '%s\n' "Unsafe characters in input" >&2
  exit 1
fi
```

### `IsSafeText text [max_len]`

Use case: report/archive filename.
Input: string and max length. Output: `0` — safe text, `1` — otherwise.

```bash
if ! IsSafeText "$filename" 64; then
  printf '%s\n' "Filename contains forbidden characters" >&2
  exit 1
fi
```

### `IsEmptyOrWhitespace text`

Use case: comment field must not be empty.
Input: string. Output: `0` — whitespace only, `1` — otherwise.

```bash
if IsEmptyOrWhitespace "$comment"; then
  comment="(no comment)"
fi
```

### `IsValueInArray value array_name`

Use case: validate CLI action before executing.
Input: value and array name. Output: `0` — found in array, `1` — otherwise.

```bash
actions=("start" "stop" "restart")
if ! IsValueInArray "$action" actions; then
  printf '%s\n' "Allowed actions: start|stop|restart" >&2
  exit 1
fi
```

### `WhatIs value`

Use case: route input by type without custom regexes.
Input: string. Output: prints type to stdout (`integer`, `ipv4`, `string`, etc.).

```bash
case "$(WhatIs "$value")" in
  integer) timeout="$value" ;;
  ipv4) target_ip="$value" ;;
  *) printf '%s\n' "Unknown input type" >&2; exit 1 ;;
esac
```

## Behavior and limitations

- `IsInteger` accepts signed integers, but not `+` sign or dot.
- `IsPositiveInteger` requires > 0; `IsGreaterZero` allows zero.
- `IsDate` checks `YYYY-MM-DD` format only, not the actual calendar date.
- `IsIPv6` and `IsIPv4CIDR` perform basic format checks without deep validation.
- `IsIPv4CIDR` validates masks `0..32` without leading zeros.
- `IsBase64` checks allowed characters and padding only.
- `ContainsDangerousChars` checks for: `<`, `>`, `&`, `` ` ``, `$`, `;`, `\`.
  defined separately if needed.

