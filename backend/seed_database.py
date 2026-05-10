import random
from datetime import datetime, timedelta, timezone
from database import SessionLocal
from models import User, Poll, Party, Candidate, Vote, CandidateQA
from auth import pwd_context

# --- CONSTANTS & REALISTIC DATA POOLS ---
POSITIONS = ['President', 'Vice President', 'Secretary', 'Treasurer', 'Auditor', 'PIO']

COURSES = [
    'Bachelor of Science in Tourism Management',
    'Bachelor of Science in Hospitality Management',
    'Bachelor of Entrepreneurship',
    'Bachelor of Arts in Communication',
    'Bachelor of Arts in Political Science',
    'Bachelor of Arts in English Language',
    'Bachelor of Science in Social Work',
    'Bachelor of Science in Biology',
    'Bachelor of Science in Information Technology',
    'Bachelor of Library and Information Science',
    'Bachelor of Music in Music Education',
    'Bachelor of Early Childhood Education',
    'Bachelor of Elementary Education',
    'Bachelor of Special Needs Education',
    'Bachelor of Physical Education',
    'Bachelor of Technology and Livelihood Education',
    'Bachelor of Secondary Education'
]

YEARS = ['1st Year', '2nd Year', '3rd Year', '4th Year']

PARTY_PLATFORMS = [
    "We stand for academic excellence and student welfare. Our primary goal is to ensure that every LNU student has access to top-tier learning resources and a supportive campus environment.",
    "Transparency, Accountability, and Progress. We aim to modernize student services, push for digital campus initiatives, and ensure that the student council budget is spent wisely.",
    "Empowering the youth through active participation. We believe in creating more extracurricular opportunities, supporting student organizations, and fostering a vibrant campus culture.",
    "A champion for student rights and inclusivity. Our platform focuses on mental health awareness, creating safe spaces for all students, and bridging the gap between the administration and the student body.",
    "Innovation and Leadership. We are committed to organizing skill-building workshops, career fairs, and networking events to prepare LNU students for the professional world.",
    "Driven by the core values of the university. We pledge to uphold academic integrity, promote environmental sustainability on campus, and organize community outreach programs."
]

FIRST_NAMES = [
    "Juan", "Maria", "Jose", "Ana", "Pedro", "Lourdes", "Carlos", "Teresa", 
    "Miguel", "Rosa", "Emanuel", "Carmen", "Rafael", "Elena", "Antonio", 
    "Beatriz", "Francisco", "Clara", "Vicente", "Isabel", "Fernando", "Silvia", 
    "Ricardo", "Luisa", "Eduardo", "Valeria", "Roberto", "Camila", "Luis", 
    "Sofia", "Gabriel", "Mariana", "Jorge", "Lucia", "Julio", "Daniela", 
    "Mario", "Valentina", "Oscar", "Victoria", "Marcos", "Martina", "Victor", 
    "Emilia", "Andres", "Juliana", "Diego", "Zoe", "Joaquin", "Micaela"
]

LAST_NAMES = [
    "Garcia", "Reyes", "Cruz", "Santos", "Bautista", "Ocampo", "Aquino", 
    "Ramos", "Mendoza", "Soriano", "Villanueva", "Diaz", "Flores", "Perez", 
    "Tolentino", "Castillo", "Santiago", "Aguilar", "Navarro", "Torres", 
    "Velasco", "Del Rosario", "Gomez", "Castro", "Rodriguez", "Rivera", 
    "Alvarez", "Romero", "De Leon", "Domingo", "Mercado", "Gonzales", 
    "Lopez", "Gutierrez", "Sison", "Miranda", "Pascual", "Sarmiento", 
    "Valdez", "Ferrer", "Nicolas", "Cordero", "Ignacio", "Guzman", "Ortiz"
]

QUESTIONS_POOL = [
    "What is your primary platform for this academic year?",
    "How do you plan to address student concerns regarding campus facilities?",
    "What is your strategy for improving student engagement?",
    "How will you ensure transparency in the council's budget?",
    "Why do you believe you are the best fit for this position?",
    "What makes your political party different from the others?",
    "How will you balance your academic studies with your council duties?"
]

