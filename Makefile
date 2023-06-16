all: fetch clean-data geocode map

fetch:
	Rscript R/1-fetch-eutl-data.R

clean-data:
	Rscript R/2-clean-data.R

geocode:
	Rscript R/3-geocode-fr.R

map:
	Rscript R/4-map-emissions.R

clean:
	rm -rf export

extraclean: clean
	rm -rf _generated_data
