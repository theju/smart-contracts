const { expect, assert } = require('chai');
const { ethers } = require('hardhat');
const BetMetadata = require('../artifacts/contracts/Betting.sol/Bet.json');

describe('Betting.sol Tests', async function() {
    let accounts = [];
    let Bet, bet;

    before(async function() {
        accounts = await web3.eth.getAccounts();
        Bet = new web3.eth.Contract(BetMetadata.abi);
        bet = await Bet.deploy({data: BetMetadata.bytecode}).send({from: accounts[0]});
    });

    describe('Bet', function() {
        it('Starting and ending a bet', async function() {
            const bet1 = await bet.methods.start().send({from: accounts[0]});
            assert.equal(bet1.events.BetStarted.returnValues.id, 1);

            const bet2 = await bet.methods.start().send({from: accounts[0]});
            assert.equal(bet2.events.BetStarted.returnValues.id, 2);

            try {
                await bet.methods.end(1, 0).send({from: accounts[1]});
            } catch (ex) {
                assert.isTrue(ex.message.search('This address cannot end the bet') >= 0);
            }

            const bet1Close = await bet.methods.end(1, 0).send({from: accounts[0]});
            const ev1 = bet1Close.events.BetEnded;
            assert.equal(ev1.returnValues.id, 1);
            assert.equal(ev1.returnValues.result, 0);

            const bet2Close = await bet.methods.end(2, 1).send({from: accounts[0]});
            const ev2 = bet2Close.events.BetEnded;
            assert.equal(ev2.returnValues.id, 2);
            assert.equal(ev2.returnValues.result, 1);
        });

        it('Entering a bet', async function() {
            const bet1 = await bet.methods.start().send({from: accounts[0]});
            const betId = bet1.events.BetStarted.returnValues.id;
            const position = 0;
            try {
                await bet.methods.enter(betId, position).send({from: accounts[0], value: 1});
            } catch (ex) {
                assert.isTrue(ex.message.search('Oracle cannot enter a bet') >= 0);
            }
            try {
                await bet.methods.enter(betId, position).send({from: accounts[1], value: 0});
            } catch (ex) {
                assert.isTrue(ex.message.search('Need to bet an amount greater than zero') >= 0);
            }
            const amount = web3.utils.toWei('1', 'ether');
            const betEnter = await bet.methods.enter(betId, position).send({from: accounts[1], value: amount});
            assert.equal(betEnter.events.BetPlaced.returnValues.id, betId);
            assert.equal(betEnter.events.BetPlaced.returnValues.position, position);
            assert.equal(betEnter.events.BetPlaced.returnValues.amount, amount);

            try {
                await bet.methods.enter(betId, position).send({from: accounts[1], value: web3.utils.toWei('10', 'ether')});
            } catch (ex) {
                assert.isTrue(ex.message.search('Bet has already been placed for this user') >= 0);
            }

            try {
                await bet.methods.enter(betId, 1).send({from: accounts[1], value: web3.utils.toWei('10', 'ether')});
            } catch (ex) {
                assert.isTrue(ex.message.search('Bet has already been placed for this user') >= 0);
            }

            await bet.methods.end(betId, position).send({from: accounts[0]});
            try {
                await bet.methods.enter(betId, position).send({from: accounts[1], value: web3.utils.toWei('10', 'ether')});
            } catch (ex) {
                assert.isTrue(ex.message.search('Bet has ended') >= 0);
            }
        });

        it('Claiming bet wins', async function() {
            const bet1 = await bet.methods.start().send({from: accounts[0]});
            const betId = bet1.events.BetStarted.returnValues.id;

            const pos1 = 0;
            const pos2 = 1;

            const day = 24 * 60 * 60;
            const balances = {};
            const newBalances = {};

            await ethers.provider.send('evm_increaseTime', [1 * day]);
            await bet.methods.enter(betId, pos1).send({from: accounts[1], value: web3.utils.toWei('100', 'ether')});
            balances[1] = await web3.eth.getBalance(accounts[1]);

            ethers.provider.send('evm_increaseTime', [10 * day]);
            await bet.methods.enter(betId, pos2).send({from: accounts[2], value: web3.utils.toWei('100', 'ether')});
            balances[2] = await web3.eth.getBalance(accounts[2]);

            ethers.provider.send('evm_increaseTime', [100 * day]);
            await bet.methods.enter(betId, pos1).send({from: accounts[3], value: web3.utils.toWei('100', 'ether')});
            balances[3] = await web3.eth.getBalance(accounts[3]);

            ethers.provider.send('evm_increaseTime', [200 * day]);
            await bet.methods.enter(betId, pos2).send({from: accounts[4], value: web3.utils.toWei('100', 'ether')});
            balances[4] = await web3.eth.getBalance(accounts[4]);

            ethers.provider.send('evm_increaseTime', [300 * day]);
            await bet.methods.enter(betId, pos1).send({from: accounts[5], value: web3.utils.toWei('100', 'ether')});
            balances[5] = await web3.eth.getBalance(accounts[5]);

            ethers.provider.send('evm_increaseTime', [301 * day]);
            const bet1Close = await bet.methods.end(betId, pos1).send({from: accounts[0]});

            await bet.methods.claim(betId).send({from: accounts[1]});
            newBalances[1] = await web3.eth.getBalance(accounts[1]);

            try {
                await bet.methods.claim(betId).send({from: accounts[2]});
            } catch (ex) {
                assert.isTrue(ex.message.search("You have not won this bet") >= 0);
            }

            await bet.methods.claim(betId).send({from: accounts[3]});
            newBalances[3] = await web3.eth.getBalance(accounts[3]);

            try {
                await bet.methods.claim(betId).send({from: accounts[4]});
            } catch (ex) {
                assert.isTrue(ex.message.search("You have not won this bet") >= 0);
            }

            await bet.methods.claim(betId).send({from: accounts[5]});
            newBalances[5] = await web3.eth.getBalance(accounts[5]);
        });
    });
});
