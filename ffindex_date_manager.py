#!/usr/bin/env python2

import calendar
import time
import operator
import os
import sys
from optparse import OptionParser


def read_file_date_tuples_from_file(input_file):
	file2date = dict()

	if not os.path.exists(input_file):
		return file2date

	fh = open(input_file, "r")

	for line in fh:
		if(line[0] == "#"):
			continue
		(filename, date) = line.rstrip().split()
		file2date[filename] = date

	fh.close()

	return file2date


def write_file_date_tuples_to_file(file2date, output_file):
	fh = open(output_file, "w")
	
	fh.write("#filename\tdate\n")
	for f in file2date.keys():
		fh.write(f+"\t"+str(file2date[f])+"\n")

	fh.close()


def read_files(f):
	files = []

	fh = open(f, "r")
	for line in fh:
		line = line.rstrip()
		files.append(line)
	fh.close()

	return files


def add_files(file2date, files):
	date = calendar.timegm(time.gmtime())

	for f in files:
		file2date[f] = date


def get_oldest_files(file2date, n, output_file):
	sorted_tuples = sorted(file2date.items(), key=operator.itemgetter(1))
	selected_files = []
	
	for i in range(min(n, len(sorted_tuples))):
		selected_files.append(sorted_tuples[i][0])

	fh = open(output_file, "w")
	for f in selected_files:
		fh.write(f+"\n")
	fh.close()



#--oldest n -i index -o files
#--update -i index -f files

def opt():
	parser = OptionParser()
	parser.add_option("--update", dest="update_flag", action="store_true",
		help="Update existing time index")
	parser.add_option("--oldest", dest="nr_oldest",
		help="FFindex prefix for input score files", type="int", metavar="INT")
	parser.add_option("-i", dest="index_file",
		help="FILE with the time index", metavar="FILE")
	parser.add_option("-f", dest="files",
		help="FILE with the new/updated files of the time index", metavar="FILE")
	parser.add_option("-o", dest="output",
		help="FILE to write the oldes files to", metavar="FILE")

	return parser


def check_input(options, parser):
	if(options.update_flag and options.nr_oldest):
		sys.stderr.write("ERROR: Please use just one option --update or --oldest!\n")
		parser.print_help()
		sys.exit(1)

	if(not options.update_flag and not options.nr_oldest):
		sys.stderr.write("ERROR: Please use one of the options --update or --oldest!\n")
		parser.print_help()
		sys.exit(1)

	if(not options.index_file):
		sys.stderr.write("ERROR: Please specify an index file!\n")
		parser.print_help()
		sys.exit(1)

	if(options.update_flag):
		if(not options.files):
			sys.stderr.write("ERROR: Please specify the files that shall be updated!\n")
			parser.print_help()
			sys.exit(1)
		elif(not os.path.exists(options.files)):
			sys.stderr.write("ERROR: The file with the filenames that shall be updated does not exist!\n")
			parser.print_help()
			sys.exit(1)


	if(options.nr_oldest):
		if(not options.output):
			sys.stderr.write("ERROR: Please specify an output file for the oldest filenames in the time index!\n")
			parser.print_help()
			sys.exit(1)



def main():
	parser = opt()
	(options, args) = parser.parse_args()
	check_input(options, parser)


	if(options.nr_oldest):
		file2date = read_file_date_tuples_from_file(options.index_file)
		get_oldest_files(file2date, options.nr_oldest, options.output)
	if(options.update_flag):
		file2date = read_file_date_tuples_from_file(options.index_file)
		updated_files = read_files(options.files)
		add_files(file2date, updated_files)
		write_file_date_tuples_to_file(file2date, options.index_file)


if __name__ == "__main__":
	main()
