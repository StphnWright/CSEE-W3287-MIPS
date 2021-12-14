# function that counts the number of instances of a character in a string
# parameters:
# a0 = character to count
# a1 = address of null terminated string
# return:
# v0 = number of instances of character in string

count_char:	
	li	$v0, 0

count_char_loop:
	lbu 	$t0, ($a1)
	beqz	$t0, count_char_loop_end
	bne	$a0, $t0, count_char_no_match
	addi 	$v0, $v0, 1

count_char_no_match:
	addiu	$a1, $a1, 1
	b	count_char_loop

count_char_loop_end:
	jr	$ra
	
######################################################## DO NOT REMOVE THIS SEPARATOR
		
# function that returns the min and max characters in a string
# paremeters:
# a0 = address of null terminated string
# return:
# v0 = min character in the given string
# v1 = max character in the given string

minmax_chars:
	li	$v0, 127	# initialize min char
	li	$v1, 0		# initialize max char

minmax_chars_loop:
	lbu	$t0, ($a0)
	beqz	$t0, minmax_chars_loop_end
	bge	$t0, $v0, minmax_chars_not_min
	move	$v0, $t0	# resetting the current minimum

minmax_chars_not_min:
	ble	$t0, $v1, minmax_chars_not_max
	move	$v1, $t0	# resetting the current maximum
	
minmax_chars_not_max:
	addiu	$a0, $a0, 1
	b	minmax_chars_loop
	
minmax_chars_loop_end:
	jr	$ra
	
######################################################## DO NOT REMOVE THIS SEPARATOR

# function that initializes a leaf node for the Huffman tree
# parameters:
# a0 = character associated with the leaf node
# a1 = character weight
# a2 = address where the new leaf goes
# return: nothing

make_leaf:
	sw	$a0, ($a2)	# initialize char
	sw	$a1, 4($a2)	# initialize weight
	li	$t0, 0
	sw	$t0, 8($a2)	# initialize has_parent
	sw	$t0, 12($a2)	# set left child to null
	sw	$t0, 16($a2)	# set right child to null
	jr	$ra

######################################################## DO NOT REMOVE THIS SEPARATOR

# function that initializes a non-leaf node with two children
# parameters:
# a0 = address of the left child node
# a1 = address of the right child node
# a2 = address where the new node goes
# return: nothing

merge_roots:
	sw	$zero, ($a2)	# set character to ASCII null
	sw	$zero, 8($a2)	# set has_parent to false	
	sw	$a0, 12($a2)	# set left child to given left child
	sw	$a1, 16($a2)	# set right child to given right child
	lw	$t0, 4($a0)	# load frequency of left child
	lw	$t1, 4($a1)	# load frequency of right child
	addu	$t0, $t0, $t1	# adding the weights of the children
	sw	$t0, 4($a2)	# set weight of parent to sum of weights
	li	$t0, 1
	sw	$t0, 8($a0)	# set has_parent to true on left child
	sw	$t0, 8($a1)	# set has_parent to true on right child 	
	jr 	$ra

######################################################## DO NOT REMOVE THIS SEPARATOR

# function walks an array of nodes and returns the number of roots
# parameters:
# a0 = address of the first node in the array
# a1 = address of the last node in the array (exclusive)
# return:
# v0 = number of roots

count_roots:
	li 	$v0, 0
	
count_roots_loop:
	beq 	$a0, $a1, count_roots_loop_end
	lw	$t0, 8($a0)	# load has_parent flag of current node
	bnez	$t0, count_roots_has_parent
	addiu	$v0, $v0, 1

count_roots_has_parent:
	addiu	$a0, $a0, 20
	b  	count_roots_loop
					
count_roots_loop_end:
	jr 	$ra

######################################################## DO NOT REMOVE THIS SEPARATOR

# function is given an array of nodes and returns the address of the lightest and second lightest root
# parameters:
# a0 = address of the first node in the array
# a1 = address of the last node in the array (exclusive)
# return:
# v0 = address of the lightest root node in the array
# v1 = address of the second lightest root node in the array

lightest_roots:
	li 	$v0, 0
	li 	$v1, 0
	li	$t1, -1		# the smallest current weight, initialized to marker value -1
	li	$t2, -1		# the second smallest current weight, initialized to marker value -1

lightest_roots_loop:
	beq	$a0, $a1, lightest_roots_loop_end
	lw	$t0, 8($a0)	# load has_parent of the current node
	bnez 	$t0, lightest_roots_loop_update	# skip node if current node is not a root
	lw	$t0, 4($a0)	# load weight of current node
	bgez	$t1, lightest_roots_smallest_set
	move	$t1, $t0	# set smallest weight to weight of current node
	move	$v0, $a0	# set smallest weight address to address of current node
	b	lightest_roots_loop_update
	
lightest_roots_smallest_set:
	bge	$t0, $t1, lightest_root_second_smallest
	move	$t2, $t1	# set second smallest weight to smallest weight
	move	$v1, $v0	# set second smallest address to address of smallest node
	move	$t1, $t0	# set smallest to weight of current node
	move	$v0, $a0	# set smallest address to address of current node
	b	lightest_roots_loop_update

lightest_root_second_smallest:
	bltz	$t2, lightest_root_second_smallest2
	bge	$t0, $t2, lightest_roots_loop_update
	
lightest_root_second_smallest2:
	move	$t2, $t0	# set second smallest weight to weight of current node
	move	$v1, $a0	# set second smallest address to address of current node

lightest_roots_loop_update:
	addiu	$a0, $a0, 20
	b	lightest_roots_loop
	
lightest_roots_loop_end:	
	jr	$ra

######################################################## DO NOT REMOVE THIS SEPARATOR

