# ADAPTIVE_SCAN_TESTING_FINAL

## Project
Design of an Energy-Budget-Constrained Adaptive Scan Testing Architecture for Low-Power VLSI

## Correct intended behavior
1. Use ONE scan chain and ONE CUT.
2. Phase 1 is conventional fixed test-pattern scheduling. It runs first and consumes the cumulative test energy.
3. When cumulative energy reaches 70% of the total budget, the conventional scheduler stops completely.
4. There is NO second conventional hardware path and NO simultaneous conventional/adaptive hardware activity.
5. The same scan chain, CUT, fault detector, fault-coverage map and energy accumulator continue into Phase 2 without reset.
6. Phase 2 is dynamic ATPG / high-priority scheduling. It targets remaining undetected faults and considers transition cost.
7. 95% fault coverage is an acceptable milestone, NOT a stop condition.
8. Continue from 95% toward 100% whenever the remaining energy budget allows.
9. Stop at 100% coverage or when the total cumulative energy budget is exhausted. If no remaining candidate pattern fits the remaining budget, stopping is also necessary to remain within budget.

## Default simulation
- Energy budget = 5000 units
- Priority threshold = 3500 units (70%)
- Acceptable coverage = 95%
- Stop coverage = 100%
- Energy model = transitions x 1
- Fault model = 20 stuck-at faults

## Expected demonstration
For the default 5000-unit budget, the conventional fixed schedule should cross the 70% threshold first. The adaptive ATPG then takes over and uses the remaining energy to target remaining faults. The intended trace is:

CONVENTIONAL -> 70% ENERGY -> HIGH-PRIORITY ATPG -> 95% MILESTONE -> CONTINUE -> 100% -> STOP

The exact numbers depend on simulator scheduling and the configured pattern-cost model, but the control sequence is the required one.

## Run Xcelium
cd sim
chmod +x run.sh
./run.sh

Batch mode:
GUI=0 ./run.sh

Override budget:
./run.sh +BUDGET=5000

## Main waveform signals

Control:
- test_phase
- pattern_valid_drive
- pattern_drive
- target_fault_drive
- decision
- high_priority
- adaptive_mode
- priority_threshold
- test_complete

Scan/energy:
- scan_in
- scan_enable
- scan_data
- activity_delta
- activity
- energy_increment
- energy

Fault/coverage:
- active_fault
- actual_y
- golden_y
- fault_detected
- detected_faults
- detected_map
- coverage
- acceptable_reached
- full_coverage
- budget_exhausted

ATPG:
- atpg_request
- atpg_test_pattern
- atpg_target_fault
- atpg_pattern_valid
- atpg_selected_cost
- atpg_score
- atpg_predicted_gain
- atpg_done
- atpg_budget_blocked

## Results
- results/adaptive_results.txt
- results/adaptive_trace.csv
