---
inclusion: always
---

# AI-DLC Interaction Rules

When the AI-DLC workflow is active in this workspace (when `.kiro/steering/aws-aidlc-rules/core-workflow.md` exists) and the AI-DLC prompt hook (`.kiro/hooks/aidlc-workflow-prompt.kiro.hook`) fires, follow these rules.

## Rule 1: Prefer userInput, fall back to markdown

**If the `userInput` tool is available** (Spec mode): Use it to present choices as clickable options.

**If the `userInput` tool is NOT available** (Vibe mode): Present options as a clean, numbered markdown list and ask the user to reply with the option number or name.

Never mix the two approaches in the same question.

## Rule 2: First question — AI-DLC yes/no

### With userInput (preferred)

Call `userInput` with:
- `reason`: `"general-question"`
- `question`: `"I see AI-DLC is set up in this workspace. Would you like to use the AI-DLC workflow for this task?"`
- `options`:
  - `{"title": "Yes, use AI-DLC", "description": "Activate the AI-DLC workflow and select a starting phase", "recommended": true}`
  - `{"title": "No thanks", "description": "Proceed normally without AI-DLC"}`

### Without userInput (fallback)

Respond with this exact markdown format:

```
I see AI-DLC is set up in this workspace. Would you like to use the AI-DLC workflow for this task?

1. **Yes, use AI-DLC** — Activate the AI-DLC workflow and select a starting phase
2. **No thanks** — Proceed normally without AI-DLC

Reply with the number (1 or 2) or the option name.
```

## Rule 3: Workspace detection (only if user chose Yes)

Before presenting the phase list, run workspace detection per `.kiro/aws-aidlc-rule-details/inception/workspace-detection.md`. Do this silently — **do not ask the user**:

1. Scan the workspace (excluding `.kiro/` and `aidlc-docs/`) for source code files (.java, .py, .js, .ts, .jsx, .tsx, .kt, .kts, .scala, .groovy, .go, .rs, .rb, .php, .c, .h, .cpp, .hpp, .cc, .cs, .fs) and build files (pom.xml, package.json, build.gradle, Cargo.toml, go.mod, Gemfile, requirements.txt, pyproject.toml, etc.).
2. Classify:
   - **Greenfield** — no source or build files found.
   - **Brownfield** — source or build files found.

## Rule 4: Second question — phase selection

Use the detected project type to determine the options. Brownfield adds **Reverse Engineering** at the top of the list.

### With userInput (preferred)

Call `userInput` with:
- `reason`: `"general-question"`
- `question`: `"Detected <greenfield|brownfield> project. Which AI-DLC phase would you like to start from?"` (substitute the detected type)
- `options` for **Greenfield** (12 phases, first is recommended). Each option `title` is prefixed with its number:
  1. `"1. Requirements analysis and validation"`
  2. `"2. User story creation"`
  3. `"3. Application Design"`
  4. `"4. Creating units of work for parallel development"`
  5. `"5. Risk assessment and complexity evaluation"`
  6. `"6. Detailed component design"`
  7. `"7. Code generation and implementation"`
  8. `"8. Build configuration and testing strategies"`
  9. `"9. Quality assurance and validation"`
  10. `"10. Deployment automation and infrastructure"`
  11. `"11. Monitoring and observability setup"`
  12. `"12. Production readiness validation"`
- `options` for **Brownfield** (13 phases, Reverse Engineering recommended). Each option `title` is prefixed with its number:
  1. `"1. Reverse Engineering"` — Analyze existing codebase to reconstruct requirements, architecture, and design artifacts
  2. `"2. Requirements analysis and validation"`
  3. `"3. User story creation"`
  4. `"4. Application Design"`
  5. `"5. Creating units of work for parallel development"`
  6. `"6. Risk assessment and complexity evaluation"`
  7. `"7. Detailed component design"`
  8. `"8. Code generation and implementation"`
  9. `"9. Build configuration and testing strategies"`
  10. `"10. Quality assurance and validation"`
  11. `"11. Deployment automation and infrastructure"`
  12. `"12. Monitoring and observability setup"`
  13. `"13. Production readiness validation"`

