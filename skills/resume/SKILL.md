---
name: resume
description: Write, expand, tune or check a resume for the user or someone they are helping. Use when the user says resume, CV, tailor my resume, make it more professional, will it pass ATS, or hands over a resume file or a job posting. Built for students and early-career people with thin work history, and it never invents facts.
---

# resume

The user is not a recruiter and often helps someone else, such as a student with a short work history. A resume with one made-up number or skill can cost that person an interview, or a job after they are hired. So the job is to present true facts well, and to ask for the facts that are missing.

## Where the facts come from

Use only what the person's current resume, the user's messages, or the person themselves have said. A resume is the one document where a plausible guess does real harm, because the person signs it and answers questions about every line in an interview.

- Find a missing fact by asking one question that names the gap and why it matters. Never fill it with a typical duty for that job title.
- Leave a visible `[bracket]` for a gap while drafting. Brackets must be gone before anything is called final.
- Numbers go in only when the person gave them. A bullet with no number is better than one with a guessed number, so do not use "when you don't have exact numbers" tricks.
- A skill, tool, level or date the person has not claimed does not go in. Convert grades or self-ratings to plain words the person can defend out loud, such as "basic".
- Check dates against today. A graduation date already in the past means the resume is stale; ask.

## What a strong version looks like

- One page for a student or early-career person, with the strongest facts for the target role first. For a design student that means education, software, coursework and projects before unrelated jobs.
- A summary of two to four sentences with no "I". Start with the role or a verb ("Graphic design student completing a BA…", "Works in…"). Name tools and one concrete fact, not traits like "dependable" or "hard worker".
- Bullets start with a plain verb and say what was done and, if known, the result. The person's own words from earlier drafts are the best source; tighten them, do not replace them with generic phrases.
- A job where the person moved up or took on more gets that story in one line, in the person's words.
- Standard section names: Summary, Education, Skills, Experience, Languages, Activities. Hiring software looks for these.
- A portfolio link in the header for any design or creative role. If there is none, say that it is the biggest gap.

## Hiring software (ATS) rules

Hiring software often reads a file as plain text in order, so layout tricks scramble it.

- One column. No tables, text boxes, columns, images, or contact details in the page header or footer.
- Plain fonts at 10 to 12 pt, real bullets, and dates written the same way everywhere.
- Keep the design, such as heading colour or rules, in paragraph formatting that survives plain text.
- When a job posting is given, match its real terms only where the person truly has that experience. Drop any keyword the person cannot back up in an interview.
- After building, extract the text with `pdftotext` and read it. If the order is scrambled or a section is missing, the layout failed.

## Voice

Run the `/humanizer` skill on the prose before showing it. Resumes made by AI show the same tells as other text: staged contrasts, triads of traits, inflated claims. Keep the person's real wording where it already reads like them.

## Files

- Ask which format is wanted. The default is a Word file to edit and a PDF to send, from one source, so they match.
- Before changing an existing file, save a dated copy beside it. Never overwrite the original.
- Keep versions in a `revisions/` folder as `Name_Resume_v01`, `v02` and so on, a Word and a PDF each. Keep the newest 10 and delete older ones when a new one arrives, so the folder stays short.
- Keep the current version at the top level under a clear name, such as `Name_Resume_new.docx`.
- Keep the look of the person's existing template (fonts, colours) unless the user asks for a change.
- If no Word library is installed, do not install one for a single file. Write the `.docx` as a zip of plain XML with Python's `zipfile` and make the PDF with `soffice --headless --convert-to pdf`.
- Look at the rendered page as an image and count the pages. The check is the page itself, not the code that made it.

## Tailoring to a job

Keep one master resume with every true fact, and make a shorter version per posting. Reorder and trim the master. Do not add to it. If the posting asks for something the person lacks, say so plainly and suggest how to get it, such as a class project or a free course, instead of stretching the truth.

## Done

The work is done when all of these hold, and the reply says which are met:

1. Every line traces to something the person said or showed. Any gap is listed as a question, ranked by how much answering it helps.
2. No `[bracket]` is left, or the reply states that one is left and why the file is not final.
3. The page count is right, the text extracts in a sensible order, and the file was opened and looked at.
4. The prose went through `/humanizer`.
5. The previous version is in `revisions/`, and the folder holds no more than 10.
