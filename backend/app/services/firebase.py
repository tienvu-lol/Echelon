"""Firebase Authentication service."""
import logging
import firebase_admin
from firebase_admin import credentials, auth
from app.core.config import settings

logger = logging.getLogger(__name__)

class FirebaseServiceError(Exception):
    """Raised when a Firebase operation fails."""
    pass

class FirebaseService:
    """Wrapper around Firebase Admin SDK for authentication."""

    _initialized = False

    @classmethod
    def initialize(cls):
        """Initializes the Firebase Admin SDK if not already initialized."""
        if cls._initialized:
            return
            
        try:
            # Check if default app is already initialized to prevent ValueError during tests
            try:
                firebase_admin.get_app()
                cls._initialized = True
                return
            except ValueError:
                pass

            if settings.firebase_credentials_path:
                cred = credentials.Certificate(settings.firebase_credentials_path)
                firebase_admin.initialize_app(cred)
            else:
                # Initialize with default application credentials
                firebase_admin.initialize_app()
            cls._initialized = True
        except Exception as e:
            logger.error(f"Failed to initialize Firebase Admin SDK: {e}")
            raise FirebaseServiceError("Failed to initialize authentication service.") from e

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

