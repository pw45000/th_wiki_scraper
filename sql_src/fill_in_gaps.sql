-- See https://stackoverflow.com/a/49958245. Basically turn all of the characters that are null into their last
-- character. Why? Because all dialogue from the Endings act have the characters as a set of spaces as the actual name.
-- The exception to this is when the following message appears inbetween dialogue:
-- "<c$Congratulations, all clear! Just as I'd expected!$>", hence, we will have to remove it.
-- characters were identified via inspection in SQL developer and
-- https://www.babelstone.co.uk/Unicode/whatisit.html

DELETE FROM cleaning where en_dialogue LIKE '%<c$%';
UPDATE cleaning SET "CHARACTER" = REPLACE("CHARACTER", UNISTR('\00A0'), NULL);
UPDATE cleaning SET "CHARACTER" = REPLACE("CHARACTER", UNISTR('\3000'), NULL);

-- In addition to CHARACTER having these special spaces, en_dialogue and jp_dialogue has these as well.
UPDATE cleaning SET en_dialogue = REPLACE(en_dialogue, UNISTR('\00A0'), '');
UPDATE cleaning SET en_dialogue = REPLACE(en_dialogue, UNISTR('\3000'), '');

TRUNCATE TABLE dialogue;
INSERT INTO dialogue SELECT last_value("CHARACTER" ignore nulls)
over(partition by act
  order by route, game
  rows between unbounded preceding and CURRENT ROW) as "CHARACTER", jp_dialogue, en_dialogue, route, act, game from cleaning;
DROP TABLE cleaning;
COMMIT;
