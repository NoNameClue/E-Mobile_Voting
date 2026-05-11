import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
import json
from datetime import datetime, timezone, timedelta

# Import FastAPI app and database components
from main import app
from database import get_db, Base
from models import User, Poll, Party, Candidate, Vote, QuestionBank, CandidateQA
from auth import pwd_context, create_access_token
import io

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
    yield TestClient(app)
    del app.dependency_overrides[get_db]

# ==========================================
# 2. CORE FIXTURES
# ==========================================
@pytest.fixture(scope="function")
def admin_user(db_session):
    admin = User(
        first_name="Admin", last_name="User", email="admin@lnu.edu.ph",
        student_number="0000000", password_hash=pwd_context.hash("adminpass"),
        role="Admin", is_active=True
    )
    db_session.add(admin)
    db_session.commit()
    db_session.refresh(admin)
    return admin

@pytest.fixture(scope="function")
def student_user(db_session):
    student = User(
        first_name="Carl David", middle_name="T.", last_name="Pura", 
        email="cdpura@lnu.edu.ph", 
        student_number="1234567", # Updated to 7 digits
        course="Bachelor of Science in Information Technology", # Updated to match dropdown
        password_hash=pwd_context.hash("StrongP@ssw0rd!"),
        role="Student", is_active=True
    )
    db_session.add(student)
    db_session.commit()
    db_session.refresh(student)
    return student

@pytest.fixture(scope="function")
def student_auth_headers(student_user):
    token = create_access_token(data={"sub": student_user.email, "role": student_user.role}, expires_delta=timedelta(hours=1))
    return {"Authorization": f"Bearer {token}"}

@pytest.fixture(scope="function")
def active_poll(db_session):
    poll = Poll(
        title="LNU SSC Election", 
        start_time=datetime.now(timezone.utc) - timedelta(days=1), 
        end_time=datetime.now(timezone.utc) + timedelta(days=1), 
        is_published=True, status="Active"
    )
    db_session.add(poll)
    db_session.commit()
    db_session.refresh(poll)
    return poll

@pytest.fixture(scope="function")
def draft_poll(db_session):
    poll = Poll(
        title="Draft Poll", 
        start_time=datetime.now(timezone.utc) + timedelta(days=1), 
        end_time=datetime.now(timezone.utc) + timedelta(days=2), 
        is_published=False, status="Draft"
    )
    db_session.add(poll)
    db_session.commit()
    db_session.refresh(poll)
    return poll


# ==============================================================================
# 3. MASSIVE NEGATIVE TESTING MATRICES (~60 Tests)
# ==============================================================================

# MATRIX 1: Validation Errors (422) - Missing required JSON/Form fields
@pytest.mark.parametrize("method, endpoint, payload", [
    ("POST", "/api/register", {"first_name": "Test"}), # Missing email/password
    ("POST", "/api/register", {"email": "test@lnu.edu.ph", "password": "pwd"}), # Missing names
    ("POST", "/api/login", {"email": "test@lnu.edu.ph"}),
    ("POST", "/api/login", {"password": "pwd"}),
    ("POST", "/api/candidates", {"first_name": "Test"}), 
    ("POST", "/api/candidates", {"poll_id": 1, "first_name": "Test"}),
    ("PUT", "/api/candidates/1", {"first_name": "Test"}),
    ("POST", "/api/parties", {"name": "LNU Youth"}), # Missing poll_id
    ("POST", "/api/parties", {"poll_id": 1}), # Missing name
    ("POST", "/api/polls", {"title": "Election"}), # Missing times
    ("POST", "/api/polls", {"start_time": "2026-01-01T00:00:00Z"}), 
    ("PUT", "/api/polls/1", {"title": "Update"}),
    ("POST", "/api/questions", {}),
    ("PUT", "/api/questions/1", {}),
    ("POST", "/api/officers", {"first_name": "Staff"}),
    ("POST", "/api/officers", {"email": "staff@lnu.edu.ph"}),
    ("PUT", "/api/officers/1", {"first_name": "Staff"}),
    ("POST", "/api/vote", {"poll_id": 1}), # Missing candidate_ids
    ("POST", "/api/vote", {"candidate_ids": [1]}), # Missing poll_id
])
def test_422_validation_errors(client, student_auth_headers, method, endpoint, payload):
    # 🛠️ FIX: Add headers for endpoints that require auth before body validation
    headers = student_auth_headers if "/api/vote" in endpoint else None
    
    if "register" in endpoint or "candidates" in endpoint or "officers" in endpoint:
        res = client.request(method, endpoint, data=payload, headers=headers)
    else:
        res = client.request(method, endpoint, json=payload, headers=headers)
    
    assert res.status_code == 422


