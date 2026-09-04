# Orchestrator Agent — Chief of Staff

> A multi-agent orchestration pattern for NanoClaw: one high-thinking orchestrator agent that routes, tracks, and synthesizes work from a pool of cheaper worker agents. The human talks only to the orchestrator.

## Architecture

```
                    ┌──────────────────────────────────┐
                    │      Human (via any channel)      │
                    └──────────────┬───────────────────┘
                                   │
                         ┌─────────▼──────────┐
                         │   Chief of Staff   │
                         │  (Orchestrator)    │
                         │  claude-sonnet-4   │ ← high-end model
                         └──┬──────┬──────┬──┘
                            │      │      │
              ┌─────────────┘      │      └─────────────┐
              ▼                    ▼                    ▼
     ┌─────────────────┐  ┌────────────────┐  ┌──────────────────┐
     │    Research     │  │  Travel-Guide  │  │  Terminal Agent  │
     │ (Worker)        │  │ (Worker)       │  │ (Worker)         │
     │ qwen3-coder-30b │  │ qwen3-coder-30b│  │ qwen3-coder-30b  │
     │ cheap tier      │  │ cheap tier     │  │ cheap tier       │
     └────────┬────────┘  └───────┬────────┘  └────────┬─────────┘
              │                   │                     │
              └───────────────────┼─────────────────────┘
                                  │
                   ┌──────────────▼──────────────┐
                   │   Results flow back to      │
                   │   orchestrator via agent-    │
                   │   to-agent destinations     │
                   └─────────────────────────────┘
```

### Key Design Decisions

- **Single point of entry** — The human sends one request, gets one synthesized response. The orchestrator hides the multi-agent machinery.
- **Model tier separation** — The orchestrator runs a high-end reasoning model (`claude-sonnet-4-20250514`) for planning, task decomposition, and synthesis. Workers run cheap models (`qwen3-coder-30b`) for execution.
- **Agent-to-agent messaging** — All communication uses NanoClaw's built-in destinations system. Workers never speak to the human directly — they report back to the orchestrator via the `orchestrator` destination.
- **Persistent workers** — Each worker is a long-lived agent with its own container, workspace, memory, and conversation history. This is not a stateless sub-query pattern — workers accumulate context over time.

## Setup Summary

### What was created

| Resource | Details |
|----------|---------|
| **Agent group** | `Chief of Staff` — folder `groups/orchestrator/`, ID `ag-83eb12ed-e939-476d-aedd-0b61485e021e` |
| **Provider** | `claude` (via OpenRouter API) |
| **Model** | `claude-sonnet-4-20250514` — high-end reasoning model |
| **CLI scope** | `global` — needed to discover all agent groups through `ncl` |
| **CLI channel** | Dedicated `orchestrator` messaging group instance on the CLI adapter |

### Files created

```
groups/orchestrator/
├── instructions.prepend.md          ← Standing instructions for the orchestrator
├── agents-index.md                  ← Live registry of all worker agents
├── orchestration-protocol.md        ← Reusable protocol documentation
└── memory/
    ├── index.md                     ← Memory index
    └── system/
        ├── definition.md            ← Memory system definition
        └── index.md                 ← Memory system index

scripts/
└── setup-orchestrator.sh            ← Re-runnable setup script
```

#### `instructions.prepend.md` — Chief of Staff Persona

The orchestrator's standing instructions. Defines:

- **Mission**: Intake → Clarify → Assign → Track → Synthesize
- **Persona**: Strategic coordinator, outcomes-focused with the human, precise with workers
- **Agent registry protocol**: Read `agents-index.md` at session start, update it when capabilities change
- **Orchestration workflow**: Three-phase process (Intake & Clarify → Plan & Assign → Track & Respond)
- **Work package template**: Structured format for every dispatched task (Context, Task, Output format, Constraints)
- **Error handling table**: What to do when workers don't respond, return errors, or contradict each other
- **Self-discovery**: First-start protocol to discover all agents via `ncl` and populate the registry
- **Memory rules**: What to store (human preferences, worker observations, flow patterns) and where

#### `agents-index.md` — Agent Registry

A documented registry of every worker the orchestrator coordinates:

```
- Research       →  Platform research, web searching, information gathering
- Travel-Guide   →  Trip planning, destination advice, itinerary building
- Terminal Agent →  System operations, CLI commands, diagnostics
- Ray            →  Australian tax / personal finance (accountant group, destination `ray`)
```

Each entry includes group ID, folder, destination name, provider, model, tier, capabilities, and triggering scenarios. Includes a blank template for adding new agents.

#### `orchestration-protocol.md` — Reusable Pattern

Documents the orchestration protocol for reuse — by this agent or any future orchestrator:

- Work package format (Context → Task → Output format → Constraints)
- Worker response format (Summary → Details → Caveats)
- Active flow tracking file structure
- Edge cases and recovery procedures
- Worker-facing instructions (if a worker needs to know how to respond to orchestrator tasks)

#### `scripts/setup-orchestrator.sh` — Setup Script

A bash script that automates the setup process:

1. Creates the agent group (idempotent)
2. Sets `cli_scope` to `global`
3. Configures provider and model
4. Adds orchestrator → worker destinations for each worker
5. Adds worker → orchestrator reverse destinations
6. Restarts the orchestrator container
7. Overridable via environment variables: `ORCHESTRATOR_MODEL`, `ORCHESTRATOR_PROVIDER`, `SKIP_MODEL_UPDATE`

### Wiring

#### Agent-to-agent destinations (bidirectional)

