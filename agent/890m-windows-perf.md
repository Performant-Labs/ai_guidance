# 890M Windows Performance — Qwen3.6-35B-A3B Q4_K_M

**Date:** 2026-05-04  
**Status:** validated end-to-end on AMD Radeon 890M iGPU, Windows 11 + WSL2, LM Studio

---

## Hardware & stack

| Component | Value |
|---|---|
| GPU | AMD Radeon 890M (RDNA 3.5 iGPU) |
| VRAM allocation | 48 GB (max possible from 96 GB system RAM) |
| System RAM | 96 GB LPDDR5x |
| Est. memory bandwidth | ~120 GB/s (LPDDR5x dual-channel) |
| OS | Windows 11 |
| Inference stack | LM Studio CLI — `lms server start` / `llmster.exe` daemon (headless, no GUI) |
| Model | `unsloth/qwen3.6-35b-a3b` |
| Quantization | Q4_K_M (GGUF) |
| Architecture | `qwen35moe` (MoE: 35B total / 3B active) |
| Loaded context | 65,536 tokens |
| Max context | 262,144 tokens |

---

## Stack architecture

### How LM Studio runs on this machine

LM Studio on Windows has two distinct runtime modes. This matters for GPU verification and lifecycle management.

| Component | Process | Role |
|---|---|---|
| `llmster.exe` | PID (varies) | Headless backend daemon — manages model loading, serves port 1234 |
| `node.exe` ×2 | PIDs (varies) | Inference workers — hold GPU memory, execute Vulkan compute |
| `LM Studio.exe` | Not running | Full Electron GUI — optional, connects to `llmster` if launched |
| `lms.exe` | Not resident | CLI tool — used to start/stop `llmster`, exits after launching daemon |

At time of benchmark, the stack was **headless** (`lms server start` mode — no GUI open). The two `node.exe` workers held ~24.9 GB + ~21.6 GB = **46.5 GB of GPU local memory** between them.

### Recommended workflow going forward

**Use the LM Studio GUI** (`LM Studio.exe`) as the primary way to start and stop the server on this machine. The GUI:
- Manages `llmster` as a child process with a valid passkey
- Provides clean shutdown (no orphaned daemon)
- Exposes the same port 1234 API for WSL/benchmarking

The `lms` CLI is for headless Linux servers. On a Windows desktop with the GUI available, using `lms` creates an orphan risk (see `troubleshooting.md` §30).

### GPU verification

Confirmed the 890M was used during benchmarks via Windows performance counters:

| Signal | Observed value | Meaning |
|---|---|---|
| GPU compute engine utilization | **96.2%** (during inference) | Vulkan compute shaders saturated |
| GPU local memory (2× node workers) | 24.9 + 21.6 = **46.5 GB** | Model loaded into iGPU VRAM |
| Physical GPUs present | **1** (`phys_0` only) | No discrete GPU — 890M is the only device |
| Engine type active | `engtype_compute` | Vulkan compute path, not display/3D |

Command to verify during a future run:
```powershell
# Fire an inference request in background, then sample while it runs:
Get-Counter '\GPU Engine(*engtype_compute*)\Utilization Percentage' -SampleInterval 1 -MaxSamples 3 |
    Select-Object -ExpandProperty CounterSamples |
    Where-Object { $_.CookedValue -gt 5 } |
    Select-Object InstanceName, CookedValue
```

---

## Benchmark results

### Test A — Time to first token (warm)

| Metric | Value |
|---|---|
| Wall-clock (model warm) | **0.87s** |
| Prompt tokens | 12 |
| Finish reason | length (5-token cap) |

Model was pre-loaded; cold-start (loading from disk) observed at ~41s on first access.

---

### Test B — Sustained generation (3,000 tokens)

**Prompt:** Detailed technical explanation of attention mechanisms in transformers (43 prompt tokens).

| Metric | Value |
|---|---|
| Wall-clock | 165.1s |
| Total tokens generated | 3,000 |
| — Thinking tokens | 1,276 (42.5%) |
| — Output tokens | 1,724 (57.5%) |
| **Throughput (all tokens)** | **18.2 t/s** |
| Throughput (output only) | 10.4 t/s |
| Finish reason | length (hit cap) |
| Prompt prefill throughput | not separately measured |

