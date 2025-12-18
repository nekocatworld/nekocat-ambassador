// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title AmbassadorConstants
 * @dev Constants used across the Ambassador Registry contract
 */
library AmbassadorConstants {
    uint256 public constant DEFAULT_AMBASSADOR_DURATION = 365 days;
    uint256 public constant MIN_AMBASSADOR_DURATION = 30 days;
    uint256 public constant MAX_AMBASSADOR_DURATION = 3650 days;

    uint256 public constant DEFAULT_SUBMISSION_FEE = 0.007 ether;
    uint256 public constant MIN_SUBMISSION_FEE = 0.0001 ether;
    uint256 public constant MAX_SUBMISSION_FEE = 0.1 ether;

    uint256 public constant MAX_BATCH_SIZE = 50;
    uint256 public constant MAX_PAGINATION_LIMIT = 100;
}
