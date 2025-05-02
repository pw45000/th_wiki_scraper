SET NEWPAGE 0
SET SPACE 0
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
set verify off
SET ECHO OFF
-- headers based on https://stackoverflow.com/q/16722089


SPOOL question_answers.txt;
-- Since we're using SQL PLUS, we can use PROMPT
-- https://stackoverflow.com/a/21708650
-- Order selection based on https://stackoverflow.com/a/56219759
PROMPT 1. What is the game with the most dialogue?
SELECT game FROM dialogue GROUP BY game ORDER BY COUNT(*) DESC FETCH FIRST 1 ROW ONLY;

PROMPT 2. What is the game with the least dialogue?
SELECT game FROM dialogue GROUP BY game ORDER BY COUNT(*) FETCH FIRST 1 ROW ONLY;

PROMPT 3. Which character(s) has the most lines of dialogue?
SELECT "CHARACTER" FROM dialogue GROUP BY "CHARACTER" ORDER BY COUNT(*) DESC FETCH FIRST 1 ROW WITH TIES;

PROMPT 4. Which character(s) has the least lines of dialogue?
SELECT "CHARACTER" FROM dialogue GROUP BY "CHARACTER" ORDER BY COUNT(*) FETCH FIRST 1 ROW WITH TIES;

PROMPT 5. How many lines of dialogue does the Unknown character have? (Any character labeled as any variation of ?)
SELECT COUNT(*) FROM dialogue WHERE "CHARACTER" LIKE '%?%';

PROMPT 6. What is the single longest line of dialogue?
-- based on https://tableplus.com/blog/2019/09/select-rows-with-longest-string-value-sql.html
-- note that the LIMIT 1 was replaced with FETCH FIRST 1 to comply with Oracle DB.
SELECT en_dialogue FROM DIALOGUE ORDER BY LENGTH(en_dialogue) DESC FETCH FIRST 1 ROW ONLY;

PROMPT 7. What is the single shortest line of dialogue?
SELECT en_dialogue FROM DIALOGUE ORDER BY LENGTH(en_dialogue) FETCH FIRST 1 ROW ONLY;


SPOOL OFF