# function that constructs the Huffman tree
# parameters:
# a0 = address of a string with the text sample on which to calculate character frequency
# a1 = address of a location in memory with sufficient space for the tree
# return:
# v0 = address of the root of the tree

build_tree:
	addiu	$sp, $sp, -28
	sw	$ra, ($sp)	# push ra on the stack
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)
	sw	$s4, 20($sp)
	sw	$s5, 24($sp)
	
	move	$s2, $a1	# s2 = address of array of nodes
	move	$s3, $a0	# s3 = address of string
	
	jal	minmax_chars
	move	$s0, $v0	# s0 = min char
	move	$s1, $v1	# s1 = max char
	
	move	$s5, $s2	# s5 = address of the current node
	
build_tree_loop:
	bgt	$s0, $s1, build_tree_loop_end
	
	move	$a0, $s0	# a0 = char to compute frequency
	move	$a1, $s3	# a1 = address of beginning of string
	jal	count_char	# returns v0 = frequency of current character
	beqz	$v0, build_tree_loop_update
	
	move	$a0, $s0	# a0 = char to be stored in node
	move	$a1, $v0	# a1 = weight of node
	move	$a2, $s5	# a2 = address of node
	jal	make_leaf

	addiu	$s5, $s5, 20	# update address of current node
	
build_tree_loop_update:
	addiu	$s0, $s0, 1	# increment current character 
	b	build_tree_loop	
		
build_tree_loop_end:
	move	$s4, $s5	# s4 = address of node after the last node

build_tree_merge_loop:
	move	$a0, $s2
	move	$a1, $s4
	jal	count_roots
	ble	$v0, 1, build_tree_merge_loop_end
	
	move	$a0, $s2
	move	$a1, $s4
	jal	lightest_roots
	
	move	$a0, $v0
	move	$a1, $v1
	move	$a2, $s4
	jal	merge_roots
	
	addiu	$s4, $s4, 20	# update address of node past last node
	b	build_tree_merge_loop
	
build_tree_merge_loop_end:
	move	$v0, $a2
	
	lw	$ra, ($sp)	# pop ra from the stack
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
	lw	$s3, 16($sp)
	lw	$s4, 20($sp)
	lw	$s5, 24($sp)
	addiu	$sp, $sp, 28	
	
	jr 	$ra

######################################################## DO NOT REMOVE THIS SEPARATOR

main:
	# save regs
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	la $a0, count_char_test1_in
	la $a1, count_char_test1_out
	jal count_char_tester
 
	la $a0, count_char_test2_in
	la $a1, count_char_test2_out
	jal count_char_tester
 
	la $a0, minmax_chars_test1_in
	la $a1, minmax_chars_test1_out 
	jal minmax_chars_tester
 
	la $a0, minmax_chars_test2_in
	la $a1, minmax_chars_test2_out
	jal minmax_chars_tester
	
	la $a0, make_leaf_test1_in
	la $a1, make_leaf_test1_out
	jal make_leaf_tester
 
	la $a0, make_leaf_test2_in
	la $a1, make_leaf_test2_out
	jal make_leaf_tester
	
	la $a0, count_roots_test1_in
	la $a1, count_roots_test1_out
	jal count_roots_tester
 
	la $a0, count_roots_test2_in
	la $a1, count_roots_test2_out
	jal count_roots_tester
	jal print_newline
 
	la $a0, merge_roots_test1_in
	la $a1, merge_roots_test1_out	
	jal merge_roots_tester
 
	la $a0, merge_roots_test2_in
	la $a1, merge_roots_test2_out	
	jal merge_roots_tester

	la $a0, lightest_roots_test1_in
	la $a1, lightest_roots_test1_out	
 	jal lightest_roots_tester

	la $a0, lightest_roots_test2_in
	la $a1, lightest_roots_test2_out	
 	jal lightest_roots_tester

	la $a0, build_tree_test1_in
	la $a1, build_tree_test1_out
	jal build_tree_tester

	jal print_newline
	jal print_newline

	# one last test, build the abc_string tree again and decompress a tiny string
	# should see 'cab' print to screen
	la $a0, abc_string
	la $a1, free_space
	jal build_tree
	move $a0, $v0
	la $a1, cab_message
	li $a2, 6
	jal decompress
	jal print_newline
	
	# now, build the final tree, and use to decompress message
	la $a0, english_frequency_string 
	la $a1, free_space
	jal build_tree
 	move $a0, $v0
	la $a1, final_message
	li $a2, 70
	jal decompress
	
	# restore regs
	lw $ra, 0($sp)
	addi $sp, $sp, 4

	# and return
	jr $ra

count_char_tester:
	# save regs
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)

	# save args
	move $s0, $a0
	move $s1, $a1

	# print test case and inputs
	la $a0, count_char_tester_msg
	jal print_string
	lw $a0, 0($s0)
	jal print_char
	jal print_comma
	lw $a0, 4($s0)
	jal print_string
	jal print_newline

	# print expected output
	la $a0, tester_expecting_msg
	jal print_string
	lw $a0, 0($s1)
	jal print_int
	jal print_newline
  
	# run test!
	lw $a0, 0($s0)
	lw $a1, 4($s0)
	jal count_char
 
	# check result against expected
	lw $t0, 0($s1)
	beq $v0, $t0, count_char_tester_pass

	# error, save result
	move $s0, $v0
	
	# print error message and result
	la $a0, tester_error_msg
	jal print_string	
	move $a0, $s0
	jal print_int
	jal print_newline
 
	# exit
	li $v0, 10 
	syscall

count_char_tester_pass:
	# print pass message
	la $a0, tester_pass_msg
	jal print_string
	
	# restore regs and return
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12
	jr $ra
	

