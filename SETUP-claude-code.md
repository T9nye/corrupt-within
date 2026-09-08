# Moving Corrupt Within into Claude Code

Delete this file once you're set up — it's instructions for you, not context for
Claude.

## 1. Make the repo

There isn't one yet. Make a folder, drop these files in, and turn it into a repo:

```bash
mkdir corrupt-within
cd corrupt-within
# copy CLAUDE.md and the docs/ folder in here
git init
git add .
git commit -m "Design docs"
```

Then create an empty repo on GitHub called `corrupt-within` (no README, no
.gitignore — you already have files), and push:

```bash
git remote add origin https://github.com/T9nye/corrupt-within.git
git branch -M main
git push -u origin main
```

You end up with:

```
corrupt-within/
├── CLAUDE.md
└── docs/
    ├── game-overview.md
    ├── corruption.md
    ├── combat.md
    ├── enemies.md
    ├── progression.md
    ├── architecture.md
    ├── haven-build.md
    └── build-order.md
```

No `src/` yet — that arrives in Phase 2 when there's actually code to sync.

## 2. Install Claude Code

Needs a Pro or Max plan — Claude Code isn't on the free tier. Install it, then:

```bash
cd path/to/corrupt-within
claude
```

It reads `CLAUDE.md` automatically on startup.

Docs: https://code.claude.com/docs/en/setup

## 3. Connect Roblox Studio

Claude Code can edit your files but can't touch Studio without an MCP server.
Two options:

- **Roblox's official one** — https://github.com/Roblox/studio-rust-mcp-server —
  download the installer from the releases page, run it, restart Studio.
- **A community one that installs in a single command:**
  ```bash
  claude mcp add robloxstudio -- npx -y robloxstudio-mcp@latest
  ```
  Then install its Studio plugin and enable *Allow HTTP Requests* under
  Experience Settings → Security.

Either way, verify the plugin shows as connected in Studio's Plugins tab before
you trust it.

**Point it at a test place first.** Anything that can build parts can also delete
them. Back up your Haven place file before you let an agent write to it.

## 4. Keep CLAUDE.md current

The only part that goes stale is the "Current state" section. Update it when you
finish a phase. Two minutes of upkeep saves you re-explaining where you are at
the start of every session.

## What to check

The design docs were rebuilt from the blueprint, so the *structure* is right but
some tuning numbers are first-pass rather than the exact figures from earlier
drafts. Worth a read-through before you build on them:

- damage and cooldown values in `docs/combat.md`
- XP curve and drop weights in `docs/progression.md`
- boss HP and phase thresholds in `docs/enemies.md`

The Haven doc deliberately doesn't restate part coordinates — your place file is
the source of truth for those now.
