# IPG Battery Longevity Analysis

Multi-center study analysis package for tracking medical device (Implantable Pulse Generator) implantations and battery longevity across different device models.

## Overview

This package analyzes the longevity of Implantable Pulse Generators (IPGs) used in deep brain stimulation therapy. It tracks device implantations, replacement/removal procedures, and generates survival analysis visualizations comparing different IPG models.

### Supported Devices

- **Activa PC** (Medtronic)
- **Vercise PC** (Boston Scientific)
- **Infinity** (Abbott)

## Features

- Extract patient cohorts with IPG implantations from OMOP CDM database
- Track replacement/removal procedures or end of observation periods
- Calculate accurate age at implantation
- Generate Kaplan-Meier survival curves
- Create detailed summary statistics tables
- Support multi-center collaborative research

## Installation

1. Clone this repository:

```bash
git clone https://github.com/parkyijoo/IPG.git
```

2. Open the R project file:

```r
# Open IPG.Rproj in RStudio
```

## Configuration

### Database Connection

Edit the `connectionDetails` section in `CodeToRun.R`:

```r
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "pdw",                       # Your database management system
  server = Sys.getenv("PDW_SERVER"),  # Your server address
  user = NULL,                        # Your username
  password = NULL,                    # Your password
  port = Sys.getenv("PDW_PORT"),      # Your port number
  pathToDriver = "~/jdbc"
)
```

### Output Settings

Modify the output folder and file names according to your institution:

```r
outputFolder <- "~:/result"
tiffName <- "YourInstitution_Kaplan_Meier_IPG.tiff"
tableName <- "YourInstitution_survival_table.csv"
```

## Usage

### Basic Workflow

1. **Configure your database connection** in `CodeToRun.R`
2. **Run the main analysis script**:

```r
source("CodeToRun.R")
```

### Output Files

The analysis generates two output files:

#### 1. Kaplan-Meier Survival Curve (`*_Kaplan_Meier_IPG.tiff`)
- High-resolution TIFF image (500 DPI)
- Survival curves for each device type
- Risk table included

#### 2. Summary Statistics Table (`*_survival_table.csv`)
- Number of IPGs and patients
- Event counts and percentages
- Age statistics (mean, SD)
- Gender distribution
- Follow-up duration (median, IQR)

## Study Design

### Inclusion Criteria

- Adult patients (≥18 years at implantation)
- First IPG implantation only
- Supported device models (Activa PC, Vercise PC, Infinity)

### Endpoint Definition

**Primary Endpoint**: Time to first replacement/removal procedure OR end of observation

**Event**: IPG replacement or removal procedure

**Censoring**: Last visit date for patients without replacement/removal

## License
The IPG package is licensed under Apache License 2.0

## Contact

- **Email**: yijoo0320@yuhs.ac
- **Name**: Yiju Park