# MATRIX 2: Not Found (404) - Targeting non-existent entities
@pytest.mark.parametrize("method, endpoint", [
    ("PUT", "/api/candidates/9999"),
    ("DELETE", "/api/candidates/9999"),
    ("PUT", "/api/parties/9999"),
    ("DELETE", "/api/parties/9999"),
    ("PUT", "/api/polls/9999"),
    ("PUT", "/api/polls/9999/publish"),
    ("PUT", "/api/polls/9999/archive?is_archived=true"),
    ("PUT", "/api/polls/9999/unarchive"),
    ("DELETE", "/api/polls/9999"),
    ("PUT", "/api/questions/9999"),
    ("DELETE", "/api/questions/9999"),
    ("PUT", "/api/officers/9999"),
    ("DELETE", "/api/officers/9999"),
    ("PUT", "/api/officers/9999/permissions"),
    ("PUT", "/api/admin/students/9999/toggle"),
])
def test_404_not_found(client, method, endpoint):
    dummy_payload_json = {"title": "X", "start_time": "2026-01-01T00:00:00Z", "end_time": "2026-01-02T00:00:00Z", "is_published": False, "is_active": True, "question_text": "X", "name": "X", "permissions": []}
    dummy_payload_form = {"poll_id": 1, "first_name": "X", "last_name": "X", "position": "X", "course_year": "X", "email": "x@x.com"}
    
    # 🛠️ FIX: Ensure /permissions gets JSON, not Form data
    if ("candidates" in endpoint or "officers" in endpoint) and "permissions" not in endpoint:
        res = client.request(method, endpoint, data=dummy_payload_form)
    else:
        res = client.request(method, endpoint, json=dummy_payload_json)
    
    assert res.status_code == 404


# MATRIX 3: Method Not Allowed (405) - Hitting wrong HTTP methods
@pytest.mark.parametrize("method, endpoint", [
    ("POST", "/api/users"),
    ("PUT", "/api/users"),
    ("DELETE", "/api/users"),
    ("POST", "/api/admin/students"),
    ("GET", "/api/admin/students/1/toggle"),
    ("GET", "/api/register"),
    ("GET", "/api/login"),
    ("PUT", "/api/vote"),
    ("DELETE", "/api/vote"),
    ("POST", "/api/vote/status/1"),
    ("POST", "/api/parties/lineups"),
    ("POST", "/api/polls/1/publish"),
    ("POST", "/api/polls/1/archive"),
    ("POST", "/api/polls/1/unarchive"),
    ("POST", "/api/polls/1/report"),
    ("POST", "/api/polls/1/results"),
])
def test_405_method_not_allowed(client, method, endpoint):
    res = client.request(method, endpoint)
    assert res.status_code == 405


# MATRIX 4: Published Poll Lockdown (400) - Editing locked polls
@pytest.mark.parametrize("method, endpoint, is_form", [
    ("POST", "/api/parties", False),
    ("PUT", "/api/parties/1", False),
    ("DELETE", "/api/parties/1", False),
    ("POST", "/api/candidates", True),
    ("PUT", "/api/candidates/1", True),
    ("DELETE", "/api/candidates/1", False),
])
def test_400_published_poll_lockdown(client, active_poll, db_session, method, endpoint, is_form):
    # Setup dummy target resources
    party = Party(party_id=1, poll_id=active_poll.poll_id, name="Test Party")
    cand = Candidate(candidate_id=1, poll_id=active_poll.poll_id, first_name="A", last_name="B")
    db_session.add_all([party, cand])
    db_session.commit()

    json_payload = {"poll_id": active_poll.poll_id, "name": "New Party"}
    form_payload = {"poll_id": active_poll.poll_id, "first_name": "A", "last_name": "B", "position": "C", "course_year": "D"}

    if is_form:
        res = client.request(method, endpoint, data=form_payload)
    else:
        res = client.request(method, endpoint, json=json_payload)

    # DELETE requests don't need a payload body
    if method == "DELETE":
        res = client.delete(endpoint)

    assert res.status_code == 400
    assert "published and locked" in res.json()["detail"].lower()