### Without userInput (fallback)

For **Greenfield**, respond with:

```
Detected: Greenfield project (no existing code).

Which AI-DLC phase would you like to start from?

1. **Requirements analysis and validation** — Gather, analyze, and validate project requirements
2. **User story creation** — Create user stories and acceptance criteria
3. **Application Design** — Design the application architecture
4. **Creating units of work for parallel development** — Break down work into parallelizable tasks
5. **Risk assessment and complexity evaluation** — Identify risks and estimate complexity
6. **Detailed component design** — Design individual components and interfaces
7. **Code generation and implementation** — Generate and implement code
8. **Build configuration and testing strategies** — Set up build pipelines and test frameworks
9. **Quality assurance and validation** — Run tests and code reviews
10. **Deployment automation and infrastructure** — Automate deployment and provision infrastructure
11. **Monitoring and observability setup** — Set up logging, metrics, and dashboards
12. **Production readiness validation** — Final checks before going live

Reply with the number (1-12) or the phase name.
```

For **Brownfield**, respond with:

```
Detected: Brownfield project (existing code found).

Which AI-DLC phase would you like to start from?

1. **Reverse Engineering** — Analyze existing codebase to reconstruct requirements, architecture, and design artifacts
2. **Requirements analysis and validation** — Gather, analyze, and validate project requirements
3. **User story creation** — Create user stories and acceptance criteria
4. **Application Design** — Design the application architecture
5. **Creating units of work for parallel development** — Break down work into parallelizable tasks
6. **Risk assessment and complexity evaluation** — Identify risks and estimate complexity
7. **Detailed component design** — Design individual components and interfaces
8. **Code generation and implementation** — Generate and implement code
9. **Build configuration and testing strategies** — Set up build pipelines and test frameworks
10. **Quality assurance and validation** — Run tests and code reviews
11. **Deployment automation and infrastructure** — Automate deployment and provision infrastructure
12. **Monitoring and observability setup** — Set up logging, metrics, and dashboards
13. **Production readiness validation** — Final checks before going live

Reply with the number (1-13) or the phase name.
```

## Rule 5: One-time per conversation

Once the user has answered the AI-DLC yes/no question in a conversation, do NOT ask again. Honor their earlier choice for all subsequent prompts in that conversation.

## Rule 6: Context gathering (after phase selection)

After the user picks a phase, silently scan the **entire workspace** for artifacts that could inform earlier phases. **Do not prompt the user.** Do not ask whether to backfill or rerun earlier phases.

1. Use the same ordered phase list shown to the user (greenfield 12 or brownfield 13). If the user picked phase N, the prior phases are 1..N-1. If N == 1, skip this rule.

