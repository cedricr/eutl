library(tidyverse)
library(here)
library(janitor)

source('constants.R')

tidy_installations <- read_csv(
  here(output_dir, 'installations-ALL.csv'), na=c("", "NA", "Excluded", "Not Calculated", "Not Reported"),
  col_types = list(
    InstallationOrAircraftOperatorID = col_character(),
    AccountHolderName = col_character(),
    InstallationNameOrAircraftOperatorCode = col_character(),
    ParentCompany = col_character(),
    ZipCode = col_character(),
    Country = col_character(),
    MainActivityTypeCode = col_integer(),
    MainActivityTypeCodeLookup = col_factor(),
    VerifiedEmissions_2005 = col_integer(),
    VerifiedEmissions_2006 = col_integer(),
    VerifiedEmissions_2007 = col_integer(),
    VerifiedEmissions_2008 = col_integer(),
    VerifiedEmissions_2009 = col_integer(),
    VerifiedEmissions_2010 = col_integer(),
    VerifiedEmissions_2011 = col_integer(),
    VerifiedEmissions_2012 = col_integer(),
    VerifiedEmissions_2013 = col_integer(),
    VerifiedEmissions_2014 = col_integer(),
    VerifiedEmissions_2015 = col_integer(),
    VerifiedEmissions_2016 = col_integer(),
    VerifiedEmissions_2017 = col_integer(),
    VerifiedEmissions_2018 = col_integer(),
    VerifiedEmissions_2019 = col_integer(),
    VerifiedEmissions_2020 = col_integer(),
    VerifiedEmissions_2021 = col_integer(),
    VerifiedEmissions_2022 = col_integer(),
    .default = col_skip()
  )
)|>
  pivot_longer(
    cols = starts_with("VerifiedEmissions_"),
    names_to = "year",
    names_prefix = "VerifiedEmissions_",
    names_transform = list(year = as.integer),
    values_to = "emissions",
    values_drop_na = TRUE
  ) |>
  clean_names() |>
  rename(
    seqe_id = installation_or_aircraft_operator_id,
    installation_name = installation_name_or_aircraft_operator_code) |>
    mutate(emissions = emissions / 1e6,
         installation_name = toupper(installation_name),
         kind = fct_recode(
           # https://www.euets.info/static/download/Description_EUTL_database.pdf
            main_activity_type_code_lookup,
            "Ciment et chaux" = "Installations for the production of cement clinker in rotary kilns or lime in rotary kilns or in other furnaces",
            "Ciment et chaux" = "Production of cement clinker",
            "Ciment et chaux" = "Production of lime, or calcination of dolomite/magnesite",
            "Cokerie" = "Coke ovens",
            "Cokerie" = "Production of coke",
            "Combustion" = "Combustion installations with a rated thermal input exceeding 20 MW",
            "Combustion" = "Combustion of fuels",
            "Industrie chimique" = "Production of ammonia",
            "Industrie chimique" = "Production of bulk chemicals",
            "Industrie chimique" = "Production of carbon black",
            "Industrie chimique" = "Production of nitric acid",
            "Industrie chimique" = "Production of soda ash and sodium bicarbonate",
            "Industrie chimique" = "Production of glyoxal and glyoxylic acid",
            "Industrie chimique" = "Production of adipic acid",
            "Metallurgie" = "Installations for the production of pig iron or steel (primary or secondary fusion) including continuous casting",
            "Metallurgie" = "Production of pig iron or steel",
            "Metallurgie" = "Production of primary aluminium",
            "Metallurgie" = "Production or processing of ferrous metals",
            "Metallurgie" = "Production or processing of non-ferrous metals",
            "Metallurgie" = "Metal ore (including sulphide ore) roasting or sintering installations",
            "Metallurgie" = "Metal ore roasting or sintering",
            "Metallurgie" = "Production of secondary aluminium",
            "Papier" = "Industrial plants for the production of (a) pulp from timber or other fibrous materials (b) paper and board",
            "Papier" = "Production of paper or cardboard",
            "Papier" = "Production of pulp",
            "Production d‘hydrogène" = "Production of hydrogen and synthesis gas",
            "Raffineries" = "Refining of mineral oil",
            "Raffineries" = "Mineral oil refineries",
            "Verre et céramique" = "Installations for the manufacture of ceramic products by firing, in particular roofing tiles, bricks, refractory bricks, tiles, stoneware or porcelain",
            "Verre et céramique" = "Installations for the manufacture of glass including glass fibre",
            "Verre et céramique" = "Manufacture of ceramics",
            "Verre et céramique" = "Manufacture of glass",
            "Verre et céramique" = "Manufacture of mineral wool",
            "Verre et céramique" = "Production or processing of gypsum or plasterboard",
            "Exploitants d’aéronefs" = "Aircraft operator activities",
            "Other" = "Other activity opted-in pursuant to Article 24 of Directive 2003/87/EC",
            "Séquestration" = "Capture of greenhouse gases under Directive 2009/31/EC"
            ))

export_filename <- here(output_dir, "emissions-ALL.csv")
write_csv(tidy_installations, export_filename)