minmax_chars_tester:	
	# save regs
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)

	# save args
	move $s0, $a0
	move $s1, $a1

	# print test case and inputs
	la $a0, minmax_chars_tester_msg
	jal print_string
	lw $a0, 0($s0)
	jal print_string
	jal print_newline

	# print expected result
	la $a0, tester_expecting_msg
	jal print_string
	lw $a0, 0($s1)
	jal print_char
	jal print_comma
	lw $a0, 4($s1)
	jal print_char	
	jal print_newline

	# run test!
	lw $a0, 0($s0)
	jal minmax_chars

	# check result
	lw $t0, 0($s1)
	bne $v0, $t0, minmax_chars_tester_fail
	lw $t0, 4($s1)
	bne $v1, $t0, minmax_chars_tester_fail

	# print pass message
	la $a0, tester_pass_msg
	jal print_string
	
	# restore regs and return
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12
	jr $ra

minmax_chars_tester_fail:
	# error, save result
	move $s0, $v0
	move $s1, $v1

	# print error message and result
	la $a0, tester_error_msg
	jal print_string
	move $a0, $s0
	jal print_char
	jal print_comma
	move $a0, $s1
	jal print_char
	jal print_newline

	# exit
	li $v0, 10 
	syscall

make_leaf_tester:
	# save regs
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	
	# save args
	move $s0, $a0
	move $s1, $a1
	
	# print test case and inputs
	la $a0, make_leaf_tester_msg
	jal print_string
	lw $a0, 0($s0)
	jal print_char
	jal print_comma
	lw $a0, 4($s0)
	jal print_int
	jal print_comma
	la $a0, free_space_msg
	jal print_string
	jal print_newline

	# print expected result	
	la $a0, tester_expecting_msg
	jal print_string
	move $a0, $s1
	jal print_tree

	# run test!
	lw $a0, 0($s0)
	lw $a1, 4($s0)
	la $a2, free_space
	jal make_leaf
	
	# check result
	la $a0, free_space
	move $a1, $s1
	jal tree_match
	bnez $v0, make_leaf_tester_pass
 
	# print error
	la $a0, tester_error_msg
	jal print_string
	la $a0, free_space
	jal print_tree
	jal print_newline
 
	# exit
	li $v0, 10 
	syscall

make_leaf_tester_pass:
	# print pass message
	la $a0, tester_pass_msg
	jal print_string
	
	# restore regs and return
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12
	jr $ra

merge_roots_tester:	
	# save regs
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	
	# save args
	move $s0, $a0
	move $s1, $a1
	
	# print test case and inputs
	la $a0, merge_roots_tester_msg
	jal print_string
	jal print_newline
	lw $a0, 0($s0)
	jal print_tree
	lw $a0, 4($s0)
	jal print_tree
	la $a0, free_space_msg
	jal print_string
	jal print_newline

	# print expected result	
	la $a0, tester_expecting_msg
	jal print_string
	jal print_newline
	lw $a0, 0($s1)
	jal print_tree

	# run test!
	lw $a0, 0($s0)
	lw $a1, 4($s0)
	la $a2, free_space
	jal merge_roots
 	
 	# check result
 	la $a0, free_space
 	lw $a1, 0($s1)
 	jal tree_match
 	bnez $v0, merge_roots_tester_pass

	# print error
	la $a0, tester_error_msg
	jal print_string
	la $a0, free_space
	jal print_tree
	jal print_newline
 
	# exit
	li $v0, 10 
	syscall

merge_roots_tester_pass:
	# print pass message
	la $a0, tester_pass_msg
	jal print_string
	
	# restore regs and return
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12
	jr $ra

count_roots_tester:
	# save regs
	addi $sp, $sp, -16
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)

	# save args
	move $s0, $a0
	move $s1, $a1

	# print test case and inputs
	la $a0, count_roots_tester_msg
	jal print_string
	jal print_newline

	# s2: pointer to current node in array
	lw $s2, 0($s0)
count_roots_tester_loop_top:
	lw $t0, 4($s0)
	beq $s2, $t0, count_roots_tester_loop_exit
	# print node
	move $a0, $s2
	jal print_tree
	addi $s2, $s2, 20
	b count_roots_tester_loop_top

count_roots_tester_loop_exit:	
	# print expected output
	la $a0, tester_expecting_msg
	jal print_string
	lw $a0, 0($s1)
	jal print_int
	jal print_newline
  
	# run test!
	lw $a0, 0($s0)
	lw $a1, 4($s0)	
	jal count_roots
 
	# check result against expected
	lw $t0, 0($s1)
	beq $v0, $t0, count_roots_tester_pass
 
	# error, save result
	move $s0, $v0
	
	# print error message and result
	la $a0, tester_error_msg
	jal print_string	
	move $a0, $s0
	jal print_int
	jal print_newline
 
	# exit
	li $v0, 10 
	syscall
	
count_roots_tester_pass:
	# print pass message
	la $a0, tester_pass_msg
	jal print_string
	
	# restore regs and return
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 16($sp)
	addi $sp, $sp, 16
	jr $ra
lightest_roots_tester:	
	# save regs
	addi $sp, $sp, -16
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)

	# save args
	move $s0, $a0
	move $s1, $a1

	# print test case and inputs
	la $a0, lightest_roots_tester_msg
	jal print_string
	jal print_newline

	# s2: pointer to current node in array
	lw $s2, 0($s0)
lightest_roots_tester_loop_top:
	lw $t0, 4($s0)
	beq $s2, $t0, lightest_roots_tester_loop_exit
	# print node
	move $a0, $s2
	jal print_tree
	addi $s2, $s2, 20
	b lightest_roots_tester_loop_top

