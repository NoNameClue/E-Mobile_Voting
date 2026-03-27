import os
import shutil
import time
from fastapi import Security, FastAPI, HTTPException, Depends, File, UploadFile, Form
from sqlalchemy import create_engine, Column, Integer, String, Boolean, DateTime, Enum as SQLEnum, JSON
from fastapi.staticfiles import StaticFiles
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
# Create uploads folder if it doesn't exist
os.makedirs("uploads", exist_ok=True)
# Mount it so images can be accessed publicly via /uploads/filename.jpg
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")
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
    
    # --- UPDATED: Added 'Staff' to Enum ---
    role = Column(SQLEnum('Admin', 'Student', 'Staff'), default='Student') 
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow) 
    profile_pic_url = Column(String(255), nullable=True)
    
    # --- ADDED: Permissions column ---
    permissions = Column(JSON, default=[])

# --- POLL MODEL (UPDATED FOR PUBLISHING) ---
class Poll(Base):
    __tablename__ = "polls"
    poll_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    title = Column(String(255), nullable=False)
    start_time = Column(DateTime, nullable=False)
    end_time = Column(DateTime, nullable=False)
    status = Column(String(50), default="Draft")          # Changed to Draft
    is_published = Column(Boolean, default=False)         # <--- NEW FIELD
    is_archived = Column(Boolean, default=False)          # <--- NEW FIELD

# --- PYDANTIC SCHEMAS ---
class LoginRequest(BaseModel):
    email: str
    password: str

class StaffCreate(BaseModel):
    full_name: str
    email: str
    password: str

class PermissionsUpdate(BaseModel):
    permissions: list[str]
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

class Party(Base):
    __tablename__ = "parties"
    party_id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, nullable=False)

class PartyCreate(BaseModel):
    name: str

# ==========================================
# 3. API ENDPOINTS
# ==========================================

# --- POLL ENDPOINTS ---
@app.get("/api/polls")
def get_polls(db: Session = Depends(get_db)):
    polls = db.query(Poll).all()
    current_time = datetime.utcnow()
    
    for p in polls:
        # Automatically expire polls if end_time has passed
        if p.end_time < current_time and p.status != "Ended":
            p.status = "Ended"
            db.commit()
            db.refresh(p)
            
    return polls

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

@app.get("/api/polls/{poll_id}/summary")
def get_poll_summary(poll_id: int, db: Session = Depends(get_db)):
    total_candidates = db.query(Candidate).filter(Candidate.poll_id == poll_id).count()
    parties_count = db.query(func.count(func.distinct(Candidate.party_name))).filter(Candidate.poll_id == poll_id).scalar()
    
    return {
        "total_candidates": total_candidates,
        "total_parties": parties_count or 0
    }

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
            "is_active": student.is_active,
            "profile_pic_url": student.profile_pic_url # <--- ADD THIS EXACT LINE
        }
        for student in students
    ]

@app.get("/api/users")
def get_all_users(db: Session = Depends(get_db)):
    # This fetches everyone from the database table you just showed me
    users = db.query(User).all()
    return users
    
