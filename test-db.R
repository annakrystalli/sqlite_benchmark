source("R/functions.R")

# ---- bench-params ----
test_cases <- "smb"
args <- commandArgs(trailingOnly = TRUE)
if(length(args) != 0) {
    test_cases <- args[-1]
    tmp_dir <- args[1]}


# ---- bench-run ----
for(test_case in test_cases){
    out <- NULL
    for(i in 2^(1:10)){
        out <- dplyr::bind_rows(out, test_sqlite_io(test_case = test_case, test_size = i))
    }
    
    # ---- bench-write_out ----
    write.csv(out, paste0(out_dir, "out_", test_case, ".csv"))
}