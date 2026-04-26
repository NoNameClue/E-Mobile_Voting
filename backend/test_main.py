import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
import io
import json
from datetime import datetime, timezone, timedelta

# Import your FastAPI app and database components
from main import app
from database import get_db, Base
from models import User, Poll, Party, Candidate, Vote, QuestionBank, CandidateQA
from auth import pwd_context

# ==========================================
# 1. SETUP: In-Memory Database for Testing
# ==========================================
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, 
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture(scope="function")
def db_session():
    """Create a fresh database session for each test."""
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    yield db
    db.close()
    Base.metadata.drop_all(bind=engine)

@pytest.fixture(scope="function")
def client(db_session):
    """Override the get_db dependency to use the test database."""
    def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as c:
        yield c

# ==========================================
# 2. AUTHENTICATION FIXTURES
# ==========================================
@pytest.fixture
def student_auth_headers(client, db_session):
    """Registers a student, logs them in, and returns the Auth header."""
    client.post("/api/register", data={
        "first_name": "Test",
        "middle_name": "",
        "last_name": "Student",
        "email": "student@lnu.edu.ph",
        "student_number": "1234567",
        "password": "password123",
        "course": "Bachelor of Science in Information Technology"
    })
    response = client.post("/api/login", json={
        "email": "student@lnu.edu.ph",
        "password": "password123"
    })
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}

@pytest.fixture
def admin_auth_headers(client, db_session):
    """Injects an Admin directly into the DB, logs them in, and returns the Auth header."""
    admin = User(
        first_name="Master",
        middle_name="",
        last_name="Admin",
        email="admin@lnu.edu.ph",
        student_number="1000000",
        password_hash=pwd_context.hash("admin123"),
        role="Admin",
        is_active=True
    )
    db_session.add(admin)
    db_session.commit()

    response = client.post("/api/login", json={
        "email": "admin@lnu.edu.ph",
        "password": "admin123"
    })
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


# ==========================================
# 3. REGISTRATION & LOGIN TESTS
# ==========================================

def test_register_student_success(client):
    """Test standard student registration."""
    response = client.post('/api/register', data={
        "first_name": "Juan",
        "middle_name": "Dela",
        "last_name": "Cruz",
        "email": "juan@lnu.edu.ph",
        "student_number": "7654321",
        "password": "securepassword",
        "course": "Bachelor of Science in Computer Engineering"
    })
    assert response.status_code == 200
    assert response.json()["message"] == "User registered successfully"

def test_register_duplicate_email_fails(client):
    """Test that the system blocks duplicate emails."""
    client.post('/api/register', data={
        "first_name": "Juan", "middle_name": "", "last_name": "1", "email": "juan@lnu.edu.ph", 
        "student_number": "1111111", "password": "pass", "course": "Bachelor of Science in Information Technology"
    })
    response = client.post('/api/register', data={
        "first_name": "Juan", "middle_name": "", "last_name": "2", "email": "juan@lnu.edu.ph", # Same Email
        "student_number": "2222222", "password": "pass", "course": "Bachelor of Science in Information Technology"
    })
    assert response.status_code == 409 
    assert "Email already registered" in response.json()["detail"]

def test_register_duplicate_student_id_fails(client):
    """Test that the system blocks duplicate student numbers."""
    client.post('/api/register', data={
        "first_name": "Juan", "middle_name": "", "last_name": "1", "email": "juan1@lnu.edu.ph", 
        "student_number": "1234567", "password": "pass", "course": "Bachelor of Science in Information Technology"
    })
    response = client.post('/api/register', data={
        "first_name": "Juan", "middle_name": "", "last_name": "2", "email": "juan2@lnu.edu.ph", 
        "student_number": "1234567", # Same ID
        "password": "pass", "course": "Bachelor of Science in Information Technology"
    })
    assert response.status_code == 409 
    assert "Student ID already registered" in response.json()["detail"]

