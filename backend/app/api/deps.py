"""FastAPI dependencies."""

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.services.firebase import FirebaseService, FirebaseServiceError

security = HTTPBearer()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> dict:
    """
    Dependency to get the current authenticated user from Firebase token.
    Returns the decoded token dictionary.
    """
    token = credentials.credentials
    try:
        decoded_token = FirebaseService.verify_token(token)
        if not isinstance(decoded_token, dict) or not decoded_token.get("uid"):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid user token: missing uid.",
                headers={"WWW-Authenticate": "Bearer"},
            )
        return decoded_token
    except HTTPException:
        raise
    except FirebaseServiceError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
            headers={"WWW-Authenticate": "Bearer"},
        )
