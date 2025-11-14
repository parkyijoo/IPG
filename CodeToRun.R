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
# pdfName <- "YourInstitution_Kaplan_Meier_IPG.pdf"          # Modify pdfName according to your institution
tableName <- "YourInstitution_survival_table.csv"            # Modify tableName according to your institution
tableName2 <- "YourInstitution_result_table.csv"             # Modify tableName according to your institution
tableName3 <- "YourInstitution_yearly_patient_count.csv"     # Modify tableName according to your institution

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

# =====================================================
# New: Add Criteria & Device
# =====================================================

analysisData <- rawData %>%
  filter(FOLLOW_UP_DAYS > 365) %>%
  filter(as.Date(DEVICE_EXPOSURE_START_DATE) <= as.Date("2019-12-31"))

ipgModels <- data.frame(
  DEVICE_NAME = c("Activa PC", "Vercise PC", "Infinity", "Activa SC", "Soletra")
)

# =====================================================

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

# =====================================================
# New: Yearly Patient Count Table
# =====================================================

yearlyPatientCount <- analysisData %>%
  mutate(IMPLANT_YEAR = format(as.Date(DEVICE_EXPOSURE_START_DATE), "%Y")) %>%
  group_by(IMPLANT_YEAR) %>%
  summarise(
    n_patients = n_distinct(PERSON_ID),
    n_ipgs = n()
  ) %>%
  arrange(IMPLANT_YEAR)

# =====================================================

# Extract KM Results
km_fit <- analysisData %>%
mutate(EVENT_FLAG = as.numeric(EVENT_FLAG)) %>%
survfit(Surv(FOLLOW_UP_DAYS, EVENT_FLAG) ~ DEVICE_NAME, data = .)

km_summary <- summary(km_fit, times = seq(0, 1825, by = 365))

# plot <- ggsurvplot(km_fit,
#            data = analysisData,
#            pval = FALSE,                            # p-value
#            conf.int = FALSE,                        # CI
#            risk.table = TRUE,
#            palette = c("#E18727FF", "#0072B5FF"), 
#            xlab = "Follow-up Days",
#            ylab = "Survival probability",
#            title = "Kaplan-Meier Survival Curves by IPG type",
#            ggtheme = theme_minimal(),
#            legend.title = "",
#            legend.labs = c("Activa PC", "Activa SC", "Infinity", "Soletra", "Vercise PC"),
#            break.time.by = 365,
#            xlim = c(0, 1825),
#            font.main = 14,
#            font.x = 12,
#            font.y = 12,
#            font.tickslab = 10,
#            font.legend = 10,
#            risk.table.fontsize = 3.5
#   )
# 
# # Save plot as PDF file
# pdf(file.path(outputFolder, pdfName), width = 7.87, height = 5.91) 
# print(plot)
# dev.off()

# Export results table as CSV
write.csv(tableResults, file.path(outputFolder, tableName))
write.csv(analysisData, file.path(outputFolder, tableName2))
write.csv(yearlyPatientCount, file.path(outputFolder, tableName3))
saveRDS(km_fit, file.path(outputFolder, "YourInstitution_km_fit.rds"))
