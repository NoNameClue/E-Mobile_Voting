from sqlalchemy import Column, Integer, String, Boolean, DateTime, Enum as SQLEnum, JSON, ForeignKey
from sqlalchemy.orm import relationship
from database import Base

class User(Base):
    __tablename__ = "users"
    user_id = Column(Integer, primary_key=True, index=True)
    student_number = Column(String(50), unique=True, index=True)
    first_name = Column(String(50), nullable=False)
    middle_name = Column(String(50), default="")
    last_name = Column(String(50), nullable=False)
    email = Column(String(100), unique=True, index=True)
    course = Column(String(100))
    password_hash = Column(String(255))
    role = Column(SQLEnum('Admin', 'Student', 'Staff'), default="Student")
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime)
    profile_pic_url = Column(String(255), nullable=True)
    permissions = Column(JSON, default=list)

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
    name = Column(String(100), unique=True, index=True) # 🛠️ CHANGED TO name
    
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

class Vote(Base):
    __tablename__ = "votes"
    vote_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"))
    poll_id = Column(Integer, ForeignKey("polls.poll_id"))
    candidate_id = Column(Integer, ForeignKey("candidates.candidate_id"))