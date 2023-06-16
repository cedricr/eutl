
library(tidyverse)
library(here)
library(sf)
library(janitor)

source('constants.R')

# Base SIRENE
# https://www.data.gouv.fr/fr/datasets/base-sirene-des-entreprises-et-de-leurs-etablissements-siren-siret/
sirene_url = "https://files.data.gouv.fr/insee-sirene/StockEtablissement_utf8.zip"
sirene_destfile <-  here(data_dir, "etablissements-sirene.zip")
if (!file.exists(sirene_destfile)) {
  download.file(sirene_url, sirene_destfile)
  # The unzipped CSV file is more than 4GB, so R's unzip will choke on it
  # We've got to unzip it manually
  unzip(sirene_destfile,
        unzip = getOption("unzip"),
        exdir = data_dir)
}
sirene_csv <-
  here(data_dir, unzip(sirene_destfile, list = TRUE)[[1]])

# Base des codes postaux
# https://www.data.gouv.fr/fr/datasets/base-officielle-des-codes-postaux/
postcodes_url <-
  "https://datanova.legroupe.laposte.fr/explore/dataset/laposte_hexasmal/download/?format=csv&timezone=Europe/Berlin&use_labels_for_header=true"
postcodes_csv <- here(data_dir, "code_postaux.csv")
if (!file.exists(postcodes_csv)) {
  download.file(postcodes_url, postcodes_csv)
}

base_sirene <- read_csv(
  sirene_csv,
  col_types = cols_only(
    codePostalEtablissement = col_character(),
    codeCedexEtablissement = col_character()
  )
)

base_cedex <- base_sirene |>
  filter(!is.na(codeCedexEtablissement) &
           !is.na(codePostalEtablissement)) |>
  distinct(codeCedexEtablissement, .keep_all = TRUE) |>
  rename(cp = codePostalEtablissement,
         cedex = codeCedexEtablissement)

base_postalcode <-  read_delim(postcodes_csv,
                               delim = ";",
                               col_types = "cccccc") |>
  rename_with(tolower) |>
  select(code_postal, coordonnees_geographiques) |>
  distinct(code_postal, .keep_all = TRUE) |>
  separate(coordonnees_geographiques,
           into = c("latitude", "longitude"),
           sep = ",")

base_cedex_geo <- base_cedex |>
  left_join(base_postalcode, by = c("cp" = "code_postal")) |>
  select(-cp) |>
  rename(code_postal = cedex)

full_base_postalcode <- base_cedex_geo |>
  rbind(base_postalcode) |>
  distinct(code_postal, .keep_all = TRUE)

installations <- read_csv(
  here(output_dir, 'emissions-ALL.csv'), show_col_types = FALSE
) |>
  filter(country == 'FR',  main_activity_type_code != 10)


unknown_cps <- installations |>
  anti_join(full_base_postalcode, by = c("zip_code" = "code_postal")) |>
  distinct(zip_code, .keep_all = TRUE) |>
  arrange(by = zip_code)
print(unknown_cps$zip_code )
# http://code.postal.fr/code-postal-13165.html
# https://github.com/zip_codes/FR
installations[installations$zip_code == "01155", 'zip_code'] <- "01150"
# installations[installations$zip_code == "10402", 'zip_code'] <- "10400"
installations[installations$zip_code == "13165", 'zip_code'] <- "13220"
installations[installations$zip_code == "26131", 'zip_code'] <- "26700"
installations[installations$zip_code == "29224", 'zip_code'] <- "29460"
installations[installations$zip_code == "31401", 'zip_code'] <- "31000"
installations[installations$zip_code == "38129", 'zip_code'] <- "38500"
installations[installations$zip_code == "38148", 'zip_code'] <- "38140"
installations[installations$zip_code == "38556", 'zip_code'] <- "38550"
installations[installations$zip_code == "42803", 'zip_code'] <- "42800"
installations[installations$zip_code == "46131", 'zip_code'] <- "46130"
installations[installations$zip_code == "50444", 'zip_code'] <- "50440"
installations[installations$zip_code == "54212", 'zip_code'] <- "54200"
installations[installations$zip_code == "60435", 'zip_code'] <- "60430"
installations[installations$zip_code == "60544", 'zip_code'] <- "60110"
installations[installations$zip_code == "60871", 'zip_code'] <- "60870"
installations[installations$zip_code == "62193", 'zip_code'] <- "62190"
installations[installations$zip_code == "65309", 'zip_code'] <- "65300"
installations[installations$zip_code == "68331", 'zip_code'] <- "68330"
installations[installations$zip_code == "69583", 'zip_code'] <- "69250"
installations[installations$zip_code == "71014", 'zip_code'] <- "71000"
installations[installations$zip_code == "72086", 'zip_code'] <- "72000"
installations[installations$zip_code == "73403", 'zip_code'] <- "73400"
installations[installations$zip_code == "74961", 'zip_code'] <- "74960"
installations[installations$zip_code == "76808", 'zip_code'] <- "76800"
installations[installations$zip_code == "77291", 'zip_code'] <- "77990"
installations[installations$zip_code == "87206", 'zip_code'] <- "87200"
installations[installations$zip_code == "88155", 'zip_code'] <- "88150"
installations[installations$zip_code == "91895", 'zip_code'] <- "91400"
installations[installations$zip_code == "97242", 'zip_code'] <- "97200"
installations[installations$zip_code == "97292", 'zip_code'] <- "97232"
installations[installations$zip_code == "97610", 'zip_code'] <- "97615"
installations[installations$zip_code == "97690", 'zip_code'] <- "97600"

fr_emitters_geo <- installations |>
  left_join(full_base_postalcode, by = c("zip_code" = "code_postal")) |>
  # distinct(seqe_id, .keep_all = TRUE) |>
  filter(!is.na(latitude) & !is.na(longitude))
  # filter(!str_detect(zip_code, "^9[789]"))


fr_emissions <- st_as_sf(fr_emitters_geo,
               coords = c('longitude', 'latitude'),
               na.fail = FALSE) |>
  st_set_crs(4326)

st_write(fr_emissions, here(output_dir, "emissions-FR-geo.geojson"), append = FALSE, delete_dsn = TRUE)
st_write(fr_emissions, here(output_dir, "emissions-FR-geo.gpkg"), append = FALSE, delete_dsn = TRUE)
st_write(fr_emissions, here(output_dir, "emissions-FR-geo.csv"), append = FALSE, delete_dsn = TRUE, layer_options = "GEOMETRY=AS_XY")

