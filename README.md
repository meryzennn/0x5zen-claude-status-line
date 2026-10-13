# 0x5zen Claude Status Line

Custom status line untuk [Claude Code](https://docs.claude.com/en/docs/claude-code/statusline) di Windows (PowerShell).

```
✻ Opus 5.5 · high | ctx: 42% | 📁 my-project | <branch-icon> main | ⏳ 5h: 18% (reset 2h 4m)
```

| Bagian | Isi |
|---|---|
| `✻ Opus 5.5` | Model aktif |
| `· high` | Effort level (warna beda per level, `max` pakai warna pelangi). Hilang kalau model tidak mendukung effort |
| `ctx: 42%` | Persentase context window yang terpakai |
| `📁 my-project` | Nama folder kerja |
| `main` | Branch git (`--` kalau bukan repo git) |
| `5h: 18% (reset 2h 4m)` | Pemakaian rate limit 5 jam dan sisa waktu reset. Hanya muncul untuk akun Pro/Max setelah respons pertama; sebelumnya `--` |

## Kebutuhan

- Windows dengan Windows PowerShell 5.1 (bawaan Windows) atau PowerShell 7
- Git di `PATH` (untuk nama branch)
- Terminal yang mendukung ANSI truecolor (Windows Terminal, VS Code terminal)
- Icon branch memakai glyph Powerline (`U+E0A0`); pakai [Nerd Font](https://www.nerdfonts.com/) agar tampil benar

## Pasang lewat agent Claude Code

Buka Claude Code, lalu tempel prompt ini:

```text
Pasang custom status line dari https://github.com/meryzennn/0x5zen-claude-status-line:
1. Download statusline.ps1 dari repo itu ke ~/.claude/statusline.ps1 (folder .claude di home user saya).
2. Baca isinya dulu sebelum dipakai.
3. Tambahkan ke ~/.claude/settings.json tanpa menghapus setting lain:
   "statusLine": {
     "type": "command",
     "command": "powershell -NoProfile -ExecutionPolicy Bypass -File <path absolut ke statusline.ps1, pakai slash />",
     "refreshInterval": 60
   }
   Kalau sudah ada "statusLine", backup dulu nilai lamanya dan tanyakan saya sebelum mengganti.
4. Tes dengan: echo '{"model":{"display_name":"Test"}}' | powershell -NoProfile -ExecutionPolicy Bypass -File <path tadi>
```

Status line muncul setelah Claude Code merespons pesan berikutnya (atau restart Claude Code).

## Pasang manual

1. Download [`statusline.ps1`](statusline.ps1) ke `C:\Users\<nama>\.claude\statusline.ps1`.
2. Edit `C:\Users\<nama>\.claude\settings.json`, tambahkan:

   ```json
   "statusLine": {
     "type": "command",
     "command": "powershell -NoProfile -ExecutionPolicy Bypass -File C:/Users/<nama>/.claude/statusline.ps1",
     "refreshInterval": 60
   }
   ```

   `refreshInterval` (detik) membuat countdown reset rate limit tetap jalan saat Claude Code idle.

3. Tes:

   ```powershell
   '{"model":{"display_name":"Test"}}' | powershell -NoProfile -ExecutionPolicy Bypass -File C:/Users/<nama>/.claude/statusline.ps1
   ```

   Kalau keluar `status unavailable`, ada error di script.

## Kustomisasi

- Warna effort: ubah hashtable `$colors` (kode warna ANSI).
- Urutan/isi segmen: ubah format string di baris `Write-Output` paling bawah.
- Script juga meneruskan payload ke `~/.orca/agent-hooks/claude-statusline.cmd` kalau file itu ada (integrasi Orca). Kalau tidak pakai Orca, bagian ini otomatis dilewati.
