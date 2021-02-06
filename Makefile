.PHONY: clean all

all: csv-transcompute.rb FFG_analysis020521.csv
	bundle exec ruby ./csv-transcompute.rb FFG_analysis020521.csv

clean:
	rm csv_output_gamma_family.csv
	rm csv_output_gamma_feeding_guild.csv
