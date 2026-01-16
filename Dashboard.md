---
type: dashboard
title: Dashboard
tags:
  - dashboard
  - index
domain: general
created: {{date}}
updated: {{date}}
---

# Dashboard

> Главная страница базы знаний

---

## Быстрые ссылки

| | |
|---|---|
| [[00_CORE/strategy/current_priorities\|Текущие приоритеты]] | [[00_CORE/identity/scope\|Роль и области]] |
| [[00_CORE/identity/constraints\|Ограничения]] | [[00_CORE/stakeholders/index\|Стейкхолдеры]] |

---

## Ближайшие 1-1

```dataview
TABLE WITHOUT ID
  link(file.link, person) as "С кем",
  date as "Дата",
  status as "Статус"
FROM "10_PEOPLE"
WHERE type = "1-1" AND status != "done"
SORT date ASC
LIMIT 5
```

---

## Команда (прямые подчинённые)

```dataview
TABLE WITHOUT ID
  link(file.link, name) as "Имя",
  role as "Роль",
  team as "Команда"
FROM "10_PEOPLE"
WHERE type = "person" AND reporting = "direct"
SORT name ASC
```

---

## Активные проекты

```dataview
TABLE WITHOUT ID
  link(file.link, id) as "ID",
  title as "Название",
  status as "Статус",
  priority as "Приоритет",
  owner as "Владелец"
FROM "30_PROJECTS/active"
WHERE type = "project"
SORT priority ASC
```

---

## Критичные задачи

```dataview
TABLE WITHOUT ID
  title as "Задача",
  owner as "Ответственный",
  due as "Срок",
  project as "Проект"
FROM ""
WHERE type = "task" AND priority = "critical" AND status != "done"
SORT due ASC
LIMIT 5
```

---

## Последние ADR

```dataview
TABLE WITHOUT ID
  link(file.link, id) as "ADR",
  title as "Название",
  date as "Дата",
  status as "Статус"
FROM "40_DECISIONS/adr"
WHERE type = "adr"
SORT date DESC
LIMIT 5
```

---

## Ближайшие встречи комитетов

```dataview
TABLE WITHOUT ID
  link(file.link, title) as "Встреча",
  date as "Дата",
  meeting_type as "Тип"
FROM "20_MEETINGS"
WHERE type = "meeting" OR type = "committee-meeting"
SORT date ASC
LIMIT 5
```

---

## Навигация по структуре

| Раздел | Описание |
|--------|----------|
| [[00_CORE/\|00_CORE]] | Ядро: идентичность, стейкхолдеры, стратегия |
| [[10_PEOPLE/\|10_PEOPLE]] | Профили людей и 1-1 встречи |
| [[20_MEETINGS/\|20_MEETINGS]] | Комитеты и сессии |
| [[30_PROJECTS/\|30_PROJECTS]] | Проекты: активные, бэклог, архив |
| [[40_DECISIONS/\|40_DECISIONS]] | ADR и Decision Journal |
| [[50_KNOWLEDGE/\|50_KNOWLEDGE]] | Методологии и глоссарий |
| [[60_DOMAIN/\|60_DOMAIN]] | Предметная область |
| [[90_TEMPLATES/\|90_TEMPLATES]] | Шаблоны документов |
| [[99_ARCHIVE/\|99_ARCHIVE]] | Архив |

---

## Статистика

### Документы по типам

```dataviewjs
const types = ["person", "project", "adr", "meeting", "1-1"];
const counts = {};

for (const type of types) {
  counts[type] = dv.pages().where(p => p.type === type).length;
}

dv.table(
  ["Тип", "Количество"],
  Object.entries(counts).map(([type, count]) => [type, count])
);
```

### 1-1 за последний месяц

```dataviewjs
const oneMonthAgo = dv.date("today").minus({months: 1});
const meetings = dv.pages('"10_PEOPLE"')
  .where(p => p.type === "1-1" && p.date >= oneMonthAgo)
  .length;

dv.paragraph(`Проведено 1-1 за месяц: **${meetings}**`);
```
