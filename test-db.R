source("R/functions.R")

# ---- bench-params ----
test_cases <- "smb_local"
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
               db_dir <- ""
               out_dir <- "out/"
           },
           "smb_local" = {
               source("R/mount.R")
               mount_ooominds1_volume()
               db_dir <- "~/../../Volumes/ooominds1/User/ac1adk/test_db/"
               out_dir <- "out/"          
           },
           "smb_local_home" = {
               source("R/mount.R")
               mount_ooominds1_volume()
               db_dir <- "~/../../Volumes/ooominds1/User/ac1adk/test_db/"
               out_dir <- "out/"          
           },
           "smb_sharc" = {
               db_dir <- "/shared/ooominds1/User/ac1adk/test_db/"
               out_dir <- "out/"          
           },
           "sharc_scratch" = {
               db_dir <- paste0(tmp_dir,"/test_db")
               out_dir <- "out/" 
           },
           "sharc_data" = {
               db_dir <- "~/data/ac1adk/test_db/"
               out_dir <- "out/" 
           })
    
    cat(test_case, "\n")
    
    for(i in 2^(1:9)){
        create_testdb(test_case = test_case, 
                       test_size = i,
                       db_dir = db_dir,
                       out_dir = out_dir,
                       tmp_dir = tmp_dir)
    }
    
    out <- NULL
    for(i in 2^(1:9)){
        out <- dplyr::bind_rows(out, 
                                test_sqlite_io(test_case = test_case, 
                                               test_size = i,
                                               db_dir = db_dir,
                                               out_dir = out_dir,
                                               tmp_dir = tmp_dir))
    }
    
    # ---- bench-write_out ----
    write.csv(out, paste0(out_dir, "out_", test_case, ".csv"))
}