import random
from datetime import datetime, timedelta, timezone
from database import SessionLocal
from models import User, Poll, Party, Candidate, Vote
from auth import pwd_context

# --- REALISTIC DATA GENERATORS ---
POSITIONS = ['President', 'Vice President', 'Secretary', 'Treasurer', 'Auditor', 'PIO']
COURSES = [
    'Bachelor of Science in Information Technology', 'Bachelor of Science in Computer Engineering',
    'Bachelor of Arts in Communication', 'Bachelor of Elementary Education', 'Bachelor of Science in Biology'
]
YEARS = ['1st Year', '2nd Year', '3rd Year', '4th Year']

FIRST_NAMES = ["Miguel", "Sofia", "Mateo", "Camila", "Lucas", "Valeria", "Diego", "Isabella", "Juan", "Maria", "Carlos", "Ana", "Luis", "Elena", "Andres", "Lucia"]
LAST_NAMES = ["Santos", "Reyes", "Cruz", "Bautista", "Ocampo", "Aquino", "Mendoza", "Soriano", "Villanueva", "Diaz", "Flores", "Perez", "Castillo", "Santiago", "Torres"]
MIDDLE_INITIALS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

def generate_name():
    return random.choice(FIRST_NAMES), f"{random.choice(MIDDLE_INITIALS)}.", random.choice(LAST_NAMES)

def get_unique_vote_distribution(total_votes):
    """Mathematically distributes votes among 6 candidates so there are NEVER any ties."""
    if total_votes < 21:
        # Hardcoded fallback for very small numbers to guarantee no ties
        return [6, 5, 4, 3, 2, 1][:6]
        
    counts = [
        int(total_votes * 0.38), # 1st Place gets 38%
        int(total_votes * 0.25), # 2nd Place gets 25%
        int(total_votes * 0.15), # 3rd Place gets 15%
        int(total_votes * 0.10), # 4th Place gets 10%
        int(total_votes * 0.07)  # 5th Place gets 7%
    ]
    # 6th Place gets whatever is left over
    counts.append(total_votes - sum(counts))
    
    # Failsafe: Force them to be strictly unique
    while len(set(counts)) < len(counts):
        for i in range(len(counts) - 1):
            if counts[i] <= counts[i+1]:
                counts[i] += 1
                counts[i+1] -= 1
                
    return sorted(counts, reverse=True)

