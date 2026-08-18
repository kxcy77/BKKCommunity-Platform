# Elderly User Acceptance Test

This test must be completed with at least six BKK participants aged 60 or older. Automated checks cannot replace it.

## Pass criteria

- Every Must task passes without a critical defect.
- At least 80% of all tasks are completed without help.
- The average ease-of-use rating is at least 4 out of 5.
- No participant is misled into attending, travelling to, sharing or saving a demonstration event.
- Text remains readable at 200% scaling and every task can be completed with TalkBack or VoiceOver.

## Test setup

- Use a physical Android device and a physical iPhone where possible.
- Test the website with a mouse or trackpad and with keyboard only.
- Use test accounts and clearly labelled test content. Do not use a participant's real password.
- Ask the participant to think aloud. Do not point to a control or tell them which button to press.
- Record whether help was needed, the point of confusion and the exact words the participant used.

## Must tasks

1. Sign in using an existing account.
2. Return to Home after opening another section.
3. Find an upcoming event and explain its time and location.
4. Confirm attendance for a real test event, then cancel it.
5. Identify that the demonstration event is not real and cannot accept attendance.
6. Find a discount and explain how to claim it.
7. Find a local service phone number.
8. Contact BKK for help.
9. Request a password-reset code and create a new password.
10. Sign out.

## Accessibility checks

- Repeat tasks 1, 3, 6 and 8 at 200% text scaling.
- Repeat tasks 1, 3 and 8 with TalkBack on Android or VoiceOver on iOS.
- On the website, repeat tasks 1, 3 and 8 using Tab, Shift+Tab, Enter and arrow keys only.
- Confirm that focus is visible, labels are read correctly, controls are at least 48px/dp/pt high and status is never communicated by colour alone.

## Evidence table

| Participant | Device | Independent tasks / 10 | Critical defect? | Ease rating / 5 | Main confusion | Evidence reference |
|---|---|---:|---|---:|---|---|
| P1 |  |  |  |  |  |  |
| P2 |  |  |  |  |  |  |
| P3 |  |  |  |  |  |  |
| P4 |  |  |  |  |  |  |
| P5 |  |  |  |  |  |  |
| P6 |  |  |  |  |  |  |

## Defect rule

Treat a problem as critical if it can cause account loss, false attendance, travel to a fake event, disclosure of personal information, inability to sign in/reset a password, or inability to contact BKK. Stop the pilot until every critical defect is fixed and retested.
