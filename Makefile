.PHONY: clean

csv_output.csv: csv-transcompute.rb Below\ South\ Bend.csv
	bundle exec ruby ./csv-transcompute.rb

clean:
	rm csv_output.csv
