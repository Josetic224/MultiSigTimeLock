//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract MultiSig {
    error onlyWalletRestriction();
    error ownerExists();
    error addressZero();
    error insufficientAmount();

    event ownerAddition(address owner);

    address[] public owners;
    uint256 public quorum = (owners.length * 51) / 100;
    enum Status {
        PROPSED,
        APPROVED,
        REJECTED,
        WITHDRAWAL
    }
    struct TransactionDetails {
        uint256 amount;
        string message;
        uint256 currentTime;
        uint256 timeLock;
        address receiver;
        Status status;
    }

    uint256 public transactionCount;

    mapping(uint256 => TransactionDetails) transactions;
    mapping(address => uint256) balances;
    mapping(address => bool) isOwner;

    // this helps in access control to ensure that address calling the function is the wallet Address
    modifier onlyWallet() {
        if (msg.sender != address(this)) revert onlyWalletRestriction();
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        if (!isOwner[owner]) revert ownerExists();
        _;
    }

    modifier onlyOwners() {
        bool _isOwner = false;

        //loop into the array
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == msg.sender) {
                _isOwner = true;
                break;
            }
        }
        require(
            _isOwner,
            "You don't have enough permissions to call this function"
        );
        _;
    }

    modifier addressZeroCheck(address receiver) {
        if (receiver == address(0)) revert addressZero();
        _;
    }

    function addOwner(address owner) external ownerDoesNotExist(owner) {
        isOwner[owner] = true;
        owners.push(owner);
        emit ownerAddition(owner);
    }

    function removeOwner(address _owner) external {
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == _owner) {
                delete owners[i];
            }
        }
    }

    function initiateTransaction(
        uint256 _amount,
        string memory _message,
        address _receiver
    ) public ownerDoesNotExist(msg.sender) addressZeroCheck(_receiver) {
        transactionCount++;
        if (balances[address(this)] < _amount) revert insufficientAmount();
        transactions[transactionCount] = TransactionDetails({
            amount: _amount,
            message: _message,
            currentTime: block.timestamp,
            timeLock: block.timestamp + 3 days,
            receiver: _receiver,
            status: Status.PROPSED
        });
    }

    function approveTransaction(
        uint256 txId
    ) public ownerDoesNotExist(msg.sender) {
        require(txId != 0, "txId not found");
        require(
            block.timestamp > transactions[txId].timeLock,
            "Transaction not yet Unlocked"
        );
        require(
            transactions[txId].status == Status.PROPSED,
            "Transaction must have been proposed"
        );

        //update the state
        transactions[txId].status = Status.APPROVED;
    }

    function withdrawTransaction(uint256 txId, uint256 _amount) public payable {
        require(msg.sender != address(0), "Address Zero is not allowed");
        require(_amount >= 0, "invalid Amount");
        require(
            transactions[txId].status == Status.APPROVED,
            "This Transaction has not been Approved"
        );
        require(
            block.timestamp > transactions[txId].timeLock,
            "Unock Timenot reached yet"
        );
        require(transactions[txId].amount == _amount, "differences in amount");

        transactions[txId].status = Status.APPROVED;
    }
}
