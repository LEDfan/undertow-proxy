rm(list=ls())

# if TRUE helps with optimising the app during development
options(shiny.trace = FALSE)

# This is required for ShinyProxy
port <- 3838
 
print(paste0('run.R script, User: ', Sys.getenv("SHINYPROXY_USERNAME")))

shiny::runApp(
   appDir = ".",
   host = '0.0.0.0',
   port = as.numeric(port)
)
