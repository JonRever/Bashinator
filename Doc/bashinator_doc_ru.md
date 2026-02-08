# Библиотека bashinator

**Версия:** `0.1.1`

Набор Bash-функций для проверки типов, форматов и безопасного текста. Все функции
возвращают код возврата: `0` — проверка пройдена, `1` — проверка не пройдена.

## Назначение библиотеки

Библиотека предназначена для быстрой валидации входных данных в shell-скриптах:
проверка типов и форматов, базовые проверки безопасности и удобные утилиты для
контроля входа до дальнейшей обработки.

## Подключение

Подключите файл и вызывайте функции напрямую:

```bash
source "./bashinator.sh"
```

## Типовые юзкейсы

- Валидация аргументов CLI и переменных окружения до запуска логики.
- Проверка форматов (IP, UUID, IPv4 CIDR) перед сетевыми операциями.
- Защита от опасных символов перед использованием ввода в shell-командах.
- Приведение значений к безопасным дефолтам при некорректном вводе.
- Проверка принадлежности значений разрешенному списку.

## Функции и юзкейсы

Ниже приведены прикладные примеры для каждой функции. Они показывают, как
сократить рутину проверки входа в Bash-скриптах. Для запуска примеров сначала
подключите библиотеку:

```bash
source "./bashinator.sh"
```

### `IsEmpty value`

Юзкейс: обязательный секрет в окружении (CI/CD, интеграции, cron).
Вход: строка/значение. Выход: `0` — пусто, `1` — есть символы.

```bash
if IsEmpty "$API_TOKEN"; then
  printf '%s\n' "API_TOKEN обязателен" >&2
  exit 1
fi
```

### `IsNull value`

Юзкейс: `jq -r` вернул `null`, нужно заменить на дефолт.
Вход: строка. Выход: `0` — значение равно `null`, `1` — иначе.

```bash
json_value="$(jq -r '.owner' config.json)"
if IsNull "$json_value"; then
  json_value="unknown"
fi
```

### `IsBoolean value`

Юзкейс: флаг из env управляет поведением, валидируем до запуска.
Вход: строка. Выход: `0` — `true` или `false`, `1` — иначе.

```bash
if ! IsBoolean "$ENABLE_LOGS"; then
  printf '%s\n' "ENABLE_LOGS должен быть true/false" >&2
  exit 1
fi
```

### `IsString value`

Юзкейс: пользовательское имя из CLI не должно быть пустым/числом.
Вход: строка. Выход: `0` — есть буквенные символы, `1` — иначе.

```bash
if ! IsString "$username"; then
  printf '%s\n' "Имя пользователя некорректно" >&2
  exit 1
fi
```

### `IsInteger value`

Юзкейс: порт из аргумента для локального сервиса.
Вход: строка. Выход: `0` — целое со знаком, `1` — иначе.

```bash
if ! IsInteger "$PORT"; then
  printf '%s\n' "PORT должен быть целым числом" >&2
  exit 1
fi
```

### `IsPositiveInteger value`

Юзкейс: число повторов при сетевых сбоях.
Вход: строка. Выход: `0` — целое > 0, `1` — иначе.

```bash
if ! IsPositiveInteger "$RETRIES"; then
  RETRIES=3
fi
```

### `IsGreaterZero value`

Юзкейс: смещение/страница для выборки логов.
Вход: строка. Выход: `0` — целое >= 0, `1` — иначе.

```bash
if ! IsGreaterZero "$OFFSET"; then
  OFFSET=0
fi
```

### `IsIPv4 value`

Юзкейс: адрес узла для диагностики и мониторинга.
Вход: строка. Выход: `0` — валидный IPv4, `1` — иначе.

```bash
if ! IsIPv4 "$TARGET_IP"; then
  printf '%s\n' "Неверный IPv4: $TARGET_IP" >&2
  exit 1
fi
ping -c 1 "$TARGET_IP"
```

### `IsIPv6 value`

Юзкейс: адрес для правил маршрутизации/доступа.
Вход: строка. Выход: `0` — формат IPv6, `1` — иначе.

```bash
if ! IsIPv6 "$TARGET_IP"; then
  printf '%s\n' "Неверный IPv6: $TARGET_IP" >&2
  exit 1
fi
```

### `IsIPv4CIDR value`

