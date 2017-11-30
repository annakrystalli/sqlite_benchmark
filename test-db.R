source("R/functions.R")

# ---- bench-params ----
test_cases <- "smb"
tmp_dir <- NULL
args <- commandArgs(trailingOnly = TRUE)
if(length(args) != 0) {
    test_cases <- args[-1]
    tmp_dir <- args[1]}


# ---- bench-run ----
for(test_case in test_cases){
   # test-params
    switch(test_case,
           "local" = {
               db_path <- "test_db"
               out_dir <- "out/"
           },
           "smb_local" = {
               source("R/mount.R")
               mount_ooominds1_volume()
               db_path <- "~/../../Volumes/ooominds1/User/ac1adk/test_db/test_db"
               out_dir <- "out/"          
           },
           "smb_sharc" = {
               db_path <- "~/shared/ooominds1/User/ac1adk/test_db/test_db"
               out_dir <- "out/"          
           },
           "sharc_scratch" = {
               db_path <- paste0(tmp_dir,"/test_db")
               out_dir <- "out/" 
           },
           "sharc_data" = {
               db_path <- "~/data/ac1adk/test_db/test_db"
               out_dir <- "out/" 
           })
    
    cat(test_case, "\n")
    out <- NULL
    for(i in 2^(1:9)){
        out <- dplyr::bind_rows(out, 
                                test_sqlite_io(test_case = test_case, 
                                               test_size = i,
                                               db_path = db_path,
                                               out_dir = out_dir,
                                               tmp_dir = tmp_dir))
    }
    
    # ---- bench-write_out ----
    write.csv(out, paste0(out_dir, "out_", test_case, ".csv"))
}