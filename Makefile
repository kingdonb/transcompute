.PHONY: clean

csv_output.csv: csv-transcompute.rb $(FILE)
	bundle exec ruby ./csv-transcompute.rb $(FILE)

clean:
	rm csv_output.csv
