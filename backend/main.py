from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, Integer, String, Boolean, Enum as SQLEnum
from sqlalchemy.orm import sessionmaker, Session, declarative_base
from passlib.context import CryptContext
import jwt
import enum
from datetime import datetime, timedelta

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

Base.metadata.create_all(bind=engine)

# Dependency to get DB session securely
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

class UserCreate(BaseModel):
    user_id: str
    password: str

# ==========================================
# 3. API ENDPOINTS
# ==========================================

@app.post("/api/register")
def register(request: RegisterRequest, db: Session = Depends(get_db)):
    # 1. Check if email or student number already exists to prevent crashes
    if db.query(User).filter(User.email == request.email).first():
        raise HTTPException(status_code=400, detail="Email is already registered")
    
    if db.query(User).filter(User.student_number == request.student_number).first():
        raise HTTPException(status_code=400, detail="Student number is already registered")
    
    raw_password = request.password
    if len(raw_password.encode('utf-8')) > 72:
        raw_password = raw_password[:72]
    
    # 2. Securely hash the password (Never save plain text!)
    hashed_password = pwd_context.hash(request.password)
    
    # 3. Create the new user object
    # Notice we don't pass 'user_id', 'role', or 'is_active' because MySQL handles defaults!
    new_user = User(
        student_number=request.student_number,
        full_name=request.full_name,
        email=request.email,
        course=request.course,
        password_hash=hashed_password
    )
    
    # 4. Save to the database
    db.add(new_user)
    db.commit()
    
    return {"message": "Registration successful! You can now log in."}

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