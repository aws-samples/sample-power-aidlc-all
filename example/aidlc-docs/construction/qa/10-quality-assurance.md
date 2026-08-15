# Phase 10 — Quality Assurance and Validation (Example)

> **Group:** Construction · **Greenfield phase 9 / Brownfield phase 10**
> **Purpose:** Run tests and reviews to validate the implementation against the
> requirements and design.

## 1. Test results (example run)

| Suite | Tests | Passed | Coverage |
|-------|-------|--------|----------|
| Unit | 142 | 142 | 84% |
| Integration | 38 | 38 | — |
| E2E (Playwright) | 6 | 6 | — |

## 2. Requirements validation

| Requirement | Validated by | Result |
|-------------|--------------|--------|
| FR-1 Login | US-1 E2E + unit | ✅ |
| FR-4 Move task | US-4 E2E | ✅ |
| FR-6 Pagination | Integration test (500 tasks) | ✅ |
| NFR-1 Board < 1s | Load test (k6), p95 = 640ms | ✅ |
| NFR-4 Stateless | Integration across 2 instances | ✅ |

## 3. Code review findings

- All UoWs reviewed by a second engineer.
- 3 issues found and fixed: missing index on `dueDate`, N+1 query in task list,
  and a missing rate-limit on login (US-1 AC).

## 4. Security checks

- Dependency scan: no high/critical CVEs.
- Auth: sessions HttpOnly + Secure; passwords bcrypt (cost 12).
- Input validation on all write endpoints.

## 5. Verdict

All MVP acceptance criteria pass. Ready to proceed to Operations.