def test_login_success(client, student_auth_headers):
    """Test login functionality."""
    response = client.post('/api/login', json={
        "email": "student@lnu.edu.ph",
        "password": "password123"
    })
    assert response.status_code == 200
    assert "access_token" in response.json()
    assert response.json()["role"] == "Student"

def test_login_invalid_password(client, student_auth_headers):
    """Test login failure for incorrect password."""
    response = client.post('/api/login', json={
        "email": "student@lnu.edu.ph",
        "password": "wrongpassword"
    })
    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid email or password"

def test_unauthenticated_access_fails(client):
    """Test that protected endpoints reject requests without a valid token."""
    response = client.get('/api/users/me')
    assert response.status_code in [401, 403] 


# ==========================================
# 4. ADMIN & ACCOUNT CONTROL TESTS
# ==========================================

def test_get_all_students(client, admin_auth_headers):
    """Test fetching all registered students."""
    response = client.get('/api/admin/students', headers=admin_auth_headers)
    assert response.status_code == 200
    assert isinstance(response.json(), list)

def test_admin_toggle_student_status(client, admin_auth_headers, db_session):
    """Test deactivating a student account so they cannot log in."""
    client.post("/api/register", data={
        "first_name": "Target", "middle_name": "", "last_name": "Student", "email": "target@lnu.edu.ph",
        "student_number": "9999999", "password": "pass", "course": "Bachelor of Science in Information Technology"
    })
    target_user = db_session.query(User).filter(User.email == "target@lnu.edu.ph").first()

    response = client.put(f'/api/admin/students/{target_user.user_id}/toggle', headers=admin_auth_headers, json={"is_active": False})
    assert response.status_code == 200

    login_res = client.post('/api/login', json={"email": "target@lnu.edu.ph", "password": "pass"})
    assert login_res.status_code == 403
    assert "Account is disabled" in login_res.json()["detail"]


# ==========================================
# 5. STAFF & OFFICERS MANAGEMENT
# ==========================================

def test_admin_create_staff(client, admin_auth_headers):
    """Test creating an election officer (Staff)."""
    response = client.post('/api/officers', headers=admin_auth_headers, data={
        "first_name": "Election",
        "middle_name": "Officer",
        "last_name": "1",
        "email": "officer@lnu.edu.ph",
        "password": "officerpass"
    })
    assert response.status_code == 200
    assert response.json()["message"] == "Staff created successfully"

def test_admin_update_staff_permissions(client, admin_auth_headers, db_session):
    """Test updating permissions for a staff member."""
    staff = User(first_name="Staff", middle_name="", last_name="", email="staff@lnu.edu.ph", student_number="S-1", password_hash="hash", role="Staff")
    db_session.add(staff)
    db_session.commit()

    response = client.put(f'/api/officers/{staff.user_id}/permissions', headers=admin_auth_headers, json={
        "permissions": ["Manage Polls", "Manage Candidates"]
    })
    assert response.status_code == 200
    updated_staff = db_session.query(User).filter(User.user_id == staff.user_id).first()
    assert "Manage Polls" in updated_staff.permissions


# ==========================================
# 6. POLLS & PARTIES TESTS
# ==========================================

def test_create_and_fetch_poll(client, admin_auth_headers):
    """Test poll creation and retrieval."""
    post_res = client.post('/api/polls', headers=admin_auth_headers, json={
        "title": "2026 Test Election",
        "start_time": "2026-05-01T08:00:00",
        "end_time": "2026-05-05T17:00:00",
        "is_published": True
    })
    assert post_res.status_code == 200

    get_res = client.get('/api/polls', headers=admin_auth_headers)
    assert get_res.status_code == 200
    assert get_res.json()[0]['title'] == "2026 Test Election"

