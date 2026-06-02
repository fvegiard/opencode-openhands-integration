# Troubleshooting Guide

Common issues and solutions for OpenCode-OpenHands integration.

---

## MCP Server Not Connecting

**Problem:** `@openhands health_check` returns no response

**Solutions:**
1. Verify server is running: `ps aux | grep mcp_server.py`
2. Check config path in `~/.config/opencode/oh-my-opencode.json`
3. Ensure path is absolute, not relative
4. Test server directly: `python mcp_server.py`
5. Restart OpenCode

## OpenHands SDK Not Available

**Problem:** Health check shows "MOCK MODE"

**Solutions:**
1. Install OpenHands SDK:
   ```bash
   cd ~/openhands-sdk
   source .venv/bin/activate
   uv pip install -e .
   ```
2. Restart MCP server

## API Key Issues

**Problem:** "Invalid API key" errors

**Solutions:**
1. Verify key format: `echo $ANTHROPIC_API_KEY`
2. Should start with `sk-ant-`
3. Export in shell: `export ANTHROPIC_API_KEY="..."`
4. Or use `.env` file

## Configuration Not Loading

**Problem:** Changes don't take effect

**Solutions:**
1. Check JSON syntax: `cat ~/.config/opencode/oh-my-opencode.json | jq .`
2. Use absolute paths
3. Restart OpenCode
4. Check logs: `tail ~/.config/opencode/logs/mcp.log`

For detailed troubleshooting, see full documentation.

---

## MCP Validation Failures

This section covers failures from the MCP validation matrix (§7 in MCP_ENABLEMENT_PLAN.md) and risks (§8), plus expanded modes per execution plan. Use **exact remediation commands** that match what `scripts/validate_mcps.sh --strict` (and sibling test/setup) will emit/check.

Run the validator for diagnosis:
```bash
bash scripts/validate_mcps.sh --verbose --strict
```

### Validation Matrix (Core Checks)
| Check | Command (used by validator/test.sh) | Expected |
|-------|-------------------------------------|----------|
| Python version | `python3 --version` | >= 3.12 |
| Repo deps / .venv | `uv pip install -r requirements.txt` (after `uv venv` + activate) | success |
| MCP syntax | `python -m py_compile mcp_server.py` | success |
| Repo MCP health | `python -c "from mcp_server import health_check; print(health_check())"` | contains "OpenHands MCP Server is running" |
| MCP registry (claude) | `claude mcp list \| grep -E 'github\|openhands\|GitKraken'` | includes intended (github target; openhands/GitKraken fallbacks ok) |
| GitHub MCP auth/smoke | `claude --print ...` (or equiv read via github MCP) | success payload (branch name or equiv; no auth/scope err) |
| Repo validation | `bash scripts/validate_mcps.sh --strict` | exit code 0 |
| Repo test | `bash test.sh` | all tests pass |

### Failure Modes & Exact Remediations

**1. Missing registration (GitHub / openhands in claude mcp)**
- Symptom: `claude mcp list | grep -E 'github|openhands|GitKraken'` shows nothing / WARN in validator.
- Remediation (GitHub target):
  ```bash
  export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_yourpat..."
  claude mcp add --transport http github https://api.githubcopilot.com/mcp/ --header "Authorization: Bearer $GITHUB_PERSONAL_ACCESS_TOKEN"
  claude mcp list | grep -E 'github|GitKraken'
  claude mcp get github
  ```
- For openhands (additive to claude; primary is opencode config):
  ```bash
  claude mcp add openhands -- python "$(pwd)/mcp_server.py"
  claude mcp list | grep openhands
  ```
- Re-run validator.

