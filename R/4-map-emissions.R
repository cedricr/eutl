
library(tidyverse)
library(here)
library(sf)
library(cartogram)
library(plotly)
library(rnaturalearth)
library(patchwork)

source('constants.R')


# Get 2022 values
fr_emissions <- st_read(here(output_dir, "emissions-FR-geo.geojson")) |>
  filter(!is.na(emissions)) |>
  filter(!str_detect(zip_code, "^9[789]")) |>
  filter(year == 2022)

# Fix ArcelorMittal DK + DK6
fr_emissions <- fr_emissions |>
  mutate(kind = replace(kind, seqe_id == 956, "Metallurgie")) |>
  mutate(kind = replace(kind, seqe_id == 988, "Metallurgie")) |>
  arrange(desc(emissions))


# Remove zero emitters

fr_emissions <- fr_emissions |>
  filter(emissions > 0)

ratios <- fr_emissions$emissions / max(fr_emissions$emissions)
weights <- exp(-3*ratios)
dorling_emissions_euts <- cartogram_dorling(
  x = fr_emissions %>% st_transform(2154),
  weight = "emissions",
  k = 1,
  m_weight = weights,
  itermax = 1000
)


# plot(dorling_emissions_euts["emissions"])

st_write(dorling_emissions_euts, here(output_dir, "emissions-FR-dorling.geojson"), append = FALSE, delete_dsn = TRUE)




