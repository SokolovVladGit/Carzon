# Codex Working Instructions

These instructions apply to all Codex tasks in this repository.

The current task prompt defines the task-specific goal and scope.
This file defines persistent repository rules, safety boundaries, execution
behaviour, and reporting requirements.

A task prompt may narrow these instructions or explicitly authorise a normally
restricted action. It must not silently weaken safety restrictions.

If the task prompt conflicts with this file or is materially ambiguous, stop
and report the conflict before making changes.

---

## 1. Core principles

Produce concise, engineering-grade work and reports.

- Prefer: facts → actions → verification.
- Make minimal, safe, complete, and root-cause-oriented changes.
- Avoid unrelated modifications.
- Inspect repository evidence before forming conclusions.
- Do not speculate when the answer can be established from code, tests, logs,
  configuration, or Git diff.
- If something remains uncertain, state the assumption explicitly.
- Do not repeat the same point in different words.
- Avoid meta-commentary and generic AI-style explanations.
- Keep prose short unless additional detail is required for a risk, blocker,
  failure, or material trade-off.
- Do not perform product or architectural expansion beyond the stated task.

---

## 2. Project context

This repository is a Flutter mobile application.

Preserve the established project architecture and conventions:

- feature-first structure;
- Bloc/Cubit for state management;
- get_it for dependency injection;
- GoRouter for navigation;
- Supabase for database, authentication, storage, RPCs, and Edge Functions;
- Firebase Cloud Messaging for push notifications;
- RU and RO localisation;
- light and dark themes.

The project is currently in release-candidate stabilisation.

Default product scope is:

- final UI polish;
- release QA;
- real-device QA;
- release build checks;
- hosted environment verification;
- release-readiness fixes;
- regression fixes.

Do not begin unrelated P2/P3 feature expansion, broad redesigns, or speculative
architecture work unless explicitly requested.

Follow existing repository patterns before introducing new ones.

---

## 3. Execution environment

Default execution mode:

- Work locally.
- Operate only inside the current repository.
- Use manual approvals.
- Request approval when an action requires elevated access, network access,
  hosted-service access, or execution outside the expected local task scope.

Do not recommend or enable automatic approval for:

- deployments;
- hosted Supabase operations;
- production services;
- secrets;
- credentials;
- release publication;
- Git write operations;
- destructive actions.

Do not modify files outside the current workspace.

Do not access unrelated private files, credentials, keychains, environment
files, or user data outside the repository.

---

## 4. Task modes

Determine the task mode from the explicit task prompt.

Do not silently convert one task mode into another.

### 4.1 Audit mode

Use when asked to:

- investigate;
- diagnose;
- inspect;
- analyse;
- determine a root cause;
- propose a fix;
- review architecture;
- perform a read-only audit.

In Audit mode:

- Do not modify files.
- Do not apply fixes.
- Do not install or update dependencies.
- Do not run formatting, code generation, migrations, or other write-oriented
  commands.
- Read the relevant implementation and repository state.
- Run read-only inspection commands when useful.
- Stop after the audit report.

### 4.2 Implementation mode

Use only when explicitly asked to:

- implement;
- fix;
- change;
- add;
- remove;
- refactor.

In Implementation mode:

1. Inspect the relevant code and current Git state before editing.
2. Identify the actual cause or required behaviour.
3. Define the expected implementation scope.
4. Make the smallest complete change.
5. Preserve established architecture and conventions.
6. Run targeted verification.
7. Review the final diff for unintended changes.
8. Stop after the implementation report.

Do not perform unrelated improvements.

### 4.3 Continuation mode

Use when the repository contains unfinished task-related changes from:

- a previous Codex session;
- Cursor;
- another coding agent;
- an interrupted implementation;
- a session that ended because of limits or failure.

In Continuation mode:

- Treat the working tree as inherited state, not a clean baseline.
- Inspect `git status --short` before editing.
- Inspect the relevant existing diff.
- Identify unfinished implementation and relevant failing tests.
- Preserve correct inherited work.
- Do not restart the implementation from scratch.
- Do not rewrite already-working sections without a concrete reason.
- Complete only the unfinished stated task.
- Leave unrelated dirty files untouched.

The final report must distinguish:

1. inherited state at the beginning of the current session;
2. work completed during the current Codex session;
3. final combined task diff against `HEAD`;
4. unrelated pre-existing changes left untouched.

Do not attribute the entire diff against `HEAD` to the current Codex session.

### 4.4 Review-only mode

Use when asked to inspect an existing implementation or diff without changing
it.

In Review-only mode:

- Do not modify files.
- Inspect the relevant code and diff.
- Check architecture, correctness, scope, tests, and regression risks.
- Identify concrete defects only.
- Do not propose broad redesigns unless required by a confirmed defect.
- Stop after the review report.

### 4.5 Deployment mode

Use only when deployment is explicitly requested.

Before deployment:

- confirm the exact target;
- confirm prerequisites;
- confirm that no required hosted SQL step remains pending;
- request manual approval for the hosted or network action;
- do not deploy unrelated functions or services.

After deployment:

- report the exact command;
- report the deployed target;
- report the result;
- run the specified smoke check;
- report unresolved risks.

---

## 5. Initial repository-state inspection

Before any implementation or continuation task:

- inspect `git status --short`;
- identify relevant pre-existing modified and untracked files;
- distinguish task-related files from unrelated user changes;
- do not assume the working tree is clean.

Use `git diff`, `git diff --stat`, and `git diff --name-only` when required to
understand scope.

Do not:

- discard existing changes;
- overwrite unrelated changes;
- restore files to `HEAD`;
- reset the working tree;
- treat unrelated dirty files as part of the task.

If existing changes make safe ownership of the task unclear, stop and report:

- the ambiguous files;
- why ownership is unclear;
- the recommended safe next step.

---

## 6. Scope rules

- Modify only files required for the current task.
- Do not refactor unrelated code.
- Do not rename or reorganise files unless required.
- Do not introduce new abstractions without a concrete need.
- Do not add or upgrade dependencies unless explicitly requested or strictly
  necessary.
- Do not alter public behaviour outside the requested scope.
- Preserve backwards compatibility unless the task explicitly requires a
  breaking change.
- Prefer root-cause fixes over symptom patches.
- Preserve correct existing work.
- Do not make opportunistic cleanup changes.

Do not run unless explicitly requested or technically required:

- repository-wide formatting;
- repository-wide code generation;
- bulk search-and-replace;
- dependency upgrades;
- migration regeneration;
- global import sorting;
- line-ending normalisation;
- whitespace cleanup outside changed sections.

Format only directly modified task files.

Do not modify generated files unless the task explicitly requires their
regeneration.

If a larger change would be safer or necessary, stop before expanding scope and
briefly explain the trade-off.

---

## 7. Change-size guardrail

Before editing:

- identify the expected files or directories;
- estimate the expected changed-file count when reasonably possible.

If the task is expected to affect only a small area, keep the change within that
area.

If the implementation is projected to modify more than 10 files, stop before
editing unless the task prompt explicitly authorises the larger scope.

Report:

1. projected file count;
2. affected directories;
3. reason the larger scope is required;
4. recommended approach.

During implementation:

- inspect `git diff --stat` after substantial editing steps;
- do not wait until the end to detect unexpected scope expansion.

If the actual changed-file count materially exceeds the expected scope:

- stop further editing;
- do not revert anything automatically;
- report `git status`;
- report `git diff --stat`;
- explain the likely cause;
- request a decision.

---

## 8. Decision boundaries

Stop and request a decision before:

- making an architectural change;
- introducing a new dependency;
- changing a public API or data contract;
- creating a breaking database migration;
- changing authentication or authorisation behaviour;
- changing product behaviour or UX where multiple valid options exist;
- modifying production configuration;
- modifying secrets or credentials;
- performing an irreversible action;
- expanding materially beyond the stated scope;
- publishing or deploying a release;
- performing an unexpected hosted-service action.

When requesting a decision:

- state the exact decision required;
- give the recommended option;
- summarise the material trade-off in 1–2 lines.

Do not continue past the decision boundary without explicit approval.

---

## 9. Git and GitHub restrictions

Unless explicitly authorised for the exact current action, do not run:

- `git add`;
- `git commit`;
- `git push`;
- `git pull`;
- `git reset`;
- `git restore`;
- `git checkout`;
- `git switch`;
- merge;
- rebase;
- branch creation or deletion;
- stash operations;
- force operations;
- GitHub pull-request or merge actions.

Do not stage files.

Do not discard existing user or agent changes.

Read-only Git commands are allowed when needed:

- `git status`;
- `git diff`;
- `git diff --stat`;
- `git diff --name-only`;
- `git log`;
- `git show`.

A suggested commit message may be included in the final implementation report,
but no commit may be created.

---

## 10. Supabase SQL and database restrictions

Codex may prepare local repository changes for:

- SQL migrations;
- tables;
- indexes;
- functions;
- RPCs;
- policies;
- triggers;
- database tests;
- verification queries.

Unless explicitly authorised, do not:

- apply hosted Supabase migrations;
- execute hosted Supabase SQL;
- modify hosted tables directly;
- modify hosted RLS policies;
- modify hosted functions or triggers;
- reset or link a hosted project;
- perform destructive database actions.

When a hosted database change is required, stop after preparing the local
migration and report:

- exact migration filename;
- affected table, function, RPC, policy, trigger, or index;
- why the hosted change is required;
- when it must be applied;
- whether it must precede an Edge Function deployment;
- verification query or smoke check;
- relevant rollback or recovery consideration.

The human owner applies hosted SQL manually by default.

---

## 11. Supabase Edge Function restrictions

Codex may implement Edge Functions locally.

Do not deploy an Edge Function unless the exact deployment is explicitly
requested in the current task prompt.

Before deployment:

- confirm the function name;
- confirm required SQL migrations are already applied;
- confirm required secrets are available;
- request manual approval for the network or hosted action.

Do not:

- deploy unrelated functions;
- modify hosted secrets without explicit authorisation;
- deploy while a required SQL migration is pending;
- enable automatic approval for deployment.

After deployment, report:

- function name;
- exact command;
- deployment result;
- smoke-test command or procedure;
- smoke-test result;
- remaining risk.

---

## 12. Production, Firebase, and release restrictions

Unless explicitly authorised, do not:

- modify production Firebase configuration;
- modify signing configuration;
- modify bundle identifiers or application identifiers;
- modify certificates, provisioning profiles, or signing keys;
- publish App Store or Google Play releases;
- upload release builds;
- modify production secrets;
- change hosted cron configuration;
- perform destructive storage operations.

Local code and configuration preparation is allowed when required by the task,
but production actions require explicit approval.

---

## 13. Verification rules

- Run the narrowest relevant checks first.
- Run broader checks only when justified by the task scope.
- Prefer targeted tests over the complete test suite for small changes.
- Do not claim that a check passed unless it was actually executed.
- Report the exact command and result for every automated check.
- If a check was not run, state why.
- Do not hide warnings, failures, skipped tests, or incomplete validation.
- Distinguish failures caused by the current changes from failures that appear
  to be pre-existing.
- Do not fix unrelated pre-existing failures unless explicitly requested.

Before finishing an implementation or continuation task:

- inspect the final diff;
- inspect `git diff --check`;
- confirm no unrelated files were changed;
- confirm the requested behaviour is covered;
- report remaining risks;
- report any checks that still require a physical device or hosted environment.

---

## 14. Manual QA reporting

Do not present a manual QA checklist as completed verification.

Every manual check must be explicitly labelled as one of:

- Performed — passed
- Performed — failed
- Not performed
- Requires physical device
- Requires hosted environment

When a manual check was not performed, do not imply that the behaviour has been
verified.

---

## 15. Audit report format

Use only for Audit mode.

### 1. Current behaviour

- Facts observed in the repository.
- No unsupported speculation.

### 2. Most likely root cause

- One primary cause.
- Up to two secondary causes when relevant.
- Clearly label assumptions and unverified conclusions.

### 3. Minimal fix plan

- Concrete implementation steps.
- No unrelated refactoring.
- Mention trade-offs only when material.

### 4. Files involved

- File paths only.

### 5. Verification checklist

- Five to eight concrete checks.

### 6. Risks or blockers

- Include only when present.
- Otherwise omit this section.

Stop after the audit report.

---

## 16. Review-only report format

Use only for Review-only mode.

### 1. Scope reviewed

- Files, diff, or feature inspected.

### 2. Findings

For every confirmed issue include:

- severity;
- file path;
- concrete defect;
- expected impact;
- recommended minimal correction.

Do not invent findings to fill the report.

### 3. Verification evidence

- Commands, tests, or repository evidence inspected.

### 4. Remaining uncertainty

- Include only when present.

### 5. Recommendation

Use one of:

- Acceptable as implemented
- Acceptable with minor follow-up
- Corrective implementation required
- Insufficient evidence

Stop after the review report.

---

## 17. Implementation report format

Use after Implementation mode.

### 1. Files changed

- File paths only.

### 2. What changed

- Three to six concise bullet points.
- Describe behaviour and intent.
- Avoid low-level narration.

### 3. Confirmations

- Requirements satisfied.
- Relevant behaviour explicitly left unchanged.
- Scope boundaries respected.

### 4. Verification performed

For every executed check include:

- exact command or manual check;
- result;
- relevant warnings or failures.

### 5. Not verified

- Checks not performed and why.
- Omit when all relevant checks were completed.

### 6. Risks or unresolved issues

- Include only when present.
- Distinguish pre-existing issues from issues introduced by this change.
- Otherwise omit.

### 7. Git review

Include:

- current branch;
- final changed-file count;
- unrelated dirty files left untouched;
- `git diff --check` result;
- suggested commit message.

Do not commit or stage changes.

---

## 18. Continuation report format

Use after Continuation mode.

### 1. Inherited state

- Relevant unfinished implementation present at session start.
- Relevant failing tests present at session start.
- Initial relevant files and Git state.

### 2. Work completed in this session

- Changes made by the current Codex session only.

### 3. Final files changed

- Task-related file paths.
- Clearly distinguish unrelated pre-existing dirty files.

### 4. Final combined task state

- Behaviour now implemented.
- Combined task diff against `HEAD` when useful.
- Do not attribute the combined diff entirely to this session.

### 5. Verification performed

For every check include:

- exact command;
- result;
- relevant warnings or failures.

### 6. Not verified

- Checks not performed and why.

### 7. Risks or unresolved issues

- Include only when present.
- Distinguish inherited issues from newly introduced issues.

### 8. Git review

Include:

- current branch;
- initial and final repository status summary;
- current-session scope;
- unrelated files left untouched;
- `git diff --check` result;
- suggested commit message.

Do not commit or stage changes.

---

## 19. Response style

- Prefer short bullet points.
- Avoid long prose.
- Do not repeat task context.
- Do not narrate every tool call or editing step.
- Do not include generic recommendations.
- Be explicit and technically precise.
- Keep trade-offs to one or two lines.
- Report facts separately from assumptions.
- Finish with the required report.
- Do not add filler after the report.