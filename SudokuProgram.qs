namespace ExploringGroversSearchAlgorithm {
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Intrinsic;
    open SudokuElements;
    open SudokuOracles;
    open SudokuSolutionsSuperposition;


    operation RunGroversSearch(
        register : Qubit[],
        phaseOracle : ((Qubit[]) => Unit is Adj),
        iterations : Int,
        bitstring : Bool[][]
        ) : Unit {

        // Prepare an equal superposition of basis states in the register as defined by bitstring
        // E.g. A register with 3 qubits and the bitstring = [[False,False,True], [True,False,False]]
        // we obtain 1/sqrt(2)*(|001⟩ + |100⟩)
        // Note that Grover's Search algorithm would normally contain
        // an equal superposition of ALL basis states of the input register.
        // E.g. for a register with 3 qubits, we would prepare the register in
        // the state 1/sqrt(8)*(|000⟩+|100⟩+|010⟩+|001⟩+|101⟩+|110⟩+|011⟩+|111⟩) 
        BitstringSuperposition(register, bitstring);
        //DumpRegister((), register);

        // Grover iterations
        for (_ in 1 .. iterations) {
            phaseOracle(register);
            within {
                ApplyToEachA(H, register);
                ApplyToEachA(X, register);
            } apply {
                Controlled Z(Most(register), Tail(register));
            }
        }
    }

    @EntryPoint()
    operation SolveGraphColoringProblem() : Unit {

        // Define the Sudoku:
        // - order=2: 4x4=16 grid Sudoku
        // - order=3: 9x9=81 grid Sudoku
        let order = 2;
        // let gridSize = PowI(order, 2) * PowI(order, 2);
        // Grid pairs defines pairs of Sudoku cells that cannot contain the same number
        // (see verticesList for details)
        // let gridPairs = verticesList(order);

        // Test with smaller Sudokus
        //let gridSize = 6;
        //let gridPairs = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (0, 4), (1, 4), (0, 5), (1, 5), (4, 5)];
        // let gridSize = 4;
        // let gridPairs = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)];
        let gridSize = 3;
        let gridPairs = [(0, 1), (0, 2), (1, 2)];

        // How many bits to represent the Sudoku numbers?
        // - A 4x4 Sudoku contains 4 numbers (1 to 4).
        //   We can pick the 4 numbers as 0 to 3, and these can be represented by 2 bits.
        // - A 9x9 Sudoku contains 9 numbers (1 to 9).
        //   Even if we pick these numbers as 0 to 8, we need 4 bits (8 being 1000 in binary).     
        // Each number is described using 'bitlength' bits (or qubits).
        mutable SudokuNumbers =  new Int[0];
        mutable bitlength = 0;    
        if (order == 2) {
            set bitlength = 2;
            set SudokuNumbers = [0, 1, 2, 3];
        } elif (order == 3) {
            set bitlength = 4;
            set SudokuNumbers = [0, 1, 2, 3, 4, 5, 6, 7, 8];
        } elif (order == 4) {
            set bitlength = 4;
            set SudokuNumbers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
        }

        // Prepare permutations of Sudoku numbers
        // e.g. if Sudoku numbers are [1,2], the function DoPermute
        // returns the array of arrays [[1,2], [2,1]]
        let SudokuRow = DoPermute(SudokuNumbers, new Int[][0], 0);
        //let test = DoPermute([0, 1, 2, 3, 4, 5, 6, 7, 8], new Int[][0], 0);
        // Obtain arrays of Sudoku solutions (good and bad)
        // The solutions are based on permutations of the Sudoku numbers by rows.
        // E.g. Consider a 4x4 Sudoku
        // Any of the 4 rows could be any permutation of the set {1,2,3,4}. There are 4!=24 such solutions.
        // Irrespective of being a correct or wrong Sudoku solution, with 4 rows there are 24^4 (24x24x24x24) ways of
        // completing a Sudoku grid using one permutation of the 4! for each row.
        // A wrong Sudoku solution that is obtained following this process is:
        //     -----------------
        //     | 0 | 1 | 2 | 3 |
        //     -----------------
        //     | 0 | 1 | 2 | 3 |
        //     -----------------
        //     | 0 | 1 | 2 | 3 |
        //     -----------------
        //     | 0 | 1 | 2 | 3 |
        //     -----------------
        // The array that defines this solution is [0,1,2,3,0,1,2,3,0,1,2,3,0,1,2,3], and there are 24^4 arrays that are obtained using
        // the function DoPermuteArrays.
        // We can speed up the computation by reducing the number of rows/cells to solve for the Sudoku.
        let sudoku = [SudokuRow];  // 1 row of a Sudoku
        //let sudoku = [SudokuRow, SudokuRow];  // 2 rows of a Sudoku
        //let SudokuSolutions = [sudoku, [[0], [1], [2], [3]]]; //  1 row + 1st cell from 2nd row
        //let SudokuSolutions = [SudokuRow, SudokuRow, SudokuRow, SudokuRow];  // 4 rows of a Sudoku
        let SudokuSolutions = DoPermuteArrays(sudoku, new Int[][0], 0, new Int[0], new Int[0], new Int[0], new Int[0]);
        Message($"{Length(SudokuSolutions)}");
        // Transform the arrays of Sudoku solutions numbers to bit strings using little-endian encoding
        // E.g. input [[0,1,2,3], [0,1,3,2]] is transformed to
        // [[False,False,True,False,False,True,True,True], [False,False,True,False,True,True,False,True]]
        mutable SudokuBitstring = new Bool[][0];
        for (SudokuSolution in SudokuSolutions) {
            mutable bitstring = new Bool[0];
            for (i in SudokuSolution) {
                set bitstring = bitstring + IntAsBoolArray(i, bitlength);
            }
            set SudokuBitstring = SudokuBitstring + [bitstring];
        } 

        // Define the oracle that finds the Sudoku solutions...
        let markingOracle = SudokuOracle(gridPairs, _, _, bitlength);
        // ... and transform it into a phase oracle
        let phaseOracle = OracleConverter(markingOracle, _);

        // Preallocate the Sudoku solution variable
        mutable solution = new Bool[gridSize * bitlength];

        // The register has the number of qubits that is bitsPerColor qubits
        // times the number of grid cells considered.
        using ((register, output) = (Qubit[gridSize * bitlength], Qubit())) {
            mutable nIterations = 1;
            mutable isCorrect = false;
            // We run Grover's search for 1 interation but if we don't find a correct solution
            // we run it for 2 iterations and keep increasing it by 1 more until a solution
            // is found or the max number of iterations is reached
            repeat {
                RunGroversSearch(register, phaseOracle, nIterations, SudokuBitstring);
                // MultiM measures each qubit in a given array in the standard basis.
                let res = MultiM(register);
                //  We apply the Sudoku oracle (marking oracle) after measurement to check if the
                // solution is correct. If correct, output qubit is in state |1⟩
                markingOracle(register, output);
                if (MResetZ(output) == One) {
                    set isCorrect = true;
                    set solution = ResultArrayAsBoolArray(res);
                }
                ResetAll(register);
            }
            until (isCorrect or nIterations > 30)
            fixup {
                set nIterations += 1;
            }
            if (not isCorrect) {
                fail "No valid Sudoku solution was found";
            }
        }

        // Convert the valid solution to readable format
        let numberBits = Chunks(bitlength, solution);
        Message("The resulting Sudoku solution:");
        for (i in 0 .. gridSize - 1) {
            Message($" Index {i} - Number {BoolArrayAsInt(numberBits[i]) + 1}");
        }
    }
}