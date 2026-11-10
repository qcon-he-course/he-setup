# Decisions: pc-303

Ticket: PC-303 Show each pet's age on the owner's page

## Decided

- **D1** The owner's page shows each pet's age in whole years for a pet one year old or older: "1 year", "3 years". Under a year, in whole months: "1 month", "5 months". Under a month: "under a month". Decided with the ticket, 2026-11-02.
- **D2** The age is as of today, worked out when the owner's page is shown. Nothing new is stored, and the schema does not change. Decided with the ticket, 2026-11-02.
- **D3** A birthday counts on the day itself: a pet born 2023-11-02 is 3 years old on 2026-11-02 and 2 years old on 2026-11-01. A pet born on 29 February has its birthday on 1 March in a year with no 29 February. Decided with the ticket, 2026-11-02.
- **D4** A pet with no stored birth date shows no age. Decided with the ticket, 2026-11-02.
- **D5** *Amended by D7 (Q1, 2 November): the texts go into every language file, in English; the rest stands.* The label is "Age", next to the pet's birth date. The texts are English, in `messages.properties` only; the other language files fall back to it until a translation ticket. Decided with the ticket, 2026-11-02.
- **D6** Any further decision this change needs goes to a person: stop and say so. Decided with the ticket, 2026-11-02.
- **D7** The age texts and the "Age" label go into every language file, with the English text, until a translation ticket. `I18nPropertiesSyncTest` stays as it is. Replaces D5's "in `messages.properties` only", which that test does not allow. Asked as Q1 in e14's proposal (e23, round 1), answered 2026-11-02. Rejected: translating them now; changing the sync test.
- **D8** A month counts when its day has come. When the current month has no such day, the month counts from the 1st of the next month: a pet born on 31 January is under a month old on 28 February and 1 month old on 1 March. The same rule as 29 February in D3. Asked as Q2 in e14's proposal (e23, round 1), answered 2026-11-02. Rejected: the last day of a short month counts as the day.
- **D9** A pet whose stored birth date is after today shows no age, as a pet with no birth date does (D4). Asked as Q3 in e14's proposal (e23, round 1), answered 2026-11-02. Rejected: "under a month"; a warning text.
- **D10** A pet that shows no age still shows the "Age" label, with an empty value, so every pet's details have the same shape. Asked as Q4 in e14's proposal (e23, round 1), answered 2026-11-02. Rejected: leaving the entry out.
- **D11** "Today" is the date in the server's default time zone, the same today the pet forms use when they reject a birth date after today. No new setting. Asked as Q5 in e14's proposal (e23, round 1), answered 2026-11-02. Rejected: a clinic time zone setting.
- **D12** The glossary's entry for Age includes "under a month". The person changed `GLOSSARY.md` with this answer. Asked as Q6 in e14's proposal (e23, round 1), answered 2026-11-02.
