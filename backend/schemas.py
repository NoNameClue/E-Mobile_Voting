from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class UserCreate(BaseModel):
    full_name: str
    email: str
    student_number: str
    password: str
    course: str

class UserLogin(BaseModel):
    email: str
    password: str

class OfficerCreate(BaseModel):
    full_name: str
    email: str
    password: str

class PermissionsUpdate(BaseModel):
    permissions: List[str]

class PartyCreate(BaseModel):
    party_name: str

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
    name: Optional[str] = None
    course_year: Optional[str] = None
    description_platform: Optional[str] = None

class StatusUpdate(BaseModel):
    is_active: bool