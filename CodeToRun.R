# =====================================================
# IPG Battery Longevity Anlaysis
# Multi-center Study Analysis Code
# Version: 2025-10-15
# =====================================================
#
# Execute all the R codes
# (QnA: Yiju Park / yijoo0320@yuhs.ac / 010-7670-6891)
#
# =====================================================

outputFolder <- "~/result"
pdfName <- "YourInstitution_Kaplan_Meier_IPG.tiff" # Modify tiffName according to your institution
tableName <- "YourInstitution_survival_table.csv" # Modify tableName according to your institution

# Library Setting
library(CohortMethod)
library(DatabaseConnector)
library(SqlRender)
library(survival)
library(survminer)
library(dplyr)
library(tidyr)

# =====================================================
#
# Details for connecting to the server: Modify connectionDetails according to your institution
#
# =====================================================

connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "pdw",                        # modify dbms (e.g.,sql server)
                                                                server = Sys.getenv("PDW_SERVER"),   # modify server address
                                                                user = NULL,                         # modify user (server username)
                                                                password = NULL,                     # modify password
                                                                port = Sys.getenv("PDW_PORT"),       # modify port
                                                                pathToDriver = "~/jdbc")

schema <- "DATABASE.SCHEMA" # modify schema according to your institution (e.g., CDM54_2501.CDM)

# =====================================================

connection <- DatabaseConnector::connect(connectionDetails)
sql <- SqlRender::readSql("CreateCohorts.sql")
rawData <- DatabaseConnector::renderTranslateQuerySql(connection, sql, databaseschema = schema)
DatabaseConnector::disconnect(connection)

analysisData <- rawData

ipgModels <- data.frame(
  DEVICE_NAME = c("Activa PC", "Vercise PC", "Infinity")
)

tableResults <- ipgModels %>%
  left_join(
    analysisData %>% 
      group_by(DEVICE_NAME) %>% 
      summarise(
        n_ipgs = n(),
        n_patients = n_distinct(PERSON_ID),
        n_events = sum(EVENT_FLAG == 1),
        pct_events = round(100 * n_events / n_ipgs, 1),
        
        # Age
        mean_age = mean(AGE_AT_IMPLANT),
        sd_age = sd(AGE_AT_IMPLANT),
        
        # Gender
        n_male = sum(GENDER_SOURCE_VALUE == "M"),
        pct_male = round(100 * n_male / n_ipgs, 1),
        
        # Follow-up
        median_fu = median(FOLLOW_UP_DAYS),
        q1_fu = quantile(FOLLOW_UP_DAYS, 0.25),
        q3_fu = quantile(FOLLOW_UP_DAYS, 0.75),
      ),
    by = "DEVICE_NAME"
  ) %>%
  mutate(across(where(is.numeric), ~replace_na(., 0)))

# Extract KM Results
analysisData$EVENT_FLAG <- as.numeric(analysisData$EVENT_FLAG)
head(analysisData)

km_fit <- survfit(Surv(FOLLOW_UP_DAYS, EVENT_FLAG) ~ DEVICE_NAME,
                  data = analysisData)

plot <- ggsurvplot(km_fit,
           data = analysisData,
           pval = FALSE,                            # p-value
           conf.int = FALSE,                        # CI
           risk.table = TRUE,
           palette = c("#E18727FF", "#0072B5FF"), 
           xlab = "Follow-up Days",
           ylab = "Survival probability",
           title = "Kaplan-Meier Survival Curves by IPG type",
           ggtheme = theme_minimal(),
           legend.title = "",
           legend.labs = c("Activa PC", "Infinity"),
           break.time.by = 365,
           xlim = c(0, 1825),
           font.main = 14,
           font.x = 12,
           font.y = 12,
           font.tickslab = 10,
           font.legend = 10,
           risk.table.fontsize = 3.5,
  )

# Save plot as TIFF file
pdf(file.path(outputFolder, pdfName), width = 7.87, height = 5.91) 
print(plot)
dev.off()

# Export results table as CSV
write.csv(tableResults, file.path(outputFolder, tableName))