lightest_roots_tester_loop_exit:	
	# print expected result
	la $a0, tester_expecting_msg
	jal print_string
	jal print_newline
	lw $a0, 0($s1)
	jal print_tree
	lw $a0, 4($s1)
	jal print_tree	

	# run test!
	lw $a0, 0($s0)
	lw $a1, 4($s0)
	jal lightest_roots

	# save returned pointers 
	move $s0, $v0
	move $s2, $v1
	
	# check if lightest matches expecting
 	move $a0, $s0
 	lw $a1, 0($s1)
 	jal tree_match
 	beqz $v0, lightest_roots_tester_fail	

	# lightest matches, check second lightest
	move $a0, $s2
	lw $a1, 4($s1)
	jal tree_match
	beqz $v0, lightest_roots_tester_fail	

	# passed, so print pass message
	la $a0, tester_pass_msg
	jal print_string
	
	# restore regs and return
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	addi $sp, $sp, 16
	jr $ra
	
lightest_roots_tester_fail:
 
 	# print error message and result
 	la $a0, tester_error_msg
 	jal print_string
	jal print_newline
 	move $a0, $s0
 	jal print_tree
 	move $a0, $s2
 	jal print_tree

	# exit
 	li $v0, 10 
 	syscall

build_tree_tester:	
	# save regs
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	
	# save args
	move $s0, $a0
	move $s1, $a1

	# print test case
	la $a0, build_tree_tester_msg
	jal print_string
	jal print_newline
	lw $a0, 0($s0)
	jal print_string
	jal print_newline
	la $a0, free_space_msg
	jal print_string
	jal print_newline

	# print expected output
	la $a0, tester_expecting_msg
	jal print_string
	jal print_newline
	lw $a0, 0($s1)
	jal print_tree
 
	# run test!
	lw $a0, 0($s0)
	la $a1, free_space
	jal build_tree
	move $s0, $v0
	
  	# check result
  	move $a0, $s0
  	lw $a1, 0($s1)
  	jal tree_match 
  	bnez $v0, build_tree_tester_pass
  
  	# print error
  	la $a0, tester_error_msg
  	jal print_string
  	jal print_newline
  	move $a0, $s0
  	jal print_tree
  
  	# exit
  	li $v0, 10 
  	syscall
  	
build_tree_tester_pass:	
  	# print pass message
  	la $a0, tester_pass_msg
  	jal print_string
	
	# restore regs and return
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12
	jr $ra
	# a0 root
	# a1 other root	
	# return 0 if not matching, 1 otherwise
tree_match:	
	# save regs
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)

	# save arguments
	move $s0, $a0
	move $s1, $a1

	# if both pointers null, return true
	or $t0, $s0, $s1
	beqz $t0, tree_match_exit_true

	# know one or the other is non-null, so if either one is null, have mismatch
	beqz $s0, tree_match_exit_false
	beqz $s1, tree_match_exit_false

	# now know both are non-null, so going to recurse

	# check if left children match
	lw $a0, 12($s0)
	lw $a1, 12($s1)
	jal tree_match
	beqz $v0, tree_match_exit_false # if false, return false from whole thing

	# check if right children match
	lw $a0, 16($s0)
	lw $a1, 16($s1)
	jal tree_match
	beqz $v0, tree_match_exit_false # if false, return false from whole thing
	
	# children match, now compare contents of the node
	lw $t0, 0($s0)
	lw $t1, 0($s1)
	bne $t0, $t1, tree_match_exit_false
	lw $t0, 4($s0)
	lw $t1, 4($s1)
	bne $t0, $t1, tree_match_exit_false
	lw $t0, 8($s0)
	lw $t1, 8($s1)
	bne $t0, $t1, tree_match_exit_false

tree_match_exit_true:
	li $v0, 1
	b tree_match_exit	

tree_match_exit_false:
	li $v0, 0
	
tree_match_exit:	
	# restore regs
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12
	jr $ra	


	# a0: tree root
	# a1: pointer to compressed text
	# a2: num bits compressed
decompress:	
	addi $sp, $sp, -28
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	sw $s5, 24($sp)
	
	# save args
	move $s0, $a0 # s0: root of tree
	move $s1, $a1 # s1: curr spot in compressed words
	move $s2, $a2 # s2: num bits to decompress
	              # s4: going to hold word of bits
	move $s5, $a0 # s5: curr position in tree

	# load first word of bits
	lw $s4, 0($s1)
	addi $s1, $s1, 4
	
decompress_top:
	# if processed all bits, done
	beqz $s2, decompress_exit

	# decrement bits to decompress
	addi $s2, $s2, -1
	
	# t0: bitmask for this bit
	li $t0, 1
	sllv $t0, $t0, $s2

	# t1: extracted bit 
	and $t1, $s4, $t0
	
	# if that was last bit in word, need to load new word
	li $t2, 1
	bne $t2, $t0, decompress_use_extracted_bit

	# load new word
	lw $s4, 0($s1)
	addi $s1, $s1, 4

decompress_use_extracted_bit:	
	# descend left or right
	beqz $t1, decompress_descend_left

	# descend right
	lw $s5, 16($s5)
	b decompress_leaf_check
	
decompress_descend_left:	
	lw $s5, 12($s5)

decompress_leaf_check:
	# if child pointer, not at leaf
	lw $t0, 12($s5)
	bnez $t0, decompress_done_with_bit

	# else at leaf, print char and reset to root
	lw $a0, 0($s5)
	jal print_char
	move $s5, $s0
	
decompress_done_with_bit:
#	jal print_newline
	b decompress_top

decompress_exit:
	jal print_newline
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)	
	lw $s5, 24($sp)
	addi $sp, $sp, 28
	jr $ra

print_tree:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	li $a1, 0
	jal __print_tree
	lw $ra, 0($sp)
	addi $sp, $sp, 4
        jr $ra
	
	
	# a0 root
	# a1 depth
