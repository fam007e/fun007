# LenientGradCalc

**Lenient Grade Calculator**

An interactive CLI grade calculator that applies leniency rules for borderline percentages, automatically rounding up students who are within 2% of the next grade boundary.

## Grade Boundaries

| Percentage | Grade |
| ---------- | ----- |
| 90%+       | A*    |
| 80-89%     | A     |
| 70-79%     | B     |
| 60-69%     | C     |
| 50-59%     | D     |
| 40-49%     | E     |
| <40%       | U     |

## Leniency Rule

If a student's percentage is within 2% of a grade boundary (below 80%), they get rounded up. For example:
- 68% → 70% → Grade B
- 78% → 80% → Grade A

## Usage

```bash
python lenientgradcalc.py
```

### Commands

- Enter marks lost to calculate grade
- Type `change` to set new total marks
- Type `xx` to exit

## Requirements

- Python 3.x (standard library only)

## License

MIT License