| Source | Destination | Target |
|--------|-------------|--------|
| Chief of Staff | `research` | Research agent |
| Chief of Staff | `travel-guide` | Travel-Guide agent |
| Chief of Staff | `terminal-agent` | Terminal Agent |
| Research | `orchestrator` | Chief of Staff |
| Travel-Guide | `orchestrator` | Chief of Staff |
| Terminal Agent | `orchestrator` | Chief of Staff |

The orchestrator talks to workers via `send_message({ to: "<destination-name>", text: "..." })`. Workers reply via `send_message({ to: "orchestrator", text: "..." })`, which arrives as an inbound message with `from="<worker-name>"`.

#### Channel wiring

The orchestrator has its own CLI messaging group on the CLI adapter, using instance `orchestrator` to keep its channel separate from the existing `cli` and `travel-guide` instances. This is wired with `engage_mode: pattern`, `engage_pattern: "."` (responds to any message).

## The Orchestration Flow

### Phase 1: Intake & Clarify

```
Human: "I'm planning a trip to Japan next spring..."

Orchestrator thinks: This is a travel request. But "next spring" is vague.
Do they want general research, itinerary, budget, or all three?

Orchestrator asks: "I'd be happy to help plan that! A few questions:
1. Rough dates or just a season?
2. Budget range?
3. Are you more interested in cities, nature, or a mix?"

Human clarifies → Orchestrator has a clear brief.
```

Uses `ask_user_question` for multi-choice decisions, plain messages for free-form clarification. Never dispatches a half-understood task.

### Phase 2: Plan & Assign

```
Orchestrator thinks: Three angles here — destination research (Research),
itinerary building (Travel-Guide), and checking current conditions (Terminal Agent).

Work package to Research:
## Context
Planning Japan trip, spring 2027, Tokyo + Kyoto, 10 days. Budget mid-range.

## Task
Research recommended neighborhoods in Tokyo and Kyoto for a first-time visitor.
Include food districts, cultural sites, and day-trip options from each city.

## Output format
1. Summary of both cities
2. Neighborhood recommendations with reasons
3. Must-see cultural sites
4. Day-trip possibilities with travel times
5. Caveats (seasonal closures, peak crowds)

Work package to Travel-Guide (parallel):

## Context
Same trip. Research team will provide city details.

## Task
Draft a sample 10-day itinerary based on Tokyo (5 days) + Kyoto (5 days).
Leave placeholders for details the research team is gathering.

## Output format
1. Day-by-day itinerary
2. Estimated per-day budget
3. Suggested transport passes
4. Open questions for the user
```

Dispatches to multiple workers in parallel when tasks are independent. Uses structured work packages every time — no informal requests.

### Phase 3: Track & Synthesize

```
Orchestrator maintains /workspace/agent/active-flows.md:

## Flow: japan-trip-2027
- Request: Plan 10-day Japan trip, Tokyo + Kyoto, spring 2027
- Workers: research, travel-guide
- Status: research=received, travel-guide=received
- Both replies are in → synthesizing...

Synthesized response to human:

**Japan Trip — Tokyo & Kyoto (Spring 2027)**

**Cities & Neighborhoods:**
- Tokyo: Shinjuku (nightlife/shopping), Asakusa (temples/culture), Shibuya (youth/energy)
- Kyoto: Gion (geisha district), Higashiyama (temples), Arashiyama (bamboo grove)

**Sample 10-Day Itinerary:**
[condensed day-by-day]

**Estimated Budget:** ~$3,500–$5,000 for mid-range (flights, hotels, food, transport, activities)

**Next Steps:**
1. Confirm dates to lock down accommodation prices
2. Would you like restaurant recommendations in specific neighborhoods?
3. Should I look into rail passes?
```

## Comparison to Alternatives

| Pattern | When to use | Trade-offs |
|---------|-------------|------------|
| **Orchestrator** (this setup) | Complex, multi-domain requests; need for planning/decomposition; high-thinking synthesis | One extra hop; orchestrator model cost |
| **Single agent** | Simple requests, single domain | No coordination overhead, but limited by single context window |
| **`create_agent` on demand** | Spontaneous specialist needs mid-conversation | Agent persists indefinitely; overhead for one-shots |
| **Parallel MCP tool calls** | Independent tool queries in one turn | No coordination between calls; no persistence |

## Extending the Pattern

### Adding a new worker agent

1. Create the agent group: `ncl groups create --folder <slug> --name "My Agent"`
2. Configure it: `ncl groups config update --id <id> --model <model>`
3. Add destinations:
   ```bash
   ncl destinations add --agent-group-id <orchestrator-id> --local-name <name> --target-type agent --target-id <worker-id>
   ncl destinations add --agent-group-id <worker-id> --local-name orchestrator --target-type agent --target-id <orchestrator-id>
   ```
4. Update `agents-index.md` with the new agent's capabilities
5. Restart the orchestrator: `ncl groups restart --id <orchestrator-id>`
6. Done — the orchestrator discovers the new agent on restart

### Changing the orchestrator model

```bash
ncl groups config update --id ag-83eb12ed-e939-476d-aedd-0b61485e021e --model <new-model>
ncl groups restart --id ag-83eb12ed-e939-476d-aedd-0b61485e021e
```

### Adding worker skills

Worker agents can have specialized skills installed (via `/add-*` skills or container skills) — the orchestrator just needs to know about them in `agents-index.md`. The orchestrator does not need every skill; it only needs the capability description.

## See also

- [NanoClaw architecture](architecture.md) — host/container split, session DBs, entity model
- [Agent-to-agent messaging](../README.md) — `create_agent` and destination-based routing
- [Container skills](../container/skills/) — skill system for agent capabilities
- `groups/orchestrator/instructions.prepend.md` — the orchestrator's standing instructions
- `groups/orchestrator/agents-index.md` — live agent registry
- `scripts/setup-orchestrator.sh` — re-runnable setup automation