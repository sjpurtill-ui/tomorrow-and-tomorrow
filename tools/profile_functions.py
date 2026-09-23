"""Temporarily wrap every function in the given GDScript files with an inclusive
timer (performance_trace.mark). timefuncs.py f.gd [...] | timefuncs.py --restore f.gd [...]
Skips _init/_ready/_process/_notification, getters/setters, and functions whose
signature spans lines."""
import sys, os, re, shutil
BK = 'artifacts/profile_functions_backup'; os.makedirs(BK, exist_ok=True)
SKIP = {'_init', '_ready', '_process', '_physics_process', '_notification', '_exit_tree', '_enter_tree', '_input', '_unhandled_input', '_draw', '_to_string', '_get', '_set', '_get_property_list'}
restore = sys.argv[1] == '--restore'
for path in sys.argv[2 if restore else 1:]:
    bk = os.path.join(BK, os.path.basename(path))
    if restore:
        shutil.copy(bk, path); os.remove(bk); print('restored', path); continue
    shutil.copy(path, bk)
    tag = os.path.basename(path).split('.')[0]
    lines = open(path, encoding='utf-8').read().split('\n')
    out = []
    sig = re.compile(r'^(static\s+)?func\s+(\w+)\s*\((.*)\)\s*(->\s*([\w\[\]\.]+))?\s*:(.*)$')
    for line in lines:
        m = sig.match(line)
        if not m or m.group(2) in SKIP:
            out.append(line); continue
        static, name, args, _, ret, body = m.groups()
        # split args at top-level commas
        depth = 0; cur = ''; parts = []
        for ch in args:
            if ch in '([{': depth += 1
            if ch in ')]}': depth -= 1
            if ch == ',' and depth == 0: parts.append(cur); cur = ''
            else: cur += ch
        if cur.strip(): parts.append(cur)
        names = [re.split(r'[:=]', p.strip())[0].strip() for p in parts]
        if any(not n or not re.match(r'^\w+$', n) for n in names):
            out.append(line); continue
        static = static or ''
        orig = '__t_' + name
        ret_s = ('->' + ret) if ret else ''
        call = '%s(%s)' % (orig, ','.join(names))
        wrapper = [
            '%sfunc %s(%s)%s:' % (static, name, args, ret_s),
            '\tvar __tr=preload("res://scripts/performance_trace.gd");var __st:int=__tr.start()',
        ]
        if ret == 'void':
            wrapper += ['\t' + call, '\t__tr.mark("%s.%s",__st)' % (tag, name)]
        elif ret:
            wrapper += ['\tvar __r:%s=%s' % (ret, call), '\t__tr.mark("%s.%s",__st)' % (tag, name), '\treturn __r']
        else:
            wrapper += ['\tvar __r=%s' % call, '\t__tr.mark("%s.%s",__st)' % (tag, name), '\treturn __r']
        out += wrapper
        out.append('%sfunc %s(%s)%s:%s' % (static, orig, args, ret_s, body))
    open(path, 'w', encoding='utf-8', newline='\n').write('\n'.join(out)); print('timed', path)
