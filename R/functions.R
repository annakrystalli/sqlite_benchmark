
# ---- sqltb-pkgs----
depend <- c("DBI", "RSQLite", "dplyr", "janeaustenr", "stringr", "tidytext", "NCmisc")
if (!require("pacman")) install.packages("pacman")
pacman::p_load(depend, character.only = T)

# ---- sqltb-create_db----
create_testdb <- function(test_case = "local", test_size = 10, 
                           db_dir = "", out_dir = "out/", 
                           tmp_dir = NULL){
    
    db_path <- paste0(db_dir, "test_db_", test_size)
    if(db_dir != ""){
        dir.create(db_dir, showWarnings = FALSE, recursive = TRUE)
        }
    
    # ---- create-corpus ----   
    create_db <- paste0(
"rm -f ",db_path,"
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
    t0 <- Sys.time()
    db <- dbConnect(RSQLite::SQLite(), dbname = db_path)
    
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
    cat("test_case: ", test_case, "- test_size: ", test_size, "CREATE DB - time elapsed: ", 
        Sys.time() - t0, "\n \n")
}
    
# ---- sqltb-test-db ----
test_sqlite_io <- function(test_case = "local", test_size = 10, 
                           db_dir = "", out_dir = "out/", 
                           tmp_dir = NULL) {
    
    db_path <- paste0(db_dir, "test_db_", test_size)    
    db <- dbConnect(RSQLite::SQLite(), dbname = db_path)
    t0 <- Sys.time()
    dbGetQuery(db, "SELECT * FROM corpus INNER JOIN lexicon ON corpus.wordID = lexicon.wordID")
    t1 <- Sys.time()
    cat("test_case: ", test_case, "- test_size: ", test_size, "TEST JOIN - time elapsed: ", t1 - t0, "\n \n")
    
    dbDisconnect(db)
    
    tibble(test_case = test_case, test_size = test_size, 
           db_size = file.info(db_path)$size,
           time_elapsed = t1 - t0, 
           R.version = sessionInfo()$R.version$version.string,
           platform = sessionInfo()$platform,
           running = sessionInfo()$running)
}