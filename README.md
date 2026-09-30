# DevOps Course 2026 — практические работы №1–4

**Алиев Никита Денисович, ЭФБО-01-24.**
Дисциплина: «Инструменты DevOps». Преподаватель: Гиматдинов Дамир Маратович.

## Работы

1. Git и GitHub: `about_me.md`, `goals.md`, первоначальные коммиты.
2. Ветки и Pull Request: `hobby.md`, `ide_notes.md`, `svn_comparison.md`.
   PR №1 объединён: https://github.com/NikiVence/devops-course-2026/pull/1.
3. Продвинутый Git: `calculator.py`, `README_CALC.md`, `.githooks/commit-msg`,
   теги `evidence/pr3-*`, журнал `reports/pr3/commands.txt`.
4. Контрольная работа выполняется в отдельном проекте `devops-kr-template`.

## Отчёты

Все четыре отчёта собраны в [reports/index.md](reports/index.md).
Для каждой работы подготовлены Word, PDF, Markdown и иллюстрации фактических журналов.

## Проверки и учебная история

```powershell
python -c "from calculator import add, subtract; print(add(2, 3), subtract(8, 3))"
git log --graph --oneline --all
git show evidence/pr3-calculator-dirty
git show evidence/pr3-calculator-clean
```

Сравнение merge и rebase сохранено в тегах `evidence/pr3-merge` и
`evidence/pr3-rebase`. Это реальные результаты упражнений, выполненных 24.09.2026.
История удалённого репозитория была пересоздана; 30.09.2026 локальная история
упражнений объединена с выполненными пользователем ПР1–2 без force push.
Файлы `about_me.md`, `goals.md`, `hobby.md` сохранены из версии пользователя.

## Проверка сообщений коммитов

```powershell
git config core.hooksPath .githooks
```

Хук `commit-msg` принимает Conventional Commits и отклоняет `bad message`.
Исходные результаты проверки: `reports/pr3/14_hook.txt`.

## Публикация и оставшиеся действия

Точный статус: [reports/remaining.md](reports/remaining.md).
Данные об участии другого студента, SSH и внешних репозиториях отмечены
по фактически проверенным результатам.
