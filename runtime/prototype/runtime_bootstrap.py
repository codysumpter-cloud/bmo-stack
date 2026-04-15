import os
import sys
import logging
from pathlib import Path
from typing import Any

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("iBuddy-Bootstrap")

# Configuration: Path to the reference runtime implementation (hermes-agent)
DEFAULT_REFERENCE_PATH = "/Users/prismtek/repos/hermes-agent"
REFERENCE_RUNTIME_PATH = os.environ.get("IBUDDY_REFERENCE_RUNTIME_PATH", DEFAULT_REFERENCE_PATH)

_ADAPTER_INSTANCE = None

def initialize_runtime():
    """
    Explicitly initializes the reference runtime dependency.
    Validates the path and prepares the import environment.
    """
    global _ADAPTER_INSTANCE
    logger.info("--- iBuddy Runtime Bootstrap ---")
    logger.info(f"Targeting reference runtime at: {REFERENCE_RUNTIME_PATH}")

    ref_path = Path(REFERENCE_RUNTIME_PATH)
    if not ref_path.exists() or not ref_path.is_dir():
        logger.error(f"CRITICAL: Reference runtime path not found: {REFERENCE_RUNTIME_PATH}")
        raise FileNotFoundError(f"The required reference runtime implementation was not found at {REFERENCE_RUNTIME_PATH}. Please set IBUDDY_REFERENCE_RUNTIME_PATH.")

    if str(ref_path) not in sys.path:
        sys.path.insert(0, str(ref_path))
        logger.info("Reference runtime path injected into sys.path.")

    logger.info("Reference runtime dependency resolved. Prototype is now using the Hermes reference implementation.")
    logger.info("---------------------------------")

def get_adapter(**kwargs):
    """
    Provides a singleton BuddyAdapter instance from the reference implementation.
    """
    global _ADAPTER_INSTANCE
    if _ADAPTER_INSTANCE is None:
        try:
            from src.buddy_adapter import BuddyAdapter
            _ADAPTER_INSTANCE = BuddyAdapter(**kwargs)
            
            # Re-hydrate existing sessions from disk on startup
            logger.info("Re-hydrating sessions from persistence layer...")
            _ADAPTER_INSTANCE.load_sessions()
            logger.info("Session re-hydration complete.")
            
        except ImportError as e:
            logger.error(f"CRITICAL: Failed to import BuddyAdapter from reference runtime: {e}")
            raise ImportError(f"Could not locate BuddyAdapter in {REFERENCE_RUNTIME_PATH}")
    
    return _ADAPTER_INSTANCE
