# ---- sqlite3-command ----
test_case <- "local"
test_size <- 100

switch(test_case,
       "local" = {
           db_path <- "test_db"
           out_dir <- "out"
       },
       "smb" = {
           source("R/mount.R")
           mount_ooominds1_volume()
           db_path <- "~/../../Volumes/ooominds1/User/ac1adk/test_db/test_db"
           out_dir <- "~/../../Volumes/ooominds1/User/ac1adk/test_db/"
       },
       "sharc_fast" = {
           db_path <- "/fastdata/ac1adk/test_db/test_db"
           out_dir <- "/fastdata/ac1adk/test_db/" 
       },
       "sharc" = {
           db_path <- "/data/ac1adk/test_db/test_db"
           out_dir <- "/data/ac1adk/test_db/" 
       })


create_db <- paste0("rm -f ",db_path,"

sqlite3 ",db_path," <<EOF

CREATE TABLE lexicon (
wordID INTEGER PRIMARY KEY,
word TEXT
);

CREATE TABLE corpus (
ID INTEGER PRIMARY KEY,
wordID INTEGER,
linenumber INTEGER,
chapter INTEGER,
book TEXT
);

EOF")

# ---- create-db ----
system(create_db)
db <- dbConnect(RSQLite::SQLite(), dbname = db_path)

# ---- create-corpus ----
depend <- c("DBI", "RSQLite", "dplyr", "janeaustenr", "stringr", "tidytext")
if (!require("pacman")) install.packages("pacman")
pacman::p_load(depend, character.only = T)

corpus <- austen_books() %>%
    group_by(book) %>%
    mutate(linenumber = row_number(),
           chapter = cumsum(str_detect(text, regex("^chapter [\\divxlc]",
                                                   ignore_case = TRUE)))) %>%
    ungroup() %>%
    unnest_tokens(word, text)

# ---- create-lexicon ----
lexicon <- corpus %>% pull(word) %>% unique() %>% sort() %>% 
    tibble(word=.) %>% mutate(wordID = 1:n()) 


# ---- create-corpus-wordID ----
corpus <- corpus %>% 
    mutate(wordID = factor(word, levels = lexicon$word) %>% as.numeric, 
           book = as.character(book)) %>% 
    select(-word)
corpus <- do.call("bind_rows", replicate(test_size, corpus, simplify = FALSE)) %>% 
    mutate(ID = 1:n())


populate_db <- function(db, corpus, lexicon, index = "wordID"){
    for(table in c("corpus", "lexicon")){
        dbWriteTable(db, name = table, value = get(table)[dbListFields(db, table)], 
                     append = T, header = F)
        dbExecute(db, paste0("CREATE INDEX ", index,"_", table, 
                             "_index ON ",table," (",index,")"))
        cat(table, "complete \n")
    }
}

# ---- pop-db ----
populate_db(db, corpus, lexicon)
dbDisconnect(db)

# ---- test-db ----
db <- dbConnect(RSQLite::SQLite(), dbname = db_path)
t0 <- Sys.time()
dbGetQuery(db, "SELECT * FROM corpus INNER JOIN lexicon ON corpus.wordID = lexicon.wordID")
t1 <- Sys.time()
cat(t1 - t0)
out <- list(db_path = db_path,
            sessionInfo = sessionInfo(),
            t0 = t0,
            t1 = t1)
saveRDS(out, paste(paste(out_dir, test_case, sep = "/"), "db-test-out.rds", sep = "_"))
dbDisconnect(db)