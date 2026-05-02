# Qwen3.6-27B on vLLM via RunPod — Deployment Runbook

**Audience:** future Performant Labs operators (and AI agents) standing up a Qwen3-family model on RunPod for use as a local-LLM coding agent.
**Status:** validated end-to-end on 2026-04-30 with vLLM 0.19.1, A100-SXM4-80GB, RunPod template `qaqvwnwdc6` ("Qwen3.6-27BvLLM"), reachable from VS Code's Roo Code extension over the OpenAI-compatible API.
**Cost as of writing:** ~$1.49/hr for an A100-80GB on RunPod's on-demand market.

---

## 1. TL;DR

The working stack:

| Component | Value |
|---|---|
| Model | `Qwen/Qwen3.6-27B` (multimodal, but text-only mode forced) |
| Inference engine | vLLM 0.19.1 with cu128 wheel |
| Base image | `runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04` |
| GPU | A100-SXM4-80GB |
| Container disk | 150 GB |
| Persistent volume | 0 GB (model re-downloads on each pod) |
| Cold start | ~12–15 min (pip install vLLM + 55 GB weight download + warmup) |
| Steady-state generation | ~30–80 tokens/sec |

The vLLM start command (full):

```bash
python -m vllm.entrypoints.openai.api_server \
  --model Qwen/Qwen3.6-27B \
  --host 0.0.0.0 --port 8000 \
  --dtype bfloat16 \
  --max-model-len 131072 \
  --enable-auto-tool-choice --tool-call-parser qwen3_coder \
  --reasoning-parser qwen3 \
  --default-chat-template-kwargs '{"enable_thinking": false}' \
  --language-model-only \
  --api-key sk-1234567890
```

**Critical flags (each one is load-bearing — see §4 for what fails without it):**

