# Персонализация базы знаний

> Откройте этот файл в Claude Desktop или Claude Code и следуйте инструкциям.
> AI проведёт вас через 4 этапа настройки.

---

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

### Вопрос 4: Стейкхолдеры
"Кто ваш непосредственный руководитель и ключевые стейкхолдеры?"

Пример: "CEO, CPO, Tech Leads, руководители продуктовых команд"

### Вопрос 5: Ограничения ("красные линии")
"Какие ограничения нельзя нарушать в вашей работе?"

Примеры:
- Единая платформа — все продукты на одной платформе
- In-house разработка ядра — аутсорс запрещён
- Регуляторные требования — GDPR, 152-ФЗ
- Бюджетные лимиты

### Вопрос 6: Методологии
"Какие методологии и фреймворки вы используете в работе?"

Примеры: OKR, ADR, 1-1 meetings, Agile/Scrum, ITIL, DDD, Jobs to Be Done

---

После сбора ответов, сформируй таблицу:

| Параметр | Значение |
|----------|----------|
| {{ROLE}} | [ответ на вопрос 1] |
| {{COMPANY}} | [ответ на вопрос 2] |
| {{AREAS}} | [ответ на вопрос 3] |
| {{STAKEHOLDERS}} | [ответ на вопрос 4] |
| {{CONSTRAINTS}} | [ответ на вопрос 5] |
| {{METHODOLOGIES}} | [ответ на вопрос 6] |
| {{VAULT_NAME}} | [company]-[role] в lowercase через дефис |
| {{VAULT_PATH}} | ~/Documents/[Company]_[Role] |

Попроси подтверждение: "Всё верно? Можем переходить к персонализации?"

---

## Этап 2: Персонализация

### 2.1 Замена плейсхолдеров

Замени плейсхолдеры в следующих файлах:

1. **CLAUDE.md** — замени {{ROLE}}, {{COMPANY}}, {{AREAS}}, {{VAULT_NAME}}
2. **CLAUDE_DESKTOP.md** — замени все плейсхолдеры
3. **00_CORE/identity/scope.md** — замени {{ROLE}}, {{COMPANY}}, {{AREAS}}
4. **00_CORE/identity/constraints.md** — замени {{CONSTRAINTS}}
5. **00_CORE/stakeholders/index.md** — замени {{STAKEHOLDERS}}

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

#### Для Claude Desktop (рекомендуемый способ)

Skills устанавливаются через интерфейс приложения:

1. Клонируй репозиторий с навыками:
```bash
git clone https://github.com/mdemyanov/ai-assistants.git /tmp/ai-assistants
```

2. Создай zip-архивы для каждого skill:
```bash
cd /tmp/ai-assistants/skills

# Создать архивы на рабочем столе
zip -r ~/Desktop/meeting-prep.zip meeting-prep/
zip -r ~/Desktop/meeting-debrief.zip meeting-debrief/
zip -r ~/Desktop/correspondence-2.zip correspondence-2/
zip -r ~/Desktop/public-speaking.zip public-speaking/
```

3. Откройй Claude Desktop → Settings → Skills → "Install skill" → выбери каждый zip-файл

4. Очисти временные файлы:
```bash
rm -rf /tmp/ai-assistants
rm ~/Desktop/meeting-*.zip ~/Desktop/correspondence-2.zip ~/Desktop/public-speaking.zip
```

#### Для Claude Code

Skills устанавливаются в проектную или пользовательскую директорию:

```bash
# Клонировать репозиторий
git clone https://github.com/mdemyanov/ai-assistants.git /tmp/ai-assistants

# Опция 1: Project-level (рекомендуется для команды)
mkdir -p .claude/skills
cp -R /tmp/ai-assistants/skills/meeting-prep .claude/skills/
cp -R /tmp/ai-assistants/skills/meeting-debrief .claude/skills/
cp -R /tmp/ai-assistants/skills/correspondence-2 .claude/skills/

# Опция 2: User-level (для личного использования)
mkdir -p ~/.claude/skills
cp -R /tmp/ai-assistants/skills/meeting-prep ~/.claude/skills/
cp -R /tmp/ai-assistants/skills/meeting-debrief ~/.claude/skills/
cp -R /tmp/ai-assistants/skills/correspondence-2 ~/.claude/skills/

# Очистить временные файлы
rm -rf /tmp/ai-assistants
```

> **Примечание:** Claude Code ищет skills в `.claude/skills/` (project-level) и `~/.claude/skills/` (user-level). Путь `.github/skills` не поддерживается.

**Установленные навыки:**
- `meeting-prep` — подготовка к встречам (`/prep`)
- `meeting-debrief` — постобработка встреч (`/debrief`)
- `correspondence-2` — деловая переписка (`/correspondence`)
- `public-speaking` — подготовка выступлений

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
