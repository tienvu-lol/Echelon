import pytest
from fastapi import HTTPException
from fastapi.security import HTTPAuthorizationCredentials
from unittest.mock import patch, MagicMock
from app.services.firebase import FirebaseService, FirebaseServiceError
from app.api.deps import get_current_user

def test_firebase_verify_token_success():
    """Test successful token verification using a mocked Firebase auth."""
    mock_token = "valid_mock_token"
    mock_decoded = {"uid": "test_user_123", "email": "test@example.com"}
    
    with patch("app.services.firebase.auth.verify_id_token") as mock_verify:
        mock_verify.return_value = mock_decoded
        
        # Ensure service is initialized for testing without actual credentials
        FirebaseService._initialized = True
        
        result = FirebaseService.verify_token(mock_token)
        
        mock_verify.assert_called_once_with(mock_token)
        assert result == mock_decoded

def test_firebase_verify_token_failure():
    """Test token verification failure."""
    mock_token = "invalid_mock_token"
    
    with patch("app.services.firebase.auth.verify_id_token") as mock_verify:
        mock_verify.side_effect = Exception("Expired token")
        FirebaseService._initialized = True
        
        with pytest.raises(FirebaseServiceError) as exc_info:
            FirebaseService.verify_token(mock_token)
            
        assert "Token verification failed" in str(exc_info.value)
        assert "Expired token" in str(exc_info.value)

def test_get_current_user_dependency_success():
    """Test the FastAPI dependency successfully returning a user."""
    mock_creds = HTTPAuthorizationCredentials(scheme="Bearer", credentials="valid_token")
    mock_decoded = {"uid": "user_456"}
    
    with patch("app.api.deps.FirebaseService.verify_token") as mock_verify:
        mock_verify.return_value = mock_decoded
        
        result = get_current_user(mock_creds)
        assert result == mock_decoded

def test_get_current_user_dependency_failure():
    """Test the FastAPI dependency raising a 401 on invalid token."""
    mock_creds = HTTPAuthorizationCredentials(scheme="Bearer", credentials="bad_token")
    
    with patch("app.api.deps.FirebaseService.verify_token") as mock_verify:
        mock_verify.side_effect = FirebaseServiceError("Token verification failed")
        
        with pytest.raises(HTTPException) as exc_info:
            get_current_user(mock_creds)
            
        assert exc_info.value.status_code == 401
        assert "Token verification failed" in exc_info.value.detail