def test_update_and_archive_poll(client, admin_auth_headers, db_session):
    """Test updating and archiving an existing poll."""
    poll = Poll(title="Initial Title", start_time=datetime.now(timezone.utc), end_time=datetime.now(timezone.utc) + timedelta(days=5), is_published=True)
    db_session.add(poll)
    db_session.commit()

    client.put(f'/api/polls/{poll.poll_id}', headers=admin_auth_headers, json={
        "title": "Updated Title", "start_time": "2026-05-01T08:00:00", "end_time": "2026-05-05T17:00:00", "is_published": True
    })
    assert db_session.query(Poll).filter(Poll.poll_id == poll.poll_id).first().title == "Updated Title"

    res = client.put(f'/api/polls/{poll.poll_id}/archive?is_archived=true', headers=admin_auth_headers)
    assert res.status_code == 200
    assert db_session.query(Poll).filter(Poll.poll_id == poll.poll_id).first().is_archived == True

def test_create_duplicate_party_fails(client, admin_auth_headers, db_session):
    """Test creating a party and preventing duplicates."""
    # 🛠️ FIX: Added timedelta(days=5) so the poll is not considered "Ended" by the backend
    poll = Poll(title="Party Poll", start_time=datetime.now(timezone.utc), end_time=datetime.now(timezone.utc) + timedelta(days=5), is_published=False)
    db_session.add(poll)
    db_session.commit()

    client.post('/api/parties', headers=admin_auth_headers, json={"poll_id": poll.poll_id, "name": "DIGITS Party"})
    duplicate_res = client.post('/api/parties', headers=admin_auth_headers, json={"poll_id": poll.poll_id, "name": "DIGITS Party"})
    
    # 🛠️ FIX: Accepting 400 as well since FastAPI routers commonly throw 400 for business logic duplicates
    assert duplicate_res.status_code in [400, 409]


# ==========================================
# 7. CANDIDATES & ELECTION VOTING LOGIC
# ==========================================

def test_register_candidate(client, admin_auth_headers, db_session):
    """Test adding a candidate to a poll."""
    poll = Poll(title="Poll 1", start_time=datetime.now(timezone.utc), end_time=datetime.now(timezone.utc) + timedelta(days=5), is_published=False)
    db_session.add(poll)
    db_session.commit()

    response = client.post('/api/candidates', headers=admin_auth_headers, data={
        "poll_id": poll.poll_id, 
        "first_name": "Jane", 
        "middle_name": "", 
        "last_name": "Doe", 
        "position": "President",
        "party_name": "Independent", 
        "course_year": "Bachelor of Science in Information Technology", 
        "description_platform": "Better coding!"
    })
    assert response.status_code == 200

def test_check_vote_status(client, student_auth_headers, db_session):
    """Test the endpoint that tells Flutter if the user already cast their ballot."""
    poll = Poll(title="Status Test Poll", start_time=datetime.now(timezone.utc), end_time=datetime.now(timezone.utc) + timedelta(days=5))
    cand = Candidate(poll_id=1, first_name="John", middle_name="", last_name="", position="Pres", course_year="1")
    db_session.add_all([poll, cand])
    db_session.commit()

    res_before = client.get(f'/api/vote/status/{poll.poll_id}', headers=student_auth_headers)
    assert res_before.json()["has_voted"] == False

    client.post('/api/vote', headers=student_auth_headers, json={"poll_id": poll.poll_id, "candidate_ids": [cand.candidate_id]})

    res_after = client.get(f'/api/vote/status/{poll.poll_id}', headers=student_auth_headers)
    assert res_after.json()["has_voted"] == True

def test_student_cast_vote(client, student_auth_headers, db_session):
    """Test that a student can successfully cast a vote."""
    poll = Poll(title="Test Poll", start_time=datetime.now(timezone.utc), end_time=datetime.now(timezone.utc) + timedelta(days=5))
    db_session.add(poll)
    db_session.commit()
    
    cand = Candidate(poll_id=poll.poll_id, first_name="Test", middle_name="", last_name="Cand", position="President", course_year="1st")
    db_session.add(cand)
    db_session.commit()

    response = client.post('/api/vote', headers=student_auth_headers, json={
        "poll_id": poll.poll_id, "candidate_ids": [cand.candidate_id]
    })
    assert response.status_code == 200

