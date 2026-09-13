# Civic administration — runtime review handoff

READY for integrator review; not yet canonical. Worktree `/Users/seanpurtill/Documents/Codex/tt-civic-administration`, branch `codex/civic-administration`, base `cc1f931`. Four existing discoveries: jurisdiction_boundaries, official_mandate_registers, public_office_handover, petition_registers. Exact AND prerequisites and no OR additions; no new discovery identities authored.

## Player behavior

The existing government maintains settlement-and-subject jurisdiction and mandates for its real appointed local leaders. Mandates have explicit expiry and do not transfer automatically to replacements. Appointment changes queue actual pending civic duties; a paid, authorized handover transfers custody without rewriting the original directive author. Pending or unauthorized custody prevents an implementation review from being falsely completed.

Observed local water, food and shelter deficits can produce a bounded aggregate household petition. Filing and disposition use clerical work. Addressing changes actual local work priorities; deferral retains the grievance; resolution requires observation showing the shortage has improved. Existing leader conversation supports “show petitions”, “record our jurisdiction”, “record your mandate” / “renew your mandate”, and “address/defer/resolve petition N”. No new mandatory forms or official population pool.

GovernmentPeopleSystem owns the ledger and daily processing. The shared effective-workers calculation reserves10% of primary-office Administration capacity before ordinary administration consumes its remaining share. Daily credit uses the existing local population scope, at most once per day; no missed-day backfill and no secondary-office duplicate credit. The30-unit bank is an abstract bounded clerical-work balance, not simulated sheets or archives.

## Evidence

69 combined tests pass:12 new civic,32 existing government,4 existing civic implementation,21 purchase tests. Final validation-only tightening was followed by12/12 civic tests. Actual paid studies for each of thefour subjects pay goods and require delivery/examination without granting mastery or public authority. Full saves cover both mandates and an unfinished handover; actor and settlement scope checks cover clerical draws and shortage observations. See `CIVIC_ADMINISTRATION_PROGRESS.md` for exact logs and prior fixture corrections.

Graph805/587 explicit routes,no errors on the801-base branch. Local resource closure804/805, with inherited size-exclusion chromatography blocked under local-only assumptions; no new civic node blocked. Successful combination with canonical806 would yield810. No millennial pacing claim.

## Integration and saves

Changed shared surfaces: GameState.effective_workers adds an optional fourth bypass flag for the reservation; GovernmentPeopleSystem owns/reset/processes records and hooks local appointment; CivicImplementationSystem checks recorded custody before review; AdvisorSystem handles explicit administrative conversation commands; DiscoverySystem registers four definitions; SaveSystem and WorldSimulation validate human/other-actor ledgers. Existing optional-save absence maps to an empty ledger. Old no-record successor reporting is preserved. Narrow merge conflicts with shared files must be resolved deliberately; do not overwrite canonical changes.

New files: civic_administration.gd, civic_administration_knowledge.gd, test_civic_administration.gd and these review documents. The integrator owns four art assets and bindings, asset commit `ef1b24e5f670de84d9742de42c19d4b0e03ad2d5`. Generated untracked Godot UID/import files are excluded. No player or editor was interrupted; tests used explicit isolated headless paths.

## Boundaries

Jurisdiction is an owned settlement plus civic subjects, not drawn polygons, extraterritorial courts or personal-law systems. Petition origin is a condition-backed aggregate household report, not individually simulated petitioners. The registry retains128 petitions and up to32 dispositions each; old resolved petitions may retire for capacity while unresolved records stay. Mandates support up to365 days, conversational issuance90 days. Commands use explicit phrases; unrestricted semantic paraphrases are not implemented. Clerk work is abstract and paperwork materials are not separately consumed. Historical institutional breadth, licensing of clerical services, all natural progression paths and2500–3000-year pacing remain outside this batch's proof. The full5000-discovery goal remains unfinished.
