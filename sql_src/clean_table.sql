-- Generally, we would use a temp table for this cleaning operation, but as I understand it, temporary tables
-- are generally wiped after the execution of the script that created it.
-- Given that we need to run one more script after this one, I believe in this case it would be easier to create
-- a table and then DROP it explicitly in the proceeding script. That and dynamic SQL has some security implications.
CREATE TABLE cleaning AS SELECT * FROM DIALOGUE;

CREATE OR REPLACE PROCEDURE remove_footnotes AS
BEGIN
    UPDATE cleaning SET en_dialogue = REGEXP_REPLACE(en_dialogue, '\[\d+\]|\(\d+\)', '');
    UPDATE cleaning SET jp_dialogue = REGEXP_REPLACE(jp_dialogue, '\[\d+\]|\(\d+\)', '');
END;
/

CREATE OR REPLACE PROCEDURE replace_newline_placeholder AS
BEGIN
    -- Some characters speak simultaneously, which will need to be accounted for. This is broken by a specific pattern
    -- of newlines, and since it is much easier to make a regex with our temporary token, we do our fixing here.
    UPDATE cleaning SET "CHARACTER" = REGEXP_REPLACE("CHARACTER", '^<fix123>([^<>]+)<fix123>([^<>]+)<fix123><fix123>.*$', '\1_and_\2');
    -- CHR(10) = newline
    UPDATE cleaning SET en_dialogue = REPLACE(en_dialogue, '<fix123>', chr(10));
    UPDATE cleaning SET jp_dialogue = REPLACE(jp_dialogue, '<fix123>', chr(10));
    UPDATE cleaning SET "CHARACTER" = REPLACE("CHARACTER", '<fix123>', chr(10));
END;
/

CREATE OR REPLACE PROCEDURE fix_broken_character_tags AS
BEGIN
    -- We need to use the 6th argument to only return the first capture group.
    -- See here: https://stackoverflow.com/a/7759146
    -- Extracts the character from a messed up string, placing it in the correct column, and then removing
    -- the garbage segments of the text, aka strings like <c$(character):$12345678>
    -- Important Note: jp_dialogue in these cases IS en_dialogue, but the fix would be coming later.

    UPDATE cleaning SET jp_dialogue = REPLACE(jp_dialogue, '<c$$12345678">', '') WHERE GAME = 'Th06' OR GAME = 'Th07';
    UPDATE cleaning SET "CHARACTER" = REGEXP_SUBSTR(jp_dialogue, '<c\$(.*?):\$', 1, 1, NULL, 1) WHERE GAME = 'Th06' OR GAME = 'Th07';
    UPDATE cleaning SET jp_dialogue = REGEXP_REPLACE(jp_dialogue, '<c\$.*?:\$[0-9]+>\s?', '') WHERE GAME = 'Th06' OR GAME = 'Th07';

    UPDATE cleaning SET jp_dialogue  = REPLACE(jp_dialogue, '<l$$12345678">', '') WHERE GAME = 'Th08';
    UPDATE cleaning SET "CHARACTER"  = REGEXP_SUBSTR(jp_dialogue, '<l\$(.*?):\$', 1, 1, NULL, 1) WHERE GAME = 'Th08';
    UPDATE cleaning SET jp_dialogue  = REGEXP_REPLACE(jp_dialogue, '<l\$.*?:\$[0-9]+>\s?', '') WHERE GAME = 'Th08';
END;
/

CREATE OR REPLACE PROCEDURE fix_categorization AS
BEGIN
    -- All ending dialogue is placed in the wrong column. English dialogue is placed in the Japanese column.
    UPDATE cleaning SET jp_dialogue = en_dialogue, en_dialogue = jp_dialogue WHERE ACT = 'Endings';
END;
/

CREATE OR REPLACE FUNCTION find_real_game_name(numeric_name IN VARCHAR2)
RETURN VARCHAR2 AS
    -- Mirrors GAME column size
    real_name VARCHAR2(31);
