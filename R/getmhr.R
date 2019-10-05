require(rjson)
Ugla.Url <- paste0("https://ugla.hi.is/service/proftafla/?request=activeProftafla")
Ugla.Data <- readLines(Ugla.Url,  warn = "F")
Ugla.Raw <- fromJSON(Ugla.Data)
Proftafla_id <- Ugla.Raw$data$proftafla_id

# Proftafla_id = 58

Ugla.Url <- paste0("https://ugla.hi.is/service/proftafla/?request=getFile&file=resourcesMessy&proftaflaID=",Proftafla_id)
Ugla.resource <- readLines(Ugla.Url,  warn = "F")

for (i in c(2:length(Ugla.resource))) {
  if (Ugla.resource[[i]] == "set CidMHR :=") {
    break;
  }
}
MHR = character(0)
for (j in c((i+1):length(Ugla.resource))) {
  if (Ugla.resource[[j]] == ';') {
    break;
  }
  MHR = c(MHR,Ugla.resource[[j]])
}

save(file=c("mhr.Rdata"), list=c("MHR"))
