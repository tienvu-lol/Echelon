"""Firebase Authentication service."""

import logging
import threading

import firebase_admin
from firebase_admin import auth, credentials

from app.core.config import settings

logger = logging.getLogger(__name__)


class FirebaseServiceError(Exception):
    """Raised when a Firebase operation fails."""


class FirebaseService:
    """Wrapper around Firebase Admin SDK for authentication."""

    _initialized = False
    _initialization_lock = threading.Lock()

    @classmethod
    def initialize(cls):
        """Initializes the Firebase Admin SDK if not already initialized."""
        if cls._initialized:
            return

        try:
            # Fast path when another caller or test initialized the default app.
            try:
                firebase_admin.get_app()
                cls._initialized = True
                return
            except ValueError:
                pass

            with cls._initialization_lock:
                if cls._initialized:
                    return

                # Another thread may have initialized Firebase while this one
                # was waiting for the lock.
                try:
                    firebase_admin.get_app()
                except ValueError:
                    if settings.firebase_credentials_path:
                        cred = credentials.Certificate(settings.firebase_credentials_path)
                        firebase_admin.initialize_app(cred)
                    else:
                        # Initialize with default application credentials
                        firebase_admin.initialize_app()

                cls._initialized = True
        except Exception as e:
            logger.error(f"Failed to initialize Firebase Admin SDK: {e}")
            raise FirebaseServiceError(
                "Failed to initialize authentication service."
            ) from e

    @staticmethod
    def verify_token(id_token: str) -> dict:
        """Verifies a Firebase ID token and returns the decoded token."""
        FirebaseService.initialize()

        try:
            decoded_token = auth.verify_id_token(id_token)
            return decoded_token
        except Exception as e:
            logger.error(f"Firebase token verification failed: {e}")
            raise FirebaseServiceError("Invalid or expired authentication token") from e
