namespace SudokuOracles {
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;

    // Oracle for verifying if 2 n bit numbers are the same
    operation NumberEqualityOracle(
        n0 : Qubit[],
        n1 : Qubit[],
        target : Qubit
        ) : Unit is Adj+Ctl {

        within {
            // Bitwise XOR of qubits arrays (numbers n0 and n1) in place
            for ((q0, q1) in Zipped(n0, n1)) {
                CNOT(q0, q1);
            }
        } apply {
            // If all XORs are 0, the numbers are the same -> flip target qubit
            // E.g. If we compare qubit n0 in state |01> and qubit n1 in state |01>:
            //      CNOT(q0=0, q1=0) -> q1=0
            //      CNOT(q0=1, q1=1) -> q1=0
            // n1 stage becomes |00> and target qubit is flipped (target state becomes |1>)
            (ControlledOnInt(0, X))(n1, target);
        }
    }

    // Oracle for verifying a Sudoku solution
    operation SudokuOracle(
        gridPairs : (Int, Int)[], 
        solutionsRegister : Qubit[], 
        target : Qubit,
        nbits : Int
        ) : Unit is Adj+Ctl {

        // The number of qubits to represent each digit is a function of the Sudoku order:
        // Order 2: 0 to 3 needs 2 qubits (e.g. 3 = 11)
        // Order 3: 0 to 8 needs 4 qubits (e.g. 3 = 0011)

        // Split the solutionsRegister by digits
        let digits = Chunks(nbits, solutionsRegister);

        // Allocate array of qubits to store conflicts with the Sudoku rules
        using (conflictQubits = Qubit[Length(gridPairs)]) {
            within {
                // Loop through the Sudoku grid pairs considered (i, j)
                for (((i, j), conflictQubit) in Zipped(gridPairs, conflictQubits)) {
                    NumberEqualityOracle(digits[i], digits[j], conflictQubit);
                }
            } apply {
                // A correct Sudoku solution has conflictQubits in state |0 .. 0⟩ and
                // a target qubit flipped (target state becomes |1>).
                // If 2 numbers are incorrectly the same, conflictQubit will have the qubit
                // for that grid pair in state |1>.
                (ControlledOnInt(0, X))(conflictQubits, target);
            }
        }
    }
    // Oracle that marks the qubit states that represent a valid solution using their phases
    // (instead of using the state of an extra qubit)
    operation OracleConverter(
        markingOracle : ((Qubit[], Qubit) => Unit is Adj), 
        register : Qubit[]
        ) : Unit is Adj {

        using (target = Qubit()) {
            within {
                // Prepare target state in |-⟩ state...
                X(target);
                H(target);
            } apply {
                // ... so that in applying the marking oracle,
                // 'phase kickback' adds a -1 relative phase to the register state
                // if the target is flipped
                markingOracle(register, target);
            }
        }
    }
}