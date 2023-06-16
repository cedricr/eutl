library(here)

here::i_am("constants.R")

data_dir <- here('_generated_data')
output_dir <- here('export')

if (!dir.exists(data_dir)) {
  dir.create(data_dir)
}

if (!dir.exists(output_dir)) {
  dir.create(output_dir)
}

countries <- c("AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IS", "IE", "IT", "LV", "LI", "LT", "LU", "MT", "NL", "XI", "NO", "PL", "PT", "RO", "SK", "SI", "ES", "SE", "GB")

