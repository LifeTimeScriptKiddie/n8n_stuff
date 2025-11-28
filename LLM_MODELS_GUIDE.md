# LLM Models Guide

This guide explains how to configure and manage local language models for the n8n reconnaissance hub using Ollama.

## Quick Start

### 1. Choose a Model Profile

Edit your `.env` file and set the `LLM_MODEL_PROFILE` variable:

```bash
# Options: minimal, efficient, standard, full, custom
LLM_MODEL_PROFILE=efficient
```

### 2. Run Setup

The setup script will automatically pull models based on your chosen profile:

```bash
./setup.sh
```

### 3. Manage Models

Use the model management script for ongoing model management:

```bash
./manage-models.sh list                    # List installed models
./manage-models.sh pull-profile efficient  # Pull efficient profile
./manage-models.sh info                    # Show detailed model info
```

---

## Model Profiles

### Minimal Profile (~2GB)

**Best for:** Low memory systems, quick testing, resource-constrained environments

**Models:**
- `llama3.2:1b` - Ultra-fast 1B parameter model for reasoning
- `nomic-embed-text` - Embeddings for RAG applications

**Use cases:**
- Testing and development
- Systems with <8GB RAM
- Quick prototyping

---

### Efficient Profile (~5GB) ⭐ RECOMMENDED

**Best for:** Production use with resource constraints, balanced performance

**Models:**
- `llama3.2:1b` - Ultra-fast reasoning (1B params)
- `mistral:7b-instruct-q4_0` - 4-bit quantized Mistral for instruction following
- `nomic-embed-text` - Embeddings for RAG

**Use cases:**
- Production deployments
- Systems with 8-16GB RAM
- Good balance of speed and capability

**Why this profile:**
- Minimal memory footprint with quantization
- Still maintains good quality output
- Fast inference times
- Covers all essential use cases

---

### Standard Profile (~10GB)

**Best for:** Balanced performance and quality, general purpose

**Models:**
- `llama3.2` - Main reasoning model (~2GB)
- `mistral:7b-instruct` - Fast instruction following (~4GB)
- `llama3:7b-q4_0` - Quantized Llama-3 7B (~4GB)
- `nomic-embed-text` - Embeddings for RAG

**Use cases:**
- Systems with 16-32GB RAM
- When you need better quality than efficient profile
- Multiple concurrent inference tasks

---

### Full Profile (~20GB)

**Best for:** Maximum capability and versatility, experimentation

**Models:**
- `llama3.2:1b` - Ultra-fast lightweight
- `llama3.2` - Standard reasoning
- `llama3:7b-q4_0` - Quantized Llama-3 7B
- `mistral:7b-instruct` - Mistral full precision
- `mistral:7b-instruct-q4_0` - Mistral quantized
- `codellama:7b-q4_0` - Code analysis (quantized)
- `nomic-embed-text` - Embeddings for RAG

**Use cases:**
- Systems with 32GB+ RAM
- Testing different models for different tasks
- Development and research
- Code analysis capabilities

---

### Custom Profile

**Best for:** Advanced users with specific requirements

Configure your own model list in `.env`:

```bash
LLM_MODEL_PROFILE=custom
LLM_CUSTOM_MODELS=llama3.2:1b,phi3:mini,nomic-embed-text
```

---

## Model Management

### Using the Management Script

The `manage-models.sh` script provides easy model management:

#### List Installed Models

```bash
./manage-models.sh list
```

Output:
```
NAME                        ID              SIZE      MODIFIED
llama3.2:1b                abc123def456    1.3 GB    2 hours ago
mistral:7b-instruct-q4_0   def789ghi012    3.8 GB    2 hours ago
nomic-embed-text           ghi345jkl678    274 MB    2 hours ago
```

#### Pull a Specific Model

```bash
./manage-models.sh pull llama3.2:1b
```

#### Pull an Entire Profile

```bash
./manage-models.sh pull-profile efficient
```

#### Remove a Model

```bash
./manage-models.sh remove mistral:7b-instruct
```

#### Get Model Information

```bash
./manage-models.sh info
```

---

## Understanding Quantization

Quantization reduces model size by using fewer bits to represent weights, with minimal quality loss.

