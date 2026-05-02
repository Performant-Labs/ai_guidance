# MiniMax M2.5 on RunPod (2× A100-SXM4-80GB) — Setup Plan

**Audience:** Performant Labs operator (or AI agent) standing up `MiniMaxAI/MiniMax-M2.5` as an alternative or replacement Heph backend on RunPod.
**Status:** Plan only — *not yet executed.* All Phase 0 verification checks must pass before any pod is launched.
**Prerequisites:** Working knowledge of `qwen3-vllm-runpod-runbook.md` (this doc references its lessons rather than repeating them).
**Estimated total time + cost (clean run):** ~85 min, ~$2 of pod spend.

---

## Why M2.5

Per the runbook's §6.1–§6.2 benchmark positioning, MiniMax M2.5 is the highest-quality OSS coding model that fits on a single self-hostable machine class:

| Property | Value |
|---|---|
| Total / active params | 229 B / 10 B (MoE; 256 experts, top-8 + 1 shared) |
| Context | 192 K native |
| SWE-bench Verified | **80.2** (matches Opus 4.6, beats Qwen3.6-27B by 3 pts) |
| License | OSS (HuggingFace + GitHub) |
| INT4 weight size | ~115 GB (fits 2× A100-80GB with TP=2, ~22 GB KV per GPU) |
| Released | Feb 12, 2026 (mature ecosystem, ~3 months of community quants) |

The pairing **2× A100-SXM4-80GB + M2.5 at INT4** is the sweet-spot deployment: ~$3/hr on RunPod's on-demand market, projected ~150 tokens/sec sustained (~5× the current Heph throughput on Qwen3.6-27B dense at 28.2 t/s with SGLang — see runbook §16.4), and a quality bump on the head-to-head rubric.

---

## TL;DR — the plan in one screen

1. **Phase 0 (no spend):** Verify four unknowns via web fetches — checkpoint format, vLLM model class, tool-call parser, community quantizations.
2. **Phase 1 (no spend):** Clone the existing `Qwen3.6-27BvLLM` template's exact field shape via the RunPod API; swap `name`, `dockerArgs`, `containerDiskInGb`. Save via `saveTemplate` mutation. Verify via GraphQL.
3. **Phase 2 (~$2 spend):** Launch a 2× A100-SXM4 pod from the new template. Verify NVLink active *before* waiting for cold-start. Smoke-test with three curls (`/v1/models`, pong, tool-call).
4. **Phase 3 (no spend):** Capture stats, update runbook §3.3, terminate pod.

If anything fails at any phase, stop and iterate via the API (do not edit templates in the GUI — see §3.1 of the runbook for the API mutation pattern that works).

---

## Phase 0 — Pre-flight verification (no spend, ~30 min)

These checks resolve unknowns *before* committing to a template build. Every check has a clear pass/fail criterion. Skip none.

### 0.1 — Checkpoint format and total file size

```
GET https://huggingface.co/MiniMaxAI/MiniMax-M2.5/raw/main/config.json
GET https://huggingface.co/api/models/MiniMaxAI/MiniMax-M2.5
```

**Read from `config.json`:**

- `architectures` — must include a class registered in vLLM (e.g. `MiniMaxText01ForCausalLM`, `MiniMaxM2ForCausalLM`)
- `torch_dtype` — must be `bfloat16` or `float8_e4m3fn`
- `num_local_experts == 256` and `num_experts_per_tok == 8`

**Read from API model summary:** sum the `siblings[].size` for all `.safetensors` files.

**Pass criteria:**

- Architecture class is recognized (not exotic)
- Total safetensors size ≤ 250 GB

**Fail action:**

- If architecture class is unfamiliar, search vLLM source for support level; if not registered, this template can't be built today.
- If total > 250 GB, raise `containerDiskInGb` to 400 GB in Phase 1; expect 25–35 min download cold-start.

### 0.2 — vLLM model class registration

```
GET https://raw.githubusercontent.com/vllm-project/vllm/main/vllm/model_executor/models/registry.py
```

**Pass criteria:** grep for `MiniMax` in the result. Find the exact model class name and the vLLM version it landed in (look at `git blame` on that line if needed).

**Fail action:**