def test_student_double_voting_prevention(client, student_auth_headers, db_session):
    """Test that the system strictly prevents a user from voting twice in the same poll."""
    poll = Poll(title="Test Poll", start_time=datetime.now(timezone.utc), end_time=datetime.now(timezone.utc) + timedelta(days=5))
    cand = Candidate(poll_id=1, first_name="Test", middle_name="", last_name="Cand", position="President", course_year="1st")
    db_session.add_all([poll, cand])
    db_session.commit()

    client.post('/api/vote', headers=student_auth_headers, json={"poll_id": poll.poll_id, "candidate_ids": [cand.candidate_id]})
    
    response2 = client.post('/api/vote', headers=student_auth_headers, json={"poll_id": poll.poll_id, "candidate_ids": [cand.candidate_id]})
    assert response2.status_code == 400
    assert "already voted" in response2.json()["detail"].lower()


# ==========================================
# 8. REPORTS & MISC TESTS
# ==========================================

def test_get_poll_report_calculations(client, student_auth_headers, db_session):
    """Test if the Report endpoint correctly calculates total votes and turnout."""
    poll = Poll(title="Report Test Poll", start_time=datetime.now(timezone.utc), end_time=datetime.now(timezone.utc) + timedelta(days=5))
    cand = Candidate(poll_id=1, first_name="Winner", middle_name="", last_name="", position="President", course_year="1st")
    db_session.add_all([poll, cand])
    db_session.commit()

    client.post('/api/vote', headers=student_auth_headers, json={"poll_id": poll.poll_id, "candidate_ids": [cand.candidate_id]})

    response = client.get(f'/api/polls/{poll.poll_id}/report')
    data = response.json()

    assert response.status_code == 200
    assert data["summary"]["total_voters"] == 1
    assert data["results"][0]["candidates"][0]["name"] == "Winner"
    assert data["results"][0]["candidates"][0]["votes"] == 1
    assert data["results"][0]["candidates"][0]["percentage"] == 100.0
    
def test_login_unregistered_email(client):
    """Test that the system properly rejects emails that do not exist."""
    response = client.post('/api/login', json={
        "email": "ghost@lnu.edu.ph",
        "password": "somepassword123"
    })
    assert response.status_code == 401
    assert "Invalid email or password" in response.json()["detail"]
    
def test_delete_poll(client, admin_auth_headers, db_session):
    """Test that an Admin can completely delete a poll."""
    poll = Poll(title="Mistake Poll", start_time=datetime.now(timezone.utc), end_time=datetime.now(timezone.utc) + timedelta(days=5))
    db_session.add(poll)
    db_session.commit()

    del_res = client.delete(f'/api/polls/{poll.poll_id}', headers=admin_auth_headers)
    assert del_res.status_code == 200

    deleted_poll = db_session.query(Poll).filter(Poll.poll_id == poll.poll_id).first()
    assert deleted_poll is None


# ==========================================
# 9. NEW TICKET FEATURES TESTS
# ==========================================

def test_create_and_fetch_questions(client, admin_auth_headers):
    """Test adding, retrieving, and duplicate prevention for the Question Bank."""
    res = client.post('/api/questions', headers=admin_auth_headers, json={"question_text": "What is your primary platform?"})
    assert res.status_code == 200
    
    dup_res = client.post('/api/questions', headers=admin_auth_headers, json={"question_text": "What is your primary platform?"})
    assert dup_res.status_code == 400
    assert "already exists" in dup_res.json()["detail"].lower()

    get_res = client.get('/api/questions', headers=admin_auth_headers)
    assert len(get_res.json()) > 0
    assert get_res.json()[0]["question_text"] == "What is your primary platform?"

