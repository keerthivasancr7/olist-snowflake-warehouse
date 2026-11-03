# Simulated incremental workflow

These are simulated changes to historical Olist data, not live CDC.
Run Snowflake SQL in a Snowflake worksheet and shell commands in Terminal.

## Prerequisites

- Complete setup and initial loading.
- Build and test the warehouse.
- Save baseline run_results.json and manifest.json.
- Use immutable batch files and increasing batch sequences.
- Use OLIST_LOAD for stage operations and RAW loads.

## Batch sequence

| Sequence | Batch ID | Input | Purpose |
|---|---|---|---|
| 1 | initial_001 | Five original CSVs | Historical baseline |
| 2 | simulated_002 | Two orders, one item | New order and shipped-to-delivered update |
| 3 | simulated_003_invalid | One order | Invalid status; expected test failure |
| 4 | simulated_004_recovery | One order | Failed recovery attempt: uploaded status remained invalid |
| 5 | simulated_005_recovery | One corrected order | Successful recovery |
| 6 | simulated_006_status_update | One order | Delivered-to-canceled update after incremental filtering |

Batch 4 is retained as execution history. It is not a successful recovery.

## Each load

1. Generate or locate the intended local CSV.
2. Upload it to its own batch-specific stage path.
3. Query the staged file and verify its ID and status.
4. COPY into RAW with explicit target columns, batch ID and sequence.
5. Verify RAW batch counts.
6. Run the appropriate dbt build checkpoint.

COPY accepts structurally valid CSVs. dbt tests enforce business rules.

## Normal build checkpoint — Terminal

From the olist project folder:

../.venv/bin/dbt build --select path:models/staging path:models/core path:models/marts --profiles-dir .

Preserve target/run_results.json and target/manifest.json after each checkpoint.

## Invalid-status checkpoint — Terminal

../.venv/bin/dbt build --select stg_orders+ --profiles-dir .

Expected: accepted-status test fails and fct_orders plus downstream marts
are skipped. Verify that the invalid new order is absent from fct_orders.

This is a build-blocking rejection, not row-level quarantine.
Other independent branches are not guaranteed to remain unchanged.

## Recovery checkpoint

Keep the original invalid RAW versions.
Load the same order ID with a corrected status and higher batch sequence.
Run the normal build. Verify one corrected order in CORE and passing tests.

## Rerun checks

- Repeat the unchanged COPY statements without FORCE.
- Check that RAW batch counts do not increase.
- Repeat dbt build.
- Check fact uniqueness and compare contents against saved snapshots.
- After incremental filtering, unchanged facts should affect zero rows.

COPY file history provides bounded replay protection.
A persistent batch ledger and checksum validation are still required
for stronger ingestion guarantees.

## Verified results

- Baseline: 18 models succeeded; 82 tests passed.
- Batch 2: 99,442 orders and 112,651 items; unique keys matched counts.
- Transformation rerun: zero differences against batch-2 fact snapshots.
- Invalid status: one failed test; 33 downstream nodes skipped.
- Batch 5 recovery: 18 models succeeded; 82 tests passed.
- After recovery: 99,443 orders and 112,651 items.
- Filtered unchanged run: zero affected rows in both facts.
- Batch 6: one order updated, zero inserted, zero duplicates;
  zero item rows affected; all 100 build results passed.

## Incremental limitations

The fact filter compares batch sequence per business key.
Updates require a higher sequence; same-sequence edits are unsupported.
Staging still reads RAW to identify the latest version.
Deletes and business-key changes are not implemented.