**2. PAT scope insufficient (or expired / bad token)**
- Symptom: GitHub smoke in validator/claude --print fails with "unauthorized", "scope", "403", "not found" (for protected), or no payload match.
- Remediation:
  - Go to https://github.com/settings/personal-access-tokens/new (fine-grained)
  - Scopes: **Contents: Read**, **Issues: Read**, **Pull requests: Read**, **Metadata: Read** (for target repo/org e.g. fvegiard/* or public).
  - Re-export + re-add the MCP (remove first if needed: `claude mcp remove github`)
  - Smoke test (copy from plan):
    ```bash
    claude --print "Using only the github MCP, list the default branch or 1 open issue for repo fvegiard/opencode-openhands-integration. Be terse." --allow-dangerously-skip-permissions 2>&1 | grep -E 'main|master|error|not found|unauth|scope'
    ```
  - Then `bash scripts/validate_mcps.sh --strict`

**3. Bad config path for mcp_server.py (path drift, relative vs absolute)**
- Symptom: `@openhands health_check` silent/no-response in opencode; validator "config path check fail"; "No such file" on MCP start.
- Remediation:
  ```bash
  # Compute the absolute path the validator/setup use
  python -c "
  import os
  abs_path = os.path.abspath('mcp_server.py')
  print('Use this in config:', abs_path)
  print('Example block:')
  print('\"args\": [\"' + abs_path + '\"]')
  "
  ```
  Edit `~/.config/opencode/oh-my-opencode.json` (create from `cp config/oh-my-opencode.json.example ~/.config/opencode/oh-my-opencode.json` if missing):
  - Change to **absolute** path (never relative).
  - Match exactly what `$(pwd)` or abspath produces (see setup.sh which writes it).
  - Also update the example if for sharing.
  - Cross-check: `grep -o 'mcp_server.py[^"]*' ~/.config/opencode/oh-my-opencode.json`
  - Restart OpenCode (and any running mcp_server).
- Validator will compute abs and grep configs for it.

**4. No .venv / deps**
- Symptom: validator/test.sh: ".venv not found", "FastMCP not found", import errors on health_check, py_compile fails.
- Remediation (idempotent, matches setup.sh + validator):
  ```bash
  uv venv
  source .venv/bin/activate
  uv pip install -r requirements.txt
  python -m py_compile mcp_server.py
  python -c 'from mcp_server import health_check; print(health_check())'
  bash scripts/validate_mcps.sh --strict
  ```
- If in setup: re-run `bash setup.sh --skip-opencode --skip-openhands`

**5. claude --print smoke fails (or non-deterministic / MCP not exercised)**
- Symptom: smoke output lacks expected (no branch, "error"); validator may mark GitHub smoke fail (or warn if --no-smoke).
- Remediation:
  - Confirm registration + PAT (see 1+2).
  - Interactive first: run `claude` and manually invoke a github tool once (to approve).
  - Use shorter: `claude mcp list` presence may be enough for some; strict may require payload.
  - GitKraken fallback (often present): `claude mcp list | grep GitKraken` (provides git_* + PR tools).
  - Direct GitHub API fallback (if PAT):
    ```bash
    curl -s -H "Authorization: Bearer $GITHUB_PERSONAL_ACCESS_TOKEN" \
      https://api.github.com/repos/fvegiard/opencode-openhands-integration | grep -E 'default_branch|name'
    ```
  - Re-run: `bash scripts/validate_mcps.sh --strict`

**6. Supabase unrelated (or other non-target MCP fails)**
- Symptom: `claude mcp list` shows `supabase-knowledge ... ✗ Failed to connect`
- Remediation: **Ignore**. Per plan: "Supabase failed in baseline → ignore (not in scope; plan targets github + openhands)". Validator does not fail --strict on unrelated MCPs. Only enforce github/openhands/git* presence.

**7. Mock vs real OpenHands**
- Symptom: health shows "in MOCK mode"; `OPENHANDS_AVAILABLE=false`
- Remediation: (MOCK is acceptable per design; validator accepts it + prints note)
  ```bash
  # For real exec (full SDK):
  git clone https://github.com/fvegiard/OpenHands.git ~/openhands-sdk || true
  cd ~/openhands-sdk
  uv venv
  source .venv/bin/activate
  uv pip install -e .
  # Then restart your mcp_server.py (in the integration repo venv)
  ```
  - Direct test always: `source .venv/bin/activate && python -c 'from mcp_server import health_check; print(health_check())'`
  - In mock: OpenHands MCP tools still respond (delegation uses mock impl).
  - Validator: will show MOCK but pass if "running" in output.
  - To confirm SDK: `python -c "import openhands; print('real')" 2>&1 || echo 'still mock'`

### Additional Consistency Notes
- **claude vs opencode config drift**: Validator (if ~/.config/opencode/* present) will cross-check "openhands" args path vs abspath(`mcp_server.py`). Keep in sync.
- **claude mcp list | grep ...** and python health + validator must be run from *repo root*.
- All snippets here match the pseudocode/sketch in plan.md + test.sh/setup.sh + mcp_server.py health_check output ("OpenHands MCP Server is running").
- After any fix: re-run `bash scripts/validate_mcps.sh --strict` until green.
- For GitKraken users: healthy `GitKraken` in `claude mcp list` can proxy many git/github ops (27 tools incl. git_*, issues_*, pull_request_*).

**Last Updated:** June 2026 (MCP validation layer added)

---

## GitHub MCP (claude mcp) Research Notes - 2026-06-02 (harvested from subagent 05: wt-mcp-05-github-researcher)

**Current claude mcp list (this rig):** No "github" entry at research time. Present: `git-mcp: uvx mcp-server-git - ✓`, `GitKraken: /usr/bin/gk mcp --host=claude-cli - ✓` (27 tools incl git_*, issues_*, pull_request_* , repository_get_file_content with provider=github). Other rig MCPs (not in claude registry): grok_com_github (46 GitHub API tools: list_branches, list_issues, get_latest_release, list_releases, get_me etc).

**Exact add commands (current 2026, Claude Code 2.1.160+):**

1. Recommended HTTP (hosted, PAT in header; supports /readonly for read-only smoke):
   ```
   export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_...
   claude mcp add-json github '{"type":"http","url":"https://api.githubcopilot.com/mcp","headers":{"Authorization":"Bearer '"$GITHUB_PERSONAL_ACCESS_TOKEN"'"}}'
   # or for read-only tool surface only:
   claude mcp add-json github '{"type":"http","url":"https://api.githubcopilot.com/mcp/readonly","headers":{"Authorization":"Bearer '"$GITHUB_PERSONAL_ACCESS_TOKEN"'"}}'
   # legacy (older claude):
   claude mcp add --transport http github https://api.githubcopilot.com/mcp/ -H "Authorization: Bearer $GITHUB_PERSONAL_ACCESS_TOKEN"
   ```

2. Docker (local stdio):
   ```
   claude mcp add github -e GITHUB_PERSONAL_ACCESS_TOKEN=$GITHUB_PERSONAL_ACCESS_TOKEN -- docker run -i --rm -e GITHUB_PERSONAL_ACCESS_TOKEN ghcr.io/github/github-mcp-server
   ```

3. After add: `claude mcp list | grep -i github` ; `claude mcp get github` ; restart claude if needed.

**GitKraken as proxy:** `claude mcp add -t stdio GitKraken gk mcp` (already present). Good for local git + some remote GitHub if `gk` logged in (`gk auth login`). Use `gk mcp` for git_branch etc. Not full GitHub API surface like official.

**git-mcp:** Local only (mcp-server-git via uvx). `claude mcp add git-mcp -- uvx mcp-server-git` (already present).

**For OpenCode (separate from claude mcp):** See official https://github.com/github/github-mcp-server/blob/main/docs/installation-guides/install-opencode.md (uses opencode.json "mcp"."github" with "type":"remote" + headers or local docker; set "oauth":false for PAT).

**Required fine-grained PAT permissions (read-only smoke: list_branches, repo info, list_issues, get_latest_release):**
- Resource owner: your user (or org)
- Repository access: "Only select repositories" -> fvegiard/opencode-openhands-integration (or All repos)
- Repository permissions:
  - Contents: Read-only   (enables: branches, releases/latest, contents/*, commits, compare, tree etc.)
  - Issues: Read-only     (list_issues, issue_read etc.)
  - Pull requests: Read-only (for PR tools, recommended for completeness)
  - Metadata: Read-only   (base repo visibility, often auto-granted)
- No write scopes. Classic PAT "repo" scope also works but less secure (prefer fine-grained).
- Source: github-mcp-server docs + GitHub REST perms table (Contents read covers /branches /releases ; Issues read for list_issues). See https://docs.github.com/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens

**Non-interactive smoke (bash for validator):**
- Preferred: `claude --print --dangerously-skip-permissions "Using the github MCP, list branches for fvegiard/opencode-openhands-integration (or report default branch). Be terse. Output branch names only." 2>&1`
  - Pros: exercises real claude MCP registration, auth, tool dispatch + model selection of tool.
  - Cons: model may not always invoke tool (mitigate with explicit "call the list_branches tool" or "use github list_branches"); first-use may need prior interactive approval of server; output parsing needed (grep for 'main' or branch names or error); rate limits/context tax (github MCP ~42k-55k tokens schema).
  - Flags that work (v2.1.160): --print / -p , --dangerously-skip-permissions , --model , --output-format json (for structured), --allowed-tools etc. No --max-tokens (use --max-budget-usd or rely on model).
  - Example that worked for git-mcp: `claude --print --dangerously-skip-permissions "Using the git-mcp MCP tool, ... report tersely..."` -> "Current branch: `mcp/05-github-researcher` ..."
- Fallback if no github MCP or claude --print blocked: direct curl (if PAT exported): `curl -s -H "Authorization: Bearer $GITHUB_PERSONAL_ACCESS_TOKEN" "https://api.github.com/repos/fvegiard/opencode-openhands-integration/branches?per_page=3" | jq '.[].name' ` (tests PAT+connectivity, NOT MCP layer).
- Or use rig MCPs (researcher harness only, not for validator script): via search_tool + use_tool on grok_com_github__list_branches etc. (verified working: returned main, dev, ... ; get_me ok; releases empty as expected).
- GitKraken fallback smoke: `claude --print ... "using GitKraken MCP, git status or list branches in $(pwd) ..."`

**Smoke target repo for validator:** fvegiard/opencode-openhands-integration (public? list_branches works without broad scopes).

**Recommendation for validator (scripts/validate_mcps.sh):**
- Parse `claude mcp list` for github (case-insens, ✓ Connected preferred).
- If present: run claude --print smoke with prompt tuned to "list branches ... fvegiard/opencode-openhands-integration" + "terse" + expect 'main' or branch name in output (lenient grep -qiE 'main|master|dev|copilot|branch|error|unauthorized|scope|not found|failed').
- Also `claude mcp get github` for details.
- If absent: WARN or (in --strict) FAIL with exact copy-paste add command (redact PAT).
- Support env: GITHUB_PERSONAL_ACCESS_TOKEN or GITHUB_PAT .
- Always redact Bearer in logs.
- Also check git-mcp / GitKraken presence as "git proxy" note.
- For OpenHands part: separate (not this research).
- Capture to logs/validate-*.log with timestamp.
- Exit 0 on green (or strict if github smoke passed).

**MCP tool verification (in researcher harness):** grok_com_github__list_branches(owner=fvegiard, repo=opencode-openhands-integration) -> [{"name":"main",...}, {"name":"dev",...}] (success). list_issues -> empty ok. get_latest_release -> 404 expected (no releases). get_me succeeded.

**Sources (cite inline in docs if added):** github.com/github/github-mcp-server (install-claude.md, README, remote-server.md), docs.github.com/rest/authentication/permissions..., various 2026 posts on claude mcp add patterns. Verified 2026-06-02.

**Next for siblings:** implementer01 use these EXACT snippets in validator + docs. researcher delivered actionable "exact add command" + "smoke snippet".

**Status:** Research complete for workstream 5.2. No PAT in this env for claude github (human enter only); used harness grok_com_github for live test. Ready to hand off snippets.

---

## Security & Compliance Review Notes - 2026-06-02 (harvested from subagent 08: wt-mcp-08-security-sentinel)

**Role of #08:** Security-sentinel (A9) + reviewer (A5) — full audit of validator (#01), capture-baseline (#06), all sibling changes, PAT/redaction/safety/minimalism per plan §8/§10 + doctrine §04/06e/10/12/16. Read-only for audit (extensive read_file + grep/ripgrep); only wrote SECURITY_REVIEW.md in its own isolated wt.

**Key audit findings (pass/fail):**
- Validator redaction comprehensive (sed for Bearer, Authorization: Bearer, GITHUB_PAT/ANTHROPIC/sk-ant/ghp_/generic key/token/pat/secret/auth; dual tee: screen full + redacted log only): **PASS**
- No rm -rf / destructive ops in validator or any new *.sh (grep across **/*.sh = zero "rm " in new code; pre-existing only): **PASS**
- Safe idempotent ops (if ! -d .venv; uv venv; uv pip -q; checks before actions): **PASS**
- Proper error handling (collectors, || true, no $VAR/creds in fail msgs, RC at end): **PASS**
- mcp_server.py: 11/11 copies identical (no drift; grep health_check marker count=1 each): **PASS**
- Narrow/additive diffs only; no new secrets in committed files (all greps = placeholders + intended redact code only): **PASS**
- .env.example / configs: only placeholders (even #04 additive GITHUB_...=ghp_your-... + scopes): **PASS**
- PAT handling (from #05 research + code/docs): human-only (no auto-add), redacted, minimal scopes (Contents/Issues/PRs/Metadata Read), risks §8 mitigated in validator + TROUBLESHOOTING: **PASS**
- Logs redacted + .gitignore'd; no real .env/secrets committed: **PASS**
- Would pass human sec+code review: **PASS** (green with notes)

**Compliance:** All changes exactly as plan §10 ("Keep changes minimal and scoped. Prefer additive docs and scripts over broad rewrites. Redact secrets..."). No mcp_server.py edits. Docs aligned (exact cmds match validator). Minor notes (non-blockers): #07 test cross-wt abs paths (fan-out dev artifact); validator/capture not yet fully integrated in all paths; some "will be created by sibling" refs (coordination during parallel work).

**Recommended hardening (proposals; additive, apply post-gate as small PRs):**
- Unify/enhance redaction across validate + capture (add explicit sk-ant- , JSON patterns, test redaction unit in script).
- Implement `--no-smoke` flag (graceful for rate/approval issues; per plan risk + TROUBLESHOOTING).
- Explicit scope checklist always-on in validator report when !HAS_GITHUB.
- Integrate capture-baseline (#06) into validator --verbose path.
- /tmp hygiene in #07 test (trap 'rm -f ...' EXIT or mktemp + logs/ subdir).
- `--dangerously-skip-permissions` on claude --print smoke (for non-tty/CI).
- Minor: version validator output, defensive command -v guards, etc.

**Evidence:** Full 170+ line report in subagent 08's wt: `/home/francis-v/.grok/worktrees/git-opencode-openhands-integration/wt-mcp-08-security-sentinel/SECURITY_REVIEW.md` (process, every absolute path, redaction snippets, PAT review, compliance matrix, pass/fail list, hardening proposals, OVERALL green).

**Status:** Security gate green. No blockers. Fan-out posture strong (redaction best-in-class, no leaks/destructives, PAT human-gated + redacted, changes exactly scoped). Re-run full greps + `bash scripts/validate_mcps.sh --strict` after any hardening application. Ready for merge of 08's branch (review artifact) + final human gate.

**Next for siblings/orchestrator:** Incorporate hardening as small additive edits (e.g. in validator or #10 closure). Human sec+code review + re-run gate. See 08's SECURITY_REVIEW.md for verbatim details.