# MATRIX 5: Unauthenticated Access (401) - For protected endpoints
@pytest.mark.parametrize("method, endpoint", [
    ("GET", "/api/users/me"),
    ("GET", "/api/vote/status/1"),
    ("POST", "/api/vote"),
    ("GET", "/api/users/me/votes"),
])
def test_401_unauthenticated(client, method, endpoint):
    res = client.request(method, endpoint, json={"poll_id": 1, "candidate_ids": [1]})
    assert res.status_code == 401


# ==============================================================================
# 4. EXPLICIT BUSINESS LOGIC & CRUD TESTS (40+ Tests)
# ==============================================================================

# --- AUTH ROUTER ---
# --- AUTH ROUTER ---
def test_register_success(client):
    res = client.post("/api/register", data={
        "first_name": "New", "last_name": "Student", "email": "new@lnu.edu.ph",
        "student_number": "7654321", # Updated to 7 digits
        "password": "StrongP@ssw0rd!", 
        "course": "Bachelor of Science in Information Technology" # Updated to match dropdown
    })
    assert res.status_code == 200

def test_register_duplicate_email(client, student_user):
    res = client.post("/api/register", data={
        "first_name": "Clone", "last_name": "User", "email": student_user.email,
        "student_number": "8888888", 
        "password": "StrongP@ssw0rd!", 
        "course": "Bachelor of Science in Information Technology"
    })
    assert res.status_code == 409

def test_register_duplicate_student_id(client, student_user):
    res = client.post("/api/register", data={
        "first_name": "Clone", "last_name": "User", "email": "unique@lnu.edu.ph",
        "student_number": student_user.student_number, 
        "password": "StrongP@ssw0rd!", 
        "course": "Bachelor of Science in Information Technology"
    })
    assert res.status_code == 409

def test_login_success(client, student_user):
    res = client.post("/api/login", json={"email": student_user.email, "password": "StrongP@ssw0rd!"})
    assert res.status_code == 200
    assert "access_token" in res.json()

def test_login_fail_bad_password(client, student_user):
    res = client.post("/api/login", json={"email": student_user.email, "password": "wrong"})
    assert res.status_code == 401

# --- USERS ROUTER ---
def test_get_all_users(client, admin_user, student_user):
    res = client.get("/api/users")
    assert res.status_code == 200
    assert len(res.json()) >= 2

def test_get_all_students(client, admin_user, student_user):
    res = client.get("/api/admin/students")
    assert res.status_code == 200
    assert len(res.json()) == 1
    assert res.json()[0]["student_number"] == student_user.student_number

def test_toggle_student_status(client, student_user, db_session):
    res = client.put(f"/api/admin/students/{student_user.user_id}/toggle", json={"is_active": False})
    assert res.status_code == 200
    
    # Verify login is forbidden
    login_res = client.post("/api/login", json={"email": student_user.email, "password": "StrongP@ssw0rd!"})
    assert login_res.status_code == 403 

# --- STAFFS ROUTER ---
def test_create_staff_success(client):
    res = client.post("/api/officers", data={
        "first_name": "Staff", "last_name": "One", "email": "staff1@lnu.edu.ph",
        "student_number": "STAFF-1", "password": "pwd"
    })
    assert res.status_code == 200

def test_get_officers(client, db_session):
    client.post("/api/officers", data={"first_name": "S", "last_name": "O", "email": "s@lnu.edu.ph", "password": "p"})
    res = client.get("/api/officers")
    assert res.status_code == 200
    assert len(res.json()) >= 1

def test_update_staff(client, db_session):
    client.post("/api/officers", data={"first_name": "Old", "last_name": "Name", "email": "old@lnu.edu.ph", "password": "p"})
    staff = db_session.query(User).filter(User.email == "old@lnu.edu.ph").first()
    
    res = client.put(f"/api/officers/{staff.user_id}", data={
        "first_name": "New", "last_name": "Name", "email": "new@lnu.edu.ph", "password": "newp"
    })
    assert res.status_code == 200

