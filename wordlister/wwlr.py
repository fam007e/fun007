from itertools import permutations

def generate_combinations(input_string):
	#Generate all permutations of the input string
	perms = permutations(input_string)
	combinations = [''.join(perm) for perm in perms]
	return combinations

def write_to_dat(combinations, output_file):
	with open(output_file, 'w') as file:
		for combination in combinations :
			file.write(combination + '\n')

def main():
	input_string = input("Enter the input string:")
	output_file = input("Enter the output file name with .dat extension:")
	combinations = generate_combinations(input_string)
	write_to_dat(combinations, output_file)
	print("Combinations have been written to", output_file)

if __name__ == "__main__":
	main()
