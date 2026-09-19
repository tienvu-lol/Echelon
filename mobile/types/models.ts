/**
 * TypeScript interfaces mirroring backend Pydantic models.
 */

export interface StudentProfile {
  id: string;
  major: string;
  graduation_year: number;
  skills: string[];
  interests: string[];
  coursework: string[];
  experience: string[];
  bio: string | null;
  profile_text: string | null;
  created_at: string;
}

export interface Opportunity {
  id: string;
  title: string;
  organization: string;
  opportunity_type: string;
  description: string;
  skills: string[];
  majors: string[];
  class_years: number[];
  location: string | null;
  paid: boolean | null;
  deadline: string | null;
  contact_name: string | null;
  contact_email: string | null;
  apply_url: string | null;
  source_url: string | null;
  source_name: string | null;
}

export interface OpportunityCard {
  id: string;
  title: string;
  organization: string;
  opportunity_type: string;
  description: string;
  skills: string[];
  location: string | null;
  paid: boolean | null;
  deadline: string | null;
  apply_url: string | null;
  explanation: string | null;
}

export interface Swipe {
  id: string;
  student_id: string;
  opportunity_id: string;
  direction: 'left' | 'right';
  created_at: string;
}

export interface SavedOpportunity {
  student_id: string;
  opportunity_id: string;
  created_at: string;
}

export interface HealthResponse {
  status: string;
}

export interface ServiceTestResponse {
  service: string;
  status: string;
  message: string;
  details?: Record<string, unknown>;
}