@app.get("/api/users/me")
def get_user_profile(user_id: int = Depends(get_current_user_id), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return {
        "full_name": user.full_name,
        "student_number": user.student_number,
        "profile_pic_url": user.profile_pic_url
    }

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
async def register(
    student_number: str = Form(...),
    full_name: str = Form(...),
    email: str = Form(...),
    course: str = Form(...),
    password: str = Form(...),
    photo: Optional[UploadFile] = File(None), # <--- ADDED
    db: Session = Depends(get_db)
):
    if db.query(User).filter(User.email == email).first():
        raise HTTPException(status_code=400, detail="Email is already registered")
    if db.query(User).filter(User.student_number == student_number).first():
        raise HTTPException(status_code=400, detail="Student number is already registered")
    
    photo_url = None
    if photo and photo.filename:
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        safe_filename = photo.filename.replace(" ", "_")
        file_path = f"uploads/user_{timestamp}_{safe_filename}"
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(photo.file, buffer)
        photo_url = file_path

    hashed_password = pwd_context.hash(password)
    
    new_user = User(
        student_number=student_number,
        full_name=full_name,
        email=email,
        course=course,
        password_hash=hashed_password,
        profile_pic_url=photo_url, # <--- ADDED
        is_active=True
    )
    
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
    
    access_token_payload = {
    "sub": user.email,
    "role": user.role,
    "permissions": user.permissions if user.permissions else [] 
}

    # 4. Generate the secure JWT Session Token
    expire = datetime.utcnow() + timedelta(hours=2) # Token lasts 2 hours
    user_perms = user.permissions if user.permissions is not None else []
    token_data = {
        "sub": str(user.user_id),
        "email": user.email,
        "role": user.role,
        "permissions": user_perms, # <--- VERIFY THIS LINE
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
async def update_candidate(
    candidate_id: int, 
    name: str = Form(...),
    party_name: str = Form(...),
    course_year: str = Form(...),
    description_platform: str = Form(""),
    photo: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db)
):
    db_candidate = db.query(Candidate).filter(Candidate.candidate_id == candidate_id).first()
    if not db_candidate:
        raise HTTPException(status_code=404, detail="Candidate not found")

    db_candidate.name = name
    db_candidate.party_name = party_name
    db_candidate.course_year = course_year
    db_candidate.description_platform = description_platform

    if photo and photo.filename:
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        safe_filename = photo.filename.replace(" ", "_")
        file_path = f"uploads/{timestamp}_{safe_filename}"
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(photo.file, buffer)
        db_candidate.photo_url = file_path

    db.commit()
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

@app.get("/api/polls/{poll_id}/report")
def get_poll_report(poll_id: int, db: Session = Depends(get_db)):
    # 1. Total Active Students (Eligible Voters base)
    total_active_students = db.query(User).filter(
        User.role == "Student", 
        User.is_active == True
    ).count()

    # 2. Total Turnout (STRICTLY counts ONLY votes from currently active users)
    total_voters = db.query(Vote.user_id).join(
        User, Vote.user_id == User.user_id
    ).filter(
        Vote.poll_id == poll_id,
        User.is_active == True  # <--- Strips out deactivated accounts' votes
    ).distinct().count()

    turnout_percentage = (total_voters / total_active_students * 100) if total_active_students > 0 else 0.0

    # 3. Get Vote Counts per candidate (STRICTLY from active users only)
    active_votes = db.query(
        Vote.candidate_id, 
        func.count(Vote.vote_id).label('count')
    ).join(
        User, Vote.user_id == User.user_id
    ).filter(
        Vote.poll_id == poll_id,
        User.is_active == True  # <--- Prevents deactivated users from inflating candidate scores
    ).group_by(Vote.candidate_id).all()
    
    # Create a quick dictionary to map candidate_id -> total active votes
    vote_dict = {cand_id: count for cand_id, count in active_votes}

    # Fetch all candidates assigned to this poll
    candidates = db.query(Candidate).filter(Candidate.poll_id == poll_id).all()

    # 4. Group by Position
    positions_data = {}
    for cand in candidates:
        if cand.position not in positions_data:
            positions_data[cand.position] = []
        
        # If they have no active votes, it defaults to 0
        c_votes = vote_dict.get(cand.candidate_id, 0)
        
        positions_data[cand.position].append({
            "candidate_id": cand.candidate_id,
            "name": cand.name,
            "party_name": cand.party_name,
            "votes": c_votes
        })

    # 5. Process math for each position (Winner, Margin, Percentages)
    report_details = []
    for pos, cands in positions_data.items():
        # Sort descending by votes
        cands.sort(key=lambda x: x["votes"], reverse=True)
        total_pos_votes = sum(c["votes"] for c in cands)
        
        processed_cands = []
        for i, c in enumerate(cands):
            pct = (c["votes"] / total_pos_votes * 100) if total_pos_votes > 0 else 0.0
            
            # Margin calculation (Winner vs 2nd place)
            margin = 0.0
            if i == 0 and len(cands) > 1: # If this is the winner
                runner_up_pct = (cands[1]["votes"] / total_pos_votes * 100) if total_pos_votes > 0 else 0.0
                margin = pct - runner_up_pct

            processed_cands.append({
                "rank": i + 1,
                "name": c["name"],
                "party_name": c["party_name"],
                "votes": c["votes"],
                "percentage": round(pct, 2),
                "is_winner": i == 0 and c["votes"] > 0, # Winner if they have at least 1 vote
                "margin": round(margin, 2) if i == 0 else None
            })
        
        report_details.append({
            "position": pos,
            "total_votes": total_pos_votes,
            "candidates": processed_cands
        })

    return {
        "summary": {
            "total_active_students": total_active_students,
            "total_voters": total_voters,
            "turnout_percentage": round(turnout_percentage, 2)
        },
        "results": report_details
    }

@app.post("/api/parties")
def create_party(party: PartyCreate, db: Session = Depends(get_db)):
    if not party.name or not party.name.strip():
        raise HTTPException(status_code=400, detail="Party name cannot be empty.")
    
    # Check for duplicates
    existing_party = db.query(Party).filter(func.lower(Party.name) == party.name.lower().strip()).first()
    if existing_party:
        raise HTTPException(status_code=400, detail="Error: A party with this name already exists.")
    
    new_party = Party(name=party.name.strip())
    db.add(new_party)
    db.commit()
    
    return {"message": "Party created successfully"}

@app.get("/api/parties/lineups")
def get_party_lineups(db: Session = Depends(get_db)):
    parties = db.query(Party).all()
    # Standard positions to check against
    standard_positions = ["President", "Vice President", "Secretary", "Treasurer", "Auditor", "PIO"]
    
    results = []
    for p in parties:
        # Fetch all candidates currently claiming this party name
        cands = db.query(Candidate).filter(Candidate.party_name == p.name).all()
        
        # Build the lineup dictionary with default nulls
        lineup = {pos: None for pos in standard_positions}
        
        for c in cands:
            if c.position in lineup:
                lineup[c.position] = c.name
                
        results.append({
            "party_id": p.party_id,
            "party_name": p.name,
            "lineup": lineup
        })
        
    return results

@app.delete("/api/parties/{party_id}")
def delete_party(party_id: int, db: Session = Depends(get_db)):
    party_to_delete = db.query(Party).filter(Party.party_id == party_id).first()
    
    if not party_to_delete:
        raise HTTPException(status_code=404, detail="Party not found.")
        
    # Prevent deletion of the default 'Independent' party
    if party_to_delete.name.lower() == "independent":
        raise HTTPException(status_code=403, detail="Cannot delete the Independent party.")

    # 1. Safely migrate existing candidates to 'Independent'
    db.query(Candidate).filter(Candidate.party_name == party_to_delete.name).update(
        {"party_name": "Independent"}, synchronize_session=False
    )
    
    # 2. Delete the party
    db.delete(party_to_delete)
    db.commit()
    
    return {"message": "Party deleted and candidates migrated to Independent."}

@app.post("/api/candidates")
async def register_candidate(
    poll_id: int = Form(...),
    name: str = Form(...),
    position: str = Form(...),
    party_name: str = Form(...),
    course_year: str = Form(...),
    description_platform: Optional[str] = Form(None),
    photo: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db)
):
    # 1. Validation Check: No duplicate positions in the same party (except Independent)
    if party_name.lower() != "independent":
        existing = db.query(Candidate).filter(
            Candidate.poll_id == poll_id,
            Candidate.party_name == party_name,
            Candidate.position == position
        ).first()

        if existing:
            raise HTTPException(status_code=400, detail=f"The {party_name} already has a {position} registered.")

    # 2. Handle Photo Upload
    photo_url = None
    if photo and photo.filename:
        from datetime import datetime
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        safe_filename = photo.filename.replace(" ", "_")
        file_path = f"uploads/{timestamp}_{safe_filename}"

        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(photo.file, buffer)

        # Store the URL path in the database
        photo_url = f"{file_path}"

    # 3. Save to Database
    new_candidate = Candidate(
        poll_id=poll_id,
        name=name,
        position=position,
        party_name=party_name,
        course_year=course_year,
        description_platform=description_platform, # or 'bio' depending on your exact SQLAlchemy model name
        photo_url=photo_url
    )

    db.add(new_candidate)
    db.commit()

    return {"message": "Candidate registered successfully!"}