def test_update_staff_permissions(client, db_session):
    client.post("/api/officers", data={"first_name": "P", "last_name": "P", "email": "p@lnu.edu.ph", "password": "p"})
    staff = db_session.query(User).filter(User.email == "p@lnu.edu.ph").first()
    
    res = client.put(f"/api/officers/{staff.user_id}/permissions", json={"permissions": ["manage_polls"]})
    assert res.status_code == 200

def test_delete_staff(client, db_session):
    client.post("/api/officers", data={"first_name": "D", "last_name": "D", "email": "d@lnu.edu.ph", "password": "d"})
    staff = db_session.query(User).filter(User.email == "d@lnu.edu.ph").first()
    
    res = client.delete(f"/api/officers/{staff.user_id}")
    assert res.status_code == 200

# --- POLLS ROUTER ---
def test_create_poll_success(client):
    start = datetime.now(timezone.utc)
    res = client.post("/api/polls", json={
        "title": "SSC Election", "start_time": start.isoformat(), 
        "end_time": (start + timedelta(days=1)).isoformat(), "is_published": False
    })
    assert res.status_code == 200

def test_get_polls_status_mapping(client, active_poll, draft_poll):
    res = client.get("/api/polls")
    assert res.status_code == 200
    statuses = [p["status"] for p in res.json()]
    assert "Active" in statuses
    assert "Draft" in statuses

def test_update_poll_success(client, draft_poll):
    res = client.put(f"/api/polls/{draft_poll.poll_id}", json={
        "title": "Updated Poll", "start_time": "2026-01-01T00:00:00Z", 
        "end_time": "2026-01-02T00:00:00Z", "is_published": False
    })
    assert res.status_code == 200

def test_publish_poll(client, draft_poll):
    res = client.put(f"/api/polls/{draft_poll.poll_id}/publish")
    assert res.status_code == 200

def test_archive_unpublished_poll_fails(client, draft_poll):
    res = client.put(f"/api/polls/{draft_poll.poll_id}/archive?is_archived=true")
    assert res.status_code == 400

def test_archive_and_unarchive_published_poll(client, active_poll):
    res = client.put(f"/api/polls/{active_poll.poll_id}/archive?is_archived=true")
    assert res.status_code == 200
    res2 = client.put(f"/api/polls/{active_poll.poll_id}/unarchive")
    assert res.status_code == 200

def test_delete_poll(client, draft_poll):
    res = client.delete(f"/api/polls/{draft_poll.poll_id}")
    assert res.status_code == 200

# --- PARTIES ROUTER ---
def test_create_party_success(client, draft_poll):
    res = client.post("/api/parties", json={"poll_id": draft_poll.poll_id, "name": "LNU Youth", "platform_bio": "Empowering students"})
    assert res.status_code == 200
    assert res.json()["platform_bio"] == "Empowering students"

def test_create_party_duplicate_fails(client, draft_poll):
    client.post("/api/parties", json={"poll_id": draft_poll.poll_id, "name": "Duplicate Party"})
    res = client.post("/api/parties", json={"poll_id": draft_poll.poll_id, "name": "Duplicate Party"})
    assert res.status_code == 409

def test_get_parties_by_poll(client, draft_poll):
    client.post("/api/parties", json={"poll_id": draft_poll.poll_id, "name": "Get Party", "platform_bio": "Bio check"})
    res = client.get(f"/api/parties/{draft_poll.poll_id}")
    assert res.status_code == 200
    assert len(res.json()) > 0
    assert res.json()[0]["platform_bio"] == "Bio check"

def test_update_party(client, draft_poll, db_session):
    client.post("/api/parties", json={"poll_id": draft_poll.poll_id, "name": "Up Party"})
    party = db_session.query(Party).filter(Party.name == "Up Party").first()
    res = client.put(f"/api/parties/{party.party_id}", json={"name": "New Name", "platform_bio": "New Bio"})
    assert res.status_code == 200

def test_delete_party(client, draft_poll, db_session):
    client.post("/api/parties", json={"poll_id": draft_poll.poll_id, "name": "Del Party"})
    party = db_session.query(Party).filter(Party.name == "Del Party").first()
    res = client.delete(f"/api/parties/{party.party_id}")
    assert res.status_code == 200

