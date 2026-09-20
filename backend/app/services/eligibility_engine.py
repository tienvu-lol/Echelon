"""Eligibility Engine.

Determines if a student is eligible for a given opportunity based on hard filters.
Returns ELIGIBLE, INELIGIBLE, or UNKNOWN.
"""

from typing import Tuple, List

from app.models.student import StudentProfile
from app.models.opportunity import Opportunity

ELIGIBLE = "ELIGIBLE"
INELIGIBLE = "INELIGIBLE"
UNKNOWN = "UNKNOWN"

def evaluate_eligibility(profile: StudentProfile, opportunity: Opportunity) -> Tuple[str, List[str]]:
    """Evaluates eligibility.
    
    Returns:
        A tuple of (status, list of explanation notes).
    """
    notes = []
    status = ELIGIBLE
    
    # 1. Check Class Year
    if opportunity.class_years and profile.class_year:
        if profile.class_year not in opportunity.class_years:
            status = INELIGIBLE
            notes.append(f"Requires class year in {opportunity.class_years}, but student is {profile.class_year}.")
    elif opportunity.class_years and not profile.class_year:
        status = UNKNOWN
        notes.append(f"Requires class year in {opportunity.class_years}, but student's class year is unknown.")
        
    # 2. Check Major / Degree
    if opportunity.majors and profile.major:
        # Simple substring match for now
        student_major_lower = profile.major.lower()
        matched = False
        for req_major in opportunity.majors:
            if req_major.lower() in student_major_lower or student_major_lower in req_major.lower():
                matched = True
                break
        if not matched:
            status = INELIGIBLE
            notes.append(f"Requires major in {opportunity.majors}, but student is {profile.major}.")
            
    # 3. Check School Restrictions
    if opportunity.school_restrictions:
        # We assume the user is from Virginia Tech based on our Echelon agent constraint.
        vt_aliases = ["virginia tech", "vt", "vpi", "virginia polytechnic"]
        matched = False
        for restriction in opportunity.school_restrictions:
            r_lower = restriction.lower()
            if any(alias in r_lower for alias in vt_aliases):
                matched = True
                break
        if not matched:
            status = INELIGIBLE
            notes.append(f"Opportunity is restricted to specific schools: {opportunity.school_restrictions}.")
            
    if status == ELIGIBLE and not notes:
        notes.append("Student meets all known eligibility criteria.")
        
    return status, notes

