namespace SudokuSolutionsSuperposition {
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Intrinsic;

    // Recursive solution for the implementation of superposition of an aribtrary number bit strings from
    // https://github.com/microsoft/QuantumKatas/blob/main/Superposition/Workbook_Superposition_Part2.ipynb
    operation BitstringSuperposition (qs : Qubit[], bitstring : Bool[][]) : Unit {
        BitstringSuperposition_Recursive(new Bool[0], qs, bitstring);
    }

    operation BitstringSuperposition_Recursive (currentBitString : Bool[], qs : Qubit[], bitstring : Bool[][]) : Unit {
        // An array of bit strings whose columns we are considering begin with |0⟩
        mutable zeroLeads = new Bool[][0];
        // An array of bit strings whose columns we are considering begin with |1⟩
        mutable oneLeads = new Bool[][0];
        // The number of bit strings
        let rows = Length(bitstring);
        // the current position we're considering
        let currentIndex = Length(currentBitString);
        // For bitstrings > qs, the process stops when currentIndex > Length(qs)
        if (rows >= 1 and currentIndex < Length(qs)) { 
            // figure out what percentage of the bits should be |0⟩
            for (row in 0 .. rows-1) {
                //Message($"{bits[row]}, {currentIndex}, {currentBitString}");
                if (bitstring[row][currentIndex]) {
                    set oneLeads = oneLeads + [bitstring[row]];
                } else {
                    set zeroLeads = zeroLeads + [bitstring[row]];
                }
            }
            // rotate the qubit to adjust coefficients based on the previous bit string
            // for the first path through, when the bit string has zero length, 
            // the Controlled version of the rotation will perform a regular rotation
            let theta = ArcCos(Sqrt(IntAsDouble(Length(zeroLeads)) / IntAsDouble(rows)));
            (ControlledOnBitString(currentBitString, Ry))(qs[0 .. currentIndex - 1], 
                                                        (2.0 * theta, qs[currentIndex]));
            
            // call state preparation recursively based on the bit strings so far
            BitstringSuperposition_Recursive(currentBitString + [false], qs, zeroLeads);
            BitstringSuperposition_Recursive(currentBitString + [true], qs, oneLeads);
        } 
    }
}