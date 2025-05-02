import pandas as pd
import json

dialogue_df = pd.read_csv('csv/wiki_dialogue.csv')
dialogue_df = dialogue_df.fillna('')
dialogue_df = dialogue_df.replace('\n', '<fix123>', regex=True)
dialogue_df.to_csv('csv/wiki_dialogue.csv', index=False)
max_dict = {}

for column in dialogue_df.columns.tolist():
    # https://stackoverflow.com/a/61280960
    max_dict[column] = len(max(dialogue_df[column],key=len))

with open("max_len.json", "w+") as max_len_file:
    json.dump(max_dict, max_len_file, indent=4)