### Quantization Types

| Type | Bits | Size Reduction | Quality Loss | Recommendation |
|------|------|----------------|--------------|----------------|
| q4_0 | 4-bit | ~50% | ~5% | Best for most use cases |
| q5_0 | 5-bit | ~40% | ~3% | Good quality/size balance |
| q8_0 | 8-bit | ~25% | <1% | Near-original quality |

### Example: Mistral 7B

```
mistral:7b-instruct          ~4.1 GB   Full precision
mistral:7b-instruct-q4_0     ~2.2 GB   4-bit quantized (50% smaller)
mistral:7b-instruct-q8_0     ~3.8 GB   8-bit quantized (minimal loss)
```

**Recommendation:** Use q4_0 quantization for most use cases - excellent quality with significant size savings.

---

## Popular Additional Models

### Ultra-Small Models (<2GB)

Perfect for low-memory systems or fast inference:

```bash
docker exec recon_ollama ollama pull llama3.2:1b    # 1.3GB - Llama 1B
docker exec recon_ollama ollama pull phi3:mini      # 2.3GB - Microsoft Phi-3
docker exec recon_ollama ollama pull gemma:2b       # 1.6GB - Google Gemma 2B
docker exec recon_ollama ollama pull qwen2:1.5b     # 1.0GB - Qwen 1.5B
```

### Medium Models - Quantized (2-5GB)

Best balance of size and capability:

```bash
docker exec recon_ollama ollama pull llama3:7b-q4_0        # 4.3GB
docker exec recon_ollama ollama pull mistral:7b-q4_0       # 4.1GB
docker exec recon_ollama ollama pull llama2:7b-q4_0        # 3.8GB
docker exec recon_ollama ollama pull neural-chat:7b-q4_0   # 4.1GB
```

### Code-Specialized Models

For analyzing configs, scripts, and code:

```bash
docker exec recon_ollama ollama pull codellama:7b-q4_0     # 3.8GB
docker exec recon_ollama ollama pull deepseek-coder:6.7b   # 3.8GB
docker exec recon_ollama ollama pull starcoder2:7b         # 4.0GB
```

### Embedding Models

For RAG (Retrieval-Augmented Generation) and semantic search:

```bash
docker exec recon_ollama ollama pull nomic-embed-text      # 274MB - Recommended
docker exec recon_ollama ollama pull mxbai-embed-large     # 669MB - Alternative
docker exec recon_ollama ollama pull all-minilm            # 45MB  - Lightweight
```

---

## Using Models in n8n Workflows

### Ollama Configuration

The Ollama service is accessible from n8n workflows at:

```
OLLAMA_HOST=http://ollama:11434
```

### Example: Using Llama3.2:1b for Fast Analysis

In your n8n workflow, configure the Ollama node:

```json
{
  "model": "llama3.2:1b",
  "prompt": "Analyze this nmap scan output and identify critical vulnerabilities...",
  "temperature": 0.7
}
```

### Example: Using Mistral for Instruction Following

```json
{
  "model": "mistral:7b-instruct-q4_0",
  "prompt": "Given the following reconnaissance data, prioritize targets by risk...",
  "temperature": 0.3
}
```

### Example: Using CodeLlama for Script Analysis

```json
{
  "model": "codellama:7b-q4_0",
  "prompt": "Analyze this PowerShell script found during enumeration...",
  "temperature": 0.2
}
```

### Example: Using Embeddings for RAG

```json
{
  "model": "nomic-embed-text",
  "input": "CVE-2024-1234 exploitation technique",
  "collection": "pentest_knowledge"
}
```

---

## Performance Considerations

### Memory Requirements

| Profile   | Minimum RAM | Recommended RAM | Notes |
|-----------|-------------|-----------------|-------|
| Minimal   | 4GB         | 8GB             | Basic functionality |
| Efficient | 8GB         | 12GB            | Good for production |
| Standard  | 16GB        | 24GB            | Multiple models loaded |
| Full      | 24GB        | 32GB+           | All models available |

### Inference Speed

Approximate tokens per second on typical hardware:

| Model                    | CPU (16 cores) | GPU (RTX 3060) | GPU (RTX 4090) |
|--------------------------|----------------|----------------|----------------|
| llama3.2:1b             | 60-80 t/s      | 150-200 t/s    | 300-400 t/s    |
| mistral:7b-q4_0         | 15-25 t/s      | 80-100 t/s     | 150-200 t/s    |
| llama3:7b-q4_0          | 12-20 t/s      | 70-90 t/s      | 140-180 t/s    |
| mistral:7b-instruct     | 8-15 t/s       | 50-70 t/s      | 100-130 t/s    |

---

## Troubleshooting

### Ollama Container Not Running

```bash
# Check if Ollama is running
docker ps | grep recon_ollama

# Start Ollama if needed
docker compose up -d ollama

# Check logs
docker logs recon_ollama
```

### Model Pull Failed

```bash
# Retry with verbose output
docker exec -it recon_ollama ollama pull llama3.2:1b

# Check available disk space
docker exec recon_ollama df -h

# Check Ollama service
curl http://localhost:11434/api/tags
```

### Out of Memory

If you're running out of memory:

1. Switch to a smaller profile:
   ```bash
   # Edit .env
   LLM_MODEL_PROFILE=minimal
   ```

2. Remove unused models:
   ```bash
   ./manage-models.sh list
   ./manage-models.sh remove <model-name>
   ```

3. Use quantized versions:
   ```bash
   # Replace full precision with quantized
   ./manage-models.sh remove mistral:7b-instruct
   ./manage-models.sh pull mistral:7b-instruct-q4_0
   ```

---

## Advanced Configuration

### Setting Concurrent Model Loading

Edit `docker-compose.yml`:

```yaml
ollama:
  environment:
    - OLLAMA_NUM_PARALLEL=3  # Load up to 3 models simultaneously
```

### Custom Model Parameters

Create a custom Modelfile for fine-tuned behavior:

```bash
docker exec -it recon_ollama sh

cat > /tmp/pentestllama <<EOF
FROM llama3.2:1b

PARAMETER temperature 0.3
PARAMETER top_p 0.9
PARAMETER top_k 40

SYSTEM You are a cybersecurity expert assistant specializing in penetration testing and reconnaissance.
EOF

ollama create pentestllama -f /tmp/pentestllama
```

---

## Best Practices

### Model Selection Strategy

1. **Start with Efficient Profile** - Best balance for most users
2. **Test with Minimal** - If you have limited resources
3. **Upgrade to Standard** - If you need better quality
4. **Use Quantized Models** - q4_0 offers great quality/size ratio
5. **Specialize as Needed** - Add code models only if analyzing scripts

### Workflow Design

1. **Use lightweight models for fast decisions** (llama3.2:1b)
2. **Use larger models for complex analysis** (mistral:7b, llama3:7b)
3. **Use code models only for code analysis** (codellama)
4. **Always use embeddings for RAG** (nomic-embed-text)

### Resource Optimization

1. **Don't load all models at once** - Use only what you need
2. **Clean up unused models regularly** - Free up disk space
3. **Monitor memory usage** - Adjust profile if needed
4. **Use quantized versions** - Especially for 7B+ models

---

## Additional Resources

- [Ollama Model Library](https://ollama.ai/library) - Browse all available models
- [Ollama Documentation](https://github.com/ollama/ollama/blob/main/docs/README.md)
- [Model Quantization Guide](https://github.com/ollama/ollama/blob/main/docs/quantization.md)

---

## Quick Reference Commands

```bash
# Model management
./manage-models.sh list                      # List installed models
./manage-models.sh pull llama3.2:1b          # Pull specific model
./manage-models.sh pull-profile efficient    # Pull profile
./manage-models.sh remove <model>            # Remove model
./manage-models.sh info                      # Show detailed info

# Manual Ollama commands
docker exec recon_ollama ollama list         # List models
docker exec recon_ollama ollama pull <model> # Pull model
docker exec recon_ollama ollama rm <model>   # Remove model
docker exec recon_ollama ollama run <model>  # Test model interactively

# Check Ollama status
curl http://localhost:11434/api/tags         # API check
docker logs recon_ollama                     # View logs
```
