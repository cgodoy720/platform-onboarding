## Integration Build Checklist

### Setup
1. Add new env vars to `.env` and `.env.example` (API keys, webhook URLs, etc.)
2. Create service file in `services/[name]Service.js`
3. Initialize the client/SDK in the service constructor
4. Export a singleton instance

### Service Structure
- Follow the pattern in `services/slackService.js` or `services/aiClient.js`
- Wrap all external calls in try/catch with meaningful error messages
- Log request/response at debug level, errors at error level
- Handle rate limits with exponential backoff (see `utils/retryUtils.js` in pilot-client for patterns)

### API Layer
1. Create controller in `controllers/[name]Controller.js`
2. Create route in `routes/[name].js`
3. Register in `app.js`
4. If receiving webhooks: add signature verification middleware (see `middleware/slackSignatureVerification.js`)

### Frontend (if needed)
1. Add API functions to a service file in `src/services/`
2. Create React Query hooks for the integration
3. Build UI components using existing shadcn/ui primitives

### Testing Strategy
- Mock the external service in tests
- Test error handling paths (timeout, auth failure, rate limit)
- Test webhook signature verification with known-good and bad signatures
