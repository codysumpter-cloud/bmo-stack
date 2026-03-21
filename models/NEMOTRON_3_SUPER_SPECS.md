# Nemotron 3 Super 120B Model Specifications

## Overview
Nemotron 3 Super is a family of large language models created by NVIDIA. The 120B variant is part of the Nemotron 3 Super series designed for high-performance language understanding and generation.

## Technical Specifications
- **Parameters**: 120 billion
- **Architecture**: Transformer-based decoder-only
- **Context Length**: 32,768 tokens (32k)
- **Vocabulary Size**: 256,000 tokens (based on Nemotron 3 tokenizer)
- **Training Data**: Multilingual corpus including English, Spanish, German, French, Italian, Portuguese, Dutch, Russian, Chinese, Japanese, Korean, Arabic, and others
- **Precision**: Available in BF16 (BFLOAT16) and FP8 formats
- **Model Type**: Instruction-tuned variant available for chat/completion tasks

## Capabilities
- Strong performance on multilingual understanding and generation
- Extended context handling for long-form documents
- Function calling and tool use capabilities
- Code generation across multiple programming languages
- Mathematical reasoning and problem solving
- Structured output generation (JSON, XML, etc.)

## Hardware Requirements (for inference)
- **VRAM**: Approximately 240GB+ for BF16 full precision (120B * 2 bytes = 240GB)
  - With quantization (INT4/INT8): 60-120GB VRAM
  - With FP8: ~120GB VRAM
  - With 4-bit quantization: ~30-60GB VRAM
- **System RAM**: 256GB+ recommended for comfortable operation
- **Storage**: 250GB+ for model files and dependencies
- **Recommended GPUs**: 
  - 2x NVIDIA H100 80GB (NVLink) for FP16/BF16
  - 4x NVIDIA A100 40GB or 80GB for quantized inference
  - Single GPU inference possible with aggressive quantization and offloading

## Software Compatibility
- **Primary**: NVIDIA TensorRT-LLM, vLLM, Hugging Face Transformers
- **Alternative**: Ollama (with appropriate quantization), llama.cpp, text-generation-inference
- **Frameworks**: PyTorch, JAX, TensorFlow (via Transformers)

## Licensing
- NVIDIA Nemotron 3 Super models are available under the NVIDIA Open Model License
- Permits commercial use, research, and modification
- Requires attribution and adherence to license terms

## Usage Notes for BMO/OmniAPI
1. **Quantization Recommended**: For local deployment, use 4-bit or 8-bit quantization to reduce VRAM requirements
2. **Context Management**: Leverage the 32k context for long conversations and document processing
3. **Instruction Following**: The instruction-tuned variant performs best with clear, structured prompts
4. **Tool Use**: Capable of parsing and executing tool/function calls in JSON format
5. **Multilingual**: Can handle conversations in multiple languages without explicit language switching

## Acquisition
- Available via Hugging Face: `nvidia/nemotron-3-super-120b`
- Requires accepting license terms on HF
- May require NVIDIA AI Enterprise account for direct download from NVIDIA NGC
- Alternative sources: Local training from base model if available

## Verification
To verify model integrity after download:
```bash
# Check file sizes and structure
ls -lh models/nemotron-3-super-base/
# Validate configuration
cat models/nemotron-3-super-base/config.json
# Test basic inference (when server is set up)
```

## Next Steps for Local Deployment
1. Download model files to `/home/prismtek/bmo-context/models/nemotron-3-super-base/`
2. Set up local inference server (vLLM, TensorRT-LLM, or Ollama-compatible wrapper)
3. Convert to desired quantization format (GGUF for llama.cpp, AWQ, GPTQ, etc.)
4. Verify basic chat functionality
5. Integrate with omniAPI adapter layer