def test_delete_independent_party_fails(client, draft_poll, db_session):
    ind_party = Party(poll_id=draft_poll.poll_id, name="Independent")
    db_session.add(ind_party)
    db_session.commit()
    res = client.delete(f"/api/parties/{ind_party.party_id}")
    assert res.status_code == 400

# --- CANDIDATES ROUTER ---
def test_create_candidate_with_qa(client, draft_poll):
    qa_data = json.dumps([{"question": "Why vote?", "answer": "I am capable."}])
    res = client.post("/api/candidates", data={
        "poll_id": draft_poll.poll_id, "first_name": "Jane", "last_name": "Doe",
        "position": "President", "party_name": "Independent", "course_year": "BSCOE 2-1",
        "qa_data": qa_data
    })
    assert res.status_code == 200

def test_create_candidate_duplicate_party_position_fails(client, draft_poll):
    client.post("/api/candidates", data={
        "poll_id": draft_poll.poll_id, "first_name": "A", "last_name": "B",
        "position": "President", "party_name": "LNU Youth", "course_year": "BSIT"
    })
    res = client.post("/api/candidates", data={
        "poll_id": draft_poll.poll_id, "first_name": "C", "last_name": "D",
        "position": "President", "party_name": "LNU Youth", "course_year": "BSIT"
    })
    assert res.status_code == 400

def test_create_candidate_independent_multiple_success(client, draft_poll):
    client.post("/api/candidates", data={
        "poll_id": draft_poll.poll_id, "first_name": "A", "last_name": "B",
        "position": "President", "party_name": "Independent", "course_year": "BSIT"
    })
    res = client.post("/api/candidates", data={
        "poll_id": draft_poll.poll_id, "first_name": "C", "last_name": "D",
        "position": "President", "party_name": "Independent", "course_year": "BSIT"
    })
    assert res.status_code == 200

def test_get_candidates_includes_qa(client, draft_poll):
    qa_data = json.dumps([{"question": "Vision?", "answer": "Success"}])
    client.post("/api/candidates", data={
        "poll_id": draft_poll.poll_id, "first_name": "John", "last_name": "Smith",
        "position": "Senator", "party_name": "Independent", "course_year": "BSIT", "qa_data": qa_data
    })
    res = client.get(f"/api/candidates/{draft_poll.poll_id}")
    assert res.status_code == 200
    assert "qas" in res.json()[0]
    assert res.json()[0]["qas"][0]["answer"] == "Success"

def test_update_candidate_wipes_and_replaces_qa(client, draft_poll, db_session):
    client.post("/api/candidates", data={
        "poll_id": draft_poll.poll_id, "first_name": "Up", "last_name": "Cand",
        "position": "VP", "party_name": "Independent", "course_year": "BSIT",
        "qa_data": json.dumps([{"question": "Old", "answer": "Old"}])
    })
    cand = db_session.query(Candidate).filter(Candidate.first_name == "Up").first()
    
    new_qa = json.dumps([{"question": "New", "answer": "New Answer"}])
    res = client.put(f"/api/candidates/{cand.candidate_id}", data={
        "poll_id": draft_poll.poll_id, "first_name": "Up", "last_name": "Cand",
        "position": "VP", "party_name": "Independent", "course_year": "BSIT",
        "qa_data": new_qa
    })
    assert res.status_code == 200
    
    res_get = client.get(f"/api/candidates/{draft_poll.poll_id}")
    updated_cand = next((c for c in res_get.json() if c["candidate_id"] == cand.candidate_id), None)
    assert updated_cand["qas"][0]["answer"] == "New Answer"

def test_delete_candidate(client, draft_poll, db_session):
    client.post("/api/candidates", data={
        "poll_id": draft_poll.poll_id, "first_name": "Del", "last_name": "Cand",
        "position": "Sec", "party_name": "Independent", "course_year": "BSIT"
    })
    cand = db_session.query(Candidate).filter(Candidate.first_name == "Del").first()
    res = client.delete(f"/api/candidates/{cand.candidate_id}")
    assert res.status_code == 200

# --- QUESTIONS ROUTER ---
def test_create_question(client):
    res = client.post("/api/questions", json={"question_text": "What is your primary goal?"})
    assert res.status_code == 200

