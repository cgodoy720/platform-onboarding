You are starting a feature kickoff session. Enter plan mode before doing anything else.

## Setup

Read these files before speaking to the developer:
- `test-pilot-server/CLAUDE.md`
- `pilot-client/CLAUDE.md`
- `test-pilot-server/database-schema.sql` (if it exists)

## Interview

Greet the developer in plain English. Then ask these questions conversationally, adapting based on their answers:

1. **What are you building?** (free description in plain English)
2. **Who is this for?** (which user role: builder, staff, admin, applicant, volunteer, etc.)
3. **What should it do?** (core behavior — what triggers it, what it produces)
4. **Does it need to show something on screen, or run in the background?**
   - Screen → **New Page**
   - Background/scheduled → **Cron Job**
   - Connects to an external service → **Integration**
5. **Does it need to read or write to the database?** (surface relevant tables you found in the schema)
6. **Are there existing features it should connect to?** (reference what you found in the CLAUDE.md files)
7. **Anything else we should know?** (edge cases, constraints, deadlines)

## Classify and Route

Based on the answers, classify the build as one of:

| Build Type | Signals |
|-----------|---------|
| **New Page** | "show", "dashboard", "page", "view", needs UI |
| **Integration** | external service, webhook, API key, "connect to X" |
| **Cron Job** | "daily", "weekly", "every night", "automated", "reminder", "report" |

## Produce the Spec

Output a structured spec:

```
FEATURE PLAN: [Feature Name]
Type: [New Page / Integration / Cron Job]

WHAT IT DOES
[2-3 sentence plain English summary]

FILES TO CREATE
  Backend:
    - controllers/[name]Controller.js
    - queries/[name].js
    - routes/[name].js (or add to existing)
  Frontend (if applicable):
    - src/pages/[Name]/index.jsx
    - src/pages/[Name]/[Name].css

FILES TO MODIFY
  - app.js (register new route)
  - src/App.jsx (add route)

DATABASE
  Tables used: [from schema]
  New tables needed: [if any]

TASKS (in order)
  [ ] 1. ...
  [ ] 2. ...
  [ ] 3. ...

Ready to start? Say "go" and I'll begin with Task 1.
```

Wait for the developer to confirm before writing any code.
