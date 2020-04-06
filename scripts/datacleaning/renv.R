
if(file.exists('renv.lock')){
	renv::activate()
	print('renv ready to go')
}else{
	renvUrl <- "http://cran.r-project.org/src/contrib/Archive/renv/renv_0.9.2.tar.gz"
	install.packages(renvUrl, repos=NULL, type="source")
	renv::init()
	install.packages(c('ggmap', 'readxl'), dependencies=TRUE)
	renv::snapshot()
	renv::activate()
	print('renv ready to go, but without any control over which versions of the packages were installed. This is obviously not the ideal route. gggarbage has crazy depends.')
}
