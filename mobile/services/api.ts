/**
 * API service for communicating with the Echelon FastAPI backend.
 * 
 * All backend communication goes through this module.
 * The mobile app never calls Gemini or Databricks directly.
 */

import { HealthResponse, StudentProfile, OpportunityCard, Swipe } from '../types/models';

const API_BASE_URL = process.env.EXPO_PUBLIC_API_BASE_URL || 'http://localhost:8000';

class ApiError extends Error {
  status: number;
  
  constructor(message: string, status: number) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
  }
}

async function request<T>(endpoint: string, options?: RequestInit): Promise<T> {
  const url = `${API_BASE_URL}${endpoint}`;
  
  try {
    const response = await fetch(url, {
      headers: {
        'Content-Type': 'application/json',
        ...options?.headers,
      },
      ...options,
    });

    if (!response.ok) {
      const errorBody = await response.text();
      throw new ApiError(
        `API request failed: ${response.status} ${errorBody}`,
        response.status
      );
    }

    return await response.json() as T;
  } catch (error) {
    if (error instanceof ApiError) throw error;
    throw new ApiError(
      `Network error: Unable to reach backend at ${url}. Is the server running?`,
      0
    );
  }
}

// Health
export async function healthCheck(): Promise<HealthResponse> {
  return request<HealthResponse>('/health');
}

// Profile
export async function createProfile(profile: {
  major: string;
  graduation_year: number;
  skills?: string[];
  interests?: string[];
  coursework?: string[];
  experience?: string[];
  bio?: string;
}): Promise<StudentProfile> {
  return request<StudentProfile>('/api/profile', {
    method: 'POST',
    body: JSON.stringify(profile),
  });
}

// Recommendations
export async function getRecommendations(
  studentId: string,
  limit: number = 10
): Promise<{ student_id: string; opportunities: OpportunityCard[] }> {
  return request(`/api/opportunities/recommendations?student_id=${studentId}&limit=${limit}`);
}

// Swipes
export async function recordSwipe(swipe: {
  student_id: string;
  opportunity_id: string;
  direction: 'left' | 'right';
}): Promise<Swipe> {
  return request<Swipe>('/api/swipes', {
    method: 'POST',
    body: JSON.stringify(swipe),
  });
}

// Saved
export async function getSavedOpportunities(studentId: string) {
  return request(`/api/saved?student_id=${studentId}`);
}

export async function saveOpportunity(opportunityId: string, studentId: string) {
  return request(`/api/saved/${opportunityId}?student_id=${studentId}`, {
    method: 'POST',
  });
}
