Ugla.Url <- paste0("https://ugla.hi.is/service/proftafla/?request=getFile&file=resourcesMessy&proftaflaID=34")
Ugla.resource <- readLines(Ugla.Url,  warn = "F")
cat("", file="resources.dat",sep="\n")
for (i in c(1:length(Ugla.resource))) {
  cat(Ugla.resource[[i]], file="resources.dat",append=TRUE)
  cat(c("\n"), file="resources.dat", append=TRUE)
}

