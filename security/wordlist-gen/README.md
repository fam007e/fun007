# wordlister

**Permutation-Based Wordlist Generator**

Generates all possible permutations of an input string and saves them to a file. Useful for password recovery, dictionary attacks, or combinatorial analysis.

## Usage

```bash
python wwlr.py
```

Follow the prompts:

```
Enter the input string: abc
Enter the output file name with .dat extension: output.dat
Combinations have been written to output.dat
```

## Output Example

For input `"abc"`, generates:
```
abc
acb
bac
bca
cab
cba
```

## ⚠️ Warning

Permutation count grows factorially: `n!` combinations for `n` characters.
- 6 chars = 720 combinations
- 10 chars = 3,628,800 combinations

## Requirements

- Python 3.x (uses built-in `itertools`)

## License

MIT License
