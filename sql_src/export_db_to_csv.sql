SPOOL 'csv/wiki_dialogue.csv'
SET MARKUP CSV ON;
SELECT "CHARACTER", en_dialogue, route, act, game FROM dialogue;
SET MARKUP CSV OFF;
