// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "./Owner.sol";

contract PaymentObligation {
    Owner public owner;
    address payable public collector;

    // Mapping to track the payment obligation of each wallet
    mapping(address => uint256) public pending;

    // Event to track the amount cleared by a wallet
    event Paid(
        address indexed _wallet,
        uint256 indexed _amount,
        uint256 indexed _at
    );
    // Event to track the payment obligation of a wallet
    event Pending(
        address indexed _wallet,
        uint256 indexed _amount,
        uint256 indexed _at
    );

    modifier onlyOwner() {
        require(owner.isOwner(msg.sender), "You are not the owner");
        _;
    }

    // Fall back function to receive coins into the contract
    receive() external payable {
        require(msg.value > 0, "Amount cannot be zero");
        require(
            pending[msg.sender] >= 0,
            "You have no pending payment obligation"
        );
        require(
            msg.value <= pending[msg.sender],
            "Amount cannot be greater than pending"
        );

        // Track the coins received by the contract
        pending[msg.sender] -= msg.value;

        // Delete the mapping if the payment obligation is cleared
        if (pending[msg.sender] == 0) {
            delete pending[msg.sender];
        }

        // Transfer the coins to the main faucet
        collector.transfer(msg.value);

        // Track the cleared payment obligation of the wallet
        emit Paid(msg.sender, msg.value, block.timestamp);
    }

    // Function to add a payment obligation to a wallet
    function addPaymentObligation(
        address _wallet,
        uint256 _amount
    ) external onlyOwner {
        require(_amount > 0, "Amount cannot be zero");
        pending[_wallet] += _amount;
        emit Pending(_wallet, _amount, block.timestamp);
    }

    // Function to clear a payment obligation of a wallet
    function removePaymentObligation(
        address _wallet,
        uint256 _amount
    ) external onlyOwner {
        require(_amount > 0, "Amount cannot be zero");
        require(
            _amount <= pending[_wallet],
            "Amount cannot be greater than pending"
        );
        pending[_wallet] -= _amount;
        if (pending[_wallet] == 0) {
            delete pending[_wallet];
        }
        // Track the cleared payment obligation of the wallet
        emit Paid(_wallet, _amount, block.timestamp);
    }

    // Function to set the collector address
    function setCollector(address payable _collector) external onlyOwner {
        require(_collector != collector, "Collector address already set");
        collector = _collector;
    }
}
