# Secure and Efficient Computing Review

Sixteen new modern-history discoveries for review. This branch contains **3,072 distinct authored identities: 657 verified runtime definitions and 2,415 drafts**, leaving **1,928** of the 5,000 target unauthored. Canonical water integration is separate and promotes existing identities without changing this total. These sixteen records are design proposals, not playable features.

## What changes in play

Secure hardware creates an industrial and institutional choice: pay for installed devices and continuing qualification, or depend on an external provider with finite capacity and delivery costs. Faster cryptography does not make a cipher stronger. Isolating keys differs from ordinary memory permissions; sideloading differs from key derivation; measuring leakage differs from repairing it. No discovery guarantees immunity to compromise.

Power management makes energy, throughput and response time competing constraints. A sleepy machine can miss a deadline; an always-ready machine consumes more power. Governors choose among qualified operating states, while the physical supply, cooling and installed equipment remain necessary. These are proposed consumers for the existing finite computation and power systems; no numerical savings are claimed.

## Proposed branches and consumers

All entries require every listed mandatory parent and one parent from each alternative group. Equipment imports can substitute for manufacturing access during operation, while local qualification and prerequisite mastery remain required. Dates and civilization identity do not unlock these practices.

| Discovery | Mandatory foundations | Alternative foundations | Operating requirement and consequence |
|---|---|---|---|
| Hardware Entropy Health Testing | analog_digital_conversion | statistical_inference OR probability_theory | Sampled noise hardware, reference tests and failure reporting. Stops weak random supply; blocks dependent secure services until repaired. |
| Cryptographic Random Bit Expansion | hardware_entropy_health_testing, cryptographic_protocol_design | None | Protected generator state and finite fresh entropy. Supplies bounded random requests; stale or compromised state requires recovery. |
| Hardware Root Key Isolation | cryptographic_identity_management, memory_protection | integrated_circuit_fabrication OR programmable_logic_arrays | Provisioned protected device and controlled service interface. Allows authentication without exposing root keys to ordinary software. |
| Hardware Key Derivation States | hardware_root_key_isolation, content_integrity_hashing | None | Protected derivation engine and recorded device ownership transitions. Limits cross-context key reuse; state transitions can retire old access. |
| Cryptographic Key Sideload | hardware_root_key_isolation | cryptographic_block_acceleration OR programmable_logic_arrays | Compatible protected interfaces and qualified interconnect. Avoids ordinary memory copies while binding use to installed equipment. |
| Cryptographic Block Acceleration | cryptographic_protocol_design | integrated_circuit_fabrication OR programmable_logic_arrays | Qualified cipher hardware, power and data interface. Raises finite secure-message throughput; does not improve the underlying cipher guarantee. |
| Masked Cryptographic Datapaths | cryptographic_block_acceleration, cryptographic_random_bit_expansion | None | Additional logic, randomness bandwidth and qualification trials. Reduces tested leakage at extra area and execution cost; no universal immunity. |
| Constant Time Secret Operations | cryptographic_protocol_design, software_verification | None | Reviewed code and timing measurements on the target machine. Reduces timing exposure with a possible throughput cost. |
| Cryptographic Leakage Qualification | cryptographic_protocol_design, instrumentation_amplifier_circuits | None | Instrumented samples, controlled experiments and analyst work. Reveals vulnerable implementations; testing itself does not repair them. |
| Fault Detecting Security Control | finite_state_models, redundant_sensor_voting | None | Qualified logic and fault trials on actual hardware. Detected corruption aborts a sensitive operation; faults outside the test model remain possible. |
| Dynamic Voltage and Frequency Scaling | hardware_timing_closure, operating_system_device_drivers | linear_voltage_regulation OR switch_mode_power_conversion | Adjustable hardware, stable supply and characterized operating points. Trades compute throughput against power; unsupported low voltage causes rejected settings or faults. |
| Idle Residency Governors | hardware_interrupt_handling, process_scheduling | None | Supported sleep states and measured entry and exit costs. Long idle periods save energy; frequent wakeups can erase the gain. |
| Device Runtime Suspend | operating_system_device_drivers | None | Driver callbacks, usage tracking and a wake-capable device where needed. Reduces peripheral consumption; resume latency can delay work. |
| Power Domain Dependency Ordering | device_runtime_suspend, finite_state_models | None | Declared device dependencies and checked transition sequencing. Prevents powering down a live dependency; shared demand may keep a domain awake. |
| Energy Aware Task Placement | process_scheduling, compute_power_budgeting | None | Calibrated processors, workload demand estimates and scheduling capacity. Can reduce work energy while respecting capacity; inaccurate models may select worse placements. |
| Latency Bounded Power Policy | idle_residency_governors, dynamic_voltage_frequency_scaling, real_time_computing | None | Measured transition times, workload deadlines and qualified controller. Keeps urgent workloads responsive by forgoing some energy savings. |

## Recovery routes

Each record includes five explicit proposed contracts: paid scholar travel and supervised trials; partnerships with reciprocal experimental contributions; commissioned research with uncertain outcomes; delivered equipment or metered licensed service; and analysis of an obtained sample. All require reachable sources, delay, local work and actual operating resources. They grant neither instant mastery nor manufacturing ability. These record-level contracts still need runtime implementation and acceptance testing.

## Evidence and scope limits

The technical sources establish mechanisms, not the game's causal graph or its balance. Those are editorial proposals:

- [NIST entropy-source recommendation](https://nvlpubs.nist.gov/nistpubs/specialpublications/nist.sp.800-90b.pdf) supports qualification of physical randomness; deterministic expansion is a separate proposed consumer of qualified seed supply.
- [OpenTitan key manager](https://opentitan.org/book/hw/ip/keymgr/) supports hidden root state, derived keys and hardware delivery of keys.
- [OpenTitan cipher hardware](https://opentitan.org/book/hw/ip/aes/) supports finite acceleration and masking costs.
- [OpenTitan secure hardware guidelines](https://opentitan.org/book/doc/security/implementation_guidelines/hardware/) distinguish timing leakage, physical leakage and fault countermeasures under a declared threat model.
- [Linux CPU performance scaling](https://cdn.kernel.org/doc/html/latest/admin-guide/pm/cpufreq.html), [idle management](https://www.kernel.org/doc/html/latest/driver-api/pm/cpuidle.html), [runtime device power management](https://docs.kernel.org/power/runtime_pm.html) and [energy models](https://cdn.kernel.org/doc/html/latest/power/energy-model.html) provide concrete examples of workload and latency constrained power control.

Cryptographic hardware atlas subject D21-20 now has mapped authored scope. Energy-proportional computing D21-25 remains partial because dedicated clock-gating and retention/isolation circuit qualification are still absent. Quantum fault tolerance also remains partial. No atlas label is counted as an additional discovery.

## Handoff

Worktree `/Users/seanpurtill/Documents/Codex/tt-computing-coverage`, branch `codex/computing-coverage`, base `7a5e91ff9cc2005c1560bdb348fc8ff67e796044`. Documents only; no runtime or save-format change. All sixteen receive H05 editorial horizon assignments with scope digests, not date gates. Identity, normalized-name and AND/OR reachability checks pass with no missing parents or unreachable drafts. Existing meanings were reviewed against the D21 inventory; broader historical/semantic review and operating implementation remain necessary.

Integrator: merge new records and mappings, preserve newer runtime promotion data, regenerate coverage rather than overwriting it from this older baseline, and update the current combined count. No Godot test was run for this documentation-only batch.
