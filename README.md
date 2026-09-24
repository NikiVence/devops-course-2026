# DevOps — практические работы №1 и №2

Алиев Никита, ЭФБО-01-24. Дисциплина: «Инструменты девопс», 2026/2027.

- `about_me.md` — информация о студенте и технологии.
- `goals.md` — три цели на семестр.
- `hobby.md` — идея системы консультаций, в ветке `feature/hobby-project` до review.
- `ide_notes.md` — сравнение работы с Git в IDE и терминале.
- `svn_comparison.md` — ответы на три вопроса о SVN.
- `control_questions.md` — ответы к защите обеих практических работ.
- `reports/` — отчёты, фактические протоколы и оставшиеся действия.

## Локальная демонстрация rebase

```powershell
git switch practice/rebase-playground
git log --oneline main..HEAD
git switch main
```

Ветка упражнения не публикуется согласно домашнему заданию.
Перед сдачей проверьте оставшиеся действия в `reports/remaining.md`.

## Практическая работа №3

Калькулятор: `calculator.py`. Протоколы и отчёт: `reports/pr3/`.
Для включения проверки сообщений после клонирования: `git config core.hooksPath .githooks`.

## Multi-remote test

Основной репозиторий и зеркало синхронизируются одной командой `git push origin main`.
