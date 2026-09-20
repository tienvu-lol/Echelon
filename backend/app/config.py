"""Legacy configuration facade re-exporting from app.core.config.

Maintains backward compatibility with any modules or tests importing
from app.config while ensuring a single, deterministic configuration source.
"""

from app.core.config import Settings, get_settings, settings

__all__ = ["Settings", "get_settings", "settings"]