def test_create_question_duplicate_fails(client):
    client.post("/api/questions", json={"question_text": "Duplicate Q?"})
    res = client.post("/api/questions", json={"question_text": "Duplicate Q?"})
    assert res.status_code == 400

def test_get_questions(client):
    client.post("/api/questions", json={"question_text": "Get Q?"})
    res = client.get("/api/questions")
    assert res.status_code == 200
    assert len(res.json()) > 0

def test_edit_question(client, db_session):
    client.post("/api/questions", json={"question_text": "Old Q?"})
    q = db_session.query(QuestionBank).filter(QuestionBank.question_text == "Old Q?").first()
    res = client.put(f"/api/questions/{q.question_id}", json={"question_text": "New Q?"})
    assert res.status_code == 200

def test_delete_question(client, db_session):
    client.post("/api/questions", json={"question_text": "Del Q?"})
    q = db_session.query(QuestionBank).filter(QuestionBank.question_text == "Del Q?").first()
    res = client.delete(f"/api/questions/{q.question_id}")
    assert res.status_code == 200

# --- VOTING & RESULTS ROUTER ---
def test_check_vote_status_unvoted(client, active_poll, student_auth_headers):
    res = client.get(f"/api/vote/status/{active_poll.poll_id}", headers=student_auth_headers)
    assert res.status_code == 200
    assert res.json()["has_voted"] is False

def test_submit_vote_success(client, active_poll, student_auth_headers, db_session):
    cand = Candidate(poll_id=active_poll.poll_id, first_name="Carl", last_name="Pura", position="President")
    db_session.add(cand)
    db_session.commit()

    res = client.post("/api/vote", json={"poll_id": active_poll.poll_id, "candidate_ids": [cand.candidate_id]}, headers=student_auth_headers)
    assert res.status_code == 200

def test_check_vote_status_voted(client, active_poll, student_auth_headers, db_session, student_user):
    db_session.add(Vote(user_id=student_user.user_id, poll_id=active_poll.poll_id, candidate_id=1))
    db_session.commit()
    
    res = client.get(f"/api/vote/status/{active_poll.poll_id}", headers=student_auth_headers)
    assert res.status_code == 200
    assert res.json()["has_voted"] is True

def test_submit_vote_double_vote_fails(client, active_poll, student_auth_headers, db_session, student_user):
    db_session.add(Vote(user_id=student_user.user_id, poll_id=active_poll.poll_id, candidate_id=1))
    db_session.commit()

    res = client.post("/api/vote", json={"poll_id": active_poll.poll_id, "candidate_ids": [1]}, headers=student_auth_headers)
    assert res.status_code == 400

def test_get_my_votes(client, active_poll, student_auth_headers, db_session, student_user):
    cand = Candidate(poll_id=active_poll.poll_id, first_name="A", last_name="B", position="Sen")
    db_session.add(cand)
    db_session.commit()
    db_session.add(Vote(user_id=student_user.user_id, poll_id=active_poll.poll_id, candidate_id=cand.candidate_id))
    db_session.commit()

    res = client.get("/api/users/me/votes", headers=student_auth_headers)
    assert res.status_code == 200
    assert len(res.json()) > 0

def test_get_poll_results(client, active_poll, db_session, student_user):
    cand = Candidate(poll_id=active_poll.poll_id, first_name="Winner", last_name="Cand", position="President")
    db_session.add(cand)
    db_session.commit()
    db_session.add(Vote(user_id=student_user.user_id, poll_id=active_poll.poll_id, candidate_id=cand.candidate_id))
    db_session.commit()

    res = client.get(f"/api/polls/{active_poll.poll_id}/results")
    assert res.status_code == 200
    assert res.json()[0]["votes"] == 1
    assert res.json()[0]["percentage"] == 100.0

