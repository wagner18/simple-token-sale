/*
This Token Contract is an addition to the HumanStandardToken.

It includes a function called `redeem`, which takes an elliptic signature,
a value (number of tokens to burn), and a nonce. It removes the specified
number of tokens both from the signer's balance and from the total supply.
.*/

import "tokens/StandardToken.sol";

pragma solidity ^0.4.11;

contract ERC661Token is StandardToken {


    /* Public variables of the token */

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It's like comparing 1 wei to 1 ether.
    string public symbol;                 //An identifier: eg SBX
    string public version = 'H0.1';       //human 0.1 standard. Just an arbitrary versioning scheme.
    mapping (address => uint256) nonces;  // Redemption nonces

    function ERC661Token(
      uint256 _initialAmount,
      string _tokenName,
      uint8 _decimalUnits,
      string _tokenSymbol
      ) {
      balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
      totalSupply = _initialAmount;                        // Update total supply
      name = _tokenName;                                   // Set the name for display purposes
      decimals = _decimalUnits;                            // Amount of decimals for display purposes
      symbol = _tokenSymbol;                               // Set the symbol for display purposes
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
      allowed[msg.sender][_spender] = _value;
      Approval(msg.sender, _spender, _value);

      //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn't have to include a contract in here just for this.
      //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
      //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
      require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
      return true;
    }

    // Redeem tokens. This decreases the signer's supply AND decreases the total supply
    function redeem(bytes32[3] sig, uint256 amount, uint256 nonce) returns (bool success) {
      // ABI definition of this function
      bytes32 word = 0xbfdaf40d;

      // Ensure the message is in the signature and get the signer
      bytes32 message = keccak256(uint256(amount), bytes4(word), address(this), uint256(nonce));
      address signer = ecrecover(message, uint8(sig[2]), sig[0], sig[1]);

      // Subtract from user's balance and supply
      assert(balances[signer] >= amount);
      assert(totalSupply >= amount);
      balances[signer] -= amount;
      totalSupply -= amount;

      // Check the user's nonce and increment it
      assert(nonces[signer] == nonce);
      nonces[signer] += 1;

      return true;
    }


}
