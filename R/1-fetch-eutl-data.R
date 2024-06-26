
library(tidyverse)
library(httr)
library(xml2)
library(here)
library(parallel)

source('constants.R')


operators_dir <- here(data_dir, "operators")

if (!dir.exists(operators_dir)) {
  dir.create(operators_dir)
}



# Relancer le script en cas d'erreurs réseau
for (country_code in countries) {
  oha_filename <- here(operators_dir, str_glue("oha-{country_code}.xml"))
  if (!file.exists(oha_filename)) {
    oha_url <- str_glue(
      "https://ec.europa.eu/clima/ets/exportEntry.do?installationName=&accountHolder=&permitIdentifier=&form=oha&form=oha&searchType=oha&currentSortSettings=&mainActivityType=-1&installationIdentifier=&account.registryCodes={country_code}&languageCode=en&exportType=1&exportAction=oha&exportOK=exportOK"
    )
    download_xml(oha_url, file = oha_filename)
  }
  parsed_data <- read_xml(oha_filename)
  installation_ids <-
    parsed_data %>% xml_find_all(".//InstallationOrAircraftOperatorID") %>% as_list

  installations_dir <- here(data_dir, "installations", country_code)
  if (!dir.exists(installations_dir)) {
    dir.create(installations_dir, recursive = TRUE)
  }

  for (id in installation_ids) {
    installation_filename <- here(installations_dir, str_glue('installation-{country_code}-{id}.xml'))
    if (!file.exists(installation_filename)) {
      print(str_c(country_code, ' ', id))
      installation_url <- str_glue(
        "https://ec.europa.eu/clima/ets/exportEntry.do?installationName&permitIdentifier&searchType=oha&mainActivityType&accountType&selectedPeriods&complianceStatus&account.registryCodes={country_code}&languageCode=en&account.registryCode&accountStatus&accountID&accountHolder&form=ohaDetails&registryCode&installationIdentifier={id}&action&primaryAuthRep&identifierInReg&returnURL&buttonAction=all&exportType=1&exportAction=ohaDetails&exportOK=exportOK"
      )
      download_xml(installation_url,
                   file = installation_filename)
    }
  }
}


account_root <- "//OHADetails/Account/"
installation_root <- str_c(account_root, 'Installation/')

