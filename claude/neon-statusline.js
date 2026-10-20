#!/usr/bin/env node
// NEON NOIR · status line di Claude Code, stesso stile del prompt PowerShell:
//   ┌─[ …/Projects/app ]─[  main ● ]─[ ◆ Opus 5.5 · high ]─[ ctx ▰▰▰▱▱▱▱▱ 34% ]  +156 −23
//   ├─[ 5h ▰▰▱▱▱▱▱▱ 23% ↻ 2h 14m ]─[ 7g ▰▰▰▱▱▱▱▱ 41% ↻ 3g 5h ]
//   └─ ⚡ skill ● ecc:plan  update-config   ⧉ plugin ecc · vercel   ◈ mcp context7×10   ⚙ agent ecc:code-reviewer
// Dati da Claude Code (JSON su stdin). Skill/plugin/MCP/agenti si ricavano dal transcript della sessione,
// letto in modo incrementale (solo le righe nuove) con lo stato in %TEMP%\neon-statusline\<session>.json.
// "●" e colore acceso = usati nel prompt in corso; attenuati = usati prima nella sessione.
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');

const paint = (r, g, b) => (s) => `\x1b[38;2;${r};${g};${b}m${s}\x1b[0m`;
const dim = paint(85, 102, 95), cyan = paint(24, 214, 208), green = paint(57, 255, 136), text = paint(189, 242, 207);
const yellow = paint(230, 210, 90), purple = paint(164, 114, 255), red = paint(255, 56, 96), soft = paint(120, 140, 132);
const visible = (s) => s.replace(/\x1b\[[\d;]*m/g, '').length;
// lingua dalla sessione PowerShell che ha avviato Claude Code ($NeonConfig.Language → NEON_LANG); inglese di default
const L = process.env.NEON_LANG === 'it' ? { day: 'g', week: '7g', spend: 'spesa' } : { day: 'd', week: '7d', spend: 'spend' };

// ── directory e git ──
function shortPath(dir) {
  const home = os.homedir();
  let p = dir.toLowerCase().startsWith(home.toLowerCase()) ? '~' + dir.slice(home.length) : dir;
  p = p.replace(/\\/g, '/');
  const parts = p.split('/').filter(Boolean);
  return parts.length > 3 ? '…/' + parts.slice(-3).join('/') : p;
}

function gitBranch(dir) {
  for (let d = dir; ; d = path.dirname(d)) {
    const dotgit = path.join(d, '.git');
    if (fs.existsSync(dotgit)) {
      try {
        let gitdir = dotgit;
        if (fs.statSync(dotgit).isFile()) gitdir = path.resolve(d, fs.readFileSync(dotgit, 'utf8').replace(/^gitdir:\s*/, '').trim());
        const head = fs.readFileSync(path.join(gitdir, 'HEAD'), 'utf8').trim();
        return head.startsWith('ref:') ? head.replace(/^ref:\s*refs\/heads\//, '') : head.slice(0, 7);
      } catch { return ''; }
    }
    if (path.dirname(d) === d) return '';
  }
}

// ── barre e tempi ──
function bar(pct, width = 8) {
  const p = Math.max(0, Math.min(100, pct));
  const filled = Math.round((p / 100) * width);
  const color = p >= 80 ? red : p >= 60 ? yellow : green;
  return color('▰'.repeat(filled)) + dim('▱'.repeat(width - filled)) + ' ' + color(`${Math.round(p)}%`);
}

function until(epochSeconds) {
  const s = Math.max(0, epochSeconds - Date.now() / 1000);
  const d = Math.floor(s / 86400), h = Math.floor((s % 86400) / 3600), m = Math.floor((s % 3600) / 60);
  return d > 0 ? `${d}${L.day} ${h}h` : h > 0 ? `${h}h ${m}m` : `${m}m`;
}

function contextPercent(j) {
  const c = j.context_window;
  if (!c) return null;
  if (typeof c.used_percentage === 'number') return c.used_percentage;
  const u = c.current_usage;
  const used = u && (u.input_tokens || 0) + (u.cache_read_input_tokens || 0) + (u.cache_creation_input_tokens || 0);
  return used && c.context_window_size ? (used / c.context_window_size) * 100 : null;
}

// ── attività della sessione dal transcript ──
function classify(name, input, items) {
  const add = (kind, key) => {
    const it = items[kind + ':' + key] || (items[kind + ':' + key] = { kind, name: key, count: 0, seq: 0, turn: 0 });
    it.count++;
    return it;
  };
  const hits = [];
  if (name === 'Skill' && input && input.skill) {
    hits.push(add('skill', input.skill));
    if (input.skill.includes(':')) hits.push(add('plugin', input.skill.split(':')[0]));
  } else if ((name === 'Agent' || name === 'Task') && input && input.subagent_type) {
    hits.push(add('agent', input.subagent_type));
    if (input.subagent_type.includes(':')) hits.push(add('plugin', input.subagent_type.split(':')[0]));
  } else if (name.startsWith('mcp__')) {
    const server = name.slice(5).split('__')[0];
    const plug = server.match(/^plugin_([^_]+)_/);
    if (plug) hits.push(add('plugin', plug[1]));
    else hits.push(add('mcp', server.replace(/^claude_ai_/, '').replace(/_/g, ' ')));
  }
  return hits;
}

function sessionActivity(j) {
  const file = j.transcript_path;
  if (!file || !fs.existsSync(file)) return null;
  const cacheDir = path.join(os.tmpdir(), 'neon-statusline');
  const cacheFile = path.join(cacheDir, `${(j.session_id || 'session').replace(/[^\w-]/g, '')}.json`);
  let st = { offset: 0, turn: 0, seq: 0, items: {} };
  try { st = JSON.parse(fs.readFileSync(cacheFile, 'utf8')); } catch { /* prima lettura */ }

  const size = fs.statSync(file).size;
  if (size < st.offset) st = { offset: 0, turn: 0, seq: 0, items: {} };   // transcript riscritto
  if (size > st.offset) {
    const fd = fs.openSync(file, 'r');
    const buf = Buffer.alloc(size - st.offset);
    fs.readSync(fd, buf, 0, buf.length, st.offset);
    fs.closeSync(fd);
    const end = buf.lastIndexOf(0x0a);
    if (end >= 0) {
      st.offset += end + 1;
      for (const line of buf.toString('utf8', 0, end).split('\n')) {
        const isUser = line.includes('"type":"user"');
        if (!isUser && !line.includes('"tool_use"')) continue;
        let o; try { o = JSON.parse(line); } catch { continue; }
        const content = o.message && o.message.content;
        if (o.type === 'user') {
          // un nuovo prompt (non un tool_result) apre un nuovo turno
          const isPrompt = typeof content === 'string' || (Array.isArray(content) && content.some((c) => c.type === 'text') && !content.some((c) => c.type === 'tool_result'));
          if (isPrompt && !o.isMeta) {
            st.turn++;
            const txt = typeof content === 'string' ? content : content.filter((c) => c.type === 'text').map((c) => c.text).join(' ');
            const cmd = txt.match(/<command-name>\/?([^<\s]+)<\/command-name>/);
            if (cmd) for (const it of classify('Skill', { skill: cmd[1] }, st.items)) { it.seq = ++st.seq; it.turn = st.turn; }
          }
        } else if (o.type === 'assistant' && Array.isArray(content)) {
          for (const c of content) {
            if (c.type !== 'tool_use') continue;
            for (const it of classify(c.name || '', c.input, st.items)) { it.seq = ++st.seq; it.turn = st.turn; }
          }
        }
      }
      try { fs.mkdirSync(cacheDir, { recursive: true }); fs.writeFileSync(cacheFile, JSON.stringify(st)); } catch { /* cache non scrivibile: si rilegge la prossima volta */ }
    }
  }
  return st;
}

function activityLine(st, width) {
  if (!st) return '';
  const groups = [
    ['skill', yellow, '⚡ skill'], ['plugin', purple, '⧉ plugin'], ['mcp', cyan, '◈ mcp'], ['agent', green, '⚙ agent'],
  ];
  const parts = [];
  for (const [kind, color, label] of groups) {
    const list = Object.values(st.items).filter((i) => i.kind === kind).sort((a, b) => b.seq - a.seq);
    if (!list.length) continue;
    const shown = list.slice(0, 4).map((i) => {
      const n = i.name + (i.count > 1 ? dim(`×${i.count}`) : '');
      return i.turn === st.turn ? color('● ') + color(n) : soft(n);
    });
    parts.push(dim(label + ' ') + shown.join(dim(' · ')) + (list.length > 4 ? dim(` +${list.length - 4}`) : ''));
  }
  if (!parts.length) return '';
  let line = dim('└─ ') + parts.join('   ');
  // tronca per stare nella larghezza del terminale
  while (visible(line) > width && parts.length > 1) { parts.pop(); line = dim('└─ ') + parts.join('   ') + dim(' …'); }
  return line;
}

// ── main ──
let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', (d) => (input += d));
process.stdin.on('end', () => {
  let j = {};
  try { j = JSON.parse(input); } catch { /* JSON assente: solo la directory */ }
  const width = parseInt(process.env.COLUMNS, 10) || 140;
  const dir = (j.workspace && j.workspace.current_dir) || j.cwd || process.cwd();

  // riga 1: dove · branch · modello · contesto · righe modificate
  const l1 = [dim('┌─[ ') + cyan(shortPath(dir)) + dim(' ]')];
  const branch = gitBranch(dir);
  if (branch) {
    let dirty = false;
    try {
      dirty = execFileSync('git', ['--no-optional-locks', '-C', dir, 'status', '--porcelain', '-uno'],
        { timeout: 800, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim().length > 0;
    } catch { /* repository non leggibile */ }
    l1.push(dim('─[ ') + (dirty ? yellow : green)(' ' + branch + (dirty ? ' ●' : '')) + dim(' ]'));
  }
  const model = j.model && (j.model.display_name || j.model.id);
  if (model) {
    const extra = [j.effort && j.effort.level, j.fast_mode ? 'fast' : ''].filter(Boolean).join(' · ');
    l1.push(dim('─[ ') + purple('◆ ' + model) + (extra ? dim(' · ') + text(extra) : '') + dim(' ]'));
  }
  const pct = contextPercent(j);
  if (pct !== null) l1.push(dim('─[ ') + dim('ctx ') + bar(pct) + dim(' ]'));
  const c = j.cost || {};
  if (c.total_lines_added || c.total_lines_removed) l1.push('  ' + green(`+${c.total_lines_added || 0}`) + ' ' + red(`−${c.total_lines_removed || 0}`));

  // riga 2: limiti del piano (solo Pro/Max, dopo la prima risposta)
  const rl = j.rate_limits || {};
  const l2 = [];
  if (rl.five_hour && typeof rl.five_hour.used_percentage === 'number')
    l2.push(dim('[ ') + dim('5h ') + bar(rl.five_hour.used_percentage) + (rl.five_hour.resets_at ? dim(' ↻ ' + until(rl.five_hour.resets_at)) : '') + dim(' ]'));
  if (rl.seven_day && typeof rl.seven_day.used_percentage === 'number')
    l2.push(dim('[ ') + dim(L.week + ' ') + bar(rl.seven_day.used_percentage) + (rl.seven_day.resets_at ? dim(' ↻ ' + until(rl.seven_day.resets_at)) : '') + dim(' ]'));
  if (rl.spend_limit && typeof rl.spend_limit.used_percentage === 'number')
    l2.push(dim('[ ') + dim(L.spend + ' ') + bar(rl.spend_limit.used_percentage) + dim(' ]'));

  // riga 3: skill / plugin / mcp / agenti della sessione
  let l3 = '';
  try { l3 = activityLine(sessionActivity(j), width); } catch { /* transcript illeggibile: nessuna riga */ }

  const out = [l1.join('')];
  if (l2.length) out.push(dim(l3 ? '├─' : '└─') + l2.join(dim('─')));
  if (l3) out.push(l2.length ? l3 : l3.replace('└─', '└─'));
  process.stdout.write(out.join('\n'));
});