def test_get_poll_report_advanced_margins(client, active_poll, db_session):
    # Testing the new advanced margin calculations (Ticket 9 Fix)
    cand1 = Candidate(poll_id=active_poll.poll_id, first_name="Lead", last_name="A", position="Mayor")
    cand2 = Candidate(poll_id=active_poll.poll_id, first_name="RunnerUp", last_name="B", position="Mayor")
    db_session.add_all([cand1, cand2])
    db_session.commit()
    
    # 3 votes for Lead, 1 vote for RunnerUp
    for _ in range(3):
        db_session.add(Vote(user_id=1, poll_id=active_poll.poll_id, candidate_id=cand1.candidate_id))
    db_session.add(Vote(user_id=2, poll_id=active_poll.poll_id, candidate_id=cand2.candidate_id))
    db_session.commit()

    res = client.get(f"/api/polls/{active_poll.poll_id}/report")
    assert res.status_code == 200
    report = res.json()["results"][0]
    
    # cand1 has 75%, cand2 has 25%
    winner = report["candidates"][0]
    loser = report["candidates"][1]
    
    assert winner["votes"] == 3
    assert winner["margin"] == 50.0  # 75 - 25
    assert winner["is_winner"] is True
    
    assert loser["votes"] == 1
    assert loser["margin"] == -50.0 # 25 - 75
    assert loser["is_winner"] is False
    
# ==============================================================================
# 5. ADVANCED INTEGRATION & EDGE CASE TESTS (15+ New Tests)
# ==============================================================================

# --- STRICT PASSWORD ENFORCEMENT MATRICES ---
@pytest.mark.parametrize("invalid_password, expected_status", [
    ("Short1!", 400),                             # Fails length (< 12)
    ("nouppercase123!", 400),                     # Fails uppercase
    ("NOLOWERCASE123!", 400),                     # Fails lowercase
    ("NoNumbersHere!", 400),                      # Fails numbers
    ("NoSpecialChars123", 400),                   # Fails special character
    ("StrongP@ssw0rd!", 200),                     # PASSES all criteria
])
def test_backend_password_strength_enforcement(client, invalid_password, expected_status):
    """
    CRITICAL: Ensures the backend rejects weak passwords even if the 
    Flutter front-end validation is bypassed.
    """
    res = client.post("/api/register", data={
        "first_name": "Sec", "last_name": "Test", 
        "email": f"{invalid_password}@lnu.edu.ph", # unique email per test
        "student_number": f"02-{len(invalid_password)}{expected_status}", 
        "password": invalid_password,
        "course": "Bachelor of Science in Information Technology"
    })
    assert res.status_code == expected_status

# --- DATA INTEGRITY: Party Deletion Cascade ---
def test_delete_party_reassigns_candidates_to_independent(client, draft_poll, db_session):
    """
    CRITICAL: Tests the logic in parties_router that ensures when a party is deleted, 
    its candidates are NOT deleted, but gracefully moved to 'Independent'.
    """
    party_res = client.post("/api/parties", json={"poll_id": draft_poll.poll_id, "name": "Reassign Party"})
    party_id = party_res.json()["party_id"]
    
    client.post("/api/candidates", data={
        "poll_id": draft_poll.poll_id, "first_name": "Orphan", "last_name": "Cand",
        "position": "Senator", "party_name": "Reassign Party", "course_year": "BSIT"
    })
    
    res_del = client.delete(f"/api/parties/{party_id}")
    assert res_del.status_code == 200
    
    # Verify the candidate survived and is now Independent
    cands = client.get(f"/api/candidates/{draft_poll.poll_id}").json()
    orphan = next((c for c in cands if c["first_name"] == "Orphan"), None)
    
    assert orphan is not None, "Candidate was accidentally deleted!"
    assert orphan["party_name"] == "Independent", "Candidate was not reassigned to Independent!"

# --- STRING EDGE CASES: Question Bank Validation ---
def test_create_question_with_blank_spaces_fails(client):
    """Tests the .strip() logic to ensure users can't bypass empty string checks using spaces."""
    res = client.post("/api/questions", json={"question_text": "     "})
    assert res.status_code == 400
    assert "blank" in res.json()["detail"].lower()

def test_edit_question_to_blank_spaces_fails(client, db_session):
    client.post("/api/questions", json={"question_text": "Valid Question"})
    q = db_session.query(QuestionBank).filter(QuestionBank.question_text == "Valid Question").first()
    
    res = client.put(f"/api/questions/{q.question_id}", json={"question_text": "   "})
    assert res.status_code == 400
    assert "blank" in res.json()["detail"].lower()

