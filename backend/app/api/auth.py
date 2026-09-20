from fastapi import APIRouter, Depends
from app.api.deps import get_current_user

router = APIRouter(prefix="/api/auth", tags=["auth"])

@router.get("/me")
async def get_me(current_user: dict = Depends(get_current_user)):
    """
    Test endpoint for Firebase authentication.
    Returns the decoded token for the current user.
    """
    return {
        "status": "authenticated",
        "uid": current_user.get("uid"),
        "email": current_user.get("email"),
        "token_data": current_user
    }

