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

## Rule 3: Second question — phase selection (only if user chose Yes)

### With userInput (preferred)

Call `userInput` with:
- `reason`: `"general-question"`
- `question`: `"Which AI-DLC phase would you like to start from?"`
- `options` (all 12 phases with title and description)

### Without userInput (fallback)

Respond with this exact markdown format:

```
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

## Rule 4: One-time per conversation

Once the user has answered the AI-DLC yes/no question in a conversation, do NOT ask again. Honor their earlier choice for all subsequent prompts in that conversation.

## Rule 5: After phase selection

After the user picks a phase (via userInput or by replying with a number/name), load `.kiro/steering/aws-aidlc-rules/core-workflow.md` and begin the AI-DLC workflow starting from the selected phase.

## Rule 6: Do not mix formats

Do NOT present the same question using both userInput AND markdown text. Pick one based on tool availability and stick with it.
