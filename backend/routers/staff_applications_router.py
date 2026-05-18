from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import get_db
from models import User, StaffApplication
from schemas import StaffApplicationCreate
from auth import get_current_user

router = APIRouter(tags=["Staff Applications"])


# =========================================================
# STUDENT SUBMITS APPLICATION
# =========================================================
@router.post("/api/staff-applications")
def apply_for_staff(
    application: StaffApplicationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Prevent staff/admin from applying again
    if current_user.role in ["Admin", "Staff"]:
        raise HTTPException(
            status_code=400,
            detail="You already have a staff/admin role."
        )

    existing = db.query(StaffApplication).filter(
        StaffApplication.user_id == current_user.user_id,
        StaffApplication.status == "Pending"
    ).first()

    if existing:
        raise HTTPException(
            status_code=400,
            detail="You already have a pending application."
        )

    new_application = StaffApplication(
        user_id=current_user.user_id,
        intent=application.intent,
        qualifications=application.qualifications,
        status="Pending"
    )

    db.add(new_application)
    db.commit()

    return {"message": "Application submitted successfully"}
    

# =========================================================
# ADMIN FETCH APPLICATIONS
# =========================================================
@router.get("/api/staff-applications")
def get_staff_applications(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in ["Admin"]:
        raise HTTPException(status_code=403, detail="Unauthorized")

    applications = db.query(StaffApplication).all()

    results = []

    for app in applications:
        results.append({
            "application_id": app.application_id,
            "student_name": f"{app.user.first_name} {app.user.middle_name} {app.user.last_name}",
            "student_number": app.user.student_number,
            "intent": app.intent,
            "qualifications": app.qualifications,
            "status": app.status
        })

    return results


# =========================================================
# ADMIN APPROVES APPLICATION
# =========================================================
@router.put("/api/staff-applications/{application_id}/approve")
def approve_application(
    application_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):

    # CHECK ROLE
    if "Admin" not in current_user.role and "Staff" not in current_user.role:
        raise HTTPException(status_code=403, detail="Unauthorized")

    application = db.query(StaffApplication).filter(
        StaffApplication.application_id == application_id
    ).first()

    if not application:
        raise HTTPException(status_code=404, detail="Application not found")

    application.status = "Approved"

    db.commit()

    return {
        "message": "Application approved"
    }

@router.put("/api/staff-applications/{application_id}/decline")
def decline_application(
    application_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):

    # CHECK ROLE
    if "Admin" not in current_user.role and "Staff" not in current_user.role:
        raise HTTPException(status_code=403, detail="Unauthorized")

    application = db.query(StaffApplication).filter(
        StaffApplication.application_id == application_id
    ).first()

    if not application:
        raise HTTPException(status_code=404, detail="Application not found")

    application.status = "Declined"

    db.commit()

    return {
        "message": "Application declined"
    }

@router.get("/my-application")
def get_my_application(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    application = db.query(StaffApplication).filter(
        StaffApplication.user_id == current_user.user_id
    ).first()

    if not application:
        raise HTTPException(status_code=404, detail="No application")

    return {
        "application_id": application.application_id,
        "status": application.status,
    }

@router.get("/api/staff-applications/my-application")
def get_my_application(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):

    application = db.query(StaffApplication).filter(
        StaffApplication.user_id == current_user.user_id
    ).first()

    if not application:
        raise HTTPException(
            status_code=404,
            detail="No application found"
        )

    return {
        "application_id": application.application_id,
        "status": application.status,
        "intent": application.intent,
        "qualifications": application.qualifications
    }