ANSWERS_POOL = [
    "My focus will be on open communication and immediate action on student feedback.",
    "I plan to implement a digital suggestion box and hold monthly town halls.",
    "We will prioritize budget allocation towards facility maintenance and student orgs.",
    "My track record shows a commitment to integrity and hard work for the student body.",
    "I aim to create inclusive programs that cater to all degree programs and year levels.",
    "I believe in leading by example, ensuring every student's voice is genuinely heard.",
    "We will push for digitalization of student services to make transactions faster."
]

def generate_name():
    return random.choice(FIRST_NAMES), f"{random.choice('ABCDEFGHIJKLMNOPQRSTUVWXYZ')}.", random.choice(LAST_NAMES)

def get_unique_vote_distribution(total_votes):
    """Mathematically distributes votes among 6 candidates so there are NEVER any ties."""
    counts = [
        int(total_votes * 0.38), # 1st Place gets 38%
        int(total_votes * 0.25), # 2nd Place gets 25%
        int(total_votes * 0.15), # 3rd Place gets 15%
        int(total_votes * 0.10), # 4th Place gets 10%
        int(total_votes * 0.07)  # 5th Place gets 7%
    ]
    # 6th Place gets whatever is left over (approx 5%)
    counts.append(total_votes - sum(counts))
    return sorted(counts, reverse=True)