---

### Test C — Coding task (TypeScript refactor, CHORE-LINT-001 profile)

**Task:** Eliminate `as any` casts in a Fastify route handler by adding proper TypeScript types.  
**Method:** Assistant prefill past `</think>` block to measure output-phase throughput directly.

| Metric | Value |
|---|---|
| Wall-clock | 13.7s |
| Output tokens | 228 |
| Thinking tokens | 0 (prefill bypass) |
| **Throughput (output)** | **16.7 t/s** |
| Finish reason | **stop** ✅ |

**Output quality:** Model correctly introduced `DbClient` and `UserBody` interfaces, used
`FastifyInstance & { db: DbClient }` augmentation, and `FastifyRequest<{ Body: UserBody }>`
generics — zero `as any` casts remaining. Equivalent to Heph's CHORE-LINT-001 output quality.

---

## Thinking-mode behaviour

The unsloth Q4_K_M GGUF has thinking enabled by default in its chat template. `/no_think`
prefix and `"thinking": {"type": "disabled"}` API parameter had no effect. Thinking token
budget scales heavily with task complexity:

| Task type | Thinking tokens before output |
|---|---|
| Short explanation (Test B) | ~1,276 tokens |
| Coding task (Test C) | >4,000 tokens (budget exceeded at 4k cap) |

**Practical implication:** For agentic use, either (a) set `max_tokens` ≥ 6,000+ per call,
or (b) use assistant prefill to skip thinking. Option (b) gives cleaner latency but bypasses
the model's reasoning; option (a) is more faithful to how Heph was run on RunPod.

---

## Speculative decoding results — Dense 27B + 1.7B draft

**Date:** 2026-05-04  
**Stack:** llama-server b9033 (Vulkan), standalone (no LM Studio)  
**Target model:** `qwen/qwen3.6-27b` Q4_K_M (dense, 27B params)  
**Draft model:** `qwen/qwen3-1.7b` Q8_0  
**Thinking:** Disabled via `LLAMA_CHAT_TEMPLATE_KWARGS={"enable_thinking":false}`  
**Port:** 8080

### Test A — Time to first token (warm, spec-dec)

| Metric | Value |
|---|---|
| Wall-clock | 2.05s |
| Throughput | 4.0 t/s |
| Draft acceptance | 1/1 (100%) |
| Finish reason | length (5-token cap) |

### Test B — Sustained generation (600 tokens, spec-dec)

**Prompt:** Same attention-mechanisms prompt as MoE Test B (43 prompt tokens).  
Token cap reduced to 600 (from 3,000) to keep wall-clock reasonable on the slower dense model.

| Metric | Value |
|---|---|
| Wall-clock | 132.0s |
| Total tokens generated | 600 |
| **Throughput** | **4.5–4.6 t/s** |
| Draft acceptance | 430/687 (**63%**) |
| Finish reason | length (hit cap) |

### Test C — Coding task (TypeScript refactor, spec-dec)

**Task:** Same CHORE-LINT-001 task as MoE Test C.

| Metric | Value |
|---|---|
| Wall-clock | 44.9s |
| Output tokens | 305 |
| **Throughput** | **6.1–6.8 t/s** |
| Draft acceptance | 238/362 (**66%**) |
| Finish reason | **stop** ✅ |

**Output quality:** Correct — equivalent to MoE Test C output.

### Speculative decoding analysis

The dense 27B + 1.7B draft achieves **4.5–6.8 t/s** on the 890M, roughly **3–4× slower** than
the MoE baseline (18.2 t/s). This confirms the bandwidth bottleneck: the dense 27B must read
all 27B parameters per token, while the MoE reads only ~3B active parameters. On ~120 GB/s
LPDDR5x, the dense model is fundamentally memory-bandwidth-limited.

Draft acceptance at 63–66% is reasonable for a generic 1.7B drafter. The purpose-built DFlash
draft models (`dflash-draft-3.6-q4_k_m.gguf`, `dflash-draft-3.6-q8_0.gguf`) should achieve
higher acceptance rates (80%+), potentially pushing throughput to 8–10 t/s — still well below
the MoE path.