- If M2.5 is in nightly only, change `/setup.sh` install line to: `pip install vllm --extra-index-url https://wheels.vllm.ai/nightly`
- If M2.5 isn't in any vLLM, consider SGLang as an alternative — it was validated on A100-SXM4-80GB on 2026-05-02 (see `qwen3-vllm-runpod-runbook.md` §16) and is 8% faster than vLLM baseline for Qwen3.6-27B. SGLang's MoE support (`--moe-a2a-backend`, `--ep-size`) may cover M2.5 where vLLM does not.

### 0.3 — Tool-call parser and thinking-mode handling

```
GET https://huggingface.co/MiniMaxAI/MiniMax-M2.5/raw/main/README.md
```

**Read:** look for the "Deployment / vLLM / Usage" section and copy the recommended `vllm serve` command verbatim.

**Pass criteria:** model card explicitly recommends a `--tool-call-parser` value (e.g. `minimax_m2`, `hermes`) and clarifies whether to set `--reasoning-parser` and `--default-chat-template-kwargs` for thinking-mode control.

**Fail action:** if the model card has no vLLM section, default to `--tool-call-parser hermes` (used by M2) and no reasoning-parser. Document this as a "best-effort guess" in the template's `readme` field. Phase 2.4's tool-call smoke test will validate.

### 0.4 — Community quantizations available

```
GET https://huggingface.co/api/models?author=unsloth&search=MiniMax-M2.5
GET https://huggingface.co/api/models?author=bartowski&search=MiniMax-M2.5
```

**Pass criteria:** if either author has an AWQ / GPTQ / INT4 variant, prefer that as the `--model` argument. Smaller download (~115 GB vs ~229 GB), faster startup, and avoids relying on vLLM's runtime quantization.

**Fail action:** if no community quants exist, use the native checkpoint and add `--quantization awq` or `--quantization bitsandbytes` to the vLLM args (slower startup; expect +5 min). Note in `readme` that future operators should switch to a community quant when one ships.

### 0.5 — Token and API health

```bash
curl -sS -H "Authorization: Bearer $RUNPOD_API_TOKEN" \
  https://rest.runpod.io/v1/templates/qaqvwnwdc6 | jq -r '.name'
# Pass: prints "Qwen3.6-27BvLLM"

curl -sS -H "Authorization: Bearer $HF_TOKEN" \
  https://huggingface.co/api/whoami | jq -r '.name'
# Pass: prints user name (not 401)
```

**Fail action:** rotate or refresh tokens in `~/.env.local` and reload shell before proceeding.

---

## Phase 1 — Build the template (~15 min, no GPU spend)

Only proceed if all Phase 0 checks pass. If a check failed gracefully, document the workaround in the template's `readme` field so the next operator knows.

### 1.1 — Pull existing Qwen template's exact field shape

```
GET https://rest.runpod.io/v1/templates/qaqvwnwdc6
```

Capture the JSON response. This is the known-good shape — every field except the four below is mirrored unchanged.

**Fields to mirror unchanged from Qwen template:**

- `imageName`
- `volumeInGb`
- `volumeMountPath`
- `env` (carries `HUGGING_FACE_HUB_TOKEN`)
- `category`
- `containerRegistryAuthId`
- `startSsh`
- `startJupyter`
- `isPublic`
- `isServerless`

### 1.2 — Construct the new `/setup.sh`

Filling in values verified in Phase 0:

```bash
#!/bin/bash
set -e
export HF_HOME=/root/.cache/huggingface
export VLLM_CACHE_ROOT=/workspace/vllm_cache
mkdir -p "$VLLM_CACHE_ROOT"

echo '=== NVLink sanity check ==='
if ! nvidia-smi nvlink -s 2>/dev/null | grep -q 'Active'; then
  echo "WARNING: NVLink not active. Tensor parallelism will be PCIe-bound."
  echo "Verify pod is A100-SXM4-80GB, not A100-PCIe-80GB."
fi

echo '=== Detecting GPU count ==='
GPU_COUNT=$(nvidia-smi -L | wc -l)
echo "GPUs detected: $GPU_COUNT"
if [ "$GPU_COUNT" -lt 2 ]; then
  echo "ERROR: M2.5 requires at least 2 GPUs. Got $GPU_COUNT."
  exit 1
fi

echo '=== Installing vLLM ==='
python -m pip install --quiet 'vllm<0.20' \
  --extra-index-url https://download.pytorch.org/whl/cu128 \
  || python -m pip install --quiet 'vllm<0.15' \
  --extra-index-url https://download.pytorch.org/whl/cu128
python -c "import vllm; print('vllm', vllm.__version__)"

echo '=== Starting vLLM ==='
python -m vllm.entrypoints.openai.api_server \
  --model <VERIFIED_MODEL_ID> \
  --host 0.0.0.0 --port 8000 \
  --tensor-parallel-size "$GPU_COUNT" \
  --dtype auto \
  --max-model-len 131072 \
  --enable-auto-tool-choice \
  --tool-call-parser <VERIFIED_PARSER> \
  <OPTIONAL --reasoning-parser X> \
  <OPTIONAL --quantization X> \
  --api-key sk-1234567890 \
  > /vllm.log 2>&1 &

echo 'Container is now persistent.'
tail -f /vllm.log
```

