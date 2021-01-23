.PHONY: clean all

all: csv-transcompute.rb Above-South-Bend.csv Below-South-Bend.csv
	bundle exec ruby ./csv-transcompute.rb Above-South-Bend.csv Below-South-Bend.csv

clean:
	rm csv_output_above_species.csv
	rm csv_output_above_order.csv
	rm csv_output_below_species.csv
	rm csv_output_below_order.csv