BEGIN
    CASE numeric_name
        WHEN 'Th06' THEN real_name := 'Embodiment_of_Scarlet_Devil';
        WHEN 'Th07' THEN real_name := 'Perfect_Cherry_Blossom';
        WHEN 'Th08' THEN real_name := 'Imperishable_Night';
        WHEN 'Th10' THEN real_name := 'Mountain_of_Faith';
        WHEN 'Th11' THEN real_name := 'Subterranean_Animism';
        WHEN 'Th12' THEN real_name := 'Undefined_Fantastic_Object';
        WHEN 'Th13' THEN real_name := 'Ten_Desires';
        WHEN 'Th14' THEN real_name := 'Double_Dealing_Character';
        WHEN 'Th15' THEN real_name := 'Legacy_of_Lunatic_Kingdom';
        WHEN 'Th16' THEN real_name := 'Hidden_Star_in_Four_Seasons';
        WHEN 'Th17' THEN real_name := 'Wily_Beast_and_Weakest_Creature';
        WHEN 'Th18' THEN real_name := 'Unconnected_Marketeers';
        ELSE real_name := 'Naming Error Replacement';
    END CASE;
    RETURN real_name;
END;
/

CREATE OR REPLACE PROCEDURE fix_game_names AS
-- All games are abbreviated to things such as 'Th06' instead of their full name such as 'Embodiment_of_Scarlet_Devil'.
BEGIN
    UPDATE cleaning SET game = find_real_game_name(game) WHERE act = 'Endings';
END;
/

CREATE OR REPLACE FUNCTION find_team_name_replacement(team_alias IN VARCHAR2)
RETURN VARCHAR2 AS
    -- Mirrors ROUTE column size
    team_name VARCHAR2(25);
BEGIN
    CASE team_alias
        WHEN 'Barrier_Team' THEN team_name := 'Reimu_and_Yukari';
        WHEN 'Boundary_Team' THEN team_name := 'Reimu_and_Yukari';
        WHEN 'Magic_Team' THEN team_name := 'Marisa_and_Alice';
        WHEN 'Scarlet_Team' THEN team_name := 'Remilia_and_Sakuya';
        WHEN 'Netherworld_Team' THEN team_name := 'Youmu_and_Yuyuko';
        WHEN 'Ghost_Team' THEN team_name := 'Youmu_and_Yuyuko';
        ELSE team_name := 'Naming Error Replacement';
    END CASE;
    RETURN team_name;
END;
/

CREATE OR REPLACE PROCEDURE fix_team_names AS
-- Optional, but some Routes are listed under their alias rather than the two characters that compose it.
-- It would be more useful to have it as the latter since then we can see which teams appear more than once.
-- For instance, 'Magic_Team' is functionally 'Marisa_and_Alice', so it doesn't make sense to have two separate names.
-- Additionally, there are different names even within the game: 'Barrier Team' and 'Boundary Team' are the same.
BEGIN
    UPDATE cleaning SET route = find_team_name_replacement(route) WHERE game='Imperishable_Night';
END;
/

CREATE OR REPLACE PROCEDURE remove_non_dialogue_records AS
BEGIN
    UPDATE cleaning SET "CHARACTER" = REPLACE("CHARACTER", CHR(10), '');
    DELETE FROM cleaning WHERE "CHARACTER" IS NULL OR REGEXP_LIKE("CHARACTER", '^[[:space:]]+$');
    -- The above does not accurately capture all spaces, as some are special. This is on purpose, since the ones with
    -- special spaces are those which are formatted to be a continuation of a character's speech in certain endings.
    -- See fill_in_gaps.sql for more information.

END;
/

CREATE OR REPLACE PROCEDURE remove_translator_notes AS
BEGIN
    -- All translator notes are formatted such that in the string such that they look like this:
    -- "3 pints? Maybe 4 gallons?"(She uses the units...which roughly correspond to these amounts.)
    -- All translator notes are what is right of the quotations, and this regex removes them by splitting the str
    -- into two groups: 1) what is left of " and 2) what is right of ".
    UPDATE cleaning SET en_dialogue = REGEXP_REPLACE(en_dialogue, '^(".*?")\s*(.*)$', '\1');
END;
/

BEGIN
    remove_footnotes;
    replace_newline_placeholder;
    fix_broken_character_tags;
    fix_categorization;
    fix_game_names;
    fix_team_names;
    remove_non_dialogue_records;
    remove_translator_notes;
    -- Note that fill_in_gaps.sql should be executed after this script, as it's generally safer and easier to run
    -- DDL code in pure SQL and not dynamic SQL, i.e., in PL/SQL.
    COMMIT;
END;
/