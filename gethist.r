### Web history database extractor and manager ###
### Version 0.0.1 ###
### Nick Kriukov (kriukov@gmail.com) ###


##############################   Functions   ############################## 

# Ask to install required package
pkg.installer = function(pkg.name) {
  cat(paste0("Required package \"", pkg.name, "\" not installed, install (y/n)? "))
  answer = readLines("stdin", n = 1)
  res = -1
  cyc = 1
  while(res == -1) {
    if (answer == "y" | answer == "Y") {
      message("Installing package ", pkg.name, "...")
      install.packages(pkg.name, repos = "http://cran.us.r-project.org")
      res = 1
    } else if (answer == "n" | answer == "N") {
      message("Quitting...")
      res = 0
      quit()
    } else {
      if (cyc < 3) {
        cat(paste0("Required package \"", pkg.name, "\" not installed, install (y/n)? "))
        answer = readLines("stdin", n = 1)
      } else {
        message("Quitting...")
        res = 0
        quit()
      }
    }
    cyc = cyc + 1
  }
  return(res)
}

# Check if required package(s) is/are installed, if not, ask, if confirmed, install
check.dep = function() {
  is.DBI = nzchar(system.file(package = "DBI"))
  is.RSQLite = nzchar(system.file(package = "RSQLite"))
  if (is.DBI & is.RSQLite) res = 1
  else {
    !is.DBI & pkg.installer("DBI")
    !is.RSQLite & pkg.installer("RSQLite")
    res = 1
  }
  return(res)
}

# Mozilla history file loader
loadhist.mozilla = function(histfile) {
  deps = check.dep()
  if (deps != 1) quit()
  library(DBI)
  library(RSQLite)
  
  con = dbConnect(SQLite(), histfile)
  #dbListTables(con)
  
  plc = dbReadTable(con, "moz_places")
  plc = cbind.data.frame("url" = plc$url, 
                         "title" = plc$title, 
                         "date" = plc$last_visit_date)
  dbDisconnect(con)
  rm(con)
  
  # Places with date 0 are not web history (are bookmarks), remove
  plc = plc[!is.na(plc$date),]
  
  # Convert date/time to human-readable
  plc$date = as.POSIXct(plc$date/1e6, origin = "1970-01-01", tz = "UTC")
  
  plc = cbind.data.frame("date" = plc$date, "url" = plc$url, "title" = plc$title)
  plc = plc[order(plc$date),]
  row.names(plc) = NULL
  
  # url and title are integer, make character
  plc$url = as.character(plc$url)
  plc$title = as.character(plc$title)
  
  return(plc)
}

# Chrome-type history file loader
loadhist.chrome = function(histfile) {
  deps = check.dep()
  if (deps != 1) quit()
  library(DBI)
  library(RSQLite)
  
  con = dbConnect(SQLite(), histfile)
  #dbListTables(con)
  
  plc = dbReadTable(con, "urls")
  plc = cbind.data.frame("url" = plc$url, 
                         "title" = plc$title, 
                         "date" = plc$last_visit_time)
  dbDisconnect(con)
  rm(con)
  
  # If table is in db, but it is empty, skip
  if (length(plc[,1]) == 0) {
    print("History is empty")
    quit()
  }
  
  # Places with date 0 sometimes appear for an unknown reason,remove
  plc = plc[!is.na(plc$date),]
  
  # Convert date/time to human-readable
  # https://stackoverflow.com/questions/20458406/what-is-the-format-of-chromes-timestamps
  plc$date = as.POSIXct(plc$date/1e6, origin = "1601-01-01", tz = "UTC")
  
  plc = cbind.data.frame("date" = plc$date, "url" = plc$url, "title" = plc$title)
  plc = plc[order(plc$date),]
  row.names(plc) = NULL
  
  # url and title are integer, make character
  plc$url = as.character(plc$url)
  plc$title = as.character(plc$title)
  
  return(plc)
}

