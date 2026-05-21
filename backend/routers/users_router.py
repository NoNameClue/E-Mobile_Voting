from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy.orm import Session
from sqlalchemy import or_, desc
from database import get_db
from models import User, StaffApplication
from pydantic import BaseModel
from typing import Optional, List
from auth import pwd_context, get_current_user

router = APIRouter(tags=["Users", "Staff Applications"])

class UserAdminUpdate(BaseModel):
    course: Optional[str] = None
    password: Optional[str] = None
    is_student_officer: Optional[bool] = None
    permissions: Optional[List[str]] = None

class ApplicationSubmit(BaseModel):
    intent_statement: str
    experience: str
    availability: str

class ApplicationReview(BaseModel):
    status: str 

@router.get("/api/users")
def get_all_users(db: Session = Depends(get_db)):
    users = db.query(User).all()
    return [{**u.__dict__, "full_name": f"{u.first_name} {u.middle_name} {u.last_name}".replace("  ", " ").strip()} for u in users]

@router.get("/api/admin/students")
def get_paginated_students(
    skip: int = Query(0, description="How many records to skip"),
    limit: int = Query(20, description="How many records to return"),
    search: str = Query(None, description="Search by name or ID"),
    db: Session = Depends(get_db)
):
    query = db.query(User).filter(User.role == "Student")
    if search:
        search_term = f"%{search}%"
        query = query.filter(or_(User.student_number.like(search_term), User.first_name.like(search_term), User.last_name.like(search_term)))
    
    query = query.order_by(User.created_at.desc())
    total_count = query.count()
    students = query.offset(skip).limit(limit).all()
    
    results = [
        {
            "user_id": s.user_id,
            "full_name": f"{s.first_name} {s.middle_name} {s.last_name}".replace("  ", " ").strip(),
            "student_number": s.student_number,
            "course": s.course,
            "is_active": s.is_active,
            "created_at": s.created_at.isoformat() if s.created_at else None,
            "profile_pic_url": s.profile_pic_url,
            "is_student_officer": getattr(s, 'is_student_officer', False),
            "permissions": getattr(s, 'permissions', [])
        } for s in students
    ]
    return {"total": total_count, "items": results}

@router.put("/api/admin/students/{user_id}/toggle")
async def toggle_student_status(user_id: int, request: Request, db: Session = Depends(get_db)):
    student = db.query(User).filter(User.user_id == user_id, User.role == "Student").first()
    if not student: raise HTTPException(status_code=404, detail="Student not found")
    
    try:
        data = await request.json()
        if "is_active" in data: student.is_active = bool(data["is_active"])
        elif "status" in data: student.is_active = bool(data["status"])
        else: student.is_active = not student.is_active
    except Exception:
        student.is_active = not student.is_active

    db.commit()
    return {"message": f"Status updated successfully to {student.is_active}"}

@router.put("/api/admin/users/{user_id}")
def update_user_admin(user_id: int, update_data: UserAdminUpdate, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.user_id == user_id).first()
    if not db_user: raise HTTPException(status_code=404, detail="User not found")
    
    if update_data.course is not None: db_user.course = update_data.course
    if update_data.password: db_user.password_hash = pwd_context.hash(update_data.password)
    if update_data.is_student_officer is not None: db_user.is_student_officer = update_data.is_student_officer
    if update_data.permissions is not None: db_user.permissions = update_data.permissions
        
    db.commit()
    return {"message": "User updated successfully"}


# ==========================================
# 🚀 STUDENT OFFICER APPLICATION ROUTES 
# ==========================================

@router.post("/api/students/apply-staff")
def submit_staff_application(app_data: ApplicationSubmit, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    existing = db.query(StaffApplication).filter(StaffApplication.user_id == current_user.user_id, StaffApplication.status == "Pending").first()
    if existing:
        raise HTTPException(status_code=400, detail="You already have a pending application.")
        
    new_app = StaffApplication(
        user_id=current_user.user_id,
        intent_statement=app_data.intent_statement,
        experience=app_data.experience,
        availability=app_data.availability
    )
    db.add(new_app)
    db.commit()
    return {"message": "Application submitted successfully"}

@router.get("/api/students/apply-staff/status")
def check_application_status(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    # 🚀 CRITICAL FIX: Forces SQLAlchemy to get the absolute newest data from the DB, ignoring cached sessions
    db.refresh(current_user) 
    
    is_officer = getattr(current_user, 'is_student_officer', False)
    latest_app = db.query(StaffApplication).filter(StaffApplication.user_id == current_user.user_id).order_by(desc(StaffApplication.applied_at)).first()
    
    if not latest_app:
        return {"status": "None"}
        
    # 🛠️ BUG FIX: If Admin accepted them originally, but later revoked the role in Manage Users
    if latest_app.status == "Accepted" and not is_officer:
        return {"status": "None"}
        
    if is_officer:
        return {"status": "Accepted"}
        
    return {"status": latest_app.status, "applied_at": latest_app.applied_at}

@router.get("/api/admin/staff-applications")
def get_all_applications(db: Session = Depends(get_db)):
    apps = db.query(StaffApplication, User).join(User).filter(StaffApplication.status == "Pending").order_by(StaffApplication.applied_at.asc()).all()
    
    results = []
    for app, user in apps:
        results.append({
            "application_id": app.application_id,
            "user_id": user.user_id,
            "full_name": f"{user.first_name} {user.middle_name} {user.last_name}".replace("  ", " ").strip(),
            "student_number": user.student_number,
            "course": user.course,
            "profile_pic_url": user.profile_pic_url,
            "intent_statement": app.intent_statement,
            "experience": app.experience,
            "availability": app.availability,
            "applied_at": app.applied_at.isoformat()
        })
    return results

@router.put("/api/admin/staff-applications/{application_id}")
def review_application(application_id: int, review: ApplicationReview, db: Session = Depends(get_db)):
    app = db.query(StaffApplication).filter(StaffApplication.application_id == application_id).first()
    if not app:
        raise HTTPException(status_code=404, detail="Application not found")
        
    app.status = review.status
    
    if review.status == "Accepted":
        user = db.query(User).filter(User.user_id == app.user_id).first()
        if user:
            user.is_student_officer = True
            user.permissions = ["Dashboard"]
            
    db.commit()
    return {"message": f"Application {review.status.lower()}"}