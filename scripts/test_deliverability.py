import smtplib
from email.mime.text import MIMEText

# SMTP Details (Nuvvu mundhu pampina keys)
SMTP_SERVER = "email-smtp.us-east-1.amazonaws.com"
SMTP_PORT = 587
USERNAME = "AKIAXZLAHVPE5XWIOCXY"
PASSWORD = "BKdCKi3Xqr7Aaonr+jmnMT0KRSoxabiRCqsDNSsqr5hA"

def send_test_mail():
    msg = MIMEText("This is an automated deliverability test.")
    msg['Subject'] = "Automated Infrastructure Test"
    msg['From'] = "info@sree84s.site"
    msg['To'] = "sreekanthpaleti1999@gmail.com"

    try:
        server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
        server.starttls()
        server.login(USERNAME, PASSWORD)
        server.send_message(msg)
        server.quit()
        print("Success: Email sent!")
    except Exception as e:
        print(f"Error: {e}")

# Loop to send 10 emails
for i in range(20):
    send_test_mail()