# Profile directory
maindir = function(BR) {
  OS = Sys.info()[["sysname"]]
  if (OS == "Linux") {
    if      (BR == "SM") mdir = "~/.mozilla/seamonkey" # Multi-profile; see in main part
    else if (BR == "FF") mdir = "~/.mozilla/firefox"   # Multi-profile; see in main part
    else if (BR == "GC") mdir = "~/.config/google-chrome/Default/History"
    else if (BR == "CH") mdir = "~/.config/chromium/Default/History"
    else if (BR == "VV") mdir = "~/.config/vivaldi/Default/History"
    else if (BR == "OP") mdir = "~/.config/opera/History"
    
  } else if (OS == "Windows") {
    if      (BR == "SM") mdir = paste0(Sys.getenv("APPDATA"), "/mozilla/seamonkey")
    else if (BR == "FF") mdir = paste0(Sys.getenv("APPDATA"), "/mozilla/firefox")
    else if (BR == "GC") mdir = paste0(Sys.getenv("LOCALAPPDATA"), "/Google/Chrome/User Data/default/History")
    else if (BR == "CH") mdir = paste0(Sys.getenv("LOCALAPPDATA"), "/Chromium/User Data/default/History")
    else if (BR == "VV") mdir = paste0(Sys.getenv("LOCALAPPDATA"), "/Vivaldi/User Data/default/History")
    else if (BR == "OP") mdir = paste0(Sys.getenv("LOCALAPPDATA"), "/Opera Software/Opera Stable/History")
    else if (BR == "ED") mdir = paste0(Sys.getenv("LOCALAPPDATA"), "/Microsoft/Edge/User Data/Default/History")
  } 
  return(mdir)
}


##############################   Main program   ##############################

## -- Command-line arguments, messages, errors --

args = as.character(commandArgs(trailingOnly = TRUE))
browsers = c("NA", "MZ", "SM", "FF", "GC", "CH", "VV", "OP", "ED")

opts = c("-x", "-a", "-xa", "-ax", "-h", "-f", "-fa", "-af", "-c")

if (length(args) == 0) {
  desc = c(
    "gethist 0.0.1: Web history database extractor and manager",
    "",
    "R packages required: DBI, RSQLite",
    "",
    "To view help: Rscript gethist.r -h"
  )
  writeLines(desc)
  quit()
}

if (args[1] == opts[5]) {
  helpmsg = c(
    "gethist 0.0.1: Web history database extractor and manager",
    "",
    "Usage: Rscript gethist.r BR -option [devicename] [origin] output",
    "",
    "Browser (BR) names:",
    "",
    "SM\tSeaMonkey",
    "FF\tFirefox",
    "MZ\tMozilla generic (SM or FF), only with options -f or -fa",
    "GC\tGoogle Chrome",
    "CH\tChromium",
    "VV\tVivaldi",
    "OP\tOpera",
    "ED\tMicrosoft Edge",
    "NA\tNone; not applicable",
    "",
    "Options:",
    "",
    "-x\tExtract history from default location into RDS file",
    "-f\tExtract history from a given history file into RDS file",
    "-a\tAdd an extracted RDS file to an existing RDS database",
    "-xa\tExtract history from default location and add it to RDS database",
    "-fa\tExtract history from a given history file and add it to RDS database",
    "-c\tConvert an RDS file to a CSV file",
    "-h\tView this help",
    "",
    "devicename is any name you give to mark your device in the database",
    "Options -a, -c and -h have no devicename parameter",
    "",
    "Database format",
    "",
    "The table with columns \"date\", \"url\", \"title\", \"device\". ",
    "Date is UTC.",
    "",
    "Examples:",
    "",
    "Rscript gethist.r SM -x desktop xfile.rds",
    " - extracts SeaMonkey history into file xfile.rds",
    "Rscript gethist.r MZ -f laptop path/to/places.sqlite xfile.rds",
    " - extracts Mozilla (FF or SM or other) history from file places.sqlite ", "into file xfile.rds",
    "Rscript gethist.r NA -a xfile.rds dbfile.rds",
    " - adds file xfile.rds to database dbfile.rds",
    "Rscript gethist.r GC -xa desktop2 dbfile.rds",
    " - extracts Google Chrome history and adds it to database dbfile.rds",
    "Rscript gethist.r FF -fa laptop2 /path/to/places.sqlite dbfile.rds",
    " - extracts Firefox history from file places.sqlite and adds it to database", "dbfile.rds",
    "Rscript gethist.r NA -c rdsfile.rds csvfile.csv",
    " - converts an RDS file to a CSV file",
    "",
    "For options -a, -xa, -fa, old main database is overwritten by the new one!",
    "",
    "R packages required: DBI, RSQLite",
    "Install them from R: install.packages(c(\"DBI\", \"RSQLite\"))"
  )
  
  writeLines(helpmsg)
  quit()
}

BR = args[1]
opt = args[2]

if (!(BR %in% browsers)){
  print("Unknown browser: use NA to skip")
  quit()
}

if (!(opt %in% opts)) {
  print("No valid option supplied")
  quit()
} else if (!((opt %in% opts[c(1:4,9)] & length(args) == 4) |
           (opt %in% opts[6:8] & length(args) == 5))) {
  print("Device name and/or file names are missing, or too many parameters")
  quit()
}

