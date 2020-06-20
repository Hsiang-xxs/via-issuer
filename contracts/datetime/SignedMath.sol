pragma solidity ^0.6.4;


/**
 * Advanced math library for signed integers
 * (including floats which are represented as multiples of 10 ** 18)
 */
library SignedMath {

    int256 constant private INT256_MIN = -2 ** 255;

    uint256 constant public PRECISION = 18;
    uint256 constant public MULTIPLICATOR = 10 ** PRECISION;


    /**
     * @dev The product of a and b has to be less than INT256_MAX (~10 ** 76),
     * as devision (normalization) is performed after multiplication
     * Upper boundary would be (10 ** 58) * (MULTIPLICATOR) == ~10 ** 76
     */
    function floatMult(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        if (a == 0 || b == 0) return 0;

        require(!(a == -1 && b == INT256_MIN), "SignedMath.floatMult: OVERFLOW_DETECTED");
        int256 c = a * b;
        require(c / a == b, "SignedMath.floatMult: OVERFLOW_DETECTED");

        // normalize (divide by MULTIPLICATOR)
        int256 d = c / int256(MULTIPLICATOR);
        require(d != 0, "SignedMath.floatMult: CANNOT_REPRESENT_GRANULARITY");

        return d;
    }

    function floatDiv(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        require(b != 0, "SignedMath.floatDiv: DIVIDED_BY_ZERO");

        // normalize (multiply by MULTIPLICATOR)
        if (a == 0) return 0;
        int256 c = a * int256(MULTIPLICATOR);
        require(c / a == int256(MULTIPLICATOR), "SignedMath.floatDiv: OVERFLOW_DETECTED");

        require(!(b == -1 && a == INT256_MIN), "SignedMath.floatDiv: OVERFLOW_DETECTED");
        int256 d = c / b;
        require(d != 0, "SignedMath.floatDiv: CANNOT_REPRESENT_GRANULARITY");

        return d;
    }

    /**
        * @dev Returns the smallest of two signed numbers.
        */
    function min(int256 a, int256 b) internal pure returns (int256) {
            return a <= b ? a : b;
    }

    /**
        * @dev Returns the largest of two signed numbers.
        */
    function max(int256 a, int256 b) internal pure returns (int256) {
            return a >= b ? a : b;
    }
}
