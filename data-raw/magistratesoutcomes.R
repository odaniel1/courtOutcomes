library(data.table)
library(dtplyr)
library(tidyverse, warn.conflicts = FALSE)

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
magoutcomes <- fread(paste(temp_csv, csv_within_zip, sep = "/"), stringsAsFactors = TRUE)
unlink(temp)
unlink(temp_csv, recursive = TRUE)
rm(temp, temp_csv, unzip_command, csv_within_zip, url_path)

# Clean names for ease of use with R, and reduce to data of interest.
magoutcomes <-
  magoutcomes %>%
  as_tibble() %>%
  janitor::clean_names() %>%
  filter(year_of_appearance == 2018)

# Add region and country to data based on force_code
forceregions <- fread("./data-raw/forceregions.csv")
magoutcomes <- left_join(magoutcomes, forceregions)

# A function to generate a date from a year/quarter pair; the date returned
# is the last day of the supplied quarter.
date_from_year_quarter <- function(year, quarter){
  quarter <- str_remove(quarter, "Q") %>% as.numeric()
  month   <- 1 + 3 * (quarter - 1)
  date    <- paste0(year, "-", month, "-01") %>% as.Date(format = "%Y-%m-%d")
  date    <- lubridate::ceiling_date(date, unit = "quarter") -1
  date
}

# Add date for end of quarter.
magoutcomes <-
  magoutcomes %>%
  mutate(
    appearance_period = date_from_year_quarter(year_of_appearance, quarter)
  )

# Treat all character variables as factors.
magoutcomes <-
  magoutcomes %>%
  mutate_if(is.character, as.factor)

# Reorder variables
magoutcomes <-
  magoutcomes %>%
  select(appearance_period, year_of_appearance, quarter, country, region, force_code, everything())

magoutcomes <- magoutcomes %>% select(-appearance_quarter_end)

# Save as an rds file so that the data is available to the package.
usethis::use_data(magoutcomes, overwrite = TRUE, compress = 'xz')
