These files are in lib/, not a subdirectory of app/, because Rails need not
load their code for the web application. No sense having their code eat up
memory in puma.
