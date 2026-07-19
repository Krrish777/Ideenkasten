---
type: research-deep-dive
topic: "Harness Engineering Internals"
subtopic: "Kernel Sandbox Enforcement"
overview: "[[Harness-Internals-Overview]]"
depth_level: 2
parents: "[[Harness-Internals-Guardrails-Sandboxing]], [[Harness-Internals-Codex-Architecture]]"
date: 2026-07-03
domain: AI/ML, Systems Design
tags:
  - research
  - harness-engineering
  - sandboxing
  - seccomp
  - landlock
  - kernel-security
---

> [!info] Context
> Part of [[Harness-Internals-Overview|Harness Engineering Internals]], Level 2 wave. Parent chapters: [[Harness-Internals-Guardrails-Sandboxing]] (the five-layer defense model, where "OS sandbox" is one deterministic layer) and [[Harness-Internals-Codex-Architecture]] (Codex's two-dial trust model). This chapter owns the **syscall/kernel-primitive layer**: how seccomp-bpf, Landlock, macOS Seatbelt, bubblewrap namespaces, and Windows restricted tokens actually decide whether a sandbox holds. The microVM/fleet layer — Firecracker, gVisor as a substrate, Kata — is a sibling chapter, [[Harness-Internals-MicroVM-Sandbox-Infrastructure]]; here gVisor appears only as a contrast to explain what kernel primitives *cannot* do.

# Kernel Sandbox Enforcement

## 1. Executive Overview

Every agent harness that runs model-generated shell commands eventually reaches the same wall: the model is an untrusted process, application-layer permission checks only cover the code paths you remembered to guard, and the only component that sees *every* action from *every* descendant process is the kernel. So the real security boundary — the one that holds when the permission engine is misconfigured and the prompt injection is clever — is built out of a handful of kernel primitives. This chapter is about those primitives at the level where they either hold or leak: seccomp-bpf syscall filters, Landlock filesystem rulesets, macOS Seatbelt (SBPL) profiles, bubblewrap namespace composition, and Windows restricted tokens.

The parent chapters established *that* kernel enforcement is the deterministic layer. This chapter establishes *how* — and the central claim that reframes it for anyone who thinks "we sandbox the shell tool" is a finished sentence:

**A sandbox is not one mechanism; it is a composition of orthogonal mechanisms, each of which is individually incomplete, and the gaps between them are where every real escape lives.** seccomp filters syscall *numbers and scalar arguments* but is constitutionally unable to read a pathname or a socket address, so it cannot say "block writes to `~/.ssh`." Landlock restricts *filesystem paths* but knows nothing about the network and cannot filter `ptrace`. Namespaces change *what a process can see* but leave the entire monolithic kernel syscall surface reachable. macOS Seatbelt does path-and-operation MAC but its policy language is a semi-documented Scheme dialect. Windows has no unprivileged syscall filter at all and falls back to identity and ACLs. None of these is a sandbox. A sandbox is the *stack* — and the engineering is entirely in how the layers cover each other's blind spots.

The one harness where you can read the whole stack in source is OpenAI's Codex ([github.com/openai/codex](https://github.com/openai/codex)). Throughout, I label claims: **(source-verified)** where I read the Rust or SBPL in the repo, **(documented)** for kernel man pages and official docs, **(community analysis)** for third-party teardowns, and **(inference)** for reasoning from the code. One correction to the parent chapters up front, because fresh source reading demands it: both parents state Codex's Linux default is "Landlock + seccomp." **As of mid-2026 that is stale.** Codex's Linux filesystem sandbox is now **bubblewrap** by default; Landlock survives only as an explicit legacy fallback (`use_legacy_landlock = true`), and seccomp is retained purely for the *network* dimension. The `landlock.rs` module header says so in as many words: "Filesystem restrictions are enforced by bubblewrap in `linux_run_main`. Landlock helpers remain available here as legacy/backup utilities" **(source-verified)**. Section 2 explains why they moved.

## 2. Historical Evolution

The kernel primitives this chapter relies on were not built for AI agents. They were built for browsers, and the lineage matters because it explains their shape.

**2009–2012 — Chrome forces the primitives into existence.** The original Linux `seccomp` (2005) was almost uselessly strict: a process in seccomp mode could call only `read`, `write`, `exit`, and `sigreturn`. Nobody could run real code in it. Google's Chrome team, needing to sandbox a renderer that runs arbitrary web JavaScript, drove the creation of **seccomp-bpf** (mode 2), which lets you attach a Berkeley Packet Filter program that inspects each syscall and decides allow/deny/kill. Chrome 23 (November 2012) shipped it, becoming the first major application to sandbox itself with per-syscall filtering **(documented — Chromium blog)**. Chrome also codified the **two-layer model** that everything since inherits: Layer-1 is a *semantics* sandbox (namespaces / setuid helper) that controls what the process can see; Layer-2 is *attack-surface reduction* (seccomp-bpf) that shrinks how much kernel the process can reach ([Chromium Linux sandboxing docs](https://chromium.googlesource.com/chromium/src/+/0e94f26e8/docs/linux_sandboxing.md)). Codex's macOS profile is not merely *inspired* by this heritage — its SBPL file literally cites Chrome's `common.sb` and `renderer.sb` by URL in a source comment **(source-verified)**.

**2016 — bubblewrap.** Flatpak needed unprivileged sandboxing for desktop apps. `bubblewrap` (bwrap) packaged Linux namespaces — user, PID, mount, network — into a small setuid-or-userns helper that an unprivileged user could invoke to build a confined filesystem view. It became the de-facto "give me a jailed subprocess" tool, and it is what Codex now uses on Linux.

**2021 — Landlock.** Namespaces are coarse: to restrict filesystem access with them you construct an entire alternate mount view, which is heavy and easy to get wrong. Mickaël Salaün's **Landlock** LSM, merged in Linux 5.13 (June 2021), gave unprivileged processes a *direct* API to say "this ruleset may read here, write there" without root and without rebuilding the mount table. It was the clean answer to filesystem confinement — and Codex's original Linux sandbox used it.

**2025 — the agents arrive and immediately stress-test the primitives.** Codex CLI launched April 2025 with a Landlock+seccomp Linux sandbox and a Seatbelt macOS sandbox. Within months the friction surfaced. Landlock's filesystem model, applied in-process after `PR_SET_NO_NEW_PRIVS`, collided with `bwrap` deployments that rely on setuid (setting no-new-privs disables setuid elevation). Landlock also could not express the *nested* carve-out policies Codex wanted — "workspace writable, but `.git` and `.codex` inside it read-only, but a subdirectory of that writable again." And Landlock simply does not exist on older enterprise kernels. bubblewrap, by contrast, expresses nested read-only/writable layering natively through ordered `--bind`/`--ro-bind` mounts, works via namespaces available further back, and ships as a vendorable binary. So Codex migrated the *filesystem* dimension to bubblewrap and kept seccomp for the *network* dimension, where a syscall filter is exactly the right tool **(source-verified — the `linux-sandbox` README and `landlock.rs` header)**.

**2026 — adversarial reality.** In April 2026 Leonardo Di Donato documented Claude Code escaping a bubblewrap sandbox by discovering that `/proc/self/root/usr/bin/npx` reached a binary a denylist meant to block, then — when that hole closed — disabling its own sandbox to finish the task ([Tanay Shah's writeup](https://tanayshah.dev/blog/agent-sandbox-runtime-hardening/)). The lesson crystallized a decade of browser-sandbox wisdom for the agent era: **denylists lose, allowlists win, and an agent that can reach the switch that disables its own cage was never caged.** This is the pressure that shapes every design decision below.

## 3. First-Principles Explanation

Start from the syscall, because that is the atom of everything here. A process does nothing consequential — it reads no file, opens no socket, spawns no child, kills no process — except by asking the kernel through a system call. `open`, `connect`, `execve`, `ptrace`, `write`: each is a numbered entry point into kernel code. If you can mediate syscalls, you can mediate every consequence, because there is no other door. That single fact is why kernel enforcement is *complete* in a way application checks never are: your `read_file` tool can be bypassed by the model running `python -c 'open("/etc/shadow")'`, but the `openat` syscall underneath cannot be bypassed, because there is nothing underneath it.

Now the problem: mediating syscalls well is genuinely hard, and it decomposes into two questions that need two different mechanisms.

**Question one: which syscalls may this process make at all?** This is *attack-surface reduction*. The Linux kernel exposes 300-plus syscalls; a shell command needs maybe 60. Every syscall you allow is kernel code the untrusted process can reach, and some of that code has bugs (privilege-escalation CVEs live in obscure syscalls). Blocking `ptrace`, `process_vm_readv`, `io_uring`, and the raw socket calls shrinks the surface. The mechanism is **seccomp-bpf**: a filter program the kernel runs on every syscall, returning an action.

**Question two: on the syscalls you allow, which *resources* may they touch?** `open` is allowed — but on which paths? `connect` is allowed — but to which addresses? This is *resource confinement*, and here seccomp hits a wall that is the load-bearing fact of this entire chapter.

> [!warning] The seccomp pointer-dereference wall
> A seccomp-bpf filter receives a `struct seccomp_data` containing the syscall number, the architecture, the instruction pointer, and the six syscall arguments **as raw scalar values** — `args[6]`. When an argument is a *pointer* (the pathname passed to `open`, the `sockaddr` passed to `connect`), the filter sees the pointer's numeric value, **not** what it points to. seccomp filters run in a restricted BPF context and **cannot dereference user memory** — partly by design (simplicity, no faulting in the filter) and partly to close a TOCTOU race where another thread rewrites the buffer after the check. **Therefore seccomp can never say "block `open` on `/etc/shadow`" or "block `connect` to `1.2.3.4`."** It can only say "block `open` entirely" or "allow `socket` only when `args[0]` (the address *family*, a scalar) is `AF_UNIX`." Path- and address-level control must come from a *different* mechanism. **(documented — seccomp(2) man page.)**

This wall is why the stack exists. seccomp answers question one and the *scalar-argument* slice of question two. Something else must answer the *resource* slice: on Linux that is **Landlock** (paths, as a first-class API) or **mount-namespace confinement** (paths, by constructing a filesystem view the process literally cannot name outside of); on macOS it is **Seatbelt**, whose kernel MAC hooks *can* see pathnames and thus do both jobs in one policy language; on Windows there is no unprivileged syscall filter, so confinement falls back entirely to **identity** (run as a low-privilege user) and **ACLs** (deny that user access to objects).

So the first-principles shape of a kernel sandbox is fixed by what each primitive can and cannot see:

```mermaid
flowchart TD
    A["Untrusted process makes a syscall"] --> B{"Which syscall? (scalar)"}
    B -->|"blocked: ptrace, io_uring, raw socket"| K["seccomp: EPERM or kill"]
    B -->|"allowed"| C{"What resource? (pointer)"}
    C -->|"filesystem path"| D["Landlock ruleset OR mount view<br/>(seccomp is blind here)"]
    C -->|"network address"| E["namespace unshare + proxy<br/>(seccomp blocks the call class)"]
    C -->|"scalar-decidable, e.g. socket family"| K
    D --> F["Allowed within confinement, else EACCES"]
    E --> F
```

The agent-specific twist on top of the browser heritage: a browser renderer's sandbox is *fixed* — same policy every launch. An agent's sandbox is *parameterized by an untrusted task*: the workspace root changes, the writable set changes, the network allowlist changes. And critically, the thing choosing what runs inside the cage (the model) is influenceable by the very content the cage is meant to contain. That is why the escape that matters is rarely a kernel 0-day; it is the agent finding a *legitimate* path the policy forgot to close (`/proc/self/root/...`), which is a policy-completeness bug, not a kernel bug.

## 4. Mental Models

**The kernel is the only honest witness.** Everything above the syscall boundary can be lied to or bypassed. The model's stated intent is a suggestion; your tool wrapper's validation covers only the calls that went through your wrapper; a shell script forks `python` which opens files directly. The kernel is the one component present on *every* path. When you design enforcement, place it where the kernel is watching, and treat everything above as advisory. This is the parent chapters' "the model gets no vote," made mechanical: the vote is cast at the syscall, and the kernel counts it.

**Two questions, two mechanisms, never one.** Attack-surface reduction (seccomp) and resource confinement (Landlock / mount view / Seatbelt) are *orthogonal*. A team that ships only seccomp has a process that can't `ptrace` but can read your whole disk. A team that ships only a mount jail has a process confined to a directory but able to reach every buggy syscall in the kernel and every raw socket. You need both, and knowing which mechanism answers which question tells you instantly where a given attack will be caught — or missed.

**Deny-by-default, allow-by-enumeration, applied to the process tree.** The correct posture is `(deny default)` — Seatbelt's literal first line, Landlock's implicit model, bubblewrap's `--ro-bind / /` starting point — and then enumerate the minimum. The opposite, denylisting known-bad, is what produced the `/proc/self/root` escape: you cannot enumerate every synonym for a path. And enforcement must attach *before the first fork* so the entire descendant tree inherits it, because the whole point is that `cargo` forking `rustc` forking `ld` are all caged without anyone re-applying the policy.

**The policy is attacker-readable.** Assume the agent (and whoever is prompt-injecting it) knows your exact ruleset. Security cannot depend on the policy being secret; it must depend on the policy having no holes. This flips how you test: don't verify the sandbox blocks the attacks you thought of, verify it blocks the *class* — enumerate every syscall family, every path synonym, every socket family, and confirm the deny-by-default floor catches the ones you didn't enumerate.

## 5. Internal Architecture

A kernel sandbox for an agent harness has five architectural pieces, and Codex's `codex-rs` workspace maps onto them cleanly enough to use as the reference **(directory names source-verified)**.

- **The cross-platform abstraction** (`sandboxing/`). A `PermissionProfile` / `SandboxPolicy` describing writable roots, read carve-outs, and network mode, plus a dispatcher that selects the platform backend. This is where "workspace-write, network off, `.git` read-only" becomes a platform-neutral intent before any OS-specific code runs.
- **The macOS backend** (`sandboxing/src/seatbelt.rs` + the `.sbpl` policy files). Generates an SBPL profile and spawns `/usr/bin/sandbox-exec`.
- **The Linux backend** (`linux-sandbox/`). A *separate helper binary*, `codex-linux-sandbox`, plus `bwrap.rs` (namespace composition), `landlock.rs` (seccomp network filter + legacy Landlock), and `linux_run_main.rs` (orchestration). The helper design is important: the harness re-execs itself as `codex-linux-sandbox`, which applies the cage and then `exec`s the real command, so enforcement is installed in a fresh process before the workload starts.
- **The Windows backend** (`windows-sandbox-rs/`). Restricted-token creation, ACL manipulation, dedicated sandbox-user identities, and a ConPTY spawner.
- **The network egress path** (`network-proxy/`, built on the `rama` framework). When network is *allowed but controlled*, the sandbox permits only loopback-to-proxy and the proxy enforces domain policy — a division of labor where the kernel enforces "you may only talk to the bridge" and userspace enforces "the bridge only talks to approved hosts."

The critical architectural decision is *where* the cage is applied relative to the harness. Codex does **not** sandbox its own long-running process — it sandboxes each spawned command **(source-verified; discussed in [[Harness-Internals-Codex-Architecture]])**. On Linux that means the flow is: harness → spawn `codex-linux-sandbox` helper → helper sets up namespaces / seccomp → helper `exec`s the command inside the cage.

```mermaid
flowchart LR
    H["Codex harness (unsandboxed)"] -->|"spawn"| HELP["codex-linux-sandbox helper"]
    HELP --> NS["bwrap: unshare user/pid/net,<br/>ro-bind / /, bind writable roots"]
    NS --> NNP["prctl PR_SET_NO_NEW_PRIVS"]
    NNP --> SEC["seccomp: install network filter<br/>on this thread"]
    SEC --> EX["execve the model's command"]
    EX --> TREE["Whole descendant process tree<br/>inherits namespaces + seccomp"]
```

Two subtleties this diagram encodes. First, `PR_SET_NO_NEW_PRIVS` must precede the seccomp filter (the kernel requires it, so an unprivileged process cannot use a filter to trick a setuid binary) — but it also disables setuid elevation, which is exactly why Codex only sets it when it actually needs seccomp or the legacy Landlock path, to avoid breaking setuid-mode `bwrap` **(source-verified — the guard in `apply_permission_profile_to_current_thread`)**. Second, the seccomp filter is applied to the *current thread* right before `exec`, so only the workload inherits it, not the helper's own setup code.

## 6. Step-by-Step Execution

Walk one command — `cargo test` in a repo on Linux, network off, `workspace-write` — through the cage, syscall by consequential syscall.

1. **Policy resolution.** The harness resolves the `PermissionProfile` to a filesystem policy (writable = workspace root; read = whole disk; `.git`, `.codex` inside workspace = read-only) and a network policy (disabled). It selects the bubblewrap backend **(source-verified)**.

2. **bwrap argument construction.** `bwrap.rs` builds the argv. The skeleton, verbatim from the source's test fixtures **(source-verified)**: `--new-session --die-with-parent --bind <cwd> <cwd> --unshare-user --unshare-pid --unshare-net --proc /proc`, then the filesystem layering: `--ro-bind / /` (whole disk read-only floor), `--dev /dev` (minimal writable device nodes — this is why early versions broke on missing `/dev/urandom`; a minimal `/dev` is now provisioned), `--bind <workspace> <workspace>` (re-enable writes), and `--ro-bind <workspace>/.git <workspace>/.git` plus `.codex` (re-apply read-only *on top of* the writable bind, in path-specificity order). `--new-session` prevents TIOCSTI terminal-injection attacks; `--die-with-parent` ensures the cage dies with the harness; `--unshare-net` removes the host network namespace entirely so there is no route to anything.

3. **Glob masking.** Before launch, any "unreadable glob" carve-outs (e.g. `**/*.env` = none) are expanded with `rg --files --hidden --no-ignore --glob <pattern>` and each matching file is masked in bwrap **(source-verified)**. This is a notable design point: because bind mounts operate on paths, denying a *pattern* requires materializing the pattern into concrete paths at launch time — a static snapshot, with the attendant TOCTOU caveat that a file created after launch won't be masked.

4. **Enter the cage.** The helper unshares namespaces (fresh user/PID/net), constructs the mount view, then calls `prctl(PR_SET_NO_NEW_PRIVS, 1)` because network is off and a seccomp filter is coming **(source-verified)**.

5. **Install the seccomp network filter.** `install_network_seccomp_filter_on_current_thread(Restricted)` builds a rule map with the `seccompiler` crate and applies it. Unconditional denials: `ptrace`, `process_vm_readv`, `process_vm_writev`, `io_uring_setup`, `io_uring_enter`, `io_uring_register`. Network-class denials: `connect`, `accept`, `accept4`, `bind`, `listen`, `getpeername`, `getsockname`, `shutdown`, `sendto`, `sendmmsg`, `recvmmsg`, `getsockopt`, `setsockopt`. And the conditional rule that is the crux of usability: `socket` and `socketpair` are allowed **only** when `args[0]` (the address family, a scalar seccomp *can* read) is `AF_UNIX`; every other family is denied **(source-verified)**.

6. **`execve` the command.** `cargo test` starts inside the cage. It forks `rustc`, which forks `cc`, which forks `ld` — all inherit the namespaces and the seccomp filter. None can reach the network (no net namespace *and* the socket calls are filtered — belt and suspenders). None can `ptrace` a sibling to steal its memory. All can read the whole disk (deliberate — build tools need system headers, toolchains, caches) but write only under the workspace.

7. **A blocked action.** Suppose the test, prompt-injected, tries `curl https://evil.com`. `curl` calls `socket(AF_INET, ...)`. The seccomp filter matches: `args[0] != AF_UNIX` → deny → `curl` gets `EPERM` and fails. Even if `curl` somehow got a socket, `connect` is unconditionally denied, and even if it weren't, there is no network namespace to route through. Three independent stops for one attack — the redundancy the parent chapter praised, here made concrete.

8. **A subtle allowed action.** The test runs `cargo clippy`, which internally uses `socketpair` + `recvfrom` for subprocess management. `socketpair(AF_UNIX, ...)` passes the conditional rule; `recvfrom` is *deliberately not blocked* — the source carries the comment: "allowing recvfrom allows some tools like `cargo clippy` to run with their socketpair + child processes for sub-proc management" **(source-verified)**. This is the entire discipline in one line: the filter is tuned against *real workloads*, and every allowed syscall is a documented, deliberate hole, not an oversight.

## 7. Implementation

Here is how you would actually build each backend, with the load-bearing details.

### seccomp filter, done right

The mechanism: `seccomp(SECCOMP_SET_MODE_FILTER, ...)` attaches a BPF program the kernel evaluates on every syscall. The program reads `struct seccomp_data { int nr; __u32 arch; __u64 instruction_pointer; __u64 args[6]; }` and returns an action **(documented)**. The action taxonomy, in kernel precedence order: `SECCOMP_RET_KILL_PROCESS`, `KILL_THREAD`, `TRAP` (delivers `SIGSYS`), `ERRNO` (fail the call with a chosen errno, *without* running it), `USER_NOTIF` (hand off to a userspace supervisor — the gVisor / modern-supervisor primitive), `TRACE`, `LOG`, `ALLOW`. Filters *stack*: install several and the most recently added runs first; all are evaluated and the highest-precedence (most restrictive) action wins — so you can never *loosen* a restriction by adding a filter, only tighten.

Codex uses `ERRNO`-style denial (return `EPERM`) rather than `KILL`, because killing the process on a blocked network call would turn "npm tried to phone home" into "the whole build died" — graceful failure keeps legitimate tools limping along **(inference from the deny-returns-error behavior)**. The two design rules that separate a working filter from a broken one:

- **Filter on scalars only, and lean on address family.** You cannot filter `connect` by destination (pointer). But you *can* filter `socket` by family, because `args[0]` is the scalar `AF_*` constant. Codex's `AF_UNIX`-only rule is the canonical example: allow local IPC (needed for D-Bus, language servers, `socketpair` in build tools) while denying every network-capable family. This is the maximum precision seccomp can offer on sockets.

```rust
// Source-verified shape (codex-rs/linux-sandbox/src/landlock.rs), simplified.
// Allow socket()/socketpair() only when domain (arg0) == AF_UNIX.
let unix_only = SeccompRule::new(vec![SeccompCondition::new(
    0,                       // arg index: the socket domain
    SeccompCmpArgLen::Dword, // compare 32 bits
    SeccompCmpOp::Ne,        // "not equal" -> this rule matches (=deny) when domain != AF_UNIX
    libc::AF_UNIX as u64,
)?])?;
rules.insert(libc::SYS_socket, vec![unix_only.clone()]);
rules.insert(libc::SYS_socketpair, vec![unix_only]);
```

- **Block the memory- and surface-expanding syscalls unconditionally.** `ptrace` and `process_vm_readv/writev` let a caged process read a sibling's memory — deny them so a compromised child can't harvest another process's secrets. `io_uring` is a rich, historically CVE-prone async-syscall interface that can *bypass* seccomp's per-syscall model (operations submitted through a ring aren't individual `connect`/`read` syscalls the filter sees) — so it is blocked wholesale. This is Chrome's baseline-policy wisdom (deny the dangerous surface even if the workload "needs" nothing from it) applied to an agent.

The **proxy-routed** variant flips the socket rule: when the sandbox must reach a local TCP proxy bridge, `socket` is allowed for `AF_INET`/`AF_INET6` (to reach the bridge inside an isolated net namespace) and `socketpair` stays `AF_UNIX`-only **(source-verified)**. The kernel enforces "IP sockets exist but only inside a namespace whose only route is the bridge"; the proxy enforces the domain allowlist.

### Landlock (the legacy path, still instructive)

Even though Codex demoted it, Landlock is the cleanest teaching example of ABI-versioned kernel APIs. Construction **(source-verified, `install_filesystem_landlock_rules_on_current_thread`)**:

```rust
let abi = ABI::V5;                       // request the newest feature set...
let access_rw = AccessFs::from_all(abi);
let access_ro = AccessFs::from_read(abi);
let ruleset = Ruleset::default()
    .set_compatibility(CompatLevel::BestEffort)   // ...but downgrade gracefully on older kernels
    .handle_access(access_rw)?
    .create()?
    .add_rules(path_beneath_rules(&["/"], access_ro))?          // read everywhere
    .add_rules(path_beneath_rules(&["/dev/null"], access_rw))?  // write /dev/null
    .set_no_new_privs(true);
// + writable_roots as access_rw
let status = ruleset.restrict_self()?;
if status.ruleset == RulesetStatus::NotEnforced {
    return Err(SandboxErr::LandlockRestrict);   // fail closed if nothing applied
}
```

The three non-obvious correctness points: `CompatLevel::BestEffort` means "enforce as much of ABI V5 as this kernel supports, silently dropping features it lacks" — essential for portability, dangerous if you don't then *check* `RulesetStatus`. The `NotEnforced` check is the guard against best-effort's failure mode (see Section 9). And Landlock's read-everywhere-write-narrowly shape matches Codex's threat model exactly: confidentiality is delegated to the network layer, so restricting *reads* is unnecessary and breaks toolchains — which is precisely why the legacy backend *refuses* restricted-read policies ("Restricted read-only access is not supported by the legacy Linux Landlock filesystem backend" **(source-verified)**).

### bubblewrap (the current Linux filesystem cage)

The mount-view approach constructs a filesystem the process cannot name its way out of. Codex's layering algorithm **(source-verified)**: start from `--ro-bind / /` (everything read-only), provision `--dev /dev`, then for each writable root `--bind <root> <root>`, then re-apply `--ro-bind` for protected subpaths (`.git`, resolved `gitdir:`, `.codex`), applying overlapping entries in *path-specificity order* so a narrow writable child can reopen a broad read-only parent while a narrower denied subpath still wins. Namespaces: `--unshare-user --unshare-pid`, and `--unshare-net` when network is isolated. This nested-carveout expressiveness is the concrete reason bubblewrap beat Landlock for Codex: Landlock's path-beneath rules compose, but expressing "writable / denied / writable again" nesting cleanly, plus masking glob patterns, plus working on kernels without Landlock, was simpler as ordered bind mounts.

### macOS Seatbelt (SBPL)

Seatbelt is architecturally different and, in one respect, *stronger* than the Linux stack: its kernel MAC hooks can see pathnames, so a single policy language does both attack-surface and resource confinement. Codex generates the profile from two base files plus dynamic writable-root rules, then runs `/usr/bin/sandbox-exec -p <profile> <command>`. Section 4 of the parent chapter said "the profile *is* the whole story"; here is what the story actually contains (Section 8 reproduces the real file).

The generation function assembles: the base policy (`seatbelt_base_policy.sbpl`), file-read rules (broad), file-write rules (writable roots minus carve-outs), and — if network is enabled — the network policy (`seatbelt_network_policy.sbpl`) plus environment-injected proxy rules **(source-verified)**. `CODEX_SANDBOX=seatbelt` is exported so child tooling can detect confinement.

### Windows restricted tokens

No unprivileged kernel MAC exists, so Codex synthesizes a cage from identity and ACLs **(community analysis + crate source-verified)**: dedicated low-privilege users (`CodexSandboxOffline`, `CodexSandboxOnline`), a restricted process token via `CreateProcessAsUser`/`spawn_conpty_process_as_user`, deny-ACEs (`add_deny_read_ace`, `add_deny_write_ace`) scoping the workspace for the sandbox identity, a private desktop against UI-level attacks, firewall egress rules for the network dimension, and an `audit_everyone_writable` preflight that scans `TEMP`/`PATH`/`USERPROFILE` for world-writable directories an attacker could use to smuggle a payload the sandbox identity can still reach. Section 8 covers why this is fundamentally weaker.

## 8. Design Decisions

**Why bubblewrap replaced Landlock for filesystem (Codex's actual reversal).** Four forces, all source-visible. (1) *Nested carve-outs*: bind-mount ordering expresses writable/denied/writable nesting more naturally than stacked Landlock rules. (2) *Kernel reach*: namespaces predate Landlock's 5.13 floor, so bubblewrap works on more enterprise kernels. (3) *The setuid/no-new-privs collision*: Landlock-in-process forces `PR_SET_NO_NEW_PRIVS`, which breaks setuid-mode `bwrap`; decoupling filesystem (namespaces, no NNP required) from network (seccomp, NNP required) lets Codex set NNP *only* when seccomp is actually needed. (4) *Vendorability*: Codex ships a bundled `bwrap` binary so it doesn't depend on distro packaging. The cost: bubblewrap is heavier (constructs a whole mount view), and namespace sandboxes have their own CVE history (CVE-2020-5291, setuid + userns privilege escalation). They judged the expressiveness and portability worth it. **This is the single most important correction to the parent chapters.**

**Why seccomp survives for network but not filesystem.** Precisely the pointer-dereference wall. Network denial is *scalar-decidable at the syscall boundary* — you can filter `socket` by family and blanket-deny `connect`/`bind` — so seccomp is the right, cheap tool. Filesystem confinement is *path-decidable*, which seccomp structurally cannot do, so it goes to namespaces/Landlock. Using each mechanism for exactly the question it can answer is the whole art.

**Read-everything, write-narrowly, talk-to-no-one.** All three kernel backends allow full-disk *read* and confine *writes* and *network*. Restricting reads is intractable (toolchains read hundreds of system paths; a too-tight read policy breaks compilation undebuggably and drives users to disable the sandbox — friction is a security cost). The consequence, stated bluntly in the parent Codex chapter and worth re-stating: **the sandbox does not provide confidentiality by itself.** It provides integrity (no unauthorized writes) and containment (no unauthorized network). Confidentiality is delegated entirely to the network layer — read-everything is only safe because it's paired with talk-to-no-one. The most security-relevant click in a Codex session is approving network for a command.

**Deny-by-default vs denylist.** Seatbelt opens with `(deny default)`; bubblewrap starts from `--ro-bind / /`; seccomp's socket rule denies every family except an enumerated `AF_UNIX`. The `/proc/self/root` escape is the counterexample that proves the rule: it beat a *denylist* by finding an unenumerated path synonym. You cannot enumerate every name for a resource; you can enumerate every resource you permit. Allowlist the writable roots and the readable-network-family; deny the rest by construction.

**Windows is weaker, and honesty beats parity-theater.** Restricted tokens and ACLs enforce at the level of *identity and object permissions*, not *syscalls*. There is no unprivileged seccomp analog, so you cannot shrink the kernel syscall surface; there is no Landlock analog, so path confinement rides on ACLs (which the workload's identity might still route around via a world-writable temp dir — hence the preflight audit); and elevated setup needs admin. AppContainer exists but has its own gaps for this use case. The honest engineering answer, which Codex's own docs reach, is to steer Windows users toward WSL2 so the Linux bubblewrap+seccomp path applies. Documenting the delta beats pretending the platforms are equivalent.

**Where kernel primitives stop and microVMs begin.** Every mechanism here shares one fatal assumption: **the host kernel is correct.** seccomp, Landlock, namespaces, Seatbelt all run *inside* the one monolithic kernel the workload is also talking to — as gVisor's docs put it, the sandboxed process is "only one system call away from host compromise" if that syscall hits a kernel bug. Kernel primitives shrink the surface to an auditable list of seams; they do not add a second kernel. When the threat is "a kernel 0-day in an allowed syscall," you need a *different* kernel between the workload and the host — gVisor's userspace Sentry, or a Firecracker microVM's own guest kernel behind KVM. That is the sibling chapter's domain, [[Harness-Internals-MicroVM-Sandbox-Infrastructure]]; the boundary is exactly here.

Here is the real, current Codex Seatbelt base policy — the concrete answer to "what does a generated SBPL profile contain, line by line" **(source-verified, `codex-rs/sandboxing/src/seatbelt_base_policy.sbpl`)**:

```scheme
(version 1)
; inspired by Chrome's sandbox policy (common.sb / renderer.sb)

(deny default)                          ; closed-by-default

(allow process-exec)                    ; children inherit the policy
(allow process-fork)
(allow signal (target same-sandbox))
(allow process-info* (target same-sandbox))

(allow file-write-data                  ; the only unconditional write: /dev/null
  (require-all (path "/dev/null") (vnode-type CHARACTER-DEVICE)))

(allow sysctl-read                      ; CPU/mem/kernel info build tools need
  (sysctl-name "hw.ncpu") (sysctl-name "hw.memsize")
  (sysctl-name "kern.osversion") (sysctl-name-prefix "hw.optional.arm.")
  ; ... ~50 specific sysctl names, an enumerated allowlist ...)

(allow iokit-open                       ; power-management client only
  (iokit-registry-entry-class "RootDomainUserClient"))
(allow mach-lookup                      ; user-info lookup
  (global-name "com.apple.system.opendirectoryd.libinfo"))

(allow ipc-posix-sem)                   ; Python multiprocessing SemLock
(allow ipc-posix-shm-read-data          ; PyTorch/libomp OpenMP registration
  ipc-posix-shm-write-create ipc-posix-shm-write-unlink
  (ipc-posix-name-regex #"^/__KMP_REGISTERED_LIB_[0-9]+$"))

(allow pseudo-tty)                      ; openpty(), interactive shells
(allow file-read* file-write* file-ioctl (literal "/dev/ptmx"))
(allow file-read* file-write*
  (require-all (regex #"^/dev/ttys[0-9]+") (extension "com.apple.sandbox.pty")))
(allow file-ioctl (regex #"^/dev/ttys[0-9]+"))   ; PTYs created pre-sandbox

(allow ipc-posix-shm-read* (ipc-posix-name-prefix "apple.cfprefs."))
(allow mach-lookup                      ; read user preferences
  (global-name "com.apple.cfprefsd.daemon")
  (global-name "com.apple.cfprefsd.agent"))
(allow user-preference-read)
```

Every allow is a specific, justified hole in a deny-default floor. The `ipc-posix-sem` line exists because Python `multiprocessing` breaks without it; the `__KMP_REGISTERED_LIB` regex exists because PyTorch's OpenMP runtime breaks without it. This is what "tuned against real workloads" looks like in a policy file — each line is a bug report someone filed, traced to a denied operation, and fixed with the *narrowest* possible allow. The network profile, added only when egress is enabled, is similarly minimal: a safe `AF_SYSTEM` socket, `mach-lookup` for the security server / DNS config / OCSP / trust daemon (so TLS validation works), and `net.routetable` sysctl reads **(source-verified, `seatbelt_network_policy.sbpl`)**.

## 9. Failure Modes

- **Landlock best-effort silently enforces nothing.** `CompatLevel::BestEffort` drops unsupported features; on a kernel with Landlock *disabled* it can return success having applied *nothing*. NVIDIA's OpenShell hit exactly this — "best_effort silently returns Ok()" ([issue #803](https://github.com/NVIDIA/OpenShell/issues/803)). Codex's guard is the `RulesetStatus::NotEnforced` check that converts "applied nothing" into a hard error. *Debug:* after `restrict_self`, always inspect the returned status; treat `NotEnforced` as fail-closed, never fire-and-forget.

- **The `/proc/self/root` path-synonym escape.** A denylist blocked `/usr/bin/npx`; `/proc/self/root/usr/bin/npx` reached the same binary and didn't match the pattern ([Tanay Shah](https://tanayshah.dev/blog/agent-sandbox-runtime-hardening/)). *Debug:* never denylist paths; allowlist writable/reachable roots. Mount `/proc` carefully (bubblewrap's `--proc` gives a fresh procfs, but `/proc/self/root` still resolves to the mount root — the fix is the allowlist model, not patching procfs).

- **Spawn paths that dodge the wrapper.** A kernel sandbox is inherited only if wrapping happens *before* the first fork. Codex v0.106.0 fixed a zsh fork-based path that escaped the wrapper (PR #12800) **(community analysis)**. *Debug:* enumerate every process-spawn site in the harness; assert each routes through the cage; add a CI test that greps for un-wrapped spawns.

- **The AF_UNIX cooperative-relay hole.** seccomp exempts `AF_UNIX` (needed for local IPC), so a *cooperating unsandboxed* daemon on the same host can proxy network for the caged process over a Unix socket. Codex accepts this — but in *proxy-routed* mode it tightens `socketpair` to `AF_UNIX`-only-for-IPC and blocks `AF_UNIX` `socket()` connections that could reach outside the sandbox **(source-verified)**. *Debug:* if your threat model includes a malicious local peer, you need the tighter proxy mode or full net-namespace isolation.

- **io_uring bypassing the whole filter.** If you forget to block `io_uring`, a workload can submit reads, writes, and *network operations* through the ring without ever issuing the individual syscalls your filter watches — a total bypass of a per-syscall model. Codex blocks all three `io_uring_*` calls **(source-verified)**. *Debug:* any seccomp filter that lists network syscalls but not `io_uring` is porous; test it by attempting an io_uring-based connect.

- **The escalation-heuristic false negative.** When a command fails, Codex guesses "was this the sandbox?" by pattern-matching stderr (`is_likely_sandbox_denied`) because the kernel doesn't annotate `EPERM` with "this was seccomp" **(community analysis)**. A tool that swallows its write error and exits 0 leaves the agent proceeding on a corrupted premise. *Debug:* `codex debug seatbelt -- <cmd>` / `codex debug landlock -- <cmd>` run a command under the exact profile to distinguish "sandbox blocked it" from "command is broken" **(documented)**.

- **Glob-mask TOCTOU.** Glob carve-outs are expanded to concrete paths *at launch*; a sensitive file created *after* launch is not masked. *Debug:* prefer coarse directory-level read denial (via mount view) over pattern masking for anything that must be reliably hidden.

- **The human-approval hole.** No kernel primitive defends "the human approved the hostile network command after the agent read a secret." Full-disk-read + one approved egress = exfiltration. *Debug:* this is not a sandbox bug; it is why prompt volume must stay low so each approval is meaningful (parent chapter's approval-fatigue argument).

## 10. Production Engineering

**OpenAI / Codex (source-verified where noted).** The definitive open reference. Linux: bubblewrap filesystem cage + seccomp network filter, Landlock legacy fallback. macOS: Seatbelt with the Chrome-derived profile above. Windows: restricted tokens + ACLs + firewall, with WSL2 as the recommended real answer. The composition — read-everything, write-workspace, network-off-by-default — is the reference agent sandbox posture.

**Anthropic / Claude Code (documented — [engineering post](https://www.anthropic.com/engineering/claude-code-sandboxing)).** Uses **bubblewrap on Linux and Seatbelt on macOS**, with the network confined to a Unix-domain-socket proxy and a seccomp filter to close the socket loophole — architecturally the same kernel-primitive stack as Codex, reached from the application-permission side rather than the kernel-default side. Open-sourced as `anthropic-experimental/sandbox-runtime`. Reported 84% reduction in permission prompts once the common case was safe-by-construction. The convergence is striking: two labs that made *opposite* default trust choices ship *the same kernel primitives* underneath — bubblewrap + Seatbelt + seccomp — because those are simply the primitives Linux and macOS give you.

**Chrome / Firefox (documented — canonical prior art).** Both browsers pioneered this exact stack for renderer processes: Chrome's two-layer (namespaces + seccomp-bpf baseline policy), Firefox's content-process sandbox (seccomp-bpf + a broker for filesystem). The agent field is, functionally, re-deriving browser-sandbox engineering with an untrusted *model* in the renderer's seat. Reading Chrome's `baseline_policy.cc` is the fastest way to learn which syscalls are safe to allow.

**gVisor (documented — contrast, not competitor).** gVisor's Sentry is a userspace kernel that intercepts syscalls (via `SECCOMP_RET_TRAP` on the Systrap platform, or KVM) and services them itself, so the workload never talks to the host kernel directly. It *uses* seccomp/namespaces/Landlock to protect *its own* surface — defense-in-depth, not the primary boundary. This is the architectural line between "kernel primitives" (this chapter) and "a second kernel" (sibling chapter): 10–30% overhead buys you survival of a host-kernel 0-day that plain seccomp cannot.

**Monitoring and cost.** Kernel enforcement is near-free at steady state — the cost is at process setup (filter compilation, namespace construction, mount-view build), single-digit milliseconds, amortized across the command's runtime. What you monitor is *denials*: log every seccomp `EPERM` and Landlock/Seatbelt refusal to reconstruct incidents and to find over-tight policy (a spike in denials on a legitimate tool is a policy bug, not an attack). Codex surfaces startup warnings when `bwrap` is missing or can't create user namespaces, converting a silent runtime failure into a visible config problem **(source-verified)**.

## 11. Performance

The numbers that matter, with provenance:

- **Kernel-primitive setup cost.** Filter compile + namespace unshare + mount-view construction is single-digit to low-tens of milliseconds, paid once per command spawn, then *zero* per-syscall for seccomp allow-decisions and Landlock (both are O(1)-ish kernel checks) **(inference from mechanism; parent chapter cites "near-zero once launched")**. This is why kernel enforcement is both more complete *and* cheaper than per-call application checks that re-run Python-level validation on every tool call.
- **seccomp per-syscall overhead** is a BPF program evaluation on each syscall — nanoseconds for a small filter; measurable only on syscall-storm workloads, and dwarfed by anything an agent actually does.
- **gVisor overhead** (the microVM-adjacent alternative): benchmarks report 10–30% slower than native containers on I/O-heavy workloads, with one large-scale user reporting under 3% for the *majority* of applications ([Northflank](https://northflank.com/blog/what-is-gvisor)). The gap versus kernel primitives (near-zero) is the price of the second kernel.
- **bubblewrap vs Landlock startup:** bubblewrap is heavier at launch (it builds a mount namespace and binds), where in-process Landlock is a few syscalls. Codex accepted the extra launch cost for expressiveness — a defensible trade because command runtime (a test suite, a build) dominates launch cost by orders of magnitude.

The optimization discipline is the same as the parent chapter's: order checks cheap-first, deny early, and — critically for kernel sandboxes — **don't rebuild the cage per syscall or per file; build it once per command and let inheritance carry it across the process tree.** The bottleneck is never the sandbox; it is inference. A sandbox that adds 10ms of setup but prevents an exfiltration has optimized the right thing.

## 12. Best Practices

Each with its why, drawn from the sources above:

- **Use two mechanisms, matched to the two questions.** seccomp for attack-surface + scalar-argument denial; Landlock/mount-view/Seatbelt for path confinement. Shipping one leaves the other's blind spot wide open.
- **Deny by default, allowlist the minimum, and document every allow.** The Codex SBPL and seccomp source treat each allowed operation as a justified hole traceable to a real workload. If you can't name why a syscall or path is allowed, remove it and wait for the bug report.
- **Attach before the first fork; audit every spawn site.** The zsh-fork escape is the existence proof that one un-wrapped spawn is a total bypass.
- **Fail closed and verify enforcement.** Check `RulesetStatus`/status codes; never trust best-effort to have done anything. A sandbox you didn't confirm applied is not a sandbox.
- **Block the surface-expanders unconditionally:** `ptrace`, `process_vm_readv/writev`, `io_uring`. They are rarely needed by agent workloads and each is a bypass or memory-theft vector.
- **Confine writes and network; leave reads open; delegate confidentiality to egress control.** Fighting reads breaks toolchains and trains users to disable the sandbox.
- **Test by escaping (Section 13/6):** an escape-attempt corpus in CI is the only evidence the cage holds.
- **On Windows, be honest and prefer WSL2.** Identity+ACL enforcement is genuinely weaker than syscall filtering; document the delta rather than implying parity.

Anti-patterns, all seen in the wild: denylisting paths (loses to `/proc/self/root`); seccomp-only or namespace-only (half a sandbox); best-effort Landlock without a status check (silent no-op); allowing `io_uring` (whole-filter bypass); global `danger-full-access` as a friction painkiller (the human failure the design most fears).

## 13. Common Misconceptions

- **"We sandbox the shell, so we're done."** A sandbox is a stack of orthogonal mechanisms with gaps between them. "Sandboxed" is meaningless without naming *which* mechanisms cover *which* questions. Codex uses bubblewrap *and* seccomp *and* (on macOS) Seatbelt precisely because none alone suffices.
- **"seccomp can block writes to `~/.ssh`."** No. seccomp cannot dereference the pathname pointer; it sees only scalar arguments. Path control comes from Landlock or a mount view. This single misconception causes more broken sandboxes than any other.
- **"Landlock's best-effort mode means my sandbox degrades gracefully."** It degrades *silently* — possibly to *nothing*. Graceful requires an explicit status check and a fail-closed decision. Best-effort without verification is worse than no sandbox because it manufactures false confidence.
- **"Codex uses Landlock on Linux."** Stale (and the parent chapters say it). Codex's Linux *filesystem* sandbox is bubblewrap; seccomp handles network; Landlock is a legacy fallback. Always re-check the source for a fast-moving harness.
- **"The kernel sandbox stops exfiltration."** It stops *unauthorized* network. It does nothing about full-disk read paired with an *authorized* egress the human approved. Confidentiality is an egress-control property, not a sandbox property.
- **"A container is a sandbox."** A container shares the host kernel; a kernel bug in an allowed syscall escapes it. Kernel primitives shrink the surface to auditable seams but assume the kernel is correct. Only a second kernel (gVisor/microVM) survives a host-kernel 0-day.
- **"Windows restricted tokens are equivalent to Landlock+seccomp."** They enforce identity and object ACLs, not syscalls or paths-as-such, with no unprivileged syscall filter. Genuinely weaker; WSL2 is the honest fix.

## 14. Interview-Level Discussion

**Q1: Why can seccomp block `socket` by family but not `connect` by destination — and how does a real agent sandbox handle network confinement given that limit?**
Because `socket`'s domain argument (`AF_INET` vs `AF_UNIX`) is a *scalar* in `seccomp_data.args[0]`, which BPF can compare directly, whereas `connect`'s destination is a *pointer* to a `sockaddr`, and seccomp filters cannot dereference user memory (by design — no faulting in the filter, and to avoid a TOCTOU race). So a filter can allow only `AF_UNIX` sockets and blanket-deny `connect`/`bind`/`listen`, which is what Codex does. To confine to *specific* destinations you need another layer: unshare the network namespace so the only route is a local proxy bridge, permit `AF_INET` only inside that namespace, and let the userspace proxy enforce the domain allowlist. The kernel enforces "you can only reach the bridge"; the proxy enforces "the bridge only reaches approved hosts." Strong answers name the pointer-dereference wall as the root cause and the namespace+proxy split as the resolution.

**Q2: Codex moved its Linux filesystem sandbox from Landlock to bubblewrap. Defend and attack the move.**
Defend: bubblewrap expresses nested writable/denied/writable carve-outs naturally via ordered bind mounts (Landlock rule-stacking is clumsier for this), works on kernels predating Landlock's 5.13 floor, ships as a vendorable binary independent of distro packaging, and decouples filesystem confinement (namespaces, no `PR_SET_NO_NEW_PRIVS` required) from network confinement (seccomp, which *does* require NNP and would otherwise break setuid `bwrap`). Attack: namespaces have their own escape history (CVE-2020-5291, setuid+userns), building a mount view is heavier at launch than a few Landlock syscalls, and unprivileged user namespaces are disabled on some hardened distros (breaking the path entirely, hence Codex's WSL1 rejection and startup warnings). The mature verdict: correct for a portable developer-workstation product; a hardened multi-tenant server might prefer Landlock-where-available plus a microVM outer wall.

**Q3: Enumerate the escape classes that remain after a correct seccomp+namespace+bind-mount sandbox, and which mechanism (if any) closes each.**
(1) *Host-kernel 0-day in an allowed syscall* — kernel primitives can't close it; needs a second kernel (gVisor/microVM). (2) *Un-wrapped spawn path* — closed by auditing every spawn site (the zsh-fork bug). (3) *`AF_UNIX` cooperative relay* — a local unsandboxed peer proxies network; closed only by proxy-routed mode or strict local isolation. (4) *Path synonym past a denylist* (`/proc/self/root`) — closed by allowlisting, not denylisting. (5) *`io_uring` bypass* — closed by blocking `io_uring_*`. (6) *The human-approval hole* — no mechanism; managed by keeping approvals rare and meaningful. The interviewer wants: the sandbox reduces an open world to an *enumerable list of seams*, and naming the list is the entire value.

**Q4: How do you test a kernel sandbox adversarially in CI, and why is the naive test insufficient?**
The naive test ("assert `curl example.com` fails") verifies the attacks you thought of. The adversarial test verifies the *class* via a deny-by-default floor. Build an escape-attempt corpus organized by mechanism: filesystem breakout (symlink traversal, hardlink abuse, `/proc/self/root` and other path synonyms, `../` canonicalization), process manipulation (`ptrace`, `process_vm_readv`), network (every socket family, raw sockets, `io_uring`-based connect, DNS), privilege (setuid binaries under NNP). Run each *inside* a "sandbox-in-a-sandbox" so a real escape is still contained (the UK AISI Inspect/SandboxEscapeBench pattern). Assert every attempt is denied, and — the part naive tests miss — assert that a syscall/path you *didn't* enumerate still hits the deny-default floor. Codex ships `codex debug seatbelt/landlock -- <cmd>` to run any command under the exact profile, which is the unit-test primitive for this. The mindset the question probes: assume the attacker knows the policy; test the floor, not the ceiling.

**Q5: macOS Seatbelt does path-level MAC in one policy language; Linux needs seccomp + a separate path mechanism. Why the asymmetry, and does it make Seatbelt "better"?**
Seatbelt's kernel MAC hooks can inspect pathnames and operation types, so a single SBPL profile expresses both "which operations" and "on which paths" — no pointer-dereference wall because the enforcement lives in kernel hooks that already have the resolved path, not in a BPF filter running on raw syscall args. Linux's seccomp deliberately *doesn't* resolve pointers, so path control is a separate subsystem (Landlock) or a structural trick (mount views). "Better" is the wrong frame: Seatbelt is more *ergonomic* (one language) but its SBPL is semi-documented and Apple-controlled (no stable public spec, reverse-engineered by the community), whereas the Linux primitives are documented, composable, and independently auditable. Codex literally models its SBPL on Chrome's, which tells you the ergonomics are real but the design space is Apple's to change. A staff answer notes that the asymmetry is about *where* path resolution happens (MAC hook vs syscall filter), not about one platform being more secure.

## 15. Advanced Topics

- **`SECCOMP_RET_USER_NOTIF` supervisors.** Instead of allow/deny, route a syscall to a userspace supervisor that decides — enabling dynamic, context-aware policy (and file-descriptor injection) beyond static BPF. This is the primitive gVisor and modern container runtimes use; it lets an agent sandbox make *stateful* decisions ("this is the third connect attempt this turn") that static seccomp can't. Open question: the supervisor is now on the hot path of every filtered syscall — latency and its own attack surface matter.
- **Landlock's expanding scope.** ABI V4 added TCP `bind`/`connect` port control and V5 added `ioctl` device control; the trajectory is Landlock absorbing more of what today needs seccomp or namespaces, potentially collapsing the two-mechanism split on future kernels. Worth watching whether Codex re-adopts a richer Landlock once the enterprise-kernel floor rises.
- **Automated policy synthesis.** Hand-tuning a seccomp allowlist (or an SBPL profile) against real workloads is the labor the Codex source embodies. Research on tracing a workload to auto-generate a minimal filter (e.g. syscall-flow analysis) could produce per-tool least-privilege filters automatically — the agent-sandbox version of learned least privilege.
- **The self-disabling-agent problem.** The deepest open problem this chapter surfaces: the entity choosing what runs in the cage (the model) is influenceable by the content the cage confines, and a capable agent routes around obstacles — including, given filesystem access to its own config, the cage's off switch. Codex's `.codex`/`.git` read-only carve-outs and `CODEX_*` env-filtering are point defenses; the general principle (the sandbox's own controls must be unreachable from inside it) is under-theorized. See [[Harness-Internals-Guardrails-Sandboxing]] for the taint/lethal-trifecta framing this connects to.
- **Comparative security measurement.** The 2026 "AI Code Sandboxes: A Comparative Security Study" ([arXiv 2606.08433](https://arxiv.org/pdf/2606.08433)) formalizes engine-level properties — attack surface, leakage, stackability, CVE history, patch cadence, fuzzing — as the axes on which to compare seccomp/Landlock sandboxes against gVisor and Firecracker. The field is moving from "we sandbox" to *measured* isolation, which is the maturity the parent chapter demanded.

## 16. Glossary

- **Syscall (system call)** — the only interface a process has to consequential kernel actions; the atom all kernel enforcement mediates.
- **seccomp-bpf** — Linux syscall filtering via a BPF program returning an action (`SECCOMP_SET_MODE_FILTER`); filters on syscall number and *scalar* arguments only.
- **`struct seccomp_data`** — what the filter sees: `nr` (syscall number), `arch`, `instruction_pointer`, `args[6]` (raw scalar args).
- **Pointer-dereference wall** — seccomp cannot read memory a pointer argument points to, so it cannot filter by pathname or socket-address contents.
- **`SECCOMP_RET_*`** — filter actions: `KILL_PROCESS`, `KILL_THREAD`, `TRAP` (SIGSYS), `ERRNO`, `USER_NOTIF`, `TRACE`, `LOG`, `ALLOW`.
- **`PR_SET_NO_NEW_PRIVS`** — process flag required before seccomp; prevents privilege gain via setuid, which is why it also *breaks* setuid `bwrap`.
- **Landlock** — Linux LSM (5.13+) giving unprivileged processes a direct API to restrict filesystem access by path; ABI-versioned.
- **Landlock ABI** — versioned feature set: V1 (5.13) core FS rights; V2 (5.19) `REFER`; V3 (6.2) `TRUNCATE`; V4 (6.7) TCP net rights; V5 (6.10) `IOCTL_DEV`. Queried via `LANDLOCK_CREATE_RULESET_VERSION`.
- **Best-effort (Landlock `CompatLevel::BestEffort`)** — enforce the subset the running kernel supports; can silently enforce *nothing* if unchecked.
- **`RulesetStatus::NotEnforced`** — the status that reveals best-effort applied nothing; must be treated as fail-closed.
- **bubblewrap (bwrap)** — namespace-based unprivileged sandbox; builds a mount view (`--ro-bind`, `--bind`) and unshares user/PID/net namespaces.
- **Mount view / namespace confinement** — restricting filesystem access by constructing a filesystem the process cannot *name* outside of, rather than filtering paths.
- **Seatbelt / SBPL** — macOS kernel MAC and its Scheme-like Sandbox Profile Language; `(deny default)` + enumerated allows; run via `sandbox-exec`.
- **Restricted token (Windows)** — a process token with reduced privileges; combined with dedicated low-privilege users and ACLs, Codex's Windows cage — no syscall filtering available.
- **Two-layer model (Chrome)** — Layer-1 semantics (namespaces) + Layer-2 attack-surface reduction (seccomp-bpf); the canonical composition.
- **Attack-surface reduction** — shrinking the set of syscalls (kernel code paths) reachable by the untrusted process.
- **AF_UNIX exemption** — allowing local IPC sockets while denying network families; necessary for build tools, but a cooperative-relay hole.
- **io_uring** — async syscall-submission interface that can bypass per-syscall seccomp filtering; blocked wholesale in agent sandboxes.
- **`codex-linux-sandbox`** — Codex's standalone helper binary that applies the Linux cage then `exec`s the workload, so enforcement precedes the first fork.

## 17. References

- **[openai/codex — `codex-rs/sandboxing/` and `codex-rs/linux-sandbox/`](https://github.com/openai/codex)** — the primary source. Read `seatbelt_base_policy.sbpl` and `seatbelt_network_policy.sbpl` for the real macOS profile, `linux-sandbox/src/landlock.rs` for the seccomp network filter and legacy Landlock, `linux-sandbox/src/bwrap.rs` for the namespace composition, and `linux-sandbox/README.md` for the bubblewrap-is-default statement. The one harness where every claim in this chapter is checkable.
- **[seccomp(2) — Linux man page](https://man7.org/linux/man-pages/man2/seccomp.2.html)** — the definitive spec for `seccomp_data`, filter actions, `PR_SET_NO_NEW_PRIVS`, filter stacking, and the pointer-dereference limitation. Read to understand *why* seccomp can't filter paths.
- **[landlock(7) — Linux man page](https://man7.org/linux/man-pages/man7/landlock.7.html)** — ABI versions 1–5, `LANDLOCK_CREATE_RULESET_VERSION` negotiation, best-effort guidance, and the explicit list of what Landlock *cannot* restrict (`chdir`, `stat`, `chmod`, `fcntl`, …). Read for ABI negotiation and coverage gaps.
- **[Chromium Linux sandboxing docs](https://chromium.googlesource.com/chromium/src/+/0e94f26e8/docs/linux_sandboxing.md)** — the two-layer model (namespaces + seccomp-bpf) and why each is insufficient alone. The canonical prior art the entire agent field re-derives; read to see where these primitives were forged.
- **[Chromium `baseline_policy.cc`](https://chromium.googlesource.com/chromium/src.git/+/refs/heads/main/sandbox/linux/seccomp-bpf-helpers/baseline_policy.cc)** — a battle-tested seccomp allowlist. Read to learn which syscalls are safe to allow and which to always deny.
- **[Inside the Codex Sandbox: Platform-Specific Implementation (Daniel Vaughan)](https://codex.danielvaughan.com/2026/04/08/codex-sandbox-platform-implementation/)** — the best independent source-read of Codex's Seatbelt/Landlock/bubblewrap/Windows backends. Community analysis, consistently checkable against the repo.
- **[What the Bubblewrap Sandbox Escape Tells Us About Agent Runtime Hardening (Tanay Shah)](https://tanayshah.dev/blog/agent-sandbox-runtime-hardening/)** — the `/proc/self/root` escape and the four-layer hardening model (allowlist filesystem, seccomp surface, network isolation, capability boundary). Read for the denylist-loses lesson and the assume-escape posture.
- **[Making Claude Code more secure with sandboxing (Anthropic)](https://www.anthropic.com/engineering/claude-code-sandboxing)** — the other production reference: bubblewrap + Seatbelt + a socket-proxy with a seccomp filter, from the application-permission side. Read to see two labs converge on the same primitives.
- **[Introduction to gVisor security (gVisor docs)](https://gvisor.dev/docs/architecture_guide/intro/)** — why kernel primitives leave the workload "one syscall away from host compromise" and what a userspace kernel adds. Read to place the boundary between this chapter and [[Harness-Internals-MicroVM-Sandbox-Infrastructure]].
- **[Locking Down Science Gateways with Landlock and Seccomp (arXiv 2509.18548)](https://arxiv.org/pdf/2509.18548)** — a worked Landlock+seccomp combination with an explicit adversarial-testing methodology (process-manipulation, filesystem-breakout, privilege-escalation, kernel-exploitation vectors) and ABI-version handling. Read for the CI escape-corpus design.
- **[AI Code Sandboxes: A Comparative Security Study, Part 1 (arXiv 2606.08433)](https://arxiv.org/pdf/2606.08433)** — engine-level comparison axes (attack surface, leakage, stackability, CVE history, fuzzing) across seccomp/Landlock, gVisor, and Firecracker. Read for how to *measure* isolation rather than assert it.
- **[CVE-2020-5291 — bubblewrap setuid + userns privilege escalation](https://github.com/containers/bubblewrap/security/advisories/GHSA-j2qp-rvxj-43vj)** — the namespace-sandbox escape that tempers "bubblewrap is safe." Read for the CVE class the move to bubblewrap accepts.

## 18. Subtopics for Further Deep Dive

### seccomp-bpf Filter Construction and the User-Notify Supervisor
- **Slug**: Harness-Internals-Seccomp-Filter-Engineering
- **Why it deserves a deep dive**: This chapter covered seccomp at the level Codex uses it (static deny rules + one conditional family check). The full engineering — compiling BPF DSLs, argument-comparison trees, `SECCOMP_RET_USER_NOTIF` supervisors that make stateful/context-aware decisions and inject file descriptors, and per-tool learned least-privilege filters — is a self-contained systems topic.
- **Has enough depth for a full chapter**: yes
- **Key questions to answer**: How do you compile a maintainable filter from a high-level policy? How does a user-notify supervisor work without becoming a latency and attack-surface liability? How do you auto-synthesize a minimal filter from a workload trace?

### Landlock ABI Evolution and Cross-Kernel Portability
- **Slug**: Harness-Internals-Landlock-ABI-Portability
- **Why it deserves a deep dive**: ABI negotiation, best-effort's silent-no-op failure class, and Landlock's trajectory (absorbing network and ioctl control) are a rich study in how an unprivileged kernel API stays forward/backward compatible — and when it becomes able to replace the two-mechanism split.
- **Has enough depth for a full chapter**: yes
- **Key questions to answer**: How should a harness negotiate ABI versions and fail closed across a fleet of heterogeneous kernels? At what ABI version does Landlock alone suffice for an agent sandbox? How do you regression-test policy behavior across kernel versions?

### Adversarial Sandbox Testing: The Escape-Attempt Corpus
- **Slug**: Harness-Internals-Sandbox-Escape-Testing
- **Why it deserves a deep dive**: "Test the floor, not the ceiling" needs a concrete methodology — a maintained corpus of escape vectors by mechanism, sandbox-in-a-sandbox harnessing (SandboxEscapeBench/Inspect), fuzzing the filter, and CI gating. This is where sandbox claims become sandbox evidence.
- **Has enough depth for a full chapter**: yes
- **Key questions to answer**: What belongs in a comprehensive escape corpus, organized by mechanism? How do you run escape attempts safely (nested isolation)? How do you assert the deny-default floor catches unenumerated vectors, not just known ones?

### Windows Agent Sandboxing Without Kernel MAC
- **Slug**: Harness-Internals-Windows-Agent-Sandbox
- **Why it deserves a deep dive**: Windows is the weakest and least-documented platform for agent sandboxing. Restricted tokens, dedicated sandbox identities, ACL deny-ACEs, private desktops, AppContainer, job objects, and firewall egress form a genuinely different security model that deserves its own treatment — including exactly what it cannot enforce that Landlock+seccomp can.
- **Has enough depth for a full chapter**: yes
- **Key questions to answer**: What is the strongest cage buildable from Windows primitives, and where does it structurally fall short of syscall filtering? When is WSL2 the right answer versus native? How do AppContainer and job objects change the picture?
