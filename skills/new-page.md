## New Page Build Checklist

### Backend
1. Create query file in `queries/[name].js` with pg-promise (`db.any()`, `db.one()`, etc.)
2. Create controller in `controllers/[name]Controller.js` — validate input, call queries, return JSON
3. Create or update route file in `routes/[name].js` — apply `authenticateToken` middleware
4. Register route in `app.js`

### Frontend
1. Create page directory: `src/pages/[Name]/`
2. Create `index.jsx` with the page component
3. Create `[Name].css` for page-specific styles (use Tailwind utilities where possible)
4. Add route in `src/App.jsx` with appropriate route guard (`ProtectedRoute`, `AdminRoute`, etc.)
5. Wire up API calls using React Query (`useQuery` / `useMutation`)
6. Use existing shadcn/ui components from `src/components/ui/`
7. Check permissions with `usePermissions()` hook if the page is role-restricted

### Patterns to Follow
- Auth: `useAuthStore((s) => s.user)` for current user, `useAuthStore((s) => s.token)` for token
- API base: import from `utils/api.js`, uses `VITE_API_URL`
- State: React Query for server state, Zustand for auth/nav only
- Styling: Tailwind + shadcn/ui + Radix. Design tokens in `index.css` `:root`
- Path alias: `@/*` maps to `./src/*`