__print_tree:
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)	

	# save arguments
	move $s0, $a0
	move $s1, $a1

	# if has right child, recurse
	lw $a0, 16($s0)
	beqz $a0, __print_tree_node
	addi $a1, $s1, 2
	jal __print_tree
	
	# print this node info
__print_tree_node:
	move $a0, $s1
	jal print_spaces
	li $a0, '*'
	jal print_char
	jal print_space
	jal print_lbracket
	lw $a0, 0($s0)
	jal print_char
	jal print_comma
	lw $a0, 4($s0)
	jal print_int
	jal print_comma
	lw $a0, 8($s0)
	jal print_int
	jal print_rbracket	
 	jal print_newline

	# if has left child, recurse
	lw $a0, 12($s0)
	beqz $a0, __print_tree_exit
	addi $a1, $s1, 2
	jal __print_tree

__print_tree_exit:	
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)		
	addi $sp, $sp, 12
	jr $ra

print_int:
	li $v0, 1
	syscall
	jr $ra

print_char:
	li $v0, 11
	syscall
	jr $ra
	
print_newline:
 	li $v0, 11
 	li $a0, '\n'
 	syscall
	jr $ra

print_plus:
 	li $v0, 11
 	li $a0, '+'
 	syscall
	jr $ra

print_colon:
 	li $v0, 11
 	li $a0, ':'
 	syscall
	jr $ra
	
print_equals:
 	li $v0, 11
 	li $a0, '='
 	syscall
	jr $ra

print_comma:
 	li $v0, 11
 	li $a0, ','
 	syscall
 	li $v0, 11
 	li $a0, ' '
 	syscall
	jr $ra

print_lbracket:
 	li $v0, 11
 	li $a0, '['
 	syscall
	jr $ra

print_rbracket:
 	li $v0, 11
 	li $a0, ']'
 	syscall
	jr $ra
	
print_dash:
 	li $v0, 11
 	li $a0, '-'
 	syscall
	jr $ra
	
print_space:
 	li $v0, 11
 	li $a0, ' '
 	syscall
	jr $ra

print_spaces:
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	move $s0, $a0
print_spaces_top:
	beqz $s0, print_spaces_exit
	jal print_space
	addi $s0, $s0, -1
	b print_spaces_top
print_spaces_exit:	
	lw $ra, 0($sp)
	lw $s0, 4($sp)	
	addi $sp, $sp, 8
	jr $ra
	
print_string:
	li $v0, 4
	syscall
	jr $ra

print_hexword:
	# save regs
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)

	# s0: hexword
	move $s0, $a0
	# s1: nibble mask
	li $s1, 0xf0000000

	# print 0
	li $a0, 0
	li $v0, 1
	syscall
 
	# print x
	li $a0, 'x'
	li $v0, 11
	syscall

	# print nibble
	and $a0, $s0, $s1
	srl $a0, $a0, 28
	jal print_hexchar

	# print nibble
	srl $s1, $s1, 4
	and $a0, $s0, $s1
	srl $a0, $a0, 24
	jal print_hexchar

	# print nibble
	srl $s1, $s1, 4
	and $a0, $s0, $s1
	srl $a0, $a0, 20
	jal print_hexchar

	# print nibble
	srl $s1, $s1, 4
	and $a0, $s0, $s1
	srl $a0, $a0, 16
	jal print_hexchar

	# print nibble
	srl $s1, $s1, 4
	and $a0, $s0, $s1
	srl $a0, $a0, 12
	jal print_hexchar

	# print nibble
	srl $s1, $s1, 4
	and $a0, $s0, $s1
	srl $a0, $a0, 8
	jal print_hexchar

	# print nibble
	srl $s1, $s1, 4
	and $a0, $s0, $s1
	srl $a0, $a0, 4
	jal print_hexchar

	# print nibble
	srl $s1, $s1, 4
	and $a0, $s0, $s1
	srl $a0, $a0, 0
	jal print_hexchar
	
	# restore regs
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12

 	jr $ra

print_hexchar:
	la $t0, hexchars
	add $t0, $t0, $a0
	lbu $a0, 0($t0)
	li $v0, 11
	syscall
	jr $ra
	
.data

hexchars:			.asciiz "0123456789abcdef"
tester_on_msg:			.asciiz "On: "
tester_expecting_msg:		.asciiz "Expecting: "
tester_pass_msg:		.asciiz "PASS!"
tester_error_msg:		.asciiz "ERROR! Got: "
count_char_tester_msg:		.asciiz "\n\nTesting count_char()\nOn: "
minmax_chars_tester_msg:	.asciiz "\n\nTesting minmax_chars()\nOn: "
count_roots_tester_msg:		.asciiz "\n\nTesting count_roots()\nOn: "
merge_roots_tester_msg:		.asciiz "\n\nTesting merge_roots()\nOn: "
make_leaf_tester_msg:		.asciiz "\n\nTesting make_leaf()\nOn: "
lightest_roots_tester_msg:	.asciiz "\n\nTesting lightest_roots()\nOn: "
build_tree_tester_msg:		.asciiz "\n\nTesting build_tree()\nOn: "
free_space_msg:			.asciiz "<pointer to free space>"
				 
abc_string:			.asciiz "aaaaabbbbccd"
some_good_string:		.asciiz "There is some good in this world, and it's worth fighting for."

array_of_nodes1_begin:	
array_of_nodes1_first:
	.word 'a', 120, 0, 0, 0
	.word 'b', 220, 1, 0, 0
array_of_nodes1_second:
	.word 'y', 320, 0, 0, 0
	.word 'c', 420, 1, 0, 0
	.word 'x', 520, 0, 0, 0
array_of_nodes1_end:	

