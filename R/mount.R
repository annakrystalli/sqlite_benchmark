## ---- mount-volume_dependencies ----
library(secret)

## ---- mount-volume_function ----
mount_ooominds1_volume <- function(user = "anna", private_key = "~/.ssh/r_vault"){
    
    vault <- file.path( "/Users/Anna/Documents/workflows/RSE_clients/news-scrape", ".news-scrape_vault")
    sharc_access <- get_secret("sharc_login", key = private_key, vault = vault)
    
    bash <- paste0("if df | awk '{print $NF}' | grep -Ex '/Volumes/ooominds1';
                   then
                   echo ''
                   else
                   open 'smb://", sharc_access["username"],":", sharc_access["password"],"@uosfstore.shef.ac.uk/shared/ooominds1'
                   fi")
    
    system(bash)
}

