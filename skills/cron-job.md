## Cron Job Build Checklist

### Setup
1. Create service file in `services/[name]Service.js`
2. Follow the pattern in `services/emailAutomationService.js` as a template
3. Add an env var gate: `process.env.ENABLE_[NAME]_CRON=true` to enable/disable

### Service Structure
- Export `start()` and `stop()` methods
- Use `node-cron` for scheduling (already a project dependency)
- Make the job **idempotent** — running it twice should produce the same result
- Add logging at start, completion, and error of each run
- Track last run time and result

### Registration
1. Import the service in `app.js`
2. Call `service.start()` gated by the env var (see how `ENABLE_EMAIL_CRON_JOBS` is used in `app.js`)
3. Add the env var to `.env.example`

### Common Patterns
- Daily jobs: `'0 9 * * *'` (9 AM)
- Weekly jobs: `'0 18 * * 5'` (Friday 6 PM)
- Hourly: `'0 * * * *'`
- Use `services/emailAutomationService.js` as reference for email-sending cron jobs
- Use `services/slackService.js` for Slack-posting cron jobs

### Error Handling
- Wrap the entire job in try/catch
- Log errors but don't crash the server
- Consider a dead-letter mechanism for failed items (log to DB or file)

### Database Queries
- If the job processes records, use a `processed` flag or timestamp to avoid reprocessing
- Use transactions for multi-step operations