Replace `<VERIFIED_*>` and `<OPTIONAL ...>` placeholders with values confirmed in Phase 0.

### 1.3 — Base64-encode and embed in template `dockerArgs`

```bash
B64=$(printf '%s' "$NEW_SETUP" | base64 | tr -d '\n')
NEW_DOCKER_ARGS="bash -c \"echo $B64 | base64 -d > /setup.sh && chmod +x /setup.sh && /setup.sh\""
```

### 1.4 — Call `saveTemplate` mutation

The same envelope used in the runbook §3.1, but with these field-value differences:

| Field | Qwen template | M2.5 template |
|---|---|---|
| `id` | (omit — creates new template) |  |
| `name` | `Qwen3.6-27BvLLM` | `MiniMax-M2.5-vLLM` |
| `containerDiskInGb` | 150 | **300** (or 400 if 0.1 said checkpoint > 250 GB) |
| `ports` | `8000/tcp,22/tcp` | `8000/tcp,22/tcp` (unchanged — TCP lesson applies) |
| `dockerArgs` | (Qwen base64 wrapper) | (M2.5 base64 wrapper from 1.3) |
| `readme` | (empty) | (Phase 0 caveats noted here) |

**Pass criteria:** mutation returns HTTP 200 with `data.saveTemplate.id` populated. Capture this new ID — needed for verification and pod-launch.

### 1.5 — Verify the saved template

```
POST https://api.runpod.io/graphql
query { podTemplate(id: <NEW_ID>) { dockerArgs containerDiskInGb name } }
```

Decode the embedded base64 in `dockerArgs`. Verify the decoded `/setup.sh` contains:

- The verified `--tool-call-parser` from Phase 0.3
- The verified `--model <ID>` from Phase 0.4 (community quant ID if found, else native)
- `--tensor-parallel-size "$GPU_COUNT"` (literal string, will expand at runtime)
- The NVLink check block

**Fail action:** if any expected substring is missing, the saved version isn't what was intended. Re-run 1.3 and 1.4 with corrected values; verify again before any pod launch.

---

## Phase 2 — Pod launch + smoke test (~30 min, ~$2 spend)

Only proceed if Phase 1 verification is clean.

### 2.1 — Launch a 2× A100-SXM4 pod from the new template

**Manual on operator's end:**

1. RunPod console → Templates → find `MiniMax-M2.5-vLLM`
2. Click "Deploy"
3. **CRITICAL: select GPU type "A100 SXM4-80GB"** (or "A100 80GB SXM"). **Do NOT select "A100 80GB PCIe."** PCIe-only A100s have ~32 GB/s GPU↔GPU bandwidth vs SXM4's ~600 GB/s NVLink — TP=2 on PCIe will be ~30× slower for prefill.
4. Set GPU count = 2
5. Confirm datacenter has SXM4 inventory; if "Out of Stock," try a different DC before falling back to a different GPU type
6. Click "Deploy On-Demand"
7. Capture the new pod ID

### 2.2 — Bridge: confirm SXM4 + NVLink *before* waiting for cold start

Don't waste ~25 min of cold-start time on a misconfigured pod. SSH in immediately and verify:

```bash
nvidia-smi -L
# Expect: "GPU 0: NVIDIA A100-SXM4-80GB" (× 2)
# REJECT: "A100-PCIE-80GB" or anything else

nvidia-smi nvlink -s | head -20
# Expect: "Active" status on links
# REJECT: any "Inactive" or empty output

nvidia-smi topo -m
# Expect: "NV12" or similar between GPU 0 and GPU 1
# REJECT: "PIX" or "PHB" (PCIe-only paths)
```