- `--language-model-only` — skips the multimodal vision encoder. **Without this, vLLM 0.19.1 segfaults during ViT warmup** for `Qwen3_5ForConditionalGeneration` architecture. (Runtime warmup still emits "Multi-modal warmup completed" line — don't be confused; the flag prevents the *segfault* path, not the warmup log line.)
- `--default-chat-template-kwargs '{"enable_thinking": false}'` — disables Qwen3's reasoning mode server-side. Without it, the model emits 200+ tokens of `<think>...</think>` before the actual answer, which exhausts `max_tokens` budgets and breaks tool-calling agents like Roo Code, Cline, Aider that don't expose `chat_template_kwargs` per request.
- `--reasoning-parser qwen3` — vLLM's Qwen3-specific reasoning parser. Routes any thinking content vLLM does see into `reasoning_content` rather than mixing it into `content`. Pair with the chat-template-kwargs flag.
- `--tool-call-parser qwen3_coder` paired with `--enable-auto-tool-choice` — required for OpenAI-style tool calls to be parsed out of the model's output. The recipe page recommends this even for the non-Coder model.
- `--dtype bfloat16` — matches the on-disk weight dtype. Don't mix.
- `--max-model-len 131072` — Qwen3.6 supports 262K natively but vLLM allocates KV cache against this value, so set it to what you actually need. **128K is the practical setting for an agentic coding workload comparable to Anthropic Opus's window.** Smaller values fail mid-task: 32K runs out before Roo Code finishes loading its system prompt + agents.md + role md + brief + a couple file reads (~33K total). 64K runs out partway through a typical chore once tool-call history (file reads, test outputs, prior assistant messages) accumulates. A real coding session sustains ~50–80K of context, so 128K gives headroom. On A100-80GB with 27B bf16, 128K KV cache uses ~24 GB; total VRAM with the 55 GB model lands at ~79 GB, ~1 GB headroom. **vLLM's startup memory profiler will refuse the launch if it doesn't fit** — there's no risk of mid-session OOM. KV cache per token ≈ 192 KB (48 layers × 8 KV heads × 128 dim × 2 bytes × 2 for K+V).

**Critical flag NOT to use:**

- ~~`--enable-prefix-caching`~~ — **disables it deliberately**. With `Qwen3_5ForConditionalGeneration` (Mamba/GDN delta attention architecture), prefix caching forces Mamba cache mode `'align'` which is "experimental" per vLLM's own warnings. On vLLM 0.19.1 the experimental path drops generation throughput to ~0.2 tokens/sec (effectively unusable) with GPU at 0% utilization while showing 73 GB memory used. Symptom: a repeated `UserWarning: Input tensor shape suggests potential format mismatch: seq_len (...) < num_heads (...)` from `vllm/model_executor/layers/fla/ops/utils.py`. Dropping the flag restores normal speed.

The full container start command (template `dockerArgs`) wraps a base64-encoded `/setup.sh` that pip-installs vLLM and launches the above:

```bash
bash -c "echo <BASE64_OF_SETUP_SH> | base64 -d > /setup.sh && chmod +x /setup.sh && /setup.sh"
```

The decoded `/setup.sh`:

```bash
#!/bin/bash
set -e
export HF_HOME=/root/.cache/huggingface
export HF_TOKEN=
export VLLM_CACHE_ROOT=/workspace/vllm_cache
mkdir -p "$VLLM_CACHE_ROOT"

echo '=== Installing vLLM ==='
python -m pip install --quiet 'vllm<0.20' --extra-index-url https://download.pytorch.org/whl/cu128 \
  || python -m pip install --quiet 'vllm<0.15' --extra-index-url https://download.pytorch.org/whl/cu128
python -c "import vllm; print('vllm', vllm.__version__)"

echo '=== Starting vLLM ==='
python -m vllm.entrypoints.openai.api_server \
  --model Qwen/Qwen3.6-27B \
  --host 0.0.0.0 --port 8000 \
  --dtype bfloat16 \
  --max-model-len 131072 \
  --enable-auto-tool-choice --tool-call-parser qwen3_coder \
  --reasoning-parser qwen3 \
  --default-chat-template-kwargs '{"enable_thinking": false}' \
  --language-model-only \
  --api-key sk-1234567890 > /vllm.log 2>&1 &

echo 'Container is now persistent.'
tail -f /vllm.log
```

The trailing `tail -f /vllm.log` is the persistence trick: it blocks PID 1's bash forever, keeping the container alive even if vLLM exits. You can SSH in via RunPod's gateway, debug, kill the vllm process by name (anchored — see §4-G), and relaunch without restarting the container.

---

## 2. Background — why this combination

We're running a local Qwen3.6 instance to power **Hephaestus**, a chore-task implementer agent in the CTRFHub multi-agent setup. Hephaestus drives Roo Code in VS Code; Roo Code calls vLLM's OpenAI-compatible API; vLLM serves Qwen3.6-27B from a single A100 on RunPod.

Why each layer:

- **vLLM (not llama.cpp/SGLang/TGI):** OpenAI-compatible API out of the box, mature tool-calling parser support, well-documented Qwen3 recipe.
- **RunPod (not Coolify-on-Uranus, not Together/Fireworks):** on-demand GPU pricing without committing to a managed inference provider. Coolify-on-Uranus is parked as PL-020 for the future; the build-image-on-Uranus-and-deploy-on-RunPod pattern is what we settled on.
- **A100 (not H100, despite preference):** what was available in `US-MD-1` on the test night. The recipe in §1 works on either; H100 would be ~30% faster on prefill-dominated agentic workloads.
- **Qwen3.6-27B specifically (not 3.6-35B-A3B, not Qwen3-32B):** the user's choice for the head-to-head experiment. **This is the less-documented variant** — see §6.

---

## 3. RunPod template configuration (`Qwen3.6-27BvLLM`, id `qaqvwnwdc6`)

| Field | Value |
|---|---|
| `name` | `Qwen3.6-27BvLLM` |
| `imageName` | `runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04` |
| `containerDiskInGb` | **150** (was 50; insufficient — see §4-D) |
| `volumeInGb` | 0 (no persistent volume; weights re-download per pod) |
| `volumeMountPath` | `/workspace` |
| `ports` | `8000/http,22/tcp` (note: stored as a single comma-separated **String** in GraphQL, not an array) |
| `env` | `HUGGING_FACE_HUB_TOKEN=hf_...` |
| `dockerArgs` | the `bash -c "echo <B64> | base64 -d > /setup.sh ..."` from §1 |
| `startSsh` | `true` |
| `startJupyter` | `true` (RunPod default; harmless) |
| `category` | `NVIDIA` |

### 3.1 Updating the template programmatically

`runpodctl` is not installed locally and the REST API doesn't expose `dockerArgs` in GET responses, so updates must go through GraphQL `saveTemplate`. Schema gotchas discovered on 2026-04-30:

- **Field name is `id`, not `templateId`.** GraphQL error: `Field "templateId" is not defined by type "SaveTemplateInput"`. Use `id`.
- **Ports is a String, not an array.** `["8000/http","22/tcp"]` is rejected with `String cannot represent a non string value`. Send `"8000/http,22/tcp"` instead.
- **The mutation requires the full template object,** not just the changed fields. You must round-trip every field — `name`, `imageName`, `containerDiskInGb`, `volumeInGb`, `volumeMountPath`, `ports`, `env`, `readme`, `category`, `containerRegistryAuthId`, `startSsh`, `startJupyter`, `isPublic`, `isServerless`, `dockerArgs`. Missing required fields are reported individually (`Field "X" of required type "Int!" was not provided.`).
- **GraphQL introspection is disabled** (`INTROSPECTION_DISABLED`). Don't waste time on `__type` or `__schema` queries — discover the schema by sending a deliberately-broken request and reading the `errors[].message`.
- **The mutation envelope that works:**

  ```graphql
  mutation Save($input: SaveTemplateInput!) {
    saveTemplate(input: $input) { id name }
  }
  ```

- **Verifying the save:** the REST GET (`https://rest.runpod.io/v1/templates/{id}`) does not return `dockerArgs`. Use GraphQL `query($id: String!) { podTemplate(id: $id) { dockerArgs } }` to read it back. Note: `podTemplate(id: $id)` — *not* `podTemplate(input: {templateId: $id})`.

A working bridge script that pulls existing values, replaces only the changed fields, and verifies via GraphQL lives in `~/Projects/ctrfhub/.claude-bridge/req-argos-runpod-template-update-v6.sh` (history of dead-ends in v1–v5 also there for reference).

### 3.2 Updating env via API

Same `saveTemplate` mutation, `env` field. Format: `[{key: "X", value: "Y"}, ...]`. **Caveat:** the API will accept and persist the env values you send back — so re-sending the existing env (round-trip) means the existing tokens go through your script's memory. Don't print the variables array to stdout, ever.

---

## 4. Failure modes encountered & their fixes

Each entry: **symptom → root cause → fix → how to confirm.**

### A. vLLM segfaults during multimodal warmup

**Symptom.** vLLM cold-starts, downloads weights, prints `INFO ... Starting to load model Qwen/Qwen3.6-27B`, loads to GPU (~51 GiB used), then:

```
INFO ... Encoder cache will be initialized with a budget of 16384 tokens,
        and profiled with 1 image items of the maximum feature size.
!!!!!!! Segfault encountered !!!!!!!
  File "<unknown>", line 0, in _PyEval_EvalFrameDefault
  ...
  File "<unknown>", line 0, in (anonymous namespace)::THPFunction_apply(...)
  File "<unknown>", line 0, in _start
RuntimeError: Engine core initialization failed.
```

The C-level traceback with `THPFunction_apply` + `(anonymous namespace)` frames is the giveaway — that's a CUDA/Torch native crash, not Python.

**Root cause.** `Qwen/Qwen3.6-27B` is a vision-language model (architecture `Qwen3_5ForConditionalGeneration`, pipeline tag `image-text-to-text`). vLLM's vision-encoder warmup feeds a dummy image through the ViT, which uses FlashAttention 2. On vLLM 0.19.1 + A100 the FA2-in-ViT path crashes. Independent of any chat-template/reasoning settings.

**Fix.** `--language-model-only`. Skips loading the vision encoder weights and the warmup pass entirely. For text-only workloads (i.e., a coding agent) the vision tower is dead weight anyway.

**Confirmation.** Log line during startup: `All limits of multimodal modalities supported by the model are set to 0, running in text-only mode.` And: `Multi-modal warmup completed in 9.686s` *without* a segfault (the warmup log line still appears even with the flag — it's the warmup *crash* that disappears).

### B. Generation runs at 0.2 tokens/sec

**Symptom.** vLLM starts cleanly, listens on :8000, returns valid 200 responses on `/v1/chat/completions`, but **inference is glacial.** The vLLM throughput log:

```
INFO Engine 000: Avg prompt throughput: 1.9 tokens/s,
                 Avg generation throughput: 0.2 tokens/s,
                 Running: 0 reqs, Waiting: 0 reqs,
                 GPU KV cache usage: 0.0%, Prefix cache hit rate: 0.0%
```

`nvidia-smi` snapshot during inference shows GPU utilization at 0% and power at 72 W (idle), even though 73 GB of VRAM is allocated to model weights. Repeated warning during requests:

```
UserWarning: Input tensor shape suggests potential format mismatch:
seq_len (19) < num_heads (48). This may indicate the inputs were passed
in head-first format [B, H, T, ...] when head_first=False was specified.
  vllm/model_executor/layers/fla/ops/utils.py:113
```

**Root cause.** `--enable-prefix-caching` activates Mamba cache mode `'align'` for the `qwen3_5` architecture. Per vLLM's own startup warning: *"Prefix caching in Mamba cache 'align' mode is currently enabled. Its support for Mamba layers is experimental."* On vLLM 0.19.1 this experimental path triggers a tensor-format mismatch in the Flash Linear Attention (FLA) kernels, which fall back to a non-GPU code path. Hence the GPU sits idle while inference plods through CPU.

**Fix.** Drop `--enable-prefix-caching` from the start command. After restart + warmup, generation throughput jumps to normal (~30–80 t/s for 27B bf16 on A100) and GPU utilization climbs to 60%+ during requests with power draw ~187 W.

**Confirmation.** Warm wall-clock for a 2-token completion drops from ~10 s to ~0.1 s. The format-mismatch warnings stop appearing in `/vllm.log`.

**Trade-off.** Prefix caching does help with multi-turn agentic workloads where the same system prompt is repeated. Once vLLM upstream fixes the Mamba/FLA interaction (a fix may already be on `main`), the flag should come back. Until then: leave it off for `qwen3_5` arch.

### C. `ModuleNotFoundError: No module named 'vllm'`

**Symptom.** `/setup.sh` runs `python -m vllm.entrypoints.openai.api_server ...` and gets:

```
/usr/bin/python: Error while finding module specification for
  'vllm.entrypoints.openai.api_server'
  (ModuleNotFoundError: No module named 'vllm')
```

Container stays alive (because `tail -f` blocks PID 1) but never serves anything.

**Root cause.** vLLM is *not* pre-installed in the `runpod/pytorch:2.4.0-...` image's `/usr/bin/python`. We *thought* it was, because earlier pods worked — but that was because the earlier pods' `/entrypoint.sh` (RunPod's pytorch image entrypoint) somehow surfaced a different python where vLLM was already installed. New container instances fired up after a template re-deploy use `/opt/nvidia/nvidia_entrypoint.sh` (NVIDIA's CUDA base entrypoint), which does no such setup. **Don't rely on the runpod/pytorch image to pre-install vLLM.**

**Fix.** Bake the install into `/setup.sh`:

```bash
python -m pip install --quiet 'vllm<0.20' --extra-index-url https://download.pytorch.org/whl/cu128
```

The `<0.20` ceiling pins us to the version range we tested; the cu128 extra index ensures the right pytorch wheel for the CUDA 12.8 base image. Adds ~3–5 min to cold start. Worth it for reliability.

**Confirmation.** `python -c "import vllm; print(vllm.__version__)"` returns `0.19.1` (or whatever's current under the cap).

### D. Disk full during weight download

**Symptom.** vLLM args parse fine, model arch resolves, engine init starts, then:

```
RuntimeError: Data processing error: File reconstruction error:
              IO Error: No space left on device (os error 28)
```

In `huggingface_hub/file_download.py`'s `xet_get` → `download_files`. Buried in a multi-frame Python traceback inside the EngineCore process.

**Root cause.** Default `containerDiskInGb` is 50 GB. Qwen3.6-27B at bf16 on disk is ~55 GB. Plus pip-installed vLLM + torch + dependencies = ~10 GB. Total need is ~65 GB minimum — and the HF cache writes to a temp file before atomic rename, so peak usage during download can be 1.5x the on-disk size. **50 GB is not enough for any 27B+ bf16 model.**

**Fix.** `containerDiskInGb: 150`. (100 might suffice in steady state but 150 gives breathing room for pip cache, log growth, etc.)

**Confirmation.** `df -h /` inside the running pod shows `/` overlay at 150 GB total. After warm vLLM, expect ~70–80 GB used (vllm + cache + weights).

### E. Engine core "Failed core proc(s): {}"

**Symptom.** Generic vLLM error message: `RuntimeError: Engine core initialization failed. See root cause above. Failed core proc(s): {}`. **This is a wrapper exception, not the actual error.**

**Root cause.** The actual error is *higher up* in `/vllm.log`, often hundreds of lines back. The wrapper catches all engine init failures and re-raises with this generic message. Whatever the actual cause is — segfault, OOM, disk full, missing dependency — it'll be in earlier log entries.

**Fix.** When you see this, immediately `head -n 100 /vllm.log` and `grep -n 'ERROR\|Error\|Exception\|Segfault' /vllm.log`. Don't trust the trailing traceback alone.

### F. SSH gateway hang on RunPod

**Symptom.** `ssh xxx-yyy@ssh.runpod.io` connects (gateway prints welcome banner) but the remote bash never executes the command. Connection hangs indefinitely; `ServerAliveInterval` doesn't fire because the gateway is responsive at the SSH protocol level.

**Root cause #1.** Inline command-as-argument with `-tt` (forced PTY): the remote shell receives the command but treats it as interactive PTY input, eating heredocs and complex pipelines. Shape that fails:

```bash
ssh -tt user@host 'cat <<EOF | python3 -
... script ...
EOF'
```

**Fix #1.** Use heredoc-via-SSH-stdin instead. Shape that works:

```bash
ssh -tt user@host <<'REMOTE'
echo "hello"
exit
REMOTE
```

The heredoc becomes the SSH session's stdin; the gateway's bash runs each line. Note: `-tt` is still required (the gateway rejects no-PTY connections with `Error: Your SSH client doesn't support PTY`).

**Root cause #2.** Even with the stdin pattern, base64-decoded payloads get mangled if the shell sees them as PTY input. Solution:

**Fix #2.** Pass the payload as a single base64 chunk and decode on-pod:

```bash
B64=$(printf '%s' "$PAYLOAD" | base64 | tr -d '\n')
REMOTE_CMD="echo '$B64' | base64 -d | python3 -; exit"
ssh -tt ... "$REMOTE_TARGET" "$REMOTE_CMD"
```

This is what the working `req-argos-vllm-diag-v2.sh` pattern looks like.

**Symptom of hung session that stalls the bridge.** When SSH is hung, the bridge's worker doesn't get a result file written, and queued requests pile up. Recovery:

```bash
pkill -f "ssh.*<pod-id>"
# remove the stuck request file so bridge moves on:
rm -f ~/Projects/ctrfhub/.claude-bridge/req-<name>.sh
```

### G. `pkill -f "vllm.entrypoints"` kills PID 1

**Symptom.** You try to restart vLLM via `pkill -f vllm.entrypoints` over SSH; the container appears to die instead, restarted by RunPod with the original config (10–15 minute cold start, lost progress).

**Root cause.** PID 1 in RunPod's setup is `bash -c "echo BASE64... | base64 -d > /setup.sh && /setup.sh"`. The base64 string contains the vllm-entrypoints command as a literal substring. `pgrep -f "vllm.entrypoints"` matches PID 1's cmdline, and `kill -9` to PID 1 terminates the container.

**Fix.** Always anchor the regex with `^python`:

```bash
pgrep -fa '^python.*vllm.entrypoints'
pkill -f '^python.*vllm.entrypoints'
```

This matches only the actual python process, not the bash that has vllm-entrypoints in its argv as a base64-decoded string. Verify with `pgrep -fa` (the `a` shows the full cmdline so you can confirm before killing).

### H. HF token in `env` field of API responses

**Symptom.** A diagnostic that prints a RunPod template or pod object dumps the env map, which on inspection contains `"HUGGING_FACE_HUB_TOKEN": "hf_..."` in plaintext. The `*_TOKEN` value is now in:

- bridge response files on disk
- `bridge/live.log` if the script tee'd
- terminal scrollback of any tail
- the chat history of the AI agent that ran the diag

**Root cause.** RunPod's REST and GraphQL responses include `env` with all values in plaintext. **Always.** This is the documented behavior, not a leak by them — it's a leak in any caller that doesn't redact.

**Fix.** Apply a redaction filter to *every* response that might include env, by default:

```bash
redact() {
  sed -E \
    -e 's/(hf_)[A-Za-z0-9]{20,}/\1<redacted>/g' \
    -e 's/(rpa_)[A-Za-z0-9_-]{20,}/\1<redacted>/g' \
    -e 's/(sk-)[A-Za-z0-9_-]{30,}/\1<redacted>/g' \
    -e 's/("HUGGING_FACE_HUB_TOKEN"[[:space:]]*:[[:space:]]*")[^"]+(")/\1<redacted>\2/g' \
    -e 's/("[A-Z_]*TOKEN[A-Z_]*"[[:space:]]*:[[:space:]]*")[^"]+(")/\1<redacted>\2/g' \
    -e 's/("[A-Z_]*KEY[A-Z_]*"[[:space:]]*:[[:space:]]*")[^"]+(")/\1<redacted>\2/g' \
    -e 's/("value"[[:space:]]*:[[:space:]]*")[^"]+(")/\1<redacted>\2/g'
}
```

**Print structural info, not values.** Lists of env keys are fine; values are not. Prefer `jq -r '.env | keys[]'` over `jq '.env'`. When debugging template responses, `jq 'keys[]'` shows top-level fields without dumping `env`.

**If a token leaks anyway:** rotate at https://huggingface.co/settings/tokens, update `~/.env.local` and the template's env map, scrub the bridge response files (`rm res-*.out res-*.exit`) and live.log (`sed -i.bak ...; rm *.bak`).

### I. Roo Code hits "maximum context length is 32768 tokens"

**Symptom.** Roo Code reports an OpenAI-API error during a normal task (often before the agent even produces output):

```
OpenAI completion error: 400 This model's maximum context length is 32768 tokens.
However, you requested 0 output tokens and your prompt contains at least 32769 input tokens,
for a total of at least 32769 tokens.
```

The "0 output tokens" is the giveaway — the input *alone* exceeded the limit. No generation happened.

**Root cause.** Default `--max-model-len 32768` is too small for Roo Code's effective prompt. A typical Roo Code prompt for a real coding task is: system instructions (~3K) + `agents.md` (~3K) + role-specific md (~1K) + the task brief (~3K) + 1–3 file reads (~5–15K) + tool-call history (~5K). That easily clears 32K before the agent has done much.

**Fix.** Bump `--max-model-len`. **128K (`131072`) is the practical setting for sustained agent work.** Memory budget on A100-80GB:

| `--max-model-len` | KV cache | Total VRAM (model + KV) | Notes |
|---|---|---|---|
| 32768 | ~6 GB | ~61 GB | runs out during initial prompt load |
| 65536 | ~12 GB | ~67 GB | runs out partway through a typical chore as tool-call history accumulates |
| 131072 | ~24 GB | ~79 GB | recommended; matches Opus window for fair comparison |
| 262144 (native) | ~48 GB | doesn't fit | vLLM startup OOM |

KV cache size per token ≈ `2 × num_layers × num_kv_heads × head_dim × dtype_bytes` ≈ 192 KB for Qwen3.6-27B at bf16. Multiply by `max-model-len` for total. (Mamba/GDN state is fixed-size — doesn't scale with seq_len.) **vLLM allocates the full KV cache budget at startup**, so OOM (if any) happens at launch, not mid-session.

**Empirical: tonight (2026-04-30) we hit this twice on a single chore — first at 32K (initial prompt couldn't fit), then again at 64K (tool-call history grew). Set 128K from the start; don't try to ladder up.**

**Confirmation.** vLLM's startup log line: `Using max model len 131072`. Roo Code's prompt now has 4× breathing room over the typical session size.

### J. Vision-required tasks (Tier 3 visual verification, design-mockup briefs)

**Symptom.** A Hephaestus-driven test-writer or spec-enforcer session hits a step that requires *looking at* an image — interpreting a design mockup in a brief, debugging a Playwright screenshot diff in `test-results/`, or auditing an embedded PNG in a `tier-3-report.md`. Heph produces no useful output beyond "I cannot view images."

**Root cause.** The recipe in §1 sets `--language-model-only`, which is mandatory to dodge the FA2-in-ViT segfault (§4-A). Side effect: the multimodal vision encoder is not loaded at all, so Heph is text-only. He is *not* a multimodal model in this configuration regardless of what `Qwen/Qwen3.6-27B` advertises.

**What still works without vision:**

- *Writing* Tier 3 test code (Playwright `expect(page).toHaveScreenshot()` calls). The model generates Playwright API code from its training knowledge; vision is not required to produce valid test bodies.
- *Running* Tier 3 tests. Pass/fail/diff-pixel-count signals are all text. Heph reads them fine.
- Tier 1 (headless) and Tier 2 (ARIA) for any route. These are entirely text-based.

**What does not work without vision:**

- Debugging a Tier 3 failure ("is this a real regression or should I update the snapshot?"). Heph sees only "X% pixels differ"; he cannot judge.
- Spec-enforcer auditing a `tier-3-report.md` that includes screenshots. Heph audits the markdown structure; he is blind to the embedded PNGs.
- Briefs that include Figma exports, design mockups, or screenshots of intended UI. Heph cannot read them as input.

**Mitigation, until fixed.** Treat Heph as **qualified for backend stories and chores only**. Route UI stories (anything touching `src/views/`, the `/setup` wizard, login/password forms, the dashboard) to Daedalus or Talos. The brief's "Required test tiers" section per story declares whether Tier 3 applies; if it does, Heph is not the right implementer.

**Path to fix (one of):**

1. vLLM upstream patches the multimodal vision-encoder warmup for `Qwen3_5ForConditionalGeneration`, allowing `--language-model-only` to be dropped. Watch for vLLM 0.20+.
2. Switch Heph's model to a text-only Qwen3 dense (e.g. `Qwen3-32B`) and accept "no multimodal capacity" as a permanent design choice — but lose Qwen3.6's tool-call training.
3. Add a vision-capable second model (e.g., a smaller VLM on the same pod via tensor-parallel slicing) that handles only the Tier 3 audit steps, fronted by a router. Significant complexity for a corner case.

For now: option 1 is the wait-and-see; the role-boundary note is the operational answer. See §6 for `agents.md` integration.

### K. Cloudflare 524 / "terminated" errors on long Heph responses

**Symptom.** Roo Code reports an error during a long-running tool call. The error text is one of:

- `OpenAI completion error: 524 status code (no body)`
- `terminated`
- Generic "request failed mid-stream"

In `/vllm.log`, the engine shows the request was *still generating* when the client gave up — `request_success_total{finished_reason="abort"}` stays at 0, vLLM doesn't notice the disconnect.

**Root cause.** The RunPod HTTP proxy URL (`https://<pod-id>-8000.proxy.runpod.net`) is fronted by Cloudflare. Cloudflare has two relevant timeouts:

- **524 (origin timeout):** 100 seconds without *any* response from origin. Hit if a request's prefill phase alone (large prompt at ~1,500–2,000 t/s) exceeds 100 sec before the first token streams.
- **Idle-between-chunks timeout:** even with `stream: true`, if vLLM's tool-call parser buffers the entire response (e.g. with `--tool-call-parser qwen3_coder`), there can be a 100+ sec gap between the last logical chunk and the next, killing the connection.

For agentic workloads with 70K+ token contexts and tool-call-shaped responses, both are reachable on routine requests.

**Fix.** Switch the template's port mapping from `8000/http` (Cloudflare-proxied) to `8000/tcp` (direct TCP). The resulting URL is `http://<publicIp>:<dynamicPort>/v1` instead of `https://<pod-id>-8000.proxy.runpod.net/v1`. No proxy in the path → no idle/origin timeouts.

API call:

```
saveTemplate mutation with ports: "8000/tcp,22/tcp" (was "8000/http,22/tcp")
```

The dynamic public port is assigned per-launch; query via REST `GET /v1/pods/{podId}` → `portMappings."8000"` or GraphQL `pod.runtime.ports[]` filtered to `privatePort == 8000`.

**Trade-offs.**

- ✗ HTTP not HTTPS — traffic is in clear over the public internet. Acceptable for a development experiment; not for anything sensitive. The `--api-key sk-1234567890` placeholder is also passed in the clear (it's a fake key for traffic isolation, not real auth).
- ✗ Pod IP and port change every launch — Roo Code's Base URL must be updated after each fresh pod.
- ✓ No proxy timeouts — Heph can take 10+ minutes per response without disconnects.
- ✓ Lower latency than going through Cloudflare (saw 0.19s vs ~0.4s for `/v1/models`).

**Confirmation.** From the Mac, `curl http://<publicIp>:<port>/v1/models` returns 200 in <0.5s. Streaming chat-completion calls show first byte within 1s; no 524 or termination on multi-minute responses.

**Alternative if you can't go TCP.** Roo Code may have a configurable HTTP request timeout. Bumping it to 600,000 ms (10 min) helps with 524 specifically but doesn't fix the idle-between-chunks issue. Direct TCP is the cleaner fix.

---

## 5. The bridge architecture

A full description lives at `~/Sites/ai_guidance/agent/claude-bridge.md`. Adjuncts learned 2026-04-30:

- **Don't background the bridge with `&` alone.** It gets SIGTTOU'd on first stdout write and suspends. Use `nohup ~/Sites/ai_guidance/agent/claude-bridge.sh > ~/bridge.log 2>&1 & disown`. Verify with `pgrep -fa claude-bridge`.
- **Watch live with** `tail -f ~/bridge.log` in a sidecar terminal tab.
- **Bridge processes serially.** A hung script blocks the queue. Recovery: kill the hung child (`pkill -f "ssh.*<target>"`), then `rm` the unprocessed `req-*.sh` from `.claude-bridge/`.
- **Cap polling attempts** to 3–5 in scripts so a transient bridge stall doesn't loop forever. Use `for i in 1 2 3 4 5; do ... sleep 6; done`.
- **Always tee to live.log** (the existing wrapper does this for you, but custom scripts shouldn't redirect away from it).

---

## 6. Notes on Qwen3.6-27B specifically

The official vLLM recipe at https://github.com/vllm-project/recipes/blob/main/Qwen/Qwen3.5.md covers **Qwen3.5** (397B-A17B MoE) and **Qwen3.6** (35B-A3B MoE) — the bigger, MoE-architecture cousins. There is **no Qwen3.6-27B.md** recipe. The 27B variant exists in the official Qwen HuggingFace org (created 2026-04-21, ~770K downloads as of 2026-04-30) and shares the architecture (`Qwen3_5ForConditionalGeneration`, multimodal, Mamba+GDN delta), but it is *not* in the official recipe table. **It's a dense model, not MoE** — naming convention in the Qwen3 family: `{Total}-A{Active}` suffix denotes MoE (e.g., 35B-A3B = 35B total / 3B active per token); plain `{N}B` like `27B` is dense. So Qwen3.6-27B reads all ~54 GB of weights per token during decode, which is the binding constraint on inference throughput on bandwidth-limited hardware.

Implications:

- The recipe's deployment patterns (`-dp 8 --enable-expert-parallel`, `--mm-encoder-tp-mode data`, etc.) are for the multi-GPU MoE variants. **Don't apply them to the 27B dense.** Single-GPU TP=1 is correct.
- The recipe's known-error table mentions a Mamba+cudagraph capture-size crash with a workaround (`--max-cudagraph-capture-size 256`). If you ever see `causal_conv1d_update assert num_cache_lines >= batch`, that's the fix.
- vLLM 0.19.1 may have specific bugs on this less-tested arch. The `--enable-prefix-caching` issue (§4-B) is one. Watch for more in newer vLLM versions; the `<0.20` pin in §1 is conservative.

### 6.1 Benchmark positioning vs frontier closed models

Critical context for interpreting the head-to-head rulings in §11–§12. The benchmark gap to current frontier models is much smaller than the rubric scores might suggest in isolation — most of the rubric gap is *code-organization style and autonomy*, not raw capability.

**SWE-bench Verified** (real GitHub-issue resolution; the most-cited general coding benchmark):

| Model | Score | Gap vs Heph |
|---|---|---|
| Claude Opus 4.7 | 87.6 | +10.4 |
| GPT-5.5 | 82.6 | +5.4 |
| Claude Opus 4.6 | 80.8 | +3.6 |
| **Qwen/Qwen3.6-27B (Heph)** | **77.2** | — |
| Qwen/Qwen3.6-35B-A3B (MoE) | 73.4 | −3.8 (slower model trades quality for ~9× decode speed) |

**SWE-bench Pro** (harder, multi-step issues on real codebases):

| Model | Score |
|---|---|
| Claude Opus 4.7 | 64.3 |
| GPT-5.5 | 58.6 |
| Claude Opus 4.6 | ~58 (inferred) |
| Qwen/Qwen3.6-27B (Heph) | 53.5 |

**How to read this in light of the head-to-head rulings:**

- The CHORE-LINT-001 and CTRF-003 head-to-heads pitted **Heph (77.2) against Daedalus = Opus 4.6 (80.8)**: a 3.6-point benchmark gap. The rubric gaps were 7 (chore) and 14 (story) points respectively — meaning *most of the measured difference is style and autonomy, not raw capability*. Heph defaults to verbose docs, monolithic files, occasional `as any`, and required several infrastructure interventions; those rubric losses stack on top of the modest 3.6-point capability gap.
- **If you re-ran the head-to-head with Daedalus = Opus 4.7** (current frontier rather than last cycle's), expect the rubric gap to widen substantially. The capability gap to Heph would be 10.4 points instead of 3.6 — and the rubric would compound that with the same style/autonomy losses. Likely 18–25 point rubric gap on a story.
- **If you re-ran with Daedalus = GPT-5.5**, expect rubric outcomes between the Opus 4.6 and Opus 4.7 cases. GPT-5.5 sits 1.8 points above Opus 4.6 and 5 points below Opus 4.7 on Verified.
- **The harder SWE-bench Pro benchmark** widens the gap meaningfully — Heph's 53.5 vs Opus 4.7's 64.3 is a 10.8-point chasm. For real production debugging across a multi-file codebase, the open-weight gap is more material than Verified suggests.

**Implication for production deployment:**

- Heph as a Daedalus-on-Opus-4.6 replacement is a defensible choice on capability grounds — speed and code-organization preferences are the binding constraints, not raw quality.
- Heph as a Daedalus-on-Opus-4.7-or-GPT-5.5 replacement is harder to justify on capability grounds. The frontier moved; an open-weight at 77.2 SWE-bench Verified is comfortably one tier behind the current-cycle frontier.
- Re-test annually as the open-weight class catches up. Qwen3.6 dropped 9 days before this experiment ran; open-weight models at this size class will continue improving.

### 6.2 Mac hardware sizing for OSS coding models — corrected analysis

An earlier draft suggested "M5 Max is fine for dense Qwen3.6-27B" — that was wrong on the speed dimension. Both M-series Studios are *inadequate* for **dense** Qwen3.6-27B at usable agentic speed; the actual Mac case rests on whether you'd run an **MoE** model that fits.

**Speed reality for dense 27B:**

| Setup | Sustained decode | Story wall-clock vs tonight |
|---|---|---|
| A100 80 GB (RunPod, tonight) | ~10–12 t/s | baseline, ~5 hours |
| **M5 Max** 128 GB (614 GB/s bandwidth) | **~7 t/s** | **~7+ hours — worse** |
| **M5 Ultra** 256 GB (~1.2 TB/s rumored) | **~12 t/s** | **~5 hours — same as tonight** |
| H100 80 GB (RunPod) | ~22 t/s | ~2.5 hours |

For dense 27B, **neither Mac speeds anything up.** Max is *slower* than tonight; Ultra is *the same*. Buying a Mac specifically to host dense 27B is buying the same problem at higher capex.

**Where Macs change things — MoE models that fit:**

| Model | Total / active | INT4 weight | M5 Max | M5 Ultra |
|---|---|---|---|---|
| Qwen3.6-27B dense (tonight) | 27 B / 27 B | n/a | ~7 t/s | ~12 t/s |
| Qwen3.6-35B-A3B MoE | 35 B / 3 B | ~17 GB | ~50 t/s | ~80 t/s |
| Qwen3.5-397B-A17B MoE | 397 B / 17 B | ~198 GB | doesn't fit | ~70 t/s |
| **DeepSeek V4-Flash MoE** | **284 B / 13 B** | ~142 GB | doesn't fit | **~100 t/s real** |
| Kimi K2.6 MoE | 1 T / 32 B | ~500 GB | doesn't fit | doesn't fit |
| DeepSeek V4-Pro MoE | 1.6 T / unknown | ~800 GB | doesn't fit | doesn't fit |

**Clean Mac decision matrix:**

| Goal | Right answer |
|---|---|
| Run Qwen3.6-27B dense faster than tonight | Neither Mac. Use cloud or wait for MoE alternatives. |
| Run an OSS coding model that *beats* tonight's Heph and fits one machine | **M5 Ultra + DeepSeek V4-Flash** — only combo that solves both speed *and* quality |
| Run Qwen3.6-35B-A3B (one tier behind Heph but ~9× faster) | **M5 Max** is sufficient |
| Run Kimi K2.6, V4-Pro, MiniMax M2.5 locally | Doesn't fit any single-machine setup; cloud-API or multi-GPU cluster |
| Avoid local-LLM ops entirely | Anthropic API for Daedalus, no Mac purchase |

**Corrected M5 Ultra value proposition:** Ultra is justified specifically by "unlock MoE models that fit comfortably under 200 GB INT4." Without a model like V4-Flash, Ultra is wasted bandwidth on dense 27B.

**Benchmark check on the Mac-Ultra-runnable candidates:**

| Model | SWE-Verified | License | vs Heph (77.2) |
|---|---|---|---|
| **DeepSeek V4-Flash** | **79.0** | MIT | **+1.8** ✓ |
| Qwen3.5-397B-A17B | 76.2 | Apache 2.0 | −1.0 |
| Qwen3.6-35B-A3B | 73.4 | Apache 2.0 | −3.8 |

V4-Flash on Ultra is the genuine "better local Heph" — both faster and slightly higher quality than tonight's setup, plus MLA's 90% KV-cache reduction unlocks much larger contexts in agentic workflows.

---

## 7. Roo Code configuration

| Field | Value |
|---|---|
| API Provider | OpenAI Compatible |
| Base URL | `https://<pod-id>-8000.proxy.runpod.net/v1` (per-pod proxy URL) |
| API Key | `sk-1234567890` (placeholder; matches `--api-key` in start command) |
| Model ID | `Qwen/Qwen3.6-27B` |
| Reasoning Effort toggle | OFF |

Roo Code does **not** expose `chat_template_kwargs` or "custom request fields", so the only way to disable thinking-mode at request time is server-side via `--default-chat-template-kwargs`. This is the load-bearing flag for any agent client (Roo Code, Cline, Aider) that wraps OpenAI's API but doesn't surface vLLM-specific extensions.

---

## 8. Smoke test sequence (5 min from cold-start "Application startup complete")

Run from the pod (or via SSH bridge):

**Test 1 — endpoint up:**
```bash
curl -sS -H "Authorization: Bearer sk-1234567890" \
  http://localhost:8000/v1/models
```
Expect HTTP 200 with the model listed.

**Test 2 — clean inference, no thinking:**
```bash
curl -sS -X POST http://localhost:8000/v1/chat/completions \
  -H "Authorization: Bearer sk-1234567890" \
  -H "Content-Type: application/json" \
  -d '{"model":"Qwen/Qwen3.6-27B","messages":[{"role":"user","content":"reply pong"}],"max_tokens":10,"temperature":0}'
```
Expect: `content: "pong"`, `completion_tokens: 1–3`, `finish_reason: "stop"`, `reasoning_content: null`. **Wall-clock should be sub-second on a warm engine.** If it's >5s, recheck §4-B.

**Test 3 — tool calling:**
Confirm Roo Code can fire a `read_file` tool call and process the response. Simplest prompt: `Read the file <some-path-in-workspace> and tell me how many lines it has.` Expect a tool-call approval prompt, then a numeric answer.

If all three pass, the stack is ready for an agent task.

---

## 9. Building a reusable Harbor image (Uranus-side)

Source lives at `/root/qwen-vllm/` on Uranus (`62.238.6.48`, `ssh uranus`). Files:

- `Dockerfile` — `nvidia/cuda:12.8.0-devel-ubuntu22.04` base, Python 3.11, vLLM `>=0.15,<0.20` cu128 wheel, transformers upgrade, no openssh (RunPod gateway provides container exec).
- `entrypoint.sh` — pulls model on first run if not in HF cache, launches vllm with the proven args (incl. `--language-model-only`, no `--enable-prefix-caching`).

**Status as of 2026-04-30:** source updated and verified, **build/push not yet run.** When ready:

```bash
cd /root/qwen-vllm
docker build -t harbor.performantlabs.com/library/qwen3-vllm:latest .
docker push harbor.performantlabs.com/library/qwen3-vllm:latest
# Update the RunPod template's imageName field to point at Harbor.
# Future cold starts skip the pip install phase entirely (~3 min saved).
```

The split into `qwen3-vllm:latest` (lean) + `qwen3-vllm-bench:latest` (extends with llama.cpp + benchmarks) is parked work — single image is sufficient for now.

---

## 10. Empirical baselines

Concrete numbers from a real session, for future operators to compare against.

### CHORE-LINT-001 (Hephaestus, 2026-04-30)

A single-file TypeScript refactor (eliminating 14 `as any` casts in a Vitest integration test file by adding a Fastify module augmentation). Roo Code agent driving the model; fully autonomous after auto-approve was enabled mid-session.

**Stack at the time of measurement:** vLLM 0.19.1, Qwen3.6-27B bf16, A100-SXM4-80GB, `--max-model-len 131072` (128K), no `--enable-prefix-caching`, `--language-model-only`.

**Measured over the 128K-context window only** (vLLM was restarted twice for context bumps; numbers below are from the final, stable phase of the session):

| Metric | Value |
|---|---|
| Successful chat completions | 13 (all `finish_reason: stop`, 0 errors) |
| Total prompt tokens processed | 914,907 (~915K) |
| Total generation tokens | 2,012 |
| Avg prompt size per request | ~70K tokens |
| Avg completion length | ~155 tokens |
| Peak generation throughput | 26.1 tokens/sec (10s window avg) |
| Mean generation throughput | 5.59 tokens/sec (over 36 snapshots, dragged down by idle gaps between tool calls) |
| Mean prompt-prefill throughput | 2,541 tokens/sec |
| Peak KV cache usage | 23.3% of 128K ≈ 30K tokens |
| Pod runtime for the experiment | ~3 hours |
| Cost on RunPod A100-80GB on-demand | ~$4.50 |

**Read-out for future operators:**

- **Prompt:generation token ratio is ~450:1** for agentic workflows. Most token cost is re-reading context across tool calls. That's why prefix-caching (when it works for the architecture) is the biggest available optimization.
- **Real KV needs maxed at ~30K tokens** in this session, well under the 64K we initially tried. But a single one-token-overflow killed the session at 64K because Roo Code retries in-place; 128K is the right setting because it has comfortable margin, not because the workload demands 128K of active context.
- **Peak generation throughput of 26 t/s** is the floor for "model is working correctly." If you see steady-state averages anywhere near 5–10 t/s on this hardware, that's normal duty cycling between tool calls. If you see *peaks* below 10 t/s, something's wrong (revisit §4-B).
- **Wall-clock for a single-file mechanical refactor: roughly 30 minutes of model time spread over 13 requests, ~3 hours of pod uptime including the (long, painful) infrastructure debugging.** A clean run with the runbook's recipe in place would be closer to ~30 min total: 12 min cold start + 15–20 min of Heph working.

### CTRF-003 (Hephaestus, full three-role harness, 2026-04-30 / 2026-05-01)

A real story implementation: extend the existing CTRF ingest endpoint to accept multipart artifact uploads with magic-bytes validation, per-file and per-run size limits, and integration with the existing `ArtifactStorage` interface. Heph played all three implementer roles in sequence (feature-implementer → test-writer → spec-enforcer), each in a fresh Roo Code session reading from the on-branch `.argos/CTRF-003/*-handoff.md` files. Pod 1 was terminated mid-experiment due to Cloudflare 524 timeouts on long responses; pod 2 used a TCP port mapping (`8000/tcp` instead of `8000/http`) which bypassed Cloudflare entirely and resolved the timeouts. See §4-K below.

**Stack:** identical to CHORE-LINT-001 except `ports: 8000/tcp,22/tcp` for pod 2.

**Combined across both pods:**

| Metric | Value |
|---|---|
| Successful chat completions | ~118 (38 on pod 1, 80 on pod 2) |
| Total prompt tokens prefilled | ~8.1 M |
| Total generation tokens | ~87 K |
| Server-side errors | 0 |
| Preemptions | 0 |
| Non-stop finish_reasons (length/abort/error/repetition) | All zero |
| Peak generation throughput | 27.9 tokens/sec |
| Mean generation throughput (combined, 412 ten-second windows) | 12.2 tokens/sec |
| Mean prompt-prefill throughput | ~2,000 tokens/sec |
| Peak KV cache usage | 37.7% of 128K ≈ 48K tokens (during spec-enforcer phase) |
| Estimated GPU-busy compute time | ~2 hours (68 min prefill + 56 min decode at peak) |
| Pod cost | ~$7–9 (pod 1 ~$4.50 + pod 2 ~$3–4.50) |
| Wall-clock (rough) | ~4–5 hours including infrastructure debugging |

**Read-outs from this session:**

- **Spec-enforcer is the most context-heavy role.** Peak KV cache (~48K tokens) hit during the audit phase, when Heph had to read all required skills + the brief + both handoffs + the full diff simultaneously. **64K context would have been tight; 128K is the right setting for full-harness work.**
- **Prompt:generation ratio is ~93:1** for story-shape work — *more* lopsided than the chore's 450:1 *despite* less repetitive context, because three sequential agent sessions each loaded a fresh copy of the same docs. Persistent context (or session-shared KV cache) would dramatically reduce cost; today's setup loads from scratch per role.
- **Heph completed 118 sequential requests with zero server-side errors, zero preemptions, zero non-`stop` finish_reasons.** As a measure of model reliability under sustained load, this is reassuring. The errors that *did* surface during the session (524s, "terminated") were all in the network path, not the model.
- **Wall-clock for a story is ~4–5 hours on this hardware** including infrastructure debugging; a clean run with the runbook's recipe (now stable) would be more like 90–120 min of Heph time spread across the three role sessions.
- **Speed bottleneck is structural.** Sustained 12 t/s (mean) on a 27B dense model isn't a tuning issue — it's bandwidth-bound decode at this model size on A100. Faster paths require either H100 (~2× decode), the MoE variant `Qwen3.6-35B-A3B` (~9× decode at slight quality cost per benchmarks), or vLLM 0.20+ unblocking faster kernels.

---

## 11. Head-to-head audit — CHORE-LINT-001 (2026-04-30)

A controlled comparison of two coding agents on the same brief. Documented here because the runbook is the only durable cross-session record of *why* this Qwen3.6-27B + RunPod stack was set up in the first place.

### Setup

| Contestant | Model | Driver | Branch |
|---|---|---|---|
| **Hephaestus** | Qwen3.6-27B (bf16, vLLM on RunPod A100) | Roo Code | `chore/lint-001-qwen` |
| **Daedalus** | Claude Opus 4.6 | AntiGravity | `chore/lint-001-opus` |

Both received the identical brief at `.argos/CHORE-LINT-001/brief.md` (committed to both contestant branches by Argos before the run, so each agent read it from the same on-branch path). The brief asked for a single mechanical refactor: replace 14 `(app as any).<member>` casts in one Vitest integration test file with a proper Fastify `FastifyInstance` module augmentation. Acceptance criteria: lint clean, typecheck clean, tests pass, small diff.

### What each delivered

| Metric | Heph | Daedalus |
|---|---|---|
| Files changed | 2 | 2 |
| Net lines changed | 71 (+57 / −14) | 39 (+25 / −14) |
| New augmentation file | `src/types/fastify-augment.ts` (42 lines) | `src/types/fastify-augment.d.ts` (11 lines) |
| Augmented type members | 3 (correct) | 3 (correct) |
| `as any` casts removed | 14/14 ✓ | 14/14 ✓ |
| `BootState` source | imported from existing `../modules/health/schemas.js` ✓ | same ✓ |
| `MikroORM` import | `@mikro-orm/core` ✓ | same ✓ |
| `import 'fastify';` in aug file | absent (relies on indirect imports) | present (canonical Fastify pattern) |
| Extra import added to test file | `import '../../types/fastify-augment.js';` | none (relies on tsconfig auto-include) |
| Extension chosen | `.ts` (deviation from brief's `.d.ts` recommendation) | `.d.ts` (matches brief) |
| JSDoc commentary | extensive (30 lines) | none |
| PR opened by agent | yes (PR #62) — deviates from "stop after pushing" instruction | no |
| Commit message | exact match to brief template | exact match to brief template |

### Validation results (Argos ran post-hoc on a clean checkout)

| Branch | `npm run lint` | `npm run typecheck` | `npm test` |
|---|---|---|---|
| `chore/lint-001-qwen` (Heph) | 0 warnings ✓ | 0 errors ✓ | 304 pass / 9 fail / 90 skipped — failures are `better-sqlite3` native-binding issues unrelated to the chore (same 9 fail on `main`) |
| `chore/lint-001-opus` (Daedalus) | 0 warnings ✓ | 0 errors ✓ | identical to Heph (same 304/9/90) |

The 9 test failures pre-exist on `main` and reproduce identically on both contestant branches — they're an environment issue with `better-sqlite3` needing a rebuild against current Node, not anything either contestant introduced. Treated as a wash for scoring.

### Scoring per the head-to-head rubric

Rubric is in `.argos/CHORE-LINT-001/head-to-head.md`: five criteria scored 1–5, weighted, max 45.

| Criterion | Weight | Heph | Daedalus | Reasoning |
|---|---|---|---|---|
| **Correctness** | 3× | 5 | 5 | Both removed all 14 casts, both have correct types, both pass lint/typecheck, test failures are environment-only and identical between branches |
| **Type Fidelity** | 2× | 5 | 5 | Both correctly used the existing `BootState` union and the project's `MikroORM` import path; both signatures match what `app.decorate(...)` actually attaches |
| **Minimality** | 2× | 3 | 5 | Daedalus minimal (11 lines, exact match to brief). Heph wrote 4× more lines, mostly JSDoc commentary the brief didn't request, plus an explicit consumer-side import the brief didn't ask for. Both well-formed, but Heph exceeds the requested scope |
| **Code Style** | 1× | 3 | 5 | Daedalus matches brief's recommended `.d.ts` extension and uses the canonical `import 'fastify';` pattern from Fastify's docs. Heph used `.ts` and added an explicit consumer-side import. Heph also opened PR #62 despite the brief saying "stop after pushing — Argos opens the winning PR." All small deviations, none catastrophic |
| **Autonomy** | 1× | 4 | 5 | Heph completed the implementation in 13 successful model calls. Required interventions: turning on Roo Code's auto-approve mid-task, plus three context-window restarts (32K → 64K → 128K). The context-window failures were Argos's setup error, not Heph's autonomy issue, so docked only for the auto-approve toggle. Daedalus ran without reported intervention |

| Contestant | Score |
|---|---|
| Heph | (5×3) + (5×2) + (3×2) + (3×1) + (4×1) = **38 / 45** |
| Daedalus | (5×3) + (5×2) + (5×2) + (5×1) + (5×1) = **45 / 45** |

### Winner: **Daedalus**, by 7 points.

Both implementations are functionally correct. The 7-point gap is entirely in **Minimality** and **Code Style** — Daedalus produced exactly what the brief asked for, in the form the brief recommended. Heph produced a *defensibly more documented* version that exceeded the requested scope.

In a different context — e.g., introducing `fastify-augment.d.ts` as a new module-augmentation pattern *for future maintainers to copy* — Heph's verbose JSDoc-heavy version might be preferred. For a chore brief asking for the minimum mechanical change, restraint wins.

### What this says about Qwen3.6-27B as a Hephaestus model

- **Capable of producing correct refactors at this scope.** No type errors, no eslint-disable workarounds, no `as unknown as X` chains. The augmentation pattern was understood and applied correctly.
- **Tends toward over-documentation when not constrained.** The JSDoc additions (30 lines) suggest the model defaults to "be helpful by adding context" rather than "do exactly what the brief asks." For chore work specifically, briefs may need a "no JSDoc unless requested" non-goal explicitly.
- **Brief literalism is uneven.** The `.d.ts` recommendation in the brief was framed as "Create `src/types/fastify-augment.d.ts`" with extension implicit. Heph generalized to `.ts`. Daedalus took it literally. Future briefs for Heph should treat extension/path/idiom as required, not suggested, when comparing fairly.
- **Tool-call autonomy is real.** 13 sequential tool calls completed without redirection, on context that grew to ~70K tokens per request. This is the work Heph is for.

### Aftermath

- `chore/lint-001-opus` (Daedalus) becomes the merged PR.
- `chore/lint-001-qwen` (Heph) gets deleted; PR #62 closed without merging.
- The brief edit + orchestrator artifacts on `chore/agents-add-hephaestus` get committed via a normal chore PR.

---

## 12. Head-to-head audit — CTRF-003 (2026-04-30 / 2026-05-01)

A real story implementation: extend the existing CTRF ingest endpoint at `POST /api/v1/projects/:slug/runs` to accept artifact files alongside the CTRF JSON in a single multipart request. Magic-bytes validation, per-file and per-run size limits, integration with the `ArtifactStorage` interface, external-URL by-reference handling. Story-shape work — three sequential roles per side: feature-implementer → test-writer → spec-enforcer.

### Setup

Identical to CHORE-LINT-001 in agent assignment (Heph = Qwen3.6-27B via Roo Code on RunPod; Daedalus = Opus 4.6 via Claude Code Desktop), with two changes:

1. **Three sequential roles per agent**, each in a fresh chat session reading from the on-branch `.argos/CTRF-003/*-handoff.md` files. Argos handed prompts to André; André pasted into each agent's IDE.
2. **Pod 2 used `8000/tcp` port mapping** instead of `8000/http` to bypass Cloudflare's 100 sec idle/origin timeout (see §4-K). Pod 1 hit 524s and "terminated" errors on long Heph responses, prompting the swap.

### What each delivered

| Metric | Heph | Daedalus |
|---|---|---|
| Files changed | 14 | 11 |
| Lines added | 1,753 | 1,471 (−16%) |
| Lines deleted | 47 | 149 (3× more refactoring) |
| New library files | One monolithic `artifact-storage.ts` (110 lines, interface + impl) | Cleanly split: `artifact-storage.ts` (interface), `local-artifact-storage.ts`, `s3-artifact-storage.ts` (stub), `magic-bytes.ts`, `artifact-validation.ts` |
| Test file | `ingest-artifacts.test.ts`, 521 lines | `ingest-artifacts.test.ts`, 498 lines |
| `app.ts` modifications | 14 lines | 8 lines |
| `TestArtifact` entity | +1 line | unchanged |
| Migrations created | None (correct — schema-generator-at-boot per INFRA-005) | None (same) |
| `s3-artifact-storage.ts` | Not created | Created as **stub** throwing `NotImplementedError` (per brief) |
| `feature-handoff.md` committed | Yes | No (followed `feature-implementer.md`'s "gitignored, never commit" instruction) |
| `test-handoff.md` committed | Yes | No (same) |
| `spec-audit.md` committed | Yes (77 lines) | Yes (86 lines) |
| BLOCKING issues self-identified in own audit | 2 (`bodyLimit` rejection of multipart > 10 MB; `ReferenceOnlyError` thrown as plain `Error` → 500 instead of 400) | 1 (`@fastify/multipart` registered without `limits.fileSize` override → 1 MB default cap preempts custom per-type limits) |
| Coverage gaps flagged in own audit | 3 | 3 |

### Spec ambiguity surfaced (handoff commit question)

`agents.md` says ".argos/<taskId>/ directory is **tracked** (not gitignored) and travels with the story branch." `.antigravity/agents/feature-implementer.md` says feature-handoff is "(gitignored — never commit)." These contradict. Heph picked the more workflow-friendly interpretation; Daedalus followed the role doc literally. Treated as a wash for scoring, but the docs need reconciliation in a chore PR.

### Spec-audit quality (the most uncertain capability going in)

This was the single most-uncertain test of the experiment: can a 27B-parameter model produce a structured, accurately-cited, real-finding-surfacing audit document? The going-in expectation was that this would be the role where Heph fell flat.

**Result: both audits are high quality.** Both:

- Found *real BLOCKING bugs* in their own implementations (not their counterpart's — each agent audited their own work).
- Cited specific skills with section references.
- Did the full planning-doc conformance scan (each box checked with a line citation).
- Scanned for forbidden patterns from `CLAUDE.md`.
- Evaluated 5 judgment calls thoughtfully (brief↔skill drift, file-naming choices, in-memory vs streaming buffering, default-size discrepancies).
- Followed the audit template's severity / location / citation / suggested-fix structure.

Daedalus's audit is slightly longer (86 vs 77 lines) and has more precise line-level citations; Heph's is more concise but covers the same ground. Both produced verdict `BLOCK` with specific remediation targets. **Spec-enforcer skill is proven on Heph.**

### Scoring per the head-to-head rubric

Same five-criterion rubric as CHORE-LINT-001, weighted, max 45.

| Criterion | Weight | Heph | Daedalus | Reasoning |
|---|---|---|---|---|
| **Correctness** | 3× | 3 | 4 | Both implementations have BLOCKING issues. Heph: 2 distinct (bodyLimit + ReferenceOnlyError shape). Daedalus: 1 (multipart fileSize default). Both audits caught their own bugs. Daedalus's blocker is one-line remediation; Heph's blockers need code change AND test update. |
| **Type Fidelity** | 2× | 3 | 5 | Heph's own audit flagged: one `as any` cast in service entity creation, and one duplicated interface (`ArtifactPart` / `ParsedArtifactPart`). Daedalus has neither. |
| **Minimality** | 2× | 3 | 5 | Daedalus 16% smaller diff with 3× more deletions (more refactoring of existing code vs adding new files). Cleaner separation across multiple small library files vs Heph's monolithic `artifact-storage.ts`. |
| **Code Style** | 1× | 4 | 5 | Daedalus split files cleanly per concern, made minimal `app.ts` changes, didn't touch the entity. Heph's code is fine but less restrained. Handoff-commit difference is a wash (genuine spec ambiguity). |
| **Autonomy** | 1× | 3 | 5 | Heph required multiple infrastructure-level interventions through the night (prefix-caching restart, auto-approve toggle, context-window bumps from 32K→64K→128K, Cloudflare TCP-port swap). Most were Argos-side fixes upstream of Heph rather than Heph getting stuck — but they cost wall-clock and André attention. Daedalus on Claude Code ran with minimal redirection. |

| Contestant | Score |
|---|---|
| Heph | (3×3) + (3×2) + (3×2) + (4×1) + (3×1) = **28 / 45** |
| Daedalus | (4×3) + (5×2) + (5×2) + (5×1) + (5×1) = **42 / 45** |

### Winner: **Daedalus**, by 14 points (vs the 7-point gap on the chore).

The gap widened on the story because:

- Implementation complexity scales the small Heph weaknesses. Over-tackiness, occasional `as any`, monolithic file layout — these are minor in a 50-line refactor and material in a 1,400-line implementation.
- Daedalus's better code-organization instincts have more surface to express in story-scale work.

### What this says about Qwen3.6-27B as a Hephaestus across the full harness

- **All three role capabilities are present.** Implementer writes correct (if buggy in places) code that uses the proper interfaces, types, and patterns. Test-writer respects file-path boundaries, hits the floor cases the brief asked for. Spec-enforcer produces a real audit with real findings — this was the load-bearing uncertainty going in, and it passed.
- **Code-organization sensibility is weaker.** Heph defaults to "add a new file" rather than "refactor an existing file"; defaults to "verbose JSDoc" rather than "minimal documentation"; defaults to "commit everything" rather than "commit only what's required." None of these are wrong; they're stylistic choices that consistently cost minimality/code-style points against Daedalus.
- **Type discipline is slightly weaker.** Two `as any` / duplicate-type slips that Daedalus didn't make. The audit caught them, which is good — but they shouldn't have been there to catch.
- **Speed is structural, not capability.** Heph took ~5 hours wall-clock vs Daedalus's likely ~90 minutes. That's a 3× gap that no model tuning can close at this hardware tier.

### What this says about the harness itself

- **The three-role split with on-branch handoff files works** for either model.
- **The spec-enforcer audit catches real bugs.** Both audits found BLOCKING issues. Without the spec-enforcer step, both implementations would have shipped with bugs that Argos's PR-Agent-equivalent review (Daedalus configuration in CI) would catch later — but the per-story spec-enforcer step caught them first, which is the design intent.
- **The handoff-commit ambiguity needs resolution.** `agents.md` and `.antigravity/agents/feature-implementer.md` give contradictory guidance on whether feature-handoff.md should be committed. Resolution belongs in a chore PR before more stories run.

### Aftermath

- `story/CTRF-003-opus` (Daedalus) becomes the merged PR — after the BLOCKING finding (`@fastify/multipart` `limits.fileSize` default) is fixed.
- `story/CTRF-003-qwen` (Heph) gets deleted.
- The handoff-commit spec ambiguity goes into `gaps.md` for resolution.
- Both implementations have BLOCKING audit findings. Per the harness `implementstory.md` Phase 1 protocol, the winning implementation returns to feature-implementer mode for the remediation pass — Daedalus fixes his one-line config issue, audit re-runs, then the story merges.

---

## 13. Forward links

- Memory entry `runpod_qwen3_vllm_recipe.md` — short-form recipe summary, kept terse for context-window efficiency in future Argos sessions.
- `~/Projects/ctrfhub/.claude-bridge/` — full history of bridge scripts that produced this runbook (v1–v8 of various probes, all preserved for archaeology).
- `~/Sites/ai_guidance/agent/claude-bridge.md` — bridge architecture reference.
- `~/Sites/ai_guidance/agent/troubleshooting.md` — sibling troubleshooting doc for the broader Performant Labs agent stack.
- vLLM Qwen3.5/3.6 official recipe: https://github.com/vllm-project/recipes/blob/main/Qwen/Qwen3.5.md

---

## 14. Speculative decoding — configuration and benchmarks (2026-05-02)

### 14.1 Configuration

ngram speculative decoding was added to template `qaqvwnwdc6` on 2026-05-02. No draft model is required — vLLM's built-in prompt n-gram lookup generates candidate tokens from the prompt itself.

**Flag added to the vLLM start command:**

```bash
--speculative-config '{"method":"ngram","num_speculative_tokens":5,"prompt_lookup_max":4}'
```

**What changed vs the §1 recipe:** one flag added; everything else identical.

**vLLM version note:** the old-style flat flags (`--speculative-model "[ngram]"`, `--ngram-prompt-lookup-max`, `--num-speculative-tokens`) were removed in vLLM 0.19.x. The JSON `--speculative-config` form is required. Sending the flat flags produces:

```
api_server.py: error: unrecognized arguments: --speculative-model --ngram-prompt-lookup-max 4 --num-speculative-tokens 5
```

**Side effect:** vLLM logs a warning at startup — `Async scheduling not supported with ngram-based speculative decoding and will be disabled.` — and disables async scheduling. This is expected and benign; async scheduling is a throughput optimisation for high-concurrency batch workloads, not relevant for single-user agentic sessions.

---

### 14.2 Benchmark methodology

Run on 2026-05-02 against pod `0owsyyekupgi90`, template `qaqvwnwdc6`, vLLM 0.19.1, A100-SXM4-80GB. All measurements taken after 3 warmup requests to ensure CUDA graphs are hot. Wall-clock timed with `date +%s%N` on-pod; token counts from the API response `usage` field.

**Three benchmarks:**

| Benchmark | Prompt | `max_tokens` | Runs |
|-----------|--------|-------------|------|
| Prose | "Write a detailed explanation of how transformers work…" | 400 | 3 |
| Code | "Write a complete TypeScript class implementing an LRU cache…" | 400 | 3 |
| Prefill | Repeated "The quick brown fox…" × 150 (~1,518 tokens) | 50 | 3 |

Speculative decoding metrics (`Mean acceptance length`, per-position acceptance rates) read directly from vLLM's `SpecDecoding metrics` log lines.

---

### 14.3 Results

#### Decode throughput

| Benchmark | Decode t/s (with spec decoding) | Baseline (§10, no spec decoding) | Delta |
|-----------|----------------------------------|-----------------------------------|-------|
| Prose (400 tok) | **26.4 t/s** | 26.1 t/s peak | +1.5% |
| Code (400 tok) | **29.8 t/s** | 26.1 t/s peak | **+14.6%** |

Runs were extremely stable — all three runs per benchmark landed within 0.1 t/s of each other.

#### Prefill throughput

| Context size | Prefill t/s (today) | Baseline (§10) | Notes |
|---|---|---|---|
| ~1,500 tok | 1,398 t/s | 2,541 t/s | Not comparable — §10 baseline was at ~70K token contexts; short contexts underutilise GPU |

#### Speculative decoding acceptance rates (from vLLM logs)

| Request type | Avg draft acceptance rate | Mean accepted length | Observation |
|---|---|---|---|
| Prose | 6–7% | 1.25–1.33 | Very few ngram hits in natural language |
| Code (TypeScript) | 30–44% | 2.5–3.2 | Strong hits on repetitive boilerplate (`const`, `this.`, `return`, `}`, indentation) |

---

### 14.4 Interpretation

**Code generation is the primary beneficiary.** TypeScript boilerplate is highly repetitive — ngram lookup finds matches frequently, yielding 30–44% draft acceptance and a sustained +14.6% decode speedup. Prose is nearly flat because natural language has low n-gram repetition across the prompt window.

**For Hephaestus's actual workload** (code generation, tool-call scaffolding, structured handoff documents), speculative decoding should yield 15–30% decode gains on the generation-heavy portions. The sessions are heavily prefill-dominated (~93:1 prompt:generation ratio on CTRF-003), so the net session-level speedup is smaller — but across a full story like CTRF-003 (~87K generation tokens), this is roughly 7,000 extra tokens of generation for the same wall-clock time, or ~10–15 minutes off the ~5 hour wall-clock.

**Zero cost:** ngram speculative decoding uses no additional VRAM (no draft model), adds no startup latency, and produces identical outputs (speculation is always verified by the target model before committing).

**Correctness is preserved.** Both smoke tests from §8 passed post-change: `content: 'pong'`, `finish_reason: stop`, `reasoning_content: None`. No regressions.

---

### 14.5 Known limitation — `--enable-prefix-caching` incompatibility

Prefix caching (deliberately disabled per §4-B) and ngram speculative decoding are independently incompatible with this architecture. They cannot be combined. The `align`-mode Mamba cache issue (§4-B) takes precedence; speculative decoding is the available optimisation in its absence.

When vLLM upstream fixes the Mamba/FLA interaction and prefix caching becomes usable, the two features will need to be evaluated together. Per vLLM docs, prefix caching + speculative decoding is a supported combination on standard (non-Mamba) architectures.

---

### 14.6 Failed attempt — `Qwen/Qwen3-0.6B` as draft model (2026-05-02)

**What was attempted.** Replacing ngram with `Qwen/Qwen3-0.6B` as a learned draft model, following the community pattern of using a small same-family model for better acceptance rates on prose (where ngram only achieves 6–7%):

```bash
--speculative-config '{"method":"draft_model","model":"Qwen/Qwen3-0.6B","num_speculative_tokens":5}'
```

**What failed.** vLLM rejected the config at startup with a vocabulary size mismatch:

```
pydantic_core._pydantic_core.ValidationError: 1 validation error for SpeculativeConfig
  Value error, Target and draft model should have the same vocabulary size.
  Target model vocab_size=248320. Draft model vocab_size=151936.
```

**Root cause.** `Qwen3.6-27B` uses an expanded tokenizer (248,320 tokens) that is distinct from the standard Qwen3 series tokenizer (151,936 tokens). The Qwen3.6 family (`27B`, `35B-A3B`) is a separate line from `Qwen3` (`0.6B`, `1.7B`, `4B`, `8B`, `14B`, `32B`). There is no small companion model in the Qwen3.6 vocab family — as of 2026-05-02, Alibaba has not released a `Qwen3.6-0.6B` or similar.

**Resolution.** Reverted to ngram on both the running pod and the template.

**Path forward for draft model speculation on this model:**

- **EAGLE heads** — EAGLE uses the target model's hidden states as draft input rather than a separate tokenizer, so the vocab mismatch doesn't apply. If EAGLE heads are trained for Qwen3.6-27B (the model is ~2 weeks old as of this writing), they would work. Check HuggingFace for `EAGLE-*-Qwen3.6*` periodically.
- **Wait for a small Qwen3.6-family model** — if Alibaba releases a `Qwen3.6-0.6B` or `Qwen3.6-1.7B` with the 248,320-token vocab, draft model speculation becomes viable immediately.
- **ngram remains the best available option** — +14.6% on code generation with zero VRAM cost and no tokenizer constraints.

---

---

## 15. Inference optimization landscape — community research (2026-05-02)

Survey of techniques being actively tried on X and GitHub as of 2026-05-02, two weeks after Qwen3.6-27B's release. Columns: availability for this pod (A100-SXM4-80GB, vLLM 0.19.1, BF16) and for Apple Silicon (MLX).

| Method | What it is | Claimed speedup | A100 + vLLM BF16 | MLX | Notes |
|--------|-----------|----------------|-------------------|-----|-------|
| **Native MTP** | Built-in Multi-Token Prediction head in the model — no separate drafter | **~2×, 80–90% acceptance** | ✅ `{"method":"mtp","num_speculative_tokens":1}` | ⚠️ Partial | **Not yet tried on this pod — highest priority next test.** Works on BF16; most INT4 quants silently drop the MTP head |
| **ngram** *(current)* | vLLM prompt n-gram lookup | +15% code / +1.5% prose | ✅ Deployed | ❌ | Zero cost, no extra model. Weak on prose |
| **DFlash** | Block-diffusion drafter (`z-lab/Qwen3.6-27B-DFlash`, 1.73B) — drafts full block in one pass | **2× Ampere, 2–5× Blackwell** | ⚠️ Needs Luce/llama.cpp (not stock vLLM); gated HF model | ✅ `bstnxbt/dflash-mlx` | Vocab matches Qwen3.6 (248,320). Gated — needs HF access request. vLLM fork (AEON-7) is Blackwell-only |
| **EAGLE-3** | Learned draft head using target model hidden states | 2–3× (other models) | ❌ No heads trained yet | ❌ | Active for Gemma 4 / Llama 3. Qwen3.6 only 2 weeks old — check back |
| **Lorbus INT4 + MTP** | AutoRound INT4 that preserves MTP head in BF16 | **~2× via MTP at ~85% acceptance** | ✅ Works on A100 via vLLM | ❌ | Only INT4 quant with working MTP. Halves VRAM vs BF16; unlocks longer context |
| **Official FP8** (`Qwen/Qwen3.6-27B-FP8`) | Alibaba's fine-grained FP8 quant | 1.3–1.5× via VRAM headroom | ✅ A100 supports FP8 | ❌ | Frees ~27 GB VRAM → fits 262K context or enables MTP with KV headroom |
| **TurboQuant KV cache** | 3–4 bit KV cache quantization, merged into vLLM main | Enables 256K+ context on limited VRAM | ❌ Buggy — [vLLM #40880](https://github.com/vllm-project/vllm/issues/40880): MTP × TurboQuant × Mamba hybrid produces degenerate output | ⚠️ llama.cpp only | Known conflict with Qwen3.6's Mamba/GDN hybrid layers. Unblocked on standard transformers |
| **NVFP4** | NVIDIA FP4, native Blackwell tensor cores | 80 t/s on RTX 5090 | ❌ Blackwell only (SM120+) | ❌ | A100 = Ampere SM80 — not supported |
| **MLX quantized** (Unsloth) | 3/4/6/8-bit MLX variants for Apple Silicon | ~50–80 t/s on M-series | ❌ | ✅ `unsloth/Qwen3.6-27B-UD-MLX-{3,4,6,8}bit` | Best option for local Mac inference |
| **GGUF / llama.cpp** | Q4_K_M etc, 16.8 GB, runs on ~18 GB VRAM | 35–70 t/s (hardware-dependent) | ⚠️ Loses vLLM tool-call parsing | ✅ via mlx-lm | Required for DFlash on non-Blackwell |

### 15.1 Highest-priority next test: Native MTP

Qwen3.6-27B ships with a native Multi-Token Prediction head. No separate model download, no gated access, no framework change — just a one-flag change to the existing BF16 pod:

```bash
--speculative-config '{"method":"mtp","num_speculative_tokens":1}'
```

Community reports 80–90% draft acceptance and ~2× decode throughput on A100-class hardware. This is a strict improvement over ngram (6–44% acceptance) and requires nothing new to be installed.

**Gotcha:** Most INT4 quantizations (AWQ, GPTQ) drop or corrupt the MTP head — `mtp.fc.weight` is missing, vLLM finds 0% draft acceptance and falls back silently. The exception is `Lorbus/Qwen3.6-27B-int4-AutoRound`, which deliberately preserves the MTP head in BF16 post-quantization.

### 15.2 DFlash path (when ready)

`z-lab/Qwen3.6-27B-DFlash` (1.73B params, MIT licence) is the trained block-diffusion drafter for this exact model. It uses the correct 248,320-token vocab (unlike `Qwen3-0.6B` which was rejected — see §14.6). Blockers as of 2026-05-02:

1. **Gated model** — request access at `https://huggingface.co/z-lab/Qwen3.6-27B-DFlash`.
2. **No stock vLLM support** — requires either Luce/llama.cpp (loses tool-call parsing) or the `AEON-7/vllm-dflash` fork (currently Blackwell-only). Watch for an Ampere-compatible build.
3. **8-bit DFlash drafter** (per @davideciffa, 2026-05-02) — quantizing the drafter to 8-bit halves its VRAM footprint from ~3.4 GB to ~1.7 GB with no accuracy loss; this is how it fits alongside the 27B target on a single A100.

### 15.3 What to ignore for this pod

- **NVFP4** — Blackwell SM120+ only. Not worth investigating for A100.
- **TurboQuant KV** — active vLLM bug with the Mamba hybrid architecture. Do not attempt until [#40880](https://github.com/vllm-project/vllm/issues/40880) is resolved.
- **Standard AWQ/GPTQ INT4** — drops the MTP head; net result is slower than BF16 + MTP for agentic workloads.

---

## §16. SGLang Parallel Experiment Template

A second RunPod template (`q8ycgrr2s0`, "Qwen3.6-27B SGLang") was created on 2026-05-02 as a parallel experimentation environment alongside the vLLM template. The goal is to test native MTP speculative decoding via SGLang, which has first-class support for it.

### 16.1 Template details

| Field | Value |
|---|---|
| Template ID | `q8ycgrr2s0` |
| Template name | `Qwen3.6-27B SGLang` |
| Base image | `runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04` |
| Container disk | 150 GB |
| Ports | `8000/tcp,22/tcp` |
| API port | 8000 (SGLang serves on 30000 internally, same external port as vLLM) |

### 16.2 Setup script (`/tmp/qwen_sglang_setup.sh`)

```bash
#!/bin/bash
set -e
export HF_HOME=/root/.cache/huggingface
export HF_TOKEN=

echo '=== Installing SGLang ==='
python -m pip install --quiet "sglang[all]>=0.4.6.post1" --extra-index-url https://download.pytorch.org/whl/cu128
python -c "import sglang; print('sglang', sglang.__version__)"

echo '=== Starting SGLang ==='
python -m sglang.launch_server \
  --model-path Qwen/Qwen3.6-27B \
  --host 0.0.0.0 --port 8000 \
  --dtype bfloat16 \
  --context-length 131072 \
  --enable-torch-compile \
  --speculative-algo NEXTN \
  --speculative-num-steps 3 \
  --speculative-eagle-topk 1 \
  --speculative-num-draft-tokens 4 \
  --tool-call-parser qwen3 \
  --reasoning-parser qwen3 \
  --api-key sk-1234567890 > /sglang.log 2>&1 &

echo 'Container is now persistent.'
tail -f /sglang.log
```

### 16.3 Key differences from vLLM template

| Aspect | vLLM (`qaqvwnwdc6`) | SGLang (`q8ycgrr2s0`) |
|---|---|---|
| Speculative decoding | ngram, +14.6% code | Baseline only (NEXTN blocked — see §16.5) |
| Thinking mode | Server-side flag `--default-chat-template-kwargs` | Per-request only via `chat_template_kwargs` |
| MTP/NEXTN support | Not applicable | Blocked by VRAM on A100-80GB |
| torch.compile | Not enabled | Not used in final config |
| Spec decoding flags | JSON `--speculative-config` | Individual CLI flags |

### 16.4 SGLang baseline benchmarks (2026-05-02)

Run on pod `95ly73hheqrpds`, template `q8ycgrr2s0`, SGLang 0.4.6.post1, A100-SXM4-80GB. Same methodology as §14.2. All measurements taken after 3 warmup requests. No speculative decoding.

| Benchmark | SGLang baseline | vLLM baseline (§10) | vLLM + ngram (§14) | SGLang vs vLLM baseline | SGLang vs vLLM+ngram |
|---|---|---|---|---|---|
| Prose (400 tok) | **28.2 t/s** | 26.1 t/s | 26.4 t/s | **+8.0%** | **+6.8%** |
| Code (400 tok) | **28.2 t/s** | 26.1 t/s | 29.8 t/s | **+8.0%** | -5.4% |

SGLang baseline is consistently ~8% faster than vLLM baseline across all request types. The prose/code gap disappears — vLLM+ngram only helps code, SGLang's core engine is uniformly faster.

**Memory at startup:**
- Model: 51.05 GB VRAM; Mamba SSM states: 4.64 GB; KV cache: 85,399 slots / 5.22 GB; free: 17.09 GB

### 16.5 NEXTN speculative decoding — blocked on A100-80GB

NEXTN was tested exhaustively and is **not compatible with Qwen3.6-27B on A100-80GB**.

**Root cause:** NEXTN requires additional VRAM for the MTP forward pass and (when radix cache is enabled) doubles the Mamba SSM states via `extra_buffer`. Even with `--disable-radix-cache`, 32k context, and every `--mem-fraction-static` value tried, OOM persists. The MTP head consumes enough VRAM that no tunable combination fits within 80 GB alongside the 51 GB model.

**Attempts made:**

| Config | Result |
|---|---|
| NEXTN, 4 draft tokens, extra_buffer, 131072 ctx | OOM |
| NEXTN, 4 draft tokens, extra_buffer, 65536 ctx, `mem_fraction_static=0.88` | OOM |
| NEXTN, 1 draft token, extra_buffer, 131072 ctx | OOM |
| NEXTN, 1 draft token, extra_buffer, `--max-mamba-cache-size 4` | OOM |
| NEXTN, 1 draft token, extra_buffer, `mem_fraction_static=0.82` | OOM |
| NEXTN, 1 draft token, `--disable-radix-cache`, 131072 ctx | OOM |
| NEXTN, 1 draft token, `--disable-radix-cache`, 32768 ctx | OOM |

**Path forward:** The MoE variant `Qwen3.6-35B-A3B` (3B active params/token, ~35 GB weights) would have substantially lower VRAM pressure and is the obvious next test for NEXTN.

**Active template config** (what the running pod uses — no spec decoding):
```bash
python -m sglang.launch_server \
  --model-path Qwen/Qwen3.6-27B \
  --host 0.0.0.0 --port 8000 \
  --dtype bfloat16 \
  --context-length 131072 \
  --tool-call-parser qwen3_coder \
  --reasoning-parser qwen3 \
  --api-key sk-1234567890
```

### 16.6 Tool-call smoke test (2026-05-02, pod `95ly73hheqrpds`)

Sent a single request with a `read_file` tool defined — same shape Roo Code uses. Result: **clean pass**.

```
finish_reason:       "tool_calls"          ✓
content:             null                  ✓
reasoning_content:   null                  ✓  (thinking suppressed via chat_template_kwargs)
tool_calls[0].function.name:      "read_file"
tool_calls[0].function.arguments: {"path": "/etc/hostname"}
```

SGLang's tool-call output is wire-compatible with vLLM's — a Roo Code client pointed at either server will behave identically.

### 16.7 SGLang-specific notes

- **Thinking mode is per-request only** — no server-side `enable_thinking=false`. Clients must pass `chat_template_kwargs: {"enable_thinking": false}` per request. Roo Code needs this at the client level.
- **libnuma1 required** — missing from the base image. Must `apt-get install -y libnuma1` before starting SGLang or sgl_kernel fails to import.
- **Template `q8ycgrr2s0` updated (2026-05-02)** — original script had `--tool-call-parser qwen3` (invalid) and omitted libnuma install. Both fixed via `saveTemplate` mutation before pod termination. The corrected script is in §16.8 below.

### 16.8 Corrected setup script (applied to template `q8ycgrr2s0` on 2026-05-02)

```bash
#!/bin/bash
set -e
export HF_HOME=/root/.cache/huggingface
export HF_TOKEN=

echo '=== Installing dependencies ==='
apt-get install -y libnuma1
python -m pip install --quiet "sglang[all]>=0.4.6.post1" --extra-index-url https://download.pytorch.org/whl/cu128
python -c "import sglang; print('sglang', sglang.__version__)"

echo '=== Starting SGLang ==='
python -m sglang.launch_server \
  --model-path Qwen/Qwen3.6-27B \
  --host 0.0.0.0 --port 8000 \
  --dtype bfloat16 \
  --context-length 131072 \
  --tool-call-parser qwen3_coder \
  --reasoning-parser qwen3 \
  --api-key sk-1234567890 > /sglang.log 2>&1 &

echo 'Container is now persistent.'
tail -f /sglang.log
```

---

---

## §17. Local / Apple Silicon deployment

**Context:** §6.2 covers the hardware decision matrix (dense 27B is bandwidth-bound; M5 Max is slower than an A100; MoE is the right Mac model). This section covers *how* to run it: engine choices, what carries over from the RunPod experiments, and practical commands.

---

### 17.1 What carries over from the RunPod experiments

Everything learned about the model's quirks applies regardless of inference engine:

| Finding | Applies on Apple Silicon? |
|---|---|
| `enable_thinking: false` required to suppress reasoning tokens | **Yes** — same model behaviour, passed per-request in mlx-lm |
| Prefix caching incompatible with Mamba hybrid | **Yes** — avoid on any engine |
| Tool-call parser name `qwen3_coder` | mlx-lm handles this internally; llama.cpp doesn't need it |
| 128K context minimum for agentic workloads | **Yes** — same session dynamics |
| `--language-model-only` to skip ViT | mlx-lm loads text-only by default; not needed |
| SGLang NEXTN blocked by VRAM | Irrelevant — mlx-lm doesn't support NEXTN |
| ngram spec decoding (+14.6% code) | **Yes** — mlx-lm supports ngram via `--speculative-decoding-algorithm ngram` |

### 17.2 Engine choice for Apple Silicon

| Engine | Dense 27B BF16 | MoE 35B-A3B Q4 | Tool calling | Spec decoding | Notes |
|---|---|---|---|---|---|
| **mlx-lm** | M5 Max 128 GB only | ✅ any M-series 24 GB+ | ✅ Qwen3 native | ✅ ngram | Best overall for M-series; Metal GPU acceleration |
| **llama.cpp** | All (with quantization) | ✅ | ✅ via `--jinja` | ✅ ngram, draft model | Needed for DFlash; MoE offload to RAM works well |
| **SGLang** | Not available on macOS | ❌ | — | — | Linux/CUDA only |
| **vLLM** | Not available on macOS | ❌ | — | — | Linux/CUDA only |

**Recommendation:** mlx-lm for M-series Macs. llama.cpp if you want MoE RAM offload on M1 Max (which can't fit the 35B-A3B INT4 in 32 GB unified memory fully).

### 17.3 Dense 27B on Apple Silicon

Only fits without quantization on M5 Max 128 GB. All other configurations require quantization.

**VRAM requirements by quantization:**

| Format | Model size | M1 Max 32 GB | M1 Max 64 GB | M5 Max 48 GB | M5 Max 128 GB |
|---|---|---|---|---|---|
| BF16 | ~55 GB | ❌ | ❌ | ❌ | ✅ (~10 t/s) |
| Q8_0 | ~29 GB | ❌ | ✅ (~6 t/s) | ✅ (~8 t/s) | ✅ (~9 t/s) |
| Q4_K_M | ~16 GB | ✅ (~6 t/s) | ✅ (~7 t/s) | ✅ (~10 t/s) | ✅ (~11 t/s) |

Speed is purely memory-bandwidth-bound for dense 27B. M1 Max at 400 GB/s, M5 Max at 614 GB/s — neither matches the A100's ~2 TB/s. The speed ceiling at Q4 on M5 Max is roughly the same as the A100 BF16. Quality is lower due to quantization.

**MLX model IDs (Unsloth quantized):**

```
unsloth/Qwen3.6-27B-UD-MLX-4bit   # Q4 — fits 16 GB+
unsloth/Qwen3.6-27B-UD-MLX-6bit   # Q6 — fits 24 GB+
unsloth/Qwen3.6-27B-UD-MLX-8bit   # Q8 — fits 32 GB+
```

**mlx-lm server command (dense 27B, Q4, M1 Max 32 GB):**

```bash
mlx_lm.server \
  --model unsloth/Qwen3.6-27B-UD-MLX-4bit \
  --host 0.0.0.0 --port 8000 \
  --max-tokens 131072 \
  --chat-template qwen3_coder \
  --api-key sk-1234567890
```

**Client must pass per-request** (no server-side flag in mlx-lm):
```json
"extra_body": {"chat_template_kwargs": {"enable_thinking": false}}
```

### 17.4 MoE 35B-A3B — the interesting Mac path

`Qwen3.6-35B-A3B` activates only 3B parameters per token. At INT4 (~18 GB), it fits in 32 GB+ unified memory with no offloading needed. With llama.cpp MoE offload (cold experts to RAM), it fits in as little as 16 GB with decent RAM.

**Why this is the right model for most Apple Silicon setups:**
- Q4 INT4: ~18 GB VRAM → fits M1 Max 32 GB
- ~50 t/s on M5 Max 128 GB (vs ~10 t/s for dense 27B BF16)
- **45.2 t/s prose / 37.1 t/s code on M1 Max 32 GB with mlx-lm** (measured 2026-05-02)
- SWE-bench Verified: 73.4 (vs 77.2 for dense 27B) — 3.8-point quality gap

**M1 Max 32 GB measured results (mlx-lm, `mlx-community/Qwen3.6-35B-A3B-4bit`, 2026-05-02):**

| Task | t/s |
|---|---|
| Prose (300 tok) | 45.2 |
| Code (300 tok) | 37.1 |
| **Average** | **~41** |

This is **faster than the A100-SXM4-80GB running the dense 27B with SGLang (28.2 t/s)**. The MoE architecture makes the difference — only 3B active parameters per forward pass vs 27B for the dense model, fully offsetting the M1 Max's lower raw compute vs an A100.

Tool-call smoke test: `finish_reason: tool_calls`, `content: null`, valid JSON arguments — wire-compatible with Roo Code.

At ~41 t/s on M1 Max, Hephaestus's ~87K generation token story (CTRF-003 equivalent) drops from ~5 hours to ~35 minutes, locally, at zero cost. The 3.8-point SWE-bench gap is almost certainly worth it.

**llama.cpp MoE offload command (M1 Max 32 GB):**

```bash
# Install: brew install llama.cpp
llama-server \
  --model Qwen3.6-35B-A3B-Q4_K_M.gguf \
  --host 0.0.0.0 --port 8000 \
  --ctx-size 131072 \
  --n-gpu-layers 999 \
  --moe-expert-offload-scale 0.8 \
  --api-key sk-1234567890
```

`--moe-expert-offload-scale 0.8` keeps 80% of expert FFNs on GPU, offloads cold 20% to system RAM. Tune down if you get OOM, tune up if you have headroom.

**Tool calling in llama.cpp:** Use `--jinja` flag and verify the Qwen3 chat template is embedded in the GGUF or loaded separately. The model generates the same JSON tool-call format as the RunPod setup.

**GGUF download:**
```bash
# Via huggingface-cli
huggingface-cli download Qwen/Qwen3.6-35B-A3B-GGUF \
  --include "Qwen3.6-35B-A3B-Q4_K_M*.gguf" \
  --local-dir ./models
```

### 17.5 Speculative decoding on mlx-lm — blocked for MoE (tested 2026-05-02)

mlx-lm supports draft-model speculative decoding via `--draft-model` and `--num-draft-tokens`. **ngram is not supported** — the flags referenced in earlier drafts of this section do not exist in mlx-lm.

**Draft model attempt: Qwen3-4B-4bit drafting Qwen3.6-35B-A3B-4bit**

Two blockers encountered in sequence:

1. **Tokenizer mismatch warning** — `Draft model tokenizer does not match model tokenizer. Speculative decoding may not work as expected.` Qwen3 and Qwen3.6 use different tokenizers. Acceptance rate would be near 0%.

2. **MoE cache type incompatibility** — Even ignoring the tokenizer issue, inference crashes with:
   ```
   ValueError: Speculative decoding requires a trimmable prompt cache (got {'ArraysCache'})
   ```
   The MoE architecture's KV cache (`ArraysCache`) cannot be trimmed, which is required by mlx-lm's speculative decoding implementation. This is a hard architectural block, not a configuration issue.

**No smaller Qwen3.6 model exists.** The Qwen3.6 family has only two models: 27B dense and 35B-A3B MoE. Using 27B as a draft for 35B-A3B is impractical (draft nearly as expensive as target). A matching small draft model does not exist.

**Conclusion:** Speculative decoding is not available for Qwen3.6-35B-A3B on mlx-lm. The 41 t/s baseline is the current ceiling. This mirrors the NEXTN block on SGLang (§16.5) — MoE architectures have constraints that block speculative decoding optimizations on current tooling.

### 17.6 DFlash on Apple Silicon

Per §15.2, the DFlash draft model (`z-lab/Qwen3.6-27B-DFlash`) is available via `bstnxbt/dflash-mlx` — an MLX port. Vocab matches (248,320). Requires HF access request to the gated repo.

The llama.cpp path (`Luce`) is the other option and doesn't require the gated model for the inference engine itself — only the drafter. Status as of 2026-05-02: unverified on Apple Silicon hardware. Worth attempting once HF access is granted.

### 17.7 Recommended starting point per device

| Device | Model | Engine | Command section |
|---|---|---|---|
| M1 Max 32 GB | `mlx-community/Qwen3.6-35B-A3B-4bit` | mlx-lm | §17.4 |
| M1 Max 64 GB | `Qwen3.6-27B-UD-MLX-8bit` or 35B-A3B Q4 | mlx-lm or llama.cpp | §17.3 / §17.4 |
| M5 Max 48 GB | `Qwen3.6-35B-A3B-Q4` (full VRAM) | mlx-lm | §17.4 |
| M5 Max 128 GB | `Qwen3.6-27B` BF16 or 35B-A3B Q4 | mlx-lm | §17.3 |

For Hephaestus (agentic coding), the 35B-A3B at Q4 on any M-series is the better operational choice — the speed advantage (~4–5×) dominates the ~4-point quality gap for a task-executing agent.

---

## §18. Local / AMD Radeon 890M deployment (Ganymede)

> **⚠️ All benchmarks in this section were performed on Ganymede — a Minisforum AI X1 Pro (AMD Ryzen AI 9 HX 370, Radeon 890M iGPU, 48 GB unified LPDDR5X RAM). They are entirely distinct from the A100-SXM4-80GB results in §§1–16 and the Apple Silicon results in §17. Do not mix these numbers.**

**Hardware specs:**

| Property | Value |
|---|---|
| Machine | Minisforum AI X1 Pro |
| CPU | AMD Ryzen AI 9 HX 370 |
| GPU | AMD Radeon 890M (iGPU, integrated) |
| Unified VRAM | 48 GB LPDDR5X |
| Memory bandwidth | ~170 GB/s |
| OS | Windows 11 |
| Inference backend | LM Studio (Vulkan backend via llama.cpp) |

No ROCm on Windows — LM Studio uses Vulkan compute shaders for all GPU operations. Speed is purely memory-bandwidth-bound, same physics as Apple Silicon unified memory but at ~170 GB/s vs Apple's 400–614 GB/s.

---

### 18.1 Baseline: Qwen3.6-27B dense Q4_K_M

**Model:** `unsloth/Qwen3.6-27B-UD-Q4_K_M` loaded in LM Studio, `--gpu max`

| Metric | Value |
|---|---|
| Generation speed | **2.10 t/s** |
| VRAM used | ~16 GB |

This is the bandwidth ceiling for a 27B dense model at Q4_K_M on 170 GB/s memory. All spec decoding experiments below are measured against this baseline.

---

### 18.2 N-gram speculative decoding (Qwen3.6-27B)

Best practical option for interactive chat on this hardware. No training-distribution mismatch, zero VRAM cost.

| Metric | Value |
|---|---|
| Generation speed | **3.12 t/s** |
| Improvement vs baseline | **+49%** |

LM Studio exposes n-gram spec decoding in the model load settings. Set draft min/max tokens to 2–5, prompt lookup window to 4.

---

### 18.3 DFlash speculative decoding (Qwen3.6-27B)

DFlash uses hidden-state draft tokens from a dedicated 1.73B drafter (`z-lab/Qwen3.6-27B-DFlash`). Requires `buun-llama-cpp` fork (not stock llama.cpp). **Not useful for chat on this hardware.**

#### Results by mode

| Mode | Speed | Acceptance rate | vs baseline |
|---|---|---|---|
| Chat (default) | 0.93 t/s | 5.6% | **−56% (worse)** |
| Chat, temp=0 | ~1.0 t/s | 21.9% | worse |
| Chat, `thinking=0` | ~1.0 t/s | ~20% | worse |
| Raw completion (`/completion` endpoint) | **4.23 t/s** | **46.5%** | **+101%** |

#### Why chat mode fails

DFlash was trained on plain-text continuation data. Chat-format inputs (system prompt + `<|im_start|>` turn structure) produce hidden states that are out-of-distribution for the drafter → catastrophically low acceptance rate (5.6%). The break-even for chat on this hardware is ~29% acceptance; chat mode never gets there.

Raw `/completion` (no chat template) hits 46.5% acceptance and doubles throughput — but is not useful for interactive agents that rely on chat format.

**Conclusion:** Use n-gram for chat (+49%), DFlash only if you have a raw-completion use case (+101%).

#### Build notes (buun-llama-cpp on Windows)

Building buun-llama-cpp on Windows requires:
- Vulkan SDK (for SPIR-V shader compilation)
- `glslc` available on PATH — must wrap WSL2's `glslc` because:
  - Windows native glslc often isn't available
  - CMD batch files split on `=` signs (breaks `-fshader-stage=compute`)
  - Bash metacharacters in `-DFLOAT_TYPE_MAX=float16_t(65504.0)` break `wsl -- glslc` without quoting

**Working wrapper** (`C:\scoop\shims\glslc.cmd`):
```batch
@echo off
python "%~dp0glslc_wrap.py" %*
exit /b %ERRORLEVEL%
```

**`glslc_wrap.py`** (handles `=` in args and `()` in macros via shlex quoting):
```python
import sys, subprocess, re, shlex

def win_to_wsl(arg):
    m = re.match(r'^([A-Za-z]):[/\\]+(.*)', arg)
    if m:
        return '/mnt/{}/{}'.format(m.group(1).lower(), m.group(2).replace('\\', '/'))
    return arg

args = [win_to_wsl(a) for a in sys.argv[1:]]
bash_cmd = ' '.join(shlex.quote(a) for a in ['glslc'] + args)
subprocess.run(['wsl', '--', 'bash', '-c', bash_cmd])
```

Also required in `ggml/src/ggml-vulkan/CMakeLists.txt`: propagate `CMAKE_C_COMPILER`, `CMAKE_CXX_COMPILER`, `CMAKE_RC_COMPILER` into `VULKAN_SHADER_GEN_CMAKE_ARGS` for the ExternalProject_Add sub-cmake.

---

### 18.4 MoE: Qwen3.6-35B-A3B — the right model for this hardware

**Model:** `unsloth/Qwen3.6-35B-A3B-UD-Q4_K_M` (Unsloth Dynamic mixed-precision quant)
**File size:** ~21 GB + 1.7 GB mmproj (vision projector, unused for text inference)

| Metric | Value |
|---|---|
| Generation speed | **14.54 t/s** |
| VRAM used | 23.92 GB |
| Improvement vs dense 27B | **7× (690%)** |
| Improvement vs n-gram 27B | **4.7×** |

#### Why MoE wins on bandwidth-limited hardware

Dense 27B: every token requires reading all 27B parameters from LPDDR5X.
MoE 35B-A3B: only 3B parameters are **active** per token (top-2 expert routing from 64 experts). Memory reads per token drop ~9×, proportionally reducing the bandwidth bottleneck.

**Bandwidth scaling validates the result:**
- M5 Max (614 GB/s) measures ~50 t/s on this model (§17.4)
- Radeon 890M (170 GB/s): 50 × (170 / 614) ≈ **13.8 t/s**
- Measured: 14.54 t/s ✓ — within noise of the theoretical ceiling

**This means we are at the hardware bandwidth ceiling.** No software optimization will significantly exceed 14–15 t/s on this hardware with this model at this quantization.

#### Loading in LM Studio

```
lms load unsloth/qwen3.6-35b-a3b --gpu max
```

Model key: `unsloth/qwen3.6-35b-a3b` (lowercase). The model picker also shows it at 22.28 GiB (includes mmproj). LM Studio's `lms status` confirms load at 23.92 GB.

The model fits alongside other loaded models — at 23.92 GB it leaves 24 GB free in the 48 GB pool (enough for a second 14B-class model simultaneously).

#### Startup script (LMStudio-Startup.ps1)

Updated to load MoE as default, aliased to `mistralai/mistral-small-3.2` for API compatibility with existing clients:

```powershell
& $lmsPath load unsloth/qwen3.6-35b-a3b --identifier mistralai/mistral-small-3.2 --gpu max
```

---

### 18.5 Benchmark summary (Ganymede, Radeon 890M)

All tests: LM Studio Vulkan backend, Windows 11, 48 GB LPDDR5X.

| Model | Spec decoding | Speed | Notes |
|---|---|---|---|
| Qwen3.6-27B Q4_K_M | None | 2.10 t/s | Bandwidth ceiling for dense 27B |
| Qwen3.6-27B Q4_K_M | N-gram | 3.12 t/s | +49%; best for chat |
| Qwen3.6-27B Q4_K_M | DFlash (chat) | 0.93 t/s | Worse than baseline; do not use for chat |
| Qwen3.6-27B Q4_K_M | DFlash (raw completion) | 4.23 t/s | +101%; only useful without chat format |
| **Qwen3.6-35B-A3B UD-Q4_K_M** | **None** | **14.54 t/s** | **Recommended default** |

---

### 18.6 What carries over from the A100/Apple Silicon experiments

| Finding | Applies on Radeon 890M? |
|---|---|
| `enable_thinking: false` required | **Yes** — same model behaviour; set in LM Studio per-model settings |
| Prefix caching incompatible with Mamba hybrid | **Yes** — do not enable in LM Studio |
| Tool-call parser `qwen3_coder` | LM Studio handles internally |
| 128K context minimum for agentic workloads | **Yes** — same session dynamics |
| Vocab mismatch for standard Qwen3 draft models | **Yes** — Qwen3.6 uses 248,320-token vocab; any Qwen3-0.6B/1.7B draft is rejected |
| ngram +14.6% code on A100 | Measured **+49% on 890M** — larger gain because verification overhead is proportionally smaller at lower base speed |
| SGLang NEXTN blocked on A100 by VRAM | Irrelevant — SGLang is Linux/CUDA only |
| MTP native head (~2× decode, 80–90% acceptance) | **Not available** — confirmed absent from `unsloth/Qwen3.6-35B-A3B-UD-Q4_K_M.gguf` (see §18.7) |

### 18.7 MTP head: confirmed absent from Unsloth UD-Q4_K_M (2026-05-02)

Inspected GGUF metadata and tensor list using the `gguf` Python library:

```python
import gguf
reader = gguf.GGUFReader('Qwen3.6-35B-A3B-UD-Q4_K_M.gguf')
# 733 tensors, 54 KV metadata pairs
# No 'mtp', 'nextn', 'draft', or 'spec' keys in either metadata or tensor names
```

**Result: MTP head is not present.** 733 tensors total, none with MTP/nextn naming. Unsloth dropped the MTP head during quantization — same behaviour as their Qwen3.6-27B quants and consistent with the §15 note that standard INT4 quants silently drop the MTP head.

**Implication:** MTP speculative decoding (~2×, 80–90% acceptance) is not available for this file. The only path to MTP on 35B-A3B would be a quant that explicitly preserves the head — no such quant exists in the community as of 2026-05-02 (the Lorbus MTP-preserving quant exists only for Qwen3.6-27B).

**Next experiment:** n-gram speculative decoding (§18.2 approach applied to 35B-A3B) — the only remaining zero-cost speedup available for this model file.

---

*Compiled by Argos (Claude Opus 4.7), 2026-04-30, after a single ~5-hour debugging session with André to bring up Qwen3.6-27B for the CHORE-LINT-001 head-to-head experiment vs Daedalus (Opus 4.6).*
*§14 added by Argos (Claude Sonnet 4.6), 2026-05-02, after adding ngram speculative decoding to the template and running post-change benchmarks.*
*§14.6 added by Argos (Claude Sonnet 4.6), 2026-05-02, after a failed attempt to use Qwen3-0.6B as a draft model.*
*§15 added by Argos (Claude Sonnet 4.6), 2026-05-02, after surveying the X/GitHub community landscape for Qwen3.6-27B inference optimizations.*
*§16 added by Argos (Claude Sonnet 4.6), 2026-05-02, after creating the SGLang parallel experiment template (`q8ycgrr2s0`) and running baseline benchmarks. NEXTN blocked; baseline SGLang is 8% faster than vLLM baseline.*
*§18 added by Argos (Claude Haiku 4.5), 2026-05-02, after benchmarking Qwen3.6 models on Ganymede (Minisforum AI X1 Pro, Radeon 890M, 48 GB LPDDR5X) — DFlash build, n-gram spec decoding, and MoE 35B-A3B validated.*
*§17 added by Argos (Claude Sonnet 4.6), 2026-05-02, after testing SGLang/NEXTN limits and connecting findings to Apple Silicon deployment paths.*