@app.get("/api/users/me/votes")
def get_my_votes(user_id: int = Depends(get_current_user_id), db: Session = Depends(get_db)):
    
    # Using SQLAlchemy ORM safely joins the tables and prevents raw SQL column errors
    results = db.query(Vote, Candidate, Poll).join(
        Candidate, Vote.candidate_id == Candidate.candidate_id
    ).join(
        Poll, Vote.poll_id == Poll.poll_id
    ).filter(
        Vote.user_id == user_id
    ).order_by(
        Poll.poll_id.desc()
    ).all()

    polls = {}

    for vote, candidate, poll in results:
        poll_id = poll.poll_id

        if poll_id not in polls:
            polls[poll_id] = {
                "poll_id": poll_id,
                "poll_title": poll.title,
                "candidates": []
            }

        # Format exactly as Flutter expects it
        polls[poll_id]["candidates"].append({
            "name": candidate.name,
            "position": candidate.position,
            "party": candidate.party_name, # Map DB column 'party_name' to Flutter's 'party'
            "photo": candidate.photo_url   # Map DB column 'photo_url' to Flutter's 'photo'
        })

    return list(polls.values())

@app.put("/api/polls/{poll_id}/archive")
def archive_poll(poll_id: int, db: Session = Depends(get_db)):
    poll = db.query(Poll).filter(Poll.poll_id == poll_id).first()
    if not poll:
        raise HTTPException(status_code=404, detail="Poll not found")
    if not poll.is_published:
        raise HTTPException(status_code=403, detail="Only published polls can be archived")
    poll.is_archived = True
    db.commit()

    return {"message": "Poll archived successfully."}

