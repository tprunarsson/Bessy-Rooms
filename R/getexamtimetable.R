rm(list=ls())
require(rjson)
require(lubridate)
Ugla.Url <- paste0("https://ugla.hi.is/service/proftafla/?request=courses&proftaflaID=34")
Ugla.Data <- readLines(Ugla.Url,  warn = "F")
Ugla.Raw <- fromJSON(Ugla.Data)
Data <- Ugla.Raw$data
cid <- names(Data)
props <- names(Data[[cid[1]]])

# quickly extract all potential exam dates:
dates = rep(ymd_hms(Data[[cid[1]]]$start),length(cid))
for (i in c(1:length(cid))) {
  dates[i] <- ymd_hms(Data[[cid[i]]]$start)
}
udates = sort(unique(yday(dates)))
  
cat("param Slots := ", file="SplitForPhase.dat",sep="\n")
for (c in cid) {
  cname <- Data[[c]]$'courseName'
  cname <- chartr(c('ÍÁÆÖÝÐÞÓÚÉ'),c('IAAOYDTOUE'), cname)
  start <- ymd_hms(Data[[c]]$start)
  examday <- which(yday(start)==udates) - 1
  slot <- 1 + 2*examday + ((hour(start)) > 12)
  strcat <- sprintf('%s %d 1', cname, slot)
  write(strcat, file = "SplitForPhase.dat", append = T)
}
write(";", file = "SplitForPhase.dat", append = T)
