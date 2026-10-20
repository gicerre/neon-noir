// ── NEON NOIR · predittore PSReadLine "qui" ─────────────────────────────────
// Suggerisce solo i comandi eseguiti con successo nella directory corrente.
// Archivio: righe "<directory>\t<comando>" in %LOCALAPPDATA%\neon\dirhistory.tsv,
// condiviso tra le sessioni (lettura incrementale) e compattato oltre i 2 MB.
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Threading;
using System.Management.Automation.Subsystem.Prediction;

namespace Neon
{
    public sealed class DirHistory : ICommandPredictor
    {
        public const int MaxSuggestions = 10;
        const int KeepPerDir = 50;
        const long CompactAbove = 2 * 1024 * 1024;

        static readonly object Gate = new object();
        static readonly Dictionary<string, List<string>> ByDir = new Dictionary<string, List<string>>(StringComparer.OrdinalIgnoreCase);
        static string _file;
        static long _offset;
        static volatile string _cwd = string.Empty;

        public static readonly Guid PredictorId = new Guid("8d6f3c2a-5b1e-4e7a-9c3d-0e0e0de70010");
        public Guid Id => PredictorId;
        public string Name => "qui";
        public string Description => "Ultimi comandi riusciti nella directory corrente";

        public static void Init(string file)
        {
            lock (Gate)
            {
                _file = file;
                Directory.CreateDirectory(Path.GetDirectoryName(file));
                if (!File.Exists(file)) File.WriteAllText(file, string.Empty);
                ReadNew();
                if (new FileInfo(file).Length > CompactAbove) Compact();
            }
        }

        public static void SetCwd(string dir) => _cwd = Normalize(dir);

        public static void Record(string dir, string cmd)
        {
            if (_file == null || string.IsNullOrWhiteSpace(cmd) || cmd.IndexOf('\n') >= 0) return;
            dir = Normalize(dir);
            cmd = cmd.Trim();
            byte[] line = Encoding.UTF8.GetBytes(dir + "\t" + cmd + "\n");
            lock (Gate)
            {
                bool written = false;
                for (int i = 0; i < 3 && !written; i++)
                {
                    try
                    {
                        using (var fs = new FileStream(_file, FileMode.Append, FileAccess.Write, FileShare.ReadWrite | FileShare.Delete))
                            fs.Write(line, 0, line.Length);
                        written = true;
                    }
                    catch (IOException) { Thread.Sleep(15); }
                }
                if (written) ReadNew();   // rilegge anche le righe scritte da altre sessioni
                else Add(dir, cmd);
            }
        }

        public SuggestionPackage GetSuggestion(PredictionClient client, PredictionContext context, CancellationToken cancellationToken)
        {
            var matches = Suggestions(_cwd, context.InputAst.Extent.Text);
            if (matches.Count == 0) return default;
            var result = new List<PredictiveSuggestion>(matches.Count);
            foreach (string c in matches) result.Add(new PredictiveSuggestion(c));
            return new SuggestionPackage(result);
        }

        // Ciò che la lista live mostra per questo testo: prima i comandi che iniziano con il testo,
        // poi quelli che lo contengono; dal più recente, massimo 10
        public static List<string> Suggestions(string dir, string input)
        {
            var result = new List<string>();
            if (string.IsNullOrWhiteSpace(input)) return result;
            string[] items = Snapshot(dir);
            string needle = input.Trim();
            var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            for (int pass = 0; pass < 2 && result.Count < MaxSuggestions; pass++)
            {
                for (int i = items.Length - 1; i >= 0 && result.Count < MaxSuggestions; i--)
                {
                    string c = items[i];
                    bool prefix = c.StartsWith(input, StringComparison.OrdinalIgnoreCase);
                    bool match = pass == 0 ? prefix : !prefix && c.IndexOf(needle, StringComparison.OrdinalIgnoreCase) >= 0;
                    if (match && !c.Equals(input, StringComparison.OrdinalIgnoreCase) && seen.Add(c)) result.Add(c);
                }
            }
            return result;
        }

        // Per le frecce: tutti i comandi della directory che iniziano con il prefisso, dal più recente
        public static string[] History(string dir, string prefix)
        {
            string[] items = Snapshot(dir);
            prefix = prefix ?? string.Empty;
            var result = new List<string>();
            for (int i = items.Length - 1; i >= 0; i--)
            {
                string c = items[i];
                if (c.StartsWith(prefix, StringComparison.OrdinalIgnoreCase) && !c.Equals(prefix, StringComparison.OrdinalIgnoreCase))
                    result.Add(c);
            }
            return result.ToArray();
        }

        static string[] Snapshot(string dir)
        {
            lock (Gate)
            {
                ReadNew();
                return ByDir.TryGetValue(Normalize(dir), out var list) ? list.ToArray() : Array.Empty<string>();
            }
        }

        static string Normalize(string dir)
        {
            if (string.IsNullOrEmpty(dir)) return string.Empty;
            return dir.Length > 3 ? dir.TrimEnd('\\', '/') : dir;
        }

        static void Add(string dir, string cmd)
        {
            if (cmd.Length == 0) return;
            if (!ByDir.TryGetValue(dir, out var list)) ByDir[dir] = list = new List<string>();
            list.Remove(cmd);
            list.Add(cmd);
            if (list.Count > KeepPerDir) list.RemoveRange(0, list.Count - KeepPerDir);
        }

        // Legge solo le righe complete aggiunte dall'ultima lettura
        static void ReadNew()
        {
            try
            {
                using (var fs = new FileStream(_file, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
                {
                    if (fs.Length < _offset) { _offset = 0; ByDir.Clear(); }   // compattato da un'altra sessione
                    if (fs.Length == _offset) return;
                    fs.Seek(_offset, SeekOrigin.Begin);
                    var buf = new byte[fs.Length - _offset];
                    int read = 0;
                    while (read < buf.Length)
                    {
                        int n = fs.Read(buf, read, buf.Length - read);
                        if (n <= 0) break;
                        read += n;
                    }
                    if (read == 0) return;
                    int end = Array.LastIndexOf(buf, (byte)'\n', read - 1);
                    if (end < 0) return;
                    _offset += end + 1;
                    foreach (string raw in Encoding.UTF8.GetString(buf, 0, end + 1).Split('\n'))
                    {
                        int tab = raw.IndexOf('\t');
                        if (tab > 0) Add(raw.Substring(0, tab), raw.Substring(tab + 1).TrimEnd('\r'));
                    }
                }
            }
            catch (IOException) { }
        }

        static void Compact()
        {
            try
            {
                var sb = new StringBuilder();
                foreach (var kv in ByDir)
                    foreach (string c in kv.Value) sb.Append(kv.Key).Append('\t').Append(c).Append('\n');
                string tmp = _file + ".tmp";
                File.WriteAllText(tmp, sb.ToString(), new UTF8Encoding(false));
                File.Move(tmp, _file, true);
                _offset = new FileInfo(_file).Length;
            }
            catch (IOException) { }
        }
    }
}
