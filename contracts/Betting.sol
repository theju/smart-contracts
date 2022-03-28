// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

contract Bet {
    event BetStarted(uint256 id);
    event BetEnded(uint256 id, uint result);
    event BetPlaced(uint256 id, uint position, uint256 amount);

    address house;
    uint256 fees;

    struct UserBet {
        uint256 id;
        address bettor;
        uint256 time;
        uint256 amount;
        uint position;
    }

    struct Pot {
        uint256 num_bettors;
        uint256 sum;
        uint256 value;
    }

    struct Meta {
        uint256 id;
        uint256 start_time;
        uint256 end_time;
        address oracle;
        uint result;
        Pot for_pot;
        Pot against_pot;
        uint house_fees_bps;
    }


    uint256 house_fee_bps = 1;

    mapping (uint256 => mapping (address => UserBet)) bets;
    mapping (uint256 => Meta) meta;
    mapping (uint256 => mapping (address => uint256)) balances;
    uint256 last_id = 0;

    constructor() {
        house = msg.sender;
        fees = 0;
    }

    function start() public returns (uint256) {
        last_id += 1;
        Pot memory for_pot = Pot({
            num_bettors: 0,
            sum: 0,
            value: 0
        });
        Pot memory against_pot = Pot({
            num_bettors: 0,
            sum: 0,
            value: 0
        });
        meta[last_id] = Meta({
            id: last_id,
            start_time: block.timestamp,
            end_time: 0,
            oracle: msg.sender,
            result: 0,
            for_pot: for_pot,
            against_pot: against_pot,
            house_fees_bps: house_fee_bps
        });
        emit BetStarted(last_id);
        return last_id;
    }

    function end(uint256 bet_id, uint result) public {
        require(meta[bet_id].id != 0, "Invalid bet");
        require(meta[bet_id].oracle == msg.sender, "This address cannot end the bet");

        meta[bet_id].end_time = block.timestamp;
        meta[bet_id].result = result;
        emit BetEnded(bet_id, result);
    }

    function enter(uint256 bet_id, uint position) public payable {
        require(meta[bet_id].end_time == 0, "Bet has ended");
        require(meta[bet_id].oracle != msg.sender, "Oracle cannot enter a bet");
        require(bets[bet_id][msg.sender].id == 0, "Bet has already been placed for this user");
        require(msg.value > 0, "Need to bet an amount greater than zero");

        bets[bet_id][msg.sender] = UserBet({
            id: bet_id,
            bettor: msg.sender,
            time: block.timestamp,
            amount: msg.value,
            position: position
        });
        balances[bet_id][msg.sender] = msg.value;
        if (position == 0) {
            meta[bet_id].for_pot.num_bettors += 1;
            meta[bet_id].for_pot.value += msg.value;
            uint256 product = msg.value * 1 / (block.timestamp - meta[bet_id].start_time);
            meta[bet_id].for_pot.sum += product;
        } else {
            meta[bet_id].against_pot.num_bettors += 1;
            meta[bet_id].against_pot.value += msg.value;
            uint256 product = msg.value * 1 / (block.timestamp - meta[bet_id].start_time);
            meta[bet_id].against_pot.sum += product;
        }
        emit BetPlaced(bet_id, position, msg.value);
    }

    function claim(uint256 bet_id) public {
        require(meta[bet_id].end_time != 0, "Bet has not completed");
        require(meta[bet_id].oracle != msg.sender, "Oracle has to call claimFees");
        require(balances[bet_id][msg.sender] != 0, "User has no balance for receiving payout");

        UserBet memory user_bet = bets[bet_id][msg.sender];
        Meta memory bet = meta[bet_id];
        uint result = bet.result;
        if (user_bet.position == result) {
            uint256 dipping_pot = 0;
            uint256 max_sum = 0;
            if (bet.result == 0) {
                dipping_pot = bet.against_pot.value;
                max_sum = bet.for_pot.sum;
            } else {
                dipping_pot = bet.for_pot.value;
                max_sum = bet.against_pot.sum;
            }

            if (max_sum == 0) {
                revert("One or both of the pots are empty");
            }

            uint256 amount = balances[bet_id][msg.sender];
            uint256 winning_ratio = user_bet.amount * 100 / ((user_bet.time - bet.start_time) * max_sum);
            uint256 winning_amount = winning_ratio * dipping_pot / 100;
            uint256 house_fees = winning_amount * bet.house_fees_bps / 100;
            fees += house_fees;
            uint256 adjusted_winning_amount = amount + (winning_amount - house_fees);
            balances[bet_id][msg.sender] = 0;
            if (!payable(msg.sender).send(adjusted_winning_amount)) {
                fees -= house_fees;
                balances[bet_id][msg.sender] = amount;
            }
        } else {
            revert("You have not won this bet");
        }
    }

    function claimFees() public {
        require(msg.sender == house, "Only house can claim fees");
        require(fees > 0, "No fees to payout");

        uint256 amount = fees;
        fees = 0;
        if (!payable(msg.sender).send(amount)) {
            fees = amount;
        }
    }
}
