import smtplib
import time
import sys
import os

print "Usage:python", sys.argv[0], "[recipient](1..n) reports_dir"
print "Example:python", sys.argv[0], " wilson@ex.com jake@ex.com /opt/reports"

# constants
fromaddr = "bpm2clouddecker@gmail.com"
password = '********'

def timestamp():
    ISOTIMEFORMAT = "%Y-%m-%d-%X"
    return str(time.strftime(ISOTIMEFORMAT))

def send_mail(fromaddr, password, toaddrs, reports_dir):
    server = smtplib.SMTP('smtp.gmail.com:587')
    server.ehlo()
    server.starttls()
    server.login(fromaddr, password)
    for x in toaddrs:server.sendmail(fromaddr, x, mail_content(x, reports_dir))
    server.quit()
    
def read_surefire_report(reports_dir):
    report_lines = []
    if os.path.isdir(reports_dir):
        reports = os.listdir(reports_dir)
        for x in reports:
            if x.endswith(".txt"):
                with open("%s/%s" % (reports_dir, x), "r") as f:
                    report_lines.extend(f.readlines())
    return report_lines

def mail_content(recipient, reports_dir):
    recipient_name = recipient.split("@")[0]
    site_endpoint = "http://idlerx.cn.ibm.com:8080/sce-deck"
    mail_body = [
      "From: Decker<%s>" % fromaddr,
      "To: %s<%s>" % (recipient_name, recipient),
      "Subject: SCE-DECK-REPORT-" + timestamp(),
      "",
      "hi,%s" % recipient_name,
      "",
      "I am glad to tell you that SCE Deck for BPM was rebuilt successfully just now.",
      "Some reports may help you get the latest status about BPM v85 SCE Prj.",
      "",
      "Junit Testcase %s/surefire-report.html" % site_endpoint,
      "Test Coverage  %s/cobertura/index.html" % site_endpoint,
      "Tag List %s/taglist.html" % site_endpoint,
      "Duplicate code detection %s/cpd.html" % site_endpoint ,
      "Verification of coding rules %s/pmd.html" % site_endpoint,
      "",
      "Test Result Quick View:"
      ]
    mail_body.extend(read_surefire_report(reports_dir))
    mail_body.extend(
      [ "What's more ?",
      "Project,Dependencies,javadoc ,test javadoc ,Test Source Xref, Source Xref ...",
      site_endpoint,
      "",
      "----------------------",
      "Decker Sce",
      "BPM SCE Automation Manager",
      "----------------------",
      "The Journey is the Reward."
      ])
    return "\r\n".join(mail_body)

if __name__ == "__main__":
    recipients = sys.argv[1:-1:] if len(sys.argv[:]) > 2 else [] 
    reports_dir = sys.argv[-1]
    if len(recipients) > 0:
        print ">> Send mail to ", ",".join(recipients)
        print ">> Reports - ", reports_dir
        send_mail(fromaddr, password, recipients, reports_dir)
    else:
        print ">> No boby is in the recipients."
