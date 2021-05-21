namespace SudokuElements {
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Arrays;

    function verticesList (o : Int) : (Int, Int)[] {
        // Creates list of pairs of vertices that have to contain different numbers.
        // Output example: [(0, 1), (0, 2), (0, 3)]
        // Example:
        // - For a Sudoku of order 2, there are 2^2 * 2^2 numbers (16) in 2^2 blocks (4) (this is also a 4x4 Sudoku);
        // - For a Sudoku of order 3, there are 3^2 * 3^2 numbers (81) in 3^2 blocks (9) (this is also a 9x9 Sudoku);
        // 
        // If we consider a 4x4 Sudoku, we number the positions of the numbers as:
        //     -----------------
        //     | 0 | 1 | 2 | 3 |
        //     -----------------
        //     | 4 | 5 | 6 | 7 |
        //     -----------------
        //     | 8 | 9 | 10| 11|
        //     -----------------
        //     | 12| 13| 14| 15|
        //     -----------------
        // 
        // Then, the rules of Sudoku are:
        // - Numbers for each row (e.g. positions 0, 1, 2 and 3) have to be different to each other
        // - Numbers for each column (e.g. positions 0, 4, 8 and 12) have to be different to each other
        // - Numbers within each of the 4 blocks (e.g. positions 0, 1, 4 and 5) have to be different to each other
        //
        // Constants
        let o2 = PowI(o, 2);
        let o3 = PowI(o, 3);
        mutable vertices = new (Int, Int)[0];

        // Obtain all pairs in columns
        for (a in 0 .. o2-1) {
            for (b in a .. o2 .. o2*(o2-2) + a) {
                for (c in b + o2 .. o2 .. o2*(o2-1) + a) {
                    set vertices = vertices + [(b, c)];
                }
                
            }
        }
        // Obtain all pairs in rows
        for (a in 0 .. o2 .. o2*(o2-1)) {
            for (b in a .. a+o2-2) {
                for (c in b+1 .. a+o2-1) {
                    set vertices = vertices + [(b, c)];
                }
                
            }
        }
        // Obtain all pairs within the blocks...
        for (a in 0 .. o3 .. o3*(o-1)) {
            for (b in a .. o .. o2-o+a) {
                mutable n = new Int[0];
                for (i in 0 .. o-1) {
                    for (c in b+i*o2 .. b+i*o2+o-1) {
                        set n = n + [c];
                    }
                }
                // ...excluding those pairs already present when obtaining pairs in columns and rows
                for (bp in 0 .. o2-2) {
                    for (cp in bp+1 .. o2-1) {

                        let exists = equalArray(vertices, [n[bp], n[cp]]);
                        if (not exists) {
                            set vertices = vertices + [(n[bp], n[cp])];
                        }
                    }
                }
            }
        }
        return vertices;
    }
    function equal (a: Int, b: Int) : Bool {
        // Check equality
        return a == b;
    }

    function equalArray (vertices : (Int, Int)[], candidate : Int[]) : Bool {
        // Check if a pair of positions already exists.
        // If the new candiate (pair of positions) already exists, returns true
        for (vertex in vertices) {
            let vertexArray = TupleArrayAsNestedArray([vertex]);
            if (EqualA(equal, candidate, vertexArray[0])) {
                return true;
            }
        }
        return false;
    }

    function DoPermute(
        nums: Int[],
        results0: Int[][],
        start: Int) : Int[][] {

        // Temps var based on original list of digits
        mutable temp1 = nums;
        // results array
        mutable results = results0;
        
        if (start == (Length(nums)-1)) {
            // temp1 is one of the possible n! solutions, add it to the list.
            set results = results + [temp1];

        } else {
            for (i in start .. (Length(nums)-1)) {
                // Save before swap
                mutable temp0 = temp1[start];
                // do swap
                set temp1 w/= start <- nums[i];  // ternary operator
                set temp1 w/= i <- temp0;
                // recursion
                set results = DoPermute(temp1, results, start + 1);
            }
        }
        return results;
    }


   function DoPermuteArrays(
        arrayOfArrays: Int[][][],
        results0: Int[][],
        start: Int,
        t0: Int[],
        t1: Int[],
        a0: Int[],
        a1: Int[]) : Int[][] {

        // Inputs
        // arrayOfArrays (e.g. [[[1,2], [2,1]], [[3,4], [4,3]]])
        // arrayOfArrays[i] contains the permutations of a given array
        // obtained with DoPermute function
        // Other inputs are only relevant during recursion

        // Output
        // result[i] is an array with a combination of the input arrays
        // e.g. if the input is [[[1,2], [2,1]], [[3,4], [4,3]]],
        // the output is [[1,2,3,4], [1,2,4,3], [2,1,3,4], [2,1,4,3]]

        // results array
        mutable results = results0;
        
        // Temp vars
        // Only valid arrays temp1 will be added to the results 
        mutable temp1 = t1;
        mutable temp0 = t0;
        // i0 and i1 are arrays indices (array[i0][i1])
        mutable i0 = a0;
        mutable i1 = a1;
        // Valid condition to append temp1
        mutable condition = true;

        // 'While' loops introduced to reduce number of iterations
        // Loop1 counter
        mutable loop1 = 0;

        if (start == Length(arrayOfArrays)) {
            while (loop1 <= Length(i0)-2) {
                // Loop2 counter
                mutable loop2 = 1;

                while (loop2  <= Length(i0)-1) {
                    // if there are 2 matching pairs, the array is not valid
                    // (it's already present in the results)
                    if ((i1[loop1] == i1[loop2]) and
                        (i0[loop1] == i0[loop2]) and
                        (loop1 != loop2)) {

                        // Update counter to exit the loops and set condition false
                        set loop2 = Length(i0);
                        set loop1 = Length(i0);
                        set condition = false;

                    } else {
                        // Update counter
                        set loop2 += 1;
                    }
                }
                // Update counter
                set loop1 += 1;
            }

            // If there are NOT 2 matching pairs, temp1 array is a valid combination
            // (condition remains true)
            if (condition) {
                set results = results + [temp1];
            } 

        } else {
            for (i00 in start .. Length(arrayOfArrays)-1) {
                for (i11 in 0 .. Length(arrayOfArrays[i00])-1) {

                    // Save before appending
                    set temp0 = temp1;
                    // add new array
                    set temp1 += arrayOfArrays[i00][i11];
                    // add indeces to check if it is a valid combination
                    set i0 = i0 + [i00];
                    set i1 = i1 + [i11];
                    // recursion
                    set results = DoPermuteArrays(arrayOfArrays, results, start+1, temp0, temp1, i0, i1);
                    // undo adding array
                    set temp1 = temp0;
                }
            }
        }
        return results;
    }
}