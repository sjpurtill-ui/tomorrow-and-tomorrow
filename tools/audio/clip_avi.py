"""A court clip with its sound, as one video file, with nothing but Python and
Pillow (no ffmpeg on this machine): Motion-JPEG frames and 16-bit PCM audio
in an AVI, the kind every player opens (VLC, Windows Media Player, browsers
via a player).

Input: a folder Godot's movie writer filled (--write-movie <dir>/f.png
--fixed-fps N): f00000000.png ... and f.wav (the mix, any PCM width).
Output: <out>.avi (video + sound), <out>.wav (the sound alone, 16-bit, the
same length as the frames) for players that want them apart.

  python tools/audio/clip_avi.py <frame_dir> <out_base> [--fps 12] [--quality 88] [--gain auto|<dB>] [--scale 1.0]

--gain auto lifts the mix so its loudest moment sits at -3 dBFS (the game's
own level is quieter than a clip wants); a number is dB added as is.
"""
import os, sys, struct, wave, glob, io
import numpy as np
from PIL import Image

def read_wav(path):
    w = wave.open(path, 'rb')
    ch, width, rate, n = w.getnchannels(), w.getsampwidth(), w.getframerate(), w.getnframes()
    raw = w.readframes(n)
    if width == 4: d = np.frombuffer(raw, dtype='<i4').astype(np.float64) / 2**31
    elif width == 2: d = np.frombuffer(raw, dtype='<i2').astype(np.float64) / 2**15
    elif width == 3:
        b = np.frombuffer(raw, dtype=np.uint8).reshape(-1, 3)
        v = (b[:, 0].astype(np.int32) | (b[:, 1].astype(np.int32) << 8) | (b[:, 2].astype(np.int32) << 16))
        v = np.where(v >= 2**23, v - 2**24, v); d = v.astype(np.float64) / 2**23
    else: raise SystemExit("unsupported wav width %d" % width)
    d = d.reshape(-1, ch)
    if ch == 1: d = np.repeat(d, 2, axis=1)
    return d[:, :2], rate

def chunk(fourcc, data):
    out = fourcc + struct.pack('<I', len(data)) + data
    if len(data) % 2: out += b'\0'
    return out

def main():
    args = sys.argv[1:]
    if len(args) < 2: raise SystemExit(__doc__)
    frame_dir, out_base = args[0], args[1]
    opts = {'--fps': '12', '--quality': '88', '--gain': 'auto', '--scale': '1.0'}
    for i in range(2, len(args) - 1, 2): opts[args[i]] = args[i + 1]
    fps = int(opts['--fps']); quality = int(opts['--quality']); scale = float(opts['--scale'])
    frames = sorted(glob.glob(os.path.join(frame_dir, 'f*.png')))
    if not frames: raise SystemExit("no frames in " + frame_dir)
    audio, rate = read_wav(os.path.join(frame_dir, 'f.wav'))
    per = rate // fps
    if per * fps != rate: raise SystemExit("audio rate %d is not a whole number of samples a frame at %d fps" % (rate, fps))
    # the sound for exactly as long as the frames
    need = per * len(frames)
    if len(audio) < need: audio = np.vstack([audio, np.zeros((need - len(audio), 2))])
    audio = audio[:need]
    peak = float(np.abs(audio).max()) if len(audio) else 0.0
    if opts['--gain'] == 'auto': gain = (10 ** (-3 / 20) / peak) if peak > 1e-6 else 1.0
    else: gain = 10 ** (float(opts['--gain']) / 20)
    pcm = np.clip(audio * gain, -1, 1)
    pcm16 = (pcm * 32767).astype('<i2')
    with wave.open(out_base + '.wav', 'wb') as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(rate); w.writeframes(pcm16.tobytes())
    first = Image.open(frames[0]).convert('RGB')
    width, height = first.size
    if scale != 1.0: width, height = int(width * scale) // 2 * 2, int(height * scale) // 2 * 2
    # the movie: frames and their sound interleaved, one frame's worth each
    movi = bytearray(b'movi'); index = bytearray(); biggest = 0
    for i, path in enumerate(frames):
        img = Image.open(path).convert('RGB')
        if img.size != (width, height): img = img.resize((width, height), Image.LANCZOS)
        buf = io.BytesIO(); img.save(buf, 'JPEG', quality=quality); jpg = buf.getvalue()
        biggest = max(biggest, len(jpg))
        index += b'00dc' + struct.pack('<III', 0x10, len(movi), len(jpg)); movi += chunk(b'00dc', jpg)
        snd = pcm16[i * per:(i + 1) * per].tobytes()
        index += b'01wb' + struct.pack('<III', 0x10, len(movi), len(snd)); movi += chunk(b'01wb', snd)
    n = len(frames)
    avih = struct.pack('<IIIIIIIIII', int(1e6 / fps), int(biggest * fps + rate * 4), 0, 0x10 | 0x100, n, 0, 2,
                       biggest + per * 4, width, height) + b'\0' * 16
    vstrh = b'vids' + b'MJPG' + struct.pack('<IHHIIIIIIIIhhhh', 0, 0, 0, 0, 1, fps, 0, n, biggest, 0xFFFFFFFF, 0, 0, 0, width, height)
    vstrf = struct.pack('<IiiHH', 40, width, height, 1, 24) + b'MJPG' + struct.pack('<IiiII', width * height * 3, 0, 0, 0, 0)
    astrh = b'auds' + b'\0\0\0\0' + struct.pack('<IHHIIIIIIIIhhhh', 0, 0, 0, 0, 4, rate * 4, 0, need, per * 4, 0xFFFFFFFF, 4, 0, 0, 0, 0)
    astrf = struct.pack('<HHIIHHH', 1, 2, rate, rate * 4, 4, 16, 0)
    hdrl = b'hdrl' + chunk(b'avih', avih) + chunk(b'LIST', b'strl' + chunk(b'strh', vstrh) + chunk(b'strf', vstrf)) \
        + chunk(b'LIST', b'strl' + chunk(b'strh', astrh) + chunk(b'strf', astrf))
    body = b'AVI ' + chunk(b'LIST', hdrl) + chunk(b'LIST', bytes(movi)) + chunk(b'idx1', bytes(index))
    with open(out_base + '.avi', 'wb') as f: f.write(b'RIFF' + struct.pack('<I', len(body)) + body)
    print("%s.avi: %d frames %dx%d at %d fps, %.1f s, sound %d Hz stereo (gain %+.1f dB), %.1f MB" % (
        out_base, n, width, height, fps, n / fps, rate, 20 * np.log10(gain), os.path.getsize(out_base + '.avi') / 1e6))

if __name__ == '__main__': main()
