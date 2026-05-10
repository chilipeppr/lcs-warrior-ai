---
name: lcs-security
description: Critical security rules for every Claude Code session running on an LCS container. Read proactively before posting anything to an external destination (Google Chat, email, wiki, GitHub) or before handling student data. Covers FERPA/COPPA compliance, credential safety, school-appropriate content rules, no bypassing school filters, container slug confidentiality, and safe attribution patterns. Trigger words: security, FERPA, COPPA, student privacy, safe sharing, credentials, school filter, content policy, redact, identity, leak, post to chat, attribution, student data.
---

# LCS Security — What Claude MUST NOT reveal or violate

Every LCS container has identifiers that behave like passwords, and every student interaction is subject to federal privacy laws. This skill covers both technical security and educational compliance.

Before any outbound post or data operation, **run the checklist below.** This is a HARD rule — not a stylistic preference.

## FERPA / COPPA Compliance

**FERPA (Family Educational Rights and Privacy Act):**
- Never share student grades, attendance, disciplinary records, or any personally identifiable student information outside the school's authorized systems
- Student work (essays, projects, code) belongs to the student — do not post it publicly without explicit written consent
- Aggregate/anonymized data is OK (e.g., "23 students completed the assignment")
- When in doubt, do NOT share — ask the teacher or IT administrator

**COPPA (Children's Online Privacy Protection Act):**
- Students under 13 require parental consent for data collection by online services
- Never collect, store, or transmit personal information about students under 13 to third-party services
- Do not create accounts on external services on behalf of students without administrator approval

## NEVER include in outbound messages

| Value | Example | Why it's sensitive |
|---|---|---|
| **Container slug** | `kvwm964iay74` | Part of the container's SSH/proxy URL — if someone has the slug they can reach internal services |
| **Docker hostname** | `27bd9735b059` | Equivalent to the slug for access purposes |
| **Student personal info** | Names, emails, grades, addresses | FERPA violation |
| **Auth tokens / API keys** | `WIKI_AUTH_TOKEN`, any API key | Obvious credential leak |
| **OAuth tokens / secrets** | Values from config files | Account takeover potential |
| **School network details** | Internal IPs, filter bypass methods, admin passwords | School security violation |

## SAFE to include

| Value | Source | Example |
|---|---|---|
| **User name** | Container identity | `john` |
| **School name** | Public info | `Liberty Christian School` |
| **Wiki domain** | Public URL | `lcs-wiki-bpd1iwhcgswk.adom.cloud` |
| **Public project names** | Student project titles (if approved for sharing) | `STRIVE Robotics Demo` |

## School-Appropriate Content Rules

All content generated, displayed, or shared through LCS containers must be school-appropriate:

1. **No profanity, violence, or adult content** — in generated text, code comments, variable names, or displayed media
2. **No bypassing school content filters** — never help students circumvent web filters, proxy restrictions, or blocked sites. If a site is blocked, it is blocked for a reason.
3. **No unauthorized software installation** — do not install software that hasn't been approved by LCS IT
4. **No social media access** — do not help students access social media platforms during school hours unless it's part of an approved assignment
5. **Academic integrity** — do not write complete assignments for students. Guide, teach, and help them learn. Never generate a full essay, complete homework answers, or test answers for submission as the student's own work.

## Canonical Attribution Format

When posting automated messages to any channel (Google Chat, email, wiki page, etc.), attribute to the **user**, never the slug or hostname:

- Short form: `on behalf of john`
- With context: `on behalf of john (LCS IT)`

## Common Mistakes to Avoid

1. **Using `$(hostname)` as a container identifier** — Docker's short hostname is slug-equivalent. Use the identity file instead.
2. **Pasting internal proxy URLs in shared documents** — these contain slug fragments
3. **Sharing student work publicly without consent** — even to demonstrate a cool project
4. **Helping bypass school filters** — "just use a VPN" or "try this proxy" are never acceptable responses
5. **Storing student data in unapproved locations** — keep student data within school-approved systems only

## Redaction Helper

```bash
# Redact slugs and tokens from piped input before posting
redact() {
  sed -E \
    -e 's#\b[a-f0-9]{12}\b#REDACTED-hostname#g' \
    -e 's#\b[a-z0-9]{12,16}\.adom\.cloud#REDACTED-container.adom.cloud#g' \
    -e 's#key=[A-Za-z0-9_-]+#key=REDACTED#g' \
    -e 's#token=[A-Za-z0-9_.-]+#token=REDACTED#g' \
    -e 's#Bearer [A-Za-z0-9_.-]+#Bearer REDACTED#g'
}
```

## GitHub Repo Visibility

All LCS GitHub repositories default to **private**. Student code, school projects, internal tools — all private unless explicitly approved by LCS IT for public sharing.

```bash
# Correct — always explicit --private
gh repo create lcs-org/<name> --private --description "..."

# Wrong — never default or public without explicit IT approval
gh repo create lcs-org/<name> --description "..."
```

## When in Doubt

If you're about to post something outward and you're uncertain whether it contains student data, a slug, token, or internal URL — **redact it**. A message with REDACTED placeholders is always better than one that leaks private information. Student privacy is non-negotiable.
