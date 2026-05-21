from sqlalchemy import Column, Integer, String, Boolean, DateTime, Enum as SQLEnum, JSON, ForeignKey, Text
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from database import Base
from datetime import datetime

class User(Base):
    __tablename__ = "users"
    user_id = Column(Integer, primary_key=True, index=True)
    student_number = Column(String(50), unique=True, index=True)
    first_name = Column(String(50), nullable=False)
    middle_name = Column(String(50), default="")
    last_name = Column(String(50), nullable=False, index=True)
    email = Column(String(100), unique=True, index=True)
    course = Column(String(100))
    password_hash = Column(String(255))
    role = Column(SQLEnum('Admin', 'Student', 'Staff'), default="Student")
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, server_default=func.now(), index=True)
    profile_pic_url = Column(String(255), nullable=True)
    permissions = Column(JSON, default=list)
    is_student_officer = Column(Boolean, default=False)
    permissions = Column(JSON, nullable=True)

class Poll(Base):
    __tablename__ = "polls"
    poll_id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200))
    start_time = Column(DateTime)
    end_time = Column(DateTime)
    status = Column(String(50), default="Draft") 
    is_published = Column(Boolean, default=False)
    is_archived = Column(Boolean, default=False)
    candidates = relationship("Candidate", back_populates="poll")

class Party(Base):
    __tablename__ = "parties"
    party_id = Column(Integer, primary_key=True, index=True)
    poll_id = Column(Integer, ForeignKey("polls.poll_id", ondelete="CASCADE"), nullable=False)
    name = Column(String(100), unique=True, index=True)
    platform_bio = Column(Text, nullable=True) 
    
class Candidate(Base):
    __tablename__ = "candidates"
    candidate_id = Column(Integer, primary_key=True, index=True)
    poll_id = Column(Integer, ForeignKey("polls.poll_id"))
    first_name = Column(String(50), nullable=False)
    middle_name = Column(String(50), default="")
    last_name = Column(String(50), nullable=False)
    position = Column(String(50))
    party_name = Column(String(50), default="Independent")
    course_year = Column(String(80))
    description_platform = Column(String(500))
    photo_url = Column(String(255))
    poll = relationship("Poll", back_populates="candidates")
    qas = relationship("CandidateQA", back_populates="candidate", cascade="all, delete-orphan")
    is_withdrawn = Column(Boolean, default=False)
    
class CandidateQA(Base):
    __tablename__ = "candidate_qa"
    qa_id = Column(Integer, primary_key=True, index=True)
    candidate_id = Column(Integer, ForeignKey("candidates.candidate_id", ondelete="CASCADE"))
    question = Column(String(255))
    answer = Column(Text)
    candidate = relationship("Candidate", back_populates="qas")

class QuestionBank(Base):
    __tablename__ = "question_bank"
    question_id = Column(Integer, primary_key=True, index=True)
    question_text = Column(String(255), nullable=False, unique=True)

class Vote(Base):
    __tablename__ = "votes"
    vote_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"))
    poll_id = Column(Integer, ForeignKey("polls.poll_id"))
    candidate_id = Column(Integer, ForeignKey("candidates.candidate_id"))
    
class PartyApplication(Base):
    __tablename__ = "party_applications"
    application_id = Column(Integer, primary_key=True, index=True)
    poll_id = Column(Integer, ForeignKey("polls.poll_id"))
    party_name = Column(String(100))
    platform_bio = Column(Text, nullable=True)
    candidates_payload = Column(JSON) # Stores the locked Q&A and info
    status = Column(String(50), default="Pending") # Pending, Approved, Rejected
    submitted_at = Column(String(100))
    
class StaffApplication(Base):
    __tablename__ = "staff_applications"
    application_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False)
    intent_statement = Column(Text, nullable=False)
    experience = Column(Text, nullable=False)
    availability = Column(String(100), nullable=False)
    status = Column(String(20), default="Pending") # Pending, Accepted, Rejected
    applied_at = Column(DateTime, default=datetime.utcnow)