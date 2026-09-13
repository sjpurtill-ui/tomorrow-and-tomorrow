"""Export observed pacing samples; never synthesize or extrapolate discoveries.

The former generated-stage/calendar-gate curve did not run the game and is retired.
Use an actual audit_history_pacing report or its provenance-bearing compact archive.
"""
from __future__ import annotations
import argparse
import csv
import hashlib
import json
from pathlib import Path


def observed_samples(report: dict) -> list[dict]:
    elapsed = report['simulated_days']
    catalog = report['live_catalog']
    if type(elapsed) is not int or elapsed < 0 or type(catalog) is not int or catalog <= 0:
        raise ValueError('Invalid recorded duration or catalog count')
    rows = [report['initial'], *report.get('annual_snapshots', []), report['final']]
    by_day = {}
    for row in rows:
        day, known = row['day'], row['known']
        if type(day) is not int or not 0 <= day <= elapsed:
            raise ValueError('Sample day outside recorded run')
        if type(known) is not int or not 0 <= known <= catalog:
            raise ValueError('Sample discoveries outside recorded catalog')
        sample = {'day': day, 'year': day / 365.0, 'known': known,
                  'population': row.get('population'),
                  'civilian_lines': row.get('production', {}).get('civilian_lines'),
                  'installed_units': row.get('production', {}).get('installed_units')}
        if day in by_day and by_day[day] != sample:
            raise ValueError(f'Conflicting observations on day {day}')
        by_day[day] = sample
    if report['initial']['day'] != 0 or report['final']['day'] != elapsed:
        raise ValueError('Initial/final observations do not match run endpoints')
    return [by_day[day] for day in sorted(by_day)]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('report', type=Path, help='Recorded runtime JSON; never a synthetic forecast')
    parser.add_argument('--out', type=Path, required=True, help='Output directory for observed CSV and evidence summary')
    args = parser.parse_args()
    raw = args.report.read_bytes()
    report = json.loads(raw)
    samples = observed_samples(report)
    args.out.mkdir(parents=True, exist_ok=True)
    with (args.out / 'observed_discovery_pacing.csv').open('w', newline='') as handle:
        writer = csv.DictWriter(handle, fieldnames=list(samples[0]))
        writer.writeheader()
        writer.writerows(samples)
    result = {
        'evidence_kind': 'recorded_observations_no_interpolation',
        'input_report': str(args.report.resolve()),
        'input_sha256': hashlib.sha256(raw).hexdigest(),
        'source_commit': report.get('source_commit'),
        'source_report_sha256': report.get('source_sha256'),
        'live_catalog_at_run': report['live_catalog'],
        'scenario': report.get('scenario'),
        'simulated_years': report['simulated_days'] / 365.0,
        'requested_years': report['target_days'] / 365.0,
        'reported_target_reached': report.get('target_reached'),
        'stop_reason': report.get('stop_reason'),
        'observed_samples': len(samples),
        'initial': samples[0], 'final': samples[-1],
        'full_campaign_verified_by_this_export': False,
        'limitations': report.get('limitations', []) + [
            'Export verifies sample bounds and consistency, not report authenticity or gameplay correctness.',
            'Absent intermediate samples are not interpolated; endpoint values do not establish sustained production.',
            'Source catalog is historical unless independently matched to the current checkout.',
            'Reaching a requested horizon does not prove 5000 discoveries, recovery, viable progression or a full-world campaign.',
            'Old discovery_pacing_3000y CSV/SVG files are obsolete synthetic outputs, not runtime evidence.'
        ]}
    (args.out / 'observed_discovery_pacing.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({'recorded_years': result['simulated_years'],
                      'catalog': result['live_catalog_at_run'], 'samples': len(samples),
                      'full_campaign_verified': False}))


if __name__ == '__main__':
    main()