**Pass criteria:** all three outputs confirm NVLink is active between the two GPUs.

**Fail action:** terminate the pod immediately, document, retry pod launch with explicit SXM4 selection. Do not wait for cold-start on a PCIe pod.

### 2.3 — Wait for vLLM cold start (~15–25 min)

Bridge progress check periodically:

```bash
ssh <pod> 'pgrep -fa "^python.*vllm.entrypoints" | head -1; ss -tlnp | grep :8000; tail -n 5 /vllm.log'
```

Expected progression:

| Phase | Wall-clock | What to see |
|---|---|---|
| pip install vllm | ~3–5 min | install logs in /vllm.log? actually pip output goes to stdout of /setup.sh; check `ps -eo etime,cmd \| grep pip` |
| Model download | ~10–15 min | `du -sh /root/.cache/huggingface` grows toward ~115–229 GB |
| Engine init / cudagraph | ~3 min | `INFO ... Loading weights took N seconds` then `init engine took N seconds` |
| Application startup | ~30 sec | `Application startup complete.` in /vllm.log; port 8000 starts listening |

**Fail criteria during cold start:**

- `Engine core initialization failed` → grep `/vllm.log` for actual error (often hundreds of lines back; `head -200 /vllm.log` and look for `ERROR` / `Exception` / `Traceback`)
- OOM during weight load → checkpoint bigger than expected; rebuild template with larger disk and/or different quantization
- `unrecognized arguments: --tool-call-parser X` → flag isn't supported by this vLLM version; iterate template

### 2.4 — Smoke test from the bridge

Three escalating tests, ordered by capability tested:

**Test 1 — `/v1/models` returns 200:**

```bash
curl -sS -H "Authorization: Bearer sk-1234567890" \
  http://<pod-ip>:<dynamic-port>/v1/models
```

Expect HTTP 200 with the model ID listed.

**Test 2 — Pong (no thinking-mode):**

```bash
curl -X POST http://<pod-ip>:<port>/v1/chat/completions \
  -H "Authorization: Bearer sk-1234567890" \
  -H "Content-Type: application/json" \
  -d '{"model":"MiniMaxAI/MiniMax-M2.5",
        "messages":[{"role":"user","content":"reply pong"}],
        "max_tokens":10,"temperature":0}'
```

Expect: `content: "pong"`, `completion_tokens: 1–3`, `finish_reason: "stop"`. If completion_tokens > 10 or content is empty with reasoning_content populated, thinking-mode is leaking — adjust `--default-chat-template-kwargs`.

**Test 3 — Tool-call parser actually works:**

```bash
curl -X POST http://<pod-ip>:<port>/v1/chat/completions \
  -H "Authorization: Bearer sk-1234567890" \
  -H "Content-Type: application/json" \
  -d '{"model":"MiniMaxAI/MiniMax-M2.5",
        "messages":[{"role":"user","content":"What is 2+2? Use the calculate tool."}],
        "tools":[{"type":"function","function":{"name":"calculate","parameters":{"type":"object","properties":{"expression":{"type":"string"}}}}}],
        "max_tokens":50,"temperature":0}'
```

Expect: response has `tool_calls` array with a `calculate` function call, *not* a raw text string mentioning the tool. If it's text-only, `--tool-call-parser` is wrong.

### 2.5 — Speed validation

Generate ~300 tokens to validate sustained decode throughput vs Heph baseline:

```bash
T0=$(date +%s.%N)
curl -sS -X POST http://<pod-ip>:<port>/v1/chat/completions \
  -H "Authorization: Bearer sk-1234567890" \
  -H "Content-Type: application/json" \
  -d '{"model":"MiniMaxAI/MiniMax-M2.5",
        "messages":[{"role":"user","content":"Count from 1 to 100 in English, comma separated."}],
        "max_tokens":300,"temperature":0}'
T1=$(date +%s.%N)
echo "Wall clock: $(awk -v a=$T0 -v b=$T1 'BEGIN{printf "%.2f",b-a}')s"
```

**Pass criteria:**

- Sustained generation > 80 t/s real (300 tokens in < 4 sec). M2.5 should comfortably exceed Heph's 27 t/s peak.
- Time-to-first-token < 1 sec.