lastarg = args[length(args)]
if (strsplit(lastarg, "\\.")[[1]][length(strsplit(lastarg, "\\.")[[1]])] != "rds" & 
    opt != opts[9]) {
  warning("Output file does not have .rds extension")
}


## -- Action part --

if (opt %in% opts[c(1,3:4,6:8)]) {
  
  device.name = args[3]
  dbpath = lastarg
  
  # Determine default locations of browser history files

  if (opt %in% opts[6:8]) {
    # If option is to extract/extract-add from a file, just apply corresp. function
    filepath = args[4]
    if (BR %in% browsers[2:4]) {
      plc = loadhist.mozilla(filepath)
    } else if (BR %in% browsers[5:9]) {
      plc = loadhist.chrome(filepath)
    } else if (BR == browsers[1]) {
      print("Cannot proceed with \"any browser\" option", "\n", 
              "Use a valid browser name or MZ for generic Mozilla format")
      quit()
    }
  } else {
    # If option is to extract/extract-add from a default location,
    # need to specify it

    if (BR == "SM" | BR == "FF") {
      histdir = maindir(BR)
      if (!file.exists(paste0(histdir, "/profiles.ini"))) {
        print(paste0(BR, " profile not found"))
        quit()
      }
      
      profiles.ini = read.csv(paste0(histdir, "/profiles.ini"), skip = 3)
      profiles.ini = profiles.ini[grepl("Path", profiles.ini[,1]),]
      profiles.ini = as.character(profiles.ini)
      profiles = vector()
      for (i in 1:length(profiles.ini)) {
        profiles[i] = strsplit(profiles.ini[i], "\\=")[[1]][2]
      }
      rm(profiles.ini)
      print(paste0("Profiles found: ", length(profiles), ", reading all"))
      
      plc = data.frame()
      for (i in 1:length(profiles)) {
        filepath = paste0(histdir, "/", profiles[1], "/places.sqlite")
        plc1 = loadhist.mozilla(filepath)
        plc = rbind.data.frame(plc, plc1)
      }
      
      # Now history loaded into plc

    } else if (BR %in% browsers[5:9]) {
      filepath = maindir(BR)
      if (!file.exists(filepath)) {
        print(paste0(BR, " history file not found"))
        quit()
      }
      plc = loadhist.chrome(filepath)
    } else if (BR == "MZ") {
      print("Use SM for Seamonkey and FF for Firefox")
      quit()
    } else {
      print("Unknown browser; cannot continue")
      quit()
    }
 
  }
  # Now the history is loaded into plc
  
  plc$device = device.name
  print(paste0("Entries read: ", length(plc$date)))
  
  if (opt %in% opts[c(1,6)]) {
    saveRDS(plc, dbpath)
    rm(plc)
    
  } else if (opt %in% opts[c(3:4,7:8)]) {
    # Open the main database
    if (!file.exists(dbpath)) {
      print(paste0("Database file ", dbpath, " not found"))
      quit()
    }
    db0 = readRDS(dbpath)
    print(paste0("Database ", dbpath, " loaded, ", length(db0[,1]), " entries"))
    
    # Find duplicates in plc and db0 by date and device and remove them from plc
    isect = intersect(db0$date[db0$device == device.name], plc$date)
    datesnew = setdiff(as.numeric(plc$date), isect)
    plc = plc[as.numeric(plc$date) %in% datesnew,]
    
    # Add new entries to the main database
    db0 = rbind.data.frame(db0, plc)
    
    print(paste0("Entries added: ", length(datesnew)))
    
    # # Save database
    saveRDS(db0, dbpath)
    # Clean up
    rm(db0, plc, datesnew, isect)
  }
  
} else if (opt == opts[2]) {
  
  if (!file.exists(args[3])) {
    print(paste0("File ", args[3], " not found"))
    quit()
  }
  
  if (!file.exists(args[4])) {
    print(paste0("Database ", args[4], " not found"))
    quit()
  }
  
  plc = readRDS(args[3])
  print(paste0("Entries read in ", args[3], ": ", length(plc$date)))
  
  db0 = readRDS(args[4])
  print(paste0("Entries read in ", args[4], ": ", length(db0$date)))
  
  # Find duplicates in plc and db0 by date and device and remove them from plc
  isect = intersect(db0$date[db0$device == plc$device[1]], plc$date)
  datesnew = setdiff(as.numeric(plc$date), isect)
  plc = plc[as.numeric(plc$date) %in% datesnew,]
  
  # Add new entries to the main database
  db0 = rbind.data.frame(db0, plc)
  
  print(paste0("Entries added: ", length(datesnew)))
  
  saveRDS(db0, args[4])
} else if (opt == opts[9]) {
  db = readRDS(args[3])
  write.csv(db, args[4], row.names = FALSE)
}



