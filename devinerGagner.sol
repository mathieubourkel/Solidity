//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
import "@openzeppelin/contracts/access/Ownable.sol";

contract guessToWin is Ownable {
    struct Instance {
        string clue;
        string word;
        bool haveWinner;
        address winner;
    }

    // Mapping to link player address with bool to know if he already played
    mapping (address => bool) alreadyPlayed;

    // Instance current game
    Instance game;

    // Array with all of the addresses who already played
    address[] addresses;

    // the owner delete all the previous instance and clean the array of the bools of the mapping then he declare a new instance of the clue and the word
    function declare(string memory _clue, string memory _word) public onlyOwner{
        require(bytes(_word).length != 0 && bytes(_clue).length != 0, "Please enter something");
        for (uint i = 0; i < addresses.length; i++) {
            alreadyPlayed[addresses[i]] = false;
        }
        game = Instance(_clue, _word, false, address(0));
    }
    // get the indice by calling the instance of the struct
    function getClue() public view returns (string memory){
        return game.clue;
    }

    // users make propose and they get a boolean if they are right; if they already played or someone already won they have an error (revert)
    function proposal(string memory _word) public returns(bool) {
        require(bytes(_word).length != 0, "Please enter something");
        require(alreadyPlayed[msg.sender] == false, "You already played");
        require(game.haveWinner == false, "Someone already won");
        addresses.push(msg.sender);
        alreadyPlayed[msg.sender] = true;
        if (keccak256(abi.encodePacked(game.word)) == keccak256(abi.encodePacked(_word))) {
            game.haveWinner = true;
            game.winner = msg.sender;
            return true;
        } else { return false; }
    }

    // return a bool if we have a winner of the game (everyon can call the function)
    function haveWinner() public view returns (bool) {
        return game.haveWinner;
    }

    // return the address of the winner (only owner can call the function)
    function whoIsWinner() public view onlyOwner returns (address) {
        return game.winner;
    }
    // return the list of the address who played
    function whoPlays() public view returns (address[] memory) {
        return addresses;
    }
    
}