2. Look in **all** of these locations, not only `aidlc-docs/`:

   **AI-DLC canonical:** `aidlc-docs/inception/{reverse-engineering,requirements,user-stories,design}/`, `aidlc-docs/construction/{units-of-work,risk-assessment,component-design,code-generation,build-config,qa}/`, `aidlc-docs/operations/{deployment,monitoring,production-readiness}/`, `aidlc-docs/aidlc-state.md`.

   **Workspace-root docs:** `README.md`, `ARCHITECTURE.md`, `DESIGN.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `SECURITY.md`, `RFC*.md`, `PRD*.md`.

   **Generic doc directories:** `docs/`, `documentation/`, `doc/`, `specs/`, `spec/`, `design/`, `architecture/`, `requirements/`, `rfcs/`, `prds/`, `user-stories/` (markdown, AsciiDoc `.adoc`, reStructuredText `.rst`).

   **ADRs:** `docs/adr/`, `architecture/decisions/`, `adr/`, `decisions/`.

   **API and interface specs:** `openapi.yaml`, `openapi.yml`, `swagger.yaml`, `swagger.json`, `*.openapi.yaml`, `schema.graphql`, `*.proto`, `*.thrift`, `*.avsc`, `api/`, `schema/`, `schemas/`, `interfaces/`.

   **Kiro-specific:** `.kiro/specs/` (existing Kiro specs are high-value design context), `.kiro/steering/`.

   **Security:** `.threatmodel/`, `threat-model/`, `security/`, `SECURITY.md`.

   **Build/test/CI/CD:** `package.json`, `pom.xml`, `build.gradle`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `requirements.txt`, `Gemfile`, `*.csproj`, `Dockerfile`, `docker-compose*.yml`, `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, `azure-pipelines.yml`, `buildspec.yml`, `Makefile`, `Taskfile.yml`.

   **Infrastructure-as-code:** `terraform/`, `cdk/`, `cloudformation/`, `infra/`, `infrastructure/`, `deploy/`, `k8s/`, `kubernetes/`, `helm/`.

   **Source code (brownfield):** `src/`, `lib/`, `app/`, `packages/`, `services/`, `components/`, `modules/`, `cmd/`, `internal/`, `pkg/`. Read enough to identify modules, public interfaces, frameworks, and entry points; do not exhaustively read every file.

   **Tests:** `tests/`, `test/`, `__tests__/`, `spec/`, `e2e/`, `integration-tests/`.

   **Operations/observability:** `monitoring/`, `observability/`, `dashboards/`, `alerts/`, `runbooks/`, `sre/`, `ops/`.

3. **Exclude:** `node_modules/`, `vendor/`, `.git/`, `dist/`, `build/`, `target/`, `out/`, `.next/`, `.nuxt/`, `.venv/`, `venv/`, `__pycache__/`, `.pytest_cache/`, `.mypy_cache/`, `coverage/`, `.idea/`, `generated/`, `.terraform/`, `.gradle/`, `.cache/`. Skip lockfiles and binary assets. Skip files larger than ~200 KB unless they are clearly authoritative specs.

4. **Map evidence to phases.** A single document can inform multiple phases:
   - README, PRDs, RFCs, requirements/* → Requirements analysis
   - user-stories/, stories/, *.story.md → User story creation
   - ARCHITECTURE.md, design/, architecture/, ADRs, OpenAPI/proto → Application Design and Detailed component design
   - units-of-work/, project boards, ROADMAP.md → Units of work
   - threat models, SECURITY.md, risk-assessment/ → Risk assessment
   - src/, lib/, app/ → Code generation
   - build configs, CI files, Dockerfile, package manifests → Build configuration
   - tests/, coverage reports → Quality assurance
   - terraform/, cdk/, k8s/, deploy/ → Deployment automation
   - monitoring/, dashboards/, alerts/ → Monitoring and observability
   - runbooks/, SRE docs, production-readiness/ → Production readiness validation

5. For brownfield projects, `aidlc-docs/inception/reverse-engineering/` (if present) is your primary context for the existing codebase.

6. Briefly tell the user (one short paragraph, **not** a prompt) what was found, e.g.: _"Found requirements (README.md + docs/requirements.md), user stories (3 in docs/user-stories/), and existing architecture notes (ARCHITECTURE.md, docs/adr/). No risk assessment or units-of-work yet. Proceeding with <selected phase> using this context."_ If nothing was found, say so once and proceed.

## Rule 7: After phase selection

Once context gathering is done, load `.kiro/steering/aws-aidlc-rules/core-workflow.md` and execute the AI-DLC workflow starting from the selected phase, using the gathered context to inform the work. For **Reverse Engineering**, also consult `.kiro/aws-aidlc-rule-details/inception/reverse-engineering.md` if present.

## Rule 8: Do not mix formats

Do NOT present the same question using both userInput AND markdown text. Pick one based on tool availability and stick with it.