@app.put("/api/polls/{poll_id}/unarchive")
def unarchive_poll(poll_id: int, db: Session = Depends(get_db)):
    poll = db.query(Poll).filter(Poll.poll_id == poll_id).first()
    if not poll:
        raise HTTPException(status_code=404, detail="Poll not found")
    
    # Only allow unarchiving if it was previously archived
    if not poll.is_archived:
        raise HTTPException(status_code=400, detail="Poll is not archived")
    
    poll.is_archived = False
    db.commit()
    
    return {"message": "Poll unarchived successfully."}

from typing import List

class StaffCreate(BaseModel):
    full_name: str
    email: str
    password: str

class PermissionsUpdate(BaseModel):
    permissions: List[str]

# 1. Fetch all Staff
@app.get("/api/officers")
def get_officers(db: Session = Depends(get_db)):
    officers = db.query(User).filter(User.role == "Staff").all()
    # Format to match frontend expectations
    return [
        {
            "user_id": o.user_id, 
            "full_name": o.full_name, 
            "email": o.email, 
            "permissions": o.permissions if o.permissions else [],
            "profile_pic_url": o.profile_pic_url
        } 
        for o in officers
    ]

# 2. Create a new Staff Member (Updated for Image Upload)
@app.post("/api/officers")
async def create_staff(
    full_name: str = Form(...),
    email: str = Form(...),
    password: str = Form(...),
    photo: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db)
):
    if db.query(User).filter(User.email == email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    
    hashed_password = pwd_context.hash(password)
    dummy_id = f"STAFF-{int(time.time())}"
    
    photo_url = None
    if photo and photo.filename:
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        safe_filename = photo.filename.replace(" ", "_")
        file_path = f"uploads/staff_{timestamp}_{safe_filename}"
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(photo.file, buffer)
        photo_url = file_path
    
    new_staff = User(
        student_number=dummy_id,
        full_name=full_name,
        email=email,
        course="N/A (Staff)",
        password_hash=hashed_password,
        role="Staff",
        permissions=[],
        profile_pic_url=photo_url
    )
    db.add(new_staff)
    db.commit()
    return {"message": "Staff member created successfully"}

# 3. Edit/Update Staff Details
@app.put("/api/officers/{user_id}")
async def update_staff(
    user_id: int,
    full_name: str = Form(...),
    email: str = Form(...),
    password: Optional[str] = Form(None), # Optional password update
    photo: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.user_id == user_id, User.role == "Staff").first()
    if not user:
        raise HTTPException(status_code=404, detail="Staff not found")
        
    # Check if they are changing to an email that is already taken by someone else
    if email != user.email:
        existing = db.query(User).filter(User.email == email).first()
        if existing:
            raise HTTPException(status_code=400, detail="Email already in use")

    user.full_name = full_name
    user.email = email
    
    if password and password.strip():
        user.password_hash = pwd_context.hash(password)
        
    if photo and photo.filename:
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        safe_filename = photo.filename.replace(" ", "_")
        file_path = f"uploads/staff_{timestamp}_{safe_filename}"
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(photo.file, buffer)
        user.profile_pic_url = file_path

    db.commit()
    return {"message": "Staff updated successfully"}

# 4. Delete Staff Member
@app.delete("/api/officers/{user_id}")
def delete_staff(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.user_id == user_id, User.role == "Staff").first()
    if not user:
        raise HTTPException(status_code=404, detail="Staff not found")
        
    db.delete(user)
    db.commit()
    return {"message": "Staff deleted successfully"}

# 5. Update Staff Permissions
@app.put("/api/officers/{user_id}/permissions")
def update_permissions(user_id: int, perms: PermissionsUpdate, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.user_id == user_id, User.role == "Staff").first()
    if not user:
        raise HTTPException(status_code=404, detail="Staff not found")
    
    user.permissions = perms.permissions
    db.commit()
    return {"message": "Permissions updated successfully"}