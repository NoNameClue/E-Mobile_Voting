from fastapi import Security, FastAPI, HTTPException, Depends
from fastapi.security import HTTPBearer
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, Integer, String, Boolean, DateTime, Enum as SQLEnum
from sqlalchemy.orm import sessionmaker, Session, declarative_base
from passlib.context import CryptContext
import jwt
import enum
from datetime import datetime, timedelta
from typing import Optional
from sqlalchemy import func

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
security = HTTPBearer()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_current_user_id(credentials = Security(security)):

    token = credentials.credentials

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("sub")
        return int(user_id)

    except:
        raise HTTPException(status_code=401, detail="Invalid token")

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
# --- USER MODELS ---
class UserRole(str, enum.Enum):
    Admin = "Admin"
    Student = "Student"

class User(Base):
    __tablename__ = "users"
    user_id = Column(Integer, primary_key=True, index=True)
    student_number = Column(String(50), unique=True, nullable=False)
    full_name = Column(String(100), nullable=False)
    email = Column(String(100), unique=True, index=True)
    course = Column(String(50), nullable=False)
    password_hash = Column(String(255), nullable=False)
    role = Column(SQLEnum('Admin', 'Student'), default='Student')
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow) # <--- ADD THIS LINE

# --- POLL MODEL (UPDATED FOR PUBLISHING) ---
class Poll(Base):
    __tablename__ = "polls"
    poll_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    title = Column(String(255), nullable=False)
    start_time = Column(DateTime, nullable=False)
    end_time = Column(DateTime, nullable=False)
    status = Column(String(50), default="Draft")          # Changed to Draft
    is_published = Column(Boolean, default=False)         # <--- NEW FIELD

# --- PYDANTIC SCHEMAS ---
class LoginRequest(BaseModel):
    email: str
    password: str

class RegisterRequest(BaseModel):
    student_number: str
    full_name: str
    email: str
    course: str
    password: str

class PollCreate(BaseModel):
    title: str
    start_time: datetime
    end_time: datetime
    status: Optional[str] = "Draft"                       # Changed to Draft

class PollUpdate(BaseModel):
    title: Optional[str] = None
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    status: Optional[str] = None

# --- CANDIDATE MODELS & SCHEMAS ---
class CandidateCreate(BaseModel):
    poll_id: int
    name: str
    position: str
    party_name: Optional[str] = "Independent"
    course_year: str
    description_platform: Optional[str] = None

class CandidateUpdate(BaseModel):
    name: Optional[str] = None
    position: Optional[str] = None
    party_name: Optional[str] = None
    course_year: Optional[str] = None
    description_platform: Optional[str] = None

class Candidate(Base):
    __tablename__ = "candidates"

    candidate_id = Column(Integer, primary_key=True, index=True)
    poll_id = Column(Integer, nullable=False)
    name = Column(String(100), nullable=False)
    position = Column(String(50), nullable=False)
    party_name = Column(String(50), default='Independent')
    course_year = Column(String(50), nullable=False)
    description_platform = Column(String(500), nullable=True)
    photo_url = Column(String(255), nullable=True)

class Vote(Base):
    __tablename__ = "votes"

    vote_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False)
    poll_id = Column(Integer, nullable=False)
    candidate_id = Column(Integer, nullable=False)
    cast_at = Column(DateTime, default=datetime.utcnow)

class VoteRequest(BaseModel):
    poll_id: int
    candidate_ids: list[int]

# ==========================================
# 3. API ENDPOINTS
# ==========================================

# --- POLL ENDPOINTS ---
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

# <--- NEW PUBLISH ENDPOINT --->
@app.put("/api/polls/{poll_id}/publish")
def publish_poll(poll_id: int, db: Session = Depends(get_db)):
    db_poll = db.query(Poll).filter(Poll.poll_id == poll_id).first()
    if not db_poll:
        raise HTTPException(status_code=404, detail="Poll not found")
    
    # Mark it as published
    db_poll.is_published = True
    db_poll.status = "Published"
    db.commit()
    
    return {"message": "Poll published successfully and is now visible to students."}

@app.delete("/api/polls/{poll_id}")
def delete_poll(poll_id: int, db: Session = Depends(get_db)):
    db_poll = db.query(Poll).filter(Poll.poll_id == poll_id).first()
    if not db_poll:
        raise HTTPException(status_code=404, detail="Poll not found")
    
    db.delete(db_poll)
    db.commit()
    return {"message": "Poll deleted successfully"}

@app.get("/api/polls/{poll_id}/results")
def get_poll_results(poll_id: int, db: Session = Depends(get_db)):
    # 1. Join candidates and votes to get the count for each candidate
    results = db.query(
        Candidate,
        func.count(Vote.vote_id).label('vote_count')
    ).outerjoin(
        Vote, Candidate.candidate_id == Vote.candidate_id
    ).filter(
        Candidate.poll_id == poll_id
    ).group_by(
        Candidate.candidate_id
    ).all()

    # 2. Calculate the total votes cast per position (for accurate percentages)
    position_totals = {}
    for cand, count in results:
        position_totals[cand.position] = position_totals.get(cand.position, 0) + count

    # 3. Format the data for the Flutter frontend
    response = []
    for cand, count in results:
        pos_total = position_totals.get(cand.position, 0)
        percentage = (count / pos_total * 100) if pos_total > 0 else 0.0
        
        response.append({
            "candidate_id": cand.candidate_id,
            "name": cand.name,
            "party_name": cand.party_name,
            "position": cand.position,
            "photo_url": cand.photo_url,
            "votes": count,
            "percentage": round(percentage, 1) # Example: 45.5
        })

    return response