array_of_nodes2_begin:	
	.word 'm', 20, 1, 0, 0
	.word '0', 20, 0, 0, 0
	.word ',', 20, 1, 0, 0
	.word '-', 20, 0, 0, 0
array_of_nodes2_end:	

array_of_nodes3_begin:
	.word 'm', 45, 1, 0, 0
	.word 'p', 93, 0, 0, 0
array_of_nodes3_second:
	.word 'x', 23, 0, 0, 0
	.word 'q', 25, 1, 0, 0
array_of_nodes3_first:	
	.word 'y', 18, 0, 0, 0
array_of_nodes3_end:	
	
count_char_test1_in:	.word 'a', abc_string
count_char_test1_out:	.word 5

count_char_test2_in:	.word 'i', some_good_string
count_char_test2_out:	.word 6

minmax_chars_test1_in:	.word abc_string
minmax_chars_test1_out:	.word 'a', 'd'

minmax_chars_test2_in:	.word some_good_string
minmax_chars_test2_out:	.word ' ', 'w'
	
make_leaf_test1_in:	.word 'b', 200, 0
make_leaf_test1_out:	.word 'b', 200, 0, 0, 0

make_leaf_test2_in:	.word 'x', 125, 0
make_leaf_test2_out:	.word 'x', 125, 0, 0, 0

count_roots_test1_in: 	.word array_of_nodes1_begin, array_of_nodes1_end
count_roots_test1_out:	.word 3

count_roots_test2_in: 	.word array_of_nodes2_begin, array_of_nodes2_end
count_roots_test2_out:	.word 2

lightest_roots_test1_in:	.word array_of_nodes1_begin, array_of_nodes1_end
lightest_roots_test1_out:	.word array_of_nodes1_first, array_of_nodes1_second

lightest_roots_test2_in:	.word array_of_nodes3_begin, array_of_nodes3_end
lightest_roots_test2_out:	.word array_of_nodes3_first, array_of_nodes3_second
	
test_node1:	.word 'b', 200, 0, 0, 0
test_node2:	.word 'c', 300, 0, 0, 0	

test_tree1:		.word 0, 500, 0, test_tree1_left, test_tree1_right
test_tree1_left:	.word 'b', 200, 1, 0, 0
test_tree1_right:	.word 'c', 300, 1, 0, 0	

merge_roots_test1_in:	.word test_node1, test_node2
merge_roots_test1_out:	.word test_tree1

	

abc_string_subtree_5: .word 'a', 5, 1, 0, 0
abc_string_subtree_4: .word 'b', 4, 1, 0, 0
abc_string_subtree_2: .word 'c', 2, 1, 0, 0
abc_string_subtree_1: .word 'd', 1, 1, 0, 0
abc_string_subtree_3: .word 0, 3, 1, abc_string_subtree_1, abc_string_subtree_2
abc_string_subtree_7: .word 0, 7, 1, abc_string_subtree_3, abc_string_subtree_4

abc_string_tree_5: .word 'a', 5, 1, 0, 0
abc_string_tree_4: .word 'b', 4, 1, 0, 0
abc_string_tree_2: .word 'c', 2, 1, 0, 0
abc_string_tree_1: .word 'd', 1, 1, 0, 0
abc_string_tree_3: .word 0, 3, 1, abc_string_tree_1, abc_string_tree_2
abc_string_tree_7: .word 0, 7, 1, abc_string_tree_3, abc_string_tree_4
abc_string_tree_12: .word 0, 12, 0, abc_string_tree_5, abc_string_tree_7

merge_roots_test2_in:	.word abc_string_subtree_5, abc_string_subtree_7
merge_roots_test2_out:	.word abc_string_tree_12
	
build_tree_test1_in:	.word abc_string
build_tree_test1_out:	.word abc_string_tree_12

cab_message:	.word 0x0000002b

final_message:	.word 0x0000003f, 0x725e14d8, 0x5e63b1da
	
free_space: .space 20000
	
