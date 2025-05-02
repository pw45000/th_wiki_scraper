# th-wiki-scraper
th-wiki-scraper is a web scraper and database made for extracting and storing dialogue from a video game wiki (i.e the [Touhou Wiki](https://en.touhouwiki.net/wiki/Touhou_Wiki)).  

## Features

 - A Scrapy web scraper capable of extracting dialogue from 155 wiki pages regarding traditional mainline Touhou Games (Touhou 6-8, Touhou 10-18).
 - Spoofing capabilities that allow bypassing of Cloudflare anti-scraping protections via the use of virtual displays (via `xvfb`), proxies, and Chrome flags.  
 - An Oracle DB that stores all extracted dialogue data and sanitizes all 12888 records via Oracle SQL and PL/SQL.   

## Installation 
### Prerequisites ### 

 - A Debian-based Linux distribution due to the way this project handles installations (this project was developed using Ubuntu). This project can also be run on Windows via Ubuntu on WSL2.  
 - Have Docker Installed. Depending on your distribution, you can use the [Ubuntu](https://docs.docker.com/engine/install/ubuntu/) or [Debian](https://docs.docker.com/engine/install/debian/) installation instructions. 
 - Have an appropriate proxy set in `wiki/wiki/settings.py` set. Here, it is default set to `0.0.0.0:8000` where everything to the left of the colon is your proxy's ip and everything to the right of your colon is your proxy's port. I would personally use a HTTPS proxy listed in this [repository](https://github.com/proxifly/free-proxy-list/blob/main/proxies/protocols/https/data.json), however a paid residential proxy would have better results. 

### xvfb Installation ###
Run the following command to install `xvfb`: 
```
sudo apt install xvfb
```
### Python Libraries Installation ###
To install the python libraries relevant to this project, run the following command in the root of this project's directory (assume all of the proceeding scripts are also ran at the root): 
```
pip install -r requirements.txt
```

### Oracle Instant Client & DB Free Installation & Configuration ###
You can install Oracle Instant Client, Oracle DB Free, and SQL*Loader by running the following two commands: 
```
bash bash_src/docker_create_db.sh 
bash bash_src/install_client_run.sh
``` 
To ensure you have a proper installation, run the following commands: 
```
sqlplus 
sqlldr
```
In an improper installation, you would encounter one or both of the following error messages: 
`sqlldr: command not found`, `sqlplus: command not found`. Refer to the Troubleshooting if this occurs.  Please note that if `sqlplus` is properly installed, you will need to enter `exit` or `CTRL+C` to exit the menu before running the `sqlldr` command. 

If you have confirmed you have a proper installation, run the following command: 
```
bash bash_src/fix_client_installation.sh
```

## Usage ##
Before beginning, be sure that a docker instance is running with your DB. This can be achieved by running 
```
bash bash_src/docker_run_db.sh
```
But is generally unnecessary unless you have restarted your machine after your initial Docker installation. 

Also note that the `samples` directory contains files that can be used as references to ensure that each stage is being followed correctly. Note however that the exact order of your rows will likely be different due to how Scrapy handles scraping pages. 

Should you wish to run commands directly in `sqlplus` for debugging, run this command: 
``` 
bash bash_src/client_run.sh
```

### Step 1: Scraping The Wiki ### 
To scrape the Wiki, the command:
```
bash bash_src/scrape.sh
```
To verify that your scraper has suceeded, gradually monitor the output logs and also ensure that you the file `wiki_dialogue.csv` under the `csv` directory. 
### Step 2: Preprocessing for SQL*Loader ### 
Before `wiki_dialogue.csv` is inserted into Oracle DB via SQL*Loader, it must prepare itself in two ways: 

 - Remove embedded newlines, as SQL*Loader cannot process these. The method chosen is to replace embedded newlines with a dummy token `<fix123>`. 
 - Gather the rough length of the longest string in each column of the CSV. While this will not be 1-1 with how Oracle DB processes the string lengths, it should give a good estimate. 

Running the following command, 
```
python3 preprocess_csv_oracle.py
```
The previous CSV is overwritten and there is also a new JSON file called `max_len.json` which contains a length estimates for each of the columns. Generally, the main file for transfering, `transfer_csv.ctl` adheres to these maximum lengths, excluding jp_dialogue and en_dialogue  which are set to 1000, as these contain Unicode characters which may be processed differently in Oracle DB. For reference, the longest string length in jp_dialogue and en_dialogue are 408 and 715 respectively. 

### STEP 3: Transferring the CSV and DB Sanitizing ###
This is the largest step, as it: 

 1. Transfers `wiki/wiki_dialogue.csv` to Oracle DB
 2. Sanitizes the table created from the transfer process, DIALOGUE. 
 3. Exports the sanitized contents to `wiki_wiki_dialogue.csv`, overwriting it in the process. The column JP_DIALOGUE is dropped as this project is interested in English dialogue only. 

Note that realistically, we would typically do the bulk of preprocessing in our CSV prior to transferring. However, this is done in PL/SQL and Oracle SQL in this project as an excercise.

The command that corresponds with this step is as follows: 
```
bash bash_src/master_create_and_clean.sh
```

Below this is more information regarding how sanitization was performed. If you are not interested in this, please skip to step 4. 

Here are some examples of properly formatted dialogue (note how the JP column was included, as all rows with the 'ACT' column set to 'Endings' all lack JP_DIALOGUE): 

| CHARACTER | JP_DIALOGUE              | EN_DIALOGUE                                           | ROUTE | ACT      | GAME                        |
|-----------|--------------------------|-------------------------------------------------------|-------|----------|-----------------------------|
| Hatate    | (empty)                  | So you're sure she said she was a god of impairments? | Aya   | Endings  | Hidden_Star_in_Four_Seasons |
| Reimu     | 迷い込んではいないわよ 私は山へ行きたいんだから | But I'm not lost. I just want to go to the mountain.  | Reimu | Scenario | Mountain_of_Faith           |
| Marisa |   | Surely these people can't be from the moon. | Reimu_and_Yukari | Endings | Imperishable_Night |      |

Now, here are various examples of improperly formatted dialogue (generally in the order of where they were removed in the sanitization code): 
| ISSUE                                                                              | CHARACTER                     | JP_DIALOGUE                                                                                                         | EN_DIALOGUE                                                  | ROUTE        | ACT      | GAME                        |
|------------------------------------------------------------------------------------|-------------------------------|---------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------|--------------|----------|-----------------------------|
| Contains an footnote                                                               | Marisa                        | 「人類は十進法を採用しました」 って見えるな                                                                                              | It looks to me more like humankind learning how to add.[1]   | Marisa       | Scenario | Embodiment_of_Scarlet_Devil |
| Contains a newline placeholder (i.e. \<fix123\>                                      | \<fix123\>Reimu\<fix123\>\<fix123\> | \<fix123\>久々のお仕事だわ。\<fix123\>\<fix123\>                                                                                | \<fix123\>It's been a while since my last job.\<fix123\>\<fix123\> | Reimu        | Scenario | Embodiment_of_Scarlet_Devil |
| Contains broken character tags/formatting, JP_DIALOGUE and EN_DIALOGUE are swapped |                        | \<c\$Reimu:\$12345678\> "You could use a little time in the sun, don't you think? \<c\$\$12345678"\> You look sickly pale." |                                                       | Reimu        | Endings  | Embodiment_of_Scarlet_Devil |
| Improper Game Name                                                                 | Marisa                        |                                                                                                              | Ah, thanks.                                                  | Marisa       | Endings  | Th17                        |
| Improper Team Name                                                                 | Yukari                        | ええ、夜の方が自然が豊かってことよ。                                                                                                  | Yes, because nature thrives during the night.                | Barrier_Team | Scenario | Imperishable_Night          |
| Not a Dialogue Record                                                              |                        | BGM: クリスタライズシルバー                                                                                                    | BGM: Crystallized Silver                                     | Reimu        | Scenario | Perfect_Cherry_Blossom      |
| Improper formatting, not a dialogue record                                         |                        |                                                                                                              | \<c\$Congratulations, all clear! Just as I'd expected!\$\>       | Marisa       | Endings  | Mountain_of_Faith           |
| Valid Dialogue but lacks character tag (filled in via last character who spoke)    |                        |                                                                                                              | She's reached an understanding with us."                     | Marisa       | Endings  | Mountain_of_Faith
| Contains a special space (ideographic), which turns into ?? upon export | Yukari    |      | Morning came in the end, but nothing was settled. 　　"I'm a methodical person. 　　 All this activity doesn't suit me. Good night." 　　With that, she disappeared to... somewhere.  　　Literally, somewhere. | Reimu_and_Yukari | Endings | Imperishable_Night |         

### Step 4: Asking Questions Via Queries
Now that the data has been sanitized, answers to questions (e.g. What was the most frequent X in Y column?)  regarding the data can be returned through queries. 

A demonstration of this can be found by running the following command: 
```
bash bash_src/query_questions.sh
``` 
which then outputs the following to `question_answers.txt` in the root directory of this project: 
```
1. What is the game with the most dialogue?
Subterranean_Animism
2. What is the game with the least dialogue?
Embodiment_of_Scarlet_Devil
3. Which character(s) has the most lines of dialogue?
Marisa
4. Which character(s) has the least lines of dialogue?
Both
Sakuya_and_Yuyuko
??/
Marisa_and_Yuyuko
Remilia_and_Reimu
Reimu_and_Yuyuko
Sakuya.
Remilia_and_Marisa
Cirno & Larva
??
5. How many lines of dialogue does the Unknown character have? (Any character labeled as any variation of ?)
       684
6. What is the single longest line of dialogue?

The one possessing you

is an eagle spirit from Toutetsu's gang, right?


To think the prideful Gouyoku Alliance would

cooperate with Kiketsu Family, how unexpected.


Thanks to you defeating Keiki,

the Animal Realm has returned to being a competitive society.


And thus, the strongest, fastest army,

the Keiga Family, will rule all.


Soon the Animal Realm shall

come under our possession.


Perhaps not just the Animal Realm, but Hell and the Human Realm too......?

My dreams are broadening.


7. What is the single shortest line of dialogue?
"?"

```



## Troubleshooting ##
### Improper Oracle Instant Client or Oracle SQL*Loader Installation
The single most common issue encountered is that `sqlldr` is not properly installed. In order to fix this, run the following command: 
```
bash bash_src/fix_client_installation.sh
```
If that fails, please instead run the following commands instead: 
```
export PATH=/opt/oracle/instantclient_23_7:$PATH  
export ORACLE_HOME=/opt/oracle/instantclient_23_7
```
Should that fail, please uncomment the following lines in `bash_src/fix_client_installation.sh` (i.e. remove the `#` in front of the line) as needed: 
```
sudo ln -s /opt/oracle/instantclient_23_7/sqlplus /usr/bin/sqlplus  
sudo ln -s /opt/oracle/instantclient_23_7/sqlldr /usr/bin/sqlldr
```
Then, repeat the first command used in this section. 
### Scraper Fails Due to a Chrome Error ###
Generally, if you have errors such as `ERR_TUNNEL_CONNECTION_FAILED` or `ERR_CONNECTION_RESET` it means your proxy has failed and you will need to use a new one. This happens most commonly with free proxies. However, there might be an exception for the following error: `ERR_CONNECTION_TIMED_OUT` where occasionally it is a result of using a proxy from far away--- attempt to rerun your scraper again for a few times to see if it works. If it has not, it is also likely a proxy failure. 

### Scraper Encounters a 403 Error and/or Pages Are Missing ### 
Unfortunately, this means the scraper has been detected by Cloudflare's anti-bot detection service. Gradually lower the value of `AUTOTHROTTLE_TARGET_CONCURRENCY` in `wiki/wiki/settings.py`. Some examples of extremely careful values would be `0.05` or `0.01`.
