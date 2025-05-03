# Cross-chain Rebase Token

1. A protocl that allows users to deposit into a vault and in return, receive rebase tokens that represent their underlying balance.
2. Rebase token -> balanceOf function that is dynamic to show the changing balance with time.
   - Balance increases linearly with time
   - mint tokens to our users every time they perform an action (mintin, burning, transferrring, or ... bridging)
3. Interest Rate 
   - Individually set an interest rate of each user based on some global interest rate of the protocol at the time the user deposits into the vault.
   - This global interest rate can only decrease to incentivize /  reward the early adotpers.
   - Increase Token Adoption
  
   - Ran 15 tests for test/RebaseToken.t.sol:RebaseTokenTest
   - [PASS] testCanRedeemAfterTimePassed(uint256,uint256) (runs: 259, μ: 158203, ~: 157800)
   - [PASS] testCanRedeemImmediately(uint256) (runs: 259, μ: 148037, ~: 148343)
   - [PASS] testCannotCallMintAndBurn() (gas: 19920)
   - [PASS] testCannotSetInterestRate(uint256) (runs: 259, μ: 14262, ~: 14262)
   - [PASS] testDepositLinear(uint256) (runs: 258, μ: 147038, ~: 147472)
   - [PASS] testGetRebaseTokenAddress() (gas: 11128)
   - [PASS] testInterestRateCanOnlyDecrease(uint256) (runs: 259, μ: 24516, ~: 24709)
   - [PASS] testPrincipalAmount(uint256) (runs: 259, μ: 136672, ~: 136978)
   - [PASS] testRedeemFailsIfEthTransferFails(uint256) (runs: 259, μ: 254802, ~: 255108)
   - [PASS] testTransfer(uint256,uint256) (runs: 259, μ: 251210, ~: 251727)
   - [PASS] testTransferFromWithAllowance(uint256) (runs: 259, μ: 228577, ~: 228883)
   - [PASS] testTransferFromWithMaxUintAllowance(uint256,uint256) (runs: 259, μ: 273417, ~: 273934)
   - [PASS] testTransferFromWithMaxUintAmount(uint256) (runs: 259, μ: 243926, ~: 244232)
   - [PASS] testTransferMintsAccruedInterestToBothUsers(uint256,uint256) (runs: 259, μ: 232774, ~: 233291)
   - [PASS] testTransferWithMaxAmount(uint256) (runs: 259, μ: 206841, ~: 207147)
   - Suite result: ok. 15 passed; 0 failed; 0 skipped; finished in 344.56ms (2.17s CPU time)
   - Ran 1 test suite in 345.45ms (344.56ms CPU time): 15 tests passed, 0 failed, 0 skipped (15 total tests)
  
   - ╭------------------------+-----------------+-----------------+---------------+-----------------╮
   - | File                   | % Lines         | % Statements    | % Branches    | % Funcs        +==============================================================================================+
   - | src/RebaseToken.sol    | 100.00% (48/48) | 100.00% (45/45) | 100.00% (5/5) | 100.00% (12/12) |
   - |------------------------+-----------------+-----------------+---------------+-----------------|
   - | src/Vault.sol          | 100.00% (15/15) | 100.00% (12/12) | 100.00% (2/2) | 100.00% (4/4)   |
   - |------------------------+-----------------+-----------------+---------------+-----------------|
   - | test/RebaseToken.t.sol | 100.00% (2/2)   | 100.00% (1/1)   | 100.00% (0/0) | 100.00% (1/1)   |
   - |------------------------+-----------------+-----------------+---------------+-----------------|
   - | Total                  | 100.00% (65/65) | 100.00% (58/58) | 100.00% (7/7) | 100.00% (17/17) |
   - ╰------------------------+-----------------+-----------------+---------------+-----------------╯