def seed_advanced_data():
    db = SessionLocal()
    try:
        # --- 1. SET TARGET DATE: May 6, 2026 ---
        target_now = datetime(2026, 5, 6, 12, 0, 0, tzinfo=timezone.utc)
        print(f"🕒 Time-traveling system to target date: {target_now.strftime('%Y-%m-%d %H:%M:%S')} UTC")

        # --- 2. CLEAN UP OLD DATA ---
        print("🧹 Cleaning old election and student data...")
        db.query(Vote).delete()
        db.query(CandidateQA).delete() 
        db.query(Candidate).delete()
        db.query(Party).delete()
        db.query(Poll).delete()
        
        # Delete only students so Admin/Staff accounts survive
        db.query(User).filter(User.role == 'Student').delete(synchronize_session=False)
        db.commit()

        # --- 3. CREATE 8000 USERS (INCLUDING JOHN) ---
        print("👥 Generating 8,000 students (This may take a few seconds)...")
        hashed_pw = pwd_context.hash("password12345")
        
        users_to_add = []
        
        # Inject our specific target student
        john = User(
            first_name="John", middle_name="D.", last_name="Doe", 
            email="john@lnu.edu.ph", student_number="20240001",
            course="Bachelor of Science in Information Technology",
            password_hash=hashed_pw, role="Student", is_active=True,
            created_at=target_now
        )
        users_to_add.append(john)

        # Generate 7,999 more
        base_student_id = 2000000
        for i in range(7999):
            fname, mname, lname = generate_name()
            users_to_add.append(User(
                first_name=fname, middle_name=mname, last_name=lname,
                email=f"{fname.lower()}.{lname.lower()}{i}@lnu.edu.ph",
                student_number=str(base_student_id + i),
                course=random.choice(COURSES),
                password_hash=hashed_pw, role="Student", is_active=True,
                created_at=target_now
            ))
        
        # Fast bulk insert for users
        db.add_all(users_to_add)
        db.commit()

        # Fetch them back to guarantee we have their auto-incremented user_ids
        voters = db.query(User).filter(User.role == 'Student').all()

        # --- 4. CREATE 3 POLLS ---
        print("📊 Creating 3 Polls (2 Expired, 1 Active)...")
        polls = [
            Poll(title="2025 Special Elections", start_time=target_now - timedelta(days=90), end_time=target_now - timedelta(days=80), status="Ended", is_published=True, is_archived=True),
            Poll(title="2026 Spring SSC Election", start_time=target_now - timedelta(days=40), end_time=target_now - timedelta(days=30), status="Ended", is_published=True, is_archived=False),
            Poll(title="2026 Main General Election", start_time=target_now - timedelta(days=2), end_time=target_now + timedelta(days=5), status="Active", is_published=True, is_archived=False)
        ]
        db.add_all(polls)
        db.commit()

        # --- 5. CREATE PARTIES, CANDIDATES & QA ---
        print("🚩 Creating Parties, Candidates, and Unique Q&A profiles...")
        party_names_pool = [
            ['Alpha Alliance', 'Beta Bloc', 'Gamma Group', 'Delta Dynamics', 'Epsilon Echo'],
            ['Zeta Zeal', 'Eta Engineers', 'Theta Thinkers', 'Iota Innovators', 'Kappa Knights'],
            ['Lambda Leaders', 'Mu Movement', 'Nu Nation', 'Xi X-factor', 'Omicron Order']
        ]

        poll_position_candidates = {p.poll_id: {pos: [] for pos in POSITIONS} for p in polls}

        for i, poll in enumerate(polls):
            # 6 parties total per poll
            poll_party_names = ['Independent'] + party_names_pool[i] 
            
            for p_name in poll_party_names:
                # --- NEW: Inject Platform Bios ---
                bio = "An independent coalition of student leaders." if p_name == 'Independent' else random.choice(PARTY_PLATFORMS)
                new_party = Party(poll_id=poll.poll_id, name=p_name, platform_bio=bio)
                
                db.add(new_party)
                db.commit() 
                
                for position in POSITIONS:
                    fname, mname, lname = generate_name()
                    cand = Candidate(
                        poll_id=poll.poll_id,
                        first_name=fname, middle_name=mname, last_name=lname,
                        position=position, party_name=p_name,
                        course_year=f"{random.choice(COURSES)} - {random.choice(YEARS)}",
                        description_platform=f"Vote {fname} for {position}!"
                    )
                    db.add(cand)
                    db.commit() 
                    
                    poll_position_candidates[poll.poll_id][position].append(cand.candidate_id)

                    # --- ADDING THE QA RECORDS ---
                    selected_questions = random.sample(QUESTIONS_POOL, 2)
                    qa_records = []
                    
                    for q in selected_questions:
                        base_answer = random.choice(ANSWERS_POOL)
                        dynamic_answer = f"As your next {position}, {base_answer.lower()}" if random.choice([True, False]) else base_answer

                        qa_records.append(CandidateQA( 
                            candidate_id=cand.candidate_id,
                            question=q,
                            answer=dynamic_answer
                        ))
                    
                    db.add_all(qa_records)
                    db.commit()

        # --- 6. MASSIVE VOTE SIMULATION ---
        print("🗳️ Simulating ~144,000 Votes (This will take a moment)...")
        votes_to_insert = []

        for poll in polls:
            is_ongoing_poll = (poll.status == "Active")
            
            poll_voters = []
            for v in voters:
                # 🛑 CRITICAL RULE: John skips the active poll!
                if is_ongoing_poll and v.email == "john@lnu.edu.ph":
                    continue
                poll_voters.append(v)

            total_voters = len(poll_voters)

            for position in POSITIONS:
                candidate_ids = poll_position_candidates[poll.poll_id][position]
                vote_distribution = get_unique_vote_distribution(total_voters)
                
                pool_of_votes = []
                for cand_id, vote_count in zip(candidate_ids, vote_distribution):
                    pool_of_votes.extend([cand_id] * vote_count)
                
                random.shuffle(pool_of_votes)
                
                for user, assigned_cand_id in zip(poll_voters, pool_of_votes):
                    votes_to_insert.append({
                        "user_id": user.user_id,
                        "poll_id": poll.poll_id,
                        "candidate_id": assigned_cand_id
                    })

        # Insert 144,000 rows rapidly via mappings
        db.bulk_insert_mappings(Vote, votes_to_insert)
        db.commit()

        print("\n🎉 SUCCESS: Database heavily seeded with 8,000 students!")
        print(f"   - Total Polls: 3 (2 Expired, 1 Active)")
        print(f"   - Total Parties: 18 (with platform bios)")
        print(f"   - Total Candidates: 108")
        print(f"   - Total Q&A Profiles: 216 Unique Responses")
        print(f"   - Total Votes Cast: {len(votes_to_insert):,}")
        print(f"   - 'john@lnu.edu.ph' voted perfectly (Skipped the active poll).")
        print(f"   - No voting ties exist within any position.")
        print(f"   - All students have password: 'password12345'")

    except Exception as e:
        print(f"❌ Error occurred: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_advanced_data()