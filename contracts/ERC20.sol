// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ERC20Token {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    string private s_name;
    string private s_symbol;
    uint256 private s_totalSupply;
    uint8 private s_decimals;
    mapping(address => uint256) private s_balances;
    mapping(address => mapping(address => uint256)) private s_approvedSpenders;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply
    ) {
        s_name = _name;
        s_symbol = _symbol;
        s_decimals = _decimals;
        _mint(msg.sender, _totalSupply);
    }

    function name() public view returns (string memory) {
        return s_name;
    }

    function symbol() public view returns (string memory) {
        return s_symbol;
    }

    function decimals() public view returns (uint8) {
        return s_decimals;
    }

    function totalSupply() public view returns (uint256) {
        return s_totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        balance = s_balances[_owner];
    }

    function transfer(address _to, uint256 _amount) public returns (bool) {
        require(_amount <= balanceOf(msg.sender));
        require(_to != address(0));
        uint256 _cut = (_amount * 10) / 100;
        s_balances[msg.sender] -= (_amount - _cut);
        s_balances[_to] += (_amount - _cut);
        _burn(msg.sender, _cut);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= balanceOf(_from));
        require(_value <= allowance(_from, msg.sender));
        require(_to != address(0));
        uint256 _cut = (_value * 10) / 100;
        s_balances[_from] -= (_value - _cut);
        s_balances[_to] += (_value - _cut);
        _burnFrom(_from, _cut);
        emit Transfer(_from, _to, _value);
        success = true;
    }

    function approve(
        address _spender,
        uint256 _value
    ) public returns (bool succcess) {
        require(_spender != address(0));
        s_approvedSpenders[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        succcess = true;
    }

    function allowance(
        address _owner,
        address _spender
    ) public view returns (uint256 remaining) {
        remaining = s_approvedSpenders[_owner][_spender];
    }

    function _mint(address _owner, uint256 _value) internal {
        require(_owner != address(0));
        s_totalSupply += (_value * (10 ** s_decimals));
        s_balances[_owner] += (_value * (10 ** s_decimals));
        emit Transfer(address(0), _owner, (_value * (10 ** s_decimals)));
    }

    function _burn(address _owner, uint256 _value) internal {
        require(_owner != address(0));
        require(_value <= balanceOf(_owner));
        s_balances[_owner] -= _value;
        s_totalSupply -= _value;
        emit Transfer(_owner, address(0), _value);
    }

    function _burnFrom(address _owner, uint256 _value) internal {
        require(_owner != address(0));
        require(_value <= allowance(_owner, msg.sender));

        s_approvedSpenders[_owner][msg.sender] -= _value;
        _burn(_owner, _value);
    }
}