Юзкейс: IPv4-сеть для firewall/ACL.
Вход: строка. Выход: `0` — формат IPv4 CIDR, `1` — иначе.

```bash
if ! IsIPv4CIDR "$NETWORK"; then
  printf '%s\n' "IPv4 CIDR должен быть вида 10.0.0.0/24" >&2
  exit 1
fi
```

### `IsUUID value`

Юзкейс: входной request-id для трассировки и логов.
Вход: строка. Выход: `0` — UUID формата 8-4-4-4-12, `1` — иначе.

```bash
if ! IsUUID "$REQUEST_ID"; then
  printf '%s\n' "REQUEST_ID не похож на UUID" >&2
  exit 1
fi
```

### `IsBase64 value`

Юзкейс: секреты из Kubernetes/CI часто приходят в Base64.
Вход: строка. Выход: `0` — базовая проверка Base64 пройдена, `1` — иначе.

```bash
if ! IsBase64 "$SECRET_B64"; then
  printf '%s\n' "SECRET_B64 должен быть Base64" >&2
  exit 1
fi
SECRET="$(printf '%s' "$SECRET_B64" | base64 -d)"
```

### `IsDate value`

Юзкейс: дата резервной копии перед выборкой файлов.
Вход: строка. Выход: `0` — формат `YYYY-MM-DD`, `1` — иначе.

```bash
if ! IsDate "$BACKUP_DATE"; then
  printf '%s\n' "BACKUP_DATE должен быть YYYY-MM-DD" >&2
  exit 1
fi
```

### `IsEnum value values...`

Юзкейс: ограничение окружения деплоя.
Вход: значение и список допустимых. Выход: `0` — найдено совпадение, `1` — иначе.

```bash
if ! IsEnum "$ENV" "dev" "staging" "prod"; then
  printf '%s\n' "ENV должен быть dev|staging|prod" >&2
  exit 1
fi
```

### `ContainsDangerousChars text`

Юзкейс: пользовательский ввод для команды или пути.
Вход: строка. Выход: `0` — есть опасные символы, `1` — безопасно.

```bash
if ContainsDangerousChars "$user_input"; then
  printf '%s\n' "Небезопасные символы во входе" >&2
  exit 1
fi
```

### `IsSafeText text [max_len]`

Юзкейс: имя файла для архива или отчета.
Вход: строка и макс. длина. Выход: `0` — текст безопасен, `1` — иначе.

```bash
if ! IsSafeText "$filename" 64; then
  printf '%s\n' "Имя файла содержит запрещенные символы" >&2
  exit 1
fi
```

### `IsEmptyOrWhitespace text`

Юзкейс: комментарий в отчет/лог не должен быть пустым.
Вход: строка. Выход: `0` — только пробельные символы, `1` — иначе.

```bash
if IsEmptyOrWhitespace "$comment"; then
  comment="(no comment)"
fi
```

### `IsValueInArray value array_name`

Юзкейс: проверка CLI-действия перед выполнением.
Вход: значение и имя массива. Выход: `0` — найдено в массиве, `1` — иначе.

```bash
actions=("start" "stop" "restart")
if ! IsValueInArray "$action" actions; then
  printf '%s\n' "Доступные действия: start|stop|restart" >&2
  exit 1
fi
```

### `WhatIs value`

Юзкейс: разные ветки обработки без ручных регулярных выражений.
Вход: строка. Выход: печатает тип в stdout (`integer`, `ipv4`, `string` и т.д.).

```bash
case "$(WhatIs "$value")" in
  integer) timeout="$value" ;;
  ipv4) target_ip="$value" ;;
  *) printf '%s\n' "Неизвестный тип входа" >&2; exit 1 ;;
esac
```

## Поведение и ограничения

- `IsInteger` принимает целые числа со знаком, но без знака `+` и точки.
- `IsPositiveInteger` — строго больше нуля, `IsGreaterZero` — допускает ноль.
- `IsDate` проверяет формат `YYYY-MM-DD` без проверки фактической даты.
- `IsIPv6` и `IsIPv4CIDR` выполняют базовую проверку формата без углубленной
  валидации диапазонов.
- `IsIPv4CIDR` проверяет маски `0..32` без ведущих нулей.
- `IsBase64` проверяет только допустимые символы и корректность паддинга.
- `ContainsDangerousChars` ищет символы: `<`, `>`, `&`, `` ` ``, `$`, `;`, `\`.

