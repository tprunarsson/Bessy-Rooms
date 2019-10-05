require(rjson)
Ugla.Url <- paste0("https://ugla.hi.is/service/proftafla/?request=activeProftafla")
Ugla.Data <- readLines(Ugla.Url,  warn = "F")
Ugla.Raw <- fromJSON(Ugla.Data)
Proftafla_id <- Ugla.Raw$data$proftafla_id

# Proftafla_id = 58

Ugla.Url <- paste0("https://ugla.hi.is/service/proftafla/?request=getFile&file=resourcesMessy&proftaflaID=", Proftafla_id)
Ugla.resource <- readLines(Ugla.Url,  warn = "F")
cat("", file="resources.dat",sep="\n")
for (i in c(1:length(Ugla.resource))) {
  cat(Ugla.resource[[i]], file="resources.dat",append=TRUE)
  cat(c("\n"), file="resources.dat", append=TRUE)
}
