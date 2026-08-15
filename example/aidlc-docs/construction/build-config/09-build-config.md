# Phase 9 — Build Configuration and Testing Strategies (Example)

> **Group:** Construction · **Greenfield phase 8 / Brownfield phase 9**
> **Purpose:** Set up build pipelines and the testing strategy.

## 1. Build

- **Package manager:** npm workspaces (`api`, `web`, `worker`).
- **Web build:** Vite → static assets to `web/dist`.
- **API/worker build:** `tsc` → `dist/`.
- **Container:** multi-stage Dockerfile per service.

## 2. Test strategy (test pyramid)

| Level | Tool | Scope | Target |
|-------|------|-------|--------|
| Unit | Jest | Services, pure functions | 80% line coverage |
| Integration | Jest + Testcontainers | API + Postgres + Redis | Critical paths |
| E2E | Playwright | Login → create task → move on board | MVP flows |

## 3. CI pipeline (example `.github/workflows/ci.yml`)

```yaml
name: ci
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 18 }
      - run: npm ci
      - run: npm run lint
      - run: npm run test -- --run
      - run: npm run build
```

## 4. Quality gates

- PRs must pass lint, unit, and integration tests before merge.
- Coverage below 80% fails the build.
- E2E suite runs on the main branch before deploy.
