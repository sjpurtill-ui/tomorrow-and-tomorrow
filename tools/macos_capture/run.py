#!/usr/bin/env python3
"""Run the owned landscape and scouting captures without presenting a player window."""
import argparse
import fcntl
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
SOURCE = Path(__file__).resolve().parent
BUILD = ROOT / 'artifacts' / 'macos-background-capture'
GODOT = Path('/Applications/Godot.app/Contents/MacOS/Godot')
ALLOWED = {'canopy_transition_probe', 'seasonal_landscape_probe', 'terrain_lod_probe', 'ancient_scouting_probe', 'woodland_scale_probe'}
MARKERS = {'canopy_transition_probe': 'CANOPY_TRANSITION_CAPTURE PASS',
           'woodland_scale_probe': 'WOODLAND_SCALE_CAPTURE PASS',
           'seasonal_landscape_probe': 'SEASONAL_LANDSCAPE_CAPTURE PASS',
           'terrain_lod_probe': 'TERRAIN_LOD_CAPTURE PASS',
           'ancient_scouting_probe': 'ANCIENT_SCOUTING_CAPTURE PASS'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('probe', choices=sorted(ALLOWED))
    parser.add_argument('--preflight-only', action='store_true')
    args = parser.parse_args()
    override = ROOT / 'override.cfg'
    userdata = 'TomorrowAncientScoutingTests' if args.probe == 'ancient_scouting_probe' else 'TomorrowCanopyTransitionTests'
    if not override.is_file() or f'config/custom_user_dir_name="{userdata}"' not in override.read_text():
        raise RuntimeError('The owned ' + userdata + ' userdata override is required.')
    if ROOT == Path('/Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow'):
        raise RuntimeError('Native capture harness must run in its explicit task worktree.')
    BUILD.mkdir(parents=True, exist_ok=True)
    capture_lock = (BUILD / 'capture.lock').open('w')
    fcntl.flock(capture_lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    guard = BUILD / 'capture_guard.dylib'
    check = BUILD / 'CanopyGuardCheck'
    private = BUILD / 'GodotCanopyProbe'
    subprocess.run(['clang', '-dynamiclib', '-framework', 'AppKit', '-o', str(guard), str(SOURCE / 'guard.m')], check=True)
    subprocess.run(['clang', '-framework', 'AppKit', '-o', str(check), str(SOURCE / 'check.m')], check=True)
    # Never re-sign the installed editor or a normal release. Only this copy.
    shutil.copy2(GODOT, private)
    subprocess.run(['codesign', '--force', '--sign', '-', '--options', '0', str(private)], check=True)
    env = os.environ.copy()
    env.update(DYLD_INSERT_LIBRARIES=str(guard), TT_CAPTURE_OWNER='canopy-transition')
    with (BUILD / 'preflight.log').open('w') as log:
        subprocess.run([str(check)], env=env, stdout=log, stderr=subprocess.STDOUT, check=True, timeout=20)
        subprocess.run([str(private), '--headless', '--version'], env=env, stdout=log, stderr=subprocess.STDOUT, check=True, timeout=20)
    proof = (BUILD / 'preflight.log').read_text()
    if 'TT_CAPTURE_CANARY PASS' not in proof or 'TT_CAPTURE_GUARD_READY GodotCanopyProbe' not in proof:
        raise RuntimeError('Guard verification failed; no graphical probe was launched.')
    print('Background guard verified; installed Godot and normal player apps are unchanged.', flush=True)
    if args.preflight_only:
        return
    command = [str(private), '--path', str(ROOT), '--audio-driver', 'Dummy',
               '--rendering-method', 'gl_compatibility', '--windowed', '--resolution', '64x64',
               'res://tests/' + args.probe + '.tscn']
    log_path = BUILD / (args.probe + '.log')
    with log_path.open('w') as log:
        result = subprocess.run(command, cwd=ROOT, env=env, stdin=subprocess.DEVNULL,
                                stdout=log, stderr=subprocess.STDOUT, timeout=900)
    output = log_path.read_text()
    if result.returncode or 'SCRIPT ERROR:' in output or '\nERROR:' in output:
        raise RuntimeError('Native probe failed; inspect ' + str(log_path))
    if 'TT_CAPTURE_GUARD_READY GodotCanopyProbe' not in output:
        raise RuntimeError('Native probe did not verify its guard; inspect ' + str(log_path))
    if MARKERS[args.probe] not in output:
        raise RuntimeError('Native probe did not report completed checks; inspect ' + str(log_path))
    print('Probe exited. Inspect capture results and images: ' + str(log_path), flush=True)


if __name__ == '__main__':
    try:
        main()
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        print('Capture failed: ' + str(error), file=sys.stderr)
        sys.exit(1)
