library(data.table)
library(tidyverse)
library(janitor)
library(usethis)

# The csv we want to access is a single file within a zipped file hosted on gov.uk
url_path <- "https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/804669/Data-behind-interactive-tools-csv.zip"
csv_within_zip <- "remands-magistrates-court-2018.csv"

# Set up tempfiles to download the .zip to, and to extract the required csv to.
temp <- tempfile()
temp_csv <- paste0(temp, "_csv")

# We can download the zip file using native R, but to unzip just the single csv file
# of interest, we will need to use the command line/terminal, which can be done within R
# using the system function.
unzip_command <- sprintf("unzip -j \"%s\" \"%s\" -d \"%s\"", temp, csv_within_zip, temp_csv)
download.file(url_path, temp)
system(unzip_command)

# Having read in the csv file, we can delete the temporary files.
magistratesoutcomes <- fread(paste(temp_csv, csv_within_zip, sep = "/"))
unlink(temp)
unlink(temp_csv, recursive = TRUE)

# Clean names for ease of use with R, and reduce to data of interest.
magistratesoutcomes <-
  magistratesoutcomes %>%
  as_tibble() %>%
  clean_names() %>%
  filter(year_of_appearance == 2018)

# Save as an rds file so that the data is available to the package.
use_data(magistratesoutcomes, overwrite = TRUE, compress = 'xz')