**Conclusion:** On bandwidth-limited hardware like the 890M, the MoE architecture (Qwen3.6-35B-A3B)
is the clear winner. Speculative decoding helps the dense model but cannot overcome the
fundamental bandwidth gap.

---

## Comparison — 890M vs runbook reference points

| Setup | Model | Throughput | Notes |
|---|---|---|---|
| **890M MoE** | Qwen3.6-35B-A3B MoE Q4_K_M | **18.2 t/s** (total) / **16.7 t/s** (output) | 48 GB VRAM, Vulkan, LM Studio |
| **890M Dense+SpecDec** | Qwen3.6-27B dense Q4_K_M + 1.7B Q8_0 draft | **4.5–6.8 t/s** | Vulkan, llama-server b9033, 63–66% acceptance |
| A100-SXM4-80GB (RunPod) | Qwen3.6-27B dense bf16 | 12.2 t/s mean / 27.9 t/s peak | vLLM 0.19.1, §10 runbook |
| M5 Max (projected) | Qwen3.6-35B-A3B MoE | ~50 t/s | From §6.2 runbook, not tested |
| M5 Ultra (projected) | Qwen3.6-35B-A3B MoE | ~80 t/s | From §6.2 runbook, not tested |

**Key findings:**

1. **MoE wins on bandwidth-limited hardware.** The 890M at 18.2 t/s with MoE *exceeds* the
   A100's 12.2 t/s mean on the comparable dense workload. The MoE architecture (3B active
   params) reduces effective memory bandwidth demand ~9× vs the dense 27B, so the 890M's
   lower bandwidth (~120 GB/s vs ~2 TB/s on A100) is largely compensated.

2. **Speculative decoding cannot close the gap.** Dense 27B + spec-dec on the 890M achieves
   only 4.5–6.8 t/s — a 3–4× penalty vs MoE. Even with perfect draft acceptance, the dense
   model must still verify all 27B parameters, saturating memory bandwidth.

3. **Recommendation:** Use the MoE model (`qwen3.6-35b-a3b` Q4_K_M) for all local inference
   on the 890M. The dense 27B path is only worth exploring on hardware with ≥400 GB/s
   bandwidth (Apple M-series, discrete GPUs).

---

## Models available in LM Studio (inventory at time of test)

| Model ID | Quant | Arch | State |
|---|---|---|---|
| `unsloth/qwen3.6-35b-a3b` | Q4_K_M | qwen35moe | loaded ✅ |
| `qwen/qwen3.6-35b-a3b` | Q4_K_M | qwen35moe | loaded ✅ |
| `qwen/qwen3.6-27b` | Q4_K_M | qwen35 (dense VLM) | not-loaded |
| `qwen3.6-27b-dflash@q4_k_m` | Q4_K_M | dflash-draft | not-loaded ⚠️ |
| `qwen3.6-27b-dflash@q8_0` | Q8_0 | dflash-draft | not-loaded ⚠️ |

⚠️ `dflash-draft` models failed to load — arch requires a paired draft model file that
appears to be missing. Do not use until the draft model is co-located.

---

## Follow-on experiments

- [x] **Dense + speculative decoding:** Qwen3.6-27B Q4_K_M + Qwen3-1.7B Q8_0 draft — **4.5–6.8 t/s**, 63–66% acceptance. Confirmed MoE superiority. *(2026-05-04)*
- [ ] **DFlash draft models:** swap generic 1.7B drafter for `dflash-draft-3.6-q8_0.gguf` — expect 80%+ acceptance, ~8–10 t/s. Still below MoE but worth validating the ceiling.
- [ ] **Q8_0 MoE:** `qwen/qwen3.6-35b-a3b` Q8_0 if available — higher fidelity, likely ~10-13 t/s (35 GB in 48 GB VRAM)
- [ ] **Thinking-disable:** find a GGUF build or LM Studio setting that respects `/no_think` for lower latency-per-call
- [ ] **Roo Code integration:** wire `unsloth/qwen3.6-35b-a3b` as local Heph endpoint in Roo Code, run a real chore brief end-to-end
- [ ] **Podman/Ollama path:** validate WSL2 `/dev/dri` passthrough for containerised server mode
