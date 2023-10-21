# ValSplit
This bash script allows you to check a set of MIPS instructions for correct syntax.

CS1420 - Computer Systems Organisation - 2019

# Usage
The script takes 3 arguments:
input.txt file which will contain the MIPS instructions you want to check.
correct.txt file where the correct MIPS instructions will be outputted.
incorrect.txt file where the incorrect MIPS instructions will be outputted.

To use this bash script, you would open a terminal in the ValSplit folder and run the following command.
```
./valsplit.sh input.txt correct.txt incorrect.txt
```

## Example
Below is a sample input.txt file that would contain your MIPS instructions that you want to check.

### input.txt
```
add $s0 $s1 $s2

add $s0 $s1 $z2
sub $s2 $t0 $t3

lw $t1 8($t2)

addi $t3 $s0 -9

lw $t11 70000($s0)
sw $s3 4($t0)
```

This input file would output the below.

### correct.txt
```
add $s0 $s1 $s2
sub $s2 $t0 $t3
lw $t1 8( $t2 )
addi $t3 $s0 -9
sw $s3 4( $t0 )
```

### incorrect.txt
```
add $s0 $s1 $z2
10 lw $t11 70000( $s0 )
```
