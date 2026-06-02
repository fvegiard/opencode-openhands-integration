# Usage Examples

Comprehensive examples for using the OpenCode-OpenHands integration.

---

## Example 1: Create a FastAPI Application

```
ulw

Create a Python FastAPI application with:
- /health endpoint returning {"status": "ok"}
- /users/{user_id} endpoint with Pydantic validation
- Proper error handling with HTTP status codes
- Docker support
- Requirements.txt

Use @openhands for implementation.
```

**Expected Output:**
- `main.py` with FastAPI app
- `models.py` with Pydantic models
- `Dockerfile`
- `requirements.txt`
- `README.md` with setup instructions

---

## Example 2: Debug a Production Error

```
@openhands debug_issue: Getting 500 error on /api/users endpoint

Stack trace:
  File "app/routes/users.py", line 67, in get_users
    results = db.query(User).filter(User.active == True).all()
  File "sqlalchemy/orm/query.py", line 2821, in all
    return list(self)
TypeError: 'NoneType' object is not iterable
```

**Expected Output:**
```
✓ Debug analysis complete

Root Cause:
- Database session is None (not initialized properly)
- Missing session dependency in route handler

Fix:
1. Add session dependency: def get_users(db: Session = Depends(get_db))
2. Ensure get_db() yields valid session
3. Add error handling for DB connection failures

Code patches:
[Detailed patches provided]
```

---

## Example 3: Research Authentication Flow

```
@openhands research_codebase: How does the authentication flow work from login to protected endpoint access?
```

**Expected Output:**
```
✓ Research completed

Authentication Flow:
1. User submits credentials → POST /api/auth/login
   - Handler: app/routes/auth.py:34-56
   
2. Credentials validated → app/services/auth.py:89
   - Checks username/password against database
   - Uses bcrypt for password hashing
   
3. JWT token generated → app/utils/jwt.py:23
   - Includes user_id, roles, expiry
   - Signed with SECRET_KEY from env
   
4. Token returned in response → auth.py:52
   - Format: {"token": "eyJ...", "user": {...}}
   
5. Protected endpoints validate token → app/middleware/auth.py:15-42
   - Extract from Authorization header
   - Verify signature
   - Check expiry
   - Load user from database
   - Attach to request context

File paths and line numbers provided for all steps.
```

---

## Example 4: Refactor to TypeScript

```
@openhands refactor_code: Convert all JavaScript files in src/ to TypeScript with proper typing
```

**Expected Actions:**
1. Renames `.js` → `.ts`
2. Adds type annotations
3. Creates `tsconfig.json`
4. Updates `package.json`
5. Fixes type errors

---

## Example 5: Security Audit

```
@openhands analyze_code: src/
analysis_type: security
```

**Expected Output:**
```
✓ Security analysis complete

Found 3 issues:

HIGH: SQL Injection Risk
- File: src/db/queries.js:45
- Issue: User input concatenated into SQL query
- Fix: Use parameterized queries

MEDIUM: Weak Password Requirements
- File: src/auth/validation.js:12
- Issue: Only checks length, not complexity
- Fix: Add regex for uppercase, numbers, special chars

LOW: Missing Rate Limiting
- File: src/routes/api.js
- Issue: No rate limiting on public endpoints
- Fix: Add express-rate-limit middleware
```

---

## Example 6: Parallel Bug Fixes (Ultrawork Mode)

```
ulw

Fix all ESLint warnings in the codebase. There are warnings in:
- src/components/ (React)
- src/utils/ (Pure JS)
- src/api/ (API clients)

Use @openhands to fix each directory in parallel.
```

**What Happens:**
1. Sisyphus decomposes into 3 subtasks
2. Spawns 3 OpenHands agents in parallel
3. Each agent fixes its assigned directory
4. Sisyphus aggregates and verifies

**Result:** All warnings fixed in ~10 minutes

---

## Example 7: Add Tests

```
@openhands execute_task: Add unit tests for all functions in src/utils/string-helpers.js using Jest
```

**Expected Output:**
```
✓ Task completed

Created: src/utils/string-helpers.test.js

Tests added for:
- capitalize()
- slugify()
- truncate()
- stripHtml()

All 15 tests passing.
```

---

## Example 8: Architecture Research

```
@openhands research_codebase: What patterns are used for state management? Document all approaches found.
```

**Expected Output:**
```
✓ Research completed

State Management Patterns Found:

1. Redux (Primary)
   - Location: src/store/
   - Used for: Global app state
   - Actions: src/store/actions/
   - Reducers: src/store/reducers/
   
2. React Context (Secondary)
   - Location: src/contexts/
   - Used for: Theme, Auth
   - Contexts: ThemeContext, AuthContext
   
3. Component State (Tertiary)
   - Used for: UI-only state
   - Example: Form inputs, modals
   
Recommendation: Current approach is consistent. Consider migrating context to Redux for unified state.
```

---

## Example 9: Documentation Generation

```
@openhands execute_task: Generate API documentation from the FastAPI app in main.py. Output as OpenAPI/Swagger JSON.
```

---

## Example 10: Database Migration

```
@openhands execute_task: Create Alembic migration to add 'email_verified' boolean field to users table
```

---

## Advanced: Custom Workflow

```
ulw

I need to:
1. Research how the payment system works
2. Design a refund flow
3. Implement the refund API endpoint
4. Add tests

Use @openhands for research and implementation.
Oracle should help with design.
```

**What Happens:**
1. Librarian + @openhands research payment system
2. Oracle reviews research, proposes refund design
3. You approve design
4. Sisyphus + @openhands implement refund endpoint
5. @openhands adds tests
6. Final review and delivery

---

## Tips for Effective Prompts

### ✅ Good Prompts

- **Specific:** "Fix TypeError in UserService.java line 45"
- **Context:** "Refactor auth to JWT, keeping OAuth as fallback"
- **Scoped:** "Analyze security in src/api/ directory"

### ❌ Bad Prompts

- **Vague:** "Fix the app"
- **Too broad:** "Make everything better"
- **Ambiguous:** "Update the database"

---

**Last Updated:** June 2026
