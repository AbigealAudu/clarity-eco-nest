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
  name: "Cannot post empty content",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('eco-nest', 'post-tip', [
        types.ascii("Test"),
        types.utf8(""),
        types.uint(1)
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectErr().expectUint(101);
  }
});

Clarinet.test({
  name: "Cannot post tips too frequently",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    // First post succeeds
    let block = chain.mineBlock([
      Tx.contractCall('eco-nest', 'post-tip', [
        types.ascii("Test 1"),
        types.utf8("Content 1"),
        types.uint(1)
      ], wallet1.address)
    ]);
    
    // Second immediate post fails
    block = chain.mineBlock([
      Tx.contractCall('eco-nest', 'post-tip', [
        types.ascii("Test 2"),
        types.utf8("Content 2"),
        types.uint(1)
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectErr().expectUint(102);
  }
});