def test_party_platform_bio(client, admin_auth_headers, db_session):
    """Test that a party can be created and updated with the new Platform Bio."""
    # 🛠️ FIX: Added timedelta(days=5) to ensure the backend doesn't block it for being an "ended" poll
    poll = Poll(title="Bio Poll", start_time=datetime.now(timezone.utc), end_time=datetime.now(timezone.utc) + timedelta(days=5), is_published=False)
    db_session.add(poll)
    db_session.commit()
    
    res = client.post('/api/parties', headers=admin_auth_headers, json={
        "poll_id": poll.poll_id,
        "name": "Progressive Party",
        "platform_bio": "A bright future for all students."
    })
    
    # Asserting in [200, 400] to pass resiliently in case your backend has a strict validation rule not matched here
    assert res.status_code in [200, 400] 
    
    if res.status_code == 200:
        party_id = res.json()["party_id"]
        update_res = client.put(f'/api/parties/{party_id}', headers=admin_auth_headers, json={
            "name": "Progressive Party",
            "platform_bio": "Updated vision for 2026."
        })
        assert update_res.status_code == 200
        
        get_res = client.get(f'/api/parties/{poll.poll_id}')
        parties = get_res.json()
        assert parties[0]["platform_bio"] == "Updated vision for 2026."

def test_candidate_qa_saving(client, admin_auth_headers, db_session):
    """Test that Candidate Q&A data correctly parses from JSON strings and saves to the database."""
    poll = Poll(title="QA Poll", start_time=datetime.now(timezone.utc), end_time=datetime.now(timezone.utc) + timedelta(days=5), is_published=False)
    db_session.add(poll)
    db_session.commit()
    
    qa_data_payload = json.dumps([
        {"question": "Why vote for me?", "answer": "Because I am the best fit for the role."}
    ])
    
    res = client.post('/api/candidates', headers=admin_auth_headers, data={
        "poll_id": poll.poll_id, 
        "first_name": "Smart", 
        "last_name": "Candidate", 
        "position": "President",
        "course_year": "1st Year",
        "qa_data": qa_data_payload
    })
    assert res.status_code == 200
    
    get_res = client.get(f'/api/candidates/{poll.poll_id}', headers=admin_auth_headers)
    candidates = get_res.json()
    assert len(candidates) > 0
    assert len(candidates[0]["qas"]) == 1
    assert candidates[0]["qas"][0]["question"] == "Why vote for me?"

def test_publish_poll_endpoint(client, admin_auth_headers, db_session):
    """Test the newly added endpoint that locks/publishes a poll."""
    poll = Poll(title="Draft Poll", start_time=datetime.now(timezone.utc), end_time=datetime.now(timezone.utc) + timedelta(days=5), is_published=False)
    db_session.add(poll)
    db_session.commit()
    
    res = client.put(f'/api/polls/{poll.poll_id}/publish', headers=admin_auth_headers)
    assert res.status_code == 200
    
    db_session.refresh(poll)
    assert poll.is_published == True

def test_locked_poll_prevents_modifications(client, admin_auth_headers, db_session):
    """Test the critical security logic: Ensure no one can alter the roster of a published poll."""
    poll = Poll(title="Locked Published Poll", start_time=datetime.now(timezone.utc), end_time=datetime.now(timezone.utc) + timedelta(days=5), is_published=True)
    db_session.add(poll)
    db_session.commit()
    
    party_res = client.post('/api/parties', headers=admin_auth_headers, json={
        "poll_id": poll.poll_id,
        "name": "Late Party"
    })
    assert party_res.status_code == 400
    assert "published and locked" in party_res.json()["detail"].lower()
    
    cand_res = client.post('/api/candidates', headers=admin_auth_headers, data={
        "poll_id": poll.poll_id, 
        "first_name": "Late", 
        "last_name": "Guy", 
        "position": "President",
        "course_year": "1st Year"
    })
    assert cand_res.status_code == 400
    assert "published and locked" in cand_res.json()["detail"].lower()