def test_edit_question_to_existing_text_fails(client, db_session):
    """Ensures you cannot edit a question to match another existing question (Unique Constraint)."""
    client.post("/api/questions", json={"question_text": "Alpha Q"})
    client.post("/api/questions", json={"question_text": "Beta Q"})
    
    q_beta = db_session.query(QuestionBank).filter(QuestionBank.question_text == "Beta Q").first()
    
    res = client.put(f"/api/questions/{q_beta.question_id}", json={"question_text": "Alpha Q"})
    assert res.status_code == 400
    assert "already exists" in res.json()["detail"].lower()

# --- MULTIPART FILE UPLOADS: Simulating Images ---
def test_candidate_creation_with_photo_upload(client, draft_poll):
    """Simulates uploading an image file during candidate registration via multipart/form-data."""
    fake_image = io.BytesIO(b"fake_image_data_here")
    fake_image.name = "candidate_pic.jpg"
    
    res = client.post("/api/candidates", data={
        "poll_id": draft_poll.poll_id, "first_name": "Photo", "last_name": "Cand",
        "position": "Mayor", "party_name": "Independent", "course_year": "BSIT"
    }, files={"photo": ("candidate_pic.jpg", fake_image, "image/jpeg")})
    
    assert res.status_code == 200
    
    cands = client.get(f"/api/candidates/{draft_poll.poll_id}").json()
    photo_cand = next(c for c in cands if c["first_name"] == "Photo")
    assert "candidate_pic.jpg" in photo_cand["photo_url"]

def test_staff_creation_with_photo_upload(client):
    """Simulates uploading a profile picture when creating a Staff member."""
    fake_image = io.BytesIO(b"fake_image_data_here")
    fake_image.name = "staff_pic.jpg"
    
    res = client.post("/api/officers", data={
        "first_name": "Pic", "last_name": "Staff", "email": "picstaff@lnu.edu.ph",
        "student_number": "STAFF-99", "password": "StrongP@ssw0rd!"
    }, files={"photo": ("staff_pic.jpg", fake_image, "image/jpeg")})
    
    assert res.status_code == 200

# --- ADVANCED BUSINESS LOGIC ---
def test_poll_report_empty_poll_safe_math(client, draft_poll):
    """
    Ensures that calling a report on a poll with NO votes and NO candidates 
    does not cause a DivideByZero error in the backend math logic.
    """
    res = client.get(f"/api/polls/{draft_poll.poll_id}/report")
    assert res.status_code == 200
    assert res.json()["summary"]["total_voters"] == 0
    assert res.json()["summary"]["turnout_percentage"] == 0.0

def test_party_lineups_endpoint(client, draft_poll):
    """Tests the /api/parties/lineups endpoint groups candidates correctly."""
    client.post("/api/candidates", data={
        "poll_id": draft_poll.poll_id, "first_name": "Ind", "last_name": "Cand",
        "position": "Mayor", "party_name": "Independent", "course_year": "BSIT"
    })
    
    client.post("/api/parties", json={"poll_id": draft_poll.poll_id, "name": "Lineup Party"})
    client.post("/api/candidates", data={
        "poll_id": draft_poll.poll_id, "first_name": "Part", "last_name": "Cand",
        "position": "Mayor", "party_name": "Lineup Party", "course_year": "BSIT"
    })

    res = client.get("/api/parties/lineups")
    assert res.status_code == 200
    
    data = res.json()
    assert "Independent" in data
    assert "Lineup Party" in data
    assert len(data["Independent"]) >= 1
    assert len(data["Lineup Party"]) == 1

def test_login_disabled_account_fails(client, student_user, db_session):
    """Ensure a deactivated student absolutely cannot get a JWT token."""
    student_user.is_active = False
    db_session.commit()
    
    res = client.post("/api/login", json={"email": student_user.email, "password": "StrongP@ssw0rd!"})
    assert res.status_code == 403
    assert "disabled" in res.json()["detail"].lower()

def test_cannot_delete_independent_party(client, draft_poll, db_session):
    """Double checks that 'Independent' party deletion is firmly locked out."""
    ind_party = Party(poll_id=draft_poll.poll_id, name="Independent")
    db_session.add(ind_party)
    db_session.commit()
    
    res = client.delete(f"/api/parties/{ind_party.party_id}")
    assert res.status_code == 400
    assert "Cannot delete the Independent party" in res.json()["detail"]