def seed_advanced_data():
    db = SessionLocal()
    try:
        print("🧹 1. Cleaning old election data (Keeping Users)...")
        db.query(Vote).delete()
        db.query(Candidate).delete()
        db.query(Party).delete()
        db.query(Poll).delete()
        db.commit()

        # ---------------------------------------------------------
        # 2. ENSURE WE HAVE ENOUGH USERS & JOHN
        # ---------------------------------------------------------
        print("👥 2. Checking Student population...")
        john = db.query(User).filter(User.email == "john@lnu.edu.ph").first()
        if not john:
            john = User(
                first_name="John", middle_name="D.", last_name="Doe", 
                email="john@lnu.edu.ph", student_number="20240001",
                password_hash=pwd_context.hash("password123"), role="Student", is_active=True
            )
            db.add(john)
            db.commit()

        student_count = db.query(User).filter(User.role == 'Student').count()
        if student_count < 50:
            print(f"   -> Only {student_count} students found. Generating dummy students to ensure healthy vote spreads...")
            dummy_users = []
            for i in range(50 - student_count):
                fn, mn, ln = generate_name()
                dummy_users.append(User(
                    first_name=fn, middle_name=mn, last_name=ln,
                    email=f"student{random.randint(10000,99999)}@lnu.edu.ph",
                    student_number=f"00{random.randint(100000,999999)}",
                    password_hash=pwd_context.hash("password"), role="Student", is_active=True
                ))
            db.add_all(dummy_users)
            db.commit()

        # ---------------------------------------------------------
        # 3. CREATE 3 POLLS (April 20, 2026 Context)
        # ---------------------------------------------------------
        print("📊 3. Creating Polls...")
        polls = [
            Poll(title="2025 SSC General Election", start_time=datetime(2025, 9, 1, 8, 0, tzinfo=timezone.utc), end_time=datetime(2025, 9, 7, 17, 0, tzinfo=timezone.utc), status="Ended", is_published=True, is_archived=True),
            Poll(title="2026 Special Election", start_time=datetime(2026, 3, 1, 8, 0, tzinfo=timezone.utc), end_time=datetime(2026, 3, 15, 17, 0, tzinfo=timezone.utc), status="Ended", is_published=True, is_archived=False),
            # Ongoing poll ends a few days from April 20, 2026
            Poll(title="2026 Main SSC Election", start_time=datetime(2026, 4, 18, 8, 0, tzinfo=timezone.utc), end_time=datetime(2026, 4, 25, 17, 0, tzinfo=timezone.utc), status="Active", is_published=True, is_archived=False)
        ]
        db.add_all(polls)
        db.commit()

        # ---------------------------------------------------------
        # 4. CREATE PARTIES & CANDIDATES PER POLL (Now 6 Parties including Independent)
        # ---------------------------------------------------------
        print("🚩 4. Creating Parties and Candidates...")
        
        party_names_pool = [
            ['Alpha Alliance', 'Beta Bloc', 'Gamma Group', 'Delta Dynamics', 'Epsilon Echo'],
            ['Zeta Zeal', 'Eta Engineers', 'Theta Thinkers', 'Iota Innovators', 'Kappa Knights'],
            ['Lambda Leaders', 'Mu Movement', 'Nu Nation', 'Xi X-factor', 'Omicron Order']
        ]

        poll_position_candidates = {p.poll_id: {pos: [] for pos in POSITIONS} for p in polls}

        for i, poll in enumerate(polls):
            # 🛠️ ADDED: Explicitly inject 'Independent' as the first party for every poll
            poll_party_names = ['Independent'] + party_names_pool[i] 
            
            for p_name in poll_party_names:
                new_party = Party(poll_id=poll.poll_id, name=p_name)
                db.add(new_party)
                db.commit() 
                
                # Register a candidate for every single position for this party (including Independent)
                for position in POSITIONS:
                    fname, mname, lname = generate_name()
                    cand = Candidate(
                        poll_id=poll.poll_id,
                        first_name=fname, middle_name=mname, last_name=lname,
                        position=position,
                        party_name=p_name,
                        course_year=f"{random.choice(COURSES)} - {random.choice(YEARS)}",
                        description_platform=f"Vote {fname} for {position}!"
                    )
                    db.add(cand)
                    db.commit()
                    poll_position_candidates[poll.poll_id][position].append(cand)

        # ---------------------------------------------------------
        # 5. CASTING VOTES (With Tie-Prevention)
        # ---------------------------------------------------------
        print("🗳️ 5. Calculating and Casting precise votes...")
        voters = db.query(User).filter(User.role == 'Student', User.is_active == True).all()
        
        votes_to_insert = []

        for poll in polls:
            is_ongoing_poll = (poll.status == "Active")
            
            # Determine eligible voters for this specific poll
            poll_voters = []
            for v in voters:
                # Rule: John does NOT vote in the ongoing poll
                if is_ongoing_poll and v.email == "john@lnu.edu.ph":
                    continue
                poll_voters.append(v)

            total_voters = len(poll_voters)

            for position in POSITIONS:
                candidates_for_pos = poll_position_candidates[poll.poll_id][position]
                
                # Get our mathematically perfect, tie-free vote distribution for 6 candidates
                vote_distribution = get_unique_vote_distribution(total_voters)
                
                # Map those votes to the 6 candidates
                pool_of_votes = []
                for cand, vote_count in zip(candidates_for_pos, vote_distribution):
                    pool_of_votes.extend([cand.candidate_id] * vote_count)
                
                # Shuffle the pool so it's randomly assigned to the users
                random.shuffle(pool_of_votes)
                
                # Assign to users
                for user, assigned_cand_id in zip(poll_voters, pool_of_votes):
                    votes_to_insert.append(Vote(
                        user_id=user.user_id,
                        poll_id=poll.poll_id,
                        candidate_id=assigned_cand_id
                    ))

        # Bulk insert all votes instantly
        db.bulk_save_objects(votes_to_insert)
        db.commit()

        print("\n🎉 SUCCESS: Election data generated perfectly!")
        print(f"   - Polls created: 3")
        print(f"   - Total Parties: 18 (6 per poll, including Independent)")
        print(f"   - Total Candidates: 108")
        print(f"   - Total Votes Cast: {len(votes_to_insert)}")
        print(f"   - 'john@lnu.edu.ph' voted in expired polls but NOT the ongoing one.")
        print(f"   - No voting ties exist within any position.")

    except Exception as e:
        print(f"❌ Error occurred: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_advanced_data()