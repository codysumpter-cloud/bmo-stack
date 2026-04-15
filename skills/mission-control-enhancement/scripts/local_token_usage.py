#!/usr/bin/env python3
"""
Local Token Usage Data Collector
Tracks token usage from local Ollama models by parsing logs or using Ollama API.
"""

import json
import subprocess
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
WORKFLOWS_DIR = ROOT / "workflows"
TOKEN_USAGE_FILE = WORKFLOWS_DIR / "local_token_usage.json"

def get_ollama_models():
    """Get list of locally installed Ollama models."""
    try:
        result = subprocess.run(["ollama", "list"], capture_output=True, text=True, check=True)
        lines = result.stdout.strip().split('\n')[1:]  # Skip header
        models = []
        for line in lines:
            if line.strip():
                parts = line.split()
                if parts:
                    models.append(parts[0])
        return models
    except Exception as e:
        print(f"Error getting Ollama models: {e}")
        return []

def estimate_token_usage():
    """
    Estimate token usage for local models.
    Note: Ollama doesn't provide token usage by default, so we estimate based on
    known interactions or log parsing. For now, we'll return placeholder data.
    In a real implementation, you might:
    - Parse Ollama server logs (if enabled)
    - Use a proxy to count tokens
    - Track usage via a wrapper script
    """
    models = get_ollama_models()
    usage_data = []
    
    # For each model, we'll create an entry with estimated usage
    # In a real system, this would be actual usage data
    for model in models:
        # Placeholder: In reality, you'd get this from logs or a tracking system
        usage_data.append({
            "model": model,
            "tokens_per_second": 0,  # Placeholder
            "total_tokens_today": 0,  # Placeholder
            "last_used": None,  # Placeholder
            "status": "available"
        })
    
    # If no models are installed, show a default entry
    if not usage_data:
        usage_data.append({
            "model": "none",
            "tokens_per_second": 0,
            "total_tokens_today": 0,
            "last_used": None,
            "status": "no_models_installed"
        })
    
    return {
        "timestamp": datetime.now().isoformat(),
        "data": usage_data
    }

def main():
    """Main entry point."""
    # Ensure workflows directory exists
    WORKFLOWS_DIR.mkdir(parents=True, exist_ok=True)
    
    # Collect token usage data
    token_data = estimate_token_usage()
    
    # Write to file
    try:
        with open(TOKEN_USAGE_FILE, 'w') as f:
            json.dump(token_data, f, indent=2)
        print(f"Local token usage data written to {TOKEN_USAGE_FILE}")
        print(f"Tracked {len(token_data['data'])} models")
    except Exception as e:
        print(f"Error writing token usage data: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())