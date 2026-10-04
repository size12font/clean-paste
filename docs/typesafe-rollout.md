# TypeSafe rollout

Development-only public synthetic text experiment. Code joins unchanged original spans using classified separators. No clipboard is read or uploaded. The local baseline executes CleanPasteTransform itself. Keep normal clipboard processing local. Retain the experiment for research only; current structural accuracy does not justify a product integration.

## Evaluation

Fixtures and expected labels were saved before inference. Calibration and holdout cases are distinct synthetic examples. These results do not establish precision on live users.

```json
{
  "local": {
    "exactStructure": 4,
    "cases": 12,
    "wordPreservation": 1,
    "meanLatencyMs": 0.29798348744710285
  },
  "typesafe": {
    "exactStructure": 6,
    "cases": 12,
    "wordPreservation": 1,
    "meanLatencyMs": 252.5
  }
}
```

Model: `jev-1.13.0`. Price verified on 2026-10-04: $0.042 per million input tokens; output tokens free. Every call reserves $0.01 before sending, reconciles validated usage, and retains the full reservation after an ambiguous failure. No automatic retry or allowance reset.

Local ledger: `/Users/johnnyquach/Documents/Codex/2026-10-04/go-t/work/budgets/cleanpaste.sqlite`. Reuse this existing ledger. Never create another allowance for the same rollout. Kura and Kobe local ledgers are closed after transferring only the remaining balance to production. Public fixtures may be cached by input, questions, version and model. Private application content is never cached. Operational metrics exclude the input text.

## Rollback

Disable the optional inference first. Revert the TypeSafe change commit if needed. Retain the spending ledger, reservations and consumed balance across rollback and redeployment. Never replace it with a fresh allowance. Research skill backups are in the rollout workspace under `work/backups/research`.
