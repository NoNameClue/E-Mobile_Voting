from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class UserCreate(BaseModel):
    first_name: str
    middle_name: Optional[str] = ""
    last_name: str
    email: str
    student_number: str
    password: str
    course: str

class UserLogin(BaseModel):
    email: str
    password: str

class OfficerCreate(BaseModel):
    first_name: str
    middle_name: Optional[str] = ""
    last_name: str
    email: str
    password: str

class PermissionsUpdate(BaseModel):
    permissions: List[str]

class PartyCreate(BaseModel):
    poll_id: int
    name: str

class PollCreate(BaseModel):
    title: str
    start_time: datetime
    end_time: datetime
    is_published: bool

class PollUpdate(BaseModel):
    title: str
    start_time: datetime
    end_time: datetime
    is_published: bool

class VoteSubmit(BaseModel):
    poll_id: int
    candidate_ids: List[int]

class CandidateUpdate(BaseModel):
    first_name: Optional[str] = None
    middle_name: Optional[str] = None
    last_name: Optional[str] = None
    course_year: Optional[str] = None
    description_platform: Optional[str] = None

class StatusUpdate(BaseModel):
    is_active: bool

# ADDED AS REQUESTED
class UserResponse(BaseModel):
    user_id: int
    email: str
    full_name: str
    role: str
    is_student_officer: bool = False  
    permissions: list[str] = []       
    
    class Config:
        from_attributes = True
        
class UserAdminUpdate(BaseModel):
    course: Optional[str] = None
    password: Optional[str] = None
    is_student_officer: Optional[bool] = None
    permissions: Optional[List[str]] = None

class StaffApplicationCreate(BaseModel):
    intent: str
    qualifications: Optional[str] = None

class StaffApplicationResponse(BaseModel):
    application_id: int
    user_id: int
    intent: str
    qualifications: Optional[str]
    status: str

    class Config:
        from_attributes = True