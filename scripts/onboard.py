import mysql.connector
import subprocess
import sys

# Configuration
CONFIG = {
    'host': 'localhost',
    'user': 'mailuser',
    'password': 'secure_password',
    'database': 'mailserver'
}

def get_db():
    return mysql.connector.connect(**CONFIG)

def add_domain(domain_name):
    db = get_db()
    cursor = db.cursor()
    try:
        cursor.execute("INSERT INTO virtual_domains (name) VALUES (%s)", (domain_name,))
        db.commit()
        print(f"Domain {domain_name} added successfully.")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

def add_user(email, password):
    # Hash password using doveadm
    hashed_pw = subprocess.check_output(['doveadm', 'pw', '-s', 'SHA512-CRYPT', '-p', password]).decode().strip()
    
    domain = email.split('@')[1]
    db = get_db()
    cursor = db.cursor()
    try:
        # Get domain ID
        cursor.execute("SELECT id FROM virtual_domains WHERE name = %s", (domain,))
        domain_id = cursor.fetchone()
        if not domain_id:
            print(f"Error: Domain {domain} does not exist. Add it first.")
            return

        cursor.execute("INSERT INTO virtual_users (domain_id, email, password) VALUES (%s, %s, %s)", 
                       (domain_id[0], email, hashed_pw))
        db.commit()
        print(f"User {email} added successfully.")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage:")
        print("  python onboard.py domain <domain_name>")
        print("  python onboard.py user <email> <password>")
        sys.exit(1)

    cmd = sys.argv[1]
    if cmd == "domain":
        add_domain(sys.argv[2])
    elif cmd == "user":
        add_user(sys.argv[2], sys.argv[3])
