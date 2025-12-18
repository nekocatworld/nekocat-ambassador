// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @dev Custom errors for Ambassador Registry contract
 */
error ApplicationNotFound();
error ApplicationAlreadyReviewed();
error InvalidApplicationId();
error InvalidDuration();
error InvalidFee();
error InsufficientFee();
error NotAnActiveAmbassador();
error NotAuthorized();
error InvalidBatchSize();
error InvalidPaginationLimit();
error DataHashRequired();
error DataRequired();
error NoFundsToWithdraw();

