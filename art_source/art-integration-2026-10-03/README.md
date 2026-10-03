# Art backlog integration, October 3, 2026

Current player checkout: C:/Users/sjpur/TomorrowandTomorrow.
Integration worktree: C:/Users/sjpur/tt-art-production-paired-02.
Branch: codex/integrate-art-backlog; base ba77e9646925909ebb94e32441754bb3e9c5f725.

Reconciles 47 completed worker deliveries in ascending PR order, each as a separate merge. Shared JSON conflicts were resolved recursively against each worker base, preserving disjoint existing entries. The research helper combines opening_focus, art600 focus, the three first opening corrections, and the twelve-field wide overview guard. Test selection options from both earliest opening probes are preserved.

513 new or replacement player image files retain their exact worker bytes; 84 separate style reference PNGs are also retained. Runtime checks cover 247 updated research subject bindings, 263 approved artifact records (including nine recovered prior images), and twelve field overviews. These counts describe different scopes and are not additive image-file counts. Historical interpretations and exact generation prompts remain in the original worker READMEs and source metadata. Failed or deliberately held variants remain unbound. Production for the rest of the game remains incomplete.

inventory.json records source hashes, expected bindings/focus, worker commits and individual merge commits. verify.tscn loads the actual game resolvers, live catalogue, imported textures and painting crop helper. Research sources/focus are checked at years 0,1,3,299,300,600, together with provenance, hidden-art gating and both 708x210 and 264x70 crop bounds. Artifact checks cover approved lookup, source hashes, maximum 512px imports and separation from living makers. Field overviews are checked across five era states. The private GPU probe additionally captures three research pages, the latest twelve artifact tiles, and all twelve overviews.

Validation: combined headless runtime passed all 247 subjects, 263 artifact records and twelve overviews. Artifact bank audit: 1574 approved, 6 generated (held), 2516 pending; errors=[]. Full editor import exited 0; its only diagnostics were 952 instances of the existing untextured court-mesh tangent message, explicitly exempted by the canonical launcher. No other import errors occurred. No simulation or save-schema changes. Tests use a private user-data directory; no campaign save is accessed. No player/editor process was stopped.

Private GPU results and final main delivery are recorded in docs/INTEGRATION_STATUS.md. Local import logs and rendered captures stay under artifacts/. The test override is removed before delivery.