# --- USER & ADMIN ENDPOINTS ---
@app.get("/api/admin/students")
def get_students(db: Session = Depends(get_db)):
    students = db.query(User).filter(User.role == "Student").all()
    return [
        {
            "user_id": student.user_id,
            "student_number": student.student_number, # Added
            "full_name": student.full_name,           # Added
            "email": student.email,                   # Added
            "course": student.course,                 # Added
            "created_at": student.created_at.isoformat() if student.created_at else None, # Added
            "role": student.role, 
            "is_active": student.is_active
        }
        for student in students
    ]

@app.put("/api/admin/students/{student_id}/toggle")
def toggle_student(student_id: str, db: Session = Depends(get_db)):
    student = db.query(User).filter(User.user_id == student_id).first()

    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
        
    # FIX: Use simple string comparison here
    if student.role != "Student":
        raise HTTPException(status_code=400, detail="Cannot modify admin account")

    student.is_active = not student.is_active
    db.commit()

    return {
        "message": "Student status updated",
        "user_id": student.user_id,
        "is_active": student.is_active
    }

@app.post("/api/register")
def register(request: RegisterRequest, db: Session = Depends(get_db)):
    # 1. Check if email or student number already exists
    if db.query(User).filter(User.email == request.email).first():
        raise HTTPException(status_code=400, detail="Email is already registered")
    
    if db.query(User).filter(User.student_number == request.student_number).first():
        raise HTTPException(status_code=400, detail="Student number is already registered")
    
    raw_password = request.password
    if len(raw_password.encode('utf-8')) > 72:
        raw_password = raw_password[:72]
    
    # 2. Securely hash the password
    hashed_password = pwd_context.hash(request.password)
    
    # 3. Create the new user object
    new_user = User(
        student_number=request.student_number,
        full_name=request.full_name,
        email=request.email,
        course=request.course,
        password_hash=hashed_password,
        is_active=True
    )
    
    # 4. Save to the database
    db.add(new_user)
    db.commit()
    
    return {"message": "Registration successful! You can now log in."}

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

@app.get("/api/candidates")
def get_candidates(db: Session = Depends(get_db)):

    candidates = db.query(Candidate).all()

    return [
        {
            "candidate_id": c.candidate_id,
            "poll_id": c.poll_id,
            "name": c.name,
            "position": c.position,
            "party_name": c.party_name,
            "course_year": c.course_year,
            "description_platform": c.description_platform,
            "photo_url": c.photo_url
        }
        for c in candidates
    ]
    
@app.put("/api/candidates/{candidate_id}")
def update_candidate(candidate_id: int, candidate_update: CandidateUpdate, db: Session = Depends(get_db)):
    db_candidate = db.query(Candidate).filter(Candidate.candidate_id == candidate_id).first()
    
    if not db_candidate:
        raise HTTPException(status_code=404, detail="Candidate not found")

    # Update only the fields that were provided
    update_data = candidate_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_candidate, key, value)

    db.commit()
    db.refresh(db_candidate)
    
    return {"message": "Candidate updated successfully"}

@app.get("/api/candidates/{poll_id}")
def get_candidates(poll_id: int, db: Session = Depends(get_db)):
    candidates = db.query(Candidate).filter(
        Candidate.poll_id == poll_id
    ).all()
    return candidates

@app.delete("/api/candidates/{candidate_id}")
def delete_candidate(candidate_id: int, db: Session = Depends(get_db)):
    candidate = db.query(Candidate).filter(
        Candidate.candidate_id == candidate_id
    ).first()

    if not candidate:
        raise HTTPException(status_code=404, detail="Candidate not found")

    db.delete(candidate)
    db.commit()

    return {"message": "Candidate deleted successfully"}

@app.post("/api/vote")
def submit_vote(vote: VoteRequest, user_id: int = Depends(get_current_user_id), db: Session = Depends(get_db)):
    # 1. Securely check if the user already voted in this specific poll
    existing_vote = db.query(Vote).filter(
        Vote.user_id == user_id,
        Vote.poll_id == vote.poll_id
    ).first()

    if existing_vote:
        raise HTTPException(status_code=403, detail="User already voted")

    # 2. If no duplicate found, insert the votes
    for candidate_id in vote.candidate_ids:
        new_vote = Vote(
            user_id=user_id,
            poll_id=vote.poll_id,
            candidate_id=candidate_id
        )
        db.add(new_vote)

    db.commit()
    return {"message": "Vote recorded successfully"}

@app.get("/api/vote/status/{poll_id}")
def check_vote_status(poll_id: int, user_id: int = Depends(get_current_user_id), db: Session = Depends(get_db)):
    # Check if a vote record already exists for this user in this poll
    existing_vote = db.query(Vote).filter(
        Vote.user_id == user_id,
        Vote.poll_id == poll_id
    ).first()
    
    return {"has_voted": existing_vote is not None}

@app.get("/api/polls/{poll_id}/candidates")
def get_candidates_by_poll(poll_id: int, db: Session = Depends(get_db)):

    candidates = db.query(Candidate).filter(
        Candidate.poll_id == poll_id
    ).all()

    positions = {}

    for c in candidates:

        if c.position not in positions:
            positions[c.position] = []

        positions[c.position].append({
            "candidate_id": c.candidate_id,
            "name": c.name,
            "party": c.party,
            "bio": c.bio,
            "photo": c.photo_url
        })

    return positions

@app.route('/api/candidates', methods=['GET'])
def get_candidates():

    cursor = get_db.connection.cursor()

    cursor.execute("""
        SELECT candidate_id, name, position
        FROM candidates
        ORDER BY position
    """)

    rows = cursor.fetchall()

    candidates = {}

    for row in rows:
        candidate_id, name, position = row

        if position not in candidates:
            candidates[position] = []

        candidates[position].append({
            "id": candidate_id,
            "name": name
        })

    return jsonify(candidates)

