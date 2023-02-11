# cohorts <- readr::read_csv(file = system.file("settings", "CohortsToCreate.csv", package = "phenotypePhebruary2023"),
#                              col_types = readr::cols()) |>
#   dplyr::filter(stringr::str_detect(string = tolower(cohortName),
#                                     pattern = 'anaphylaxis'))

projectCode <- "phenotypePhebruary2023"
cdmSource <- cdmSources |>
  dplyr::filter(sequence == 1) |>
  dplyr::filter(database == 'optum_extended_dod')

keyringUserService <- 'OHDSI_USER'
keyringPasswordService <- 'OHDSI_PASSWORD'
outputFolder <-
  file.path("D:/studyResults", projectCode, cdmSource$sourceKey)

connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = cdmSource$dbms,
  user = keyring::key_get(service = keyringUserService),
  password = keyring::key_get(service = keyringPasswordService),
  server = cdmSource$serverFinal,
  port = cdmSource$port
)


cohortIdsFromPackage <- c(314, 315, 316, 316, 259)
cohortDefinitionSet <-
  dplyr::bind_rows(
    PhenotypeLibrary::getPlCohortDefinitionSet(cohortIds = c(23, 24)),
    CohortGenerator::getCohortDefinitionSet(settingsFileName = "settings/CohortsToCreate.csv",
                                            packageName = projectCode)
  )

CohortGenerator::generateCohortSet(
  connectionDetails = connectionDetails,
  cdmDatabaseSchema = cdmSource$cdmDatabaseSchemaFinal,
  cohortDatabaseSchema = cdmSource$cohortDatabaseSchemaFinal,
  cohortDefinitionSet = cohortDefinitionSet,
  incremental = TRUE,
  incrementalFolder = file.path(outputFolder, 'incrementalFolder'),
  cohortTableNames = CohortGenerator::getCohortTableNames(cohortTable = paste0(
    stringr::str_squish(projectCode),
    stringr::str_squish(cdmSource$sourceId)
  ))
)

remotes::install_github("OHDSI/FeatureExtraction")

covariateSettings <- FeatureExtraction::createDefaultCovariateSettings()


Characterization::createAggregateCovariateSettings(
    targetIds = cohortDefinitionSet$cohortId,
    outcomeIds = cohortDefinitionSet$cohortId,
    riskWindowStart = 0,
    riskWindowEnd = 0,
    covariateSettings = list(covariateSettings, cohortCovariateSettings)
)


databaseId <- as.character(cdmSource$sourceKey)
databaseName <- as.character(cdmSource$sourceName)
databaseDescription <- as.character(cdmSource$sourceName)

server <- as.character(cdmSource$serverFinal)
cdmDatabaseSchema <-
  as.character(cdmSource$cdmDatabaseSchemaFinal)
cohortDatabaseSchema <-
  as.character(cdmSource$cohortDatabaseSchemaFinal)
vocabDatabaseSchema <-
  as.character(cdmSource$vocabDatabaseSchemaFinal)

port <- cdmSource$port

dbms <- cdmSource$dbms

Characterization::createAggregateCovariateSettings <- function(
    targetIds,
    outcomeIds,
    riskWindowStart = 1,
    startAnchor = 'cohort start',
    riskWindowEnd = 365,
    endAnchor = 'cohort start',
    covariateSettings
)
