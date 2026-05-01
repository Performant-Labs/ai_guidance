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
  --max-model-len 65536 \
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
- `--max-model-len 65536` — Qwen3.6 supports 262K natively but vLLM allocates KV cache against this value, so set it to what you actually need. **64K is the practical floor for an agentic coding workload** (Roo Code's prompt — system + agents.md + role md + brief + multi-file reads + tool history — easily exceeds 32K). On A100-80GB with 27B bf16, 64K KV cache uses ~12 GB, comfortable; 128K uses ~24 GB, right at the edge of what fits alongside the 55 GB model. KV cache per token ≈ 192 KB (48 layers × 8 KV heads × 128 dim × 2 bytes × 2 for K+V).

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
  --max-model-len 65536 \
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

**Fix.** Bump `--max-model-len`. **64K (`65536`) is the practical floor.** Memory budget on A100-80GB:

| `--max-model-len` | KV cache | Total VRAM (model + KV) | Headroom |
|---|---|---|---|
| 32768 | ~6 GB | ~61 GB | comfortable, but too small for agents |
| 65536 | ~12 GB | ~67 GB | comfortable; recommended default |
| 131072 | ~24 GB | ~79 GB | right at 80 GB ceiling |
| 262144 (native) | ~48 GB | doesn't fit | OOM |

KV cache size per token ≈ `2 × num_layers × num_kv_heads × head_dim × dtype_bytes` ≈ 192 KB for Qwen3.6-27B at bf16. Multiply by `max-model-len` for total. (Mamba/GDN state is fixed-size — doesn't scale with seq_len.)

**Confirmation.** vLLM's startup log line: `Using max model len 65536`. Roo Code's prompt should now fit; if it still errors at 65536, bump to 96K/128K.

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

The official vLLM recipe at https://github.com/vllm-project/recipes/blob/main/Qwen/Qwen3.5.md covers **Qwen3.5** (397B-A17B MoE) and **Qwen3.6** (35B-A3B MoE) — the bigger, MoE-architecture cousins. There is **no Qwen3.6-27B.md** recipe. The 27B variant exists in the official Qwen HuggingFace org (created 2026-04-21, ~770K downloads as of 2026-04-30) and shares the architecture (`Qwen3_5ForConditionalGeneration`, multimodal, Mamba+GDN delta), but it is *not* in the official recipe table.

Implications:

- The recipe's deployment patterns (`-dp 8 --enable-expert-parallel`, `--mm-encoder-tp-mode data`, etc.) are for the multi-GPU MoE variants. **Don't apply them to the 27B dense.** Single-GPU TP=1 is correct.
- The recipe's known-error table mentions a Mamba+cudagraph capture-size crash with a workaround (`--max-cudagraph-capture-size 256`). If you ever see `causal_conv1d_update assert num_cache_lines >= batch`, that's the fix.
- vLLM 0.19.1 may have specific bugs on this less-tested arch. The `--enable-prefix-caching` issue (§4-B) is one. Watch for more in newer vLLM versions; the `<0.20` pin in §1 is conservative.

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

## 10. Forward links

- Memory entry `runpod_qwen3_vllm_recipe.md` — short-form recipe summary, kept terse for context-window efficiency in future Argos sessions.
- `~/Projects/ctrfhub/.claude-bridge/` — full history of bridge scripts that produced this runbook (v1–v8 of various probes, all preserved for archaeology).
- `~/Sites/ai_guidance/agent/claude-bridge.md` — bridge architecture reference.
- `~/Sites/ai_guidance/agent/troubleshooting.md` — sibling troubleshooting doc for the broader Performant Labs agent stack.
- vLLM Qwen3.5/3.6 official recipe: https://github.com/vllm-project/recipes/blob/main/Qwen/Qwen3.5.md

---

*Compiled by Argos (Claude Opus 4.7), 2026-04-30, after a single ~5-hour debugging session with André to bring up Qwen3.6-27B for the CHORE-LINT-001 head-to-head experiment vs Daedalus (Opus 4.6).*
