import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can post new tip and receive tokens",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('eco-nest', 'post-tip', [
        types.ascii("Save Energy"),
        types.utf8("Turn off lights when leaving room"),
        types.uint(1)
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectOk().expectUint(1);
    block.receipts[0].events.expectFungibleTokenMintEvent(
      10,
      wallet1.address,
      "eco-token"
    );
  }
});

Clarinet.test({
  name: "Cannot post tip with invalid category",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('eco-nest', 'post-tip', [
        types.ascii("Invalid"),
        types.utf8("Test"),
        types.uint(10)
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectErr().expectUint(100);
  }
});

Clarinet.test({
  name: "Can vote on tip only once",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    const wallet2 = accounts.get('wallet_2')!;
    
    // Post tip
    let block = chain.mineBlock([
      Tx.contractCall('eco-nest', 'post-tip', [
        types.ascii("Test Tip"),
        types.utf8("Content"),
        types.uint(1)
      ], wallet1.address)
    ]);
    
    // First vote succeeds
    block = chain.mineBlock([
      Tx.contractCall('eco-nest', 'vote-tip', [
        types.uint(1),
        types.bool(true)
      ], wallet2.address)
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Second vote fails
    block = chain.mineBlock([
      Tx.contractCall('eco-nest', 'vote-tip', [
        types.uint(1),
        types.bool(true)
      ], wallet2.address)
    ]);
    block.receipts[0].result.expectErr().expectUint(401);
  }
});
