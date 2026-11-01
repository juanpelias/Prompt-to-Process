# AI Usage Disclosure

**Student:** Arul Dsena
**Assignment:** CSCE 465/765 HW3 — Task 4 (DAC/AppArmor confinement)

---

**Tool/model and date:**
Claude (Anthropic), Oct 25–28, 2026

**Purpose:**
Assistance with Task 4: setting up the `agentlab` low-privilege user and
DAC permissions, writing and debugging an AppArmor MAC profile for
`legacy_log_parser`, diagnosing why confined runs were failing
(directory-traversal permissions, a missing `mkdir` rule caught via the
kernel denial log), designing a control test to isolate MAC enforcement
from DAC, and structuring the report write-up (profile-design
rationale, denial-log selection, and the conceptual explanation of
reference monitor / complete mediation / access matrix / DAC / MAC /
least privilege).

**AI Conversation Log files:**
[Export this conversation and include it, e.g. `ai-logs/claude-task4.md` —
no passwords, API keys, or personal info were present, so nothing needed
to be redacted.]

**What I used:**
- Guidance on `useradd`/group-based DAC permission scoping for `agentlab`
- An initial AppArmor profile draft mapping each of the five Task 4
  requirements (payload read, markers-only write, explicit decoy deny,
  shell-exec deny, minimal-libs-to-start) to specific profile rules
- Step-by-step debugging help for two real failures I hit on my VM:
  1. A corrupted profile (lexer error on load) caused by a bad paste
     into `nano`; fixed by recreating the file with a heredoc instead.
  2. `sudo -u agentlab ./legacy_log_parser: Permission denied`, which
     turned out to be a directory-traversal permissions issue
     (`/home/ubuntu` lacked `o+x`/`g+x` for `agentlab` to reach deeper
     into the path), diagnosed using `namei -l`.
- Help designing the DAC-vs-MAC control test (loosening the decoy
  file's permissions to `644` and confirming AppArmor still blocked
  the read) and a shell script (`capture_task4_evidence.sh`) to
  reproduce the full demonstration in one consistent run for
  screenshots.
- A framework/outline for the required 400–600 word explanation of
  reference monitor, complete mediation, access matrix, DAC, MAC, and
  least privilege, including which specific log lines and test results
  from my own run to use as evidence for each concept.

**What I changed:**
Nothing structural — I used the group name, paths, and profile rules
as suggested. My role was reading through each suggestion, checking it
against my VM's actual state (file ownership, directory permissions,
`aa-status` output, kernel logs), and confirming it before running it,
rather than running commands blind.

**How I tested it:**
Every command was run directly on my own course VM, not just
copy-pasted on faith. I captured real `gcc`/`checksec` output, real
`aa-status` and `journalctl -k` output, and confirmed the control test
result myself: with `/opt/agentsec/decoy.txt` set to `644` (so DAC
alone would permit a read), the exploit still failed to read it, and
the kernel log showed an explicit `apparmor="DENIED"` entry
(`operation="open"`, `name="/opt/agentsec/decoy.txt"`, `fsuid=995`,
`ouid=0`) confirming AppArmor — not file permissions — produced the
block. I reset the decoy file's permissions back to `600` afterward.

**Scripts/files provided by the AI and included in this submission:**
- `policy/apparmor.profile` — the AppArmor MAC profile for
  `legacy_log_parser` (I reviewed and verified every rule against my
  own test runs before relying on it; the `markers/` line was changed
  from `r,` to `rw,` based on a denial I observed in my own kernel log).
- `src/make_payload.py` — parameterized ret2win payload generator
  (offset and `win()` address passed as arguments, rather than
  hardcoded, so it stays correct across rebuilds).
- `tests/run_tests.sh` — automated test suite for
  `legacy_log_parser_fixed` covering the five required Task 3 cases
  (valid short input, exactly max input, one byte over, missing file,
  original exploit payload).
- `tests/capture_task4_evidence.sh` — script that reproduces the full
  Task 4 confinement demonstration in one consistent run (load
  profile, confirm active, run exploit, DAC-loosening control test,
  capture kernel denial log, restore permissions) for report
  screenshots.
- `.gitignore` — excludes compiled binaries and generated `.bin`
  payloads from the repo.

I ran every one of these myself on my own VM before including it in
the submission; none were included without being executed and checked
against real output first.

**One error, limitation, or rejected suggestion:**
The first version of the AppArmor profile only granted `r` (read) on
the `markers/` directory, reasoning that the program only needed to
write a file *inside* it. This was wrong: `win()` also calls
`mkdir("markers", 0755)` on every run, which needs `c` (create)
permission on the directory itself, not just `rw` on files within it.
I only caught this because the kernel log showed a `DENIED
operation="mkdir"` entry that the AI's first draft hadn't predicted —
the write-only grant initially "worked" by coincidence, because
`markers/` already existed on disk from earlier manual testing. I
fixed the profile myself (`markers/ rw,`) based on that log evidence,
reloaded it, and re-verified no `mkdir` denial occurred on the next
run.
