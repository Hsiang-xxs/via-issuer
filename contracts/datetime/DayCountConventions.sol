pragma solidity ^0.6.4;

import "./BokkyPooBahsDateTimeLibrary.sol";
import "./SafeMath.sol";
import "./SignedSafeMath.sol";
import "./SignedMath.sol";


/**
 * @title DayCountConventions
 * @notice Implements various ISDA day count conventions as specified by ACTUS
 */
contract DayCountConventions {

    using SafeMath for uint;
    using SignedSafeMath for int;
    using SignedMath for int;

    /**
     * Returns the fraction of the year between two timestamps.
     */
    function diffTime(uint256 startTime, uint256 endTime)
        internal
        pure
        returns (int256)
    {
        uint256 d1Year = BokkyPooBahsDateTimeLibrary.getYear(startTime);
        uint256 d2Year = BokkyPooBahsDateTimeLibrary.getYear(endTime);

        int256 firstBasis = (BokkyPooBahsDateTimeLibrary.isLeapYear(startTime)) ? 366 : 365;

        if (d1Year == d2Year) {
            return int256(BokkyPooBahsDateTimeLibrary.diffDays(startTime, endTime)).floatDiv(firstBasis);
        }

        int256 secondBasis = (BokkyPooBahsDateTimeLibrary.isLeapYear(endTime)) ? 366 : 365;

        int256 firstFraction = int256(BokkyPooBahsDateTimeLibrary.diffDays(
            startTime,
            BokkyPooBahsDateTimeLibrary.timestampFromDate(d1Year.add(1), 1, 1)
        )).floatDiv(firstBasis);
        int256 secondFraction = int256(BokkyPooBahsDateTimeLibrary.diffDays(
            BokkyPooBahsDateTimeLibrary.timestampFromDate(d2Year, 1, 1),
            endTime
        )).floatDiv(secondBasis);

        return firstFraction.add(secondFraction).add(int256(d2Year.sub(d1Year).sub(1)));
    }

    
}