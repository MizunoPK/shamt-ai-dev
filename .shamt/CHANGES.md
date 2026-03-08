# Shamt Guide Changes

Changes to shared guides and scripts, recorded at time of change for use as PR context during export.

---

## 2026-03-08 — S3 scope framing and stale-reference fixes

### Guide fixes

- Modified: `.shamt/guides/stages/s3/s3_parallel_work_sync.md`
- Reason: H1 title was "S3: Cross-Feature Sanity Check" — the old stage name. Changed to "S3 Pre-Check: Parallel Work Sync Verification" to avoid conflicting with the current canonical stage title. Also fixed stale "Next Phase" footer that referenced "Prepare Comparison Matrix" (a step removed in the S3 restructuring); now correctly points to "S3.P1 — Epic Testing Strategy Development".

- Modified: `.shamt/guides/stages/s3/s3_epic_planning_approval.md`
- Reason: Three issues addressed:
  (1) No prominent scope statement — agents finishing the per-feature S2 loop had no unambiguous signal that S3 is once-per-epic. Added blockquote scope callout immediately after H1.
  (2) Overview contained authoring/migration notes ("Key Changes from Old S3", "Moved from old S4") that are not agent instructions and introduced S4 as a conceptual reference while the agent was still in S3. Removed.
  (3) S3.P1 lacked explicit differentiation from S4 despite sharing structurally identical test planning templates. Added "This is NOT per-feature test planning" callout at the start of S3.P1.

- Modified: `.shamt/guides/stages/s4/s4_feature_testing_strategy.md`
- Reason: Prerequisites checklist used the stale stage name "S3 (Cross-Feature Sanity Check)" which matched the old parallel-sync guide title rather than the current S3 canonical title. Updated to "S3 (Epic-Level Documentation, Testing Plans, and Approval)".

### Audit dimension updates

- Modified: `.shamt/guides/audit/dimensions/d1_cross_reference_accuracy.md`
- Reason: Added Type 5 "Prose References to Deleted Content" under Manual Validation. D1 automation only matches markdown links and code-formatted paths; plain prose references (e.g., "Proceed to Step 1 (Prepare Comparison Matrix)") escape all checks. Documents manual grep approach and validation process.

- Modified: `.shamt/guides/audit/dimensions/d2_terminology_consistency.md`
- Reason: Added Type 5 "Within-Folder Stage Title Consistency". D2 previously checked notation format (S#.P#) but not whether all files inside a single stage folder agreed on the same stage name. A restructuring can leave a sub-guide with the previous stage title in its H1 while the primary guide has the updated title, contaminating prerequisite references in the next stage.

- Modified: `.shamt/guides/audit/dimensions/d3_workflow_integration.md`
- Reason: Extended Type 1 (Stage Prerequisites Validation) with a "Stage Name Consistency Check" section. D3 automation validates stage numbers in prerequisites but not the parenthetical stage names. Documents manual grep approach, the distinction between number correctness and name accuracy, and includes a real example of the failure mode.

- Modified: `.shamt/guides/audit/dimensions/d18_stage_flow_consistency.md`
- Reason: Three additions:
  (1) Type 5 (Scope Alignment) extended with an "Agent Comprehension Risk" check — validates that scope is stated prominently near the H1, not just inferable from prerequisites — and a "Migration Notes in Agent Instruction Path" check for authoring notes in Overview sections.
  (2) S2→S3 transition checklist extended with an "Agent Comprehension (S3 specific)" block covering the scope callout, migration-note absence, and agent clarity requirements.
  (3) New S3→S4 transition checklist added covering handoff promises, scope transition, and structural similarity risk between S3.P1 and S4.