**Fail action:** if sustained < 30 t/s, NVLink isn't being used effectively or model is in a slow path. Bridge a deeper diag (`nvidia-smi topo -m` again, check vLLM logs for "Using FLASH_ATTN" vs "Using XFORMERS" backend).

---

## Phase 3 — Sign-off and runbook update (~10 min, no spend)

Only proceed if Phase 2 passes.

### 3.1 — Capture stats

Same template as the post-CTRF-003 stats query in the runbook §10. Document in a new sub-section:

- vLLM version actually loaded
- Model checkpoint precision (FP8 / INT4)
- Sustained generation t/s
- Peak generation t/s
- Time to first token (median)
- VRAM used per GPU
- Power draw per GPU during decode
- KV cache usage at typical 32K-token context

### 3.2 — Update the runbook

Add new sub-section in `qwen3-vllm-runpod-runbook.md`:

**§3.3 Alternative templates** containing:

- Template name (`MiniMax-M2.5-vLLM`)
- Template ID (captured from Phase 1.4)
- GPU requirements (2× A100-SXM4-80GB minimum)
- Verified vLLM args
- Phase 2 smoke test results
- Cost per hour
- Known caveats (community quant version, parser names, etc.)
- Forward links to this plan doc

### 3.3 — Decide on terminate vs keep

Same as the Heph experiment cleanup:

- **Stopped pod** still costs ~$0.50/day in storage. Acceptable if relaunching within 1–2 days.
- **Terminate** if not relaunching within ~3 days; future cold-starts will redo download but cost less than storage drag.

---

## Risk register

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| M2.5 not in vLLM stable (only nightly) | Medium | Need nightly install line | Phase 0.2 catches it, install line adjusts |
| Native checkpoint > 250 GB | Low–Medium | Won't fit 2× A100 split | Phase 0.1 catches it, switch to community AWQ or scale to 4× A100 |
| RunPod assigns A100-PCIe instead of SXM4 | Low | TP performance degraded ~30× | Phase 2.2 catches before cold-start spend |
| Tool-call parser flag wrong | Medium | Tool calls return as raw text | Phase 2.4 Test 3 catches; iterate template via API |
| Disk too small (cold start fails) | Low | Pod stuck during weight download | Phase 0.1 sizing + Phase 1 disk choice |
| Cloudflare-style network timeouts | Very Low | Already fixed via TCP port mapping | Template uses `8000/tcp` by default |
| HF token gated-access issue | Very Low | Download fails with 401 | M2.5 is not gated; still verify in Phase 0.5 |
| MoE expert routing path requires EP not TP | Medium | Sub-optimal performance | Phase 2.5 speed test catches; fall back to `-dp 2 --enable-expert-parallel` if TP=2 sustained < 30 t/s |

---

## Total time and cost estimate (clean run)

| Phase | Time | Cost |
|---|---|---|
| 0 — Verify | ~30 min | $0 |
| 1 — Build template | ~15 min | $0 |
| 2 — Pod launch + smoke | ~30 min wall-clock | ~$2 (2× A100 × 30 min × $1.49/hr × 2 GPUs ÷ 60) |
| 3 — Document | ~10 min | $0 (after pod terminated) |
| **Total** | **~85 min** | **~$2** |

If Phase 0 surfaces unknowns that can't be resolved from web fetches alone, total stretches to ~2 hours and ~$5 (one extra cold-start cycle to validate via runtime trial-and-error).

---

## References

- `~/Sites/ai_guidance/agent/qwen3-vllm-runpod-runbook.md` — full Qwen runbook with API mutation pattern (§3.1), TCP port-mapping rationale (§4-K), benchmark positioning (§6.1), Mac sizing analysis (§6.2)
- `~/Projects/ctrfhub/.claude-bridge/req-argos-runpod-template-update-v6.sh` — reference saveTemplate mutation script (working envelope; new-template version omits `id` field)
- vLLM official recipes: https://github.com/vllm-project/recipes (no V4 entry yet; M2.5 may have one — check in Phase 0.2)
- MiniMax M2.5 model card: https://huggingface.co/MiniMaxAI/MiniMax-M2.5
- DeepSeek V3.2 vLLM recipe (closest published recipe with similar arch patterns): https://github.com/vllm-project/recipes/blob/main/DeepSeek/DeepSeek-V3_2.md

---

*Drafted by Argos, 2026-05-01. Plan only — execution pending operator sign-off after Phase 0 verification.*
