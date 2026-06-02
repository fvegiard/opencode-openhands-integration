# MCP Enablement Plan

## 1) Goal

Enable reliable MCP validation/integration for this repository with focus on:
- GitHub MCP verification (Claude registry + smoke check)
- OpenHands MCP direct health verification
- repeatable local validation and baseline capture

## 2) Scope

In scope:
- `scripts/validate_mcps.sh` strict validation matrix
- `scripts/capture-baseline.sh`
- documentation and configuration alignment:
  - `README.md`
  - `QUICKSTART.md`
  - `docs/TROUBLESHOOTING.md`
  - `CHANGELOG.md`
  - `PROJECT_SUMMARY.md`
  - `.env.example`
  - `config/oh-my-opencode.json.example`
- `test.sh` Test 11 enhancement
- `.gitignore` updates for log hygiene

Out of scope:
- changes to OpenHands business logic in `mcp_server.py`
- unrelated MCP providers (example: Supabase) beyond informational notes

## 3) Execution Model (fan-out + closer)

Work split across 10 focused subagents, then harvested/closed into mainline:
1. validator implementation
2. README alignment
3. QUICKSTART + troubleshooting alignment
4. docs/changelog/project summary alignment
5. GitHub MCP research/smoke pattern
6. devops baseline capture script
7. test/gate adjustments
8. security pass/redaction review
9. architecture/light consistency check
10. verifier + handoff closure

## 4) Doctrine Compliance

- Small, reversible, scoped changes.
- Preserve existing behavior outside MCP validation surface.
- No secrets committed; redact logs.
- Validation gates required before merge.

## 5) Implementation Plan

### 5.1 Baseline capture
- Add `scripts/capture-baseline.sh`.
- Capture versions, MCP registry, config state, git hygiene, optional `test.sh`.
- Write timestamped, redacted logs to `logs/`.

### 5.2 MCP validator
- Add/maintain `scripts/validate_mcps.sh` with `--strict` and `--verbose`.
- Enforce/check matrix below.
- Redact potentially sensitive output in tee’d logs.
- Keep behavior robust even when prerequisites are missing (structured FAIL/WARN reporting).

### 5.3 Docs/config alignment
- Align docs and examples to the validator and smoke flow.
- Include PAT guidance for GitHub MCP registration.
- Keep opencode config examples explicit about OpenHands-first path with additive git/GitHub MCP usage.

### 5.4 Test harness enhancement
- Enhance `test.sh` Test 11 to optionally invoke validator from known candidate locations.
- Keep tolerant behavior (no hard fail if optional validator path unavailable in partial fan-out states).

### 5.5 Hygiene
- Ensure logs are ignored by `.gitignore`.
- Keep generated artifacts out of git history.

## 6) Fan-out Deliverable Map

- #01 validator: `scripts/validate_mcps.sh`
- #02 docs-readme: README MCP validation section + command parity
- #03 docs-quickstart-troubleshooting: quick checks + remediation matrix
- #04 docs-meta: changelog + project summary + examples alignment
- #05 github-research: smoke/read strategy and PAT transport notes
- #06 devops-baseline: `scripts/capture-baseline.sh`
- #07 tester-gate: `test.sh` Test 11 optional validator coordination
- #08 security-sentinel: redaction and non-secret handling checks
- #09 architect-light: consistency/scope confirmation
- #10 verifier-handoff: closure criteria + gate confirmation

## 7) Strict Validation Matrix

`scripts/validate_mcps.sh --strict` validates:
1. **Prerequisites**
   - `claude`, `python3 >= 3.12`, `uv`
2. **Direct OpenHands MCP health**
   - venv/deps/syntax
   - `health_check()` returns running (MOCK acceptable)
3. **Claude MCP registry**
   - target `github` presence check
   - additive git proxy checks (`GitKraken`/`git-mcp`)
4. **GitHub smoke (if github MCP registered)**
   - authenticated read operation through Claude MCP
5. **Repository test gate**
   - `./test.sh` invocation
6. **Config path consistency**
   - reference/path checks for `mcp_server.py`

## 8) Verification Commands

```bash
# baseline (optional but recommended)
bash scripts/capture-baseline.sh --verbose

# strict validation
bash scripts/validate_mcps.sh --strict

# full debug validation
bash scripts/validate_mcps.sh --verbose --strict

# repo tests
./test.sh
```

## 9) Landing Notes

- Mainline implementation landed in commit `6613022`.
- Follow-up robustness/doc completion is expected to preserve this plan and matrix exactly.
