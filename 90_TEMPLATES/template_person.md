---
type: person
id: "{{id}}"
name: "{{name}}"
role: ""
team: ""
reporting: direct | functional | external
since: {{date:YYYY-MM-DD}}
status: active
domain: general
tags:
  - person
---

> **Инструкция по созданию:**
> 1. Определить `id` по схеме: **первая буква имени + фамилия** транслитом
>    - Пример: "Алексей Иванов" → `aivanov`
>    - Пример: "Ольга Петрова" → `opetrova`
> 2. Создать папку: `10_PEOPLE/{id}/`
> 3. Скопировать этот файл как: `10_PEOPLE/{id}/{id}.md`
> 4. Заполнить frontmatter
> 5. Использовать для ссылок: `[[10_PEOPLE/{id}/{id}|Имя]]`

# {{name}}

**Должность:**
**Подчинение:** Прямое / Функциональное / Внешний
**Команда:**
**В компании с:** `= this.since`

---

## Зона ответственности

-

---

## Подчинённые

| Имя | Роль | Примечание |
|-----|------|------------|
| | | |

---

## Текущие цели

| Цель | Срок | Статус |
|------|------|--------|
| | | |

---

## Сильные стороны

-

---

## Зоны развития

-

---

## Заметки

>

---

## Участие в проектах

```dataview
TABLE WITHOUT ID
  link(file.link, id) as "Проект",
  title as "Название",
  status as "Статус",
  project_type as "Тип"
FROM "30_PROJECTS/active"
WHERE type = "project" AND contains(file.outlinks, this.file.link)
SORT status ASC
```

---

## История 1-1

```dataview
TABLE date as "Дата", status as "Статус"
FROM "10_PEOPLE"
WHERE contains(file.path, this.file.folder) AND type = "1-1"
SORT date DESC
LIMIT 10
```

---

## История изменений

| Дата | Изменения |
|------|-----------|
| {{date:DD.MM.YYYY}} | Создание профиля |
