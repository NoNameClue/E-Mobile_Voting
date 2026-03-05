from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, Integer, String, Boolean, Enum as SQLEnum
from sqlalchemy.orm import sessionmaker, Session, declarative_base
from passlib.context import CryptContext
import jwt
import enum
from datetime import datetime, timedelta
from sqlalchemy import DateTime # Ensure DateTime is in your sqlalchemy imports at the top
from typing import Optional # Add this to your imports at the top

# ==========================================
# 1. SETUP & CONFIGURATION
# ==========================================
SECRET_KEY = "your_super_secret_jwt_key_here" # Change this in production!
ALGORITHM = "HS256"

# Connect to your MySQL database (Make sure to put your actual MySQL password here)
DATABASE_URL = "mysql+pymysql://root:@localhost/emobile_voting"
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

app = FastAPI()

# ==========================================
# ADD THIS MISSING FUNCTION HERE:
# ==========================================
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
# ==========================================

# Crucial for Flutter Web: Allows your frontend to talk to this API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"]
)

# Password Hashing Setup
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# ==========================================
# 2. DATABASE MODELS & SCHEMAS
# ==========================================
# Tells Python what your MySQL users table looks like
class UserRole(str, enum.Enum):
    Admin = "Admin"
    Student = "Student"

class User(Base):
    __tablename__ = "users"
    user_id = Column(Integer, primary_key=True, index=True)
    student_number = Column(String(50), unique=True, nullable=False) # Added for registration
    full_name = Column(String(100), nullable=False)                  # Added for registration
    email = Column(String(100), unique=True, index=True)
    course = Column(String(50), nullable=False)                      # Added for registration
    password_hash = Column(String(255), nullable=False)
    role = Column(SQLEnum('Admin', 'Student'), default='Student')
    is_active = Column(Boolean, default=False)

# Defines the JSON payload Flutter will send for Login
class LoginRequest(BaseModel):
    email: str
    password: str

# Defines the JSON payload Flutter will send for Registration
class RegisterRequest(BaseModel):
    student_number: str
    full_name: str
    email: str
    course: str
    password: str

# --- ADD THESE MODELS & SCHEMAS ---
from typing import Optional

from pydantic import BaseModel
from sqlalchemy import Column, Integer, String, DateTime
from typing import Optional
from datetime import datetime

# --- 1. DATABASE MODEL ---
class Poll(Base): # Assuming Base is your SQLAlchemy declarative_base
    __tablename__ = "polls"
    poll_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    title = Column(String(255), nullable=False)
    start_time = Column(DateTime, nullable=False)
    end_time = Column(DateTime, nullable=False)
    status = Column(String(50), default="Upcoming")

# --- 2. PYDANTIC SCHEMAS ---
class PollCreate(BaseModel):
    title: str
    start_time: datetime
    end_time: datetime
    status: Optional[str] = "Upcoming"

class PollUpdate(BaseModel):
    title: Optional[str] = None
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    status: Optional[str] = None

# --- 3. API ENDPOINTS ---
@app.get("/api/polls")
def get_polls(db: Session = Depends(get_db)):
    return db.query(Poll).all()

@app.post("/api/polls")
def create_poll(poll: PollCreate, db: Session = Depends(get_db)):
    new_poll = Poll(
        title=poll.title,
        start_time=poll.start_time,
        end_time=poll.end_time,
        status=poll.status
    )
    db.add(new_poll)
    db.commit()
    db.refresh(new_poll)
    return {"message": "Poll created successfully", "poll": new_poll}

@app.put("/api/polls/{poll_id}")
def update_poll(poll_id: int, poll_update: PollUpdate, db: Session = Depends(get_db)):
    db_poll = db.query(Poll).filter(Poll.poll_id == poll_id).first()
    if not db_poll:
        raise HTTPException(status_code=404, detail="Poll not found")

    update_data = poll_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_poll, key, value)

    db.commit()
    db.refresh(db_poll)
    return {"message": "Poll updated successfully", "poll": db_poll}

@app.delete("/api/polls/{poll_id}")
def delete_poll(poll_id: int, db: Session = Depends(get_db)):
    db_poll = db.query(Poll).filter(Poll.poll_id == poll_id).first()
    if not db_poll:
        raise HTTPException(status_code=404, detail="Poll not found")
    
    db.delete(db_poll)
    db.commit()
    return {"message": "Poll deleted successfully"}

@app.get("/api/admin/students")
def get_students(db: Session = Depends(get_db)):

    students = db.query(User).filter(User.role == UserRole.Student).all()

    return [
        {
            "user_id": student.user_id,
            "role": student.role.value,
            "is_active": student.is_active
        }
        for student in students
    ]

@app.put("/api/admin/students/{student_id}/toggle")
def toggle_student(student_id: str, db: Session = Depends(get_db)):

    student = db.query(User).filter(User.user_id == student_id).first()

    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    if student.role != UserRole.Student:
        raise HTTPException(status_code=400, detail="Cannot modify admin account")

    student.is_active = not student.is_active

    db.commit()

    return {
        "message": "Student status updated",
        "user_id": student.user_id,
        "is_active": student.is_active
    }

@app.post("/api/login")
def login(request: LoginRequest, db: Session = Depends(get_db)):
    # 1. Find the user by email
    user = db.query(User).filter(User.email == request.email).first()
    
    if not user:
        raise HTTPException(status_code=401, detail="Invalid email or password")
    
    # 2. Check if the account is disabled by an admin
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account is disabled")

    # 3. Verify the password matches the hash
    if not pwd_context.verify(request.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    # 4. Generate the secure JWT Session Token
    expire = datetime.utcnow() + timedelta(hours=2) # Token lasts 2 hours
    token_data = {
        "sub": str(user.user_id),
        "email": user.email,
        "role": user.role,
        "exp": expire
    }
    token = jwt.encode(token_data, SECRET_KEY, algorithm=ALGORITHM)

    # 5. Send data back to Flutter
    return {
        "access_token": token,
        "token_type": "bearer",
        "role": user.role,
        "message": "Login successful"
    }