english_frequency_string:	.asciiz "LOOCAIESPNNOCIDTASAPGISAATLBYUCICFODPADSIINLIARVWOHHPOCEYLSLASIMEIIRBNDPAEHOAKEELUZUDTHERTAERGEAANWYLAGRSOEMLOEUTDETEULPPEEEOOCTIEIVNOTURINTRNGHRNAPTRTTMRIBHFTOMNCMPIEIFOCBFOROTHAYIDOGEGTAHEEIETLODKNSEISSYMRYOOUMOGPYLHECEMEAYETNISTFCOYNRINEIHHIRDEEULASSRHPECSSESYEADDPEDYFSNBOLILORLNJNIILOETLSWTOIINRSCABAAAECWNTYPTAEYKERIMFEANTURTHETNOAEKPRRGHSUKDNYHEHNCLTPEIBPNYMNMHEGUFLIDIEFHGTEFOILNAOBERUODIYREDNNNKTVTHIGOPELOLONOGEASRYXSCRIEEIAACECCRHKNTCESSVLYDSULRELSBNDRRNIAKGVATLMRWYVRHSARLNTEIRPWQOSNGEACATXNCTLURRTEHNEMOPVPEPIDANGBKIFMLLTSESETAEUNOECTADIROTPISEUTSNIDEABISSLOIPOTROMDIICDIDNETOLTHDTSNNCLCEMDEOISCASXOLCUUSVELEUEACETRZIARYDIRDASWUCEEISRLADEPSAFTCAESEOCTCMORITHSSTBEOXEPIAAAESNRTHONOARCINOREEOATEHEODCACNTAIFEFBIETCSOTUOEWTNOCPLADTNTTOFICDIUVCTBAIAOOTSZHHARATNTTRSOLNIRLLHNLSOTOEIKUACTMCLRIEMHIDNFTIYSTAWBSPEOLIUINNANNRLLCDRURCGMAIPGDYSBVNULNDESDIVOROMLALIOGBGPIUAEEIBZVAEIMPAURINECASRIMINATCLMRMDPGLOSBIERWROHONTECPGENSTNEOOOLBYBLSEINNYHRNCNRLREERECCRWDODMALOIMBIOFOLOOEPPHNHLEIERTMIICMITICMOFCSMEULDRNEWAELRHSETPFEILSBLNLCRHKRCXHMEEELERRNYPLWRBORGEARDAAINSTARWURPNSASAHLITIENAEMIAIRSNFTWOMOGRSSRFEROLKAKAITLCEOLUSASNLMRAIELIVOXWKCRYISOSXIHSLYKMEONREMKETTOUEEKIPASOOAUVSENEARBSHPWRTCACLSAFAELDOEVGOAOARISIMNCTRDETNSASBIIESTOEERUARRDIPEEABLIPHEFCINCLSTELBBSNLIEOIONEOTLZRLDTOECKGNCYRCSUBCEICLEXONHEILNWACRTUBOOTEAEIHAADOROIEPTLTRIENRDFUOAOEBAHHCNCRRTATIEUGTSRNMUHSLESOALNSISENNUAMEBPEWTSELUNCEOITHGAOPTSLMSEPSYARAEPIIUIBAEENSLERSERSELSTICAAOUMNTIAALASEOEVMCRPRLCDSGMDIRUSCTARACRTOUEPGLNEEGENOLANNRTPTIDRGIEIGDURADGLTOSPAEERADOWVAEELVLEDAATOETODFOAETUPPSUETTOEOCIPNNCEYNDIRLEAECIIAPOREPACEUATNLGLMHELNALFREANIGONEAISIAYSCNUBSDSENUODENEAHDLECNXCDHWRGACTTIREIRRSOLFNDRDSUDATVHPEBCNHNPHAORTINSAPGVOSGTTUHYBLCSNAYMORIEAONEEPEUDLNELILCNRSSSROTLOPRUTRIUOKOPAEPRRTLGUPOEKPFFPIUSBSOMERRRRHDLYGNALCNSEVDPHBETEUSLALCHNENAEARROMDTIUANOYTNSPPCSLSKCOERNTRDGMBPRNSTIACAPRTOADAITIEMILLDAERVNAITFRPNMNOOMLAERRARUARSLDDNEMBETRHNHREATEESPHHDTETWBDEANEULLWTTEVNNNYIPYTSRTTOIEIRILLIECUAENNTQEVRIZOEEARRAGBHARGNDRIEOITTTDUCJROISTQRDTUTEASETCNCEQRATTTISROAIDARTLOCLCEOIMRUADNNSHAUMEDCMHTPYFTUTOLRLPMSLELTIPSPOICCCEERIECUIBIPSPNBNECGNIROCMLOOIIRUYMRIEIEROUEPLAOASSNEAEIEAERLPNHRRNIHLTRRBSLESEBAEEMSNYDTNOUCJSNNDREEENEUTLUFIMRIERATAWTERWLICETTCNAIRETEUMNLONEAASYGVUEDARCRESULTTNNSKODLHOGNEAGEAECNTGRESIOISTRUDNGLRMUEAPATTKNKMIREULTNUEIYPTLPIKDAGESSOHMLICEVNMRCISNZOOILBNNIRORLIIHOELIRESCGFRUEBFOTEIISASELTMIINBSSXTKUKTRODYOGAEOEWTDNCLASEEOOUERFCCLILZDPGRTKAITCEOONTATEOGOIINGESNEUARNEAZEPHOOREPNWYNWKNSODEETCLEOSYOSPAATHHARCORCNZOIMEDSEISASVRIVETADPLEDCIAPANHTATEOITCPRKSMCILIOFAOLOUTELLEIGLSONLNINRSORRHMSACMRRAJENLAREAMEOEOTCOGURCLLOICSIREBUTIIKHANEORUEGEWFDMMEOIELAIUUUATSTHUOIAASTSCAUNURSSCEPNOTUAPNPTTACNANPFCBTCETLILEETSMCKIALUCCEIPRSPUETMTRDADYLNBDHOAAECYVRRCESHZKAUOCYMEMTENBEMWIIAUAEIHIMDASRNPCIDTCTCLDBSMLEAROSNRGADLFCNIITDGPIOWLNEFREALUOSCUBPOFRESIYLTORNETICSREETEEMITFUWSLIAINEDSLAIAEAHTEGATBRETOOBCCPTORRUBBOTOPSMAFNOKPOGAEANTTAGAHNDJDORUHCGOPMSTRAASBNIEIEUPLWRIIECNTDTSNAESHLOOLMNNRLCAEAADAFOGITEMTAIPNORLONCEEUORPNTDWNAGOOHRDSUUTINNUUATTCRNENSIONMIORTEKCCIOTLEIZREIWTLDNIZGOANUAXORTPAMTRAEMNHVQERJGPSARTHACMATSSMCRAYAINOCPICEFUONSRRNCFVSUOCEIDNSEGUEAUELONLERUHWUHLPSLELBSDCGHDEORPOSTFIKPCRRAMOSNNERONLANPHIFELFELEGASGTUNYOBPFAUOSEISGURRTEINRSIOTCAEOWLRNIOWETUUAETONUTXERYTRORLBEIMMENXHAFAIERLIRIIOIUOEAERENDTRHULNRTLEELSCEOEKIBIARIBKPOCPIUCTARUENPLEOEDRCEDWYDRHHASNICEWHREITIMDOIWADATAYOLAOEHDEPEELNUOFPYBVEFAOHOISAMRKARATOUGIORRTAETJOCIRGRVIIUEDLIRARIEOCAELIINATRSOELNSUYASLAEFOWORELNVGWETTRLUIUNUNHCTEEENAOTCNDAEALMRAIIIUABFIEADSVEEIWSHOOTDIGNIFTBORHEONMNCSCETARPGOUDTTANGESMBISLLHTCBEAEIMUISUSLIAETCNDSRNEHBEPCTTRFMTYILSAUAPAHEOAOAAAUGNENIFRTSIGONCEEELDGETFPTEGCSLOEEFVURFUINTHAAPEMDEUINAMSUUAIAPAUACBLOPEIATCLBMMAHEEDEYAYAORAYIMELNDLDEGEGIAMNMTFELEDSLASSLEAYLREAJAITSEYRAJPSTTETNTIOBCSRWERODDCOFUAINWDSENOAOHURYIIFYGGRAHRORSFEHAANITTERAMEWRLHHDMASRBAAPEYSPIUYECLARCRRDIOTRITDMTNBCVLDSEOEENPNYDNESPLNTTHSADULTPTALVSOIOIAAGOCNAYNIAVNORMMNYRAGHHLSGEEDVRWOEUOIINSAINSIAMMLPEATRRISBOECUXRLAIUENTKALDTTMRESATUFRLMTBAWVUEPOGBLGSHUOEAHYLRCARGOSKTRTGURGEACYOCYLKAHMEONISETENBRRGAEASGEEACUFMASOSIMESSLNSRCURMTSUIVOSDIBLLLEUSLUETEBTRURAGAFYONELKEUONSVEMAEBLDTHTDETNHPHITRNPTGONYCIAOVONEVAIEIEDPETHLROWICECLEEIOHEITMIIENEAYDAEEHRMELISSIONOSUSNPTRLSNAAIAVOAIPRANARLBETCSIASMTGEKMSUNOPAULCIYIRWMSMBLINEEWOETOKWEYNLHARSEBLFLWACOITAERIYGRGAGANNODEAZGAORRTTKGANLTNENNYEUMTNKITUNIOLOSSASGEGEENDCSLMRIRRCRNNOEPTMIUUILWAWDTAETAGPEHVENNERINEKNLKIAAIATNMOANWBNOEMTMKOOTOLMNBNUERONIDLTEIHDREEAIRHSENRBARTIDCIOEAYATMUCNOYEOINEAERYEEELUNCMAFYIIAEMSMSEREREFSBGNOCAHHYTWINIINYFRGPFADIOWTEERTNIODRIULRSSDFRGKNGTHRSLSARITARWEOTBCHERLOPCNEHESOEVTTNWPNTNATIEREIRHURYVNAODIISSBRRAATMHMAUGAGUPTNRMSNRILBNXCTHMLRUARRDNEINOAOTSIECUDBEEIOCLETRXNMIGTGAMRSGGDNIYOCIERTHNTIRRBSEWEPIATLAEODCRMLDGPSSSTRTIOTCRLMOSLCPIUOULDEESINFTROUDBMMMLTDKIDOOGHLGCPRECEMADLRTUOPCWEBDLUCIUAANUESEAMAHRAYMPCAPNOCAIIAKAPAGNBRANREFTEEATCAGANBNOEPNDBLRLRCETDAHOWGOESGJYIPHNOFSALMEEYCLIOAEOIGMATLIAERLLACRWRWTLFDTRDTOHFGAGEPGROLUCARBEIUSEENTEEELLTLIEEOTHSARINKGAFAWFVYAAACBNLEMLMFEEOFPEFTXLRCRATERECBCLDFSARVRCLSHGEMRFAICOOASAEBEFHOEMTMEHUNOTAESRURIEOSDHOAICNOVTOENRLLITIIVLAEOCSTFSIIRBCTYBEITSONFBILTYPPCPENLCRHEUGBDIECTPIGFATIGEARPPIHGGEEMSICNIPRKFMOBCHSRNONAHTORANTERFRIAPPDCPRNLNFRCCLMCETIRNLEAWSRQAOSOEAEHSVOAILHLNOKCSREIENYHIETOBHFMGSEALNOAAICOANLCNHRLUOAOANETARDMNIIRNHMVETPALDISQCHIHRASTWGEEIWNHGTAGEEHPRSINSOIAIINIIPAOCETNONTITAEODPNLOTRHICWNVREEETNLETVIAEICCYAEEEEUTMTSRFNCRYPOTMCIINOALRUIDMEOPYDMOREEASTROBNODSTTEBGREYDPITYEONUIOSRAUSLEMTABRSWOEOORLOOFETSFSYOCSAOOLNAEAZNLNTHRSTFDEAOBHCTONAFCONIELHRTGAHOEEHORTERRSSHCINJCREEATUEBAEIEORICTRMNNACNENREEWDDAERLIVILRRTCTOHRFBENAORAYCHBTAEUBRAEEEASRODROIIUSGESAARRNUFHDADIBNVNRICPYRINPEOREMNLNDINATIUCDAMKEDCNCTIJUTTZESLERKEMAKNFRAISHUDMRISFOEEQTTLVMLERTASTLHIOIKBRPSENPPSEUGIFRUOSESRKTWSDOATIHSBBEPEDAVUGALOSHHOSCMODOTSALHSOYTDNCEOCLSNIRNATOTORRETELRALSTIANHAIDHSEUOLSIEGATITCUAOERIFRSOTEHRTAEWLTEEATKPHOUESRFISAODUAAOUAAPOFBAMPAREULNEAEASUAYEURWATDLEADOOPMSOCHEALTONEDPKAMOIGONIILACLTSDHWPOECBKAGFARGPLTECRSDKORYIOFEUNWOPLOSAPREEULMUYITNOCROPRCIOUCORFQTMHRESRYILNOIITBCKIOLSLYKUAUHDGCERRAEMAAGONLAEPE"