parse_country <- function(country_code) {
  print(str_glue("Processing {country_code}"))
  eutl_installations <- tibble()

  oha_filename <- here(operators_dir, str_glue("oha-{country_code}.xml"))

  xml <- read_xml(oha_filename)
  installation_ids <-
    xml %>% xml_find_all(".//InstallationOrAircraftOperatorID") %>% as_list
  for (id in installation_ids) {
    installation_filename <- here(data_dir, "installations", country_code, str_glue('installation-{country_code}-{id}.xml'))
    x <- read_xml(installation_filename)

    getv <- function(root, key) {
      xml_find_first(x, str_c(root, key)) %>% xml_text
    }

    contact_root <- str_c(account_root, 'RelatedPerson[RelationshipTypeCodeLookup="Account holder"]/')

    nat_admin_code <- getv(account_root, 'NationalAdministratorCode')
    installation_id <- getv(account_root, 'InstallationOrAircraftOperatorID')

    installation_data <- tibble(
      id = str_glue("{nat_admin_code}-{installation_id}"),

      # Account
      InstallationOrAircraftOperatorID = installation_id,
      AccountHolderName = getv(account_root, 'AccountHolderName'),
      NationalAdministrator = getv(account_root, "NationalAdministrator"),
      NationalAdministratorCode = nat_admin_code,
      AccountTypeCode = getv(account_root, "AccountTypeCode"),
      AccountTypeCodeLookup = getv(account_root, "AccountTypeCodeLookup"),
      AccountStatus = getv(account_root, "AccountStatus"),
      CompanyRegistrationNo = getv(account_root, 'RelatedPerson/CompanyRegistrationNo'),

      # Account Holder
      ContactName = getv(contact_root, 'Name'),
      ContactAddress1 = getv(contact_root, 'Address1'),
      ContactAddress2 = getv(contact_root, 'Address2'),
      ContactCity = getv(contact_root, 'City'),
      ContactZipCode = getv(contact_root, 'ZipCode'),
      ContactCountryCode = getv(contact_root, 'CountryCode'),
      ContactCountryCodeLookup = getv(contact_root, 'CountryCodeLookup'),
      ContactRelationshipTypeCode = getv(contact_root, 'RelationshipTypeCode'),
      ContactRelationshipTypeCodeLookup = getv(contact_root, 'RelationshipTypeCodeLookup'),
      ContactTelephone1 = getv(contact_root, 'Telephone1'),
      ContactTelephone2 = getv(contact_root, 'Telephone2'),
      ContactEmailAddress = getv(contact_root, 'EmailAddress'),

      # Installation
      InstallationNameOrAircraftOperatorCode = getv(installation_root, 'InstallationNameOrAircraftOperatorCode'),
      ParentCompany = getv(installation_root, 'ParentCompany'),
      SubsidiaryCompany = getv(installation_root, 'SubsidiaryCompany'),
      EPRTRIdentification = getv(installation_root, 'EPRTRIdentification'),
      FirstYearOfEmissions = getv(installation_root, 'FirstYearOfEmissions'),
      LastYearOfEmissions = getv(installation_root, 'LastYearOfEmissions'),
      PermitOrPlanDate = getv(installation_root, 'PermitOrPlanDate'),
      PermitOrPlanID = getv(installation_root, 'PermitOrPlanID'),
      Latitude = getv(installation_root, 'Latitude'),
      Longitude = getv(installation_root, 'Longitude'),
      Address1 = getv(installation_root, 'Address1'),
      Address2 = getv(installation_root, 'Address2'),
      City = getv(installation_root, 'City'),
      ZipCode = getv(installation_root, 'ZipCode'),
      Country = getv(installation_root, 'NationalAdministratorCode'),
      MainActivityTypeCode = getv(installation_root, 'MainActivityTypeCode'),
      MainActivityTypeCodeLookup = getv(installation_root, 'MainActivityTypeCodeLookup')
    )

    # Compliance
    for (year in 2005:2022) {
      year_root <- str_glue('{installation_root}Compliance[Year="{year}"]/')
      installation_data <- add_column(installation_data, "FreeAllocations_{year}" := getv(year_root, 'FreeAllocations'))
      installation_data <- add_column(installation_data, "ETSPhase_{year}" := getv(year_root, 'ETSPhase'))
      installation_data <- add_column(installation_data, "AllowanceInAllocation_{year}" := getv(year_root, 'AllowanceInAllocation'))
      installation_data <- add_column(installation_data, "UnitsSurrendered_{year}" := getv(year_root, 'UnitsSurrendered'))
      installation_data <- add_column(installation_data, "CumulativeSurrenderedUnits_{year}" := getv(year_root, 'CumulativeSurrenderedUnits'))
      installation_data <- add_column(installation_data, "CumulativeVerifiedEmissions_{year}" := getv(year_root, 'CumulativeVerifiedEmissions'))
      installation_data <- add_column(installation_data, "SurrenderedAllowances_{year}" := getv(year_root, 'SurrenderedAllowances'))
      installation_data <- add_column(installation_data, "VerifiedEmissions_{year}" := getv(year_root, 'VerifiedEmissions'))
      installation_data <- add_column(installation_data, "ComplianceCode_{year}" := getv(year_root, 'ComplianceCode'))
    }
    eutl_installations <- eutl_installations %>%
      rbind(installation_data)
  }
  export_filename <- here(output_dir, str_glue("installations-{country_code}.csv"))
  write_csv(eutl_installations, export_filename)
}

mclapply(countries, parse_country, mc.preschedule = FALSE, mc.silent = FALSE, mc.cores = detectCores() - 1)

get_country_filename <- function(country_code) {
  here(output_dir, str_glue("installations-{country_code}.csv"))
}

first_filename <- get_country_filename(countries[1])
ncols <- length(strsplit(readLines(first_filename, n = 1), ",")[[1]])

installations <- read_csv(first_filename, col_types = strrep('c', ncols))

for (country_code in countries[-1]) {
  print(str_glue("Processing {country_code}"))
  installations <- installations %>%
    rbind(read_csv(get_country_filename(country_code), col_types = strrep('c', ncols)))
}

export_filename <- here(output_dir, "installations-ALL.csv")
write_csv(installations, export_filename)


