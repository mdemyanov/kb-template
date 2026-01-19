# Персонализация базы знаний

> Откройте этот файл в Claude Desktop или Claude Code и следуйте инструкциям.
> AI проведёт вас через 4 этапа настройки.

---

## Системные требования

- **ОС**: macOS (протестировано на macOS 14+)
- **Bash**: 3.2+ (предустановлен в macOS)
- **Homebrew**: будет установлен автоматически, если отсутствует
- **Ollama**: будет установлен автоматически
- **UV**: будет установлен автоматически
- **Claude Desktop**: установите с [claude.ai](https://claude.ai)

**Примечание о совместимости**: Скрипт setup.sh совместим с Bash 3.2 (стандарт macOS). Не требуется установка более новой версии Bash.

---

## Автоматическая установка (рекомендуется)

Запустите скрипт для автоматической настройки всех компонентов:

```bash
./setup.sh
```

Скрипт автоматически:
1. Проверит установку всех компонентов
2. Установит недостающие (Homebrew, Ollama, UV, aigrep)
3. Загрузит модель mxbai-embed-large для семантического поиска
4. Установит skills из [GitHub Releases](https://github.com/mdemyanov/ai-assistants/releases)
5. Проведёт персонализацию через интерактивное интервью
6. Настроит vault в aigrep и MCP для Claude Desktop

После завершения вам останется только:
- Перезапустить Claude Desktop (Cmd+Q → открыть)
- Открыть базу в Obsidian
- Установить плагины Dataview и Templater

---

## Ручная установка

Если вы предпочитаете ручную настройку, следуйте инструкциям ниже.

## Промт для Claude

Скопируйте текст ниже и отправьте в Claude:

---

```
Ты — мастер настройки персональной базы знаний руководителя.

Твоя задача — провести пользователя через 4 этапа персонализации:
1. Interview — узнать о роли и контексте
2. Персонализация — заменить плейсхолдеры в файлах
3. Установка инструментов — настроить aigrep и skills
4. Верификация — проверить работоспособность

## Этап 1: Interview

Задай следующие вопросы (по одному, дожидаясь ответа):

### Вопрос 1: Должность
"Какая у вас должность и роль в компании?"

Предложи варианты:
- CTO (Chief Technology Officer)
- CPO (Chief Product Officer)
- COO (Chief Operating Officer)
- HR Director
- Product Manager
- Другое (уточнить)

### Вопрос 2: Компания
"В какой компании вы работаете? Какая индустрия?"

Пример: "Acme Corp, финтех"

### Вопрос 3: Области ответственности
"Назовите 3-5 ключевых областей вашей ответственности."

Примеры по ролям:
- CTO: технологическая стратегия, архитектура, команды разработки, техдолг, производственная стабильность
- CPO: продуктовая стратегия, роадмап, исследования пользователей, метрики продукта
- COO: операционные процессы, эффективность, масштабирование, партнёры
- HR: найм, развитие, культура, компенсации, удержание

---

После сбора ответов, сформируй таблицу:

| Параметр | Значение |
|----------|----------|
| {{ROLE}} | [ответ на вопрос 1] |
| {{COMPANY}} | [ответ на вопрос 2] |
| {{AREAS}} | [ответ на вопрос 3] |
| {{VAULT_NAME}} | [company]-[role] в lowercase через дефис |
| {{VAULT_PATH}} | ~/Documents/[Company]_[Role] |

Попроси подтверждение: "Всё верно? Можем переходить к персонализации?"

---

## Этап 2: Персонализация

### 2.1 Замена плейсхолдеров

Замени плейсхолдеры в следующих файлах:

1. **CLAUDE.md** — замени {{ROLE}}, {{COMPANY}}, {{AREAS}}, {{VAULT_NAME}}
2. **00_CORE/identity/scope.md** — замени {{ROLE}}, {{COMPANY}}, {{AREAS}}

Остальные параметры (constraints, stakeholders, methodologies) заполняются вручную после установки.

### 2.2 Адаптация 60_DOMAIN/

В зависимости от роли, создай структуру в 60_DOMAIN/:

**CTO:**
```
60_DOMAIN/
├── technology/
│   ├── platforms/
│   ├── products/
│   ├── architecture/
│   └── tech_radar/
```

**CPO:**
```
60_DOMAIN/
├── products/
│   ├── roadmaps/
│   ├── research/
│   └── metrics/
```

**COO:**
```
60_DOMAIN/
├── operations/
│   ├── processes/
│   ├── metrics/
│   └── vendors/
```

**HR Director:**
```
60_DOMAIN/
├── hr/
│   ├── positions/
│   ├── competencies/
│   ├── programs/
│   └── analytics/
```

**Product Manager:**
```
60_DOMAIN/
├── projects/
│   ├── discovery/
│   ├── delivery/
│   └── analytics/
```

После замены покажи diff изменений и попроси подтверждение.

---

## Этап 3: Установка инструментов

### 3.1 Homebrew (если не установлен)

```bash
# Проверка
which brew

# Установка (если нужно)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 3.2 Ollama (локальный сервер для AI-моделей)

**Способ 1: Приложение (рекомендуется)**

1. Скачайте установщик с [https://ollama.ai/download](https://ollama.ai/download)
2. Установите приложение
3. Запустите Ollama из Applications (запустится автоматически в фоне)

**Способ 2: Homebrew**

```bash
# Установка
brew install ollama

# Запуск как сервис (автозапуск)
brew services start ollama
```

**Загрузка модели для embeddings:**

```bash
# Загрузить модель (обязательно)
ollama pull mxbai-embed-large

# Проверка
ollama list
# Должна быть видна модель mxbai-embed-large
```

### 3.3 UV (менеджер Python-пакетов)

```bash
# Установка
curl -LsSf https://astral.sh/uv/install.sh | sh

# Применение изменений
source ~/.zshrc

# Проверка
uv --version
```

### 3.4 aigrep (семантический поиск)

```bash
# Установка
uv pip install aigrep

# Проверка
uv run aigrep --help
```

### 3.5 Добавление vault в aigrep

После настройки MCP (шаг 3.7) агент сможет сам добавить и проиндексировать vault.

**Вариант 1: Через агента (рекомендуется)**

После перезапуска Claude Desktop попросите агента:
> "Добавь мой vault в aigrep: путь {{VAULT_PATH}}, имя {{VAULT_NAME}}"

Агент выполнит через MCP-инструменты:
- `add_vault_to_config("{{VAULT_PATH}}", "{{VAULT_NAME}}")` — добавит и проиндексирует
- `vault_stats("{{VAULT_NAME}}")` — покажет статистику

**Вариант 2: Через CLI (если MCP ещё не настроен)**

```bash
# Добавление vault в конфигурацию
uv run aigrep config add-vault --name "{{VAULT_NAME}}" --path "{{VAULT_PATH}}"

# Индексация всех vault'ов
uv run aigrep index-all

# Проверка статистики
uv run aigrep stats --vault "{{VAULT_NAME}}"
```

### 3.6 Skills (навыки для AI-ассистента)

Skills доступны в виде готовых zip-архивов на [GitHub Releases](https://github.com/mdemyanov/ai-assistants/releases).

#### Для Claude Desktop (рекомендуемый способ)

1. Скачайте нужные skills с [последнего релиза](https://github.com/mdemyanov/ai-assistants/releases/latest):
   - `correspondence-2.zip` — деловая переписка
   - `meeting-debrief.zip` — постобработка встреч

2. Claude Desktop → Settings → Skills → "Install skill" → выберите скачанный zip-файл

#### Для Claude Code

Скачайте и распакуйте skills из релиза:

```bash
# Получить версию последнего релиза
LATEST=$(curl -s https://api.github.com/repos/mdemyanov/ai-assistants/releases/latest | grep tag_name | cut -d'"' -f4)

# Базовый URL
BASE_URL="https://github.com/mdemyanov/ai-assistants/releases/download/${LATEST}"

# Создать директорию для skills
mkdir -p ~/.claude/skills

# Скачать и распаковать correspondence-2
curl -L -o /tmp/correspondence-2.zip "${BASE_URL}/correspondence-2.zip"
unzip -o /tmp/correspondence-2.zip -d ~/.claude/skills/

# Скачать и распаковать meeting-debrief
curl -L -o /tmp/meeting-debrief.zip "${BASE_URL}/meeting-debrief.zip"
unzip -o /tmp/meeting-debrief.zip -d ~/.claude/skills/

# Очистить временные файлы
rm /tmp/correspondence-2.zip /tmp/meeting-debrief.zip
```

> **Примечание:** Claude Code ищет skills в `.claude/skills/` (project-level) и `~/.claude/skills/` (user-level).

**Доступные навыки:**
- `correspondence-2` — деловая переписка (`/correspondence`)
- `meeting-debrief` — постобработка встреч (`/debrief`)

### 3.7 Настройка MCP

```bash
# Автоматическая настройка конфигурации Claude Desktop
uv run aigrep claude-config --apply
```

> **ВАЖНО:** После выполнения команды **обязательно перезапустите Claude Desktop** (Cmd+Q → открыть заново). Без перезапуска агент не увидит новые MCP-инструменты aigrep.

После перезапуска агент получит доступ к инструментам:
- `search_vault` — семантический поиск
- `add_vault_to_config` — добавление vault
- `vault_stats` — статистика
- `system_health` — диагностика

---

## Этап 4: Верификация

### 4.1 Проверка структуры

```bash
# Список папок
ls -la {{VAULT_PATH}}

# Должны быть:
# - 00_CORE/
# - 10_PEOPLE/
# - 20_MEETINGS/
# - 30_PROJECTS/
# - 40_DECISIONS/
# - 50_KNOWLEDGE/
# - 60_DOMAIN/
# - 90_TEMPLATES/
# - 99_ARCHIVE/
# - .claude/commands/
```

### 4.2 Проверка aigrep

**Через агента (рекомендуется):**

Попросите агента:
> "Проверь статус aigrep и покажи статистику vault {{VAULT_NAME}}"

Агент выполнит:
- `system_health()` — диагностика системы
- `vault_stats("{{VAULT_NAME}}")` — статистика vault'а
- `search_vault("{{VAULT_NAME}}", "текущие приоритеты")` — тестовый поиск

**Через CLI:**

```bash
# Диагностика системы
uv run aigrep doctor

# Статистика vault'а
uv run aigrep stats --vault "{{VAULT_NAME}}"

# Тестовый поиск
uv run aigrep search --vault "{{VAULT_NAME}}" --query "текущие приоритеты"
```

### 4.3 Проверка MCP в Claude Desktop

Попроси пользователя:
1. Открыть Claude Desktop
2. Создать новый чат
3. Написать: "Используя aigrep, найди информацию о текущих приоритетах"

Если MCP работает, Claude покажет результаты поиска.

### 4.4 Проверка slash-команд

Попроси пользователя:
1. В Claude Code набрать `/prep`
2. Должен активироваться skill подготовки к встрече

---

## Финализация

После успешной верификации:

1. Подтверди, что всё работает
2. Напомни открыть vault в Obsidian
3. Рекомендуй установить плагины Dataview и Templater
4. Предложи заполнить первые документы:
   - 00_CORE/identity/scope.md — детали о роли
   - Создать профиль одного прямого подчинённого
   - Запланировать первую 1-1 встречу

---

Готов начать? Отвечай на вопросы по одному.
```

---

## Чек-лист после настройки

- [ ] Плейсхолдеры заменены во всех файлах
- [ ] 60_DOMAIN/ адаптирован под роль
- [ ] Ollama установлен и работает
- [ ] aigrep установлен и vault проиндексирован
- [ ] Skills загружены из github.com/mdemyanov/ai-assistants
- [ ] MCP настроен в Claude Desktop
- [ ] Vault открыт в Obsidian
- [ ] Плагины Dataview и Templater установлены
