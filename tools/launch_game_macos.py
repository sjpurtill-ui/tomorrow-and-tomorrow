#!/usr/bin/env python3
"""Build the integrated game with the release template; open a fresh campaign."""
import argparse
import datetime
from pathlib import Path
import subprocess
import sys

CANONICAL = Path('/Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow')
GODOT = Path('/Applications/Godot.app/Contents/MacOS/Godot')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build-only', action='store_true', help='Build without opening a game; also allowed in a development worktree.')
    parser.add_argument('--resume-saved', action='store_true', help='Resume quicksave instead of starting a fresh world.')
    args = parser.parse_args()
    game_root = Path(__file__).resolve().parents[1]

    def git(*parts):
        return subprocess.check_output(['git', '-C', str(game_root), *parts], text=True).strip()

    if not args.build_only and (game_root != CANONICAL or git('branch', '--show-current') != 'main'):
        raise RuntimeError('Player launches require the canonical Mac checkout on integrated main.')
    if (game_root / 'override.cfg').exists():
        raise RuntimeError('Remove the reviewed test override before building or launching the player game.')
    config = (game_root / 'project.godot').read_text()
    if 'run/main_scene="res://local_terrain.tscn"' not in config or 'config/use_custom_user_dir=true' in config:
        raise RuntimeError('The project has a test entry point or test userdata setting.')
    if not args.build_only and git('status', '--porcelain', '--untracked-files=no'):
        raise RuntimeError('Commit and verify the integrated changes before a player launch.')
    if not args.build_only:
        for line in subprocess.check_output(['ps', '-ax', '-o', 'pid=,command='], text=True).splitlines():
            if str(game_root) in line and '--headless' not in line.split() and '--editor' not in line.split():
                if '/Contents/MacOS/Godot ' in line or '/Contents/MacOS/Tomorrow and Tomorrow ' in line:
                    raise RuntimeError('A game is already running. Exit it normally before launching another.')

    revision = git('rev-parse', '--short=12', 'HEAD')
    destination = game_root / 'artifacts' / 'macos-release' / revision
    destination.mkdir(parents=True, exist_ok=True)
    app = destination / 'Tomorrow and Tomorrow.app'
    executable = app / 'Contents' / 'MacOS' / 'Tomorrow and Tomorrow'
    build_log = destination / 'export.log'
    complete = destination / 'build.ok'
    if not executable.exists() or not complete.exists() or args.build_only:
        complete.unlink(missing_ok=True)
        with build_log.open('w') as output:
            subprocess.run([str(GODOT), '--headless', '--path', str(game_root), '--export-release', 'macOS Release', str(app)], cwd=game_root, stdout=output, stderr=subprocess.STDOUT, check=True)
        subprocess.run(['/usr/bin/codesign', '--verify', '--deep', '--strict', str(app)], check=True)
        if executable.is_file():
            complete.write_text(git('rev-parse', 'HEAD') + '\n')
    if not executable.is_file():
        raise RuntimeError(f'The release executable was not produced. See {build_log}')
    print(f'Release build {revision}: {app}', flush=True)
    if args.build_only:
        return
    stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    player_log = destination / f'player-{stamp}.log'
    # Official release templates load their bundled project and reject --path.
    # The absolute executable path identifies this canonical checkout/build.
    command = [str(executable), '--log-file', str(player_log)]
    if args.resume_saved:
        command += ['--', '--resume-saved']
    with (destination / f'stdout-{stamp}.log').open('w') as output:
        player = subprocess.Popen(command, cwd=game_root, stdin=subprocess.DEVNULL, stdout=output, stderr=subprocess.STDOUT, start_new_session=True)
    print(f'Launched standalone release PID {player.pid}; {"resume quicksave" if args.resume_saved else "fresh world"}.')
    print(f'Player log: {player_log}')


if __name__ == '__main__':
    try:
        main()
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        print(f'Launch failed: {error}', file=sys.stderr)
        sys.exit(1)
