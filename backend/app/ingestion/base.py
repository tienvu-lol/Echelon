"""Base interface for opportunity ingestion adapters."""

from abc import ABC, abstractmethod
from collections.abc import Iterator

from app.models.opportunity import Opportunity


class BaseSourceAdapter(ABC):
    """Abstract base class for all opportunity ingestion sources."""

    def __init__(self):
        pass

    @abstractmethod
    def fetch_opportunities(self) -> Iterator[Opportunity]:
        """Fetch and yield standardized Opportunity objects from the source.

        Yields:
            Opportunity: A normalized opportunity.
        """
